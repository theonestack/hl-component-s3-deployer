CfhighlanderTemplate do

    Parameters do
      ComponentParam 'DeploymentSourceBucket'
      ComponentParam 'DeploymentSourceKey'
      ComponentParam 'DeploymentBucket'
      ComponentParam 'DeploymentKey', ''
      ComponentParam 'DeploymentCleanup', 'true'
    end
  
    LambdaFunctions 'deployer'
  end