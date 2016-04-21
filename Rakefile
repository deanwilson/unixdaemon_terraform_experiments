require 'fileutils'
require 'rspec/core/rake_task'
require 'tmpdir'

BUCKET_REGION = 'eu-west-1'
BUCKET_NAME   = "net.dean-wilson-terraform-state-#{BUCKET_REGION}-#{ENV['DEPLOY_ENV']}"
ALLOWED_ENVIRONMENTS = %w(test staging production)

##### You should not need to edit anything under here

PROJECT_DIR = 'projects'.freeze


desc 'Validate the environment and required variables'
task :validate_environment do
  unless ENV.include?('DEPLOY_ENV') && ALLOWED_ENVIRONMENTS.include?(ENV['DEPLOY_ENV'])
    warn "Please set 'DEPLOY_ENV' environment variable to one of #{ALLOWED_ENVIRONMENTS.join(', ')}"
    exit 1
  end

  unless ENV.include?('PROJECT_NAME')
    warn 'Please set the "PROJECT_NAME" environment variable.'
    exit 1
  end

  unless project_name.empty?
    unless File.exist? File.join(PROJECT_DIR, project_name)
      warn "Unable to find project #{project_name} in #{PROJECT_DIR}"
      exit 1
    end
  end
end


desc 'Check for a local statefile'
task :local_state_check do
  state_file = 'terraform.tfstate'

  if File.exist? state_file
    warn "Local state file (#{state_file}) should not exist. We use remote state files."
    exit 1
  end
end


desc 'Purge remote state file'
task :purge_remote_state do
  state_file = '.terraform/terraform.tfstate'

  FileUtils.rm state_file if File.exist? state_file

  if File.exist? state_file
    warn "state file #{state_file} should not exist."
    exit 1
  end
end


desc 'Configure the remote state location'
task configure_state: [:validate_environment, :purge_remote_state] do

  args = []
  args << 'terraform remote config'
  args << '-backend=s3'
  args << '-backend-config="acl=private"'
  args << "-backend-config='bucket=#{BUCKET_NAME}'"
  args << '-backend-config="encrypt=true"'
  args << "-backend-config='key=terraform-#{project_name}.tfstate'"
  args << "-backend-config='region=#{BUCKET_REGION}'"

  system(args.join(' ')) or raise 'Error running Terraform to configure state'
end


desc 'Show the terraform plan'
task plan: [:configure_state] do
  tmp_dir = _flatten_project

  system("terraform plan -module-depth=-1 #{common_args} #{tmp_dir}")

  FileUtils.rm_r tmp_dir unless debug
end


desc 'Apply the terraform resources'
task apply: [:configure_state] do
  tmp_dir = _flatten_project

  command = "terraform apply #{common_args} #{tmp_dir}"

  puts command

  system(command)

  FileUtils.rm_r tmp_dir unless debug
end


desc 'Destroy terraform resources'
task destroy: [:configure_state] do
  tmp_dir = _flatten_project

  command = "terraform destroy #{common_args} #{tmp_dir}"

  puts command

  system(command)

  FileUtils.rm_r tmp_dir unless debug
end


desc 'create and display the resource graph'
task graph: [:configure_state] do
  tmp_dir = _flatten_project

  system("terraform graph #{tmp_dir} | dot -Tpng > graph.png")

  FileUtils.rm_r tmp_dir unless debug
end


desc 'Run the given projects awsspec tests'
RSpec::Core::RakeTask.new('spec') do |task|
  spec_dir = File.join(PROJECT_DIR, project_name, 'spec')

  base_specs        = Dir["#{spec_dir}/*_spec.rb"]
  environment_specs = Dir["#{spec_dir}/#{deploy_env}/*_spec.rb"]

  all_specs = base_specs + environment_specs

  task.pattern = all_specs.join(',')
end


# Terraform doesn't let you have .tf files in nested subdirectories so
# _flatten_project grabs all the terraform files we want in our run
# and combines them in to a single directory.

def _flatten_project
  tmp_dir   = Dir.mktmpdir('tf-temp')
  base_path = File.join(PROJECT_DIR, project_name, 'resources')

  # add an inner loop here if we want to copy other file extensions too
  ['configs', base_path, "#{base_path}/#{deploy_env}"].each do |dir|
    next if Dir["#{dir}/*.tf"].empty?

    puts "Working on #{Dir[dir + '/*.tf']}" if debug
    system("terraform get #{dir}")
    FileUtils.cp(Dir["#{dir}/*.tf"], tmp_dir)
  end

  tmp_dir
end


########################### Util functions

def debug
  ENV['DEBUG']
end

def deploy_env
  ENV['DEPLOY_ENV']
end

def project_name
  ENV['PROJECT_NAME']
end

def common_args
  " -var-file=variables/#{deploy_env}.tfvars "
end
