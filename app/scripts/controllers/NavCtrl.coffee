"use strict"

angular.module("app.controllers.NavCtrl", []).controller "NavCtrl", [
	"$scope"
	"$location"

	($scope, $location) ->
		$scope.isActiveNav = (id) ->
			$location.path() is id
]
