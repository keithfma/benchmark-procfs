#!/usr/bin/env python

# Module. Profile Python functions by reading select entries from Linux
# /proc/self files

import os
import time

def read_io():
	'''read_io()
	Returns a dictionary with the contents of /proc/self/io, all of which are of
	interest. See http://man7.org/linux/man-pages/man5/proc.5.html'''
	
	# parse file, which is a list containing "key: value" on each line
	out = {}
	file = open('/proc/self/io', 'r')
	data = file.read()
	lines = data.split('\n')
	for line in lines:
		if line.strip(): # skip empty lines
			key_val = line.split(':')
			out[key_val[0]] = key_val[1]
	
	# convert types, all entries are integers
	for key in out:
		out[key] = int(out[key])

	return out


def read_statm():
	'''read_statm()
	Returns a dictionary with the contents of /proc/self/statm, all of which are of
	interest. See http://man7.org/linux/man-pages/man5/proc.5.html'''

	# parse file, which is a list of space separated values
	file = open('/proc/self/statm', 'r')
	data = file.read()
	val = data.split()
	
	# copy val to dict, supplying keys manually, recasting types, converting units	
	bytes_per_page = os.sysconf('SC_PAGESIZE') 
	out = {}
	out['size'] = int(val[0])*bytes_per_page
	out['resident'] = int(val[1])*bytes_per_page
	out['share'] = int(val[2])*bytes_per_page
	out['text'] = int(val[3])*bytes_per_page
	out['lib'] = int(val[4])*bytes_per_page
	out['data'] = int(val[5])*bytes_per_page
	out['dt'] = int(val[6])*bytes_per_page
	
	return out


def read_stat():
	'''read_stat()
	Returns a dictionary select values from /proc/self/stat. See
	http://man7.org/linux/man-pages/man5/proc.5.html'''

	# parse file, which is a list of space separated values
	file = open('/proc/self/stat', 'r')
	data = file.read()
	val = data.split()

	# fetch units for time measurements
	sc_clk_tck = os.sysconf('SC_CLK_TCK') # clock ticks / sec

	# copy val to dict, supplying keys manually and recasting types
	out = {}
	out['minflt'] = int(val[9])
	out['cminflt'] = int(val[10])
	out['majflt'] = int(val[11])
	out['cmajflt'] = int(val[12])
	out['utime'] = float(val[13])/float(sc_clk_tck) 
	out['stime'] = float(val[14])/float(sc_clk_tck) 
	out['cutime'] = float(val[15])/float(sc_clk_tck) 
	out['cstime'] = float(val[16])/float(sc_clk_tck) 

	return out


def benchmark(func, *args):
	'''benchmark(func, *args) 
	Benchmark a python function using changes in data read from /proc/self.
	Input arguments are the function object (func) and a variable number of
	arguments (*args). Output is returned as a dictionary with entries:
	't_wall' = total elapsed time, includes t_cpu and waiting time
	't_cpu' = total processor time (sec)*
	't_cpu_usr' = time scheduled in user mode (sec)*
	't_cpu_sys' = time scehduled in kernel mode (sec)*
	'f_min' = number of minor page faults (1)*
	'f_maj' = number of major page faults (1)*
	'w_all' = total written (bytes)**
	'w_dsk' = total written to disk (bytes)***
	'w_ncall' = number of read system calls (1)*
	'r_all' = total read (bytes)**
	'r_dsk' = total read from (bytes)***
	'r_ncall' = number of read system calls (1)*

	* = including threads and children
	** = total from system calls, does not acount for caching
	*** = attempts to count bytes actually written/read to/from disk
	'''

	out = {}

	# Collect initial data, run function, collect final data
	stat_i = read_stat()
	time_i = time.time()
	io_i = read_io()
	func(*args)
	io_f = read_io()
	time_f = time.time()
	stat_f = read_stat()

	# Reduce data
	out['t_wall'] = time_f-time_i                                                                     
	out['t_cpu_usr'] = (stat_f['utime']-stat_i['utime'])+(stat_f['cutime']-stat_i['cutime']) 
	out['t_cpu_sys'] = (stat_f['stime']-stat_i['stime'])+(stat_f['cstime']-stat_i['cstime'])  
	out['t_cpu'] = out['t_cpu_usr']+out['t_cpu_sys'] 
	out['f_min'] = (stat_f['minflt']-stat_i['minflt'])+(stat_f['cminflt']-stat_i['cminflt'])
	out['f_maj'] = (stat_f['majflt']-stat_i['majflt'])+(stat_f['cmajflt']-stat_i['cmajflt'])
	out['w_all'] = io_f['wchar']-io_i['wchar']
	out['w_dsk'] = io_f['write_bytes']-io_f['write_bytes']
	out['w_ncall'] = io_f['syscw']-io_i['syscw']
	out['r_all'] = io_f['rchar']-io_i['rchar']
	out['r_dsk'] = io_f['read_bytes']-io_f['read_bytes']
	out['r_ncall'] = io_f['syscr']-io_i['syscr']

	## DEBUG: print contents of out nicely
	#for key in sorted(out):
	#	print "%s: %s" % (key, out[key])

	return out


# Read and print data if run as script, useful as a sanity check
if __name__=='__main__':
	
	io_dict = read_io()
	print ''
	print 'io ----------'
	for key in io_dict:
		print '  ', key, io_dict[key]
	
	stat_dict = read_stat()
	print ''
	print 'stat ----------'
	for key in stat_dict:
		print '  ', key, stat_dict[key]
	
	statm_dict = read_statm()
	print ''
	print 'statm ----------'
	for key in statm_dict:
		print '  ', key, statm_dict[key]
	print ''

