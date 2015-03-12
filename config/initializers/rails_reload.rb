unless Rails.configuration.cache_classes
  ActionDispatch::Reloader.to_prepare do
    ActiveRecord::Base.connection_pool.with_connection do |connection|
      conn = connection.instance_variable_get(:@connection)
      connection.execute %Q(NOTIFY #{AsyncEvents::RESET_CHANNEL}, '{}')
    end
  end
end
