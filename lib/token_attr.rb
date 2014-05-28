require 'token_attr/version'
require 'active_record'
require 'active_support/concern'

module TokenAttr
  extend ActiveSupport::Concern

  DEFAULT_TOKEN_LENGTH  = 8.freeze
  ALPHABETIC_ALPHABET   = [('a'..'z'),('A'..'Z')].map(&:to_a).flatten.freeze
  NUMERIC_ALPHABET      = [(0..9)].map(&:to_a).flatten.freeze
  ALPHANUMERIC_ALPHABET = [ALPHABETIC_ALPHABET, NUMERIC_ALPHABET].flatten.freeze

  class TooManyAttemptsError < StandardError
    attr_reader :attribute, :token

    def initialize(attr_name, token, message = nil)
      @attribute = attr_name
      @token = token
      message ||= "Can't generate unique token for \"#{attr_name}\". Last attempt with \"#{token}\"."
      super(message)
    end
  end

  included do
    before_validation :generate_tokens
  end

  module ClassMethods
    def token_attr(attr_name, options = {})
      token_attributes << attr_name

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

    def token_attributes
      @token_attributes ||= []
    end
  end

  def generate_tokens
    self.class.token_attributes.each do |attr_name|
      if send("should_generate_new_#{attr_name}?")
        new_token = nil
        try_count = 0
        begin
          raise TooManyAttemptsError.new(attr_name, new_token) if try_count == 5
          new_token = send("generate_new_#{attr_name}")
          try_count += 1
        end until token_is_unique?(attr_name, new_token)

        send "#{attr_name}=", new_token
      end
    end
  end

  def token_is_unique?(attr_name, token)
    scope = self.class.where(attr_name => token)
    scope = scope.where(id != self.id) if self.persisted?
    !scope.exists?
  end

end

# Uncomment to auto-extend ActiveRecord, probably not a good idea
# ActiveRecord::Base.send(:extend, TokenAttr)
