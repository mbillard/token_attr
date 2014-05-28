require 'active_record'
require 'active_support/concern'

module TokenAttr
  DEFAULT_TOKEN_LENGTH  = 8.freeze
  ALPHABETIC_ALPHABET   = [('a'..'z'),('A'..'Z')].map(&:to_a).flatten.freeze
  NUMERIC_ALPHABET      = [(0..9)].map(&:to_a).flatten.freeze
  ALPHANUMERIC_ALPHABET = [ALPHABETIC_ALPHABET, NUMERIC_ALPHABET].flatten.freeze

  TokenDefinition = Struct.new(:attr_name, :scope_attr)

  module Concern
    extend ActiveSupport::Concern

    included do
      before_validation :generate_tokens
    end

    module ClassMethods
      def token_attr(attr_name, options = {})
        token_definitions << TokenDefinition.new(attr_name, options[:scope])

        define_method "should_generate_new_#{attr_name}?" do
          send(attr_name).blank?
        end

        define_method "generate_new_#{attr_name}" do
          token_length = options.fetch(:length, DEFAULT_TOKEN_LENGTH)

          if alphabet = options[:alphabet]
            alphabet_array = case alphabet
            when :alphanumeric
              ALPHANUMERIC_ALPHABET
            when :alphabetic
              ALPHABETIC_ALPHABET
            when :numeric
              NUMERIC_ALPHABET
            else
              alphabet.split('')
            end
            (0...token_length).map{ alphabet_array.sample }.join
          else
            hex_length = (token_length / 2.0).ceil # 2 characters per length
            SecureRandom.hex(hex_length).slice(0...token_length)
          end
        end
      end

      def token_definitions
        @token_definitions ||= []
      end
    end

    def generate_tokens
      self.class.token_definitions.each do |td|
        if send("should_generate_new_#{td.attr_name}?")
          new_token = nil
          try_count = 0
          begin
            raise TooManyAttemptsError.new(td.attr_name, new_token) if try_count == 5
            new_token = send("generate_new_#{td.attr_name}")
            try_count += 1
          end until token_is_unique?(td, new_token)

          send "#{td.attr_name}=", new_token
        end
      end
    end

    def token_is_unique?(token_definition, token)
      attr_name  = token_definition.attr_name
      scope_attr = token_definition.scope_attr

      scope = self.class.where(attr_name => token)
      scope = scope.where.not(id: self.id) if self.persisted?
      scope = scope.where(scope_attr => read_attribute(scope_attr)) if scope_attr
      !scope.exists?
    end

  end
end

# Uncomment to auto-extend ActiveRecord, probably not a good idea
# ActiveRecord::Base.send(:extend, TokenAttr)
