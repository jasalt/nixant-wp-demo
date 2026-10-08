<?php get_header(); ?>

<?php while ( have_posts() ) : the_post(); ?>
	<article <?php post_class( 'project' ); ?>>
		<p class="project__back"><a href="<?php echo esc_url( get_post_type_archive_link( 'project' ) ); ?>">&larr; <?php esc_html_e( 'All projects', 'studio' ); ?></a></p>
		<h1 class="project__title"><?php the_title(); ?></h1>
		<dl class="project__facts">
			<?php
			$studio_facts = array(
				__( 'Client', 'studio' ) => studio_field( 'client' ),
				__( 'Year', 'studio' )   => studio_field( 'year' ),
				__( 'Services', 'studio' ) => get_the_term_list( get_the_ID(), 'service', '', ', ' ),
			);
			foreach ( array_filter( $studio_facts ) as $studio_label => $studio_value ) :
				?>
				<div><dt><?php echo esc_html( $studio_label ); ?></dt><dd><?php echo wp_kses_post( $studio_value ); ?></dd></div>
			<?php endforeach; ?>
		</dl>
		<div class="project__content"><?php the_content(); ?></div>
		<?php $studio_url = studio_field( 'project_url' ); ?>
		<?php if ( $studio_url ) : ?>
			<p><a class="button" href="<?php echo esc_url( $studio_url ); ?>"><?php esc_html_e( 'Visit the live site', 'studio' ); ?></a></p>
		<?php endif; ?>
	</article>
<?php endwhile; ?>

<?php get_footer(); ?>
