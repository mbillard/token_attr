require 'token_attr/version'
require 'active_record'

module TokenAttr
  def token_attr(attr_name)
    token_attributes << attr_name

    before_validation :generate_tokens

    define_method "should_generate_new_#{attr_name}_token?" do
      send(attr_name).blank?
    end

    define_method "generate_tokens" do
      self.class.token_attributes.each do |attr_name|
        if send("should_generate_new_#{attr_name}_token?")
          token = SecureRandom.hex(8)
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
