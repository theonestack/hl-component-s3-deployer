require 'yaml'
require 'json'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/metadata.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/metadata/s3-deployer.compiled.yaml") }

  it 'passes DeploymentMetaData as a list of file rules' do
    metadata = template['Resources']['S3DeployerCR']['Properties']['DeploymentMetaData']
    expect(metadata).not_to be_nil
  end
  
end
