RSpec.describe HasMeta::MetaData do
  describe '.resolve_data_type!' do
    
    context 'when passed an integer' do
      
      it 'returns correct type and value' do
        value = 12345
        expect(described_class.resolve_data_type!(value)).to match_array([:integer, value])
      end
            
      context 'integer is too big' do
        it 'returns correct type and value' do
          value = 2000000001
          expect(described_class.resolve_data_type!(value)).to match_array([:text, value.to_s])
        end
      end
    end
    
    context 'when passed a float' do
      it 'returns correct type and value' do
        value = 12.345
        expect(described_class.resolve_data_type!(value)).to match_array([:decimal, value])
      end
    end
    
    context 'when passed a date' do
      it 'returns correct type and value' do
        value = Date.today
        expect(described_class.resolve_data_type!(value)).to match_array([:date, value])
      end
    end
    
    context 'when passed text' do
      it 'returns correct type and value' do
        value = 'some text'
        expect(described_class.resolve_data_type!(value)).to match_array([:text, value])
      end
      
      context 'integer string' do
        it 'returns correct type and value' do
          value = '12345'
          expect(described_class.resolve_data_type!(value)).to match_array([:integer, value.to_i])
        end
      end
      
      context 'float string' do
        it 'returns correct type and value' do
          value = '12.345'
          expect(described_class.resolve_data_type!(value)).to match_array([:decimal, value.to_f])
        end
      end
      
    end
    
  end
  
  # This needs some updated tests
  describe '.generate_value_hash' do
    it 'returns a hash' do
      expect(described_class.generate_value_hash('foo').class).to eq(Hash)
    end
    
    context 'when passed a single value' do
      it 'contains a key with the data type' do
        expect(described_class.generate_value_hash('foo').keys.first).to eq(:text_value)
      end
    
      it 'contains the value' do
        expect(described_class.generate_value_hash('foo').values.first).to eq('foo')
      end
    end
    
    context 'when passed multiple values of same type' do
      it 'contains one key for data type' do
        expect(described_class.generate_value_hash('foo', 'bar').keys.count).to eq(1)
      end
      
      it 'contains an array of values for data type' do
        expect(described_class.generate_value_hash('foo', 'bar').values.first).to be_a(Array)
      end
      
      it 'contains correct values in array' do
        expect(described_class.generate_value_hash('foo', 'bar').values.first).to contain_exactly('foo', 'bar')
      end
    end
    
    context 'when passed multiple values of varying types' do
      it 'contains one key for each data type' do
        expect(described_class.generate_value_hash('foo', 'bar', 5).keys).to contain_exactly(:text_value, :integer_value)
      end
      
      it 'contains correct values for data type :text' do
        expect(described_class.generate_value_hash('foo', 'bar', 5)[:text_value]).to contain_exactly('foo', 'bar')
      end
      
      it 'contains correct values for data type :integer' do
        expect(described_class.generate_value_hash('foo', 'bar', 5)[:integer_value]).to eq(5)        
      end
    end
    
    context 'when passed an active record object' do
      target_model = TargetModel.create
      it 'returns data type :integer' do
        expect(described_class.generate_value_hash(target_model).keys).to contain_exactly(:integer_value)
      end
      it 'returns object\'s id' do
        expect(described_class.generate_value_hash(target_model)[:integer_value]).to eq(target_model.id)
        
      end
    end
  end
  
  describe '#set_attribute' do
    it 'sets the attribute to the given value' do
      value = 'some text'
      instance = described_class.new value: value
      instance.send(:set_attribute)
      expect(instance.text_value).to eq(value)
    end
    
  end
end