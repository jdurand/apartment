require 'apartment/railtie' if defined?(Rails)
require 'active_support/core_ext/object/blank'
require 'forwardable'
require 'active_record'
require 'apartment/tenant'

module Apartment

  class << self

    extend Forwardable

    ACCESSOR_METHODS  = [:use_schemas, :use_sql, :seed_after_create, :prepend_environment, :append_environment]
    WRITER_METHODS    = [:tenant_names, :database_schema_file, :excluded_models, :default_schema, :persistent_schemas, :connection_class, :tld_length, :db_migrate_tenants]

    attr_accessor(*ACCESSOR_METHODS)
    attr_writer(*WRITER_METHODS)

    def_delegators :connection_class, :connection, :establish_connection

    # configure apartment with available options
    def configure
      yield self if block_given?
    end

    # Be careful not to use `return` here so both Proc and lambda can be used without breaking
    def tenant_names
      @tenant_names.respond_to?(:call) ? @tenant_names.call : @tenant_names
    end

    # Whether or not db:migrate should also migrate tenants
    # defaults to true
    def db_migrate_tenants
      return @db_migrate_tenants if defined?(@db_migrate_tenants)

      @db_migrate_tenants = true
    end

    # Default to empty array
    def excluded_models
      @excluded_models || []
    end

    def default_schema
      @default_schema || "public"
    end

    def persistent_schemas
      @persistent_schemas || []
    end

    def connection_class
      @connection_class || ActiveRecord::Base
    end

    def database_schema_file
      return @database_schema_file if defined?(@database_schema_file)

      @database_schema_file = Rails.root.join('db', 'schema.rb')
    end

    def tld_length
      @tld_length || 1
    end

    # Reset all the config for Apartment
    def reset
      (ACCESSOR_METHODS + WRITER_METHODS).each{|method| remove_instance_variable(:"@#{method}") if instance_variable_defined?(:"@#{method}") }
    end

    def database_names
      warn "[Deprecation Warning] `database_names` is now deprecated, please use `tenant_names`"
      tenant_names
    end

    def database_names=(names)
      warn "[Deprecation Warning] `database_names=` is now deprecated, please use `tenant_names=`"
      self.tenant_names=(names)
    end

    def use_postgres_schemas
      warn "[Deprecation Warning] `use_postgresql_schemas` is now deprecated, please use `use_schemas`"
      use_schemas
    end

    def use_postgres_schemas=(to_use_or_not_to_use)
      warn "[Deprecation Warning] `use_postgresql_schemas=` is now deprecated, please use `use_schemas=`"
      self.use_schemas = to_use_or_not_to_use
    end
  end

  # Exceptions
  ApartmentError = Class.new(StandardError)

  # Raised when apartment cannot find the adapter specified in <tt>config/database.yml</tt>
  AdapterNotFound = Class.new(ApartmentError)

  # Tenant specified is unknown
  TenantNotFound = Class.new(ApartmentError)

  # Raised when database cannot find the specified database
  DatabaseNotFound = Class.new(TenantNotFound)

  # Raised when database cannot find the specified schema
  SchemaNotFound = Class.new(TenantNotFound)

  # The Tenant attempting to be created already exists
  TenantExists = Class.new(ApartmentError)

  # Raised when trying to create a database that already exists
  DatabaseExists = Class.new(TenantExists)

  # Raised when trying to create a schema that already exists
  SchemaExists = Class.new(TenantExists)
end
