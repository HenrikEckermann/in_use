import os
import re
import shutil


def search_r_files(directory):
    '''searches directory including subfolders for files that end with .R or 
    .Rmd and returns list of complete paths.'''

    pattern = re.compile(r"([\w|\d]+)(\.R)(md)?$", re.I)
    collected_files = []
    for path, dirs, files in os.walk(directory):
        for file in files:
            if pattern.findall(file):
                collected_files.append(f"{path}/{file}")
    return(collected_files)


def find_pkgs_to_install(files_or_dir, is_dir=False):
    '''If files: Collects all loaded R packages in file and returns ready to
     use command to install those packages. If dir: Searches in dir for files
     to use first.'''

    if is_dir:
        files = search_r_files(files_or_dir)
    else:
        files = files_or_dir
    list_of_pkgs = []
    patterns = [re.compile(r'(library|require)\(([\w\d]+)\)'),
                re.compile(r'(\s|\\n)([\w|\d]+)(::)')]
    if type(files) != list:
        files = [files]
    for file in files:
        with open(file, "r", encoding="utf-8") as f:
            content = f.read()
        for pattern in patterns:
            matches = pattern.finditer(content)
            for match in matches:
                if f"'{match.group(2)}'" not in list_of_pkgs:
                    list_of_pkgs.append(f"'{match.group(2)}'")
    list_of_pkgs.sort()
    list_of_pkgs = ", ".join(list_of_pkgs)
    o_br, c_br = ("{", "}")
    return(f'for (pkg in c({list_of_pkgs})){o_br}\n  if (!require(pkg)){o_br}\n    install.packages(pkg, dependencies = T)\n  {c_br}\n{c_br}')


# # examples for own use:
# print(find_pkgs_to_install(f'{os.path.expanduser("~")}/dropbox', is_dir=True))
# # output:
# for (pkg in c('car', 'emmeans', 'foreign', 'glue', 'kableExtra', 'knitr', 'papaja', 'qwraps2', 'readxl', 'rmarkdown', 'tidyverse')){
#   if (!require(pkg)){
#     install.packages(pkg, dependencies = T)
#   }
# }
# print(find_pkgs_to_install(f'{os.path.expanduser("~")}/Documents/workspace/website/mysite/main/templates', is_dir=True))
# # output
# for (pkg in c('Hmisc', 'MASS', 'VIM', 'afex', 'aplore3', 'arm', 'blmeco', 'car', 'dplyr', 'effects', 'ez', 'foreign', 'ggplot2', 'glue', 'gmodels', 'knitr', 'lattice', 'lmtest', 'ltm', 'mlogit', 'multcomp', 'pander', 'papaja', 'pastecs', 'plyr', 'psych', 'purrr', 'rafalib', 'reshape', 'reshape2', 'rmarkdown', 'stringr', 'tidyverse', 'viridis')){
#   if (!require(pkg)){
#     install.packages(pkg, dependencies = T)
#   }
# }

# you can just use pattern.sub where pattern is an object created with re
# I was  obviously not aware of that while writing the function
def s_replace(filename, old_string, new_string, copy=True):
    '''
    Changes the input file by replacing old_string (which can be regex) with
     new_string and prints 'DONE'. With the default (copy==True), a copy of the
     file is created before.
    '''

    if copy:
        name_split = filename.split('.')
        shutil.copy(filename, f"{name_split[0]}_copy.{name_split[-1]}")
    with open(filename, 'r') as f:
        content = f.read()
    with open(filename, 'w') as f:
        new_content = re.sub(r'{}'.format(old_string), new_string, content)
        f.write(new_content)
    print('DONE')

# example for substitution
# subbed_content = pattern.sub(r'install.packages\2', content)
