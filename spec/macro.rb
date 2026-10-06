# Renders a macro test file the way CloudFormation would invoke the macro, so specs
# can assert on the transformed template in out/tests/<name>/template.compiled.yaml
require 'yaml'
require 'json'
require 'open3'
require 'fileutils'

TRANSFORM_DIR = File.expand_path('../lambdas', __dir__)
DEPLOYER_FUNCTION_ARN = 'arn:aws:lambda:ap-southeast-2:123456789012:function:s3-deployer'

INVOKE_HANDLER = <<~PYTHON
  import json, sys
  sys.path.insert(0, sys.argv[1])
  import transform
  print(json.dumps(transform.handler(json.load(sys.stdin), None)))
PYTHON

# converts short form intrinsic tags (!Ref, !Sub, !GetAtt ...) into their long form
def to_cfn(node)
  value = case node
          when Psych::Nodes::Mapping
            node.children.each_slice(2).map { |k, v| [to_cfn(k), to_cfn(v)] }.to_h
          when Psych::Nodes::Sequence
            node.children.map { |child| to_cfn(child) }
          when Psych::Nodes::Scalar
            node.quoted || node.tag ? node.value : Psych::ScalarScanner.new(Psych::ClassLoader.new).tokenize(node.value)
          end

  return value unless node.tag&.start_with?('!') && !node.tag.start_with?('!!')

  name = node.tag[1..-1]
  value = value.split('.', 2) if name == 'GetAtt' && value.is_a?(String)
  { name == 'Ref' ? 'Ref' : "Fn::#{name}" => value }
end

test_file = ARGV[0]
test = to_cfn(YAML.parse_file(test_file).root)
name = test['test_metadata']['name']

event = { 'requestId' => name, 'fragment' => test['template'] }
stdout, stderr, status = Open3.capture3(
  { 'DEPLOYER_FUNCTION_ARN' => DEPLOYER_FUNCTION_ARN },
  'python3', '-c', INVOKE_HANDLER, TRANSFORM_DIR,
  stdin_data: event.to_json
)
abort("macro handler failed:\n#{stderr}") unless status.success?

result = JSON.parse(stdout.lines.last)
abort(result['errorMessage']) unless result['status'] == 'success'

out_dir = File.join('out', 'tests', name)
FileUtils.mkdir_p(out_dir)
File.write(File.join(out_dir, 'template.compiled.yaml'), result['fragment'].to_yaml)
