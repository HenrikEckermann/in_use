### 1. cite.py  
- hang_ind will add hanging indentation to the reference list in a docx. Pandoc cannot apply hanging indentation if you create a docx file from markdown (at least not January 2018). Only use it if the reference list is the last section in your docx!  
- bib_modify will apply capitalization (Apa6th) to titles that are stored in a bib file. Beware that this function is not aware of names that maybe should be capitalized outside of the applied rules.

### 2. string_op.py
- added two functions that search r code for pkg like either `library(pkg)` or `pkg::` and returns useable `install.packages(...)` statement for use in R. 
- s_replace screens a file for a regex and replaces matches by given string &rarr; this function is unneccessary because re.sub already could do that and more.








