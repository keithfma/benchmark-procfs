# Profile R functions by reading select entries from Linux /proc/self files

#	Returns a named list with the contents of /proc/self/io, all of which are of
#	interest. Names for the elements of this list come directly from the data
#	(rchar, wchar, syscr, syscw, read_bytes, write_bytes, cancelled_write_bytes).
#	See http://man7.org/linux/man-pages/man5/proc.5.html for details.
read_io <- function() {
	df = read.table('/proc/self/io', sep = ':', stringsAsFactors = FALSE)
	out <- setNames(as.list(df$V2), df$V1)
}

