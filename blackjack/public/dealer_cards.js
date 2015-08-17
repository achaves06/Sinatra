$(document).ready(function() {
  $('#dealer .card').each(function() {
    var divID = '#' + this.id;
    var time = (this.id -1) * 750;
    setTimeout(function () {
      $(divID).css("opacity",1);
    }, time);
  });


});
