require 'token_attr/version'
require 'active_record'
require 'active_support/concern'

module TokenAttr
  extend ActiveSupport::Concern

  DEFAULT_TOKEN_LENGTH  = 8.freeze
  DEFAULT_SLUG_ALPHABET = [('a'..'z'),('A'..'Z'),(0..9)].map(&:to_a).flatten.freeze

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
        send "#{attr_name}=", send("generate_new_#{attr_name}_token")
      end
    end
  end

end

# Uncomment to auto-extend ActiveRecord, probably not a good idea
# ActiveRecord::Base.send(:extend, TokenAttr)
