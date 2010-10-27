# ---+ Extensions
# ---++ DebugLogPlugin
# ---+++ Request Logging
# **BOOLEAN**
# log HTTP POST
$Foswiki::cfg{DebugLogPlugin}{LogPOST} = 1; 
# **BOOLEAN**
# log HTTP GET
$Foswiki::cfg{DebugLogPlugin}{LogPOST} = 0; 
# **BOOLEAN**
# Monitor request Timing
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
$Foswiki::cfg{DebugLogPlugin}{MonitorMacros} = 0;
# **BOOLEAN**
# Monitor the SEARCH macro
$Foswiki::cfg{DebugLogPlugin}{Monitor}{SEARCH} = 1;