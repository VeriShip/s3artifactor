path = require 'path'
fsArtifactCollection = require path.join( __dirname, "../../fileSystem/fsArtifactCollection.js")

jsonFilePath = fs = null

beforeEachFunction = () ->
	jsonFilePath = "Some Path"
	fs = 
		existsSync: (path) ->
			true
		readFileSync: (file, encoding) ->
			{ }

getTarget = () ->
	new fsArtifactCollection jsonFilePath, fs

describe 'fsArtifactCollection', ->

	beforeEach beforeEachFunction

	json = [
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

	jsonString = JSON.stringify json

	describe '#constructor(jsonFilePath)', ->

		it 'should raise an exception if jsonFilePath is null.', ->
			jsonFilePath = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if jsonFilePath is undefined.', ->
			jsonFilePath = undefined
			(() -> getTarget()).should.throw()

		it 'should raise an exception if fs is null.', ->
			fs = null
			(() -> getTarget()).should.throw()

		it 'should raise an exception if fs is undefined.', ->
			fs = undefined
			(() -> getTarget()).should.throw()

		it 'should raise an exception if the jsonFilePath does not exist.', ->
			fs.existsSync = (path) ->
					false

			(() -> getTarget()).should.throw()

	describe '#get(versionNumber)', (done) ->

		it 'should return the expected json object', (done) ->

			fs.readFileSync = (file, encoding) ->
				jsonString

			getTarget().get()
				.done (data) ->
					data.should.eql json
					done()

		it 'should return the expected json object if versions is supplied. (0.0.1)', (done) ->

			fs.readFileSync = (file, encoding) ->
				jsonString

			getTarget().get("0.0.1")
				.done (data) ->
					data.should.eql json[0]
					done()

		it 'should return the expected json object if versions is supplied. (0.0.2)', (done) ->

			fs.readFileSync = (file, encoding) ->
				jsonString

			getTarget().get("0.0.2")
				.done (data) ->
					data.should.eql json[1]
					done()

		it 'should raise an exception if there is an error in the file reading operation.', (done) ->
			
			fs.readFileSync = (file, encoding) ->
				throw 'exception'

			getTarget().get()
				.catch (err) ->
					done()

		it 'should return undefined if the version is not found.', (done) ->

			fs.readFileSync = (file, encoding) ->
				jsonString

			getTarget().get("0.0.3")
				.done (data) ->
					(data is undefined).should.be.true
					done()

	describe '#getLatest()', ->

		it 'should return the latest item.', (done) ->

			fs.readFileSync = (file, encoding) ->
				jsonString

			getTarget().getLatest()
				.done (data) ->
					data.should.eql json[1]
					done()

		it 'should return undefined if the latest is not found.', (done) ->
			
			json = [
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
					IsLatest: false 
				}
			]

			jsonString = JSON.stringify json
			fs.readFileSync = (file, encoding) ->
				jsonString

			getTarget().getLatest()
				.done (data) ->
					(data is undefined).should.be.true
					done()
