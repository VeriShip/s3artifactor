Q = require 'q'
_ = require 'lodash'
path = require 'path'
s3Key = require path.join(__dirname, 's3Key.js')

module.exports = class
	constructor: (@aws, @region, @bucket, @id) ->
		if !aws?
			throw 'You must define aws.'
		if !region?
			throw 'You must define region.'
		if !bucket?
			throw 'You must define bucket.'
		if !id?
			throw 'You must define id.'

		@key = new s3Key @id

	get: (versionNumber) ->

		latestVersionId = null

		promise = @gatherS3Versions()
			.then (data) =>
				Q.all _.map data, (item) =>
					if item.IsLatest
						latestVersionId = item.VersionId
					@gatherS3Metadata @bucket, @key.get(), item.VersionId
			.then (data) =>
				_.map data, (item) =>
					result = 
						Region: @region,
						Bucket: @bucket,
						Id: @id,
						IsLatest: item.VersionId == latestVersionId
						VersionId: item.VersionId
					if item.DeleteMarker
						result.Version = item.VersionId
					else
						result.Version = item.Metadata.version

					result

		if versionNumber?
			promise = promise.then (data) =>
				result = _.find data, { Version: versionNumber }
				console.logresult 
				result	

		promise

	getLatest: () ->
		@get().then (data) ->
			_.find data, (item) ->
				item.IsLatest

	gatherS3Versions: (collection, deferred, prevCall) ->

		if !collection?
			collection = [ ]

		if !deferred?
			deferred = Q.defer()

		s3 = new @aws.S3 { region: @region }

		listObjectVersionsOptions = 
			Bucket: @bucket
			Prefix: @key.get()

		if prevCall?
			listObjectVersionsOptions.KeyMarker = prevCall.NextKeyMarker
			listObjectVersionsOptions.VersionIdMarker = prevCall.NextVersionIdMarker

		s3.listObjectVersions listObjectVersionsOptions, (err, data) =>
			if err?
				deferred.reject err

			else
				_.forEach data.Versions, (version) ->
					collection.push version

				if data.IsTruncated
					deferred.notify "Total Items Retreived: #{collection.length}"
					@gatherS3Versions collection, deferred, data
				else
					deferred.resolve collection

		deferred.promise

	gatherS3Metadata: (bucket, key, versionId) ->

		if !bucket?
			return Q.reject 'You must supply a bucket name'

		if !key?
			return Q.reject 'You must supply a key.'

		if !versionId?
			return Q.reject 'you must supply a version id.'

		s3 = new @aws.S3 { region: @region }
		Q.nbind(s3.headObject, s3)(
			Bucket: bucket,
			Key: key,
			VersionId: versionId)