<?
	$raw = @file_get_contents("map.txt");

	# defaults
	$currentScreen = 0;

	$screens = array();
	if (file_exists("screens.s"))
	{
		# read maps.s
		$raw = file("screens.s");
		$readingScreen = -1;
		foreach($raw as $line)
		{
			$line = trim($line);
			$args = explode(" ", $line);
			if (preg_match("/^SCREEN(\d+)/", $args[0], $matches))
			{
				$readingScreen = $matches[1];
				$screens[$readingScreen] = array();
				array_shift($args);
			}

			$hex = array_shift($args);
			if ($hex == "hex")
			{
				for ($i=0; $i<count($args); $i++)
				{
					$tile = hexdec($args[$i]);
					$screens[$readingScreen][] = $tile;
				}
			}
		}
	}

	if ($_SERVER['REQUEST_METHOD'] == "POST")
	{
		# save
		foreach ($_POST as $key=>$value)
		{
			if (preg_match("/^screen(\d+)/i", $key, $matches))
			{
				$index = $matches[1];
				$screens[$index] = explode(" ", $value);
			}
		}

		@unlink("screens.s.old");
		@rename("screens.s", "screens.s.old");

		//print "<pre>"; print_r($screens);exit;

		$fp = fopen("screens.s", "wt");
		foreach ($screens as $id=>$value)
		{
			fprintf($fp, "SCREEN%d", $id);

			for ($y=0; $y<12; $y++)
			{
				$elem = array();
				for ($x=0; $x<20; $x++)
				{
					$elem[] = sprintf("%02x", $screens[$id][$y*20 + $x]);
				}

				$elem = implode(" ", $elem);
				fprintf($fp, "\thex %s\n", $elem);
			}

			fprintf($fp, "\n");
		}

		fclose($fp);

		$currentScreen = $_POST['currentScreen'];
	}
?>

<!doctype html>
<html>
<head>
	<script type="text/javascript" src="jquery.min.js"></script>
