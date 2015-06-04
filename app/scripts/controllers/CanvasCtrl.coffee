"use strict"

_ = require "lodash"
moment = require "moment"

angular.module("app.controllers.CanvasCtrl", []).controller "CanvasCtrl", [
	"$scope"
	"$location"
	"$document"

	($scope, $location, $document) ->

		# A very dirty input handling
		timePressed = {}
		keysPressed = {}
		keyCodes =
			65: "a"
			66: "b"
			37: "left"
			38: "up"
			39: "right"
			40: "down"
			13: "select"
		$document.on "keydown", (event) ->
			if event.keyCode of keyCodes
				code = keyCodes[event.keyCode]
				$scope.mainApp.key code
				event.preventDefault()

				now = +moment()
				if not timePressed[event.keyCode]
					timePressed[event.keyCode] = now
				if timePressed[event.keyCode]? and now - timePressed[event.keyCode] > 1000
					$scope.mainApp.longKey code
					delete timePressed[event.keyCode]
				keysPressed[code] = true
		$document.on "keyup", (event) ->
			delete timePressed[event.keyCode]
			if event.keyCode of keyCodes
				delete keysPressed[keyCodes[event.keyCode]]
		$document.on "mousedown", (event) ->
			alert JSON.stringify {x: event.offsetX, y: event.offsetY}

		# Processing sketch to do all the drawing
		$scope.sketch = (sketch) ->
			canvasSize =
				width: 730
				height: 380
			screenSize =
				width: 64
				height: 48
			screenScale =
				x: 3
				y: 3
			screenPosition =
				x: canvasSize.width / 2
				y: canvasSize.height / 2 - 30
			keyCoords =
				left: [89, 207, 123, 168, 125, 244]
				right: [202, 246, 238, 207, 199, 170]
				up: [124, 168, 163, 133, 199, 170]
				down: [124, 244, 163, 282, 202, 246]
				select: [135, 185, 45, 45]
				a: [530, 100, 75, 75]
				b: [530, 250, 75, 75]
			keyFunctions =
				left: "triangle"
				right: "triangle"
				up: "triangle"
				down: "triangle"
				select: "rect"
				a: "rect"
				b: "rect"
			mainFont = null
			largerFont = null
			bgImage = null
			screen = null

			sketch.setup = ->
				sketch.hint sketch.DISABLE_OPENGL_2X_SMOOTH
				sketch.size canvasSize.width, canvasSize.height, sketch.P2D
				sketch.frameRate 10
				bgImage = sketch.loadImage "background.jpg"
				sketch.imageMode sketch.CENTER

				mainFont = sketch.createFont "pixelmix.ttf", 8, false
				largerFont = sketch.createFont "pixelmix.ttf", 16, false
				sketch.textFont mainFont

				screen = sketch.createGraphics screenSize.width, screenSize.height
				screen.largerFont = largerFont
				screen.mainFont = mainFont
				screen.textAlign screen.CENTER, screen.CENTER
				screen.textFont mainFont
				screen.noSmooth()

			sketch.draw = ->
				sketch.background 0, 0
				sketch.image bgImage, canvasSize.width / 2, canvasSize.height / 2

				# Render screen
				sketch.drawScreen()
				sketch.tint 30, 200, 250
				sketch.image screen, screenPosition.x, screenPosition.y,
					screenSize.width * screenScale.x, screenSize.height * screenScale.y
				sketch.noTint()

				# Draw grid
				sketch.stroke 0, 50
				for x in [screenPosition.x - screenSize.width / 2 * screenScale.x .. screenPosition.x + screenSize.width / 2 * screenScale.x] by screenScale.x
					sketch.line x, screenPosition.y - screenSize.height / 2 * screenScale.y, x, screenPosition.y + screenSize.height / 2 * screenScale.y
				for y in [screenPosition.y - screenSize.height / 2 * screenScale.y .. screenPosition.y + screenSize.height / 2 * screenScale.y] by screenScale.y
					sketch.line screenPosition.x - screenSize.width / 2 * screenScale.x, y, screenPosition.x + screenSize.width / 2 * screenScale.x, y

				# Key presses
				sketch.fill 200, 100
				for own key, pressed of keysPressed
					continue unless pressed
					sketch[keyFunctions[key]].apply sketch, keyCoords[key]

			sketch.drawScreen = ->
				screen.fill 0
				screen.noStroke()
				screen.rect 0, 0, screenSize.width, screenSize.height

				# Draw frame (four corner-pixels)
				screen.fill 255
				screen.rect 0, 0, 1, 1
				screen.rect screenSize.width - 1, 0, 1, 1
				screen.rect 0, screenSize.height - 1, 1, 1
				screen.rect screenSize.width - 1, screenSize.height - 1, 1, 1

				$scope.mainApp.draw screen, screenSize

				screen.filter sketch.THRESHOLD, 0.9

		# Some globals for all apps below
		globalFontSize = 8

		# Cool library classes
		ui = {}
		ui.settings = ->
			rows = []

			draw: ->
			addIntegerRow: (label) ->

		# Our application database
		apps = {}
		apps.test = ->
			coords =
				x: 0
				y: 0
			fillMode = false

			draw: (screen) ->
				if fillMode
					screen.fill 255
					screen.rect 0, 0, screen.size.width, screen.size.height
				screen.ellipse coords.x, coords.y, 10, 10
			key: (key) ->
				switch key
					when "a"
						fillMode = true
					when "b"
						fillMode = false
					when "up"
						coords.y--
					when "down"
						coords.y++
					when "left"
						coords.x--
					when "right"
						coords.x++
					when "select"
						coords.x = coords.y = 0
		apps.test.metadata =
			name: "Test"
			icon: (screen, size) ->
				for i in [1..200]
					x = Math.ceil Math.random() * size.width - 1
					y = Math.ceil Math.random() * size.height - 1
					screen.rect x, y, 1, 1

		apps.none = ->
			draw: ->
			key: ->
		apps.none.metadata = 
			name: "None"
			icon: (screen, size) ->
				screen.stroke 255
				screen.noFill()
				screen.rect 0, 0, size.width, size.height

		apps.keyTest = ->
			lastKey = ""
			draw: (screen, size) ->
				screen.text lastKey, size.width / 2, size.height / 2
			key: (key) ->
				lastKey = key
			longKey: (key) ->
				lastKey = "long\n#{key}"
		apps.keyTest.metadata =
			name: "KeyTest"
			icon: (screen, size) ->
				screen.textFont screen.largerFont
				screen.text "K", size.width / 2 + 1, size.height / 2
				screen.textFont screen.mainFont

		apps.ping = ->
			coords =
				x: 10
				y: 10
			speed =
				x: 1
				y: 1

			draw: (screen, size) ->
				screen.ellipse coords.x, coords.y, 5, 5
				coords.x += speed.x
				coords.y += speed.y
				if coords.x + 5 > size.width or coords.x - 5 < 0
					speed.x = -speed.x
				if coords.y + 5 > size.height or coords.y - 5 < 0
					speed.y = -speed.y
		apps.ping.metadata =
			icon: (screen, size) ->
				screen.textFont screen.largerFont
				screen.text "o", size.width / 2 + 1, size.height / 2
				screen.textFont screen.mainFont
			name: "Ping"

		apps.pong = ->
			ball =
				coords:
					x: 10
					y: 10
				speed:
					x: 2
					y: 1
				size: 5
			caretSpeed = 1
			caretOffset = 2
			caretYses = [10, 10]
			caretSize = 10
			screenSize = null
			scores = [0, 0]

			initBall = ->
				ball.coords.x = screenSize.width / 2
				ball.coords.y = screenSize.height / 2

			draw: (screen, size) ->
				if not screenSize
					screenSize = size
					initBall()
				# Midline
				for i in [1..10]
					y = screen.lerp 0, size.height, i / 10
					screen.point size.width / 2, y
				# Score
				screen.textAlign screen.RIGHT, screen.TOP
				screen.text "#{scores[0]}", screen.width / 2, 1
				screen.textAlign screen.LEFT, screen.TOP
				screen.text "#{scores[1]}", screen.width / 2 + 2, 1
				screen.textAlign screen.CENTER, screen.CENTER
				# Carets
				screen.rect caretOffset, caretYses[0], 1, caretSize
				screen.rect size.width - caretOffset - 2, caretYses[1], 1, caretSize
				# Ball
				screen.ellipse ball.coords.x, ball.coords.y, ball.size, ball.size
				ball.coords.x += ball.speed.x
				ball.coords.y += ball.speed.y
				# Height bounces
				if ball.coords.y + ball.size > size.height or ball.coords.y - ball.size < 0
					ball.speed.y = -ball.speed.y
				# Width bounces
				if ball.coords.x - ball.size < 3
					if caretYses[0] < ball.coords.y < caretYses[0] + caretSize
						ball.speed.x = -ball.speed.x
					else
						scores[1]++
						initBall()
				if ball.coords.x + ball.size > size.width - 3
					if caretYses[1] < ball.coords.y < caretYses[1] + caretSize
						ball.speed.x = -ball.speed.x
					else
						scores[0]++
						initBall()
				# AI
				if ball.coords.x > size.width / 2 and ball.speed.x > 0
					direction = ball.coords.y - caretYses[1] - caretSize / 2
					direction /= Math.abs direction unless direction is 0
					caretYses[1] += caretSpeed * direction

			key: (key) ->
				caretYses[0] -= caretSpeed if key is "up"
				caretYses[0] += caretSpeed if key is "down"
				if caretYses[0] < 2
					caretYses[0] = 2
				if caretYses[0] > screenSize.height - caretSize - 3
					caretYses[0] = screenSize.height - caretSize - 3
		apps.pong.metadata =
			name: "Pong"
			icon: (screen, size) ->
				screen.textFont screen.largerFont
				screen.text "o-o", size.width / 2 + 1, size.height / 2
				screen.textFont screen.mainFont

		apps.settings = ->
			ui = ui.settings()
			draw: (screen, size) ->
		apps.settings.metadata =
			name: "Settings"
			icon: (screen, size) ->
				screen.textFont screen.largerFont
				screen.text "-s-", size.width / 2 + 1, size.height / 2
				screen.textFont screen.mainFont

		apps.calendar = ->
			draw: (screen, size) ->
				screen.text moment().format("L"), size.width / 2, 10
				screen.text moment().format("HH:mm:ss"), size.width / 2, 20
		apps.calendar.metadata =
			name: "Calendar"
			icon: (screen, size) ->
				screen.textFont screen.largerFont
				screen.text "-_-", size.width / 2 + 1, size.height / 2
				screen.textFont screen.mainFont

		apps.taskBar = ->
			draw: (screen, size) ->
				screen.stroke 255
				screen.line 0, size.height - 1, size.width, size.height - 1
				screen.text moment().format("HH:mm"), size.width / 2 + size.width / 4, 5

		apps.mainMenu = ->
			appList = _.keys _.pick apps, (a) -> a.metadata?
			currentIdx = 0
			currentApp = apps[appList[currentIdx]]
			currentApp.id = appList[currentIdx]
			iconSize = null
			iconOffset =
				x: 10
				y: 2

			draw: (screen, size) ->
				# Update icon size
				iconSize ?=
					width: size.width - 20
					height: size.height - 16
				# Draw icon
				screen.pushMatrix()
				screen.translate iconOffset.x, iconOffset.y
				currentApp.metadata.icon? screen, iconSize
				screen.popMatrix()
				# Draw title
				screen.fill 255
				screen.text currentApp.metadata.name,
					size.width / 2, size.height - globalFontSize
				# Draw arrows
				screen.stroke 255
				screen.triangle iconOffset.x / 2, iconOffset.y + iconSize.height / 2,
					iconOffset.x - 1, iconOffset.y + 5,
					iconOffset.x - 1, iconOffset.y + iconSize.height - 5
				iconLeft = iconOffset.x + iconSize.width
				screen.triangle iconLeft + iconOffset.x / 2 + 1, iconOffset.y + iconSize.height / 2,
					iconLeft + 2, iconOffset.y + 5,
					iconLeft + 2, iconOffset.y + iconSize.height - 5
			key: (key) ->
				switch key
					when "left"
						currentIdx--
						if currentIdx < 0
							currentIdx = appList.length - 1
						currentApp = apps[appList[currentIdx]]
						currentApp.id = appList[currentIdx]
					when "right"
						currentIdx++
						if currentIdx >= appList.length
							currentIdx = 0
						currentApp = apps[appList[currentIdx]]
						currentApp.id = appList[currentIdx]
					when "select"
						$scope.mainApp.runApp currentApp.id

		$scope.app = ->
			runningApps = {}
			mainMenu = apps.mainMenu()
			foregroundApp = mainMenu
			taskBar = apps.taskBar()
			taskBarHeight = 10
			blanked = false

			runApp: (id) ->
				runningApps[id] ?= apps[id]()
				foregroundApp = runningApps[id]
			draw: (screen, size) ->
				return if blanked
				taskBar.draw screen,
					width: size.width,
					height: taskBarHeight
				screen.pushMatrix()
				screen.translate 0, taskBarHeight
				foregroundApp.draw? screen,
					width: size.width
					height: size.height - taskBarHeight
				screen.popMatrix()
			key: (key) ->
				foregroundApp.key? key
			longKey: (key) ->
				if key is "a"
					return blanked = !blanked
				if key is "b"
					return foregroundApp = mainMenu
				foregroundApp.longKey? key

		# Our entry point, root app
		$scope.mainApp = $scope.app()
				
]
