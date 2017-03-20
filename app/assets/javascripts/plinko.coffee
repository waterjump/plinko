# module aliases
Engine = Matter.Engine
World = Matter.World
Bodies = Matter.Bodies
Events = Matter.Events

circles = []
rectangles = []
polygons = []
engine = undefined
board = undefined
img = undefined

class Chip
  constructor: (@gate, @img) ->

  jitter: ->
    Math.floor(Math.random() * 20) - 10
  body: ->
    Matter.Bodies.circle(
      80.5 + ((@gate - 1) * 60) + @jitter(),
      20,
      22,
      friction: 0.001,
      restitution: 0.75,
      sleepThreshold: 20,
      isChip: true
    )

placePegs = ->
  x = undefined
  y = 20
  cols = undefined
  offset = undefined
  i = 0
  while i < 13
    y = y + 50
    if i % 2 == 0
      cols = 8
      offset = 110
    else
      cols = 7
      offset = 140
    j = 0
    x = offset
    while j < cols
      circles.push Bodies.circle(
        x,
        y,
        2.5,
        isStatic: true
      )
      x = x + 60
      j++
    i++
  return

placeWalls = ->
  rectangles.push Bodies.rectangle(25,449,50,760, isStatic: true)
  rectangles.push Bodies.rectangle(615,449,50,760, isStatic: true)
  leftWallTriangle = Matter.Vertices.fromPath('0 0 30 50 0 100')
  rightWallTriangle = Matter.Vertices.fromPath('0 0 0 100 -30 50')
  i = 0
  while i < 6
    polygons = polygons.concat Bodies.fromVertices(60, 119 + 100 * i, leftWallTriangle, isStatic: true)
    polygons = polygons.concat Bodies.fromVertices(580, 119 + 100 * i, rightWallTriangle, isStatic: true)
    i++

placeBinWalls = ->
  x = 50
  i = 0
  while i < 10
    rectangles.push Bodies.rectangle(x, 780, 5, 110, isStatic: true)
    x = x + 60
    i++
  return

placeSlotNumbers = (p) ->
  i = 1
  while i < 10
    p.textSize(32)
    p.fill(0)
    p.text(parseInt(i), 10 + i * 60, 55)
    i++
  return

placeBinScores = (p) ->
  p.translate(0, 820)
  p.fill(0)
  p.rotate(-Math.PI / 2 )
  scores = ['100','500','1000','- 0 -','10,000','- 0 -','1000','500','100']
  i = 0
  while i < scores.length
    p.text(scores[i], 10, 90 + i * 60)
    i++

placeSensors = ->
  scores = [100, 500, 1000, 0, 10000, 0, 1000, 500, 100]
  offset = 80
  i = 0
  while i < scores.length
    rectangles.push(
      Bodies.rectangle(
        offset + (60 * i),
        788,
        55,
        80,
        isSensor: true,
        isStatic: true,
        category: 'score',
        value: scores[i]
      )
    )
    i++

dropChip = (gate) ->
  chip = new Chip(gate, img)
  console.log(chip.body())
  circles.push(chip.body())
  World.add engine.world, chip.body()
  Engine.update(engine)
  return

$(document).on('keyup', ->
  dropChip(Math.floor(Math.random() * 9) + 1)
)

rectX = (body) ->
  body.position.x - (rectWidth(body) / 2)

rectY = (body) ->
  body.position.y - (rectHeight(body) / 2)

rectWidth = (body) ->
  body.bounds.max.x - body.bounds.min.x

rectHeight = (body) ->
  body.bounds.max.y - body.bounds.min.y

play = ->
  setTimeout((->
    dropChip(Math.floor(Math.random() * 9) + 1)
    play()
    return
  ), 4000)
  return

drawChip = (p, body) ->
  p.fill(0)
  rad = body.circleRadius
  ctx = $('canvas')[0].getContext('2d')
  ctx.save()
  ctx.translate(body.position.x, body.position.y)
  ctx.rotate(body.angle)
  pat = ctx.createPattern($('#img')[0], "repeat")
  ctx.beginPath()
  ctx.arc(0, 0, rad, 0, 2 * Math.PI, false)
  ctx.fillStyle = pat
  ctx.fill()
  ctx.restore()
  return

drawEllipse = (p, body) ->
  p.fill(0)
  p.ellipse(body.position.x, body.position.y, body.circleRadius * 2)
  return

drawRect = (p, body) ->
  p.fill(0)
  p.rect(rectX(body), rectY(body), rectWidth(body), rectHeight(body)) if !body.isSensor
  return

drawPoly = (p, body) ->
  p.fill(0)
  vc = body.vertices
  p.triangle(vc[0].x, vc[0].y, vc[1].x, vc[1].y, vc[2].x, vc[2].y)
  return

myp = new p5 (p) ->
  p.preload = ->
    img = p.loadImage('assets/me.jpg')
    return

  p.setup = ->
    p.frameRate(60)
    engine = Engine.create(enableSleeping: true)
    engine.world = World.create({ gravity: { x: 0, y: 1, scale: 0.0009 } })

    board = p.createCanvas(641, 850)
    placePegs()
    placeWalls()
    placeBinWalls()
    placeSensors()
    rectangles.push Bodies.rectangle(320, 830, 641, 10, isStatic: true) # floor

    World.add engine.world, circles
    World.add engine.world, rectangles
    World.add engine.world, polygons

    Events.on(engine, "collisionStart", (event) ->
      console.log(event.pairs[0]) if event.pairs[0].bodyA.isSensor || event.pairs[0].bodyB.isSensor
      return
    )
    Engine.run engine
    return

  p.draw = ->
    p.clear()
    $.each engine.world.bodies, (_i, body) ->
      drawEllipse(p, body) if body.label == "Circle Body" && !body.isChip
      drawChip(p, body) if body.isChip
      drawRect(p, body) if body.label == "Rectangle Body"
      drawPoly(p, body) if body.label == "Body"
      Events.on body, 'sleepStart', (event) ->
        if !(body.isStatic)
          Matter.Composite.remove(engine.world, body)
        return
      return
    placeSlotNumbers(p)
    placeBinScores(p)
    return

checkFb = ->
  setTimeout(( ->
    response = undefined
    FB.login ( ->
      response = FB.api 'me?fields=video_broadcasts.limit(1){comments,reactions}', 'get'
      return
    ), scope: 'user_videos'
    console.log response
    checkFb()
  ), 5000)
  return

play()
