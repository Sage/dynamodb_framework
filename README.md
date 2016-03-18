# DynamoDb_Framework

Welcome to DynamoDb_Framework, this is a light weight framework that provides managers to help with interacting with aws dynamodb.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dynamodb_framework'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dynamodb_framework

## Usage

# MigrationScripts
To create or modify a DynamoDb instance you first need to create a migration script:

**Example**

    class CreateEventTrackingTableScript < MigrationScript

		def initialize
			#set the timestamp for when this script was created
			@timestamp = '20160318110710'
		end

		def apply
			#create an instance of the table manager
			manager = DynamoDbTableManager.new
			#create an attribute builder
			builder = DynamoDbAttributesBuilder.new

			#set the hash key attribute
			builder.add(:type, :S)			

			#create the table
			manager.create('event_tracking', builder.attributes, :type)
		end
		def undo
		
			#create an instance of the table manager
			manager = DynamoDbTableManager.new

			#drop the table
			manager.drop('event_tracking')
		
		end
	end

Each migration script should have a unique fixed timestamp value of the following format:

    yyyymmddhhMMss

**Example**

11:07:10 18-03-2016 would be:

    20160318110710

This timestamp is used to track installation of each migration script and insure correct apply/undo ordering.

# DynamoDbMigrationManager
This manager is called to apply/rollback migration script changes against a DynamoDb instance.

### #connect
This method is called to connect the manager to the DynamoDb instance. If the migration manager has never been connected to the instance then the 'dynamodb_migrations' table will be created to record migration script executions.

**Example**

    manager = DynamoDbMigrationManager.new
    manager.connect

### #apply
This method is called to execute any migration scripts (in chronological order) that have not been executed against the current DynamoDb instance.

**Example**

    #apply any outstanding migration scripts
    manager.apply

### #rollback
This method is called to rollback the last migration script that was executed against the current DynamoDb instance.

    #rollback the last migration script
    manager.rollback

# DynamoDbTableManager

This manager object provides the following methods for managing tables within a DynamoDb instance.

### #create

This method is called to create a table within DynamoDb.

