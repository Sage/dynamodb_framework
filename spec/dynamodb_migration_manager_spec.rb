require 'spec_helper'

RSpec.describe DynamoDbMigrationManager do

  table_manager = DynamoDbTableManager.new
  migration_table_name = 'dynamodb_migrations'
  repository = DynamoDbRepository.new
  repository.table_name = migration_table_name

  context '#connect' do

    it 'should create the migration table when not found' do

      table_manager.drop(migration_table_name)

      subject.connect()

      table_manager.exists?(migration_table_name)

    end

    it 'should connect when migration table already exists' do

      if !table_manager.exists?(migration_table_name)
        builder = DynamoDbAttributesBuilder.new
        builder.add(:id, :S)
        table_manager.create(migration_table_name, builder.attributes, :id)
      end

      subject.connect()

      table_manager.drop(migration_table_name)

    end

  end

  context '#apply' do

    it 'should apply all migration scripts when none have been applied previously' do

      table_manager.drop(migration_table_name)

      subject.connect()

      subject.apply()

      expect(table_manager.exists?('test1')).to eq(true)
      expect(table_manager.exists?('test2')).to eq(true)

      records = repository.all()
      expect(records.length).to eq(2)
      expect(records[0]['timestamp']).to eq('20160318110710')
      expect(records[1]['timestamp']).to eq('20160318110730')

    end

    it 'should only apply migration scripts that have not been previously applied' do

      table_manager.drop(migration_table_name)

      subject.connect()

      #setup migration history to have already previously applied script 1
      script1 = TestMigrationScript1.new
      script1.apply()

      expect(table_manager.exists?('test1')).to eq(true)
      repository.put({ :timestamp => script1.timestamp })
      records = repository.all()
      expect(records.length).to eq(1)
      expect(records[0]['timestamp']).to eq('20160318110710')

      #run migration apply
      subject.apply()

      #verify that script2 has been ran
      records = repository.all()
      expect(records.length).to eq(2)
      expect(records[1]['timestamp']).to eq('20160318110730')

    end

  end

  context '#rollback' do

    it 'should roll back the last migration script that was applied' do

      table_manager.drop(migration_table_name)
      subject.connect()

      #setup migration history to have already previously applied script 1
      script1 = TestMigrationScript1.new
      script1.apply()

      expect(table_manager.exists?('test1')).to eq(true)
      repository.put({ :timestamp => script1.timestamp })
      records = repository.all()
      expect(records.length).to eq(1)
      expect(records[0]['timestamp']).to eq('20160318110710')

      #execute a rollback
      subject.rollback()

      #verify that the test1 table has been removed as part of the rollback
      expect(table_manager.exists?('test1')).to eq(false)

    end

  end

  after do
    table_manager.drop(migration_table_name)
  end

end