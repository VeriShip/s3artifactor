Q = require 'q'
fs = require 'fs'
path = require 'path'
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

	pushArtifact: (sourcePath, version, isPublic, isEncrypted) ->

		if !sourcePath?
			Q.reject 'You must supply a source path.'	

		if !version?
			Q.reject 'You must supply a version.'

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

		if !version?
			Q.reject 'You must supply a version.'

		@artifactCollection.get(version)
			.then (existingVersion) =>
				deferred = Q.defer()
				if not existingVersion?
					deferred.reject "That version of #{@id}, version #{version} exist already."

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