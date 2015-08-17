$(document).ready(function() {
//show Dealer total
  setTimeout(function () {
    $('#result_message').fadeIn();
  }, 2000);

  $(document).on(function() {
    $('#hit').click(function() {
      $.ajax({
        type: 'GET',
        url: '/hit',
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });

    $('#stay').click(function() {
      $.ajax({
        type: 'GET',
        url: '/stay',
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });

    $('#bet').click(function() {
      $.ajax({
        type: 'GET',
        url: '/bet',
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });

  });

});
