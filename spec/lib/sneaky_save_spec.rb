require "spec_helper"

describe SneakySave, use_connection: true do
  context "new record" do
    subject { Fake.new(name: "test") }

    describe "#sneaky_save" do
      it "returns true if everything is good" do
        expect(subject.sneaky_save).to eq(true)
      end

      it "inserts the new record" do
        allow(subject).to receive(:sneaky_create).once.and_return(true)
        expect(subject.sneaky_save).to eq(true)
      end

      it "stores attributes in database" do
        subject.name = "test"
        expect(subject.sneaky_save).to eq(true)
        subject.reload
        expect(subject.name).to eq("test")
      end

      it "does not call any callback" do
        expect_any_instance_of(Fake).not_to receive(:before_save_callback)
        subject.sneaky_save
      end

      it "does not call validations" do
        expect_any_instance_of(Fake).to_not receive(:valid?)
        subject.sneaky_save
      end

      it "updates serialized column" do
        subject.config = { test: "test" }
        expect(subject.sneaky_save).to eq(true)
        subject.reload
        expect(subject.config).to eq(test: "test")
      end
    end

    describe "#sneaky_save!" do
      it "raises an exception when insert fails" do
        subject.name = nil
        expect { subject.sneaky_save! }.to raise_error(ActiveRecord::StatementInvalid)
      end

      context "associations" do
        let(:belonger) { Belonger.create! }

        it "stores associations" do
          subject.belonger = belonger
          subject.sneaky_save!
          subject.reload
          expect(subject.belonger_id).to eq(belonger.id)
        end
      end
    end
  end

  context "existing record" do
    subject { Fake.create!(name: "test") }

    describe "#sneaky_save" do
      context "record is not changed" do
        it "does nothing" do
          expect(Fake).not_to receive(:update_all)
          expect(subject.sneaky_save).to eq(true)
        end
      end

      context "record is changed" do
        it "updates attributes" do
          expect(subject).to receive(:sneaky_update).once.and_return true
          subject.name = "new name"
          expect(subject.sneaky_save).to eq(true)
        end

        it "stores attributes in database" do
          subject.name = "new name"
          subject.config = {test: "test"}
          expect(subject.sneaky_save).to eq(true)
          subject.reload
          expect(subject.name).to eq("new name")
          expect(subject.config).to eq(test: "test")
        end

        it "does not call any callback" do
          expect(subject).not_to receive(:before_save_callback)
          subject.sneaky_save
        end

        it "does not call validations" do
          expect(subject).not_to receive(:valid?)
          subject.sneaky_save
        end
      end
    end

    describe "#sneaky_save!" do
      it "raises an exception when update fails" do
        subject.name = nil
        expect { subject.sneaky_save! }.to raise_error(ActiveRecord::StatementInvalid)
      end

      context "associations" do
        let(:belonger) { Belonger.create! }

        it "stores associations" do
          subject.belonger = belonger
          subject.sneaky_save!
          subject.reload
          expect(subject.belonger_id).to eq(belonger.id)
        end
      end
    end
  end
end
