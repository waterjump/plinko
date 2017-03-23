App.circles = []
App.rectangles = []
App.polygons = []
App.engine = undefined
App.players = []
App.activeChips = []
App.myInterface = new App.Interface()
App.gameStart = (new Date).toISOString()

myp = new p5 (p) ->
  # module aliases
  Engine = Matter.Engine
  World = Matter.World
  Bodies = Matter.Bodies
  Events = Matter.Events
  engine = App.engine
  circles = App.circles
  rectangles = App.rectangles
  polygons = App.polygons
  activeChips = App.activeChips

  p.setup = ->
    p.frameRate(30)
    engine = Engine.create(enableSleeping: true)
    engine.world = World.create({ gravity: { x: 0, y: 1, scale: 0.0009 } })

    p.createCanvas(641, 850)
    App.myInterface.placePegs(circles)
    App.myInterface.placeWalls(polygons, rectangles)
    App.myInterface.placeBinWalls(rectangles)
    App.myInterface.placeSensors(rectangles)
    rectangles.push Bodies.rectangle(320, 830, 641, 10, isStatic: true) # floor

    World.add engine.world, circles
    World.add engine.world, rectangles
    World.add engine.world, polygons

    Events.on(engine, "collisionStart", (event) ->
      bodies = [event.pairs[0].bodyA, event.pairs[0].bodyB]
      sensor = bodies.filter( (b) -> return b.isSensor )[0]
      if sensor != undefined
        body = bodies.filter( (b) -> return b.isChip )[0]
        player = body.chip.player
        player.score = player.score + sensor.value
        App.myInterface.updateScore(App.players)
      return
    )
    Engine.run engine
    return

  p.dropChip = (chip) ->
    circles.push(chip.body)
    chip.player.hasActiveChip = true
    World.add engine.world, chip.body
    Engine.update(engine)
    return

  p.draw = ->
    p.clear()
    $.each engine.world.bodies, (_i, body) ->
      App.myInterface.drawEllipse(p, body) if body.label == "Circle Body" && !body.isChip
      $.each(activeChips, (_i, chip) ->
        App.myInterface.drawChip(p, chip)
      )
      App.myInterface.drawRect(p, body) if body.label == "Rectangle Body"
      App.myInterface.drawPoly(p, body) if body.label == "Body"
      Events.on body, 'sleepStart', (event) ->
        if !(body.isStatic) && body.position.y > 750
          body.chip.player.hasActiveChip = false
          activeChips = activeChips.filter( (chip) ->
            chip != body.chip
          )
          Matter.Composite.remove(engine.world, body)
        return
      return
    App.myInterface.placeSlotNumbers(p)
    App.myInterface.placeBinScores(p)
    return

hitFb = ->
  myp.httpGet(
     'https://graph.facebook.com/v2.8/me?fields=live_videos.limit(1)%7Bstatus%2Ccomments%7D&access_token=EAACBSzUTHmYBAH7kRC0egn7bMymktoEqqAY9eDmZCmYYrkLzKZCyZB1B4nVbgTZAdXHK3lOzyiWt2eLID9tiXbkyMvztFry1ZBo3ciGVVLZBC9IQ48WmUPXPULzduH6OXWxzaWaEO1HZCRK8TKoyokpeMZCPEvodcEcZD',
     {},
    'json',
    App.setupPlayer
  )
  return


App.fetchPicture = (id) ->
  result = undefined
  $.ajax(
    async: false,
    headers: { Accept : "application/json" }
    method: 'GET'
    url: 'https://graph.facebook.com/v2.8/' + id + '/picture?redirect=false&access_token=EAACBSzUTHmYBAH7kRC0egn7bMymktoEqqAY9eDmZCmYYrkLzKZCyZB1B4nVbgTZAdXHK3lOzyiWt2eLID9tiXbkyMvztFry1ZBo3ciGVVLZBC9IQ48WmUPXPULzduH6OXWxzaWaEO1HZCRK8TKoyokpeMZCPEvodcEcZD',
    success: (json) ->
      result = json.data.url
  )
  result

App.newPlayer = (id, name, msg, time) ->
  return if time < @gameStart
  player = new App.Player(id, name, time)
  chip = new App.Chip(msg, player, time)
  @activeChips.push(chip)
  player.picture = @fetchPicture(player.id)
  player.placePicture(@myInterface)
  player.chips.push chip
  @players.push player
  @myInterface.updateScore(@players)
  myp.dropChip(chip)

App.updatePlayer = (player, msg, time) ->
  if time > player.lastComment && !player.hasActiveChip && time > @gameStart && player.chips.length < 5
    player.lastComment = time
    chip = new App.Chip(msg, player, time)
    @activeChips.push(chip)
    player.chips.push(chip)
    myp.dropChip(chip)

App.compare = (a,b) ->
  if a.created_time < b.created_time
    return -1
  if a.created_time > b.created_time
    return 1
  0

App.setupPlayer = (json) ->
  comments = json.live_videos.data[0].comments.data
  comments = comments.sort(App.compare)
  $.each(comments, ((_i, comment) ->
    name = comment.from.name
    id = comment.from.id
    message = comment.message.trim()
    time = comment.created_time
    values = ['1','2','3','4','5','6','7','8','9']
    if values.includes(message)
      player = App.players.filter( (p) ->
        return p.id == id
      )[0]
      if player == undefined
        App.newPlayer(id, name, message, time)
      else
        console.log player
        App.updatePlayer(player, message, time)
    )
  )
  return

window.onload = foo = ->
  hitFb()
  setInterval(hitFb, 5000)
  return
