# DynamoDb_Framework

[![Build Status](https://travis-ci.org/Sage/dynamodb_framework.svg?branch=master)](https://travis-ci.org/Sage/dynamodb_framework)
[![Maintainability](https://api.codeclimate.com/v1/badges/068ca2a25a441119af70/maintainability)](https://codeclimate.com/github/Sage/dynamodb_framework/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/068ca2a25a441119af70/test_coverage)](https://codeclimate.com/github/Sage/dynamodb_framework/test_coverage)
[![Gem Version](https://badge.fury.io/rb/dynamodb_framework.svg)](https://badge.fury.io/rb/dynamodb_framework)

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

##Global Config

### #namespace
The namespace is used to set the prefix applied to all table and index names.

    DynamoDbFramework.namespace = 'uat'

> With a namespace of 'uat' and a table name of 'people', the resulting table name would be 'uat.people'

### #namespace_delimiter
This is the delimiter used to join the namespace prefix to table/index names.

> DEFAULT = '.'

    DynamoDbFramework.namespace_delimiter = '-'

### #default_store
This is used to set the default store that should be used for all connection actions that don't specify a store override.

    DynamoDbFramework.default_store = store

> If no [DynamoDbFramework::Store] is manually specified then the default store will attempt to use the aws credentials from the host machines aws configuration profile.

# Table
Before you can work with any data in dynamodb you require a table definition.
To define a table create a class and use the `DynamoDbFramework::Table` module.

    class ExampleTable
      extend DynamoDbFramework::Table

      table_name 'example'
      partition_key :id, :S
      range_key :timestamp, :N

    end

**attributes**

 - **table_name** [String] [Required] This is used to specify the name of the table.
 - **partition_key** [Symbol, Symbol] [Required] This is used to specify the item field to use for the partition key, along with the type of the field.
 - **range_key** [Symbol, Symbol] [Optional] This is used to specify the item field to use for the range key, along with the type of the field.

This definition can then be used to interact with DynamoDb in relation to the table.

## #create
This method is called create the table definition within a dynamodb account.
> This method should operate in an idempotent manner.

**Params**

 - **store** [DynamoDbFramework::Store] [Required] This is used to specify the Dynamodb instance/account to connect to.
 - **read_capacity** [Integer] [Optional] [Default=25] This is used to specify the read capacity to provision for this table.
 - **write_capacity** [Integer] [Optional] [Default=25] This is used to specify the write capacity to provision for this table.
 - **indexes** [Array] [Optional] This is used to specify an array of Index definitions to be created with the table.


    ExampleTable.create(read_capacity: 50, write_capacity: 35, indexes: [ExampleIndex])

## #update
This method is called to update the provisioned capacity for the table.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **read_capacity** [Integer] [Required] This is used to specify the read capacity to provision for this table.
 - **write_capacity** [Integer] [Required] This is used to specify the write capacity to provision for this table.


    ExampleTable.update(read_capacity: 100, write_capacity: 50)

## #drop
This method is called to drop the table from a dynamodb account.
> This method should operate in an idempotent manner.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.


    ExampleTable.drop


## #exists?
This method is called to determine if this table exists in a dynamodb account.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.


    ExampleTable.exists?

## #get_item
This method is called to get a single item from the table by its unique key.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **partition** [object] [Required] This is used to specify the partition_key value of the item to get.
 - **range** [object] [Optional] This is used to specify the range_key value of the item to get.


    ExampleTable.get_item(partition: uuid, range: timestamp)


## #put_item
This method is called to put a single item into the table.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **item** [object] [Required] This is the item to store in the table.


    ExampleTable.put_item(item: item)


## #delete_item
This method is called to delete an item from the table.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **partition** [object] [Required] This is used to specify the partition_key value of the item.
 - **range** [object] [Optional] This is used to specify the range_key value of the item.


    ExampleTable.delete_item(partition: uuid, range: timestamp)


## #all
This method is called to return all items from the table.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.

    ExampleTable.all


## #query
This method is called to query the table for a collection of items.

**Params**

 - **partition** [object] [Required] This is used to specify the partition_key to query within.

The query is then built up using method chaining e.g:

    query = ExampleTable.query(partition: partition_value).name.eq('fred').and.age.gt(18)

The above query chain translates into:

    FROM partition_value WHERE name == 'fred' AND age > 18

To execute the query you can then call `#execute` on the query:

    query.execute

### #execute
This method is called to execute a query.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **limit** [Integer] [Optional] This is used to specify a limit to the number of items returned by the query.
 - **count** [Boolean] [Optional] This is used to specify if the query should just return a count of results.

## Query expressions

### #eq(value)
This method is used to specify the `==` operator within a query.

### #not_eq(value)
This method is called to specify the `!=` operator within a query.

### #gt(value)
This method is called to specify the `>` operator within a query.

### #gt_eq(vaue)
This method is called to specify the `>=` operator within a query.

### #lt(value)
This method is called to specify the `<` operator within a query.

### #lt_eq(value)
This method is called to specify the `<=` operator within a query.

### #contains(value)
This method is called to check if a field contains a value within a query.

### #exists?
This method is called to check if a field exists within a query.

### #and
This method is called to combine conditions together in a traditional `&&` method within a query.

### #or
This method is called to combine conditions together in a traditional `||` method within a query.

# Index
To define a global secondary index in dynamodb create an index definition class that extends from the `DynamoDbFramework::Index` module.

    class ExampleIndex
      extend DynamoDbFramework::Index

      index_name 'example_index'
      table ExampleTable
      partition_key :name, :S
      range_key :id, :S

    end

**attributes**

 - **index_name** [String] [Required] This is used to specify the name of the index.
 - **table** [Table] [Required] This is the table definition class for the table the index should be applied to.
 - **partition_key** [Symbol, Symbol] [Required] This is used to specify the item field to use for the partition key, along with the type of the field.
 - **range_key** [Symbol, Symbol] [Optional] This is used to specify the item field to use for the range key, along with the type of the field.


## #create
This method is called create the index definition within a dynamodb account.
> This method should operate in an idempotent manner.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **read_capacity** [Integer] [Optional] [Default=25] This is used to specify the read capacity to provision for this index.
 - **write_capacity** [Integer] [Optional] [Default=25] This is used to specify the write capacity to provision for this index.


    ExampleIndex.create(read_capacity: 50, write_capacity: 35)

## #update
This method is called to update the provisioned capacity for the index.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **read_capacity** [Integer] [Required] This is used to specify the read capacity to provision for this index.
 - **write_capacity** [Integer] [Required] This is used to specify the write capacity to provision for this index.


    ExampleIndex.update(read_capacity: 100, write_capacity: 50)

## #drop
This method is called to drop the current index.
> This method should operate in an idempotent manner.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.


    ExampleIndex.drop

## #exists?
This method is called to determine if this index exists in a dynamodb account.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.


    ExampleIndex.exists?


## #query
This method is called to query the index for a collection of items.

**Params**

 - **partition** [object] [Required] This is used to specify the partition_key to query within.

The query is then built up using method chaining e.g:

    query = ExampleIndex.query(partition: partition_value).gender.eq('male').and.age.gt(18)

The above query chain translates into:

    FROM partition_value WHERE gender == 'male' AND age > 18

To execute the query you can then call `#execute` on the query:

    query.execute

### #execute
This method is called to execute a query.

**Params**

 - **store** [DynamoDbFramework::Store] [Optional] This is used to specify the Dynamodb instance/account to connect to. If not specified the `DyanmoDbFramework.default_store` will be used.
 - **limit** [Integer] [Optional] This is used to specify a limit to the number of items returned by the query.
 - **count** [Boolean] [Optional] This is used to specify if the query should just return a count of results.

## Query expressions

### #eq(value)
This method is used to specify the `==` operator within a query.

### #not_eq(value)
This method is called to specify the `!=` operator within a query.

### #gt(value)
This method is called to specify the `>` operator within a query.

### #gt_eq(vaue)
This method is called to specify the `>=` operator within a query.

### #lt(value)
This method is called to specify the `<` operator within a query.

### #lt_eq(value)
This method is called to specify the `<=` operator within a query.

### #contains(value)
This method is called to check if a field contains a value within a query.

### #exists?
This method is called to check if a field exists within a query.

### #and
This method is called to combine conditions together in a traditional `&&` method within a query.

### #or
This method is called to combine conditions together in a traditional `||` method within a query.


# MigrationScripts
To create or modify a DynamoDb instance you first need to create a migration script:

**Example**

    class CreateEventTrackingTableScript < DynamoDbFramework::MigrationScript

		def initialize
			#set the timestamp for when this script was created
			@timestamp = '20160318110710'
		end

		def apply
			EventTrackingTable.create(read_capacity: 50, write_capacity: 35)
		end
		def undo
			EventTrackingTable.drop
		end
	end

Each migration script should have a unique fixed timestamp value of the following format:

    yyyymmddhhMMss

**Example**

11:07:10 18-03-2016 would be:

    20160318110710

This timestamp is used to track installation of each migration script and insure correct apply/undo ordering.

# DynamoDbFramework::Namespace::MigrationManager
This manager is called to apply/rollback migration script changes against a DynamoDb instance.

### #connect
This method is called to connect the manager to the DynamoDb instance. If the migration manager has never been connected to the instance then the 'dynamodb_migrations' table will be created to record migration script executions.

    manager = DynamoDbFramework::MigrationManager.new
    manager.connect

### #apply
This method is called to execute any migration scripts (in chronological order) that have not been executed against the current DynamoDb instance.

**Params**

 - **namespace** [String] [Required] This is used to specify the namespace for all migration scripts to be executed within.


    #apply any outstanding migration scripts
    manager.apply(namespace)

### #rollback
This method is called to rollback the last migration script that was executed against the current DynamoDb instance.

**Params**

 - **namespace** [String] [Required] This is used to specify the namespace for all migration scripts to be executed within.


    #rollback the last migration script
    manager.rollback(namespace)

# DynamoDbFramework::TableManager

This manager object provides the following methods for managing tables within a DynamoDb instance.
> NOTE: This functionality should now be handled via the DynamoDbFramework::Table & DynamoDbFramework::Index module as described above.

### #create

This method is called to create a table within DynamoDb.

**Params**

 - **table_name** [String] [Required] This is used to specify the name of the table to create. (Must be unique within the DynamoDb instance).
 - **attributes** [Hash] [Required] This is used to specify the attributes used by the keys and indexes. (Use the DynamoDbFramework::AttributesBuilder to create attributes)
 - **partition_key** [Symbol] [Required] This is the document attribute that will be used as the partition key of this table.
 - **range_key** [Symbol / nil] [Optional] This is the document attribute that will be used as the range key for this table.
 - **read_capacity** [Number] [Default=20] This is the read throughput required for this table.
 - **write_capacity** [Number] [Default=10] This is the write throughput required for this table.
 - **global_indexes** [Array / nil] [Optional] This is an array of the global indexes to create for this table. (Use the ***#create_global_index*** method to create each global index required and populate an array for this parameter).

**Examples**

Table with partition key, no range key and no indexes:

    #create an attribute builder
	builder = DynamoDbFramework::AttributesBuilder.new

	#set the partition key attribute
	builder.add(:type, :S)

	#create the table
	manager.create('event_tracking', builder.attributes, :type)

Table with partition key, range key and no indexes:

    #create an attribute builder
	builder = DynamoDbFramework::AttributesBuilder.new

	#set the partition key attribute
	builder.add(:type, :S)
	#set the range key attribute
	builder.add(:timestamp, :S)

	#create the table
	manager.create('event_tracking', builder.attributes, :type, :timestamp)

Table with a global index:

    #create an attribute builder
	builder = DynamoDbFramework::AttributesBuilder.new

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
 - **attributes** [Hash] [Required] This is the document attributes used by the table keys and index keys. (Use the DynamoDbFramework::AttributesBuilder to create the attributes hash.)
 - **global_index** [Hash] [Required] This is the global index to add to the table. (Use the ***#create_global_index*** method to create the global index hash.)

**Example**

	#build the attributes hash
	builder = DynamoDbFramework::AttributesBuilder.new
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

### #update_ttl_attribute

This method is called to update the ttl attribute of a table.

**Params** 

 - **table_name** [String] [Required] This is the name of the table the attribute belongs to.
 - **time_to_live_status** [Boolean] [Required] This is true to turn TTL on on the table or false to turn it off.
 - **attribute_name** [String] [Required] This is the name of the attribute that is going to be used for TTL.

**Example**
    #Enable TTL
    update_ttl_attribute('ttl_example', true, 'ttl_timestamp')

### #has_index?(table_name, index_name)

This method is called to check if an index exists on a table within the database.

    manager.has_index?('event_tracking', 'event_type')
    => true


# DynamoDbFramework::Repository

This is a base repository that exposes core functionality for interacting with a DynamoDb table. It is intended to be wrapped inside of a table specific repository, and is only provided to give a common way of interacting with a DynamoDb table.

> NOTE: This functionality should now be handled via a DynamoDbFramework::Table or DynamoDbFramework::Index as detailed above.

Before calling any methods from the repository the **.table_name** attribute must be set so that the repository knows which table to run the operations against.

**Example**

    repository.table_name = 'event_tracking'

### #put
This method is called to insert an item into a DynamoDb table.

*Note*:

         [DateTime] attributes will be stored as an ISO8601 string

         [Time] attributes will be stored as an Epoch Int

The intent is that if you need to sort in dynamo by dates, then make sure you use a [Time] type. The Epoch int allows
you to compare properly as comparing date strings are not reliable.

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

## Testing

To run the tests locally, we use Docker to provide both a Ruby and JRuby environment along with a reliable Redis container.

### Setup Images:

> This builds the Ruby docker image.

```bash
cd script
./setup.sh
```

### Run Tests:

> This executes the test suite.

```bash
cd script
./test.sh
```

### Cleanup

> This is used to clean down docker image created in the setup script.

```bash
cd script
./cleanup.sh
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sage/dynamodb_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

This gem is available as open source under the terms of the
[MIT licence](LICENSE).

Copyright (c) 2018 Sage Group Plc. All rights reserved.
