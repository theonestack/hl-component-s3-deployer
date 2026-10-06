require 'yaml'

describe 'macro transformed template' do

  context 'transform' do
    it 'transforms test' do
      expect(system("ruby spec/macro.rb tests/macro_metadata.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/macro_metadata/template.compiled.yaml") }

  context 'Resource WebsiteDeployment' do
    let(:resource) { template["Resources"]["WebsiteDeployment"] }

    it "is of type Custom::S3Deployer" do
      expect(resource["Type"]).to eq("Custom::S3Deployer")
    end

    it "to have property DeploymentMetaData" do
      expect(resource["Properties"]["DeploymentMetaData"]).to eq('{"Key1":"Value1"}')
    end
  end

end
