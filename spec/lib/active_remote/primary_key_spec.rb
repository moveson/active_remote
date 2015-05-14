require 'spec_helper'

describe ActiveRemote::PrimaryKey do
  let(:tag) { Tag.new(:id => '1234', :guid => 'TAG-123', :user_guid => 'USR-123') }

  after { Tag.instance_variable_set :@primary_key, nil }

  describe ".default_primary_key" do
    it 'returns array of :guid' do
      expect(Tag.default_primary_key).to eq(:guid)
    end
  end

  describe "primary_key" do
    context "when no arguments are passed" do
      it "returns default primary key" do
        expect(Tag.primary_key).to eq(:guid)
      end
    end

    context "when arguments are passed" do
      let(:specified_primary_key) { :name }

      it "returns the given primary key" do
        expect(Tag.primary_key(specified_primary_key)).to eq(specified_primary_key)
      end
    end
  end

  describe "#primary_key" do
    it "returns the primary key for the class" do
      expect(Tag.new.primary_key).to eq Tag.primary_key
    end
  end
end
