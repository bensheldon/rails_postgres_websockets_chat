class ChatController < ApplicationController
  def index
    @messages = Message.first(10)
  end
end
