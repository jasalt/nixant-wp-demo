<?php
$studio_year     = studio_field( 'year' );
$studio_client   = studio_field( 'client' );
$studio_featured = (bool) studio_field( 'featured' );
$studio_services = get_the_terms( get_the_ID(), 'service' );
?>
<article <?php post_class( array( 'project-card', $studio_featured ? 'project-card--featured' : '' ) ); ?>>
	<div class="project-card__meta">
		<?php if ( $studio_year ) : ?>
			<span class="project-card__year"><?php echo esc_html( $studio_year ); ?></span>
		<?php endif; ?>
		<?php if ( $studio_featured ) : ?>
			<span class="project-card__badge"><?php esc_html_e( 'Featured', 'studio' ); ?></span>
		<?php endif; ?>
	</div>
	<h2 class="project-card__title"><a href="<?php the_permalink(); ?>"><?php the_title(); ?></a></h2>
	<?php if ( $studio_client ) : ?>
		<p class="project-card__client"><?php echo esc_html( $studio_client ); ?></p>
	<?php endif; ?>
	<div class="project-card__excerpt"><?php the_excerpt(); ?></div>
	<?php if ( $studio_services && ! is_wp_error( $studio_services ) ) : ?>
		<ul class="project-card__services">
			<?php foreach ( $studio_services as $studio_service ) : ?>
				<li><?php echo esc_html( $studio_service->name ); ?></li>
			<?php endforeach; ?>
		</ul>
	<?php endif; ?>
</article>
