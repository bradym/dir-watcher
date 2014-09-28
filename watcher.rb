# Watch directories and execute commands when files are modified, added or deleted.
# Inspired by https://github.com/splitbrain/Watcher
#
# Author:: Brady Mitchell (@bradymitch)
# License:: http://opensource.org/licenses/MIT

require 'rubygems'
require 'listen'
require 'yaml'
require 'trollop'

trap('SIGINT') {
  exit!
}

opts = Trollop::options do
  opt :config, 'The config file to use', :default => "#{Dir.home}/.watcher.yaml"
end

if File.exist?(opts[:config])
  config = YAML.load_file(opts[:config])
else
  abort('No config file specified, or file does not exist.')
end

def validate_job(job)
  # Check that a directory was specified
  if job['directory'].nil?
    abort('Directory must be specified.')
  end

  # Make sure the specified directory exists
  unless File.directory?(job['directory'])
    abort('Specified directory does not exist.')
  end
end

config['jobs'].each do |key, job|

  validate_job(job)

  options = {
      :filter                   => job['filter'].nil? ? nil : Regexp.new(job['filter']),
      :ignore                   => job['ignore'].nil? ? nil : Regexp.new(job['ignore']),
      :relative_paths           => job['relative_paths'].nil? ? false : job['relative_paths']
  }.reject{|key, value| value.nil?}


  Listen.to(job['directory'], options) do |modified, added, removed|

    event = {:modified => modified, :added => added, :removed => removed}.reject{|key,value| value.empty?}

    action = event.keys.first.to_s
    file   = event.values.first

    if job['command'].is_a? Hash
      unless job['command'][action].nil?
        command = job['command'][action]
      end
    else
      if job['command'].is_a? String
        command = job['command']
      end
    end

    system command
  end
end