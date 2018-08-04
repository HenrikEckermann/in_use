import os
from string_op import *
import shutil

os.getcwd()
os.chdir("block_4/structural_equation_modeling")

# select week folders, then copy rmd file and adjust header for each week
weeks = [x for x in os.listdir() if x[0] == "w"]
weeks .sort()
for week in weeks[1:]:
    shutil.copy("week_1/hw1.Rmd", f"{week}/hw_{week[5]}.Rmd")
    s_replace(f"{week}/hw_{week[5]}.Rmd", "Week 1", f"Week {week[5]}")
for week in weeks[1:]:
    os.remove(f"{week}/hw_{week[5]}_copy.Rmd")

# create r file for each week
for week in weeks[1:]:
    file = open(f"{week}/hw_{week[5]}.R", "w+")
    file.close()
    

# just learned from a pycon talk:

for i, week in enumerate(weeks):
    print(i, week)

for i in sorted(weeks):
    print(i)
for i in reversed(weeks):
    print(i)    
    
for weeks_one, weeks_two in zip(weeks, weeks):
    print(weeks_one, weeks_two)
    