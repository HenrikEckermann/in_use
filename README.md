# Own

#### Here I will upload self written programs that I created mostly for exercise purposes. Below you find them listed with a short explanation.

### 1. Investment:
I wrote this class to excerise general use of Python and PANDAS. It is my second 'program' and I know that this is not the optimal code but it works and reflects my current (March 2017) level of Python. I planned to use PyMC3 to model expected return rates based on past information. This will be the next exercise for me. At this moment the return rate is simply a random value from a normal distribution. For example the return rate of a very low risk investment is simply a random value of a normal distribution: np.random.normal(loc=1.5,scale=1.5).


### How to use:

To simulate an investment, type **investment()** and within parenthesis you need to spefify:
 - K: Amount of money as integer/float
 - the next three arguments need to be p-values (0-1) as floats that add up to 1. These will spread K into three different parts that can have different expected return rates (you first should modify the class methods according to the information you have about your investment strategy but at default stocks is most risky followed by alt followed by sec).
 - years: Specify how many years should be simulated at once by the classmethod apply(). At default it will be 1 year. The method 'apply_crash()' will always simulate 1 year.


### Example:
 --> invest 100000 in 40% stocks 40% secure, 20% alternative for 10 years:

**invest_1 = investment(100000,0.4,0.4,0.2,10)** 

 --> let 10 years pass and return the data in a DataFrame:

**invest_1.apply()**		
 
 --> Plot the data:

**invest_1.show()**  
 -->Simulates a crash (1 year) in the stocks-part whereas the other 2 parts run as expected:

**invest_apply_crash()** 	





### 2. organize_files
This was my first self written program. 

Imagine you recorded videos with your smartphone and you want to copy them onto your local machine. When you open the directory you may find another directory, (for example for dates) within that directory and even another subdirectory for each video file. If you want all your videos in one place you would need to copy every single one and open every directory. This program scans all files (that match speciefied RegEx) in a specified directory (incl. subdirectories) and moves them to one folder. Default RegEx will scan for most popular audio and video file types such as mp3, mp4, avi...


### How to use

**media_trans(directory, destpath, create_folder='', regEx='')**

### Example:
 --> Find media files in 'users/Videos' incl. subdirectories and move them to 'users/test':
**media_trans('users/Videos', 'users/test')**

 --> Find files that end with 'txt' in 'users/files' incl. subdirectories and move them to 'users/test/here':

**media_trans('users/Videos', 'users/test', create_folder='here',regEx='.*txt')**










