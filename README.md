# Own

#### Here I will upload self written programs that I created mostly for exercise purposes. Below you find them listed with a short explanation. If you have any feedback or find that I made mistakes, please give me feedback so that I can improve. Also, if you have ideas on how to improve things, let me know your suggestions. All programs work on my computer. Of course you may need to modify the foldernames that may be used.
Take the investment.py with a grain of salt as this is an extremely oversimplified and unrealistic model. It may help to calculate how a diversified portfolio can develop IF you modify the return methods. 

### 1. Pomodoro timer:
Pomodoro is a technique that helps you to stay motivated and to focus on your tasks. This program tracks how long and how often you work on specified tasks.
Although the name is Pomodoro, this program is not a pomodoro timer (yet) but it helps to use the Pomodoro technique (or other techniques). I use a pomodoro timer app on my Iphone to regularly pause and work in 25 min steps on a task.
If you use this program daily for all your work related activities (or other activities), you will know exactly how long it took to finish a specific task. Over time, this will help you to better estimate how much time you will need for a certain task and I find it motivating to see what I have done. I found that I underestimated the time I spent working on certain tasks. 

The pandas DF format with datetime index make it easy to analyze your data.

### How to use:
Start using by calling the function pom(). 
Enter a string (the task you work on), enter ‚q’ to quit the program or just return to continue the task you had been working on last time.
If you make a pause or if you finished, press Enter again. 
The date, task and duration has been tracked and stored in a Pandas DF called data. 



### 2. simulate investment:
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





### 3. Transfer media files
This was my first self written program. 

Imagine you recorded videos with your smartphone and you want to copy them onto your local machine. When you open the directory you may find another directory, (for example for dates) within that directory and even another subdirectory for each video file. If you want all your videos in one place you would need to copy every single one and open every directory. This program scans all files (that match speciefied RegEx) in a specified directory (incl. subdirectories) and moves them to one folder. Default RegEx will scan for most popular audio and video file types such as mp3, mp4, avi...


### How to use

**media_trans(directory, destpath, create_folder='', regEx='')**

### Example:
 --> Find media files in 'users/Videos' incl. subdirectories and move them to 'users/test':
**media_trans('users/Videos', 'users/test')**

 --> Find files that end with 'txt' in 'users/files' incl. subdirectories and move them to 'users/test/here':

**media_trans('users/Videos', 'users/test', create_folder='here',regEx='.*txt')**










