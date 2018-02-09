RSpec.describe HasMeta do
  it "has a version number" do
    expect(HasMeta::VERSION).not_to be nil
  end
  
  describe '#respond_to?' do
    it 'doesn\'t respond to and unknown getter' do
      model = MetaModel.new
      expect(model).not_to respond_to(:target_models)
    end
    
    context 'an attribute representing active record model' do
      it 'responds to getter' do
        model = MetaModel.new
        expect(model).to respond_to(:target_model)
      end

      it 'responds to setter' do
        model = MetaModel.new
        expect(model).to respond_to(:target_model=)
      end
      
      it 'responds to getter with _id suffix' do
        model = MetaModel.new
        expect(model).to respond_to(:target_model_id)
      end

      it 'responds to setter with _id suffix' do
        model = MetaModel.new
        expect(model).to respond_to(:target_model_id=)
      end
    end

    context 'a normal attribute with _id suffix' do
      it 'responds to getter' do
        model = MetaModel.new
        expect(model).to respond_to(:foo_id)
      end

      it 'responds to setter' do
        model = MetaModel.new
        expect(model).to respond_to(:foo_id=)
      end

      it 'doesn\'t respond to foo setter (like active record model attrs)' do
        model = MetaModel.new
        expect(model).not_to respond_to(:foo=)
      end

      it 'doesn\'t respond to foo getter (like active record model attrs)' do
        model = MetaModel.new
        expect(model).not_to respond_to(:foo)
      end
    end

    context 'a normal attribute' do
      it 'responds to setter' do
        model = MetaModel.new
        expect(model).to respond_to(:foo_bar=)
      end

      it 'responds to getter' do
        model = MetaModel.new
        expect(model).to respond_to(:foo_bar)
      end
  
      it 'doesn\'t respond to foo_bar_id getter (like active record model attrs)' do
        model = MetaModel.new
        expect(model).not_to respond_to(:foo_bar_id)
      end
  
      it 'doesn\'t respond to foo_bar_id setter (like active record model attrs)' do
        model = MetaModel.new
        expect(model).not_to respond_to(:foo_bar_id=)
      end
    end
    
    describe 'meta attribute inheritance' do
      
      context 'a subclass' do
        subclass = SubMetaModel.new
        it 'responds to it\'s ancestors\'s meta attribute getter' do
          expect(subclass).to respond_to(:foo_bar)
        end
      
        it 'responds to it\'s own meta attribute getter' do
          expect(subclass).to respond_to(:bar)
        end
      end
      
      context 'a superclass' do
        superclass = MetaModel.new
        it 'doesn\'t respond to it\'s subclass\' meta attribute getter' do
          expect(superclass).not_to respond_to(:bar)
        end
      
        it 'responds to it\'s own meta attribute getter' do
          expect(superclass).to respond_to(:foo_bar)
        end
      end
    end
  end
  
  describe '.respond_to?' do
    it 'responds to find_by_target_model_id' do
      expect(MetaModel).to respond_to(:find_by_target_model_id)
    end

    it 'doesn\'t respond to find_by_target_model' do
      expect(MetaModel).not_to respond_to(:find_by_target_model)
    end

    it 'responds to find_by_foo_id' do
      expect(MetaModel).to respond_to(:find_by_foo_id)
    end

    it 'doesn\'t respond to find_by_foo' do
      expect(MetaModel).not_to respond_to(:find_by_foo)
    end

    it 'responds to find_by_foo_bar' do
      expect(MetaModel).to respond_to(:find_by_foo_bar)
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
  
  describe 'dynamic getters and setters' do
    
    context 'normal attribute \'foo_bar\'' do

      instance = MetaModel.create name: "Example"
      value = 'test string'
      
      describe 'setter' do
        it 'increases count by 1' do
          expect{instance.foo_bar = value}.to change{HasMeta::MetaData.all.count}.by(1)
        end
          
        it 'creates associated record' do
          expect(HasMeta::MetaData.where key: :foo_bar, meta_model_type: instance.class, meta_model_id: instance.id ).not_to be_empty
        end
      end
      
      describe 'getter' do
        it 'returns correct value' do
          expect(instance.foo_bar).to eq(value)
        end
      end
      
      describe 're-setting value' do
        new_value = 'new test string'
        it 'doesn\'t create a new record' do
          expect{instance.foo_bar = new_value}.not_to change{HasMeta::MetaData.all.count}
        end
        
        it 'changes value' do
          expect(instance.foo_bar).to eq(new_value)
        end
      end

      describe 'setting value to nil' do
        it 'removes record' do
          instance.foo_bar = nil
          expect(instance.meta_data.where key: :foo_bar).to be_empty
        end
      end
      
    end
    
    context 'normal attribute with _id suffix' do
      
      instance = MetaModel.create name: "Example"
      value = 'another test string'
      
      describe 'setter' do
        it 'increases count by 1' do
          expect{instance.foo_id = value}.to change{HasMeta::MetaData.all.count}.by(1)
        end
          
        it 'creates associated record' do
          expect(HasMeta::MetaData.where key: :foo_id, meta_model_type: instance.class, meta_model_id: instance.id ).not_to be_empty
        end
      end
      
      describe 'getter' do
        it 'returns correct value' do
          expect(instance.foo_id).to eq(value)
        end
      end
      
      describe 're-setting value' do
        
        new_value = 'another new test string'
        
        it 'doesn\'t create a new record' do
          expect{instance.foo_id = new_value}.not_to change{HasMeta::MetaData.all.count}
        end
        
        it 'changes value' do
          expect(instance.foo_id).to eq(new_value)
        end
      end
      
    end
    
    context 'attribute representing active record model' do
    
      instance = MetaModel.create name: "Example"
      target_instance = TargetModel.create name: "Example"
      
      context 'without _id suffix' do
        describe 'setter' do
          it 'increases count by 1' do
            expect{instance.target_model = target_instance}.to change{HasMeta::MetaData.all.count}.by(1)
          end
          
          it 'creates associated record under key :target_model_id' do
            expect(HasMeta::MetaData.where key: :target_model_id, meta_model_type: instance.class, meta_model_id: instance.id ).not_to be_empty
          end
        end
      
        describe 'getter' do
          it 'returns correct value' do
            expect(instance.target_model).to eq(target_instance)
          end
        end        
      end

      new_target_instance = TargetModel.create name: "Example"
      
      describe 'setter with _id suffix' do
        
        it 'doesn\'t create a new record' do
          expect{instance.target_model_id = new_target_instance.id}.not_to change{HasMeta::MetaData.all.count}
        end
        
      end
      
      describe 'getter with _id suffix' do
        it 'doesn\'t return old value' do
          expect(instance.target_model).not_to eq(target_instance)
        end
        
        it 'returns the new value' do
          expect(instance.target_model).to eq(new_target_instance)
        end
        
        it 'returns an id integer' do
          expect(instance.target_model_id).to be_a(Integer)
        end
        
        it 'returns the correct value' do
          expect(instance.target_model_id).to eq(new_target_instance.id)
        end
        
      end
    
    end

  end
  
  describe 'dynamic class method getters (find_by_x)' do

    context 'normal attribute \'foo_bar\'' do

      before :context do
        @instance = MetaModel.create name: "Example"
        @value = 1
        @instance.foo_bar = @value  
      end
      
      it 'returns an array' do
        expect(MetaModel.find_by_foo_bar @value).to be_a(Array)
      end
      
      it 'array contains MetaModel instance' do
        expect(MetaModel.find_by_foo_bar @value).to contain_exactly(@instance)
      end
      
      it 'returns multiple matches' do
        another_instance = MetaModel.create name: "Example"
        another_instance.foo_bar = @value
        expect(MetaModel.find_by_foo_bar @value).to contain_exactly(@instance, another_instance)
      end
    end
    
    context 'normal attribute with _id suffix' do
      before :context do
        @instance = MetaModel.create name: "Example"
        @value = 1
        @instance.foo_id = @value
      end
      
      it 'returns an array' do
        expect(MetaModel.find_by_foo_id @value).to be_a(Array)
      end
      
      it 'array contains MetaModel instance' do
        expect(MetaModel.find_by_foo_id @value).to contain_exactly(@instance)
      end
      
      it 'returns multiple matches' do
        another_instance = MetaModel.create name: "Example"
        another_instance.foo_id = @value
        expect(MetaModel.find_by_foo_id @value).to contain_exactly(@instance, another_instance)
      end
    end

    context 'attribute representing an active record model' do
      before :context do
        @instance = MetaModel.create name: "Example"
        @target_instance = TargetModel.create name: "Example"
        @instance.target_model = @target_instance
      end
      
      it 'returns an array' do
        expect(MetaModel.find_by_target_model_id @target_instance.id).to be_a(Array)
      end
      
      it 'array contains MetaModel instance' do
        expect(MetaModel.find_by_target_model_id @target_instance.id).to contain_exactly(@instance)
      end
      
      it 'returns multiple matches' do
        another_instance = MetaModel.create name: "Example"
        another_instance.target_model = @target_instance
        expect(MetaModel.find_by_target_model_id @target_instance.id).to contain_exactly(@instance, another_instance)
      end
    end
 
  end
  
  describe '.with_meta' do
    it 'returns an active record relation' do
      expect(MetaModel.with_meta foo_bar: 'example').to be_a(ActiveRecord::Relation)
    end
    
    it 'returns items specified' do
      a = MetaModel.create
      b = MetaModel.create
      a.foo_bar = 5
      b.foo_bar = 5
      
      expect(MetaModel.with_meta foo_bar: 5).to contain_exactly(a, b)
    end
    
    it 'doesn\'t return equal values from other keys' do
      a = MetaModel.create
      b = MetaModel.create
      a.foo_bar = 6
      b.foo_id = 6
      
      expect(MetaModel.with_meta foo_bar: 6).to contain_exactly(a)
    end
    
    it 'accepts multiple arguments' do
      a = MetaModel.create
      b = MetaModel.create
      a.update_attributes foo_bar: 'some text', foo_id: 5
      b.update_attributes foo_bar: 'some other text', foo_id: 5

      expect(MetaModel.with_meta foo_bar: ['some text', 'some other text', 9], foo_id: 5).to contain_exactly(a, b)
    end
    
    context 'when passed active record object' do
      
      it 'returns items specified' do
        a = MetaModel.create
        c = TargetModel.create
        a.target_model = c
        expect(MetaModel.with_meta target_model: c).to contain_exactly(a)
        
      end
    end
    
    it 'accepts :any option' do
      a = MetaModel.create
      b = MetaModel.create
      a.update_attributes foo_bar: 'pick me'
      b.update_attributes foo_id: 7
      
      expect(MetaModel.with_meta({foo_bar: 'pick me', foo_id: 7}, any: true)).to contain_exactly(a,b)
    end
    
  end
  
  describe '.excluding_meta' do
    it 'returns and active record relation' do 
      expect(MetaModel.excluding_meta foo_bar: 'example').to be_a(ActiveRecord::Relation)
    end
    
    context 'when passed an object' do
      it 'doesn\'t return items specified' do
        a = MetaModel.create
        b = MetaModel.create
        c = TargetModel.create
        a.target_model = c
        b.target_model = c
      
        expect(MetaModel.excluding_meta target_model: c).not_to include(a, b)
      end
    
    end
    
    context 'when passed an attribute name' do
      it 'doesn\'t return items specified' do
        a = MetaModel.create
        b = MetaModel.create
        c = TargetModel.create
        a.target_model = c
        b.target_model = c
      
        expect(MetaModel.excluding_meta target_model_id: c.id).not_to include(a, b)
      end
      
    end
  
  end

  describe 'getting and setting meta attributes' do
    context 'when given a date' do
      before :context do
        @instance = MetaModel.create
        @value = Date.today
        @instance.foo_bar = @value
      end

      it 'it returns a date' do
        expect(@instance.foo_bar).to be_a(Date)
      end

      context 'that\'s stringy' do
        before :context do
          @instance = MetaModel.create
          @value = Date.today.to_s
          @instance.foo_bar = @value
        end

        it 'it returns a date' do
          expect(@instance.foo_bar).to be_a(Date)
        end
      end
    end
    
    context 'when date is stored as text' do
      before :context do
        @instance = MetaModel.create
        @value = Date.today.to_s
        @instance.meta_data.create key: :foo_bar, text_value: @value
      end

      it 'is stored as text' do
        expect(@instance.meta_data.where(key: :foo_bar).first.text_value).to eq(@value)
      end

      it 'isn\'t stored as date' do
        expect(@instance.meta_data.where(key: :foo_bar).first.date_value).to be_nil
      end

      it 'it returns a date' do
        expect(@instance.foo_bar).to be_a(Date)
      end
    end

    context 'when given an integer' do
      before :context do
        @instance = MetaModel.create
        @value = 12345
        @instance.foo_bar = @value
      end

      it 'it returns a integer' do
        expect(@instance.foo_bar).to be_a(Integer)
      end

    end

    context 'when given a stringy integer' do
      before :context do
        @instance = MetaModel.create
        @value = '12345'
        @instance.foo_bar = @value
      end

      it 'it returns a integer' do
        expect(@instance.foo_bar).to be_a(Integer)
      end

    end
    
    context 'when given a large integer' do
      before :context do
        @instance = MetaModel.create
        @value = 2000000001
        @instance.foo_bar = @value
      end

      it 'it returns a integer' do
        expect(@instance.foo_bar).to be_a(Integer)
      end


      context 'that\'s stringy' do
        before :context do
          @instance = MetaModel.create
          @value = '2000000001'
          @instance.foo_bar = @value
        end

        it 'it returns a integer' do
          expect(@instance.foo_bar).to be_a(Integer)
        end

      end

    end

    context 'when given a time' do
      before :context do
        @instance = MetaModel.create
        @value = Time.now
        @instance.foo_bar = @value
      end

      it 'it returns a time' do
        expect(@instance.foo_bar.acts_like? :time).to be true
      end

    end

    context 'when a time is stored as text' do
      before :context do
        @instance = MetaModel.create
        @value = Time.now.to_s
        @instance.meta_data.create key: :foo_bar, text_value: @value
      end

      it 'is stored as text' do
        expect(@instance.meta_data.where(key: :foo_bar).first.text_value).to eq(@value)
      end

      it 'isn\'t stored as datetime' do
        expect(@instance.meta_data.where(key: :foo_bar).first.datetime_value).to be_nil
      end

      it 'it returns a time' do
        expect(@instance.foo_bar.acts_like? :time).to be true
      end
    end

    context 'when given a float' do
      before :context do
        @instance = MetaModel.create
        @value = 12.345
        @instance.foo_bar = @value
      end

      it 'it returns a big decimal' do
        expect(@instance.foo_bar).to be_a(BigDecimal)
      end

      context 'that\'s stringy' do
        before :context do
          @instance = MetaModel.create
          @value = '12.345'
          @instance.foo_bar = @value
        end

        it 'it returns a big decimal' do
          expect(@instance.foo_bar).to be_a(BigDecimal)
        end
        
      end

    end

  end

  describe '.meta_set' do
    context 'when passed :as option' do
      before :each do
        @instance = MetaModel.create
        @value = Time.now.to_s
        @instance.meta_set :foo_bar, @value, as: :text
      end

      subject {@instance.meta_data.first}

      it 'is stored as text' do
        expect(subject.text_value).to eq(@value)
      end

      it 'isn\'t stored as datetime' do
        expect(subject.datetime_value).to be_nil
      end
    end
  end
  
end
