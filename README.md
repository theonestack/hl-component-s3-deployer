# hl-component-s3-deployer
Component to deploy files from a zip file to an S3 bucket that also allows file filtering 

## CloudFormation macro

The same deployer is also available as a CloudFormation macro, for plain CloudFormation templates that don't use HLComponent.

### Deploying the macro

Deploy the macro once per account and region:

```bash
sam build -t macro.yaml

sam deploy \
  --stack-name s3-deployer-macro \
  --resolve-s3
```

| Parameter | Default | Description |
|---|---|---|
| `SourceBucketPattern` | `*` | Bucket(s) the deployer can read zip files from |
| `DestinationBucketPattern` | `*` | Bucket(s) the deployer can deploy files to |
| `SourceBucketAccountId` | macro account | Account that owns the source buckets |
| `DestinationBucketAccountId` | macro account | Account that owns the destination buckets |

Access is limited to buckets owned by the configured accounts (`s3:ResourceAccount`). Leave an account parameter blank to use the account the macro is deployed in. A bucket in another account must also grant the deployer role access in its bucket policy.

One deployer Lambda is shared by every stack that uses the macro. Restrict the bucket patterns to limit what it can access.

### Using the macro

Add the transform and declare a `HLComponent::S3Deployer::Deployment` resource. Intrinsic functions can be used anywhere, including inside filter values:

```yaml
Transform: HLComponentS3Deployer
Resources:
  WebsiteDeployment:
    Type: HLComponent::S3Deployer::Deployment
    Properties:
      DeploymentSourceBucket: !Ref ArtifactBucket   # required
      DeploymentSourceKey: !Ref ArtifactKey         # required
      DeploymentBucket: !Ref WebsiteBucket          # required
      DeploymentKey: app/                           # optional prefix, defaults to ''
      DeploymentFilter:                             # optional placeholder replacement
        - file: '*.html'
          placeholder: placeholder32256
          value: !Sub https://${APIEndpoint}.myapi.com
      DeploymentMetaData:                           # optional S3 object metadata
        Key1: Value1
```

Stacks that use the macro must be deployed with `CAPABILITY_AUTO_EXPAND`.

In SAM templates, list `S3Deployer` ahead of the SAM transform:

```yaml
Transform:
  - HLComponentS3Deployer
  - AWS::Serverless-2016-10-31
```

### Testing the macro

Macro tests follow the same pattern as the component tests. Each `tests/macro_*.test.yaml` file holds a template that uses the macro. [spec/macro.rb](spec/macro.rb) runs it through the macro and writes the result to `out/tests/macro_<name>/template.compiled.yaml`, and the `spec/macro_*_spec.rb` specs check that output. They run with the rest of the suite:

```bash
rspec
```
