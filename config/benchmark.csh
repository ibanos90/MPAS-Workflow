#!/bin/csh -f

#Note: need to add external procedure to archive last week's experiment to some directory
#      that stays constant every week, e.g.,
# BenchmarkExpDir could be set in a separate config file generated by the cron job, then that config
# file gets sourced in config/filestructure.csh and used by the archiving program.  For now, here is an example:
set BenchmarkExpDir = /glade/scratch/${USER}/pandac/${USER}_3denvar_OIE120km
