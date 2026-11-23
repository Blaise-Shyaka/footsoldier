# Per-request and per-job context. Rails resets it before each request and each job, so
# nothing set here leaks from one to the next.
#
# agency is the tenant context: tenant models (Tenancy::Scoped) read and write only its rows.
# membership is the user's membership in that agency, which carries their role.
class Current < ActiveSupport::CurrentAttributes
  attribute :agency, :user, :membership
end
