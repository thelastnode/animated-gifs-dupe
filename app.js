var coffee = require('coffee-script');

var express = require('express');
var routes = require('./routes');

var conf = require('./conf');

var app = module.exports = express.createServer();

require('mongoose').connect(conf.mongo_uri);

// Configuration

app.configure(function() {
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.cookieParser());
  app.use(express.session({
    secret: conf.session_secret,
  }))
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function() {
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function() {
  app.use(express.errorHandler({dumpExceptions: true}));
});

app.dynamicHelpers({
  req: function(req, res) {
    return req;
  },
  conf: function(req, res) {
    return conf
  },
});

// Routes
routes.registerOn(app);

app.listen(conf.port);
console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
