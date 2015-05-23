require_relative 'contracts_generator.rb'

module Contracts
  @config = {
    :contracts_generator => ContractsGenerator.new({}),
    :contracts_use_file => true
  }

  def self.configure(opts = {})
    opts.each do |k, v|
      @config[k.to_sym] = v if @config.has_key? k.to_sym
    end
  end

  def self.configure_with(path_to_yaml_file)
    begin
      config = YAML::load(IO.read(path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults.")
      return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults.")
      return
    end

    configure(config)
  end

  def self.config
    @config
  end
end
