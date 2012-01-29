$(function() {
  $('#submit').click(function(event) {
    var url = $('#url').val();
    var results = $('#results');
    var links = $('#links');
    results.text('Checking...');
    links.text('');

    $.getJSON('/check', {
      url: url,
      user_id: window.user_id,
      oauth_token: window.oauth_token
    }, function(data) {
      results.text('');
      if (data.error) {
        results.text(data.error_description);
        return;
      }
      if (!data.exists) {
        results.text('Looks unique!');
      } else {
        results.text('Dupe!');
        for (var i = 0; i < data.urls.length; i++) {
          var x = data.urls[i];
          links.append($('<li>').append($('<a>').attr('href', x)));
        }
      }
    });
  });
});
