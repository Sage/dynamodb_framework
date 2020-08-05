require 'spec_helper'

RSpec.describe DynamoDbFramework::TableManager do

  let(:store) do
    DynamoDbFramework::Store.new({ endpoint: DYNAMODB_STORE_ENDPOINT, aws_region: 'eu-west-1' })
  end

  subject do
    DynamoDbFramework::TableManager.new(store)
  end

  attributes_builder = DynamoDbFramework::AttributesBuilder.new

  before do
    attributes_builder = DynamoDbFramework::AttributesBuilder.new
    attributes_builder.add(:id, :S)

    subject.create('update_throughput', attributes_builder.attributes, :id)

    subject.create('add_index', attributes_builder.attributes, :id)
  end

  it 'can create, check exists & drop tables' do

    exists = subject.exists?('create_drop_test')

    if exists
      subject.drop('create_drop_test')
    end

    subject.create('create_drop_test', attributes_builder.attributes, :id)

    subject.drop('create_drop_test')
  end

  it 'can create a table with a hash key and a range key' do

    exists = subject.exists?('dual_key')

    if exists
      subject.drop('dual_key')
    end

    subject.create('dual_key', attributes_builder.attributes, :id)

    subject.drop('dual_key')

  end

  it 'can create a table with a global secondary index' do

    exists = subject.exists?('index_test')

    if exists
      subject.drop('index_test')
    end

    global_indexes = []
    index1 = subject.create_global_index('index1', :name, :number)
    global_indexes.push(index1)

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:id, :S)
    builder.add(:name, :S)
    builder.add(:number, :N)

    subject.create('index_test', builder.attributes, :id, nil, 20, 10, global_indexes)

    subject.drop('index_test')

  end

  it 'can update the throughput of a table' do

    subject.update_throughput('update_throughput', 30, 30)

  end

  it 'can add a global index to an existing table' do

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:id, :S)
    builder.add(:name, :S)

    index = subject.create_global_index('new_index', :name, nil)
    subject.add_index('add_index', builder.attributes, index)

    has_index = subject.has_index?('add_index', 'new_index')

    expect(has_index).to eq(true)

  end

  it 'can update the throughput of a global secondary index' do

    exists = subject.exists?('update_index_throughput_test')

    if exists
      subject.drop('update_index_throughput_test')
    end

    global_indexes = []
    index1 = subject.create_global_index('index1', :name, :number)
    global_indexes.push(index1)

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:id, :S)
    builder.add(:name, :S)
    builder.add(:number, :N)

    subject.create('update_index_throughput_test', builder.attributes, :id, nil, 20, 10, global_indexes)

    subject.update_index_throughput('update_index_throughput_test', 'index1', 50, 50)

    subject.drop('update_index_throughput_test')

  end

  it 'can update the TTL attribute' do

    exists = subject.exists?('update_ttl_test')

    if exists
      subject.drop('update_ttl_test')
    end

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:ttl_date, :N)

    subject.create('update_ttl_test', builder.attributes, :ttl_date)

    subject.update_ttl_attribute('update_ttl_test', true, 'ttl_date')

    expect(subject.get_ttl_status('update_ttl_test')['time_to_live_status']).to eq('ENABLED')

    subject.drop('update_ttl_test')

  end

  it 'can disable the TTL attribute' do

    exists = subject.exists?('update_ttl_test')

    if exists
      subject.drop('update_ttl_test')
    end

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:ttl_date, :N)

    subject.create('update_ttl_test', builder.attributes, :ttl_date)

    subject.update_ttl_attribute('update_ttl_test', true, 'ttl_date')

    subject.update_ttl_attribute('update_ttl_test', false, 'ttl_date')

    expect(subject.get_ttl_status('update_ttl_test')['time_to_live_status']).to eq('DISABLED')

    subject.drop('update_ttl_test')

  end

  it 'handles timeouts when dynamodb fails to respond' do
    allow(subject).to receive('wait_timeout').and_return(Time.now)

    expect{subject.wait_until_ttl_changed('update_ttl_test')}.to raise_error("Timeout occurred while waiting for table: update_ttl_test, to become active.")
  end

  it 'can drop an existing global secondary index' do

    exists = subject.exists?('drop_index_test')

    if exists
      subject.drop('drop_index_test')
    end

    global_indexes = []
    index1 = subject.create_global_index('index1', :name, :number)
    global_indexes.push(index1)

    builder = DynamoDbFramework::AttributesBuilder.new
    builder.add(:id, :S)
    builder.add(:name, :S)
    builder.add(:number, :N)

    subject.create('drop_index_test', builder.attributes, :id, nil, 20, 10, global_indexes)

    subject.drop_index('drop_index_test', 'index1')

    has_index = subject.has_index?('drop_index_test', 'index1')

    subject.drop('drop_index_test')

    expect(has_index).to eq(false)

  end

  after do

    subject.drop('update_throughput')
    subject.drop('add_index')

  end

end
