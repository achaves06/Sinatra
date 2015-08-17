$(document).ready(function() {
  $('#dealer .card').each(function() {
    var divID = '#' + this.id;
    var time = (this.id -1) * 750;
    setTimeout(function() {
      $(divID).css("opacity",1);
    }, time);
  });

  $.ajax({
    type: 'GET',
    url: '/stats',
  }).done(function(msg) {
    var vars = msg.split(",");
    var total = vars[0];
    var length = Number(vars[1]);
    var balance = Number(vars[2]);
    var result = vars[3];
    var delay = (length -1 )* 750 + 500;
    setTimeout(function() {
      $('#dealer_total').html(total);
    }, delay);
    setTimeout(function () {
      $('#result_message').html(result);
    }, delay);
    setTimeout(function () {
      $('#result_message').fadeIn();
    }, delay);
    setTimeout(function () {
      $('#balance').html("$"+balance);
    }, delay+ 500);
    setTimeout(function () {
      $('#in_play').html("$0");
    }, delay+ 500);
  });

});
