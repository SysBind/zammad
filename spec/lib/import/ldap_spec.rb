require 'rails_helper'
require 'lib/import/import_job_backend_examples'

RSpec.describe Import::Ldap do
  it_behaves_like 'ImportJob backend'

  describe '::queueable?' do

    it 'is queueable if LDAP integration is activated and configured' do
      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
      allow(Setting).to receive(:get).with('ldap_config').and_return({ host: 'some' })
      expect(described_class.queueable?).to be true
    end

    it "isn't queueable if LDAP integration is deactivated" do
      allow(Setting).to receive(:get).with('ldap_integration').and_return(false)
      allow(Setting).to receive(:get).with('ldap_config').and_return({ host: 'some' })
      expect(described_class.queueable?).to be false
    end

    it "isn't queueable if LDAP configuration is missing" do
      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
      allow(Setting).to receive(:get).with('ldap_config').and_return({})
      expect(described_class.queueable?).to be false
    end
  end

  describe '#start' do
    it 'starts LDAP import resource factories' do
      import_job = create(:import_job)
      instance   = described_class.new(import_job)

      allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
      allow(Setting).to receive(:get).with('ldap_config').and_return(true)
      expect(Import::Ldap::UserFactory).to receive(:import)

      instance.start
    end

    context 'requirements' do

      it 'lets dry runs always start' do
        import_job = create(:import_job, dry_run: true)
        instance   = described_class.new(import_job)

        expect(Import::Ldap::UserFactory).to receive(:import)

        instance.start
      end

      it 'informs about deactivated ldap_integration' do
        import_job = create(:import_job)
        instance   = described_class.new(import_job)

        allow(Setting).to receive(:get).with('ldap_integration').and_return(false)

        expect(Import::Ldap::UserFactory).not_to receive(:import)

        expect do
          instance.start
          import_job.reload
        end.to change {
          import_job.result
        }

        expect(import_job.result.key?(:info)).to be true
      end

      it 'informs about blank ldap_config' do
        import_job = create(:import_job)
        instance   = described_class.new(import_job)

        allow(Setting).to receive(:get).with('ldap_integration').and_return(true)
        allow(Setting).to receive(:get).with('ldap_config').and_return({})

        expect(Import::Ldap::UserFactory).not_to receive(:import)

        expect do
          instance.start
          import_job.reload
        end.to change {
          import_job.result
        }

        expect(import_job.result.key?(:info)).to be true
      end
    end
  end
end
