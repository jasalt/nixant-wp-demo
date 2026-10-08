<?php
/**
 * Plugin Name: Studio Site
 * Description: Content model for the Studio site: the Project post type, the Service taxonomy and the project fields (Secure Custom Fields).
 * Version: 0.1.0
 * Requires Plugins: secure-custom-fields
 */

namespace Studio\Site;

defined( 'ABSPATH' ) || exit;

function register_content_types(): void {
	register_post_type(
		'project',
		array(
			'labels'       => array(
				'name'          => __( 'Projects', 'studio-site' ),
				'singular_name' => __( 'Project', 'studio-site' ),
				'add_new_item'  => __( 'Add New Project', 'studio-site' ),
				'edit_item'     => __( 'Edit Project', 'studio-site' ),
				'all_items'     => __( 'All Projects', 'studio-site' ),
			),
			'public'       => true,
			'has_archive'  => 'projects',
			'rewrite'      => array( 'slug' => 'projects', 'with_front' => false ),
			'menu_icon'    => 'dashicons-portfolio',
			'show_in_rest' => true,
			'supports'     => array( 'title', 'editor', 'excerpt', 'thumbnail' ),
		)
	);

	register_taxonomy(
		'service',
		'project',
		array(
			'labels'            => array(
				'name'          => __( 'Services', 'studio-site' ),
				'singular_name' => __( 'Service', 'studio-site' ),
			),
			'public'            => true,
			'hierarchical'      => false,
			'show_admin_column' => true,
			'show_in_rest'      => true,
			'rewrite'           => array( 'slug' => 'services', 'with_front' => false ),
		)
	);
}
add_action( 'init', __NAMESPACE__ . '\register_content_types' );

// Field groups live in code so they are versioned with the site.
function register_fields(): void {
	acf_add_local_field_group(
		array(
			'key'      => 'group_studio_project',
			'title'    => 'Project details',
			'fields'   => array(
				array(
					'key'      => 'field_studio_client',
					'label'    => 'Client',
					'name'     => 'client',
					'type'     => 'text',
					'required' => 1,
				),
				array(
					'key'   => 'field_studio_year',
					'label' => 'Year',
					'name'  => 'year',
					'type'  => 'number',
					'min'   => 1990,
					'max'   => 2100,
				),
				array(
					'key'   => 'field_studio_url',
					'label' => 'Live site',
					'name'  => 'project_url',
					'type'  => 'url',
				),
				array(
					'key'           => 'field_studio_featured',
					'label'         => 'Featured',
					'name'          => 'featured',
					'type'          => 'true_false',
					'ui'            => 1,
					'default_value' => 0,
				),
			),
			'location' => array(
				array(
					array(
						'param'    => 'post_type',
						'operator' => '==',
						'value'    => 'project',
					),
				),
			),
			'position' => 'acf_after_title',
		)
	);
}
add_action( 'acf/include_fields', __NAMESPACE__ . '\register_fields' );

// Newest work first on the project and service archives.
function order_projects( \WP_Query $query ): void {
	if ( is_admin() || ! $query->is_main_query() ) {
		return;
	}
	if ( $query->is_post_type_archive( 'project' ) || $query->is_tax( 'service' ) ) {
		$query->set( 'meta_key', 'year' );
		$query->set( 'orderby', array( 'meta_value_num' => 'DESC', 'title' => 'ASC' ) );
		$query->set( 'posts_per_page', 12 );
	}
}
add_action( 'pre_get_posts', __NAMESPACE__ . '\order_projects' );

register_activation_hook(
	__FILE__,
	function (): void {
		register_content_types();
		flush_rewrite_rules();
	}
);
register_deactivation_hook( __FILE__, 'flush_rewrite_rules' );
