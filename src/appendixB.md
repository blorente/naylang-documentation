Appendix B: How was this document made?
=======================================

Author
-------
**Note:** the process described in this Appendix was devised by Álvaro
Bermejo, who published it under the MIT license in 2017 [@persimmon].


Process
-------
This document was written on Markdown, and converted to PDF
using Pandoc.

Document is written on Pandoc's extended Markdown, and can be broken amongst
different files. Images are inserted with regular Markdown syntax for images.
A YAML file with metadata information is passed to pandoc, containing things
such as Author, Title, font, etc... The use of this information depends on
what output we are creating and the template/reference we are using.


Diagrams
--------
Diagrams are were created with LaTeX packages such as tikz or pgfgantt, they
can be inserted directly as PDF, but if we desire to output to formats other
than LaTeX is more convenient to convert them to .png files with tools such
as `pdftoppm`.


References
------------
References are handled by pandoc-citeproc, we can write our bibliography in
a myriad of different formats: bibTeX, bibLaTeX, JSON, YAML, etc..., then
we reference in our markdown, and that reference works for multiple formats
