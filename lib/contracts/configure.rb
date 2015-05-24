module Contracts
  @load_on_require = true unless defined?(@load_on_require)

  @config = {
    :contracts_generator => ContractsGenerator.new({}),
    :contracts_use_file => true
  }

  class << self
    attr_reader :load_on_require, :config
  end

  def self.load
    if Contracts.config[:contracts_use_file]
      require_relative 'contract'
    else
      Kernel::eval(Contracts::ContractsGenerator.generate, TOPLEVEL_BINDING)
    end
  end

  def self.configure(opts = {})
    opts.each do |k, v|
      @config[k.to_sym] = v if @config.has_key? k.to_sym
    end
  end

  def self.configure_with(path_to_yaml_file)
    begin
      opts = YAML::load(IO.read(path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults.")
      return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults.")
      return
    end

    configure(opts)
  end
end
