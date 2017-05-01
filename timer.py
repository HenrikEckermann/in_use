#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon May  1 09:18:55 2017

@author: henrikeckermann
"""

import time
import datetime
import os


def string_to_td(s,d=0):
    '''The string must be in the format h:m:s. Specifying days is optional!'''
    spl= [int(x) for x in s.split(':')]
    td = datetime.timedelta(days=d,hours=spl[0],minutes=spl[1],seconds=spl[2])
    return td
    

def countdown(days=0):
    '''You need to specify days seperately'''
    td = string_to_td(input('Specify time (h:m:s)\n'),d=days)
    f_time = datetime.datetime.now()+td
    while datetime.datetime.now()<f_time:
        left = f_time-datetime.datetime.now()
        print('\r{}'.format(str(left).split('.')[0]),end='')
        time.sleep(1)
    os.system('say The time is over!')   
    
    
    
def countdown_pom():
    m = int(input('Specify length in minutes:\n'))
    global td
    td = datetime.timedelta(minutes = m)
    f_time = datetime.datetime.now()+td
    while datetime.datetime.now()<f_time:
        left = f_time-datetime.datetime.now()
        print('\r{}'.format(str(left).split('.')[0]),end='')
        time.sleep(1)
    os.system('say The time is over')
    return td
    
    