</head>
<body style="background: #aaa; width: 100%;">
	<h1>
		Spacesuit Simon Map Editor
	</h1>
	<p>
		<div style="float: left;">
			<form method="get" action="/" id="load-form">
				<input type="submit" value="Revert" id="load-button" />
			</form>
		</div>
		
		<div style="float: left;">
			<form method="post" action="" id="save-form">
				<input type="hidden" name="currentScreen" value="0" />
				<input type="button" value="Save Map" id="save-button" />
			</form>
		</div>

		<br style="clear: both;" />
	</p>

	<img src="tilemap.png" id="tilemap" style="display: none;" />
	<div style="float: left;">
		<canvas id="canvas" width="645" height="560" style="border: 1px solid black;"></canvas>
	</div>

	<div id="screenList" style="float: left; padding-left: 10px; width: 600px;">
	</div>
	
	<br style="clear: both;" />

	<script type="text/javascript">
		var canvas = document.getElementById("canvas");
		var ctx = canvas.getContext("2d");
		ctx.imageSmoothingEnabled  = false;
		var tilemap = document.getElementById("tilemap");

		var currentScreen = <?= $currentScreen ?>;

		var TileMapEditor =
		{
			_mouseDown: false,
			_selectedTileX: -1,
			_selectedTileY: -1,
			_tiles: null,

			loadFromString: function(str) {
				var items = str.split(/\s+/);
				
				var mapName = items[0];
				var tileIndex = 0;

				var id = /^screen(\d+)/.exec(mapName);
				console.dir(id);

				for (var i=1; i<items.length; i++) {
					if (items[i] == "hex") {
						// ignore
						continue;
					}

					var ty = Math.floor(items[i]/3);
					var tx = items[i] % 3;
					this._tiles[currentScreen][tileIndex++] = tx + (ty*3);
				}

				this.paint();
				//console.dir(rows);
			},

			onClick: function(e) {
				var x = Math.floor(e.offsetX);
				var y = Math.floor(e.offsetY);

				if (x >= 561) {
					// click on tile map
					this._selectedTileX = Math.floor((x-561)/28);
					this._selectedTileY = Math.floor(y/32);
				} else if (x < 560) {
					// click on map
					x = Math.floor(x/28);
					y = Math.floor(y/32);
					if (x >= 0 && x < (560/28) && y >= 0 && y < (384/32)) {
						this._tiles[currentScreen][y*Math.floor(560/28)+x] = this._selectedTileX + (this._selectedTileY * 3);
					}

					this.paint();
				}
			},

			drawTileAt: function(tx, ty, x, y) {
				ctx.drawImage(tilemap, tx*28, ty*32, 28, 32, x, y, 28, 32);
			},

			onMouseDown: function(e) {
				var x = Math.floor(e.offsetX);
				var y = Math.floor(e.offsetY);

				if (x < 560) {
					this._mouseDown = true;
					this.onClick(e);
				}
			},

			onMouseMove: function(e) {
				var x = Math.floor(e.offsetX);
				var y = Math.floor(e.offsetY);

				if (this._mouseDown) {
					this.onClick(e);
				} else {
					this.paint();
				}
	
				if (x < 560) {
					x = Math.floor(x/28);
					y = Math.floor(y/32);

					ctx.strokeStyle = "#fff";
					ctx.strokeRect(x*28, y*32, 28, 32);
				}

				/*
				if (this._mouseDown) {
					
					if (x < 560) {
						// fixme (this)
						x = Math.floor(x/28)*28;
						y = Math.floor(y/32)*32;
						TileMapEditor.paint();
						TileMapEditor.drawTileAt(this._selectedTileX, this._selectedTileY, x, y);
					}
				}		
				*/
			},

			onMouseUp: function(e) {
				this._mouseDown = false;
			},

			initialize: function() {
				var tw = Math.floor(560/28);
				var th = Math.floor(384/32);

				this._tiles = new Array(256);
				for (var j=0; j<256; j++) {
					this._tiles[j] = new Array(th*tw);
					for (var i=0; i<this._tiles.length; i++) {
						this._tiles[j][i] = 0;
					}
				}

				var self = this;
				$(canvas).click(function(e) { self.onClick(e) });
				$(canvas).mousedown(function(e) { self.onMouseDown(e); });
				$(canvas).mousemove(function(e) { self.onMouseMove(e); });
				$(canvas).mouseup(function(e) { self.onMouseUp(e); });
			},

			paint: function() {
				ctx.fillStyle = "#fff";
				ctx.fillRect(0, 0, canvas.width, canvas.height);

				ctx.strokeStyle = "#f0f";
				ctx.beginPath();
				ctx.moveTo(560, 0);
				ctx.lineTo(560, 560);
				ctx.stroke();

				// draw the tilemap
				for (var y=0; y<tilemap.height/32; y++) {
					for (x=0; x<tilemap.width/28; x++) {
						//ctx.drawImage(tilemap, 561, 0, 84, 560);
						this.drawTileAt(x, y, 561+x*28, y*32);
					}
				}

				if (this._selectedTileX >= 0) {
					ctx.strokeStyle = "#fff";
					ctx.strokeRect(561 + this._selectedTileX*28, this._selectedTileY*32, 28, 32);
				}

				var tw = Math.floor(560/28);
				var th = Math.floor(280/16);
				for (var y=0; y<th; y++) {
					for (var x=0; x<tw; x++) {
						var t = this._tiles[currentScreen][y*tw + x];

						this.drawTileAt(t%3, Math.floor(t/3), x*28, y*32);
					}
				}
			}
		};

		function setActiveScreen(indx) {
			if (currentScreen != -1) {
				$("#screen" + currentScreen).css('border', '1px solid black');
			}

			currentScreen = indx;
			$("#screen" + currentScreen).css('border', '1px solid red');

			// force repaint
			TileMapEditor.paint();
		}

		function onScreenButtonClick() {
			var res = /screen(\d+)/.exec(this.getAttribute("id"));
			var indx = res[1];
			setActiveScreen(indx);
		}

		function createSidebarButtons() {
			for (var i=0; i<256; i++) {
				if (i != 0 && ((i % 16) == 0)) {
					$("div#screenList").append($("<br>"));
				}

				var e = $("<button>");
				e.attr("id", "screen" + i);
				e.css('border', "1px solid black");
				e.css('width', "30px");
				e.css('float', "left");
				e.css('marginRight', '6px');
				e.html(i.toString(16));
				e.click(onScreenButtonClick);
				$("div#screenList").append(e);
			}
		}

		function isScreenEmpty(indx) {
			for (var x=0; x<12*20; x++) {
				if (TileMapEditor._tiles[indx][x]) {
					return false;
				}
			}

			return true;
		}

		function serializeScreen(indx) {
			var str = new Array();
			for (var x=0; x<12*20; x++) {
				var d = TileMapEditor._tiles[indx][x];
				str.push(d);
			}

			return str.join(' ');
		}

		function serializeAllScreens() {
			for (var i=0; i<256; i++) {
				if (isScreenEmpty(i) == false) {
					var e = $("<input>");
					e.attr("type", "hidden");
					e.attr("name", "screen" + i);
					e.attr("value", serializeScreen(i));
					$("#save-form").append(e);
				}
			}
		}

		function onSaveClicked() {
			serializeAllScreens();
			$("form#save-form input[name='currentScreen']").val(currentScreen);
			$("form#save-form").submit();
		}

		$(document).ready(function() {
			TileMapEditor.initialize();

			<?
				foreach($screens as $id => $value) 
				{
					$str = implode(",", $value);
					
					?>TileMapEditor._tiles[<?= $id ?>] = [<?= $str ?>];
				<?
				}
			?>

			TileMapEditor.paint();
			$("form#save-form input[type=button]").click(onSaveClicked);
			createSidebarButtons();

			setActiveScreen(currentScreen);
		});
		</script>

	</script>
</body>
</html>
