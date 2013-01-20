### Jekyll/Liquid tag for responsive video embed

This is just a quick tag I whipped up. It was simple enough that I didn't spend much time looking around to see if it already existed. It's specifically for embedding YouTube videos with extra code to make them responsive. You pass it a YouTube video id (optionally a full embed or page/shortened url, it will extract the id) and --- if needed --- a width and height. It defaults to 640 x 480.

With the plugin installed, the following tag creates a responsive YouTube video embed.


    {% youtube B4g4zTF5lDo 480 360 %}

You can also use a full page (optionally the short url) or embed url:

    {% youtube http://youtu.be/2NI27q3xNyI %}

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
