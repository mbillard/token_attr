require 'token_attr/version'
require 'active_record'

module TokenAttr
  DEFAULT_TOKEN_LENGTH = 8

  def token_attr(attr_name, options = {})
    token_attributes << attr_name

    before_validation :generate_tokens

    define_method "should_generate_new_#{attr_name}_token?" do
      send(attr_name).blank?
    end

    define_method "generate_tokens" do
      self.class.token_attributes.each do |attr_name|
        if send("should_generate_new_#{attr_name}_token?")
          token_length = options.fetch(:length, DEFAULT_TOKEN_LENGTH)
          hex_length = (token_length / 2.0).ceil # 2 characters per length

          token = SecureRandom.hex(hex_length).slice(0...token_length)
          send "#{attr_name}=", token
        end

        true
      end
    end
  end

  def token_attributes
    @token_attributes ||= []
  end
end

# Uncomment to auto-extend ActiveRecord, probably not a good idea
# ActiveRecord::Base.send(:extend, TokenAttr)
