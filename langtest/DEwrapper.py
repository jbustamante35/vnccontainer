import os

path = os.getcwd()
newdir = path + "/thisdir/"
os.mkdir(newdir)

fname = newdir + "i_am_a_file.txt"
fout = open(fname, "w")
text = "\n\n\nHELLOW PYTHON!!!\n\n\n"
fout.write(text)
fout.close()
