module Tenancy
  # Lists the ways the database schema breaks the tenant table rules of ADR-0004. A table with an
  # agency_id column is a tenant table, and needs:
  #
  # - agency_id NOT NULL, and an index that starts with it;
  # - row-level security enabled and forced (owners bypass it otherwise);
  # - the tenant policy, and no other permissive policy (permissive policies are OR-ed, so any
  #   other one can open other agencies' rows);
  # - agency_id in every foreign key to another tenant table, so a row's agency cannot differ
  #   from its parent's, and in at least one foreign key, to agencies or to a tenant parent.
  #
  # A table without agency_id must not reference a tenant table: it would hold an agency's data
  # with no row-level security. agencies, the tenant root, has no agency_id and none of the rules.
  #
  # Each broken rule fails silently: the table still works, but leaks rows or loses them. The
  # suite runs this against the test database, which is loaded from the schema file, so it also
  # fails if the schema file drops the policies.
  class SchemaLint
    ROOT_TABLE = "agencies".freeze

    # The policy expression from ADR-0004, as PostgreSQL 17 prints it. If a PostgreSQL upgrade
    # prints it differently, every tenant table fails the lint; none passes by mistake.
    TENANT_POLICY = "(agency_id = (NULLIF(current_setting('app.agency_id'::text, true), ''::text))::bigint)".freeze

    def self.violations(connection)
      new(connection).violations
    end

    def initialize(connection)
      @connection = connection
    end

    # One message per broken rule, each starting with the table's name.
    def violations
      tables.values.select { |table| tenant?(table) }.flat_map { |table| violations_of(table) } +
        references_from_other_tables
    end

    private
      attr_reader :connection

      def violations_of(table)
        problems = []
        problems << "agency_id allows NULL" unless table["agency_id_not_null"]
        problems << "no index starts with agency_id" unless indexed_by_agency?(table)
        problems << "row-level security is not enabled" unless table["rls_enabled"]
        problems << "row-level security is not forced, so the table's owner bypasses it" unless table["rls_forced"]
        problems.concat(policy_problems(table), foreign_key_problems(table))
        problems.map { |problem| "#{table["name"]}: #{problem}" }
      end

      def indexed_by_agency?(table)
        indexes.any? { |index| index["table_oid"] == table["oid"] && index["first_column"] == table["agency_id_attnum"] }
      end

      def policy_problems(table)
        permissive = policies.select { |policy| policy["table_oid"] == table["oid"] && policy["permissive"] }
        tenant, others = permissive.partition { |policy| tenant_policy?(policy) }

        problems = others.map do |policy|
          "policy #{policy["name"]} is permissive and is not the tenant policy; permissive policies are OR-ed, " \
            "so it can widen access"
        end
        problems.unshift("no tenant policy: expected a permissive policy FOR ALL USING #{TENANT_POLICY}") if tenant.empty?
        problems
      end

      # FOR ALL, and checks written rows with the same expression it filters read rows with.
      def tenant_policy?(policy)
        policy["command"] == "*" && policy["qual"] == TENANT_POLICY && policy["with_check"].in?([ nil, TENANT_POLICY ])
      end

      def foreign_key_problems(table)
        keys = foreign_keys.select { |key| key["table_oid"] == table["oid"] }

        problems = keys.filter_map do |key|
          parent = tables[key["parent_oid"]]
          next unless tenant?(parent)
          next if pairs(key).include?(%w[agency_id agency_id])

          "foreign key #{key["name"]} to #{parent["name"]} leaves out agency_id, so a row's agency can differ from its parent's"
        end
        problems << "agency_id is in no foreign key to #{ROOT_TABLE} or to a tenant parent" unless keys.any? { |key| anchors_agency?(key) }
        problems
      end

      def anchors_agency?(key)
        parent = tables[key["parent_oid"]]

        if parent && parent["name"] == ROOT_TABLE
          pairs(key).include?(%w[agency_id id])
        elsif tenant?(parent)
          pairs(key).include?(%w[agency_id agency_id])
        end
      end

      def references_from_other_tables
        foreign_keys.filter_map do |key|
          table = tables[key["table_oid"]]
          parent = tables[key["parent_oid"]]
          next if tenant?(table) || !tenant?(parent)

          "#{table["name"]}: foreign key #{key["name"]} references tenant table #{parent["name"]}, but " \
            "#{table["name"]} has no agency_id, so its rows have no row-level security"
        end
      end

      def tenant?(table)
        table.present? && table["agency_id_attnum"].present?
      end

      # [column, referenced column] for each column of a foreign key, in order.
      def pairs(key)
        key["columns"].zip(key["parent_columns"])
      end

      # Ordinary and partitioned tables in the schemas on the search path, by oid.
      def tables
        @tables ||= select(<<~SQL).index_by { |table| table["oid"] }
          SELECT c.oid, c.oid::regclass::text AS name,
                 c.relrowsecurity AS rls_enabled, c.relforcerowsecurity AS rls_forced,
                 a.attnum AS agency_id_attnum, a.attnotnull AS agency_id_not_null
          FROM pg_class c
          JOIN pg_namespace n ON n.oid = c.relnamespace
          LEFT JOIN pg_attribute a ON a.attrelid = c.oid AND a.attname = 'agency_id' AND NOT a.attisdropped
          WHERE c.relkind IN ('r', 'p') AND n.nspname = ANY (current_schemas(false))
        SQL
      end

      # Partial and invalid indexes do not count: they leave out rows, or are not used at all.
      def indexes
        @indexes ||= select(<<~SQL)
          SELECT i.indrelid AS table_oid, i.indkey[0] AS first_column
          FROM pg_index i
          JOIN pg_class c ON c.oid = i.indrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE i.indisvalid AND i.indpred IS NULL AND n.nspname = ANY (current_schemas(false))
        SQL
      end

      def policies
        @policies ||= select(<<~SQL)
          SELECT p.polrelid AS table_oid, p.polname::text AS name, p.polcmd::text AS command,
                 p.polpermissive AS permissive,
                 pg_get_expr(p.polqual, p.polrelid) AS qual,
                 pg_get_expr(p.polwithcheck, p.polrelid) AS with_check
          FROM pg_policy p
          JOIN pg_class c ON c.oid = p.polrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE n.nspname = ANY (current_schemas(false))
        SQL
      end

      def foreign_keys
        @foreign_keys ||= select(<<~SQL)
          SELECT con.conname::text AS name, con.conrelid AS table_oid, con.confrelid AS parent_oid,
                 ARRAY(SELECT a.attname::text
                       FROM unnest(con.conkey) WITH ORDINALITY AS k(attnum, ord)
                       JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = k.attnum
                       ORDER BY k.ord) AS columns,
                 ARRAY(SELECT a.attname::text
                       FROM unnest(con.confkey) WITH ORDINALITY AS k(attnum, ord)
                       JOIN pg_attribute a ON a.attrelid = con.confrelid AND a.attnum = k.attnum
                       ORDER BY k.ord) AS parent_columns
          FROM pg_constraint con
          JOIN pg_class c ON c.oid = con.conrelid
          JOIN pg_namespace n ON n.oid = c.relnamespace
          WHERE con.contype = 'f' AND n.nspname = ANY (current_schemas(false))
        SQL
      end

      def select(sql)
        result = connection.select_all(sql, "Tenancy::SchemaLint")
        result.cast_values.map { |row| result.columns.zip(row).to_h }
      end
  end
end
