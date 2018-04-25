RSpec.describe DynamoDbFramework::Index do

  let(:store) do
    DynamoDbFramework::Store.new({ endpoint: DYNAMODB_STORE_ENDPOINT, aws_region: 'eu-west-1' })
  end

  let(:table_manager) do
    DynamoDbFramework::TableManager.new(store)
  end

  let(:table_name) { ExampleTable.config[:table_name] }

  before do
    ExampleTable.create(store: store)
  end

  describe '#create' do
    context 'when a valid index class calls the create method' do
      context 'with a range key' do
        let(:index_name) { ExampleIndex.config[:index_name] }
        before do
          if table_manager.has_index?(table_name, index_name)
            table_manager.drop_index(table_name, index_name)
          end
        end
        it 'should create the index' do
          expect(table_manager.has_index?(table_name, index_name)).to be false
          ExampleIndex.create(store: store)
          expect(table_manager.has_index?(table_name, index_name)).to be true
        end
      end

      context 'without a range key' do
        let(:index_name) { ExampleIndexWithoutRangeKey.config[:index_name] }
        before do
          if table_manager.has_index?(table_name, index_name)
            table_manager.drop_index(table_name, index_name)
          end
        end
        it 'should create the table' do
          expect(table_manager.has_index?(table_name, index_name)).to be false
          ExampleIndexWithoutRangeKey.create(store: store)
          expect(table_manager.has_index?(table_name, index_name)).to be true
        end
      end

      context 'when no store is specified' do
        let(:index_name) { ExampleIndex.config[:index_name] }
        before do
          DynamoDbFramework.default_store = store
          if table_manager.has_index?(table_name, index_name)
            table_manager.drop_index(table_name, index_name)
          end
        end
        it 'should create the index using the default store' do
          expect(table_manager.has_index?(table_name, index_name)).to be false
          ExampleIndex.create
          expect(table_manager.has_index?(table_name, index_name)).to be true
        end
      end
    end
    context 'when an invalid index class calls the create method' do
      context 'without a index_name specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutIndexName.create(store: store) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
      context 'without a table specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutTable.create(store: store) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
      context 'without a partition_key specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutPartitionKey.create(store: store) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
    end
  end

  describe '#update' do
    context 'when a valid index class calls the update method' do
      let(:index_name) { ExampleIndex.config[:index_name] }
      before do
        if table_manager.has_index?(table_name, index_name)
          table_manager.drop_index(table_name, index_name)
        end
        ExampleIndex.create(store: store)
      end
      it 'should update the index' do
        ExampleIndex.update(store: store, read_capacity: 50, write_capacity: 50)
      end
      context 'when no store is specified' do
        let(:index_name) { ExampleIndex.config[:index_name] }
        before do
          DynamoDbFramework.default_store = store
        end
        it 'should update the index using the default store' do
          ExampleIndex.update(read_capacity: 50, write_capacity: 50)
        end
      end
    end
    context 'when an invalid index class calls the update method' do
      context 'without an index_name specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutIndexName.update(store: store, read_capacity: 50, write_capacity: 50) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
      context 'without a table specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutTable.update(store: store, read_capacity: 50, write_capacity: 50) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
    end
  end

  describe '#drop' do
    context 'when a valid index class calls the drop method' do
      let(:index_name) { ExampleIndex.config[:index_name] }
      before do
        if table_manager.has_index?(table_name, index_name)
          table_manager.drop_index(table_name, index_name)
        end
        ExampleIndex.create(store: store)
      end
      it 'should drop the index' do
        ExampleIndex.drop(store: store)
        expect(table_manager.has_index?(table_name, index_name)).to be false
      end
      context 'when no store is specified' do
        before do
          DynamoDbFramework.default_store = store
        end
        it 'should drop the index using the default store' do
          ExampleIndex.drop
          expect(table_manager.has_index?(table_name, index_name)).to be false
        end
      end
    end
    context 'when an invalid index class calls the drop method' do
      context 'without an index_name specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutIndexName.drop(store: store) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
      context 'without a table specified' do
        it 'should raise an exception' do
          expect{ ExampleIndexWithoutTable.drop(store: store) }.to raise_error(DynamoDbFramework::Index::InvalidConfigException)
        end
      end
    end
  end

  describe '#exists?' do
    context 'when the index exists' do
      let(:index_name) { ExampleIndex.config[:index_name] }
      before do
        if table_manager.has_index?(table_name, index_name)
          table_manager.drop_index(table_name, index_name)
        end
        ExampleIndex.create(store: store)
      end
      it 'should return true' do
        expect(ExampleIndex.exists?(store: store)).to be true
      end
      context 'when no store is specified' do
        before do
          DynamoDbFramework.default_store = store
        end
        it 'should return true using the default store' do
          expect(ExampleIndex.exists?).to be true
        end
      end
    end
    context 'when the index does NOT exist' do
      let(:index_name) { ExampleIndex.config[:index_name] }
      before do
        if table_manager.has_index?(table_name, index_name)
          table_manager.drop_index(table_name, index_name)
        end
      end
      it 'should return false' do
        expect(ExampleIndex.exists?(store: store)).to be false
      end
      context 'when no store is specified' do
        before do
          DynamoDbFramework.default_store = store
        end
        it 'should return false using the default store' do
          expect(ExampleIndex.exists?).to be false
        end
      end
    end
  end

  describe '#query' do

    let(:repository) do
      DynamoDbFramework::Repository.new(store)
    end

    let(:table_name) { ExampleTable.config[:table_name] }
    let(:index_name) { ExampleIndex.config[:index_name] }

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
      DynamoDbFramework::default_store = store
      table_manager.drop(table_name)
      ExampleTable.create
      ExampleIndex.create

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
      results = ExampleIndex.query(partition: 'name 1')
                    .number.gt_eq(1)
                    .and
                    .number.lt_eq(5)
                    .execute(store: store)
      expect(results.length).to eq 4
    end
    context 'when no store is specified' do
      it 'should return the expected items' do
        results = ExampleIndex.query(partition: 'name 1')
                      .number.gt_eq(1)
                      .and
                      .number.lt_eq(5)
                      .execute
        expect(results.length).to eq 4
      end
    end
    context 'when limit is specified' do
      it 'should return the expected items' do
        results = ExampleIndex.query(partition: 'name 1')
                      .number.gt_eq(1)
                      .and
                      .number.lt_eq(5)
                      .execute(store: store, limit: 1)
        expect(results.length).to eq 1
      end
    end
    context 'when count is specified' do
      it 'should return the expected count' do
        count = ExampleIndex.query(partition: 'name 1')
                    .number.gt_eq(1)
                    .and
                    .number.lt_eq(5)
                    .execute(store: store, count: 4)
        expect(count).to eq 4
      end
    end
  end

end
