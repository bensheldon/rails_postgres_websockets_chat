class Message < ActiveRecord::Base
  after_create :send_notify

  default_scope { order("created_at DESC") }

  private
  def send_notify
    # Escape single quoted strings by inserting 2 of them
    self.class.connection.execute %Q(NOTIFY #{AsyncEvents::CHANNEL}, '#{to_json.gsub("'", "''")}')
    true
  end
end
