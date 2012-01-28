crypto = require('crypto')
conf = require('../conf')

# base64 stuff from https://gist.github.com/661597

base64_to_string = (str) -> new Buffer(str).toString('ascii')

base64_url_to_base64 = (str) ->
  padding_needed = (4 - (str.length % 4))
  [0...padding_needed].map (i) ->
    str += '='
  return str.replace(/\-/g, '+').replace(/_/g, '/')

base64_url_to_string = (str) -> base64_to_string(base64_url_to_base64(str))

require_auth = (req, res, next) ->
  parts = req.body.signed_request.split('.')
  sig = base64_url_to_base64(parts[0])
  data = JSON.parse(base64_url_to_string(parts[1]))

  if data.user_id?
    if data.algorithm.toUpperCase() != 'HMAC-SHA256'
      return res.send('Unexpected algorithm, not HMAC-SHA256')
    hmac = crypto.createHmac('sha256', conf.secret)
    hmac.update(parts[1])
    if sig != hmac.digest('base64')
      return res.send('Could not verify account')

    req.fb_data = data
    return next();
  else
    return res.render('login')

home_page = (req, res, next) ->
  res.send "Woohoo! Hello #{req.fb_data.user_id}"

exports.registerOn = (app) ->
  app.post '/', require_auth, home_page