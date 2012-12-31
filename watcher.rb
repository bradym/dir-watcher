# Watch directories and execute commands when files are modified, added or deleted.
# Inspired by https://github.com/splitbrain/Watcher
#
# Author:: Brady Mitchell (@bradymitch)
# License:: http://opensource.org/licenses/MIT

require 'rubygems'
require 'listen'
require 'yaml'

trap("SIGINT") {
  exit!
}

config = YAML.load_file('config.yaml')

def validateJob(job)
  # Check that a directory was specified
  if job["directory"].nil?
    abort("Directory must be specified.")
  end

  # Make sure the specified directory exists
  unless File.directory?(job["directory"])
    abort("Specified directory does not exist.")
  end
end

config["jobs"].each do |key, job|

  validateJob(job)

  # Set options for the watcher
  options = {
    :filter                   => job["filter"].nil? ? nil : Regexp.new(job["filter"]),
    :ignore                   => job["ignore"].nil? ? nil : Regexp.new(job["ignore"]),
    :relative_paths           => job["relative_paths"].nil? ? false : job["relative_paths"]
  }

  unless config["generic"].nil?
    options[:polling_fallback_message] = config["generic"]["polling_message"].nil? ? false : config["generic"]["polling_message"]
    options[:latency]                  = config["generic"]["latency"].nil? ? 0.25 : config["generic"]["latency"]
    options[:force_polling]            = config["generic"]["force_polling"].nil? ? false : config["generic"]["force_polling"]
  end

  # filter out nil values
  options = options.reject{|key, value| value.nil?}

  Listen.to(job["directory"], options) do |modified, added, removed|

    action = nil
    file   = nil

    unless modified.nil? || modified.empty?
      action = "modified"
      file   = modified
    end

    unless added.nil? || added.empty?
      action = "added"
      file   = added
    end

    unless removed.nil? || removed.empty?
      action = "removed"
      file   = removed
    end

    if job["command"].is_a? Hash
      unless job["command"][action].nil?
        system job["command"][action]
      end
    else
      if job["command"].is_a? String
        system job["command"]
      end
    end
  end
end