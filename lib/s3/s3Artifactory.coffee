Q = require 'q'
fs = require 'fs'
path = require 'path'
S = require 'string'
s3Key = require path.join(__dirname, 's3Key.js')

module.exports = class
	constructor: (@artifactCollection, @aws, @fs, @region, @bucket, @id) ->

		if !@artifactCollection?
			throw 'Must supply an artifactCollection.'
		if !@aws?
			throw 'Must supply an aws.'
		if !@fs?
			throw 'Must supply an fs.'
		if !@region?
			throw 'Must supply a region.'
		if !@bucket?
			throw 'Must supply a bucket.'
		if !@id?
			throw 'Must supply an id.'

		@key = new s3Key @id

	getArtifacts: () ->
		@artifactCollection.get()

	pushArtifact: (sourcePath, version, isPublic, isEncrypted, overwrite) ->

		if !sourcePath?
			Q.reject 'You must supply a source path.'	

		if !version?
			Q.reject 'You must supply a version.'

		promise = Q()

		#	We allow the user to overwrite the latest version.  If they have not supplied the 
		#	latest version then we raise an exception.
		if(overwrite ? false)
			promise = promise.then =>
				@artifactCollection.getLatest()
					.then (data) =>
						if data.Version == version
							return @deleteArtifact version
						else
							return Q.reject("The version (#{version}) supplied was not the latest.  Only the latest can be overwritten.")

		promise.then =>
			@artifactCollection.get(version)
				.then (existingVersion) =>
					deferred = Q.defer()
					if existingVersion?
						deferred.reject "That version of #{@id}, version #{version} already exists."
					else
						file = @fs.createReadStream sourcePath
						options = 
							params:
								Bucket: @bucket
								Key: @key.get()
								Body: file
								ACL: 'private'
								Metadata:
									version: version

						if isPublic
							options.params.ACL = 'public-read'

						if isEncrypted
							options.params.ServerSideEncryption = 'AES256'

						managedUpload = new @aws.S3.ManagedUpload options

						managedUpload.on 'httpUploadProgress', deferred.notify

						managedUpload.send (err, data) ->
							if err?
								deferred.reject err
							else
								deferred.resolve data

					deferred.promise
		
	getArtifact: (destPath, version) ->

		if !destPath?
			Q.reject 'You must supply a dest path.'	

		promise = null
		version = if S((version ? "").toLowerCase()).trim().s == 'latest' then null else version
		if version?
			promise = @artifactCollection.get(version)
		else
			promise = @artifactCollection.getLatest()

		promise.then (existingVersion) =>
				deferred = Q.defer()
				if not existingVersion?
					deferred.reject "That version of #{@id}, version #{version ? 'latest'}, does not exist."

				else
					options = 
						Bucket: @bucket
						Key: @key.get()
						VersionId: existingVersion.VersionId	

					s3 = new @aws.S3 { region: @region }

					file = @fs.createWriteStream(destPath)
					s3.getObject options
						.on 'httpData', (chunk) =>
							file.write chunk
						.on 'httpDone', () =>
							file.end()
						.on 'success', deferred.resolve
						.on 'error', deferred.reject 
						.on 'httpDownloadProgress', deferred.notify
						.send()

				deferred.promise

	deleteArtifact: (version) ->

		if !version?
			Q.reject 'You must supply a version.'	

		@artifactCollection.get(version)
			.then (existingVersion) =>
				deferred = Q.defer()
				if !existingVersion?
					deferred.reject "That version of #{@id}, version #{version} does not exists."

				else
					options = 
						Bucket: @bucket
						Key: @key.get()
						VersionId: existingVersion.VersionId

					s3 = new @aws.S3 { region: @region }
					s3.deleteObject options, (err, data) ->
						if err?
							deferred.reject err

						else
							deferred.resolve data

				deferred.promise