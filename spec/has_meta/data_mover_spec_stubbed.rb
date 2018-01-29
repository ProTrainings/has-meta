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
      described_class.new('meta_models', 'name', 'foo_bar', 'text').execute
      expect(HasMeta::MetaData.all.count).to eq(MetaModel.all.count)
    end
    
    ('a'..'e').to_a.each_with_index do |n, i|
      it "#{i+1}: copies values to meta_data table successfully" do
        instance = MetaModel.find_by_name(n)
        expect(instance.name).to eq(instance.foo_bar)
      end  
    end
    
    it 'doesn\'t migrate null values' do
      clear_data!
      MetaModel.create
      described_class.new('meta_models', 'name', 'foo_bar', 'text').execute
      expect(HasMeta::MetaData.all.count).to eq(0)
    end
    
    it 'doesn\'t migrate empty strings' do
      clear_data!
      MetaModel.create name: ''
      described_class.new('meta_models', 'name', 'foo_bar', 'text').execute
      expect(HasMeta::MetaData.all.count).to eq(0)
    end
    
    it 'migrates an integer value' do
      instance = MetaModel.create age: 30
      described_class.new('meta_models', 'age', 'foo_bar', 'integer').execute
      expect(instance.age).to eq(instance.foo_bar)
    end
    
    it 'migrates a decimal value' do
      instance = MetaModel.create rating: 4.8
      described_class.new('meta_models', 'rating', 'foo_bar', 'decimal').execute
      expect(instance.rating).to eq(instance.foo_bar)
    end
    
    it 'migrates a date value' do
      instance = MetaModel.create date_of_birth: Date.yesterday
      described_class.new('meta_models', 'date_of_birth', 'foo_bar', 'date').execute
      expect(instance.date_of_birth).to eq(instance.foo_bar)
    end
    
  end
  
end

