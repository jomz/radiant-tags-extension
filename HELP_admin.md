The Tags extension allows you to configure the style of tagging between 2 options: 
simple or complex strings.

== Simple Tagging

By default you may add tags to a page in a string such as "this that other". That string 
will be parsed and turned into 3 separate tags.

== Complex Tagging

You may set `Radiant::Config['tags.complex_strings'] = true` to allow you to enter more 
complex tags for your pages.

When this setting is `true` the tags are delimited by a semi-colon, allowing you to enter 
a string of tags such as "My Summer Vacation (2008); Entertainment/Nonsense". The result of that string 
will return 2 tags: `My Summer Vacation (2008)` and `Entertainment/Nonsense`

== Making the choice

You'll need to restart the application server after changing this setting. Please keep in
mind that any changes to this setting may affect any tags you currently have in the database.
It is recommended that you choose either Simple or Complex, but that you do not switch 
after creating your tags.

== Tag Clouds

Some styles are provided in tags.css for the <r:tag_cloud>. To use it, add this to your layout:
    <link rel="stylesheet" type="text/css" href="/stylesheets/tags.css" />