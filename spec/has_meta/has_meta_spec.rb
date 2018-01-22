RSpec.describe HasMeta do
  it "has a version number" do
    expect(HasMeta::VERSION).not_to be nil
  end
  binding.pry
  @model = MetaModel.new

  it 'responds to target_model getter' do
    expect(@model.respond_to? :target_model).to be_truthy
  end

  it 'responds to target_model setter' do
    expect(@model.respond_to? :target_model=).to be_truthy
  end

  it 'doesn\'t respond to target_models getter' do
    expect(@model.respond_to? :target_models).not_to be_truthy
  end

  # Change automatic addtion of "_id" to look at foregin key name
  it 'responds to target_model_id getter' do
    expect(@model.respond_to? :target_model_id).to be_truthy
  end

  it 'responds to target_model_id setter' do
    expect(@model.respond_to? :target_model_id=).to be_truthy
  end

  it 'responds to foo_id getter' do
    expect(@model.respond_to? :foo_id).to be_truthy
  end

  it 'responds to foo_id setter' do
    expect(@model.respond_to? :foo_id=).to be_truthy
  end

  it 'doesn\'t respond to foo setter' do
    expect(@model.respond_to? :foo=).not_to be_truthy
  end

  it 'doesn\'t respond to foo getter' do
    expect(@model.respond_to? :foo).not_to be_truthy
  end

  it 'responds to foo_bar setter' do
    expect(@model.respond_to? :foo_bar=).to be_truthy
  end

  it 'responds to foo_bar getter' do
    expect(@model.respond_to? :foo_bar).to be_truthy
  end

  it 'responds to find_by_target_model_id' do
    expect(MetaModel.respond_to? :find_by_target_model_id).to be_truthy
  end

  it 'doesn\'t respond to find_by_target_model' do
    expect(MetaModel.respond_to? :find_by_target_model).not_to be_truthy
  end

  it 'responds to find_by_foo_id' do
    expect(MetaModel.respond_to? :find_by_foo_id).to be_truthy
  end

  it 'doesn\'t respond to find_by_foo' do
    expect(MetaModel.respond_to? :find_by_foo).not_to be_truthy
  end

  it 'responds to find_by_foo_bar' do
    expect(MetaModel.respond_to? :find_by_foo_bar).to be_truthy
  end
  
end
