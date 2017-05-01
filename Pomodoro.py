#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr 17 09:49:39 2017

@author: henrikeckermann
"""
import pandas as pd
import datetime
import os
import timer

  
def pom_finite():
    '''Pomodoro timer'''
    if os.path.isfile('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl'):
        data = pd.read_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
    task = input('Continue last [Enter] or New [\'string\'+Enter]:\n ')
    now = datetime.datetime.now()
    if task == '':
        task = data['Tasks'][-1]
    td = timer.countdown_pom()
    print(td)
    data_dict = {'Tasks': [task], 'Duration':td}
    index = [now]
    global data_new
    data_new = pd.DataFrame(data_dict,index =index)
    data_new = data_new[['Tasks','Duration']]
    
    

def pom_infinite():
    '''Stores date,time and task after you end program''' 
    task = input('Continue last [Enter] or New [\'string\'+Enter]:\n ')
    if task == '':
        start = datetime.datetime.now()
        task = data['Tasks'][-1]
    else:
        start = datetime.datetime.now()
    input(' Press Enter to finish or to pause activity...') 
    duration = datetime.datetime.now()-start
    global data_new
    data_new = pd.DataFrame({'Duration':[duration],'Tasks':[task]})
    data_new.index=[start]
    data_new = data_new[['Tasks','Duration']]
        

def pom_man(task,duration,seconds=0):
    ''' Makes manual entry in the pomodoro data.
        Task is a string and duration a tuple where specify hours and minutes:
        E.g.: pom_man('Learned Statistics', (1,30)).
    '''
    ds = [int(i) for i in input('Type date as follows: 2017 12 24 14 14 \n').split()]
    y,m,d,h,minute = ds[0],ds[1],ds[2],ds[3],ds[4]
    td = datetime.timedelta(hours=duration[0], minutes=duration[1])
    data_dict = {'Tasks': task, 'Duration':td}
    index = [datetime.datetime(y,m,d,h,minute,seconds)]
    global data_new
    data_new = pd.DataFrame(data_dict,index =index)
    data_new = data_new[['Tasks','Duration']]

  
    
def pom():
    while True:
        global data
        data = pd.DataFrame()
        if os.path.isfile('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl'):
            data = pd.read_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
        inp = input('Quit [q], Infinite [1], Pomodoro timer [2], Edit task manually [3]\n')
        if inp == 'q':
            break
        if inp == '1':
            pom_infinite()
        elif inp == '2':
            pom_finite()
        elif inp == '3':
            task=input('Enter Task\n')
            duration =tuple((int(i) for i in input('Enter duration (h:min)\n').split(':')))
            pom_man(task,duration)
        else:
            raise ValueError('{} is no valid input'.format(inp))
        data = data.append(data_new)
        data.to_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
    print(data.tail(10))
    
    
    
        
    
    
    
    

