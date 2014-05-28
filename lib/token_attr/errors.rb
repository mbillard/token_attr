module TokenAttr

  class TooManyAttemptsError < StandardError
    attr_reader :attribute, :token

    def initialize(attr_name, token, message = nil)
      @attribute = attr_name
      @token = token
      message ||= "Can't generate unique token for \"#{attr_name}\". Last attempt with \"#{token}\"."
      super(message)
    end
  end

end
