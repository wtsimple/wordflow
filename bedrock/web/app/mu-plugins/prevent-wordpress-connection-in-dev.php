<?php
use function Env\env;

/**
 * Plugin Name:  Prevent Wordpress connection in Dev
 * Plugin URI:   https://github.com/ArmandoRiveroPi/wordflow/
 * Description:  Prevents WP from reaching external services during development
 * Version:      1.0.0
 * Author:       Armando Rivero
 * Author URI:   https://github.com/ArmandoRiveroPi/
 * License:      MIT License
 */

// prevents wp from reaching the api.wordpress.org and similar looking for updates and stuff
if (env('WP_ENV') === 'development') {
    add_filter( 'pre_http_request', '__return_true', 100 );
}