import json
import os

MACRO_RESOURCE_TYPE = 'HLComponent::S3Deployer::Deployment'
CUSTOM_RESOURCE_TYPE = 'Custom::S3Deployer'

REQUIRED_PROPERTIES = ['DeploymentSourceBucket', 'DeploymentSourceKey', 'DeploymentBucket']
OPTIONAL_PROPERTIES = ['DeploymentKey', 'DeploymentFilter', 'DeploymentMetaData']

# properties the deployer function expects as JSON encoded strings
JSON_PROPERTIES = ['DeploymentFilter', 'DeploymentMetaData']

# resource level attributes that are carried over to the custom resource
RESOURCE_ATTRIBUTES = ['Condition', 'DependsOn', 'Metadata', 'DeletionPolicy', 'UpdateReplacePolicy']


def handler(event, context):
  print(json.dumps(event))
  try:
    fragment = transform(event['fragment'], os.environ['DEPLOYER_FUNCTION_ARN'])
    return {'requestId': event['requestId'], 'status': 'success', 'fragment': fragment}
  except Exception as ex:
    print(f'transform failed - {str(ex)}')
    return {'requestId': event['requestId'], 'status': 'failure', 'errorMessage': str(ex), 'fragment': event['fragment']}


def transform(fragment, service_token):
  resources = fragment.get('Resources', {})
  for name, resource in resources.items():
    if resource.get('Type') == MACRO_RESOURCE_TYPE:
      resources[name] = build_custom_resource(name, resource, service_token)
  return fragment


def build_custom_resource(name, resource, service_token):
  properties = resource.get('Properties', {})

  missing = [p for p in REQUIRED_PROPERTIES if p not in properties]
  if missing:
    raise ValueError(f'{name} is missing required properties: {", ".join(missing)}')

  unknown = [p for p in properties if p not in REQUIRED_PROPERTIES + OPTIONAL_PROPERTIES]
  if unknown:
    raise ValueError(f'{name} has unsupported properties: {", ".join(unknown)}')

  if 'DeploymentFilter' in properties:
    validate_filter(name, properties['DeploymentFilter'])

  custom_properties = {'ServiceToken': service_token, 'DeploymentKey': ''}
  custom_properties.update(properties)
  for p in JSON_PROPERTIES:
    if p in custom_properties:
      custom_properties[p] = encode_json(custom_properties[p])

  custom_resource = {'Type': CUSTOM_RESOURCE_TYPE, 'Properties': custom_properties}
  for attribute in RESOURCE_ATTRIBUTES:
    if attribute in resource:
      custom_resource[attribute] = resource[attribute]
  return custom_resource


def validate_filter(name, filters):
  # filters built from intrinsic functions can't be validated until deploy time
  if not isinstance(filters, list):
    return
  for f in filters:
    if isinstance(f, dict) and not any(k.startswith('Fn::') or k == 'Ref' for k in f):
      missing = [k for k in ['file', 'placeholder', 'value'] if k not in f]
      if missing:
        raise ValueError(f'{name} DeploymentFilter entry is missing: {", ".join(missing)}')


def is_intrinsic(value):
  return isinstance(value, dict) and len(value) == 1 and any(k.startswith('Fn::') or k == 'Ref' for k in value)


def encode_json(value):
  # already a JSON string, or an intrinsic function that resolves to one
  if isinstance(value, str) or is_intrinsic(value):
    return value

  parts = []
  append_json(value, parts)

  # merge adjacent strings so the result is a plain string when there are no intrinsic functions
  merged = []
  for part in parts:
    if isinstance(part, str) and merged and isinstance(merged[-1], str):
      merged[-1] += part
    else:
      merged.append(part)

  if len(merged) == 1:
    return merged[0]
  return {'Fn::Join': ['', merged]}


def append_json(value, parts):
  # intrinsic functions are resolved by CloudFormation and embedded as JSON string values
  if is_intrinsic(value):
    parts.extend(['"', value, '"'])
  elif isinstance(value, dict):
    parts.append('{')
    for i, (k, v) in enumerate(value.items()):
      parts.append((',' if i else '') + json.dumps(k) + ':')
      append_json(v, parts)
    parts.append('}')
  elif isinstance(value, list):
    parts.append('[')
    for i, v in enumerate(value):
      if i:
        parts.append(',')
      append_json(v, parts)
    parts.append(']')
  else:
    parts.append(json.dumps(value))
