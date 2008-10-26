The Tags extension provides a way for you to easily categorize your pages.

== Results page

	<r:search:empty>
	  <h2>I couldn't find anything tagged with "<r:search:query/>".</h2>
	</r:search:empty>

	<r:search:results>
	  <h2>Found the following pages that are tagged with "<em><r:search:query/></em>".</h2>

	  <ul>
	  <r:search:results:each>
	    <li><r:link/> - <r:author/> - <r:date/></li>
	  </r:search:results:each>
	  </ul>
	</r:search:results>


== Tag cloud

Use `<r:tag_cloud />` anywhere you like.
I made a stab at building the 'perfect' tag cloud markup, as inspired by a post on 24ways.org;  http://24ways.org/2006/marking-up-a-tag-cloud

== Tag list

Use `<r:tag_list />` to get a list of tags for the current page. 
Also works through children:each.

== All tags

Use `<r:all_tags />` to get a list of all tags. You may iterate through them with
`<r:all_tags:each>` and access their associated pages with `<r:all_tags:each:pages:each>`

== Collections

You can grab a collection of pages with a certain tag like so;

	<r:tagged with="sometag" [scope="/some/page"] [with_any="true"]>
	  <r:link />
	</r:tagged>

Which would iterate over all the resulting pages, like you do with children:each.
When you define scope, only this page and any of it's (grand)children will be used.
Using scope="current_page" will use the page that is currently being rendered as scope. 
You can also set limit, offset etc like with children:each.

Using r:tagged in it's default setting searches for pages that have all of the given tags.
Using r:tagged with the attribute 'with_any' set to 'true' will find pages that have any of
the given tags.