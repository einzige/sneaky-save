require 'spec_helper'

describe SneakySave, use_connection: true do
  after :each do 
    subject.sneaky_save.should be_true
  end

  context 'new record' do
    subject { Fake.new }

    it('returns true if everything is good') {}

    it 'does insert of the new record' do
      subject.should_receive(:sneaky_create).once.and_return true
    end

    it 'stores attributes in database' do
      subject.name = 'test'
      subject.sneaky_save
      subject.reload
      subject.name.should == 'test'
    end

    it 'does not call any callback' do
      Fake.any_instance.should_not_receive :before_save_callback
    end

    it 'does not call validations' do
      Fake.any_instance.should_not_receive :valid?
    end
  end

  context 'existing record' do
    subject { Fake.create :name => 'test' }

    context 'record is not changed' do
      it 'does nothing' do
        Fake.should_not_receive(:update_all)
      end
    end

    context 'record is changed' do
      after :each do
        subject.name = 'new name'
      end

      it 'updates attributes' do
        subject.should be_valid
        subject.should_receive(:sneaky_update).once.and_return true
      end

      it 'stores attributes in database' do
        subject.name = 'new name'
        subject.sneaky_save.should be_true
        subject.reload
        subject.name.should == 'new name'
      end

      it 'does not call any callback' do
        subject.should_not_receive :before_save_callback
      end

      it 'does not call validations' do
        subject.should_not_receive :valid?
      end
    end
  end
end
