import os
import re


def s_replace(filename, old_string, new_string, copy=False):
    '''
    Enter filename, the string that should get replaced (old_string can be regex) and the replace. The function changes the file and prints 'DONE'. If copy==True, makes a copy of the file before.
    ''' 
    
    if copy:
        shutil.copy(filename, f"copy_{filename}")
    with open(filename, 'r') as f:
        content = f.read()
    with open(filename, 'w') as f:
        new_content = re.sub(r'{}'.format(old_string), new_string, content)
        f.write(new_content)
    print('DONE')
    
    