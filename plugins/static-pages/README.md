Put static pages in the `frontend/pages/` or `public/pages/` directories, depending 
on whether you want to them to appear in the staff interface or public user interface.

They will be available at uris like this:

  http://your.domain.org/your_as/static/page
  
Or, for the PUI:

  http://your.domain.org/your_as/static/html/page

Example: The plugin ships with a file called `moo.html`. This would be served at:

  http://your.domain.org/your_as/static/moo.html


Somethings to improve:

  - Stream the file
  - Handle file format correctly
  - Other stuff!

