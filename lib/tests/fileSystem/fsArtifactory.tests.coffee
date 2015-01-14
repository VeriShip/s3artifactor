path = require 'path'
Q = require 'q'
_ = require 'lodash'
sinon = require 'sinon'
events = require 'events'
fsArtifactory = require path.join( __dirname, "../../fileSystem/fsArtifactory.js")

collection = fs = region = bucket = id = null

artifacts = [
	{
		Region: "Some Region"
		Bucket: "Some Bucket"
		Id: "Some Id"
		Version: "0.0.1"
		Path: "Some Path"
		IsLatest: false
	}
	{
		Region: "Some Region 1"
		Bucket: "Some Bucket 1"
		Id: "Some Id 1"
		Version: "0.0.2"
		Path: "Some Path 2"
		IsLatest: true 
	}
]

beforeEachFunction = () ->
	collection = 
		get: (version) ->
			if version?
				Q(_.find artifacts, {Version: version })
			else
				Q(artifacts)
	fs = 
		createReadStream: () ->
		createWriteStream: () ->
	region = "Some Region"
	bucket = "Some Bucket"
	id = "Some Id"

getTarget = () ->
	new fsArtifactory collection, fs, region, bucket, id

describe 'fsArtifactory', ->
	beforeEach beforeEachFunction

	describe '#constructor(@collection, @region, @bucket, @id)', ->

		it 'should raise an exception if collection is null.', ->
			collection = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if collection is undefined.', ->
			collection = undefined
			(() -> getTarget()).should.throw()

		it 'should raise an exception if fs is null.', ->
			fs = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if fs is undefined.', ->
			fs = undefined
			(() -> getTarget()).should.throw()

		it 'should raise an exception if region is null.', ->
			region = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if region is undefined.', ->
			region = undefined
			(() -> getTarget()).should.throw()

		it 'should raise an exception if bucket is null.', ->
			bucket = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if bucket is undefined.', ->
			bucket = undefined
			(() -> getTarget()).should.throw()

		it 'should raise an exception if id is null.', ->
			id = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if id is undefined.', ->
			id = undefined
			(() -> getTarget()).should.throw()

	describe '#getArtifacts()', ->

		it 'should return expected artifacts.', (done) ->

			getTarget().getArtifacts()
				.done (data) ->
					data.should.eql artifacts
					done()

	describe '#getArtifact(destPath, version)', ->

		it 'should raise an exception if destPath is null.', (done) ->

			getTarget().getArtifact(null, "")
				.catch (err) ->
					done()

		it 'should raise an exception if destPath is undefined.', (done) ->

			getTarget().getArtifact(undefined, "")
				.catch (err) ->
					done()

		it 'should raise an exception if version is null.', (done) ->

			getTarget().getArtifact("", null)
				.catch (err) ->
					done()

		it 'should raise an exception if version is undefined.', (done) ->

			getTarget().getArtifact("", undefined)
				.catch (err) ->
					done()

		it 'should raise an exception if the version is undefined.', (done) ->

			getTarget().getArtifact("Some Dest Path", "0.0.10")
				.catch (err) ->
					done()

		it 'should copy the file from path to destPath.', (done) ->

			readStream =
				pipe: (writable) ->
					writable
			writeStream = 
				on: (e, func) ->
					if e == 'finish'
						func()

			fs = 
				createReadStream: sinon.stub().returns readStream 
				createWriteStream: sinon.stub().returns writeStream

			getTarget().getArtifact("Some Dest Path", "0.0.1")
				.done (data) ->

						#	All of these assertions are needed to guarantee that
						#	we copy the file correctly.
						fs.createReadStream.calledOnce.should.be.true
						fs.createReadStream.calledWithExactly artifacts[0].Path
						fs.createWriteStream.calledOnce.should.be.true
						fs.createWriteStream.calledWithExactly "Some Dest Path"
						done()

		it 'should raise an exception if the file copy fails.', (done) ->

			readStream =
				pipe: sinon.spy()
			writeStream = { }

			fs = 
				createReadStream: sinon.stub().throws()
				createWriteStream: sinon.stub().returns writeStream

			getTarget().getArtifact("Some Dest Path", "0.0.1")
				.catch (err) ->
					done()
