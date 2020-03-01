module Pvp
  class Payout < ActiveRecord::Base
    module Processor
      module Check
        class AlertConditions
          attr_reader :data

          COUNT_CHECK_THRESHOLD = 10
          PROCESSOR_RUNS_CHECK_THRESHOLD = 1

          def initialize(data)
            @data = data
          end

          def call
            [true, []]
          end
        end
      end
    end
  end
end
