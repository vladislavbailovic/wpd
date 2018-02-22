<?php
/**
 * Plugin name: general debug stuff
 */

function d () {
	echo '<pre>';
	var_export(func_get_args());
	echo '</pre>';
}

function xd () {
	d(func_get_args());
	die;
}

function dt ($bt=false) {
	$arg = $bt ? DEBUG_BACKTRACE_IGNORE_ARGS : null;
	d(debug_backtrace($arg));
}

function xdt ($bt=false) {
	dt($bt);
	die;
}
