Q = require 'q'

module.exports = class
	constructor: (@artifactCollection, @fs, @region, @bucket, @id) ->

		if not @artifactCollection?
			throw 'You must supply a artifactCollection.'

		if not @fs?
			throw 'You must supply an fs.'

		if not @region?
			throw 'You must supply a region.'

		if not @bucket?
			throw 'You must supply a bucket.'

		if not @id?
			throw 'You must supply an id.'

	getArtifacts: () ->
		@artifactCollection.get()

	getArtifact: (destPath, version) ->

		if !destPath?
			return Q.reject 'You must supply a destPath.'

		if !version?
			return Q.reject 'You must supply a version.'

		@artifactCollection.get(version).then (data) =>

			deferred = Q.defer()

			if !data?
				deferred.reject "The artifact with version #{version} was not found."

			try
				readStream = @fs.createReadStream data.Path
				writeStream = @fs.createWriteStream destPath

				readStream.pipe(writeStream).on 'finish', () ->
					deferred.resolve "Finished laying pipe."
			catch e
				deferred.reject e

			deferred.promise