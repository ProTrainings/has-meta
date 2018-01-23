RSpec.describe HasMeta::MetaData do
  describe '.resolve_data_type' do
        
    context 'when passed an integer' do
      it 'coerces to text if too big' do
        expect(described_class.resolve_data_type 2000000001).to eq(:text)
      end
      
      it 'returns :integer' do
        expect(described_class.resolve_data_type 12345).to eq(:integer)
      end
    end
    
    context 'when passed a float' do
      it 'returns :decimal' do
        expect(described_class.resolve_data_type 12.345).to eq(:decimal)
      end
    end
    
    context 'when passed a date' do
      it 'returns :date' do
        expect(described_class.resolve_data_type Date.today).to eq(:date)
      end
    end
    
    context 'when passed text' do
      it 'coerces to integer if necessary' do
        expect(described_class.resolve_data_type '12345').to eq(:integer)
      end
      
      it 'coerces to float if necessary' do
        expect(described_class.resolve_data_type '12.345').to eq(:decimal)
      end
      
      it 'return :text' do
        expect(described_class.resolve_data_type 'some text').to eq(:text)
      end
    end
    
  end
end