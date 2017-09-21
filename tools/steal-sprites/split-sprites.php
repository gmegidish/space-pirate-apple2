<?
	$im = imagecreatefrompng("montezuma_etc_000000001.png");
	
	$index = 0;

	$used = array();

	$y = 0;
	while ($y < imagesy($im))
	{
		$x = 0;
		while ($x < imagesx($im))
		{
			$im2 = imagecreatetruecolor(14, 16);
			imagecopy($im2, $im, 0, 0, $x, $y, 14, 16);

			imagepng($im2, ".crap");
			$sha = sha1(file_get_contents(".crap"));
			unlink(".crap");
			if (!in_array($sha, $used))
			{
				$used[] = $sha;

				imagepng($im2, sprintf("tile-%04d.png", $index++));
			}

			imagedestroy($im2);
			
			$x += 14;
		}

		$y += 16;
	}

?>