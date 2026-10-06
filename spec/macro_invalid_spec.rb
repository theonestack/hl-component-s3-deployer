require 'open3'

describe 'macro invalid templates' do

  {
    'invalid_missing_property' => 'WebsiteDeployment is missing required properties: DeploymentSourceBucket, DeploymentSourceKey',
    'invalid_unknown_property' => 'WebsiteDeployment has unsupported properties: Bogus',
    'invalid_filter' => 'WebsiteDeployment DeploymentFilter entry is missing: placeholder'
  }.each do |test, error|
    context test do
      it 'fails to transform' do
        _, stderr, status = Open3.capture3("ruby spec/macro.rb tests/macro_#{test}.test.yaml")
        expect(status.success?).to be_falsey
        expect(stderr).to include(error)
      end
    end
  end

end
