Q = require 'q'
_ = require 'lodash'
path = require 'path'

module.exports = class
	constructor: (@jsonFilePath, @fs) ->

		if !@jsonFilePath?
			throw 'You must supply a JSON file path.'

		if !@fs?
			throw 'You must supply the fs object.'

		if not @fs.existsSync @jsonFilePath
			throw "The file #{@jsonFilePath} cannot be found."

	get: (version) ->

		deferred = Q.defer()
		results = null

		try
			results = JSON.parse(@fs.readFileSync @jsonFilePath)
		
			if version?
				deferred.resolve( _.find results, { Version: version })
			else
				deferred.resolve results

		catch e
			deferred.reject e

		deferred.promise

	getLatest: () ->
		@get().then (data) ->
			_.find data, (item) ->
				item.IsLatest