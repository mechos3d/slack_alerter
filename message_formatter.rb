module SimpleSlackAlerts
  class MessageFormatter
    attr_reader :data, :problems

    def initialize(data:, problems:)
      @data = data
      @problems = problems
    end

    def call
      ::PotokSlackNotifier.new.perform(:billing_alerts, message, username: 'PayoutProcessorCheck',
                                                                 icon_emoji: ':table_flip_guy:')
    end

    private

    # TODO: mark with '**' (bold text in Slack) - stuff that triggered the alert (problems)
    # rubocop:disable Metrics/AbcSize
    def message
      <<~HEREDOC
        `payouts_count (last #{count_check_period}sec):`
          #{result[:payouts_count]},
        `processor_runs_ended_count (last #{processor_runs_check_period}sec):`
          #{result[:processor_runs_count]},
        `processor_status:`
          #{result[:processor_status_pair]},
        `broken_virtuals:`
          #{result[:broken_virtual_account_ids]},
        `processor_payouts_by_hour:`
          #{result[:processor_payouts_by_hour]},
        `unmatched_incoming_transactions:`
          #{result[:unmatched_incoming_transactions]},
        `broken_nominals_count:`
          #{result[:broken_nominals_count]},
        `daily_skip_list:`
          #{result[:daily_skip_list]},
        `no_was_response_payout_ids:`
          #{result[:no_was_response_payout_ids]},
        `loans_failed_finalization_ids:`
          #{result[:loans_failed_finalization_ids]}
      HEREDOC
    end
  end
end
