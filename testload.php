<!DOCTYPE HTML>
<html lang="en-US">
<head>
  <meta charset="UTF-8">
  <title></title>
  <script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>
  <!-- <script src="/sarissa-full-0.9.9.6/gr/abiss/js/sarissa/sarissa.js"></script> -->
  <script src="/ckeditor-dev/ckeditor.js"></script>
  <script src="vendor/require.js"></script>
</head>
<body>
  <form id="mainform" action="post_test.php" method="post">
    <p>
      <textarea id='editor1' name='editor1'>
        <?php
        #echo(htmlspecialchars(file_get_contents('../schematron-play/good-kipling-cke.xml')));
        ?>
      </textarea>
    </p>
    <p>
      <!-- <input type="submit" value="Submit" /> -->
    </p>
  </form>
  Data file: <input type="text" id="datafile" name="datafile" value="/textorum/test/xml/good-kipling.xml"/> <input type="button" name="loaddata" id="loaddata" value="load"/>
  <br/>
  <input type="button" name="savedata" id="savedata" value="save"/>
  <script>
  require.config({
    baseUrl: "lib",
		// urlArgs: "bust=" + "18", 
		urlArgs: (new Date()).getTime(),
     shim: {
      'ckeditor': {
        exports: 'CKEDITOR'
      }
     },
     paths: { ckeditor: '/ckeditor-dev/dev/builder/release/ckeditor/ckeditor' }
   });
  require( ["textorum/ckeditor/plugin", "textorum/ckeditor/testload"], function() {
    CKEDITOR.replace('editor1', 
    { 
     extraPlugins: 'textorum,showblocks,fakeobjects,devtools'
    }); 
  });
  </script>
</body>
</html>
