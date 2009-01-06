About
=====

Ted Gould's post about [transcoding music files using Make][1] got me thinking
about combining Make and [RecordStream][3] into a barebones [MapReduce][2]
framework.  As a demonstration, I wrote a partial solution to Tim Bray's [Wide
Finder][6] challenge, to calculate hit counts from web server logs.

RecordStream (also known as "recs") is a collection of Unix tools for
producing and processing files full of [JSON][4] objects.  It was developed by
my friends Ben Bernard and Keith Amling.  Since RecordStream files contain one
object per line, the recs tools are easy to script in combination with
traditional Unix tools like `head` and `grep`.

> *Aside: Unfortunately, the version of RecordStream on Google Code is very
> old, and in particular does not have much in the way of usage or
> installation instructions.  Hopefully Ben and Keith can get approval to
> publish the many, many, many improvements they and others have made since
> they started working at Amazon.com.*

I think of Make as a functional programming environment for shell scripting.
It's simple to write a Makefile where each rule's output depends only on the
specified input files.  Since all dependencies between rules are declared in
the Makefile, we get some nice features for free:

1. The entire process can be parallelized (using `make -j`) with no explicit
   instructions from the programmer.  Running `make -j 2` on my dual-core
   workstation resulted in a 1.75&times; speed-up for this program.
2. By saving intermediate files, we can do incremental MapReduce updates
   ([like CouchDB][5]).  Just add or remove log files from the data directory
   and re-run `make`.  The new files will be analyzed, then combined with
   cached results from any already-processed files.  If you had a huge
   collection of files, you could cache multiple levels of aggregate results
   (e.g. weekly, monthly, daily) to make incremental updates even more
   efficient.
3. Saving intermediate files also prevents other types of duplicate work.  For
   example, the first step in my Wide Finder program converts the logs to into
   RecordStream's JSON format.  This is more work than necessary for the Wide
   Finder problem alone, but in the real world you could then reuse the
   results to do other calculations.
4. You can kill the process at any point and later restart it near where it
   stopped&mdash;or even migrate it to another machine.

Here's my [source code][7]: 16 line of code, not counting comments or blank
lines.  It's not as fast as any of the heavily-optimized versions, but it
demonstrates a practical way to do parallel data processing with very little
effort.

Instructions
============

1. Check out [RecordStream][8].  Add the commands in the `bin` directory to
   your `$PATH`, and copy the contents of the lib directory into your Perl
   include path (e.g. `/usr/local/lib/site_perl`).
2. Clone this git repository: `git clone git://github.com/mbrubeck/wf-recs.git`
3. Run `make` inside your cloned repository.  Use `make -j 4` to run four
   concurrent jobs.  (Adjust for the number of processor cores in your
   machine.)

Exercise for the reader:  Integrate this with a distributed Make program, to
make it run across multiple computers on a network.

Notes
=====

The sample data in the `data` directory are the 10,000-line
<http://www.tbray.org/tmp/o10k.ap>, split into ten files.  I wimped out and
did not include file-splitting in the code itself.

Eric Wong's [Wide Finder 2 entry][9] also used Make, although his
code is currently unavailable.



[1]: http://gould.cx/ted/blog/Where_music_is_going
[2]: http://en.wikipedia.org/wiki/MapReduce
[3]: http://code.google.com/p/recordstream/
[4]: http://json.org/
[5]: http://horicky.blogspot.com/2008/10/couchdb-implementation.html
[6]: http://www.tbray.org/ongoing/When/200x/2007/09/20/Wide-Finder
[7]: Makefile
[8]: http://code.google.com/p/recordstream/source/checkout
[9]: http://groups.google.com/group/wide-finder/browse_thread/thread/10b3cc5d3d10e384/fcb8c1ce2f5ef480
