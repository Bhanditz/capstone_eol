$(function() {

  $("#tasks li").unbind('click');
  $('#worklist #tasks li').click(function() {
    if($('#worklist #tasks li.active span.indicator').html() != '') {
      $('#worklist #tasks li.active span.indicator').removeClass('invisible');
    }

    $(this).closest('ul').find("li").removeClass("active");
    $(this).find('span.indicator').addClass('invisible');
    $(this).addClass("active");
    var $update = $(this).closest('#worklist').find('#task');
    EOL.ajax_get($(this).find("a"), {update: $update, type: 'GET'});
    return(false);
  });

  $('#worklist .filters form input[type=submit]').unbind('click');
  $('#worklist .filters form input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $('<input>').attr({
        type: 'hidden',
        name: 'ajax',
        value: 1
    }).appendTo($f);
    EOL.ajax_submit($f, {update: $(this).closest('#worklist'), type: 'GET'});
    return(false);
  });

  $('#worklist #tasks p.more a').unbind('click');
  $('#worklist #tasks p.more a').click(function() {
    var $update = $(this).closest('#worklist');
    var current_link = $(this).attr('href');
    $(this).attr('href', current_link + (current_link.indexOf('?') != -1 ? "&ajax=1" : "?ajax=1"));
    EOL.ajax_get($(this), {update: $update, type: 'GET'});
    return(false);
  });

  // Wouldn't it be nice if ratings were Ajaxified?
  $('#worklist #task .ratings .rating a').unbind('click');
  $('#worklist #task .ratings .rating a').click(function() {
    var $update = $(this).closest('div.ratings');
    EOL.ajax_submit($(this), {url: $(this).attr('href'), update: $update, type: 'GET'});
    return(false);
  });

  $('#worklist #task form.comment input[type=submit]').unbind('click');
  $('#worklist #task form.comment input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: update_active_indicator('Commented')});
    return(false);
  });

  $('#worklist #task form.review_status input[type=submit]').unbind('click');
  $('#worklist #task form.review_status input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: update_active_indicator('Saved')});
    return(false);
  });

  $('#worklist #task form.ignore_data_object input[type=submit]').unbind('click');
  $('#worklist #task form.ignore_data_object input[type=submit]').click(function() {
    var $f = $(this).closest('form');
    $f.find("#return_to").val($f.find("#worklist_return_to").val());
    EOL.ajax_submit($(this).closest('form'), {update: $(this).closest('#task'), complete: update_active_indicator('Ignored')});
    return(false);
  });

  $('#worklist #task').ajaxSuccess(function() {
    resize_task_panel();
  });
});

$(window).load(function() {
  resize_task_panel();
});

function resize_task_panel() {
  $('#task').css('min-height', $('#tasks ul').css('height'));
}
function update_active_indicator(message) {
  if(message == 'Saved') {
    $('#worklist #tasks li.active').removeClass('ignored');
    $('#worklist #tasks li.active').addClass('saved');
    $('#worklist #tasks li.active span.indicator').html(message);
  }else if(message == 'Ignored') {
    $('#worklist #tasks li.active').removeClass('saved');
    if($('#worklist #tasks li.active').hasClass('ignored')) {
      $('#worklist #tasks li.active').removeClass('ignored');
      $('#worklist #tasks li.active span.indicator').html('');
    }else
    {
      $('#worklist #tasks li.active').addClass('ignored');
      $('#worklist #tasks li.active span.indicator').html(message);
    }
  }else
  {
    $('#worklist #tasks li.active span.indicator').html(message);
  }
}

