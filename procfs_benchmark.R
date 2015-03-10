# Profile R functions by reading select entries from Linux /proc/self files

#	Returns a named list with the contents of /proc/self/io, all of which are of
#	interest. Names come directly from the data
#	(rchar, wchar, syscr, syscw, read_bytes, write_bytes, cancelled_write_bytes).
#	See http://man7.org/linux/man-pages/man5/proc.5.html for details.
read_io <- function() {
	data = read.table(file = '/proc/self/io', sep = ':', stringsAsFactors = FALSE)
	out <- setNames(as.list(data$V2), data$V1)
}


#	Returns a named list with the contents of /proc/self/statm, all of which are of
#	interest. Names are not present in the data file, but rather are defined in
#	the documentation for procfs (size, resident, share, text, lib, data, dt) See
#	http://man7.org/linux/man-pages/man5/proc.5.html for details.
read_statm <- function() {
	data <- scan(file = '/proc/self/statm', what = integer(), quiet = TRUE)
	out <- setNames(as.list(data), 
	                c('size', 'resident', 'share', 'text', 'lib', 'data','dt'))
}


#	Returns a named list with select values from /proc/self/stat. Names are not
#	present in the data file, but rather are defined in the documentation for
#	procfs (minflt, cminflt, majflt, cmajflt, utime, stime, cutime cstime) See
#	http://man7.org/linux/man-pages/man5/proc.5.html for details. System times are
#	converted from "clock ticks" to seconds using a conversion factor from the
#	Bash command "getconf".
read_stat <- function() {
	sc_clk_tck = as.double(system("getconf CLK_TCK", intern=TRUE))
	out <- vector(mode = 'list', length = 8)
	names(out) <- c('minflt', 'cminflt', 'majflt', 'cmajflt', 'utime', 'stime',
	                'cutime', 'cstime')
	data <- scan(file = '/proc/self/stat', what = 'string', quiet = TRUE)
	out[['minflt']] <- as.integer(data[9]) 
	out[['cminflt']] <- as.integer(data[10]) 
	out[['majflt']] <- as.integer(data[11])  
	out[['cmajflt']] <- as.integer(data[12])  
	out[['utime']] <- as.double(data[13])/sc_clk_tck 
	out[['stime']] <-  as.double(data[14])/sc_clk_tck 
	out[['cutime']] <-  as.double(data[15])/sc_clk_tck 
	out[['cstime']] <-  as.double(data[16])/sc_clk_tck 
	out
}

