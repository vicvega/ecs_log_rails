require "active_support"
require "active_support/ordered_options"

module EcsLogRails
  class OrderedOptions < ActiveSupport::OrderedOptions
    def custom_payload(&block)
      self.custom_payload_method = block
    end
  end
end
