<?php
/**
 * Studio theme setup.
 */

defined( 'ABSPATH' ) || exit;

add_action(
	'after_setup_theme',
	function (): void {
		add_theme_support( 'title-tag' );
		add_theme_support( 'post-thumbnails' );
		add_theme_support( 'html5', array( 'search-form', 'gallery', 'caption', 'style', 'script' ) );
		register_nav_menus( array( 'primary' => __( 'Primary', 'studio' ) ) );
	}
);

// No XML-RPC endpoint to discover on the static export (bin/export-static.sh).
remove_action( 'wp_head', 'rsd_link' );

add_action(
	'wp_enqueue_scripts',
	function (): void {
		$css = '/assets/css/main.css';
		// A hash of the file as version: edits bust the browser cache, and a
		// static export only changes when the CSS does (unlike its mtime).
		wp_enqueue_style( 'studio', get_theme_file_uri( $css ), array(), substr( md5_file( get_theme_file_path( $css ) ), 0, 8 ) );
	}
);

/**
 * A project field, also when Secure Custom Fields is inactive.
 */
function studio_field( string $name, ?int $post_id = null ): mixed {
	$post_id ??= get_the_ID();
	return function_exists( 'get_field' ) ? get_field( $name, $post_id ) : get_post_meta( $post_id, $name, true );
}
