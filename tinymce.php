<!DOCTYPE HTML>
<html lang="en-US">
<head>
  <meta charset="UTF-8">
  <title></title>
  <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
  <script src="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.0/jquery-ui.min.js"></script>
  <script src="/jstree/jquery.jstree.js"></script>
  <!-- <script src="/sarissa-full-0.9.9.6/gr/abiss/js/sarissa/sarissa.js"></script> -->
  <script src="/tinymce/jscripts/tiny_mce/tiny_mce.js"></script>
  <script src="vendor/require.js"></script>
  <link rel="stylesheet" type="text/css" href="//ajax.googleapis.com/ajax/libs/jqueryui/1.10.0/themes/base/jquery-ui.css"/>
</head>
<body>
  <form id="mainform" action="post_test.php" method="post">
    <div style="width: 100%;">
      <div style="float: left; border: 1px solid red; max-height: 400px; overflow: auto; width: 29%;" id="editortree">
        &nbsp;
      </div>
      <div style="float: right; width: 69%; border: 1px solid blue;">
        <textarea style="width: 100%;" id='editor1' name='editor1'></textarea>
      </div>
      <div style="clear: both;"></div>
    </div>
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
  Data file: <input type="text" id="datafile" name="datafile" value="<?php if (isset($_GET['s'])) { echo $_GET['s']; } ?>"/> <input type="button" name="loaddata" id="loaddata" value="load"/>
  <br/>
  <input type="button" name="savedata" id="savedata" value="save"/>
  <script>
  require.config({
    baseUrl: "lib",
		// urlArgs: "bust=" + "18",
		// urlArgs: (new Date()).getTime(),
		paths: {
			"text": "../vendor/text",
      "jqueryui-popups": "../vendor/tinymce.jqueryui.popups"
		}
   });
  require( ["textorum/tinymce/plugin", "jqueryui-popups"], function() {
    tinymce.init({
      mode: 'exact',
      theme: 'advanced',
      elements: 'editor1',
      plugins: '-textorum,-jqueryinlinepopups',
      entity_encoding: 'raw',
      content_css: 'lib/textorum/tinymce/plugin.css',
    theme_advanced_buttons1 : "save,fullscreen,undo,redo,help,code,visualaid,visualchars,visualblocks",
    theme_advanced_buttons2 : "", //cut,copy,paste,pastetext,pasteword,|,search,replace,|,bullist,numlist,|,outdent,indent,blockquote,|,undo,redo,|,link,unlink,anchor,image,cleanup,help,code,|,insertdate,inserttime,preview,|,forecolor,backcolor",
    theme_advanced_buttons3 : "", //tablecontrols,|,hr,removeformat,visualaid,|,sub,sup,|,charmap,emotions,iespell,media,advhr,|,print,|,ltr,rtl,|,fullscreen",
    theme_advanced_buttons4 : "", //insertlayer,moveforward,movebackward,absolute,|,styleprops,|,cite,abbr,acronym,del,ins,attribs,|,visualchars,nonbreaking,template,pagebreak,restoredraft,visualblocks",
      keep_styles: false,
      theme_advanced_resizing: true,
      theme_advanced_resize_horizontal: false,
      preformatted: true,
      whitespace_elements: 'pre script noscript style textarea div span code',
      apply_source_formatting: false,
      valid_elements: "*[*]",
      setup: function(ed) {
        ed.onInit.add(function(ed) {
          if ($('#datafile').val()) {
            $('#loaddata').click();
          }
        });
      }
    });

  });
  </script>
</body>
</html>