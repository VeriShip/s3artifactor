path = require 'path'

should = require 'should'
aws = require 'aws-sdk'
Q = require 'q'
_ = require 'lodash'
sinon = require 'sinon'
events = require 'events'

s3Key = require path.join( __dirname, "../../s3/s3Key.js")
s3artifactory = require path.join( __dirname, "../../s3/s3Artifactory.js")

collection = aws = fs = region = bucket = id = null

describe 's3Artifactory', ->

	stockArtifacts = [
		{
			Region: region
			Bucket: bucket
			Id: id
			IsLatest: false
			VersionId: "1"
			Version: "0.0.1"
		}
		{
			Region: region
			Bucket: bucket
			Id: id
			IsLatest: false
			VersionId: "2"
			Version: "0.0.2"
		}
		{
			Region: region
			Bucket: bucket
			Id: id
			IsLatest: false
			VersionId: "3"
			Version: "3"
		}
		{
			Region: region
			Bucket: bucket
			Id: id
			IsLatest: true
			VersionId: "4"
			Version: "0.0.4"
		}
	]

	sourceArtifacts = null

	beforeEachFunction = () ->
		sourceArtifacts = JSON.parse(JSON.stringify(stockArtifacts))
		collection = 
			get: (version) ->
				if version?
					Q.resolve(_.find sourceArtifacts, { Version: version })
				else
					Q.resolve sourceArtifacts
			getLatest: () ->
				Q.resolve(_.find sourceArtifacts, { IsLatest: true })
		aws = { }
		fs = { } 
		region = "Some Region"
		bucket = "Some Bucket"
		id = "Some Id"

	getTarget = (innerCollection) ->
		if innerCollection?
			collection.get = () ->
				Q.resolve innerCollection
		new s3artifactory(collection, aws, fs, region, bucket, id)

	beforeEach beforeEachFunction

	describe '#constructor', ->

		it 'should raise an error if collection is null.', ->

			collection = null
			(() -> getTarget()).should.throw()

		it 'should raise an error if collection is  undefined.', ->

			collection = undefined 
			(() -> getTarget()).should.throw()

		it 'should raise an error if aws is null.', ->

			aws = null
			(() -> getTarget()).should.throw()

		it 'should raise an error if aws is  undefined.', ->

			aws = undefined 
			(() -> getTarget()).should.throw()

		it 'should raise an error if fs is null.', ->

			fs = null
			(() -> getTarget()).should.throw()

		it 'should raise an error if fs is  undefined.', ->

			fs = undefined 
			(() -> getTarget()).should.throw()

		it 'should raise an error if region is null.', ->

			region = null
			(() -> getTarget()).should.throw()

		it 'should raise an error if region is  undefined.', ->

			region = undefined 
			(() -> getTarget()).should.throw()

		it 'should raise an error if bucket is null.', ->

			bucket = null
			(() -> getTarget()).should.throw()

		it 'should raise an error if bucket is  undefined.', ->

			bucket = undefined 
			(() -> getTarget()).should.throw()

		it 'should raise an error if id is null.', ->

			id = null
			(() -> getTarget()).should.throw()

		it 'should raise an error if id is  undefined.', ->

			id = undefined 
			(() -> getTarget()).should.throw()

		it 'key should be set.', ->

			id = "Some Id"
			key = new s3Key id

			getTarget().key.should.eql key

	describe '#pushArtifact(sourcePath, version, isPublic, isEncrypted, overwrite)', ->

		it 'should raise an error if sourcePath is null.', (done) ->
			getTarget().pushArtifact null, '0.0.5'
				.catch (err) ->
					done()

		it 'should raise an error if sourcePath is undefined.', (done) ->
			getTarget().pushArtifact undefined, '0.0.5'
				.catch (err) ->
					done()

		it 'should raise an error if version is null.', (done) ->
			getTarget().pushArtifact 'path', null
				.catch (err) ->
					done()

		it 'should raise an error if version is undefined.', (done) ->
			getTarget().pushArtifact 'path', undefined 
				.catch (err) ->
					done()

		it 'should raise an error if the version already exists.', (done) ->
			getTarget().pushArtifact 'path', '0.0.4'
				.catch (err) ->
					done()

		it 'should open the correct file.', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3:
					ManagedUpload: class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, { }
						on: () ->

			getTarget().pushArtifact "some Path", "0.0.5"
				.done (data) ->
					fs.createReadStream.calledOnce.should.be.true
					fs.createReadStream.alwaysCalledWithExactly("some Path").should.be.true
					done()

		it 'should send the correct options to managed upload.', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3:
					ManagedUpload: class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, { }
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.6'
				.done (data) ->
					actualManagedUploadOptions.should.eql
						params:
							Bucket: bucket
							Key: key.get()
							Body: readStream
							ACL: 'private'
							Metadata:
								version: '0.0.6'
					done()

		it 'should delete the latest if overwrite is true', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			deleteOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3: class
					deleteObject: (options, callback) =>
						deleteOptions = options
						sourceArtifacts = _.filter sourceArtifacts, (item) ->
							item.VersionId != options.VersionId	
						callback null, { }
			aws.S3.ManagedUpload = class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, { }
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.4', false, false, true
				.done (data) ->
					actualManagedUploadOptions.should.eql
						params:
							Bucket: bucket
							Key: key.get()
							Body: readStream
							ACL: 'private'
							Metadata:
								version: '0.0.4'
					deleteOptions.should.eql
						Bucket: bucket
						Key: key.get()
						VersionId: "4"
					done()

		it 'should raise an exception if overwrite is true and the version is not the latest version', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			deleteOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3: class
					deleteObject: (options, callback) =>
						deleteOptions = options
						sourceArtifacts = _.filter sourceArtifacts, (item) ->
							item.VersionId != options.VersionId	
						callback null, { }
			aws.S3.ManagedUpload = class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, { }
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.2', false, false, true
				.catch (err) ->
					done()

		it 'should set the correct ACL when isPublic is set to true.', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3:
					ManagedUpload: class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, { }
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.6', true
				.done (data) ->
					actualManagedUploadOptions.should.eql
						params:
							Bucket: bucket
							Key: key.get()
							Body: readStream
							ACL: 'public-read'
							Metadata:
								version: '0.0.6'
					done()

		it 'should set the correct SSE when isEncrypted is set to true.', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3:
					ManagedUpload: class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, { }
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.6', false, true 
				.done (data) ->
					actualManagedUploadOptions.should.eql
						params:
							Bucket: bucket
							Key: key.get()
							Body: readStream
							ACL: 'private'
							Metadata:
								version: '0.0.6'
							ServerSideEncryption: 'AES256'
					done()

		it 'should raise an error if managedUpload.send does so.', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3:
					ManagedUpload: class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback "someError", null
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.6'
				.catch (error) ->
					done()

		it 'should data returned from managedUpload.send.', (done) ->

			readStream = { }
			actualManagedUploadOptions = null
			createReadStreamStub = sinon.stub()
			createReadStreamStub.returns readStream
			key = new s3Key id
			returnResult = { }

			fs = 
				createReadStream: createReadStreamStub
			aws = 
				S3:
					ManagedUpload: class
						constructor: (options) ->
							actualManagedUploadOptions = options
						send: (callback) ->
							callback null, returnResult
						on: () ->

			getTarget().pushArtifact 'some Path', '0.0.6'
				.done (data) ->
					data.should.equal returnResult
					done()

	describe '#getArtifact(destPath, version)', ->

		it 'should raise an error if destPath is null.', (done) ->
			getTarget().getArtifact null, '0.0.4'
				.catch (err) ->
					done()

		it 'should raise an error if destPath is undefined.', (done) ->
			getTarget().getArtifact undefined, '0.0.4'
				.catch (err) ->
					done()

		it 'should raise an error if the version does not exists.', (done) ->
			getTarget().getArtifact 'path', '0.0.5'
				.catch (err) ->
					done()

		it 'should open the correct file.', (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						actualManagedUploadOptions = options
						request

			promise = getTarget().getArtifact "some Path", "0.0.4"

			promise.done (data) ->
					createWriteStreamStub.alwaysCalledWithExactly("some Path").should.be.true
					done()

		it 'should pass the correct options.', (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub
			key = new s3Key id

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						actualManagedUploadOptions = options
						request

			promise = getTarget().getArtifact "some Path", "0.0.2"

			promise.done (data) ->
					actualManagedUploadOptions.should.eql
						Bucket: bucket
						Key: key.get()
						VersionId: "2"	
					done()

		it "'httpData' should have been registered.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.listeners('httpData').length.should.equal 1
					done()

		it "'httpDone' should have been registered.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.listeners('httpDone').length.should.equal 1
					done()

		it "'success' should have been registered.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.listeners('success').length.should.equal 1
					done()

		it "'error' should have been registered.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.listeners('error').length.should.equal 1
					done()

		it "'httpDownloadProgress' should have been registered.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.listeners('httpDownloadProgress').length.should.equal 1
					done()

		it "'httpData' should write to the file.", (done) ->

			chunk = { }
			actualManagedUploadOptions = null
			writeStreamStub = 
				write: sinon.stub()
				end: sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.emit('httpData', chunk)
					writeStreamStub.write.alwaysCalledWithExactly(chunk).should.be.true
					done()

		it "'httpDone' should end the file.", (done) ->

			writeStreamStub = 
				write: sinon.stub()
				end: sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						request

			getTarget().getArtifact "some Path", "0.0.4"
				.done (data) ->
					request.emit('httpDone')
					writeStreamStub.end.calledOnce.should.be.true
					done()

		it "should get the latest version if 'Latest' is passed in for version id.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub
			key = new s3Key id

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						actualManagedUploadOptions = options
						request

			promise = getTarget().getArtifact "some Path", "Latest"

			promise.done (data) ->
					actualManagedUploadOptions.should.eql
						Bucket: bucket
						Key: key.get()
						VersionId: "4"	
					done()

		it "should get the latest if version id is undefined.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub
			key = new s3Key id

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						actualManagedUploadOptions = options
						request

			promise = getTarget().getArtifact "some Path", undefined

			promise.done (data) ->
					actualManagedUploadOptions.should.eql
						Bucket: bucket
						Key: key.get()
						VersionId: "4"	
					done()

		it "should get the latest if version id is null.", (done) ->

			actualManagedUploadOptions = null
			writeStreamStub = sinon.stub()
			createWriteStreamStub = sinon.stub()
			createWriteStreamStub.returns writeStreamStub
			key = new s3Key id

			requestDef = class extends events.EventEmitter
				send: () ->
					@emit 'success'

			request = new requestDef
			fs = 
				createWriteStream: createWriteStreamStub
			aws = 
				S3: class
					getObject: (options) ->
						actualManagedUploadOptions = options
						request

			promise = getTarget().getArtifact "some Path", null

			promise.done (data) ->
					actualManagedUploadOptions.should.eql
						Bucket: bucket
						Key: key.get()
						VersionId: "4"	
					done()


	describe '#deleteArtifact(version)', ->

		it 'should raise an error if version is null.', (done) ->
			getTarget().deleteArtifact null
				.catch (err) ->
					done()

		it 'should raise an error if version is undefined.', (done) ->
			getTarget().deleteArtifact undefined
				.catch (err) ->
					done()

		it 'should raise an error if the version does not exists.', (done) ->
			getTarget().deleteArtifact '0.0.5'
				.catch (err) ->
					done()

		it 'should pass the correct options.', (done) ->

			actualOptions = null
			key = new s3Key id
			aws = 
				S3: class
					deleteObject: (options, callback) ->
						actualOptions = options
						callback null, { }

			getTarget().deleteArtifact "0.0.4"
				.done (data) ->
					actualOptions.should.eql
						Bucket: bucket
						Key: key.get()
						VersionId: "4"	
					done()

		it 'should raise an error if one happens.', (done) ->
			aws = 
				S3: class
					deleteObject: (options, callback) ->
						callback "Some Error", null

			getTarget().deleteArtifact "0.0.4"
				.catch (error) ->
					done()

		it 'should return success if everything is ok.', (done) ->
			aws = 
				S3: class
					deleteObject: (options, callback) ->
						callback null, "Some Data"

			getTarget().deleteArtifact "0.0.4"
				.done (data) ->
					done()