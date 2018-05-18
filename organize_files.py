'''
Created on 14.03.2017

@author: henrikeckermann
'''
import re
import shutil
import os


def media_trans(directory, destpath, create_folder='', regEx=''):
    ''' moves media files (or filenames that match specified regular expression) from directory (incl. subfolders) into a single destpath.
        Creates new folder if specified.
    '''
    
    #check if directory exists
    if not os.path.exists(directory):
        print('\'{}\' does not exist! Please specify an existing directory'.format(directory))
    else:
        
        # specify default regEx for media files unless regEx is specified
        if regEx == '':
            fileReg = re.compile('.*(mkv|.*mpeg|.*fla|.*swf|.*flv|.*mov|.*m4v|.*mp4|.*mpg|.*mp3|.*flac|.*wmv|.*sub|.*idx|.*sfv|.*avi)')
        else:
            fileReg = re.compile(regEx)
    
        # specify sample regex to ignore sample files that often come with download mediafiles
        sampleReg = re.compile('Sample|sample|SAMPLE')
    
        # create folder (optional) + specify dest for shutil.move
        if  create_folder in os.listdir(destpath):
            dest = '{}/{}'.format(destpath, create_folder)
        elif create_folder != '':
            os.makedirs('{}/{}'.format(destpath, create_folder))
            dest = '{}/{}'.format(destpath, create_folder)
        else:
            dest = destpath
    
        # loop over directories, check if filenames match and if True, move them
        for dirpath, dirnames, filenames in os.walk(directory):
            for filename in filenames:
                print('\n...checking {}...'.format(filename))
                if fileReg.search(filename) == None:
                    print('...skipped {}...'.format(filename))
                    continue
                if sampleReg.search(filename) != None:
                    print('...skipped {}...'.format(filename))
                    continue
                src = '{}/{}'.format(dirpath, filename)
                shutil.move(src, dest)
                print('...transferred {}...'.format(filename))
                
        print('{}'.format('\n DONE'))




