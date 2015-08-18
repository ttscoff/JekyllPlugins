### Jekyll/Liquid tag for animated GIFs

Output a styled animated gif img element for onClick play/pause with preloading.

    {% gif path_to_gif %}

You can pass in either a path to a JPEG or PNG poster image, or the GIF path, as long as both exist.

Sample output:

    <figure class="animated_gif_frame">
        <img src="/uploads/2015/08/autobook.jpg" data-source="/uploads/2015/08/autobook.gif" width="800" height="450" />
    </figure>

#### Poster image generation

If a GIF extension is passed, and a JPEG or PNG image with the same base name exists in the same folder, it will be used as the poster image. 

If not, and ImageMagick's convert command is available, a JPEG will be created from the first frame.

By default, any executable for `convert` found in $PATH will be used. To provide a path to the convert command, "imagemagick_convert" can be set
in _config.yml to point to a valid installation of ImageMagick's `convert`.

    imagemagick_convert: /usr/local/bin/convert

#### Width/Height tags

If `sips` is available (OS X), image width and height will be included in the tag.

### Installation

Install the plugin in your Jekyll plugins folder. You'll need to add some JavaScript and CSS to your template to get the onClick loading working.

#### JavaScript (jQuery)

This will find all instances of poster frame images, assign a click handler to swap the original with the animated GIF (and back on next click), as well as start pre-loading the GIF's after DOM ready.

```javascript
(function($){
    var gif = [];

    $('figure.animated_gif_frame img').each(function(i, n) {
        var data = $(n).attr('src').replace(/\.(png|jpg)$/,'.gif');
        gif.push(data);
        $(n).attr('data-source', data).data('alt', data).on('click', function() {
          var $img = $(this),
              imgSrc = $img.attr('src'),
              imgAlt = $img.attr('data-source'),
              imgExt = imgAlt.replace(/^.*?\.(\w+)$/,'$1');

          if(imgExt === 'gif') {
              $img.attr('src', $img.data('alt')).attr('data-source', imgSrc);
              $img.closest('.animated_gif_frame').addClass('playing');
          } else {
              $img.attr('src', imgAlt).attr('data-source', $img.data('alt'));
              $img.closest('.animated_gif_frame').removeClass('playing');
          }
        });
    });

    var image = [];

    $.each(gif, function(index) {
        image[index]     = new Image();
        image[index].src = gif[index];
    });
})(jQuery);
```

#### CSS

The CSS references a PNG overlay file that needs to be placed at `/images/gif-play-button.png` from the root of the site.

```css
figure.animated_gif_frame {
  position: relative;
  cursor: pointer;
  opacity: 0.85;
  transition: opacity, 0.2s, ease-in-out; }
  figure.animated_gif_frame:hover, figure.animated_gif_frame.playing {
    opacity: 1; }
  figure.animated_gif_frame::before {
    content: ' ';
    pointer-events: none;
    position: absolute;
    z-index: 100;
    background: url(/images/gif-play-button.png) center center no-repeat;
    width: 100%;
    height: 100%; }
  figure.animated_gif_frame.playing::before {
    display: none; }
  figure.animated_gif_frame.playing img {
    opacity: 1; }
```

