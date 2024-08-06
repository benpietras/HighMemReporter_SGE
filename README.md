B. Pietras, UoM Research IT.

These scripts are intended to run on a HPC batch system managed by SGE, which has various high memory nodes.  
Access to the respective nodes is controlled by usersets. Each job array task is counted as a job.  
You will need to edit to provide your HPC usersets and node specifications.

--highmem_reporter.sh--

This provides a list of jobs that ran over the last X days (set in script)
ordered by user. The output is like below for the default of 7 days:

user1, last 7 days vbigmem:  
jobno    node     maxvmem    slots  mem_perc  recommended  
4425613  mem2000  1.185TB    32     0.037TB   mem1500  
4426545  mem2000  6.134GB    32     0.191GB   standard  
4426682  mem2000  5.276GB    32     0.164GB   standard  
4425619  mem1500  440.970GB  32     13.780GB  mem256  

user2, last 7 days vbigmem:  
jobno    node     maxvmem    slots  mem_perc  recommended  
4421110  mem2000  249.911GB  10     24.991GB  mem512  
4425262  mem2000  1.021GB    24     0.042GB   standard  
[etc]  

--highmem_analysis.sh--

This takes the output of highmem_reporter.sh and provides an overview,
listed by worst offender.

username  group     email                    jobno  
user5     hum01     user5@manchester.ac.uk   5537  
user8     pb01      user8@manchester.ac.uk   733  
user22    chem01    user22@manchester.ac.uk  59  

The script also sends an email of this info, with more detailed user info
attached as a zip.

--highmem_rep.sh--

A wrapper script to run both scripts, can be used with cron:

00 06 * * MON /PATH/highmem_rep.sh 2>&1

---

Notes

Hopefully this script is adaptable enough to be of use on other HPC systems.  
Any questions / suggestions - let me know: ~~ben.pietras@manchester.ac.uk~~ bpietras@liverpool.ac.uk

Cheers!
