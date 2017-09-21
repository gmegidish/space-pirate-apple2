<?
	for ($c=1; $c<count($argv); $c++)
	{
		print "Processing " . $argv[$c] . "\n";

		$pos = strpos($argv[$c], ".png");
		$base = substr($argv[$c], 0, $pos);

		$im = imagecreatefrompng($argv[$c]);
		assert(imagesx($im) == 560);
		assert(imagesy($im) == 384);

		$im2 = imagecreatetruecolor(280, 192);
		imagecopyresized($im2, $im, 0, 0, 0, 0, 280, 192, 560, 384);
		$im = $im2;

		$tw = imagesx($im) / 14;
		$th = imagesy($im) / 16;
		$im2 = imagecreatetruecolor($tw*15, $th*17);

		imagefilledrectangle($im2, 0, 0, imagesx($im2), imagesy($im2), 0xff00ff);

		for ($y=0; $y<$th; $y++)
		{
			for ($x=0; $x<$tw; $x++)
			{
				imagecopy($im2, $im, $x*15, $y*17, $x*14, $y*16, 14, 16);
			}
		}

		imagepng($im2, "$base-split.png");
	}
?>