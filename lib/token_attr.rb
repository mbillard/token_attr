require 'token_attr/version'
require 'active_record'
require 'active_support/concern'

module TokenAttr
  extend ActiveSupport::Concern

  DEFAULT_TOKEN_LENGTH  = 8.freeze
  DEFAULT_SLUG_ALPHABET = [('a'..'z'),('A'..'Z'),(0..9)].map(&:to_a).flatten.freeze

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

      define_method "should_generate_new_#{attr_name}_token?" do
        send(attr_name).blank?
      end

      define_method "generate_new_#{attr_name}_token" do
        token_length = options.fetch(:length, DEFAULT_TOKEN_LENGTH)

        if alphabet = options[:alphabet]
          alphabet = DEFAULT_SLUG_ALPHABET if alphabet == :slug
          alphabet_array = alphabet.split('')
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
      if send("should_generate_new_#{attr_name}_token?")
        new_token = nil
        try_count = 0
        begin
          new_token = send("generate_new_#{attr_name}_token")
          try_count += 1
          raise TooManyAttemptsError.new(attr_name, new_token) if try_count == 5
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
