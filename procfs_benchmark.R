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



