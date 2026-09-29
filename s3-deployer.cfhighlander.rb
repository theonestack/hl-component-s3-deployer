CfhighlanderTemplate do

    Parameters do
      ComponentParam 'DeploymentSourceBucket'
      ComponentParam 'DeploymentSourceKey'
      ComponentParam 'DeploymentBucket'
      ComponentParam 'DeploymentKey', ''
      ComponentParam 'DeploymentDistribution', ''
    end
  
    LambdaFunctions 'deployer'
  end
