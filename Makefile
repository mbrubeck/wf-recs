# Minimal regular expression for parsing Apache log files:
LOG_FIELDS=host,logname,user,timestamp,method,path,protocol,status,bytes,referer,useragent
LOG_PATTERN='(.*) (.*) (.*) \[(.*)\] "(.*) (.*) (.*)" (.*) (.*) "(.*)" "(.*)"'

INPUT_FILES=$(wildcard data/*.log)

all: data/hit-count-totals.recs
clean:
	rm -f data/*.recs

# Parse: Convert an Apache access log into a JSON record stream.
%.log.recs: %.log
	recs-fromre --field $(LOG_FIELDS) $(LOG_PATTERN) < $< > $@

# Map/filter: Select only matching GET for individual weblog posts.
%.matches.recs: %.log.recs
	recs-grep '$$r->{method} eq "GET" && $$r->{path} =~ m|^/ongoing/When/\d\d\dx/(\d\d\d\d/\d\d/\d\d/[^ .]+)$$|' < $< > $@

# Partial reduce: Count the requests per path from a single log file.
%.hit-counts.recs: %.matches.recs
	  recs-collate --key path --aggregator count --perfect < $< > $@

# Final reduce: Add up the hit counts for all the log files.
data/hit-count-totals.recs: $(INPUT_FILES:.log=.hit-counts.recs)
	cat $^ | recs-collate --key path --aggregator sum,count --perfect \
	       | recs-sort --key sum_count=-n > $@

# Tell Make to cache intermediate files.
.SECONDARY:
