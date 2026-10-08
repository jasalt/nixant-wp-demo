<?php get_header(); ?>

<?php if ( have_posts() ) : ?>
	<?php while ( have_posts() ) : the_post(); ?>
		<article <?php post_class( 'entry' ); ?>>
			<h1 class="entry__title">
				<?php if ( is_singular() ) : ?>
					<?php the_title(); ?>
				<?php else : ?>
					<a href="<?php the_permalink(); ?>"><?php the_title(); ?></a>
				<?php endif; ?>
			</h1>
			<div class="entry__content">
				<?php is_singular() ? the_content() : the_excerpt(); ?>
			</div>
		</article>
	<?php endwhile; ?>
	<?php the_posts_pagination(); ?>
<?php else : ?>
	<p><?php esc_html_e( 'Nothing here yet.', 'studio' ); ?></p>
<?php endif; ?>

<?php get_footer(); ?>
