should = require 'should'
path = require 'path'
s3Key = require path.join( __dirname, "../../s3/s3Key.js")

describe 's3Key', ->
	describe '#get()', ->
		it 'should return key with correct id appended too it.', ->

			key = new s3Key 'SomeId'
			key.get().should.equal "#{key.prefix}SomeId"

		it 'should return key with correct id appended too it again.', ->

			key = new s3Key 'SomeId Again'
			key.get().should.equal "#{key.prefix}SomeId Again"
