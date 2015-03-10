# Profile R functions by reading select entries from Linux /proc/self files

#	Returns a named vector with the contents of /proc/self/io, all of which are of
#	interest. Names come directly from the data
#	(rchar, wchar, syscr, syscw, read_bytes, write_bytes, cancelled_write_bytes).
#	See http://man7.org/linux/man-pages/man5/proc.5.html for details.
read_io <- function() {
	raw <- read.table(file = '/proc/self/io', sep = ':', stringsAsFactors = FALSE)
	data <- as.double(raw$V2)
	names(data) <- raw$V1
	data
}


#	Returns a named vector with the contents of /proc/self/statm, all of which are of
#	interest. Names are not present in the data file, but rather are defined in
#	the documentation for procfs (size, resident, share, text, lib, data, dt) See
#	http://man7.org/linux/man-pages/man5/proc.5.html for details.
read_statm <- function() {
	data <- scan(file = '/proc/self/statm', what = double(), quiet = TRUE)
	names(data) <- c('size', 'resident', 'share', 'text', 'lib', 'data','dt')
	data
}


#	Returns a named vector with select values from /proc/self/stat. Names are not
#	present in the data file, but rather are defined in the documentation for
#	procfs (minflt, cminflt, majflt, cmajflt, utime, stime, cutime cstime) See
#	http://man7.org/linux/man-pages/man5/proc.5.html for details. System times are
#	converted from "clock ticks" to seconds using a conversion factor from the
#	Bash command "getconf".
read_stat <- function() {
	sc_clk_tck = as.double(system("getconf CLK_TCK", intern=TRUE))
	data <- vector(mode = 'double', length = 8)
	names(data) <- c('minflt', 'cminflt', 'majflt', 'cmajflt', 'utime', 'stime',
	                'cutime', 'cstime')
	raw <- scan(file = '/proc/self/stat', what = 'string', quiet = TRUE)
	data['minflt'] <- as.double(raw[9]) 
	data['cminflt'] <- as.double(raw[10]) 
	data['majflt'] <- as.double(raw[11])  
	data['cmajflt'] <- as.double(raw[12])  
	data['utime'] <- as.double(raw[13])/sc_clk_tck 
	data['stime'] <-  as.double(raw[14])/sc_clk_tck 
	data['cutime'] <-  as.double(raw[15])/sc_clk_tck 
	data['cstime'] <-  as.double(raw[16])/sc_clk_tck 
	data
}


#	Benchmark an R function using changes in data read from /proc/self.
#	Input arguments are the function object (func) and a variable number of
#	arguments (...). Output is returned as named list with entries:
#	't_wall' = total elapsed time, includes t_cpu and waiting time
#	't_cpu' = total processor time (sec)*
#	't_cpu_usr' = time scheduled in user mode (sec)*
#	't_cpu_sys' = time scehduled in kernel mode (sec)*
#	'f_min' = number of minor page faults (1)*
#	'f_maj' = number of major page faults (1)*
#	'w_all' = total written (bytes)**
#	'w_dsk' = total written to disk (bytes)***
#	'w_ncall' = number of read system calls (1)*
#	'r_all' = total read (bytes)**
#	'r_dsk' = total read from (bytes)***
#	'r_ncall' = number of read system calls (1)*
#
#	* = including threads and children
#	** = total from system calls, does not acount for caching
#	*** = attempts to count bytes actually written/read to/from disk
benchmark <- function(func, ...) {

	# collect initial data, run function, collect final data
	stat_i <- read_stat()
	time_i <- Sys.time()
	io_i <- read_io()
	func(...)
	io_f <- read_io()
	time_f <- Sys.time()
	stat_f <- read_stat()

	# reduce data
	out <- vector(mode = "double", length = 12)
	names(out) <- c('t_wall','t_cpu', 't_cpu_usr', 't_cpu_sys', 'f_min', 'f_maj',
	                 'w_all', 'w_dsk', 'w_ncall', 'r_all', 'r_dsk', 'r_ncall')
	out['t_wall'] <- as.double(time_f-time_i)
	out['t_cpu_usr'] <- (stat_f['utime']-stat_i['utime'])+(stat_f['cutime']-stat_i['cutime']) 
	out['t_cpu_sys'] <- (stat_f['stime']-stat_i['stime'])+(stat_f['cstime']-stat_i['cstime'])  
	out['t_cpu'] <- out['t_cpu_usr']+out['t_cpu_sys'] 
	out['f_min'] <- (stat_f['minflt']-stat_i['minflt'])+(stat_f['cminflt']-stat_i['cminflt'])
	out['f_maj'] <- (stat_f['majflt']-stat_i['majflt'])+(stat_f['cmajflt']-stat_i['cmajflt'])
	out['w_all'] <- io_f['wchar']-io_i['wchar']
	out['w_dsk'] <- io_f['write_bytes']-io_f['write_bytes']
	out['w_ncall'] <- io_f['syscw']-io_i['syscw']
	out['r_all'] <- io_f['rchar']-io_i['rchar']
	out['r_dsk'] <- io_f['read_bytes']-io_f['read_bytes']
	out['r_ncall'] <- io_f['syscr']-io_i['syscr']
	out
}
