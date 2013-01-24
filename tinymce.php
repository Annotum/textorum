<!DOCTYPE HTML>
<html lang="en-US">
<head>
  <meta charset="UTF-8">
  <title></title>
  <script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
  <!-- <script src="/sarissa-full-0.9.9.6/gr/abiss/js/sarissa/sarissa.js"></script> -->
  <script src="/tinymce/jscripts/tiny_mce/tiny_mce.js"></script>
  <script src="vendor/require.js"></script>
</head>
<body>
  <form id="mainform" action="post_test.php" method="post">
    <p>
      <textarea id='editor1' name='editor1'></textarea>
    </p>
    <p>
      <!-- <input type="submit" value="Submit" /> -->
    </p>
  </form>
  <ul class="filenames">
    <li>/ncbi-updates/from-client/PMC2780816kipling.xml</li>
    <li>/ncbi-updates/from-client/PMC3153123kipling.xml</li>
    <li>/ncbi-updates/from-client/PMC3256938kipling.xml</li>
    <li>test/xml/short-kipling.xml</li>
  </ul>
  Data file: <input type="text" id="datafile" name="datafile" value="<?php if (isset($_GET['s'])) { echo $_GET['s']; } else { echo '/ncbi-updates/from-client/PMC3153123kipling.xml'; } ?>"/> <input type="button" name="loaddata" id="loaddata" value="load"/>
  <br/>
  <input type="button" name="savedata" id="savedata" value="save"/>
  <script>
  require.config({
    baseUrl: "lib",
		// urlArgs: "bust=" + "18",
		// urlArgs: (new Date()).getTime(),
		shim: {
			'tinymce': {
				exports: 'tinymce'
			}
		},
		paths: {
			"text": "../vendor/text",
			tinymce: '/tinymce/jscripts/tiny_mce/tiny_mce'
		}
   });
  require( ["textorum/tinymce/plugin"], function() {
    tinymce.init({
      mode: 'exact',
      elements: 'editor1',
      plugins: '-textorum.loader,inlinepopups',
      entity_encoding: 'raw',
      content_css: 'lib/textorum/tinymce/plugin.css',
      width: '100%',
      height: '100%',
      keep_styles: false,
      theme_advanced_resizing: true,
      theme_advanced_resize_horizontal: false
    });
  });
  </script>
</body>
</html>
