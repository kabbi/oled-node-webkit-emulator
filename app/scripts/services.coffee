"use strict"

angular.module( "app.services", [])
	.factory "version", ->
		fs = require "fs"

		raw = fs.readFileSync "package.json", encoding: "utf8"
		appPackage = JSON.parse raw

		appPackage.version