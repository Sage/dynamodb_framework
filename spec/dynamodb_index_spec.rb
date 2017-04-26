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

end
