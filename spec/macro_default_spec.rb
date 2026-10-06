require 'yaml'

describe 'macro transformed template' do

  context 'transform' do
    it 'transforms test' do
      expect(system("ruby spec/macro.rb tests/macro_default.test.yaml")).to be_truthy
    end
  end

  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/macro_default/template.compiled.yaml") }

  context 'Resource WebsiteDeployment' do
    let(:resource) { template["Resources"]["WebsiteDeployment"] }

    it "is of type Custom::S3Deployer" do
      expect(resource["Type"]).to eq("Custom::S3Deployer")
    end

    it "to have property ServiceToken" do
      expect(resource["Properties"]["ServiceToken"]).to eq("arn:aws:lambda:ap-southeast-2:123456789012:function:s3-deployer")
    end

    it "to have property DeploymentSourceBucket" do
      expect(resource["Properties"]["DeploymentSourceBucket"]).to eq("artifacts")
    end

    it "to have property DeploymentSourceKey" do
      expect(resource["Properties"]["DeploymentSourceKey"]).to eq("website.zip")
    end

    it "to have property DeploymentBucket" do
      expect(resource["Properties"]["DeploymentBucket"]).to eq({"Ref"=>"WebsiteBucket"})
    end

    it "to have property DeploymentKey defaulted" do
      expect(resource["Properties"]["DeploymentKey"]).to eq("")
    end

    it "to not have property DeploymentFilter" do
      expect(resource["Properties"]).not_to have_key("DeploymentFilter")
    end

    it "to not have property DeploymentMetaData" do
      expect(resource["Properties"]).not_to have_key("DeploymentMetaData")
    end
  end

  context 'Resource WebsiteBucket' do
    it "is left unchanged" do
      expect(template["Resources"]["WebsiteBucket"]).to eq({"Type"=>"AWS::S3::Bucket"})
    end
  end

end
