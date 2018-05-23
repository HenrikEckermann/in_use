# test something...
import os
os.getcwd()
os.chdir('/Users/Henne/Desktop')
os.listdir()
doc = Document('test.docx')
n = len(doc.paragraphs)
for p in range(n):
    if doc.paragraphs[p].text[0:6] == 'Figure':

doc.paragraphs[9].add_run()
doc.save('test.docx')        




word = 'Figure 1'
p = doc.paragraphs[9]
p.runs[0].text = 'Figure 1. test motherfucker'


part_1, part_2 = p.runs[0].text[0:10], p.runs[0].text[10:]

runner_1 = p.add_run(part_1)
runner_2 = p.add_run(part_2)
runner_1.italic = True
runner_2.italic = False
p.runs[0] = runner_1
p.runs[1] = runner_2
doc.save('test.docx')
runner_1.text