sealand
=======

Repository for assets relating to the ECND project.


## Project structure

Uses the project layout suggested by [Nice R Code](http://nicercode.github.io/blog/2013-04-05-projects/).

In particular:

* ./ - Contains project-related files
* ./data/ - The data files
* ./doc/ - Documents about the costings (including data and assumptions)
* ./figs/ - Generated images
* ./output/ - Logs, generated data, tables, etc.
* ./R/ - R functions


## Running "R" from the command line

Any of the following:

    Rscript analysis.R
    R --save < analysis.R
    R CMD BATCH analysis.R


## Generating docs

Command for running *pandoc* over *doc/costing.md*:

    pandoc doc/costing.md -S -s --mathjax=http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML -o output/costing.html


## Code style

Code is being migrated to commonly used conventions, e.g.:

 - <https://google-styleguide.googlecode.com/svn/trunk/Rguide.xml>
 - <http://adv-r.had.co.nz/Style.html>
 - <https://docs.google.com/document/d/1esDVxyWvH8AsX-VJa-8oqWaHLs4stGlIbk8kLc5VlII/edit>
