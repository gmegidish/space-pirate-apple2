<?
	$im = imagecreatefrompng("sprites.png");
	$width = 14;
	$count = imagesx($im) / $width;

	$height = imagesy($im);
	assert((imagesx($im) % $width) == 0);

	$pattern = 1;

	for ($i=0; $i<$count; $i++)
	{
		$im2 = imagecreatetruecolor(14, $height);
		imagecopy($im2, $im, 0, 0, $i*$width, 0, $width, $height);

		for ($y=0; $y<$height; $y++)
		{
			if ($y == 0)
			{
				printf("SPRITE%d", $i);
			}

			$binary = "";
			$hex = "";
			for ($x=0; $x<imagesx($im2); $x += 7)
			{	
				/*
				$binary = ($pattern == 0) ? "0" : "1";
				for ($j=0; $j<7; $j++)
				{
					$v = imagecolorat($im2, $x+6-$j, $y);
					$binary .= (($v > 0) ? "1" : "0");
				}
					
				printf("\tdb %%$binary\n");
				*/

				$byte = ($pattern == 0) ? 0 : 0x80;
				for ($j=0; $j<7; $j++)
				{
					$v = imagecolorat($im2, $x+6-$j, $y);
					if ($v != 0)
					{
						$byte |= (1 << (6-$j));
						$binary .= "x";
					}
					else
					{
						$binary .= " ";
					}
				}

				$hex .= sprintf("%02x ", $byte);
	
				if (strlen($binary) == 14)
				{
					$binary = substr($binary, 7) . substr($binary, 0, 7);
					print "\thex $hex \t; " . $binary . "\n";
					$binary = "";
					$hex = "";
				}
			}
		}

		print "\n";
		imagedestroy($im2);
	}

	print "\n";

	for ($i=0; $i<$count; $i++)
	{
		if ($i == 0)
		{
			print "SPRLO";
		}

		print "\tdb <SPRITE" . $i . "\n";
	}

	print "\n";

	for ($i=0; $i<$count; $i++)
	{
		if ($i == 0)
		{
			print "SPRHI";
		}

		print "\tdb >SPRITE" . $i . "\n";
	}

	print "\n";

	imagedestroy($im);
?>