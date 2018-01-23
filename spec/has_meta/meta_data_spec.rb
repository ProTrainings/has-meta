RSpec.describe HasMeta::MetaData do
  describe '.resolve_data_type' do
    
    context 'when passed an integer' do
      
      it 'returns correct type and value' do
        value = 12345
        expect(described_class.resolve_data_type(value)).to match_array([:integer, value])
      end
            
      context 'integer is too big' do
        it 'returns correct type and value' do
          value = 2000000001
          expect(described_class.resolve_data_type(value)).to match_array([:text, value.to_s])
        end
      end
    end
    
    context 'when passed a float' do
      it 'returns correct type and value' do
        value = 12.345
        expect(described_class.resolve_data_type(value)).to match_array([:decimal, value])
      end
    end
    
    context 'when passed a date' do
      it 'returns correct type and value' do
        value = Date.today
        expect(described_class.resolve_data_type(value)).to match_array([:date, value])
      end
    end
    
    context 'when passed text' do
      it 'returns correct type and value' do
        value = 'some text'
        expect(described_class.resolve_data_type(value)).to match_array([:text, value])
      end
      
      context 'integer string' do
        it 'returns correct type and value' do
          value = '12345'
          expect(described_class.resolve_data_type(value)).to match_array([:integer, value.to_i])
        end
      end
      
      context 'float string' do
        it 'returns correct type and value' do
          value = '12.345'
          expect(described_class.resolve_data_type(value)).to match_array([:decimal, value.to_f])
        end
      end
      
    end
    
  end
  
  describe '.generate_value_hash' do
    it 'returns a hash' do
      expect(described_class.generate_value_hash('foo').class).to eq(Hash)
    end
    
    it 'contains a key with the data type' do
      expect(described_class.generate_value_hash('foo').keys.first).to eq(:text_value)
    end
    
    it 'contains the value' do
      expect(described_class.generate_value_hash('foo').values.first).to eq('foo')
    end
  end
end