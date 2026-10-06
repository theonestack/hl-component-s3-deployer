require 'yaml'

describe 'macro transformed template' do

  context 'transform' do
    it 'transforms test' do
      expect(system("ruby spec/macro.rb tests/macro_attributes.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/macro_attributes/template.compiled.yaml") }

  context 'Resource WebsiteDeployment' do
    let(:resource) { template["Resources"]["WebsiteDeployment"] }

    it "is of type Custom::S3Deployer" do
      expect(resource["Type"]).to eq("Custom::S3Deployer")
    end

    it "to have Condition" do
      expect(resource["Condition"]).to eq("IsProd")
    end

    it "to have DependsOn" do
      expect(resource["DependsOn"]).to eq("WebsiteBucket")
    end
  end

end
