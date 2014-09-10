require 'spec_helper'

describe SneakySave, use_connection: true do
  context 'new record' do
    subject { Fake.new(name: 'test') }

    describe '#sneaky_save' do
      it 'returns true if everything is good' do
        expect(subject.sneaky_save).to eq(true)
      end

      it 'inserts the new record' do
        allow(subject).to receive(:sneaky_create).once.and_return(true)
        expect(subject.sneaky_save).to eq(true)
      end

      it 'stores attributes in database' do
        subject.name = 'test'
        expect(subject.sneaky_save).to eq(true)
        subject.reload
        expect(subject.name).to eq('test')
      end

      it 'does not call any callback' do
        Fake.any_instance.should_not_receive :before_save_callback
        subject.sneaky_save
      end

      it 'does not call validations' do
        expect_any_instance_of(Fake).to_not receive(:valid?)
        subject.sneaky_save
      end
    end

    describe '#sneaky_save!' do
      it 'raises an exception when insert fails' do
        subject.name = nil
        expect { subject.sneaky_save! }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  context 'existing record' do
    subject { Fake.create! :name => 'test' }

    describe '#sneaky_save' do
      context 'record is not changed' do
        it 'does nothing' do
          Fake.should_not_receive(:update_all)
          expect(subject.sneaky_save).to eq(true)
        end
      end

      context 'record is changed' do
        it 'updates attributes' do
          subject.should_receive(:sneaky_update).once.and_return true
          subject.name = 'new name'
          expect(subject.sneaky_save).to eq(true)
        end

        it 'stores attributes in database' do
          subject.name = 'new name'
          expect(subject.sneaky_save).to eq(true)
          subject.reload
          expect(subject.name).to eq('new name')
          expect(subject.sneaky_save).to eq(true)
        end

        it 'does not call any callback' do
          subject.should_not_receive :before_save_callback
          subject.sneaky_save
        end

        it 'does not call validations' do
          subject.should_not_receive :valid?
          subject.sneaky_save
        end
      end
    end

    describe '#sneaky_save!' do
      it 'raises an exception when update fails' do
        subject.name = nil
        expect { subject.sneaky_save! }.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end
