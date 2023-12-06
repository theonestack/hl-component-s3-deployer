import boto3
import json
import io
import os
import sys
import traceback
import zipfile
import codecs
import mimetypes
import fnmatch

import cr_response

def handler(event, context):
  print(json.dumps(event))
  try:
    deployment_source_bucket = event['ResourceProperties']['DeploymentSourceBucket']
    deployment_source_key = event['ResourceProperties']['DeploymentSourceKey']
    deployment_bucket = event['ResourceProperties']['DeploymentBucket']
    deployment_key = ''
    if 'DeploymentKey' in event['ResourceProperties']:
      deployment_key = event['ResourceProperties']['DeploymentKey']
    request_type = event['RequestType']

    deployment_filter = []
    if 'DeploymentFilter' in event['ResourceProperties']:
      deployment_filter = json.loads(event['ResourceProperties']['DeploymentFilter'])
      print(f'using deployment filter:\n{json.dumps(deployment_filter)}')

    deployment_metadata = {}
    if 'DeploymentMetaData' in event['ResourceProperties']:
      deployment_metadata = json.loads(event['ResourceProperties']['DeploymentMetaData'])
      print(f'using deployment metadata:\n{json.dumps(deployment_metadata)}')      

    if request_type == 'Create':
      print(f'initial deployment from s3://{deployment_source_bucket}/{deployment_source_key} to s3://{deployment_bucket}/{deployment_key}')
      event['PhysicalResourceId'] = f'{deployment_source_bucket}/{deployment_source_key}'
      deploy_artifact(deployment_source_bucket, deployment_source_key, deployment_bucket, deployment_key, deployment_filter, deployment_metadata)
      r = cr_response.CustomResourceResponse(event)
      r.respond()
      return

    if request_type == 'Update':
      print(f'update deployment from s3://{deployment_source_bucket}/{deployment_source_key} to s3://{deployment_bucket}/{deployment_key}')
      old_deployment_source_bucket = event['OldResourceProperties']['DeploymentSourceBucket']
      old_deployment_source_key = event['OldResourceProperties']['DeploymentSourceKey']
      if old_deployment_source_bucket == deployment_source_bucket and old_deployment_source_key == deployment_source_key:
        # no update
        print(f's3://{deployment_source_bucket}/{deployment_source_key} is already deployed to s3://{deployment_bucket}/{deployment_key}')
        r = cr_response.CustomResourceResponse(event)
        r.respond()
        return
      else:
        deploy_artifact(deployment_source_bucket, deployment_source_key, deployment_bucket, deployment_key, deployment_filter, deployment_metadata)
        event['PhysicalResourceId'] = f'{deployment_source_bucket}/{deployment_source_key}'
        r = cr_response.CustomResourceResponse(event)
        r.respond()
        return

    if request_type == 'Delete':
      undeploy_artifact(deployment_source_bucket, deployment_source_key, deployment_bucket, deployment_key)
      r = cr_response.CustomResourceResponse(event)
      r.respond()
      return
    
  except Exception as ex:
    r = cr_response.CustomResourceResponse(event)
    print(f'{request_type} operation failed - {str(ex)}')
    r.respond_error(str(ex))
    return

def deploy_artifact(source_bucket, zip_key, dest_bucket, dest_key='', filters=[], metadata={}):
  s3_resource = boto3.resource('s3')
  zip_obj = s3_resource.Object(bucket_name=source_bucket, key=zip_key)
  buffer = io.BytesIO(zip_obj.get()["Body"].read())
  z = zipfile.ZipFile(buffer)

  for filename in z.namelist():
      file_info = z.getinfo(filename)
      dest_file = f'{dest_key}{filename}'
      print(f'uploading file {dest_file} to {dest_bucket}')
      content_type = mimetypes.guess_type(filename)[0]
      if content_type is None:
        content_type = 'binary/octet-stream'
      metadata['deployment'] = zip_key
      s3_resource.meta.client.upload_fileobj(
          filter_deployment(filename, z.open(filename), filters),
          Bucket=dest_bucket,
          Key=f'{dest_file}',
          ExtraArgs={'Metadata': metadata, 'ContentType': content_type}
      )


def undeploy_artifact(source_bucket, zip_key, dest_bucket, dest_key=''):
  s3_resource = boto3.resource('s3')
  zip_obj = s3_resource.Object(bucket_name=source_bucket, key=zip_key)
  buffer = io.BytesIO(zip_obj.get()["Body"].read())
  z = zipfile.ZipFile(buffer)
  for filename in z.namelist():
    dest_file = f'{dest_key}{filename}'
    metadata = s3_resource.meta.client.head_object(
      Bucket=dest_bucket,
      Key=f'{dest_file}'
    )
    if 'Metadata' in metadata:
      if 'deployment' in metadata['Metadata']:
        if zip_key == metadata['Metadata']['deployment']:
          print(f'undeploying file {dest_file} from {dest_bucket}')
          s3_resource.meta.client.delete_object(
            Bucket=dest_bucket,
            Key=f'{dest_file}'
          )

def filter_deployment(filename, source, filters):
  result = source
  for filter in filters:
    if fnmatch.fnmatch(filename, filter['file']):
      print(f"applying filter {filter['placeholder']}={filter['value']} to {filename}")
      source_str = result.read().decode('utf-8')
      source_str = source_str.replace(filter['placeholder'], filter['value'])
      result = io.BytesIO(source_str.encode('utf-8'))
  return  result
