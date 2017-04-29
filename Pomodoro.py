#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Apr 17 09:49:39 2017

@author: henrikeckermann
"""
import pandas as pd
import datetime
import os
    

def pom():
    global data
    data_new = []
    dates = []
    tasks = []
    times = []
    if os.path.isfile('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl'):
        data = pd.read_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')    
    while True:
        task = input(' Quit [q+Enter], Continue last [Enter] or New [\'string\'+Enter]:\n ')
        if task == 'q':
            break
        elif task == '':
            start = datetime.datetime.now()
            task = data['Tasks'][-1]
            tasks.append(task)
            dates.append(datetime.datetime.now())
        else:
            start = datetime.datetime.now()
            tasks.append(task)
            dates.append(datetime.datetime.now())
        input(' Press Enter to finish or to pause activity...') 
        time = datetime.datetime.now()-start
        times.append(time)
    data_new = pd.DataFrame({'Duration':times,'Tasks':tasks})
    data_new.index=dates
    data_new = data_new[['Tasks','Duration']]
    if os.path.isfile('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl'):
        data = data.append(data_new)
        data.to_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
    else:
        data = data_new
        data.to_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
    print(data.tail(10))
    
        

def pom_man(task,duration):
    ''' Makes manual entry in the pomodoro data.
        Task is a string and duration a tuple where specify hours and minutes:
        E.g.: pom_man('Learned Statistics', (1,30)).
    '''
    ds = input('Type date as follows: 2017 12 24 14 14 \n').split()
    ds = [int(i) for i in ds]
    y,m,d,h,minute = ds[0],ds[1],ds[2],ds[3],ds[4]
    s = 0
    td = datetime.timedelta(0, 0, 0, 0, duration[1], duration[0], 0)
    new_dict = {'Tasks': task, 'Duration':td}
    index = [datetime.datetime(y,m,d,h,minute,s)]
    new_df = pd.DataFrame(new_dict,index =index)
    new_df = new_df[['Tasks','Duration']]
    data = pd.read_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
    data = data.append(new_df)
    data.to_pickle('/Users/henrikeckermann/Documents/workspace/Own/pomodoro.pkl')
    

    
    
    
    
    
    

