attempts = 1
generateInterval = (attempts) ->
  maxInterval = (Math.pow(2, attempts) - 1) * 1000

  # If the generated interval is more than 30 seconds, truncate it down to 30 seconds.
  maxInterval = 30*1000 if (maxInterval > 30*1000)

  # generate the interval to a random number between 0 and the maxInterval determined from above
  Math.random() * maxInterval

ws = null
createWebsocket = ->
  scheme = "ws://" # TODO: make "wss://" in production
  uri = scheme + window.document.location.host + '/'
  ws = new WebSocket(uri)

  ws.onopen = ->
    attempts = 1 # reset

  ws.onmessage = (message) ->
    data = JSON.parse(message.data)
    $('#chat-text').prepend '<div class=\'panel panel-default\'><div class=\'panel-heading\'>' + data.author + '</div><div class=\'panel-body\'>' + data.body + '</div></div>'
    $('#chat-text').stop().animate { scrollTop: $('#chat-text')[0].scrollHeight }, 800

  ws.onclose = ->
    setTimeout ->
      attempts++
      createWebsocket()
    , generateInterval(attempts)

# Initialize the websocket
createWebsocket()

$ ->
  $('#input-form').on 'submit', (event) ->
    event.preventDefault()
    author = $('#input-author')[0].value
    body = $('#input-body')[0].value
    ws.send JSON.stringify(
      author: author
      body: body)
    $('#input-body')[0].value = ''
    return
