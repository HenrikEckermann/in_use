_This repository contains small scripts or files that I use in my workflow._

### 1. cite.py  
- hang_ind will add hanging indentation to the reference list in a docx. Pandoc cannot apply hanging indentation if you create a docx file from markdown (at least not January 2018). Only useful if the reference list is the last section in your docx!  
- bib_modify applies capitalization (Apa6th) to titles that are stored in a bib file. This function does not take care of names that should be capitalized.

### 2. string_op.py
- added two functions that search files with R code for pkgs like either `library(pkg)` or `pkg::` and returns useable `install.packages(...)` statement for use in R. 
- s_replace screens a file for a regex and replaces matches by string. Since this function uses re.sub, the new string can be group matches of defined groups. E.g. useful if you copy text from a word file right into markdown. You could use this edit numbered headers (word) into markdown headers like this: `s_replace("somefile.Rmd", r"(\s{2,})(\d{1,2}\.\s)", r"\n\n##### \2", copy = False)` 

### 3. reporting.R
- functions to ease reporting in APA6th style for LME4/afex, test statistics etc.








