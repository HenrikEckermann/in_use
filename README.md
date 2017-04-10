# Own
###Self written programs


####Here I will upload self written programs.

##1. Investment:
I wrote this class to excerise general use of Python and PANDAS. It is my second 'program' and I know that this is not the optimal code but it works and reflects my current (March 2017) level of Python. I planned to use PyMC3 to model expected return rates based on past information. This will be the next exercise for me. At this moment the return rate is simply a random value from a normal distribution. For example in this version the return rate of very low risk investment would simply be a random value of a normal distribution: np.random.normal(loc=1.5,scale=1.5)


###How to use:

To simulate an investment, type **investment()** and within parenthesis you need to spefify:
 - K: Amount of money as integer/float
 - the next three arguments need to be p-values (0-1) as float that add up to 1. These will spread K into three different parts that will have different expected return rates. For example: stocks, annuity fonds, alternative investments such as gold etc. 

<div>
 (You need to edit the functions  stocks_return(), sec_return() and alt_return() before according to the information you have about the expected return. This way you can easily customize the different parts.)
 - years: Specify how many years should be simulated at once by the classmethod apply().
</div>

### Example:
 #Invest 100000: 40% stocks 40% secure, 20% alternative for 10 years.
**invest_1 = investment(100000,0.4,0.4,0.2,10)** 

 # let 10 years pass and return the data in a DataFrame
**invest_1.apply()**		
 # Plot the data
**invest_1.show()**  
 # Simulates a crash (1 year) in the stocks-part whereas the other 2 parts run as expected.		
**invest_apply_crash()** 	




##2. organize_files
This was my first self written program. 

Imagine you recorded videos with you smartphone and you want to copy them onto your local machine. When you open the directory you may find a directory, sometimes a subdirectory (for example for dates) within that directory and even another subdirectory for each video file. If you want all your videos in one place you would need to copy every single one and open every directory. This program does all that for you.

### How to use

**media_trans(directory, destpath, create_folder='', regEx='')**

### Example:
 # Find media files in 'users/Videos' and all subdirectories and move them to 'users/test'.
**media_trans('users/Videos', 'users/test')**

 # Find files that end with 'txt' in 'users/files' and all subdirectories and move them to 'users/test/here'

**media_trans('users/Videos', 'users/test', create_folder='here',regEx='.*txt')**










