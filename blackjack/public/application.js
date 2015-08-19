$(document).ready(function() {
//show Dealer total


  $(document).on(function() {
    $('#hit').click(function() {
      $.ajax({
        type: 'POST',
        url: '/hit',
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });



    $('#bet').click(function() {
      $.ajax({
        type: 'POST',
        url: '/bet',
      }).done(function(msg) {
        $('#game').replaceWith(msg);
      });
      return false;
    });

  });

  $('#stay').click(function() {
    $.ajax({
      type: 'POST',
      url: '/stay',
    }).done(function(msg) {
      $('#dealer_cards').html(msg);
      var bet = document.getElementById('in_play').textContent;
      var balance = document.getElementById('balance').textContent;
      bet = bet.split('$')[1];
      balance = balance.split('$')[1];
      var button_html = '<form class = "form-inline" action = "/bet" method = "post"><div class="form-group"><label for="player_name">$</label><input type="number" class="form-control span1 input-large" name = "bet" id="bet" step = "any" required min = "0.5" max = "'+ balance + '" value ="' + bet + '"/><button type="submit" class="btn btn-primary btn-large">Bet</button></div></form>';
      $('#actions').html(button_html);

      });
      return false;
  });



});
