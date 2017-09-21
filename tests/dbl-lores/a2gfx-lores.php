<?
	$colors = array
	(
		0x000000, // black
		0xd00030, // deep red
		0x000090, // dark blue
		0xd020d0, // purple
		0x007020, // dark green
		0x505050, // dark gray
		0x2020f0, // medium blue
		0x60a0f0, // light blue
		0x805000, // brown
		0xf06000, // orange
		0xaaaaaa, // light gray
		0xf09080, // pink
		0x10d000, // light green
		0xf0f090, // yellow
		0x40f090, // aqua
		0xffffff, // white
	);

	# generate scanline_to_offset array for lo-res
	$scanline_to_offset = array();

	for ($y=0; $y<8; $y++)
	{
		$scanline_to_offset[] = ($y*0x80);
	}

	for ($y=0; $y<8; $y++)
	{
		$scanline_to_offset[] = ($y*0x80 + 0x28);
	}

	for ($y=0; $y<8; $y++)
	{
		$scanline_to_offset[] = ($y*0x80 + 0x50);
	}

	function find_closest_color_to($color)
	{
		global $colors;

		$r = ($color >> 16) & 0xff;
		$g = ($color >> 8) & 0xff;
		$b = ($color >> 0) & 0xff;

		$best_color = 0;
		$best_distance = 0xff*0xff*3;

		for ($i=0; $i<16; $i++)
		{
			$rx = ($colors[$i] >> 16) & 0xff;
			$gx = ($colors[$i] >> 8) & 0xff;
			$bx = ($colors[$i] >> 0) & 0xff;
			$distance = ($rx-$r)*($rx-$r) + ($gx-$g)*($gx-$g) + ($bx-$b)*($bx-$b);
			if ($distance < $best_distance)
			{
				$best_distance = $distance;
				$best_color = $i;
			}	
		}

		return $best_color;
	}

	$im = imagecreatefrompng("80x48-6.png");
	assert(imagesx($im) == 80);
	assert(imagesy($im) == 48);

	$out1 = array();
	$out2 = array();
	for ($i=0; $i<1024; $i++) 
	{
		$out1[$i] = chr(255);
		$out2[$i] = chr(255);
	}

	for ($y=0; $y<48; $y+=2)
	{
		for ($x=0; $x<80; $x++)
		{
			$color_down = find_closest_color_to(imagecolorat($im, $x, $y+0));
			$color_up = find_closest_color_to(imagecolorat($im, $x, $y+1));

			$offset = $scanline_to_offset[$y >> 1] + ($x >> 1);
			$byte = ($color_up << 4) | $color_down;

			if (($x & 1) == 1)
			{
				$out1[$offset] = chr($byte);
			}
			else
			{
				$out2[$offset] = chr($byte);
			}
		}
	}

	$out1 = join('', $out1);
	$out2 = join('', $out2);

	file_put_contents("DBLLORES.PIC", $out1);
	file_put_contents("DBLLORES2.PIC", $out2);
?>