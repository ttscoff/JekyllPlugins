### Jekyll/Liquid tag for responsive video embed

This is just a quick tag I whipped up. It was simple enough that I didn't spend much time looking around to see if it already existed. It's specifically for embedding YouTube videos with extra code to make them responsive. You pass it a YouTube video id (optionally a full embed or page/shortened url, it will extract the id) and --- if needed --- a width and height. It defaults to 640 x 480.

With the plugin installed, the following tag creates a responsive YouTube video embed.


    {% youtube B4g4zTF5lDo 480 360 %}

You can also use a full page (optionally the short url) or embed url:

    {% youtube http://youtu.be/2NI27q3xNyI %}

## CSS

Resizing the page with the embeded video causes the video to flex with the width of its container. This is done by wrapping the embedded iframe with a container div and applying the CSS:

```css
.bt-video-container {
    position:relative;
    padding-bottom:56.25%;
    padding-top:30px;
    height:0;
    overflow:hidden }

    .bt-video-container iframe,
    .bt-video-container object,
    .bt-video-container embed {
        position:absolute;
        top:0;
        left:0;
        width:100%;
        height:100%;
        margin-top:0 }
```

If you already have CSS similar to this in your stylesheet, you can adjust the classname on the wrapper and remove the line that inserts the style tag.

## JavaScript

This is the JavaScript (jQuery) I use to add load on click:

      $(".bt-video-container a.youtube").each(function(index) {
        var $this = $(this),
            embedURL,
            videoFrame,
            youtubeId = $this.data("videoid");

        // empty any placeholders
        $this.html('');
        $this.prepend('<div class="bt-video-container-div"></div>&nbsp;');
        // set the poster image from YT as the background for the div (sized to cover in CSS)
        $this.css("background", "#000 url(http://img.youtube.com/vi/"+youtubeId+"/maxresdefault.jpg) center center no-repeat");
        // set a unique id based on video ID.
        $this.attr("id", "yt" + youtubeId);
        // create an embed url.
        // leave off the protocol to prevent http/https mismatch
        // youtube-nocookie prevents YouTube from tracking your visitors *unless* they play the video
        // autoplay makes sense because they've already clicked
        // rel=0 prevents "Related Videos" from displaying at the end of the video
        embedUrl = '//www.youtube-nocookie.com/embed/' + youtubeId + '?autoplay=1&rel=0';
        // set up the embed iframe for injection. Hardcode the dimensions based on those passed in the video tag.
        videoFrame = '<iframe width="' + parseInt($this.data("width"), 10) + '" height="' + parseInt($this.data("height"), 10) + '" style="vertical-align:top;" src="' + embedUrl + '" frameborder="0" allowfullscreen></iframe>';
        // add a click handler to the link which stops it from following the default href and replaces it with the iframe we created
        $this.click(function(ev) {
          ev.preventDefault();
          $("#yt" + youtubeId).replaceWith(videoFrame);
          return false;
        });
      });
    }
