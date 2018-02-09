RSpec.describe 'Backwards Compatability' do
  before :all do
    HasMeta::MetaData.class_eval do
      def self.has_datetime_column?
        false
      end
    end
  end
  describe HasMeta do
    context 'when datetime_value column isn\'t present' do
      before :each do
        @instance = MetaModel.create
        @value = Time.now
        @instance.foo_bar = @value
      end

      it 'saves a time value as text' do
        expect(@instance.meta_data.first.text_value).to eq(@value.to_s)
      end

      it 'returns a time value' do
        expect(@instance.foo_bar.acts_like? :time).to be true
      end
    end
  end
end

