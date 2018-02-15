# -*- coding: utf-8 -*-
"""
Created on Thu Feb 15 12:43:54 2018

@author: tc02
"""

template = ["matlabbatch{3}.spm.stats.con.consess{", "}.tcon.name = " , "; \n matlabbatch{3}.spm.stats.con.consess{" , "}.tcon.weights = [", "]; \n matlabbatch{3}.spm.stats.con.consess{", "}.tcon.sessrep = 'replsc';"]

for i in range(98):
    print(template[0] + str(i+10) + template[1] + "'Condition " + str(i+1) + "'" + template[2] + str(i+10) + template[3] +  "0 "*i + "1 " + "0 " *(103-i) + template[4] + str(i+10) + template[5])
    