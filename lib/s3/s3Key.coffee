module.exports = class
	constructor: (@id) ->
		@prefix = "artifacts/"

	get: () ->
		"artifacts/#{@id}"