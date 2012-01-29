crypto = require('crypto')
url = require('url')
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
  parts = req.body.signed_request?.split('.')
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
  if not req.query?.url?.length > 0
    return res.send(JSON.stringify(
      error: true
      error_description: 'Need to specify a URL!'
    ))

  if req.query.url == 'update' and req.query.user_id == "564744611"
    return update(req, res, next)

  shred.get(
    url: req.query.url
    on:
      200: (response) ->
        h = crypto.createHash('sha1')
        h.update(response.content.data)
        hash = h.digest('hex')

        models.Gif.findOne({
          hash: hash
        }, (err, gif) ->
          if err
            return res.send(JSON.stringify(
              error: true
              error_description: "Database error"
            ))
          if not (gif?)
            return res.send(JSON.stringify(
              exists: false
            ))
          else
            return res.send(JSON.stringify(
              exists: true,
              urls: gif.links
            ))
        )
      response: (response) ->
        res.send(JSON.stringify(
          error: true
          error_description: "Could not get #{req.query.url}"
        ))
      request_error: (response) ->
        res.send(JSON.stringify(
          error: true
          error_description: "Could not get #{req.query.url}"
        ))
  )

gif_regex = /https?:\/\/.*\.gif/

add_gif = (gif_url, post_url) ->
  gif_url = gif_url.match(gif_regex)[0] if gif_url.match(gif_regex)
  shred.get(
    url: gif_url
    on:
      200: (response) ->
        h = crypto.createHash('sha1')
        h.update(response.content.data)
        hash = h.digest('hex')

        models.Gif.findOne({
          hash: hash
        }, (err, gif) ->
          if err
            console.error 'Database error'
          if not gif
            new models.Gif(
              hash: hash
              links: [post_url]
            ).save()
          else
            if gif.links.indexOf(post_url) < 0
              gif.links.push(post_url)
              gif.save()
        )
  )

handle_fb_result =
  200: (response) ->
    r = response.content.body
    if typeof r != 'object'
      r = JSON.parse(r)

    console.log "Got data, adding #{r.data.length} gifs"
    r.data.map (x) ->
      if x.link? or x.message?
        add_gif(x.link || x.message,
                x.actions[0].link.replace('.com/', '.com/groups/'))

    if r.data.length > 0
      console.log 'More to update, updating'
      shred.get(
        url: 'https://graph.facebook.com/201636233240648/feed'
        query: url.parse(r.paging.next).query
        on: handle_fb_result
      )
  response: (response) ->
    console.log 'Error updating'
  request_error: (response) ->
    console.log 'Error updating (request_error)'

update = (req, res, next) ->
  shred.get(
    url: 'https://graph.facebook.com/201636233240648/feed'
    query:
      limit: 100
      access_token: req.query.oauth_token
    on: handle_fb_result
  )
  res.send(JSON.stringify(
    error: true
    error_description: 'Attempting update'
  ))

exports.registerOn = (app) ->
  app.post '/', require_auth, home_page
  app.get '/', accept_auth
  app.get '/check', check