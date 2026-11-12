# The tenant boundary (ADR-0004). Models that include Tenancy::Scoped only ever see the rows of
# Current.agency; row-level security in PostgreSQL is the second, independent safeguard.
module Tenancy
  # Raised when a tenant model is used with no Current.agency outside Tenancy.across_agencies.
  class NoTenantError < StandardError
    def initialize(model_name)
      super("#{model_name} is tenant-owned, but no tenant is set. Set Current.agency, or wrap " \
            "platform or maintenance code in Tenancy.across_agencies.")
    end
  end

  # Raised when a record is saved into an agency other than Current.agency.
  class TenantMismatchError < StandardError; end

  ACROSS_AGENCIES_REASONS = %i[platform maintenance].freeze

  class << self
    # Runs the block with the tenant scope lifted, so tenant models return every agency's rows.
    # Only platform code (the operator console) and maintenance code (data migrations, jobs that
    # span agencies) may do this, and the reason makes each use easy to find.
    #
    # The lift applies to the current thread or fiber only and ends with the block, even when
    # the block raises.
    def across_agencies(reason)
      unless ACROSS_AGENCIES_REASONS.include?(reason)
        raise ArgumentError, "reason must be one of #{ACROSS_AGENCIES_REASONS.inspect}, got #{reason.inspect}"
      end

      previous = ActiveSupport::IsolatedExecutionState[:tenancy_across_agencies]
      ActiveSupport::IsolatedExecutionState[:tenancy_across_agencies] = reason
      begin
        yield
      ensure
        ActiveSupport::IsolatedExecutionState[:tenancy_across_agencies] = previous
      end
    end

    # The reason given to the enclosing Tenancy.across_agencies block, or nil outside one.
    def across_agencies_reason
      ActiveSupport::IsolatedExecutionState[:tenancy_across_agencies]
    end

    def across_agencies?
      !across_agencies_reason.nil?
    end
  end
end
