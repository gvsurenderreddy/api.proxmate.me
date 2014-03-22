packageApi = require '../../../routes/api/package'
request = require 'request'
sinon = require 'sinon'

{app} = require '../../../app.coffee'
{server} = require '../../../app.coffee'
{assert} = require 'chai'

ApiHelper = require('../../../routes/api/api-helper')

describe 'Api Helper', ->

  before (done) ->
    server.listen 3000
    done()

  after (done) ->
    server.close()
    done()

  # Generate stubs for mongoose functions
  beforeEach ->
    this.sandbox = sinon.sandbox.create()

  # Restore original functions
  afterEach ->
    this.sandbox.restore()

  describe 'api database handling', ->
    it 'should return 404 on wrong objectid', ->
      modelStub =
        findById: ->

      findByIdStub = this.sandbox.stub(modelStub, 'findById', (id, callback) ->
        callback({
          message: 'Cast to ObjectId failed for value "asdfa345345sdfakosdfjasdf" at path "_id"',
          name: 'CastError',
          type: 'ObjectId',
          value: 'asdfa345345sdfakosdfjasdf',
          path: '_id'
        }, null)
      )

      resStub =
        send: this.sandbox.spy()
      callback = this.sandbox.spy()

      ApiHelper.handle(modelStub, 'findById', {}, resStub, callback)
      assert.isTrue(findByIdStub.calledOnce)
      assert.isTrue(findByIdStub.calledWith({}))

      assert.isTrue(resStub.send.calledOnce)
      assert.isTrue(resStub.send.calledWith(404, '[]'))

      assert.isFalse(callback.calledOnce)

    it 'should return 500 on database error', ->
      modelStub =
        findById: ->

      findByIdStub = this.sandbox.stub(modelStub, 'findById', (id, callback) ->
        callback({
          name: 'Foo'
        }, null)
      )

      resStub =
        send: this.sandbox.spy()
      callback = this.sandbox.spy()

      ApiHelper.handle(modelStub, 'findById', {}, resStub, callback)
      assert.isTrue(findByIdStub.calledOnce)
      assert.isTrue(findByIdStub.calledWith({}))

      assert.isTrue(resStub.send.calledOnce)
      assert.isTrue(resStub.send.calledWith(500, '[]'))

      assert.isFalse(callback.calledOnce)

    it 'should return 404 if the database response is empty', ->
      modelStub =
        findById: ->

      findByIdStub = this.sandbox.stub(modelStub, 'findById', (id, callback) ->
        callback(null, null)
      )

      resStub =
        send: this.sandbox.spy()
      callback = this.sandbox.spy()

      ApiHelper.handle(modelStub, 'findById', {}, resStub, callback)
      assert.isTrue(findByIdStub.calledOnce)
      assert.isTrue(findByIdStub.calledWith({}))

      assert.isTrue(resStub.send.calledOnce)
      assert.isTrue(resStub.send.calledWith(404, '[]'))

      assert.isFalse(callback.calledOnce)

    it 'should execute callback if no errors were thrown', ->
      modelStub =
        findById: ->

      findByIdStub = this.sandbox.stub(modelStub, 'findById', (id, callback) ->
        callback(null, {foo:'bar'})
      )

      resStub =
        send: this.sandbox.spy()
      callback = this.sandbox.spy()

      ApiHelper.handle(modelStub, 'findById', {}, resStub, callback)
      assert.isTrue(findByIdStub.calledOnce)
      assert.isTrue(findByIdStub.calledWith({}))

      assert.isFalse(resStub.send.calledOnce)

      assert.isTrue(callback.calledOnce)
      assert.isTrue(callback.calledWith({foo:'bar'}))

    it 'should execute handle on shortcut methods', ->
      handleStub = this.sandbox.stub(ApiHelper, 'handle', ->
        return 'foo'
      )
      callback = this.sandbox.spy()

      ApiHelper.handleFindById('model', {}, {}, callback)
      assert.isTrue(handleStub.calledOnce)
      assert.isTrue(handleStub.calledWith('model', 'findById', {}, {}, callback))

      ApiHelper.handleFind('model', {}, {}, callback)
      assert.isTrue(handleStub.calledTwice)
      assert.isTrue(handleStub.calledWith('model', 'findById', {}, {}, callback))

  describe 'header setting', ->
    it 'should set header to json on json()', ->
      resStub =
        set: this.sandbox.spy()

      ApiHelper.setJson(resStub)
      assert.isTrue(resStub.set.calledOnce)
      assert.isTrue(resStub.set.calledWith('Content-Type', 'application/json'))

  describe 'requireKey validation', ->
    it 'should return 401 on no key', ->
      resMock =
        json: this.sandbox.spy()

      reqMock =
        query: {}

      ApiHelper.requireKey(reqMock, resMock)
      assert.isTrue(resMock.json.calledOnce)
      assert.isTrue(resMock.json.calledWith({message: 'This ressource requires a valid key. Do you have one?'}, 401))

    it 'should return 401 and message on key error', ->
      validationStub = this.sandbox.stub(ApiHelper, 'validateKey', ->
        return {success: false, message: 'foobar'}
      )

      resMock =
        json: this.sandbox.spy()

      reqMock =
        query:
          key: 'foo'

      ApiHelper.requireKey(reqMock, resMock)
      assert.isTrue(resMock.json.calledOnce)
      assert.isTrue(resMock.json.calledWith({message: 'foobar'}, 401))

    it 'should return true on valid key', ->
      validationStub = this.sandbox.stub(ApiHelper, 'validateKey', ->
        return {success: true}
      )

      resMock =
        json: this.sandbox.spy()

      reqMock =
        query:
          key: 'foo'

      res = ApiHelper.requireKey(reqMock, resMock)
      assert.isTrue(res)