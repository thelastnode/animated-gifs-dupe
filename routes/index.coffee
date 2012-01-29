crypto = require('crypto')
Shred = require('shred')
shred = new Shred()

conf = require('../conf')
models = require '../lib/models'

# Facebook stuff
FacebookClient = require('facebook-client').FacebookClient
fb = new FacebookClient(conf.app_id, conf.secret)

graph_call = (req, path, cb) ->
  fb.getSessionByAccessToken(req.fb_data.oauth_token)( (session) ->
    session.graphCall(path, {})(cb)
  )

# base64 stuff from https://gist.github.com/661597

base64_to_string = (str) -> new Buffer(str, 'base64').toString('ascii')

base64_url_to_base64 = (str) ->
  padding_needed = (4 - (str.length % 4))
  [0...padding_needed].map (i) ->
    str += '='
  return str.replace(/\-/g, '+').replace(/_/g, '/')

base64_url_to_string = (str) -> base64_to_string(base64_url_to_base64(str))

require_auth = (req, res, next) ->
  parts = req.body.signed_request?.split('.') || req.query.si
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
    return next()
  else
    return res.render('login')

accept_auth = (req, res, next) ->
  return next(req.query.error_description) if req.query.error == 'access_denied'

  res.render('success')

home_page = (req, res, next) ->
  res.render 'home_page'

check = (req, res, next) ->
  next('Need data') if req.params?.url?.length == 0

  shred.get(
    url: req.params.url
    on:
      200: (response) ->
        h = crypto.createHash('sha1')
        h.update(response.content.data)
        hash = h.digest('hex')
        res.send(JSON.stringify(
          exists: false
          urls: [hash]
        ))
  )

exports.registerOn = (app) ->
  app.post '/', require_auth, home_page
  app.get '/', accept_auth
  app.get '/check', check