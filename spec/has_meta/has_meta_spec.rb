RSpec.describe HasMeta do
  it "has a version number" do
    expect(HasMeta::VERSION).not_to be nil
  end
  
  describe '#respond_to?' do
    it 'doesn\'t respond to and unknown getter' do
      model = MetaModel.new
      expect(model.respond_to? :target_models).to be false
    end
    
    context 'an attribute representing active record model' do
      it 'responds to getter' do
        model = MetaModel.new
        expect(model.respond_to? :target_model).to be true
      end

      it 'responds to setter' do
        model = MetaModel.new
        expect(model.respond_to? :target_model=).to be true
      end
      
      it 'responds to getter with _id suffix' do
        model = MetaModel.new
        expect(model.respond_to? :target_model_id).to be true
      end

      it 'responds to setter with _id suffix' do
        model = MetaModel.new
        expect(model.respond_to? :target_model_id=).to be true
      end
    end

    context 'a normal attribute with _id suffix' do
      it 'responds to getter' do
        model = MetaModel.new
        expect(model.respond_to? :foo_id).to be true
      end

      it 'responds to setter' do
        model = MetaModel.new
        expect(model.respond_to? :foo_id=).to be true
      end

      it 'doesn\'t respond to foo setter (like active record model attrs)' do
        model = MetaModel.new
        expect(model.respond_to? :foo=).to be false
      end

      it 'doesn\'t respond to foo getter (like active record model attrs)' do
        model = MetaModel.new
        expect(model.respond_to? :foo).to be false
      end
    end

    context 'a normal attribute' do
      it 'responds to setter' do
        model = MetaModel.new
        expect(model.respond_to? :foo_bar=).to be true
      end

      it 'responds to getter' do
        model = MetaModel.new
        expect(model.respond_to? :foo_bar).to be true
      end
  
      it 'doesn\'t respond to foo_bar_id getter (like active record model attrs)' do
        model = MetaModel.new
        expect(model.respond_to? :foo_bar_id).to be false
      end
  
      it 'doesn\'t respond to foo_bar_id setter (like active record model attrs)' do
        model = MetaModel.new
        expect(model.respond_to? :foo_bar_id=).to be false
      end
    end
  end
  
  describe '.respond_to?' do
    it 'responds to find_by_target_model_id' do
      expect(MetaModel.respond_to? :find_by_target_model_id).to be true
    end

    it 'doesn\'t respond to find_by_target_model' do
      expect(MetaModel.respond_to? :find_by_target_model).to be false
    end

    it 'responds to find_by_foo_id' do
      expect(MetaModel.respond_to? :find_by_foo_id).to be true
    end

    it 'doesn\'t respond to find_by_foo' do
      expect(MetaModel.respond_to? :find_by_foo).to be false
    end

    it 'responds to find_by_foo_bar' do
      expect(MetaModel.respond_to? :find_by_foo_bar).to be true
    end
  end
  
  describe '#method_missing' do
    it 'doesn\'t allow an unknown attribute setter' do
      model = MetaModel.create name: "Example"
      expect{model.non_existent_attribute = 0}.to raise_exception(NoMethodError)
    end
    context 'normal attribute \'foo_bar\'' do
      instance = MetaModel.create name: "Example"
      it 'allows setter' do
        expect(instance.foo_bar = 'test string').to be_truthy
      end
      it 'allows getter' do
        expect(instance.foo_bar).to be_truthy
      end
    end
    context 'normal attribute ending in _id' do
      instance = MetaModel.create name: "Example"
      it 'allows setter' do
        expect(instance.foo_id = 'test string').to be_truthy
      end
      it 'allows getter' do
        expect(instance.foo_id).to be_truthy
      end
    end
    context 'attribute representing active record model' do
      instance = MetaModel.create name: "Example"
      target_instance = TargetModel.create name: "Example"
      context 'when passed attribute name' do
        it 'allows a setter' do
          expect(instance.target_model = target_instance).to be_truthy
        end
        it 'allows a getter' do
          expect(instance.target_model).to be_truthy
        end
      end
      context 'when passed \'attribute + _id \'' do
        it 'allows a setter' do
          expect(instance.target_model_id = target_instance.id).to be_truthy
        end
        it 'allows a getter' do
          expect(instance.target_model_id).to be_truthy
        end
      end
    end
  end
  
  describe '.method_missing' do
    context 'find_by_#{attribute} dynamic class method' do
      it 'doesn\'t allow an unknown attribute getter' do
        expect{MetaModel.find_by_non_existent_attribute 0}.to raise_exception(NoMethodError)
      end
      
      it 'allows a normal attribute getter' do
        expect(MetaModel.find_by_foo_bar 0).to be_truthy
      end
      
      it 'allows a normal getter for attribute ending in _id' do
        expect(MetaModel.find_by_foo_id 0).to be_truthy
      end
      
      context 'attribute representing active record model' do
        it 'doesn\'t allow a getter for find_by_#{attribute}' do
          expect{MetaModel.find_by_target_model 0}.to raise_exception(NoMethodError)
        end
        it 'allows getter for find_by_#{attribute}_id' do
          expect(MetaModel.find_by_target_model_id 0).to be_truthy
        end
      end
    end
  end
  
end
