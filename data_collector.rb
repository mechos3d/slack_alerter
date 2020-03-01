module Pvp
  class Payout < ActiveRecord::Base
    module Processor
      module Check
        class DataCollector
          attr_reader :time, :count_check_period, :processor_runs_check_period

          def initialize(time: Time.current, count_check_period: 1.hour, processor_runs_check_period: 1.hour)
            @time = time
            @count_check_period = count_check_period
            @processor_runs_check_period = processor_runs_check_period
          end

          def call
            @_call ||= {
              result: {
                payouts_count:                   payouts_count,
                processor_runs_count:            'Not implemented yet',
                processor_status_pair:           processor_status_pair,
                broken_virtual_account_ids:      broken_virtual_account_ids,
                processor_payouts_by_hour:       processor_payouts_by_hour,
                broken_nominals_count:           broken_nominals_count,
                daily_skip_list:                 daily_skip_list,
                no_was_response_payout_ids:      no_was_response_payout_ids,
                loans_failed_finalization_ids:   loans_failed_finalization_ids
              },
              arguments: {
                time: time,
                count_check_period: count_check_period,
                processor_runs_check_period: processor_runs_check_period
              }
            }
          end

          private

          def no_was_response_payout_ids
            Pvp::Payout.where(aasm_state: 'no_was_response').pluck(:id)
          end

          def loans_failed_finalization_ids
            Pvp::Loan.where(failed_finalization: true).pluck(:id)
          end

          def daily_skip_list
            return 'OK' if Rails.cache.data.get("skip_list_created_#{Date.current}").present?
            'ALARM (and check portfolio)'
          end

          def broken_nominals_count
            Global::Account.where(account_type: 'alfa_nominal', account_broken: true).count
          end

          def payouts_count
            Pvp::Payout.where(initiator_id: nil).where('created_at > ?', time - count_check_period).count
          end

          def processor_runs_count
            all_todays_runs = Rails.cache.data.lrange(processor_worker_key, 0, -1)
            return 0 if all_todays_runs.empty?

            filter_processor_runs(all_todays_runs)
          end

          def filter_processor_runs(all_runs)
            period_start = time - processor_runs_check_period

            res = all_runs.map do |x|
              el = JSON.parse(x)
              el['ended_at'] = Time.zone.parse(el['ended_at'])
              el
            end
            res.select { |x| x['ended_at'] >= period_start && x['ended_at'] < time }.count
          end

          def processor_status_pair
            status = Global::Status.find_by(component: Constants::PAYOUT_PROCESSOR)
            return 'Global::Status NOT FOUND' unless status
            arr = [status.status, status.updated_at.iso8601]
            "[:#{arr.join(', ')}]"
          end

          def broken_virtual_account_ids
            Virtual::Account.where(account_broken: true).pluck(:id)
          end

          def processor_payouts_by_hour
            raw_result = ActiveRecord::Base.connection.execute(
              'SELECT COUNT(*) AS count, (extract(hour from pvp_payouts.created_at) + 3) AS hour '\
              "FROM pvp_payouts WHERE date_trunc('day', pvp_payouts.created_at) = '#{time.to_date.to_s(:db)}' "\
              'AND initiator_id IS NULL '\
              'GROUP BY extract(hour from pvp_payouts.created_at)'
            )
            arr = raw_result.to_a.map { |x| [x['hour'].to_i, x['count'].to_i] } # .sort_by(&:first)
            fill_empty_hours(arr)
          end

          def fill_empty_hours(arr)
            arr_hours = arr.map { |x| x[0] }
            current_hour = time.hour
            all_possible_hours = (8..22)
            zero_value = '--'

            all_possible_hours.each do |hour|
              break if hour == current_hour
              arr << [hour, zero_value] unless arr_hours.include?(hour)
            end
            arr.sort_by { |(hour, _count)| hour }
          end

          def processor_worker_key
            Pvp::PayoutWorkers::ProcessorWorker.redis_worker_timestamp_key(time.to_date)
          end
        end
      end
    end
  end
end
