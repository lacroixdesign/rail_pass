$(document).on 'click', '[data-behavior="close:outdatedBrowser"]', (event)->
  event.preventDefault()
  $('#outdated-browser').fadeOut(200)
  $.cookie('outdated_browser', 'dismissed', { expires: 1, path: '/' })


jQuery ->
  if $.cookie('outdated_browser')
    $('#outdated-browser').hide()
