DEFAULT_PUMA_WORKERS = 2
DEFAULT_PUMA_THREADS = 3

workers Integer(ENV['PUMA_WORKERS'] || DEFAULT_PUMA_WORKERS)
threads Integer(ENV['PUMA_THREADS']  || DEFAULT_PUMA_THREADS), Integer(ENV['PUMA_THREADS'] || DEFAULT_PUMA_THREADS)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # worker specific setup
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] || Rails.application.config.database_configuration[Rails.env]
    config['pool'] = (ENV['PUMA_THREADS'] || DEFAULT_PUMA_THREADS) + 2 # TODO: why is this not 1?
    ActiveRecord::Base.establish_connection(config)
  end
end
