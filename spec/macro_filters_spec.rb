require 'yaml'

describe 'macro transformed template' do

  context 'transform' do
    it 'transforms test' do
      expect(system("ruby spec/macro.rb tests/macro_filters.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/macro_filters/template.compiled.yaml") }

  context 'Resource WebsiteDeployment' do
    let(:resource) { template["Resources"]["WebsiteDeployment"] }

    it "is of type Custom::S3Deployer" do
      expect(resource["Type"]).to eq("Custom::S3Deployer")
    end

    it "to have property DeploymentKey" do
      expect(resource["Properties"]["DeploymentKey"]).to eq("app/")
    end

    it "to have property DeploymentFilter" do
      expect(resource["Properties"]["DeploymentFilter"]).to eq({
        "Fn::Join"=>["", [
          '[{"file":"index.html","placeholder":"placeholder32256","value":"',
          {"Fn::Sub"=>"https://${APIEndpoint}.myapi.com"},
          '"}]'
        ]]
      })
    end
  end

end
