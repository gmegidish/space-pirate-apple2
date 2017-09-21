<?
	$im = imagecreatefrompng($argv[1]);
	assert((imagesx($im) % 14) == 0);
#	assert((imagesy($im) % 16) == 0);

	$count = imagesy($im)*imagesx($im) / (14*16);

	$pattern = 1;

	$tw = imagesx($im)/14;
	$th = imagesy($im)/16;

	for ($j=0; $j<$th; $j++)
	{
		for ($i=0; $i<$tw; $i++)
		{
			$im2 = imagecreatetruecolor(14, 16);
			imagecopy($im2, $im, 0, 0, $i*14, $j*16, 14, 16);

			for ($y=0; $y<16; $y++)
			{
				if ($y == 0)
				{
					printf("TILE%d", $j*$tw+$i);
				}

				$binary = "";
				$hex = "";
				for ($x=0; $x<imagesx($im2); $x += 7)
				{	
					/*
					$binary = ($pattern == 0) ? "0" : "1";
					for ($p=0; $p<7; $p++)
					{
						$v = imagecolorat($im2, $x+6-$p, $y);
						$binary .= (($v > 0) ? "1" : "0");
					}
						
					printf("\tdb %%$binary\n");
					*/
					$byte = ($pattern == 0) ? 0 : 0x80;
					for ($p=0; $p<7; $p++)
					{
						$v = imagecolorat($im2, $x+6-$p, $y);
						if ($v != 0)
						{
							$byte |= (1 << (6-$p));
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
	}

	print "TILESLO";
	for ($i=0; $i<$count; $i++)
	{
		print "\tdb <TILE" . $i . "\n";
	}

	print "\nTILESHI";

	for ($i=0; $i<$count; $i++)
	{
		print "\tdb >TILE" . $i . "\n";
	}

	print "\n";

	imagedestroy($im);
?>