**Params**

 - **table_name** [String] [Required] This is used to specify the name of the table to create. (Must be unique within the DynamoDb instance).
 - **attributes** [Hash] [Required] This is used to specify the attributes used by the keys and indexes. (Use the DynamoDbAttributesBuilder to create attributes)
 - **partition_key** [Symbol] [Required] This is the document attribute that will be used as the partition key of this table.
 - **range_key** [Symbol / nil] [Optional] This is the document attribute that will be used as the range key for this table.
 - **read_capacity** [Number] [Default=20] This is the read throughput required for this table.
 - **write_capacity** [Number] [Default=10] This is the write throughput required for this table.
 - **global_indexes** [Array / nil] [Optional] This is an array of the global indexes to create for this table. (Use the ***#create_global_index*** method to create each global index required and populate an array for this parameter).

**Examples**

Table with partition key, no range key and no indexes:

    #create an attribute builder
	builder = DynamoDbAttributesBuilder.new

	#set the partition key attribute
	builder.add(:type, :S)		

	#create the table
	manager.create('event_tracking', builder.attributes, :type)

Table with partition key, range key and no indexes:

    #create an attribute builder
	builder = DynamoDbAttributesBuilder.new

	#set the partition key attribute
	builder.add(:type, :S)	
	#set the range key attribute
	builder.add(:timestamp, :S)		

	#create the table
	manager.create('event_tracking', builder.attributes, :type, :timestamp)

Table with a global index:

    #create an attribute builder
	builder = DynamoDbAttributesBuilder.new

	#set the partition key attribute
	builder.add(:id, :S)		

	global_indexes = []
	#create the global index
	index = manager.create_global_index('type_index', :type)
	#add the index to the global_indexes array
	global_indexes.push(index)

	#create the table and the index
	manager.create('event_tracking', builder.attributes, :id, :nil, 20, 10, global_indexes)

### #drop
This method is called to drop a table. 

> **WARNING**: *This will drop all data stored within the table*

**Params**

 - **table_name** [String] [Required] This is the name of the table to drop.

**Example**

    #drop the table
    manager.drop('event_tracking')

### #exists?(table_name)

This method is called to check if a table exists within the database.

    manager.exists?('event_tracking')
    => true


### #add_index
This method is called to add an index to an existing table.

**Params**

 - **table_name** [String] [Required] This is the name of the index. (Must be unique within the scope of the table)
 - **attributes** [Hash] [Required] This is the document attributes used by the table keys and index keys. (Use the DynamoDbAttributesBuilder to create the attributes hash.)
 - **global_index** [Hash] [Required] This is the global index to add to the table. (Use the ***#create_global_index*** method to create the global index hash.)
 
**Example**

	#build the attributes hash
	builder = DynamoDbAttributesBuilder.new
	#add the attribute for the tables partition key & range key (if range key required)
	builder.add(:id, :S)
	#add the attributes for the index partition key and range key (if required)
	builder.add(:type, :S)

    #create the index hash
    index = manager.create_global_index('type_index', :type)
    
    #add the index to the table
    manager.add_index('event_tracking', builder.attributes, index)


### #drop_index
This method is called to drop an existing index from a table.

**Params**

 - **table_name** [String] [Required] This is the name of the table you want to remove the index from.
 - **index_name** [String] [Required] This is the name of the index you want to remove.

**Example**

	#drop the index
    manager.drop_index('event_tracking', 'type_index')

### #update_index_throughput

This method is called to update the throughput required by an index.

**Params**

 - **table_name** [String] [Required] This is the name of the table the index belongs to.
 - **index_name** [String] [Required] This is the name of the index to update.
 - **read_capacity** [Number] [Required] This is the read throughput required per second.
 - **write_capacity** [Number] [Required] This is the write throughput required per second.

**Example**

    #update the index
    manager.update_index_throughput('event_tracking', 'type_index', 50, 20)

### #has_index?(table_name, index_name)

This method is called to check if an index exists on a table within the database.

    manager.has_index?('event_tracking', 'event_type')
    => true


# DynamoDbRepository

This is a base repository that exposes core functionality for interacting with a DynamoDb table. It is intended to be wrapped inside of a table specific repository, and is only provided to give a common way of interacting with a DynamoDb table.

Before calling any methods from the repository the **.table_name** attribute must be set so that the repository knows which table to run the operations against.

**Example**

    repository.table_name = 'event_tracking'

### #put
This method is called to insert an item into a DynamoDb table.

**Params**

 - **item** [Object] [Required] The document to store within the table.

**Example**

    #add the document object to the table
    repository.put(item)

### #delete

This method is called to delete a document from a DynamoDb table.

**Params**

 - **keys** [Hash] [Required] This is a hash of the primary key of the document you want to delete. (The keys hash should contain the partition_key and if the table requires it the range_key.)

**Example**

    #delete an item where the partition key (:id) is the primary key
    repository.delete({ :id => '012' })
	
	#delete an item where the partition key (:type) and the range key (:index) is the primary key
	repository.delete({ :type => 'list', :index => 2 })

### #get_by_key
This method is called to get a single item from a table by its key.

**Params**

 - **partition_key** [Symbol] [Required] This is the document attribute that is the partition key for the table.
 - **partition_key_value** [String / Number] [Required] This is the value of the documents partition key.
 - **range_key** [Symbol] [Optional] This is the document attribute that is the range key for the table.
 - **range_key_value** [String / Number] [Optional] This is the value of the documents range key.

**Example**

    #get an item where the partition key is the primary key
    item = repository.get(:id, '12345')
	
	#get an item where the partition key and the range key is the primary key
	item = repository.get(:type, 'list', :index, 2)


### #all
This method is called to get all items from a table.

**Example**

 
    #get all items from table
    all_items_array = repository.all

### #scan
This method is called to execute a query against an entire table bypassing any indexes.

> **WARNING:** *Full table scans are slower than queries ran against a global index.*

**Params**

 - **expression** [String] [Required] This is an expression string for that contains the filter expression to run against the full table scan.
 - **expression_params** [Hash] [Required] This is a hash that contains the parameter names & values used by parameters within the scan expression.
 - **limit** [Number] [Optional] This is used to specify a limit to the number of records returned by the scan query.
 - **count** [Bool] [Optional] This is used to specify that the scan query should only return a count of the items that match the scan query.

**Example**

    #scan the table and return matching items
    results = repository.scan('#type = :type and #index > :index', { '#type' => :type, ':type' => 'list', '#index' => :index, ':index' => 2 })
    
    #scan the table and return matching items limited to 5 results
    results = repository.scan('#type = :type and #index > :index', { '#type' => :type, ':type' => 'list', '#index' => :index, ':index' => 2 }, 5)

    #scan the table and return a count of matching items
    count = repository.scan('#type = :type and #index > :index', { '#type' => :type, ':type' => 'list', '#index' => :index, ':index' => 2 }, nil, true)

> **Notes:**
>
> Attribute names should be specified using Expression parameter names which should start with a #
>
> Attribute values should be specified using Expression parameter values which should start with a :


### #query
This method is called to execute a query against either a table partition or an index.

**Params**

 - **partition_key_name** [Symbol] [Required] This is used to specify the attribute that is used as the partition key for this table.
 - **partition_key_value** [String / Number] [Required] This is used to specify the value of the partition to run this query against.
 - **range_key_name** [Symbol] [Optional] This is used to specify the range key to run this query against if needed.
 - **range_key_value** [String / Number] [Optional] This is used to specify the value of the range key to run this query against if needed.
 - **expression** [String] [Required] This is an expression string used to specify the filter  to run against the records found within the partition/range.
 - **expression_params** [Hash] [Required] This is a hash that contains the parameter names & values used by parameters within the query expression.
 - **index_name** [String] [Optional] This is the name of the index to run this query against.
 - **limit** [Number] [Optional] This is used to specify a limit to the number of records returned by the query.
 - **count** [Bool] [Optional] This is used to specify that the scan query should only return a count of the items that match the query. 

**Examples**

 Query from a table partition without an index:

    results = repository.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2})

Query and Count from a table partition without an index:

    count = repository.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2}, nil, nil, true)

Query from an index partition:

    results = repository.query(:name, 'name 1', nil, nil, '#number > :number', { '#number' => 'number', ':number' => 2}, 'name_index')
    
> **Notes:**
>
> Attribute names should be specified using Expression parameter names which should start with a #
>
> Attribute values should be specified using Expression parameter values which should start with a :
   

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vaughanbrittonsage/dynamodb_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
