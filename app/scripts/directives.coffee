"use strict"

angular.module( "app.directives", [ "app.services" ])
	.directive("appVersion", [
		"version"

		(version) ->
			(scope, elem, attrs) ->
				elem.text version
	])

	.directive("processingCanvas", ->
		(scope, elem, attrs) ->
			scope.$processing = new Processing elem[0], scope[attrs.processingCanvas]
			PFont.preloading.add "pixelmix.ttf"
			elem[0].getContext("2d").imageSmoothingEnabled = false;
	)
