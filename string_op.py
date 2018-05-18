import os
import re
import shutil


def s_replace(filename, old_string, new_string, copy=True):
    '''
    Changes the input file by replacing old_string (which can be regex) with new_string and prints 'DONE'. With the default (copy==True), a copy of the file is created before.
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
