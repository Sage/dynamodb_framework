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

      context 'with an index specified' do
        let(:table_name) { ExampleTable.config[:table_name] }
        let(:index_name) { ExampleIndex.config[:index_name] }
        before do
          table_manager.drop(table_name)
          table_manager.drop_index(table_name, index_name)
        end
        it 'should create the table and index' do
          expect(table_manager.exists?(table_name)).to be false
          expect(ExampleIndex.exists?(store: store)).to be false
          ExampleTable.create(store: store, indexes: [ExampleIndex])
          expect(table_manager.exists?(table_name)).to be true
          expect(ExampleIndex.exists?(store: store)).to be true
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

      context 'when already exists' do
        let(:table_name) { ExampleTableWithoutRangeKey.config[:table_name] }
        before do
          table_manager.drop(table_name)
          ExampleTableWithoutRangeKey.create(store: store)
        end
        it 'should return without error' do
          expect(table_manager.exists?(table_name)).to be true
          expect { ExampleTableWithoutRangeKey.create(store: store) }.not_to raise_error
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

  describe '#drop' do
    context 'when a valid table class calls the drop method' do
      let(:table_name) { ExampleTable.config[:table_name] }
      before do
        table_manager.drop(table_name)
        ExampleTable.create(store: store)
      end
      it 'should drop the table' do
        ExampleTable.drop(store: store)
        expect(table_manager.exists?(table_name)).to be false
      end
    end
    context 'when an invalid table class calls the drop method' do
      context 'without a table_name specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutTableName.drop(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
    end
  end

  describe '#exists?' do
    context 'when a table already exists' do
      let(:table_name) { ExampleTable.config[:table_name] }
      before do
        table_manager.drop(table_name)
        ExampleTable.create(store: store)
      end
      it 'should return true' do
        expect(ExampleTable.exists?(store: store)).to be true
      end
    end
    context 'when a table does NOT already exist' do
      let(:table_name) { ExampleTable.config[:table_name] }
      before do
        table_manager.drop(table_name)
      end
      it 'should return false' do
        expect(ExampleTable.exists?(store: store)).to be false
      end
    end
  end

  describe '#wait_until_active' do
    context 'when a table exists' do
      let(:table_name) { ExampleTable.config[:table_name] }
      before do
        table_manager.drop(table_name)
        ExampleTable.create(store: store)
      end
      it 'should not raise timeout error' do
        expect { ExampleTable.wait_until_active(store: store) }.not_to raise_error
      end
    end
    context 'when a table does NOT exist' do
      let(:table_name) { ExampleTable.config[:table_name] }
      before do
        table_manager.drop(table_name)
        allow_any_instance_of(DynamoDbFramework::TableManager).to receive(:wait_timeout).and_return(Time.now)
      end
      it 'should raise timeout error' do
        expect { ExampleTable.wait_until_active(store: store) }.to raise_error
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
      results = ExampleTable2.query(partition: 'name 1')
                    .number.gt_eq(1)
                    .and
                    .number.lt_eq(5)
                    .execute(store: store)
      expect(results.length).to eq 4
    end

    context 'when limit is specified' do
      it 'should return the expected items' do
        results = ExampleTable2.query(partition: 'name 1')
                      .number.gt_eq(1)
                      .and
                      .number.lt_eq(5)
                      .execute(store: store, limit: 1)
        expect(results.length).to eq 1
      end
    end
    context 'when count is specified' do
      it 'should return the expected count' do
        count = ExampleTable2.query(partition: 'name 1')
                    .number.gt_eq(1)
                    .and
                    .number.lt_eq(5)
                    .execute(store: store, count: 4)
        expect(count).to eq 4
      end
    end
  end

  describe '#all' do
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

    it 'should return all items' do
      results = ExampleTable2.all(store: store)
      expect(results.length).to eq 9
    end
  end

  describe '#CRUD' do
    let(:repository) do
      DynamoDbFramework::Repository.new(store)
    end

    let(:table_name) { ExampleTable.config[:table_name] }

    let(:item) do
      item = TestItem.new
      item.id = SecureRandom.uuid
      item.name = 'abc'
      item.timestamp = Time.now
      item.number = 1
      item
    end

    let(:table_name) { ExampleTable.config[:table_name] }
    before do
      table_manager.drop(table_name)
      ExampleTable.create(store: store)
    end

    it 'should add, get and delete the item to the table' do
      ExampleTable.put_item(store: store, item: item)
      expect(ExampleTable.get_item(store: store, partition: item.id, range: item.timestamp)).not_to be_nil
      ExampleTable.delete_item(store: store, partition: item.id, range: item.timestamp)
      expect(ExampleTable.get_item(store: store, partition: item.id, range: item.timestamp)).to be_nil
    end
  end

end
