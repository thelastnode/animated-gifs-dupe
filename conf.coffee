module.exports =
  port: process.env.PORT || 3000
  app_id: process.env.APP_ID
  canvas_page: 'https://animated-gifs-dupes.herokuapp.com/'
  secret: process.env.SECRET

module.exports.auth_url = "https://www.facebook.com/dialog/oauth?
  client_id=#{module.exports.app_id}
  &redirect_uri=#{encodeURI(module.exports.canvas_page)}
  &scope=user_groups"