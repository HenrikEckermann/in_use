# Own

#### Here I will upload self written programs that I created mostly for exercise purposes. Below you find them listed with a short explanation. If you find that I made mistakes or that code style could be much better, please give me feedback. Also, if you have any suggestions on how to improve things, let me know. 
All programs work fine on my computer (MAC OS - Anaconda). You would need to modify the folder-names.

Take the investment.py with a grain of salt as this is an extremely oversimplified and unrealistic model. It may help to calculate how a diversified portfolio can develop IF you modify the return methods. 

### 1. Pomodoro timer 

Note:
1. You need timer.py for this one.
2. The sound will only work on Mac OS (tested on Sierra). Use winsound for Winodws and there are alternatives for Linux.

Pomodoro is a technique that helps you to stay motivated and to focus on your tasks: You choose a task and specify the duration you will focus on the task without letting distract you from anything like social media, phone, other tasks etc.. Then you set the timer and begin to work. Do not interrupt the task until the time is over to train focus control. If you do not manage to focus for e.g. 25min, choose shorter time intervals. You may also choose a longer time interval but it is recommended to make a short break ever 25-35 minutes. Thus, when the time is over, make a short break of about 5 minutes. After 4 25 min cycles, make a longer break of at least 25 min. Go out for a walk or do anything that does not require you the focus effort so that you brain can rest.

Although the name is Pomodoro, this program is not only a Pomodoro timer but you can also choose to NOT specify a time before or to make an entry about a task you did in the past. Sometimes you cannot make a pause or you work in a team and need to fit the team’s work schedule. 

If you use this program daily for all your work related activities (or other activities), you will know exactly how long it took to finish a specific task. Over time, this will help you to better estimate how much time you will need for a certain task and you may find it motivating to see what you have done. I found that I underestimated the time I spent working on certain tasks. The data will be in a Pandas DF locally on you computer. So modify the foldernames before you use the program.

The pandas DF format with datetime index makes it easy to analyze your data.

### How to use:
Start using by calling the function pom(). 
Follow instructions. 
If you want to use the countdowntimer, choose option 2. 


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

### 4. Timer
Simple countdown timer and string_to_timedelta function that I needed for the Pomodoro timer.








