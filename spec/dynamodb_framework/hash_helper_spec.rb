require 'spec_helper'

RSpec.describe DynamoDbFramework::HashHelper do
  describe '#to_hash' do
    let(:service_klass) do
      Class.new do
        attr_accessor :code, :created
      end
    end
    let(:account_klass) do
      Class.new do
        attr_accessor :name, :email, :services
      end
    end

    let(:current_time       ) { Time.now                }
    let(:name               ) { 'Service User'          }
    let(:email              ) { 'service.user@sage,com' }
    let(:hr_service_code    ) { 'HR'                    }
    let(:hr_service_created ) { current_time.to_i       }
    let(:crm_service_code   ) { 'CRM'                   }
    let(:crm_service_created) { current_time.to_i       }

    let(:hr_service) do
      service_klass.new.tap do |obj|
        obj.code    = hr_service_code
        obj.created = hr_service_created
      end
    end
    let(:crm_service) do
      service_klass.new.tap do |obj|
        obj.code    = crm_service_code
        obj.created = crm_service_created
      end
    end
    let(:account) do
      account_klass.new.tap do |obj|
        obj.name = name
        obj.email = email
        obj.services = [hr_service, crm_service]
      end
    end

    context 'when given a hash' do
      let(:obj) do
        {
          name: name,
          email: email
        }
      end

      it { expect(subject.to_hash(obj)).to eq(obj) }

      context 'and one item in the hash is nil' do
        let(:name) { nil }
        let(:expected) { { email: email } }

        it { expect(subject.to_hash(obj)).to eq(expected) }
      end
    end

    context 'when all attributes are present' do
      let(:expected) do
        {
          name: "Service User",
          email: "service.user@sage,com",
          services: [
            { code: hr_service_code , created: hr_service_created },
            { code: crm_service_code, created: crm_service_created}
          ]
        }
      end

      it { expect(subject.to_hash(account)).to eq(expected) }
    end

    context 'when parent obj has nil attribute' do
      let(:name) { nil }
      let(:expected) do
        {
          email: "service.user@sage,com",
          services: [
            { code: hr_service_code , created: hr_service_created },
            { code: crm_service_code, created: crm_service_created}
          ]
        }
      end

      it { expect(subject.to_hash(account)).to eq(expected) }
    end

    context 'when child objects have nil attributes' do
      let(:hr_service_code    ) { nil }
      let(:crm_service_created) { nil }

      let(:expected) do
        {
          name: name,
          email: email,
          services: [
            { created: hr_service_created },
            { code: crm_service_code}
          ]
        }
      end

      it { expect(subject.to_hash(account)).to eq(expected) }
    end

    context 'when parent and child objects have nil attributes' do
      let(:email              ) { nil }
      let(:hr_service_code    ) { nil }
      let(:crm_service_created) { nil }

      let(:expected) do
        {
          name: name,
          services: [
            { created: hr_service_created },
            { code: crm_service_code}
          ]
        }
      end

      it { expect(subject.to_hash(account)).to eq(expected) }
    end
  end
  it { expect({a: 1, b: nil}.reject{|k, v| v.nil?}).to eq({a: 1}) }
end
