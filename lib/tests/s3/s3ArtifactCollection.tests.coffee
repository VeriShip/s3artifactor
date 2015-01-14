Q = require 'q'
_ = require 'lodash'
path = require 'path'
s3ArtifactCollection = require path.join( __dirname, "../../s3/s3ArtifactCollection.js")

aws = region = bucket = id = null

getTarget = () ->
	new s3ArtifactCollection aws, region, bucket, id

describe 's3ArtifactCollection', ->

	this.timeout 100

	beforeEachFunction = () ->
		aws = 
			S3: class
		region = 'Some Region'
		bucket = 'Some Bucket'
		id = 'Some Id'
	
	beforeEach beforeEachFunction

	describe '#constructor', ->
		it 'should contain a key with id appended to it.', ->

			target = getTarget()

			target.key.get().should.equal "#{target.key.prefix}#{target.id}"

		it 'should raise an exception if aws is null.', ->

			aws = null
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if aws is undefined.', ->

			aws = undefined 
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if region is null.', ->

			region = null
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if region is undefined.', ->

			region = undefined 
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if bucket is null.', ->

			bucket = null
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if bucket is undefined.', ->

			bucket = undefined 
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if id is null.', ->

			id = null
			(() -> getTarget())
			.should.throw()

		it 'should raise an exception if id is undefined.', ->

			id = undefined 
			(() -> getTarget())
			.should.throw()

	describe '#gatherS3Versions(collection, deferred, prevCall)', ->

		it 'should pass correct parameters to listObjectVersions.', (done) ->

			actualOptions = null
			
			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						actualOptions = options
						callback null, [ ]

			bucket = 'Some Bucket I Can Test With'
			id = 'Some id I can Test With'

			target = getTarget()

			target.gatherS3Versions()
				.finally (fin) ->
					actualOptions.Bucket.should.equal bucket
					actualOptions.Prefix.should.equal target.key.get()
					done()

		it 'should pass correct parameters to listObjectVersions when the previous call is passed.', (done) ->

			actualOptions = null
			
			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						actualOptions = options
						callback null, [ ]

			prevCall = 
				NextKeyMarker: "Some Next Key Marker"
				NextVersionIdMarker: "Some Next Version Key Marker"

			target = getTarget()

			target.gatherS3Versions null, null, prevCall
				.finally (fin) ->
					actualOptions.KeyMarker.should.equal prevCall.NextKeyMarker
					actualOptions.VersionIdMarker.should.equal prevCall.NextVersionIdMarker
					done()

		it 'should append to the passed collection.', (done) ->

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, 
							Versions: [
								{ Property: 1 }
							],
							IsTruncated: false

			target = getTarget()

			collection = [ { Property: 0 } ]

			target.gatherS3Versions collection
				.finally (fin) ->
					collection.length.should.equal 2
					collection[1].Property.should.equal 1
					done()

		it 'should use the passed deferred.', (done) ->

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, 
							Versions: [ ],
							IsTruncated: false

			target = getTarget()

			deferred = Q.defer()

			target.gatherS3Versions null, deferred, null

			deferred.promise.finally () ->
				done()

		it 'should recurse if IsTruncated is true.', (done) ->

			responses = [
				{
					Versions: [
						{ Property: 1 }
					]
					IsTruncated: false
				},
				{
					Versions: [
						{ Property: 0 }
					]
					IsTruncated: true
				}
			]

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, responses.pop()

			target = getTarget()

			target.gatherS3Versions()
				.done (data) ->
					data.length.should.equal 2
					data[0].Property.should.equal 0
					data[1].Property.should.equal 1
					done()

		it 'should return ar error if one arrises.', (done) ->

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback "Some Error", null

			target = getTarget()

			target.gatherS3Versions()
				.catch (err) ->
					done()

	describe '#gatherS3Metadata(bucket, key, versionId)', ->

		it 'should raise an exception if bucket is null.', (done) ->

			getTarget().gatherS3Metadata null, "someKey", "someVersionId"
				.catch () ->
					done()

		it 'should raise an exception if bucket is undefined.', (done) ->

			getTarget().gatherS3Metadata undefined, "someKey", "someVersionId"
				.catch () ->
					done()

		it 'should raise an exception if key is null.', (done) ->

			getTarget().gatherS3Metadata "someBucket", null, "someVersionId"
				.catch () ->
					done()

		it 'should raise an exception if key is undefined.', (done) ->

			getTarget().gatherS3Metadata "someBucket", undefined, "someVersionId"
				.catch () ->
					done()

		it 'should raise an exception if versionId is null.', (done) ->

			getTarget().gatherS3Metadata "someBucket", "someKey", null
				.catch () ->
					done()

		it 'should raise an exception if versionId is undefined.', (done) ->

			getTarget().gatherS3Metadata "someBucket", "someKey", undefined
				.catch () ->
					done()

		it 'should have passed the correct parameters to the call.', (done) ->
			
			actualOptions = null

			aws = 
				S3: class
					headObject: (options, callback) ->
						actualOptions = options
						callback null, ""

			getTarget().gatherS3Metadata "bucket", "key", "version"
				.finally (fin) ->
					actualOptions.Bucket.should.equal "bucket"
					actualOptions.Key.should.equal "key"
					actualOptions.VersionId.should.equal "version"
					done()

		it 'should pass the data back correctly.', (done) ->

			actualData = { }

			aws = 
				S3: class
					headObject: (options, callback) ->
						callback null, actualData

			getTarget().gatherS3Metadata "a", "b", "c"
				.done (data) ->
					data.should.equal actualData
					done()

		it 'should pass the error back correctly.', (done) ->

			actualError = { }

			aws = 
				S3: class
					headObject: (options, callback) ->
						callback actualError, null

			getTarget().gatherS3Metadata "a", "b", "c"
				.catch (error) ->
					error.should.equal actualError
					done()

	describe '#get(version)', ->

		beforeEachFunction()

		versionData = [
			{
				IsTruncated: false
				Versions: [
					{
						IsLatest: false
						VersionId: "3"
					}
					{
						IsLatest: true
						VersionId: "4"
					}
				]
			}
			{
				IsTruncated: true
				Versions: [
					{
						IsLatest: false
						VersionId: "1"
					}
					{
						IsLatest: false
						VersionId: "2"
					}
				]
			}
		]

		metadataData = [
			{
				DeleteMarker: false
				VersionId: "4"
				Metadata:
					version: "0.0.4"
			}
			{
				DeleteMarker: true
				VersionId: "3"
				Metadata:
					version: "0.0.3"
			}
			{
				DeleteMarker: false
				VersionId: "2"
				Metadata:
					version: "0.0.2"
			}
			{
				DeleteMarker: false
				VersionId: "1"
				Metadata:
					version: "0.0.1"
			}
		]

		expectedData = [
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

		it 'should return the correct collection of artifacts.', (done) ->

			internalVersionData = _.cloneDeep versionData
			internalMetadataData = _.cloneDeep metadataData

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, internalVersionData.pop()
					headObject: (options, callback) ->
						callback null, internalMetadataData.pop()

			getTarget().get().done (data) ->
				data.should.eql expectedData
				done()

		it 'should raise an exception if listObjectVersions does.', (done) ->

			internalMetadataData = _.cloneDeep metadataData
			
			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback "Some Exception", null
					headObject: (options, callback) ->
						callback null, internalMetadataData.pop()

			getTarget().get().catch (err) ->
				done()

		it 'should raise an exception if listObjectVersions does.', (done) ->

			internalVersionData = _.cloneDeep versionData

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, internalVersionData.pop()
					headObject: (options, callback) ->
						callback "Some Exception", null

			getTarget().get().catch (err) ->
				done()

		it 'should return a single item matching the given version.', (done) ->

			internalVersionData = _.cloneDeep versionData
			internalMetadataData = _.cloneDeep metadataData

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, internalVersionData.pop()
					headObject: (options, callback) ->
						callback null, internalMetadataData.pop()

			getTarget().get('0.0.2').done (data) ->
				data.should.eql expectedData[1]
				done()

		it 'should return undefined if the version is not found.', (done) ->

			internalVersionData = _.cloneDeep versionData
			internalMetadataData = _.cloneDeep metadataData

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, internalVersionData.pop()
					headObject: (options, callback) ->
						callback null, internalMetadataData.pop()

			getTarget().get('0.0.a').done (data) ->
				(data is undefined).should.be.true
				done()

	describe '#getLatest()', ->
		
		beforeEachFunction()

		versionData = [
			{
				IsTruncated: false
				Versions: [
					{
						IsLatest: false
						VersionId: "3"
					}
					{
						IsLatest: true
						VersionId: "4"
					}
				]
			}
			{
				IsTruncated: true
				Versions: [
					{
						IsLatest: false
						VersionId: "1"
					}
					{
						IsLatest: false
						VersionId: "2"
					}
				]
			}
		]

		metadataData = [
			{
				DeleteMarker: false
				VersionId: "4"
				Metadata:
					version: "0.0.4"
			}
			{
				DeleteMarker: true
				VersionId: "3"
				Metadata:
					version: "0.0.3"
			}
			{
				DeleteMarker: false
				VersionId: "2"
				Metadata:
					version: "0.0.2"
			}
			{
				DeleteMarker: false
				VersionId: "1"
				Metadata:
					version: "0.0.1"
			}
		]

		expectedData = [
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

		it 'should return the latest item.', (done) ->

			internalVersionData = _.cloneDeep versionData
			internalMetadataData = _.cloneDeep metadataData

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, internalVersionData.pop()
					headObject: (options, callback) ->
						callback null, internalMetadataData.pop()

			getTarget().getLatest().done (data) ->
				data.should.eql expectedData[3]
				done()

		it 'should return undefined if the latest is not found.', (done) ->

			internalVersionData = _.cloneDeep versionData
			internalVersionData[0].Versions[1].IsLatest = false

			internalMetadataData = _.cloneDeep metadataData

			aws = 
				S3: class
					listObjectVersions: (options, callback) ->
						callback null, internalVersionData.pop()
					headObject: (options, callback) ->
						callback null, internalMetadataData.pop()

			getTarget().getLatest().done (data) ->
				(data is undefined).should.be.true
				done()
