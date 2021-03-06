require 'spec_helper'

describe TokenAttr do

  class Model < BaseModel
    token_attr :token
  end

  class ModelWithLength < BaseModel
    token_attr :token, length: 13
  end

  class ModelWithAlphabet < BaseModel
    token_attr :token, alphabet: 'abc123'
  end

  class ModelWithAlphanumericAlphabet < BaseModel
    token_attr :token, alphabet: :alphanumeric
  end

  class ModelWithAlphabeticAlphabet < BaseModel
    token_attr :token, alphabet: :alphabetic
  end

  class ModelWithNumericAlphabet < BaseModel
    token_attr :token, alphabet: :numeric
  end

  class ModelWithWords < BaseModel
    token_attr :token, alphabet: :words
  end

  class ModelWithWordsAndLength < BaseModel
    token_attr :token, alphabet: :words, length: 4
  end

  class ModelWithMultipleTokens < BaseModel
    token_attr :token
    token_attr :private_token
  end

  class ModelWithOverride < BaseModel
    token_attr :token

    def should_generate_new_token?
      token == '1234'
    end
  end

  class ModelWithScope < BaseModel
    token_attr :token, scope: :scope_id
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
          fake_alphabet('TokenAttr::ALPHANUMERIC_ALPHABET', times: 8, sample: 'T')

          model = ModelWithAlphanumericAlphabet.new
          model.valid?
          model.token.should == 'TTTTTTTT'
        end

        it "generates a token with alphabetic characters when the alphabet is :alphabetic" do
          fake_alphabet('TokenAttr::ALPHABETIC_ALPHABET', times: 8, sample: 't')

          model = ModelWithAlphabeticAlphabet.new
          model.valid?
          model.token.should == 'tttttttt'
        end

        it "generates a token with numeric characters when the alphabet is :numeric" do
          fake_alphabet('TokenAttr::NUMERIC_ALPHABET', times: 8, sample: '0')

          model = ModelWithNumericAlphabet.new
          model.valid?
          model.token.should == '00000000'
        end

        it "generates a token with 3 words from the words bank when the alphabet is :words" do
          model = ModelWithWords.new
          model.valid?
          model.token.should_not be_blank
        end

        it "generates a token with 3 words when the alphabet is :words" do
          stub_const('TokenAttr::WORDS_BANK', ['Word', 'Word'])

          model = ModelWithWords.new
          model.valid?
          model.token.should == 'WordWordWord'
        end

        it "generates a token with the number of words specified by length when the alphabet is :words" do
          stub_const('TokenAttr::WORDS_BANK', ['Word', 'Word'])

          model = ModelWithWordsAndLength.new
          model.valid?
          model.token.should == 'WordWordWordWord'
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

    context "when the should_generate_new_[attr_name]? method is overridden" do
      let(:model) { ModelWithOverride.new }

      it "generates a token when the condition is satisfied" do
        SecureRandom.should_receive(:hex).with(4).and_return('newtoken')
        model.token = '1234'
        model.valid?
        model.token.should == 'newtoken'
      end

      it "does not generate a new token when the condition is not satisfied" do
        model.valid?
        model.token.should be_nil
      end
    end

    context "with scope" do
      let(:model) { ModelWithScope.new }

      context "when the scope attributes are different" do
        it "allows duplicate tokens" do
          SecureRandom.should_receive(:hex).twice.with(4).and_return('12345678')
          ModelWithScope.create(scope_id: 1)
          model.scope_id = 2
          model.valid?
          model.token.should == '12345678'
        end
      end

      context "when the scope attributes are the same" do
        it "regenerates a duplicate token" do
          SecureRandom.should_receive(:hex).twice.with(4).and_return('12345678')
          SecureRandom.should_receive(:hex).once.with(4).and_return('asdfghjk')
          ModelWithScope.create(scope_id: 1)
          model.scope_id = 1
          model.valid?
          model.token.should == 'asdfghjk'
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

  protected

  def fake_alphabet(alphabet_const, times: 8, sample: 'T')
    fake = double('Array')
    fake.stub(:split).and_return(fake)
    fake.should_receive(:sample).exactly(times).times.and_return(sample)
    stub_const(alphabet_const, fake)
  end
end
