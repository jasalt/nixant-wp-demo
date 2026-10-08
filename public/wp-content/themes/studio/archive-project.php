<?php
/**
 * Project archive: a card grid with a filter by service. Also used for the
 * service taxonomy archives (taxonomy-service.php loads this file).
 */

get_header();

$studio_services = get_terms( array( 'taxonomy' => 'service', 'hide_empty' => true ) );
$studio_current  = is_tax( 'service' ) ? get_queried_object_id() : 0;
?>

<header class="archive-header">
	<h1 class="archive-header__title">
		<?php echo is_tax( 'service' ) ? esc_html( single_term_title( '', false ) ) : esc_html__( 'Selected work', 'studio' ); ?>
	</h1>
	<?php if ( $studio_services && ! is_wp_error( $studio_services ) ) : ?>
		<nav class="filter" aria-label="<?php esc_attr_e( 'Filter by service', 'studio' ); ?>">
			<a class="filter__item<?php echo $studio_current ? '' : ' is-active'; ?>" href="<?php echo esc_url( get_post_type_archive_link( 'project' ) ); ?>"><?php esc_html_e( 'All', 'studio' ); ?></a>
			<?php foreach ( $studio_services as $studio_service ) : ?>
				<a class="filter__item<?php echo $studio_current === $studio_service->term_id ? ' is-active' : ''; ?>" href="<?php echo esc_url( get_term_link( $studio_service ) ); ?>"><?php echo esc_html( $studio_service->name ); ?></a>
			<?php endforeach; ?>
		</nav>
	<?php endif; ?>
</header>

<?php if ( have_posts() ) : ?>
	<div class="project-grid">
		<?php
		while ( have_posts() ) :
			the_post();
			get_template_part( 'template-parts/project-card' );
		endwhile;
		?>
	</div>
	<?php the_posts_pagination(); ?>
<?php else : ?>
	<p><?php esc_html_e( 'No projects yet.', 'studio' ); ?></p>
<?php endif; ?>

<?php get_footer(); ?>
