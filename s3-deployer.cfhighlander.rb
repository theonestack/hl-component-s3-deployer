CfhighlanderTemplate do

    Parameters do
      ComponentParam 'DeploymentSourceBucket'
      ComponentParam 'DeploymentSourceKey'
      ComponentParam 'DeploymentBucket'
      ComponentParam 'DeploymentKey', ''
    end
  
    LambdaFunctions 'deployer'
  end