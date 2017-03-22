class window.Player
  constructor: (@id, @name, @lastComment) ->
    @chips = []
    @score = 0
    @hasActiveChip = false

Player::placePicture = (intrfc) ->
  intrfc.placePicture(@id, @picture)
