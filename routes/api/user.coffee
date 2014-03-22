User = exports.User = require('../../models/user')

ApiHelper = require('./api-helper')

exports.detail = (req, res) ->
  ApiHelper.setJson(res)
  ApiHelper.handleFindById(User, req.params.id, res, (user) ->
    res.json({
      username: user.username,
      email: user.email,
      twitterHandle: user.twitterHandle
    })
  )

exports.validate = (req, res) ->
  ApiHelper.setJson(res)
  if not req.params.key?
    res.json({isValid: false, message: 'No key set'})

  key = req.params.key

  validationResult = ApiHelper.validateKey(key)
  if validationResult.success
    res.json({isValid: true})
  else
    res.json({isValid: false, message: validationResult.message})
