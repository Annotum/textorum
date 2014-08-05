<!doctype html>
<html>
<head>
	<title>Posted data test</title>
	<meta charset="utf-8" />
	<style>
		body {
			padding:10px 30px;
			color: #333333;
			font-family: Arial, Helvetica, sans-serif;
			font-size: 75%;
		}

		table {
			width: 100%;
			table-layout: fixed;
			border-collapse: collapse;
		}
		th {
			vertical-align: top;
			padding: 5px;
		}
		th, td {
			border: 1px solid black;

		}
		pre {
			font-family: monospace,monospace;
			font-size: 1em;
			margin: 5px;
			background-color: #f7f7f7;
			border: 1px solid #d7d7d7;
			overflow: auto;
			padding: .25em .25em 1em .25em;
		}

		.prewrap {
			white-space: pre-wrap;
		}

	</style>
	<title>Sample &mdash; TinyMCE Output</title>
	<meta http-equiv="content-type" content="text/html; charset=utf-8" />
	<link type="text/css" rel="stylesheet" href="sample.css" />
</head>
<body>
	<table>
		<colgroup><col width="120" /></colgroup>
		<thead>
			<tr>
				<th>Field Name</th>
				<th>Value</th>
			</tr>
		</thead>
<?php
foreach ( $_POST as $field => $value ) {
?>
		<tr>
			<th><?php echo htmlspecialchars($field); ?></th>
			<td><pre><?php echo htmlspecialchars($value)?></pre></td>
		</tr>
<?php
}
?>
	</table>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
	<script>
		jQuery(function($) {
			$('pre').on('click', function() {
				$(this).toggleClass('prewrap');
			});
		});
	</script>
</body>
</html>
