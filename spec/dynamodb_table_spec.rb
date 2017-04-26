RSpec.describe DynamoDbFramework::Table do

  let(:store) do
    DynamoDbFramework::Store.new({ endpoint: DYNAMODB_STORE_ENDPOINT, aws_region: 'eu-west-1' })
  end

  let(:table_manager) do
    DynamoDbFramework::TableManager.new(store)
  end

  describe '#create' do
    context 'when a valid table class calls the create method' do
      context 'with a range key' do
        let(:table_name) { ExampleTable.config[:table_name] }
        before do
          table_manager.drop(table_name)
        end
        it 'should create the table' do
          expect(table_manager.exists?(table_name)).to be false
          ExampleTable.create(store: store)
          expect(table_manager.exists?(table_name)).to be true
        end
      end

      context 'without a range key' do
        let(:table_name) { ExampleTableWithoutRangeKey.config[:table_name] }
        before do
          table_manager.drop(table_name)
        end
        it 'should create the table' do
          expect(table_manager.exists?(table_name)).to be false
          ExampleTableWithoutRangeKey.create(store: store)
          expect(table_manager.exists?(table_name)).to be true
        end
      end
    end
    context 'when an invalid table class calls the create method' do
      context 'without a table_name specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutTableName.create(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
      context 'without a partition_key specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutPartitionKey.create(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
    end
  end

  describe '#update' do
    context 'when a valid table class calls the update method' do
      let(:table_name) { ExampleTable.config[:table_name] }
      before do
        table_manager.drop(table_name)
        ExampleTable.create(store: store)
      end
      it 'should update the table' do
        ExampleTable.update(store: store, read_capacity: 50, write_capacity: 50)
      end
    end
    context 'when an invalid table class calls the update method' do
      context 'without a table_name specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutTableName.update(store: store, read_capacity: 50, write_capacity: 50) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
    end
  end

  describe '#query' do

    let(:repository) do
      DynamoDbFramework::Repository.new(store)
    end

    let(:table_name) { ExampleTable2.config[:table_name] }

    def create_query_item(name, number)
      item = TestItem.new
      item.id = SecureRandom.uuid
      item.name = name
      item.timestamp = Time.now
      item.number = number
      repository.table_name = table_name
      repository.put(item)
    end

    before do
      table_manager.drop(table_name)
      ExampleTable2.create(store: store)

      create_query_item('name 1', 1)
      create_query_item('name 1', 2)
      create_query_item('name 1', 3)
      create_query_item('name 1', 4)
      create_query_item('name 2', 1)
      create_query_item('name 2', 2)
      create_query_item('name 2', 3)
      create_query_item('name 3', 1)
      create_query_item('name 3', 2)
    end

    it 'should return the expected items' do
      results = ExampleTable2.query(partition: 'name 1').number.>=(1).and.number.<=(5).execute(store: store)
      expect(results.length).to eq 4
    end
    context 'when limit is specified' do
      it 'should return the expected items' do
        results = ExampleTable2.query(partition: 'name 1').number.>=(1).and.number.<=(5).execute(store: store, limit: 1)
        expect(results.length).to eq 1
      end
    end
    context 'when count is specified' do
      it 'should return the expected count' do
        count = ExampleTable2.query(partition: 'name 1').number.>=(1).and.number.<=(5).execute(store: store, count: 4)
        expect(count).to eq 4
      end
    end
  end

end
