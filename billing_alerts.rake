# NOTE: почему-то классы из lib не автолоадятся в rake-таске
require './lib/services/potok_slack_notifier'

namespace :billing_alerts do
  task perform: :environment do
    data = Pvp::Payout::Processor::Check::DataCollector
           .new(time: Time.current, count_check_period: 1.hour, processor_runs_check_period: 1.hour)
           .call

    need_to_alert, problems =
      Pvp::Payout::Processor::Check::AlertConditions.new(data).call

    return unless need_to_alert
    Pvp::Payout::Processor::Check::SlackAlertPerformer
      .new(data: data, problems: problems)
      .call
  end
end
