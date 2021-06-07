# -*- coding: utf-8 -*-
import os
import re

class filetool :
    ''' This module builed for handle file easily. '''
    def __init__(self) :
        self.mdname = 'filetool.py'
        self.gitdir = '.git'
        self.svndir = '.svn'

    # 遍历目录，获得文件名列表，存入文件file_names.txt中
    def list_filenames(self, current_path = os.curdir, output_text_file = 'filenames.txt') :
        '''      This method list filenames in the directory specified by
            then parameter 'current_path'.

            Usage: filetool.list_filenames("~/aaa", output_text_file='filenames.txt')
        '''
        now_work_dir=current_path
        base = ''
        files = []
        nouse = []
        file_list = sum([[os.path.join(base,file) for file in files] for base,nouse,files in os.walk(now_work_dir)],[])


        rfile = open(now_work_dir + os.sep + output_text_file,'wb')
        for each_file in file_list:
            if re.search(output_text_file, each_file) \
            or re.search(self.mdname, each_file)   \
            or re.search(self.gitdir, each_file)   \
            or re.search(self.svndir, each_file) :
	        	continue
            else:
                print each_file.split(os.sep)[-1]
                rfile.write(each_file[2:] + os.linesep) 
                print ' === END === '
        rfile.close() 
