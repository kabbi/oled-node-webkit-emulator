"use strict"

App = angular.module "app", [
	"ngAnimate"
	"ngCookies"
	"ngResource"
	"ngRoute"
	"ui.bootstrap"
	"app.controllers"
	"app.directives"
	"app.filters"
	"app.services"
	"partials"
]

App.config [
	"$routeProvider"
	"$locationProvider"

	($routeProvider, $locationProvider, config) ->

		$routeProvider
			.when("/canvas", templateUrl: "/partials/canvas.html")
			.otherwise(redirectTo: "/canvas")

		# Without server side support html5 must be disabled.
		$locationProvider.html5Mode off
]
