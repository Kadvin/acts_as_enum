require 'spec_helper'
require 'enum'

describe ActiveModel::Acts::Enum do
  class AbstractModel
    include ActiveModel::Acts::Enum
    attr_accessor :field
  end
  describe "declare sytax language(DSL)" do
    it "should accept field and expanded array as enum values" do
      lambda{
        class ModelA < AbstractModel
          acts_as_enum :field, :value1, :value2
        end
      }.should_not raise_error
      ModelA.enums[:field][:values].should == [:value1, :value2]
    end

    it "should accept field and range as enum values" do
      lambda{
        class ModelB < AbstractModel
          acts_as_enum :field, 1..5
        end
      }.should_not raise_error
      ModelB.enums[:field][:values].should == [1,2,3,4,5]
    end

    it "should accept extra hash as options for expanded enum values" do
      lambda{
        class ModelC < AbstractModel
          acts_as_enum :field, :value1, :value2, 
            :allow_nil => true, :aliases => %W[V1 V2], :labels => %W[VA VB]
        end
      }.should_not raise_error
      ModelC.enums[:field][:values].should == [:value1, :value2]
      ModelC.enums[:field][:aliases].should == %W[V1 V2]
      ModelC.enums[:field][:labels].should == %W[VA VB]
      ModelC.enums[:field][:options].should == [['VA', :value1], ['VB',:value2]]
    end

    it "should accept extra hash as options for range enum values" do
      lambda{
        class ModelD < AbstractModel
          acts_as_enum :field, 1..5,
            :allow_nil => false, :aliases => %w[1st 2nd 3rd 4th 5th], :labels => %w[One Two Three Four Five]
        end
      }.should_not raise_error
      ModelD.enums[:field][:values].should == [1,2,3,4,5]
      ModelD.enums[:field][:aliases].should == %w[1st 2nd 3rd 4th 5th]
      ModelD.enums[:field][:labels].should == %w[One Two Three Four Five]
      ModelD.enums[:field][:options].should == [['One', 1], ['Two',2],['Three',3],['Four',4],['Five',5]]
    end
  end

  describe "should validate" do
    class ValidatableModel < AbstractModel
      include ActiveModel::Validations
    end
    it "the value in the range of the value" do
      class ModelE < ValidatableModel
        acts_as_enum :field, 1..5
      end
      record = ModelE.new
      record.field = 6
      record.should_not be_valid
      record.errors[:field].should_not be_nil
    end

    it "the value allow nil or not according to options[:allow_nil]" do
      class ModelF < ValidatableModel
        acts_as_enum :field, 1..5, :allow_nil => false
      end
      record = ModelF.new
      record.should_not be_valid
      record.errors[:field].should_not be_nil

      class ModelG < ValidatableModel
        acts_as_enum :field, 1..5, :allow_nil => true
      end
      record = ModelG.new
      record.should be_valid

      class ModelH < ValidatableModel
        # if you do not specify allow_nil option, then this field can be nil
        acts_as_enum :field, 1..5
      end
      record = ModelH.new
      record.should be_valid
    end

    it "should find the label from I18n when you do not feed with any labels" do
      I18n.stub(:t) do |*args|
        key = args.shift
        options = args.extract_options!
        scope = options[:scope]
        scope << key
        scope.join("-")
      end
      class ModelI < AbstractModel
        acts_as_enum :field, 1..3, :allow_nil => true
      end
      ModelI.field_labels.should == %w[model_i-field-1 model_i-field-2 model_i-field-3]
    end
  end

  describe "should generate method:" do
    before(:all) do
      class ModelJ < AbstractModel
        acts_as_enum :field, :value1, :value2,
          :allow_nil => true, :aliases => %W[V1 V2], :labels => %W[VA VB]
      end
    end
    it "Model.\#{fields}s to return enum values" do
      ModelJ.fields.should == [:value1, :value2]
    end
    it "Model.\#{fields}_aliases to return enum value's aliases" do
      ModelJ.field_aliases.should == %W[V1 V2]
    end
    it "Model.\#{fields}_labels to return enum value's labels" do
      ModelJ.field_labels.should == %W[VA VB]
    end
    it "Model.\#{fields}_options to return enum label-value pairs as selectable options" do
      ModelJ.field_options.should == [['VA', :value1], ['VB',:value2]]
    end
    it "Model#\#{value}_\#{field}? to return \#{field}'s enum value equals to \#{value} or not" do
      record = ModelJ.new
      record.field = :value1
      record.should be_v1_field
      record.field = :value2
      record.should be_v2_field
    end

    # hard to be test for active record reason
    it "Model#\#{value}_\#{field}s to return records which \#{field}'s enum value equals to \#{value}"
  end


end

