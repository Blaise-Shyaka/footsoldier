module Tenancy
  # Row-level security only protects data from a role that cannot bypass it (ADR-0004). PostgreSQL
  # lets three kinds of role through: superusers, even where row-level security is forced; roles
  # with BYPASSRLS; and a table's owner, unless the table forces it.
  #
  # The check looks at the role the connection logged in as and at every role it is a member of,
  # because a member can switch to those roles (SET ROLE), and one that inherits from the owner
  # has the owner's privileges, bypass included.
  module DatabaseRoleCheck
    class PrivilegedRoleError < StandardError; end

    extend self

    # Raises PrivilegedRoleError unless the connection's role is bound by row-level security.
    def verify!(connection)
      reasons = bypass_reasons(connection)
      return if reasons.empty?

      raise PrivilegedRoleError, "The database role #{session_user(connection)} can bypass row-level " \
        "security, so it would not apply to this connection: #{reasons.to_sentence}."
    end

    # Why the connection's role can bypass row-level security; empty when it cannot.
    def bypass_reasons(connection)
      role = connection.select_one(<<~SQL)
        SELECT rolsuper, rolbypassrls FROM pg_roles WHERE rolname = session_user
      SQL
      # A superuser is also a member of every role, so nothing else is worth saying.
      return [ "it is a superuser" ] if role["rolsuper"]

      reasons = []
      reasons << "it has BYPASSRLS" if role["rolbypassrls"]

      privileged_roles = connection.select_values(<<~SQL)
        SELECT rolname FROM pg_roles
        WHERE rolname <> session_user
          AND (rolsuper OR rolbypassrls)
          AND pg_has_role(session_user, oid, 'MEMBER')
        ORDER BY rolname
      SQL
      if privileged_roles.any?
        reasons << "it is a member of #{privileged_roles.to_sentence}, which can bypass it"
      end

      owned_tables = connection.select_values(<<~SQL)
        SELECT format('%I.%I', n.nspname, c.relname)
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind IN ('r', 'p')
          AND n.nspname <> 'information_schema'
          AND n.nspname !~ '^pg_'
          AND pg_has_role(session_user, c.relowner, 'MEMBER')
        ORDER BY 1
      SQL
      if owned_tables.any?
        examples = owned_tables.first(3).join(", ")
        examples += ", ..." if owned_tables.size > 3
        reasons << "it owns, or is a member of the owner of, #{owned_tables.size} " \
          "#{"table".pluralize(owned_tables.size)} (#{examples})"
      end

      reasons
    end

    private
      def session_user(connection)
        connection.select_value("SELECT session_user")
      end
  end
end
