$(function() {
  $('#submit').click(function(event) {
    var url = $('#url').val();
    var results = $('#results');
    results.text('Checking...');
    $.getJSON('/check', {url: url, user_id: window.user_id}, function(data) {
      results.text('');
      if (data.error) {
        results.text(data.error_description);
        return;
      }
      if (!data.exists) {
        results.text('Looks unique!');
      } else {
        for (var i = 0; i < data.urls.length; i++) {
          var x = data.urls[i];
          results.text(results.text() + '\n' + x);
        }
      }
    });
  });
});
