RSpec.describe HasMeta::DataMover do
  describe '#execute' do

    def clear_data!
      MetaModel.all.destroy_all
      HasMeta::MetaData.all.destroy_all
    end
    
    it 'no meta models exist' do
      clear_data!
      expect(MetaModel.all.count).to eq(0)
    end
    
    it 'no meta data exists' do
      clear_data!
      expect(MetaModel.all.count).to eq(0)
    end
    
    
    it 'creates one meta data entry for each meta model' do
      a = MetaModel.create name: 'a'
      b = MetaModel.create name: 'b'
      c = MetaModel.create name: 'c'
      d = MetaModel.create name: 'd'
      e = MetaModel.create name: 'e'
      described_class.new('meta_models', 'name', 'text', 'foo_bar').execute
      expect(HasMeta::MetaData.all.count).to eq(MetaModel.all.count)
    end
    
    it 'doesn\'t migrate null values' do
      clear_data!
      MetaModel.create
      described_class.new('meta_models', 'name', 'text', 'foo_bar').execute
      expect(HasMeta::MetaData.all.count).to eq(0)
    end
    
    it 'doesn\'t migrate empty strings' do
      clear_data!
      MetaModel.create name: ''
      described_class.new('meta_models', 'name', 'text', 'foo_bar').execute
      expect(HasMeta::MetaData.all.count).to eq(0)
    end
    
    it 'migrates an integer value' do
      instance = MetaModel.create age: 30
      described_class.new('meta_models', 'age', 'integer', 'foo_bar').execute
      expect(instance.age).to eq(instance.foo_bar)
    end
    
    it 'migrates a decimal value' do
      instance = MetaModel.create rating: 4.8
      described_class.new('meta_models', 'rating', 'decimal', 'foo_bar').execute
      expect(instance.rating).to eq(instance.foo_bar)
    end
    
    it 'migrates a date value' do
      instance = MetaModel.create date_of_birth: Date.yesterday
      described_class.new('meta_models', 'date_of_birth', 'date', 'foo_bar').execute
      expect(instance.date_of_birth).to eq(instance.foo_bar)
    end
    
    it 'coerces type \'string\' to type \'text\'' do
      clear_data!
      instance = MetaModel.create name: 'example'
      described_class.new('meta_models', 'name', 'string', 'foo_bar').execute
      expect(instance.name).to eq(instance.foo_bar)
    end
    
  end
  
end

