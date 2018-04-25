RSpec.describe DynamoDbFramework::Query do

  let(:store) do
    DynamoDbFramework::Store.new({ endpoint: DYNAMODB_STORE_ENDPOINT, aws_region: 'eu-west-1' })
  end

  let(:repository) do
    DynamoDbFramework::Repository.new(store)
  end

  let(:table_manager) do
    DynamoDbFramework::TableManager.new(store)
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

  describe '#build' do
    it 'should correctly generate the expression string and params' do
      string,params = DynamoDbFramework::Query.new(table_name: table_name, partition_key: :name, partition_value: 'name 1')
                          .number.gt_eq(1)
                          .and
                          .number.lt_eq(5)
                          .and
                          .number.exists?
                          .and
                          .name.contains('name')
                          .build
      expect(string).to eq '#number >= :p0 and #number <= :p1 and attribute_exists(#number) and contains(#name, :p2)'
      expect(params['#number']).to eq 'number'
      expect(params[':p0']).to eq 1
      expect(params[':p1']).to eq 5
      expect(params['#name']).to eq 'name'
      expect(params[':p2']).to eq 'name'
    end
  end

  describe '#execute' do
    it 'should return the expected items' do
      results = DynamoDbFramework::Query.new(table_name: table_name, partition_key: :name, partition_value: 'name 1')
                    .number.gt_eq(1)
                    .and
                    .number.lt_eq(5)
                    .execute(store: store)
      expect(results.length).to eq 4
    end
    context 'when limit is specified' do
      it 'should return the expected items' do
        results = DynamoDbFramework::Query.new(table_name: table_name, partition_key: :name, partition_value: 'name 1')
                      .number.gt_eq(1)
                      .and
                      .number.lt_eq(5)
                      .execute(store: store, limit: 1)
        expect(results.length).to eq 1
      end
    end
    context 'when count is specified' do
      it 'should return the expected count' do
        count = DynamoDbFramework::Query.new(table_name: table_name, partition_key: :name, partition_value: 'name 1')
                    .number.gt_eq(1)
                    .and
                    .number.lt_eq(5)
                    .execute(store: store, count: 4)
        expect(count).to eq 4
      end
    end
    context 'when using eq' do
      it 'should return the right values' do
        results = ExampleTable2.query(partition: 'name 1').number.eq(1).execute(store: store)
        expect(results.length).to eq(1)
      end
    end
    context 'when using not_eq' do
      it 'should return the right values' do
        results = ExampleTable2.query(partition: 'name 1').number.not_eq(1).execute(store: store)
        expect(results.length).to eq(3)
      end
    end
  end

end
