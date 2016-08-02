require 'spec_helper'

RSpec.describe DynamoDbFramework::Repository do
  let(:store) do
    DynamoDbFramework::Store.new({ endpoint: DYNAMODB_STORE_ENDPOINT, aws_region: 'eu-west-1' })
  end

  let(:schema_manager) do
    DynamoDbFramework::TableManager.new(store)
  end

  subject do
    DynamoDbFramework::Repository.new(store)
  end

  def create_query_item(name, number, table_name)
    item = TestItem.new
    item.id = SecureRandom.uuid
    item.name = name
    item.timestamp = Time.now.to_i
    item.number = number
    subject.table_name = table_name
    subject.put(item)
  end

  describe '#put' do
    let(:current_time) { Time.now          }
    let(:id          ) { 'Item1'           }
    let(:name        ) { 'Name'            }
    let(:timestamp   ) { current_time.to_i }
    let(:number      ) { 5                 }

    let(:item) do
      TestItem.new.tap do |obj|
        obj.id        = id
        obj.name      = name
        obj.timestamp = timestamp
        obj.number    = number
      end
    end

    before do
      schema_manager.drop('put')
      attributes_builder = DynamoDbFramework::AttributesBuilder.new
      attributes_builder.add(:id, :S)
      schema_manager.create('put', attributes_builder.attributes, :id)
      subject.table_name = 'put'
    end

    it 'can store an item in a table' do
      expect { subject.put(item) }.to_not raise_error
    end

    context 'when one of the entity values is nil' do
      let(:name) { nil }

      it 'does not raise an error' do
        expect { subject.put(item) }.to_not raise_error

        stored_item = subject.get_by_key('id', id)

        expect(stored_item['id']).to eq(id)
        expect(stored_item['name']).to eq(name)
        expect(stored_item['timestamp']).to eq(timestamp)
        expect(stored_item['number']).to eq(number)
      end
    end

    context 'when one of the entity values is an empty string' do
      let(:name) { '' }

      it 'does not raise an error' do
        expect { subject.put(item) }.to_not raise_error

        stored_item = subject.get_by_key('id', id)

        expect(stored_item['id']).to eq(id)
        expect(stored_item['name']).to eq(nil)
        expect(stored_item['timestamp']).to eq(timestamp)
        expect(stored_item['number']).to eq(number)
      end
    end

    after do
      schema_manager.drop('put')
    end

  end

  context '#delete' do
    before do
      schema_manager.drop('delete')
      attributes_builder = DynamoDbFramework::AttributesBuilder.new
      attributes_builder.add(:id, :S)
      schema_manager.create('delete', attributes_builder.attributes, :id)
    end

    it 'can delete an item from a table' do
      item = TestItem.new
      item.id = 'Item1'
      item.name = 'Name'
      item.timestamp = Time.now.to_i
      item.number = 5

      subject.table_name = 'delete'
      subject.put(item)

      subject.delete({ id: item.id })
    end

    after do
      schema_manager.drop('delete')
    end

  end

  context '#get_by_key' do
    before do
      schema_manager.drop('get_by_key')
      attributes_builder = DynamoDbFramework::AttributesBuilder.new
      attributes_builder.add(:id, :S)
      schema_manager.create('get_by_key', attributes_builder.attributes, :id)
    end

    it 'can get an item from a table by the item key' do
      item = TestItem.new
      item.id = 'Item1'
      item.name = 'Name'
      item.timestamp = Time.now.to_i
      item.number = 5

      subject.table_name = 'get_by_key'
      subject.put(item)

      item = subject.get_by_key('id', item.id)
      expect(item).to_not be_nil
      expect(item["id"]).to eq('Item1')
      expect(item["name"]).to eq('Name')
    end

    after do
      schema_manager.drop('get_by_key')
    end

  end

  context '#query no index' do
    before do
      schema_manager.drop('query')

      attributes_builder = DynamoDbFramework::AttributesBuilder.new
      attributes_builder.add(:name, :S, :partition)
      attributes_builder.add(:id, :S, :range)

      schema_manager.create_table(name: 'query', attributes: attributes_builder.attributes)


      create_query_item('name 1', 1, 'query')
      create_query_item('name 1', 2, 'query')
      create_query_item('name 1', 3, 'query')
      create_query_item('name 1', 4, 'query')
      create_query_item('name 2', 1, 'query')
      create_query_item('name 2', 2, 'query')
      create_query_item('name 2', 3, 'query')
      create_query_item('name 3', 1, 'query')
      create_query_item('name 3', 2, 'query')
    end

    it 'should return all items within a partition that match a filter expression' do
      subject.table_name = 'query'

      results = subject.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2})

      expect(results.length).to eq(2)
    end

    it 'should count all items within a partition that match a filter expression' do
      subject.table_name = 'query'

      count = subject.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2}, nil, nil, true)

      expect(count).to eq(2)
    end

    after do
      schema_manager.drop('query')
    end
  end

  context '#query index' do
    before do
      schema_manager.drop('query_index')

      attributes_builder = DynamoDbFramework::AttributesBuilder.new
      attributes_builder.add(:id, :S)
      attributes_builder.add(:name, :S)

      global_indexes = []
      index1 = schema_manager.create_global_index('name_index', :name)
      global_indexes.push(index1)
      schema_manager.create('query_index', attributes_builder.attributes, :id, nil, 20, 10, global_indexes)


      create_query_item('name 1', 1, 'query_index')
      create_query_item('name 1', 2, 'query_index')
      create_query_item('name 1', 3, 'query_index')
      create_query_item('name 1', 4, 'query_index')
      create_query_item('name 2', 1, 'query_index')
      create_query_item('name 2', 2, 'query_index')
      create_query_item('name 2', 3, 'query_index')
      create_query_item('name 3', 1, 'query_index')
      create_query_item('name 3', 2, 'query_index')
    end

    it 'should return all items within an index partition that match a filter expression' do
      subject.table_name = 'query_index'

      results = subject.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2}, 'name_index')

      expect(results.length).to eq(2)
    end

    it 'should count all items within an index partition that match a filter expression' do
      subject.table_name = 'query_index'

      count = subject.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2}, 'name_index', nil, true)

      expect(count).to eq(2)
    end

    after do
      schema_manager.drop('query_index')
    end
  end

  context '#scan' do
    before do
      schema_manager.drop('scan')

      attributes_builder = DynamoDbFramework::AttributesBuilder.new
      attributes_builder.add(:id, :S)

      schema_manager.create('scan', attributes_builder.attributes, :id)


      create_query_item('name 1', 1, 'scan')
      create_query_item('name 1', 2, 'scan')
      create_query_item('name 1', 3, 'scan')
      create_query_item('name 1', 4, 'scan')
      create_query_item('name 2', 1, 'scan')
      create_query_item('name 2', 2, 'scan')
      create_query_item('name 2', 3, 'scan')
      create_query_item('name 3', 1, 'scan')
      create_query_item('name 3', 2, 'scan')
    end

    it 'should return all items from a table' do
      subject.table_name = 'scan'

      results = subject.all()

      expect(results.length).to eq(9)
    end

    it 'should count all items from a table that match a filter expression' do
      subject.table_name = 'scan'

      count = subject.scan('#name = :name', { '#name' => :name, ':name' => 'name 1' }, nil, true)

      expect(count).to eq(4)
    end

    it 'should return all items from a table that match a filter expression' do
      subject.table_name = 'scan'

      results = subject.scan('#name = :name', { '#name' => :name, ':name' => 'name 1' })

      expect(results.length).to eq(4)
    end

    after do
      schema_manager.drop('scan')
    end
  end
end
