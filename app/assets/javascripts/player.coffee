class App.Player
  constructor: (@id, @name, @lastComment) ->
    @chips = []
    @score = 0
    @hasActiveChip = false

App.Player::placePicture = (intrfc) ->
  intrfc.placePicture(@id, @picture)
