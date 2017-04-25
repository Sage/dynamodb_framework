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
      context 'without read_capacity specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutReadCapacity.create(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
      context 'without write_capacity specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutWriteCapacity.create(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
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
        ExampleTable.read_capacity(200)
        ExampleTable.write_capacity(100)
      end
      it 'should update the table' do
        ExampleTable.update(store: store)
      end
    end
    context 'when an invalid table class calls the update method' do
      context 'without a table_name specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutTableName.update(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
      context 'without read_capacity specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutReadCapacity.update(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
      context 'without write_capacity specified' do
        it 'should raise an exception' do
          expect{ ExampleTableWithoutWriteCapacity.update(store: store) }.to raise_error(DynamoDbFramework::Table::InvalidConfigException)
        end
      end
    end
  end

end
