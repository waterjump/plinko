Bodies = Matter.Bodies

class App.Interface

App.Interface::drawChip = (p, chip) ->
  body = chip.body
  p.fill(0)
  rad = body.circleRadius
  ctx = $('canvas')[0].getContext('2d')
  ctx.save()
  ctx.translate(body.position.x, body.position.y)
  ctx.rotate(body.angle)
  pat = ctx.createPattern(chip.player.element, "repeat")
  ctx.beginPath()
  ctx.arc(0, 0, rad, 0, 2 * Math.PI, false)
  ctx.fillStyle = pat
  ctx.fill()
  ctx.restore()
  return

App.Interface::drawEllipse = (p, body) ->
  p.ellipse(body.position.x, body.position.y, body.circleRadius * 2)
  return

App.Interface::drawRect = (p, body) ->
  p.rect(@rectX(body), @rectY(body), @rectWidth(body), @rectHeight(body)) if !body.isSensor
  return

App.Interface::drawPoly = (p, body) ->
  vc = body.vertices
  p.triangle(vc[0].x, vc[0].y, vc[1].x, vc[1].y, vc[2].x, vc[2].y)
  return

App.Interface::placePegs = (circles) ->
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

App.Interface::placePicture = (id, picture) ->
  $('body').append(
    '<img id="' + id + '" class="off-screen" src="' + picture + '" />'
  )

App.Interface::placeWalls = (polygons, rectangles) ->
  rectangles.push Bodies.rectangle(25,420,50,830, isStatic: true)
  rectangles.push Bodies.rectangle(615,420,50,830, isStatic: true)
  leftWallTriangle = Matter.Vertices.fromPath('0 0 30 50 0 100')
  rightWallTriangle = Matter.Vertices.fromPath('0 0 0 100 -30 50')
  i = 0
  while i < 6
    polygons.push Bodies.fromVertices(60, 119 + 100 * i, leftWallTriangle, isStatic: true)
    polygons.push Bodies.fromVertices(580, 119 + 100 * i, rightWallTriangle, isStatic: true)
    i++

App.Interface::placeBinWalls = (rectangles) ->
  x = 50
  i = 0
  while i < 10
    rectangles.push Bodies.rectangle(x, 780, 5, 110, isStatic: true)
    x = x + 60
    i++
  return

App.Interface::placeSlotNumbers = (p) ->
  i = 1
  while i < 10
    p.textSize(40)
    p.fill(0)
    p.text(parseInt(i), 10 + i * 60, 55)
    i++
  return

App.Interface::rectWidth = (body) ->
  body.bounds.max.x - body.bounds.min.x

App.Interface::rectHeight = (body) ->
  body.bounds.max.y - body.bounds.min.y

App.Interface::rectX = (body) ->
  body.position.x - (@rectWidth(body) / 2)

App.Interface::rectY = (body) ->
  body.position.y - (@rectHeight(body) / 2)

App.Interface::placeBinScores = (p) ->
  p.translate(0, 820)
  p.fill(0)
  p.rotate(-Math.PI / 2 )
  scores = ['100','500','1000','- 0 -','10,000','- 0 -','1000','500','100']
  i = 0
  while i < scores.length
    p.text(scores[i], 10, 90 + i * 60)
    i++

App.Interface::placeSensors = (rectangles) ->
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

App.Interface.compare = (a,b) ->
  if a.score < b.score
    return -1
  if a.score > b.score
    return 1
  0

App.Interface::updateScore = (players) ->
  $('#scoreboard').html ''
  newHtml = '<tr><td>Player</td><td>Score&nbsp;</td><td>Chips left</td></tr>'
  $.each(players.sort(App.Interface.compare).reverse(), (i, player) ->
    newHtml = newHtml + '<tr><td>' + parseInt(i + 1) + '. ' + player.name + '&nbsp;&nbsp;</td><td>' + parseInt(player.score) + '&nbsp;</td><td>' + parseInt(5 - player.chips.length) + '</td></tr>'
  )
  $('#scoreboard').html newHtml
