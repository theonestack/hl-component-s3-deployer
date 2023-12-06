require 'json'
CloudFormation do

  deployment_filter = external_parameters.fetch(:deployment_filter, nil)

  Resource("S3DeployerCR") do
    Type 'Custom::S3Deployer'
    Property 'ServiceToken',FnGetAtt('S3Deployer','Arn')
    Property 'DeploymentSourceBucket', Ref(:DeploymentSourceBucket)
    Property 'DeploymentSourceKey', Ref(:DeploymentSourceKey)
    Property 'DeploymentBucket', Ref(:DeploymentBucket)
    Property 'DeploymentKey', Ref(:DeploymentKey)
    Property 'DeploymentFilter', FnSub(deployment_filter.to_json()) unless deployment_filter.nil?
    Property 'DeploymentMetaData', FnSub(deployment_metadata.to_json()) unless deployment_metadata.nil?
  end

end