# reportifyr-examples

This repository contains example scripts showcasing the features of the `reportifyr` 
R package and is designed to complement the `reportifyr` pkgdown site and `reportifyr` 
analysis repository. 

## Repository Structure

`OUTPUTS`: Directory containing pre-generated artifacts (tables, figures, and footnotes) 
from example script: `01_analysis`. These artifacts are provided for use in other 
example scripts, but users are encouraged to generate them independently. Typically, 
this directory is created using `reportifyr`'s `initialize_report_project()` function.

`report`: Directory containing report scripts, along with shell, draft, and final 
directories, as well as a `standard_footnotes.yaml` file. Again, this setup is provided 
to pre-generate artifacts and inputs for the example scripts but is typically created using 
`reportifyr`'s `initialize_report_project()` function.
 
`scripts`: Directory containing standalone example scripts. This repository is 
structured so users can run each script independently.

## Getting Started

To get started, please clone down this repository and navigate to an example script 
of your choice.

At the beginning of each R script, you will find package installation lines. 
If your R packages are managed by external enterprise solutions, please disregard 
or comment out these lines.
