jQuery ($) ->
  if !Modernizr.svg
    $('img[src$=".svg"]').each ->
      customFallback = $(@).data("svg-fallback")
      autoFallback   = $(@).attr('src').replace('.svg', '.png')
      src = if customFallback? then customFallback else autoFallback
      $(@).attr('src', src)
