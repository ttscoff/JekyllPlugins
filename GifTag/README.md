### Jekyll/Liquid tag for animated GIFs

Output a styled animated gif img element for onClick play/pause with preloading.

    {% gif path_to_gif %}

You can pass in either a path to a JPEG or PNG poster image, or the GIF path, as long as both exist.

Sample output:

    <figure class="animated_gif_frame" data-caption="GIF (2MB)">
      <img class="animated_gif" src="/uploads/2015/08/autobook.jpg" data-source="/uploads/2015/08/autobook.gif" width="800" height="450">
      <figcaption>Click to play</figcaption>
    </figure>

#### Poster image generation

If a GIF extension is passed, and a JPEG or PNG image with the same base name exists in the same folder, it will be used as the poster image. 

If not, and ImageMagick's convert command (`brew install imagemagick`) is available, a JPEG will be created from the first frame.

By default, any executable for `convert` found in $PATH will be used. To provide a path to the convert command, "imagemagick_convert" can be set
in _config.yml to point to a valid installation of ImageMagick's `convert`.

    imagemagick_convert: /usr/local/bin/convert

#### Width/Height tags

If ImageMagick `identify` is available (or set in _config.yml with "imagemagick_identify") image width and height will be included in the tag as attributes. A fallback to `sips` is provided if available (OS X).

  imagemagick_identify: /usr/local/bin/identify

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

Below is the Compass/Sass (scss) required to display the plugin output:

```css
figure.animated_gif_frame {
    position: relative;
    cursor: pointer;
    text-align: center;
    @include opacity(0.85);
    @include transition(opacity, 0.2s, ease-in-out);
    &:hover, &.playing {
        @include opacity(1);
    }

    &::before {
        content: attr(data-caption);
        pointer-events: none;
        position: absolute;
        z-index: 100;
        text-align: center;
        line-height: 2;
        border: solid 3px #666;
        border-radius: 8px;
        font-weight: 700;
        color: #666;
        left: 50%;
        margin-left: -80px;
        width: 160px;
        height: 2em;
        top: 50%;
        margin-top: -1em;
        white-space: nowrap;
        font-size: 21px;
    }

    &.playing::before {
        display: none;
    }


    img {
        padding: 0!important;
        border: none;
        @include box-shadow(none);
        @include opacity(0.5);
    }

    figcaption {
        position: absolute;
        bottom: 0;
        background: rgba(0,0,0,.5);
        color: white;
        display: block;
        width: 100%;
        padding: 0;
        line-height: 2.4;
    }

    &.playing {
        img {
            @include opacity(1);
        }

        figcaption {
            display: none;
        }
    }
}
```

### Customization

To set a default caption, you can swap the commenting on line 37 and 38, and edit the `figcaption` tag (full HTML). Example:

    @figcap = "<figcaption>Click to play&hellip;</figcaption>"

