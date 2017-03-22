class window.Chip
  constructor: (@gate, @player, @time) ->
    @jitter = @jitter || Math.floor(Math.random() * 20) - 10
    @body = @body ||
      Matter.Bodies.circle(
        80.5 + ((@gate - 1) * 60) + @jitter,
        20,
        22,
        friction: 0.001,
        restitution: 0.75,
        sleepThreshold: 20,
        isChip: true,
        chip: @
      )
    # activeChips = activeChips.concat(@)

