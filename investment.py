
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Apr  4 18:06:15 2017

@author: henrikeckermann
"""

#investment

#import modules
import numpy as np
import pandas as pd


class investment:
  
    def __init__(self,K,stocks,sec,alt,years=1):
        self.K = K
        self.stocks = stocks
        self.sec = sec
        self.alt = alt
        self.years = years
        
        #Diversify K according to given ps
        self.K_st = self.stocks*self.K
        self.K_sec = self.sec*self.K
        self.K_alt =self.alt*self.K
        
        #Initialize lists that will be edited later
        self.K_total_values =[]
        self.K_st_values = []
        self.K_sec_values = []
        self.K_alt_values = []
        self.p_st_values = []
        self.p_sec_values = []
        self.p_alt_values = []
        self.p_total_values = []
        self.diff_st = []
        self.diff_sec = []
        self.diff_alt = []
        self.diff_total = []
        
        #Give a warning if p does not add up to 1
        if self.stocks + self.sec + self.alt !=1:
            print('Total should be 1.0 -> please check out your p-values!')

        #Create Dataframe that will be filled with data later
        self.data = pd.DataFrame({'K_total':[K],'K_stocks':[K*stocks],'p_stocks':[0],'K_sec':[K*sec],'p_sec':[0],'K_alt':[K*alt],'p_alt':[0], 'p_total':[0]})
        self.data_diff = pd.DataFrame({'diff_stocks':[0], 'diff_sec':[0],'diff_alt':[0],'diff_total':[0]})
    
    
    @staticmethod
    def zins(K,p, years=1):
        '''return K + interest for given K and p for specified number of years'''
        for i in range(years):
            K = K+((p*K)/100) 
        return K
        

    def stocks_return(self):
        '''Simulates stocks'''
        p = np.random.normal(loc=1,scale=12)
        self.p_st_values.append(p)
        before = self.data.iloc[-1,2]
        self.K_st = self.zins(self.K_st,p)
        self.K_st_values.append(self.K_st)
        diff = self.K_st-before
        self.diff_st.append(diff)
                        
    
    def sec_return(self):
        '''Simulates secure investments'''
        p = np.random.normal(loc=1,scale=1.5)
        self.p_sec_values.append(p)
        before = self.data.iloc[-1,1]
        self.K_sec = self.zins(self.K_sec,p)
        self.K_sec_values.append(self.K_sec)
        diff = self.K_sec-before
        self.diff_sec.append(diff)


    def alt_return(self):
        '''Simulates alternative investments'''
        p = np.random.normal(loc=1,scale=10)
        self.p_alt_values.append(p)
        before = self.data.iloc[-1,0]
        self.K_alt = self.zins(self.K_alt,p)
        self.K_alt_values.append(self.K_alt)
        diff = self.K_alt-before
        self.diff_alt.append(diff)


    def distrib(self):
        '''Distributes K according to determined p-values'''
        self.K = self.K_st + self.K_sec + self.K_alt
        self.K_total_values.append(self.K)
        self.K_st = self.stocks*self.K
        self.K_sec = self.sec*self.K
        self.K_alt =self.alt*self.K
        

    def update(self):
        '''update dataframes and calculate p_total'''
        data_temp = pd.DataFrame({'K_total':self.K_total_values,'K_stocks':self.K_st_values,'p_stocks':self.p_st_values,'K_sec':self.K_sec_values,'p_sec':self.p_sec_values,'K_alt':self.K_alt_values,'p_alt':self.p_alt_values})
        self.diff_total.append(self.diff_st[0]+self.diff_sec[0]+self.diff_alt[0])
        data_diff_temp = pd.DataFrame({'diff_stocks':self.diff_st, 'diff_sec':self.diff_sec,'diff_alt':self.diff_alt,'diff_total':self.diff_total})
        data_temp['p_total'] = (data_diff_temp.diff_total/self.data.iloc[-1,3])*100
        self.data = self.data.append(data_temp,ignore_index=True)
        self.data_diff = self.data_diff.append(data_diff_temp, ignore_index=True)
        
      
    def reset(self):
        self.p_st_values = []
        self.p_sec_values = []
        self.p_alt_values = []
        self.p_total_values =[]
        self.K_total_values = []
        self.K_st_values = []
        self.K_sec_values = []
        self.K_alt_values = []
        self.diff_st = []
        self.diff_sec = []
        self.diff_alt = []
        self.diff_total = []
        
        
    def apply(self):
        '''Let specified time pass'''
        for i in range(self.years):
            self.stocks_return()
            self.sec_return()
            self.alt_return()
            self.distrib()
            self.update()
            self.reset()
        print(self.data.tail())
        print(self.data_diff.tail())

    def show(self):
        self.data.plot(marker='o', subplots=True,figsize=(15,15))
        
         
    def apply_crash(self):
        '''simulates a crash in stocks market'''

        self.sec_return()
        self.alt_return()
        
        #here comes the crash
        p = np.random.normal(loc=-60,scale=10)
        self.p_st_values.append(p)
        before = self.K_st
        self.K_st = self.zins(self.K_st,p)
        self.K_st_values.append(self.K_st)
        diff = self.K_st-before
        self.diff_st.append(diff)
        
        self.distrib()
        self.update()
        self.reset()
        print(self.data.tail())
        print(self.data_diff.tail())



            
    

        



