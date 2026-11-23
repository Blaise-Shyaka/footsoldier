module Tenancy
  # Included by every tenant-owned model. Inside a tenant context (Current.agency) the model
  # only reads that agency's rows, builds new records in it, and refuses to save a record into
  # another agency or move one between agencies. Without a tenant context it raises
  # Tenancy::NoTenantError, unless the code runs inside Tenancy.across_agencies.
  #
  # This is the application half of tenant isolation; row-level security in PostgreSQL is the
  # database half (ADR-0004). Model.unscoped skips this scope: do not use it on tenant models.
  module Scoped
    extend ActiveSupport::Concern

    included do
      belongs_to :agency, class_name: "Tenancy::Agency"

      # Moving a row to another agency would leave its children behind in the old one.
      attr_readonly :agency_id

      # Evaluated for every query and every new record, so it always uses the current tenant.
      # Returning nil inside Tenancy.across_agencies leaves the relation unscoped.
      default_scope do
        next if Tenancy.across_agencies?

        agency = Current.agency or raise Tenancy::NoTenantError, name
        where(agency_id: agency.id)
      end

      before_save :ensure_saved_in_current_agency
    end

    private
      def ensure_saved_in_current_agency
        return if Tenancy.across_agencies?
        return if agency_id == Current.agency&.id

        raise Tenancy::TenantMismatchError,
          "#{self.class.name} belongs to agency #{agency_id.inspect}, but the current agency is " \
          "#{Current.agency&.id.inspect}"
      end
  end
end
