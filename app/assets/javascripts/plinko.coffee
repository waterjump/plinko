# module aliases
Engine = Matter.Engine
World = Matter.World
Bodies = Matter.Bodies
Events = Matter.Events

circles = []
rectangles = []
polygons = []
engine = undefined
img = undefined
response = undefined
players = []
activeChips = []
myInterface = new Interface()
gameStart = (new Date).toISOString()

fetchPicture = (id) ->
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

dropChip = (chip) ->
  console.log(chip)
  circles.push(chip.body)
  chip.player.hasActiveChip = true
  World.add engine.world, chip.body
  Engine.update(engine)
  return

myp = new p5 (p) ->
  p.setup = ->
    p.frameRate(30)
    engine = Engine.create(enableSleeping: true)
    engine.world = World.create({ gravity: { x: 0, y: 1, scale: 0.0009 } })

    p.createCanvas(641, 850)
    myInterface.placePegs(circles)
    myInterface.placeWalls(polygons, rectangles)
    myInterface.placeBinWalls(rectangles)
    myInterface.placeSensors(rectangles)
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
        myInterface.updateScore(players)
      return
    )
    Engine.run engine
    return

  p.draw = ->
    p.clear()
    $.each engine.world.bodies, (_i, body) ->
      myInterface.drawEllipse(p, body) if body.label == "Circle Body" && !body.isChip
      $.each(activeChips, (_i, chip) ->
        myInterface.drawChip(p, chip)
      )
      myInterface.drawRect(p, body) if body.label == "Rectangle Body"
      myInterface.drawPoly(p, body) if body.label == "Body"
      Events.on body, 'sleepStart', (event) ->
        if !(body.isStatic) && body.position.y > 750
          body.chip.player.hasActiveChip = false
          activeChips = activeChips.filter( (chip) ->
            chip != body.chip
          )
          Matter.Composite.remove(engine.world, body)
        return
      return
    myInterface.placeSlotNumbers(p)
    myInterface.placeBinScores(p)
    return

newPlayerQ = (id, name, msg, time) ->
  return if time < gameStart
  newPlayer = new Player(id, name, time)
  chip = new Chip(msg, newPlayer, time)
  activeChips.push(chip)
  newPlayer.picture = fetchPicture(newPlayer.id)
  newPlayer.placePicture(myInterface)
  newPlayer.chips.push chip
  players.push newPlayer
  myInterface.updateScore(players)
  dropChip(chip)

updatePlayer = (player, msg, time) ->
  console.log gameStart
  console.log time
  console.log (time > gameStart)
  if time > player.lastComment && !player.hasActiveChip && time > gameStart && player.chips.length < 5
    player.lastComment = time
    chip = new Chip(msg, player, time)
    activeChips.push(chip)
    player.chips.push(chip)
    dropChip(chip)

compare = (a,b) ->
  if a.created_time < b.created_time
    return -1
  if a.created_time > b.created_time
    return 1
  0

setupPlayer = (json) ->
  console.log json
  comments = json.live_videos.data[0].comments.data
  comments = comments.sort(compare)
  console.log comments
  i = 0
  while i < comments.length
    name = comments[i].from.name
    id = comments[i].from.id
    message = comments[i].message.trim()
    time = comments[i].created_time
    values = ['1','2','3','4','5','6','7','8','9']
    if values.includes(message)
      player = players.filter( (p) ->
        return p.id == id
      )[0]
      if player == undefined
        newPlayerQ(id, name, message, time)
      else
        console.log player
        updatePlayer(player, message, time)
      i++

checkFb = ->
  setTimeout(( ->
    $.ajax(
      method: 'GET'
      url: 'https://graph.facebook.com/v2.8/me?fields=live_videos.limit(1)%7Bstatus%2Ccomments%7D&access_token=EAACBSzUTHmYBAH7kRC0egn7bMymktoEqqAY9eDmZCmYYrkLzKZCyZB1B4nVbgTZAdXHK3lOzyiWt2eLID9tiXbkyMvztFry1ZBo3ciGVVLZBC9IQ48WmUPXPULzduH6OXWxzaWaEO1HZCRK8TKoyokpeMZCPEvodcEcZD'
    ).done (json) ->
      setupPlayer(json)
      return
    checkFb()
    return
  ), 5000)
  return

checkFb()
