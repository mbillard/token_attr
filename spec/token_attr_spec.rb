require 'spec_helper'

describe TokenAttr do

  class Model < ActiveRecord::Base
    include TokenAttr
    token_attr :token
  end

  class ModelWithLength < ActiveRecord::Base
    self.table_name = 'models'
    include TokenAttr
    token_attr :token, length: 13
  end

  class ModelWithAlphabet < ActiveRecord::Base
    self.table_name = 'models'
    include TokenAttr
    token_attr :token, alphabet: 'abc123'
  end

  class ModelWithSlugAlphabet < ActiveRecord::Base
    self.table_name = 'models'
    include TokenAttr
    token_attr :token, alphabet: :alphanumeric
  end

  class ModelWithMultipleTokens < ActiveRecord::Base
    self.table_name = 'models'
    include TokenAttr
    token_attr :token
    token_attr :private_token
  end

  describe ".token_attr" do
    let(:model) { Model.new }

    context "when token is blank" do
      before { model.token = '' }

      it "generates a token on validation" do
        model.valid?
        model.token.should_not be_blank
      end

      it "generates a token of the default length" do
        stub_const('TokenAttr::DEFAULT_TOKEN_LENGTH', 4)
        model.valid?
        model.token.length.should == 4
      end

      it "generates a unique token" do
        SecureRandom.should_receive(:hex).twice.with(4).and_return('12345678')
        SecureRandom.should_receive(:hex).once.with(4).and_return('abcdefgh')
        existing_model = Model.create
        model.valid?
        model.token.should == 'abcdefgh'
      end

      it "raises an exception if it can't find a unique token" do
        SecureRandom.should_receive(:hex).exactly(5 + 1).times.with(4).and_return('12345678')
        existing_model = Model.create
        expect{ model.valid? }.to raise_error(TokenAttr::TooManyAttemptsError)
      end

      context "when length is specified" do
        let(:model) { ModelWithLength.new }

        it "generates a token of the specified length" do
          model.valid?
          model.token.length.should == 13
        end
      end

      context "when an alphabet is specified" do
        let(:model) { ModelWithAlphabet.new }

        it "generates a token with characters from that alphabet" do
          model.valid?
          model.token.split('').all? do |c|
            'abc123'.include?(c)
          end.should be_true
        end

        it "generates a token of the default length even if lower than the alphabet" do
          stub_const('TokenAttr::DEFAULT_TOKEN_LENGTH', 12)
          model.valid?
          model.token.length.should == 12
        end

        it "generates a token with alphanumeric characters when the alphabet is :alphanumeric" do
          fake_alphabet = double('String')
          fake_alphabet.stub(:split).and_return(fake_alphabet)
          fake_alphabet.should_receive(:sample).exactly(8).times.and_return('T')
          stub_const('TokenAttr::ALPHANUMERIC_ALPHABET', fake_alphabet)

          model = ModelWithSlugAlphabet.new
          model.valid?
          model.token.should == 'TTTTTTTT'
        end
      end

      context "when the model has multiple tokens" do
        let(:model) { ModelWithMultipleTokens.new }

        it "generates each token" do
          model.valid?
          model.token.should_not         be_blank
          model.private_token.should_not be_blank
        end
      end
    end

    context "when token is not blank" do
      before { model.token = 'not blank' }

      it "does not generate a token on validation" do
        model.valid?
        model.token.should == 'not blank'
      end
    end
  end

end
