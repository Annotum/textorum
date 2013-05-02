do ->
  require.config
    baseUrl: "lib"

    # urlArgs: "bust=" + "18",
    # urlArgs: (new Date()).getTime(),
    paths:
      text: "../vendor/text"
      sax: "../vendor/sax"
      "jqueryui-popups": "../vendor/tinymce.jqueryui.popups"
      "tinymce-jquery": "../vendor/tinymce_jquery/jquery.tinymce"
      "tinymce-jquery-adapter": "../vendor/tinymce_jquery/adapter"

  unless require.defined("stream")
    define "stream", ->
      func = ->

      Stream: func
