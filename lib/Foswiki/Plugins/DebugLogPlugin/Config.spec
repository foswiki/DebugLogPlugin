# ---+ Extensions
# ---++ DebugLogPlugin
# ---+++ Request Logging
# **BOOLEAN**
# log HTTP POST
$Foswiki::cfg{DebugLogPlugin}{LogPOST} = 0; 
# **BOOLEAN**
# log HTTP GET
$Foswiki::cfg{DebugLogPlugin}{LogGET} = 0; 
# **BOOLEAN**
# Monitor Merge request Timing
$Foswiki::cfg{DebugLogPlugin}{LogMerge} = 0; 

# ---+++ Performance Logging
# **BOOLEAN**
# Monitor request Timing
$Foswiki::cfg{DebugLogPlugin}{RequestTimes} = 0; 
# ---++++ Specific Macro Monitoring
# **BOOLEAN**
# turn on monitoring of specific MACRO expansions
# to specify a macro to be monitored, you need to add cfg items as per the SEARCH example below.
# __Note__ for now it only works with Foswiki::Macro:: perl modules
# the value you set for each module indicates the amount of information logged (additive, each successive step logs in addition to the previous)
#    * 1=timing and memory usage
#    * 2=output string 
$Foswiki::cfg{DebugLogPlugin}{MonitorMacros} = 0;
# **NUMBER**
# Monitor the SEARCH macro
$Foswiki::cfg{DebugLogPlugin}{Monitor}{SEARCH} = 1;