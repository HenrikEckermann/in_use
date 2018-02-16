# Own

This repository contains modules that I wrote for my own workflow or that haven been created for exercise purposes. You should ignore the exercise content. But maybe you find some of the modules at the top useful for your own workflow. I am always happy for feedback for improvement:

## Python Modules

### 1. cite.py  
- hang_ind will apply hanging indentation to the reference list in a word document. Pandoc cannot apply hanging indentation if you create a docx file from markdown (at least not January 2018). This function will do that. Only use it if the reference list is the last section in your docx! 
- bib_modify will apply correct capitalization (Apa6th) to titles that are stored in a bib file 






## Exercise stuff


### 1. Pomodoro timer 

Note:
1. You need timer.py for this one.
2. The sound will only work on Mac OS (tested on MAC OS Sierra). Use winsound for Windows and there are alternatives for Linux.

Pomodoro is a technique that helps you to stay motivated and to focus on your tasks. Pomodoro means: You choose a task and specify the duration you want focus on the task (without letting you distract from anything like social media, phone, other tasks etc.). Then you set a timer and begin to work. Do not interrupt the task until the time is over to train focus control. If you do not manage to focus for e.g. 25min, choose shorter time intervals. You may also choose a longer time interval but it is recommended to make a short break every 25-35 minutes. Thus, when the time is over, make a short break of about 5 minutes. After 4 25 min cycles, make a longer break of at least 25 min. Go out for a walk or do anything that does not require you the focus effort so that your brain can rest.

Although the name is Pomodoro, this program is not only a Pomodoro timer but you can also choose to NOT specify a time before or to make an entry about a task you did in the past. Sometimes you cannot make a pause or you work in a team and need to fit the team’s work schedule, so this way you can still use Pomodoro.py to track your activities.

If you use this program daily for all your work related activities, you will know exactly how long it took to finish a specific task. Over time, this will help you to better estimate how much time you will need for a certain task and you may find it motivating to see what you have done. I found that I underestimated the time I spent working on certain tasks. The data will be stored in a Pandas DF locally on you computer. So, modify the foldernames before you use the program.

The pandas DF format with datetime index makes it easy to analyze your data.

### How to use:
Start using by calling the function pom(). 
Follow instructions. 
If you want to use the countdowntimer, choose option 2. 


### 2. simulate investment:


### How to use:

To simulate an investment, type **investment()** and within parenthesis you need to specify:
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

**invest_1.apply_crash()** 	





### 3. Transfer media files
This was my first self written program. 

Imagine you recorded videos with your smartphone and you want to copy them onto your local machine. When you open the directory you may find another directory, (for example for dates) within that directory and even another subdirectory for each video file. If you want all your videos in one place you would need to copy every single one and open every directory. This program scans all files (that match specified RegEx) in a specified directory (incl. subdirectories) and moves them to one folder. Default RegEx will scan for most popular audio and video file types such as mp3, mp4, avi...


### How to use

**media_trans(directory, destpath, create_folder='', regEx='')**

### Example:
 --> Find media files in 'users/Videos' incl. subdirectories and move them to 'users/test':
**media_trans('users/Videos', 'users/test')**

 --> Find files that end with 'txt' in 'users/files' incl. subdirectories and move them to 'users/test/here':

**media_trans('users/Videos', 'users/test', create_folder='here',regEx='.*txt')**

### 4. Timer
Simple countdown timer and string_to_timedelta function that I needed for the Pomodoro timer.








