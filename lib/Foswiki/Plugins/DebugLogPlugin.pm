# Plugin for Foswiki Collaboration Platform, http://foswiki.org/
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html

=pod

---+ package Foswiki::Plugins::DebugLogPlugin

To interact with Foswiki use ONLY the official API functions
in the Foswiki::Func module. Do not reference any functions or
variables elsewhere in Foswiki, as these are subject to change
without prior warning, and your plugin may suddenly stop
working.

For increased performance, all handlers except initPlugin are
disabled below. *To enable a handler* remove the leading DISABLE_ from
the function name. For efficiency and clarity, you should comment out or
delete the whole of handlers you don't use before you release your
plugin.

__NOTE:__ When developing a plugin it is important to remember that
Foswiki is tolerant of plugins that do not compile. In this case,
the failure will be silent but the plugin will not be available.
See %SYSTEMWEB%.InstalledPlugins#FAILEDPLUGINS for error messages.

__NOTE:__ Defining deprecated handlers will cause the handlers to be 
listed in %SYSTEMWEBWEB%.InstalledPlugins#FAILEDPLUGINS. See
%SYSTEMWEB%.InstalledPlugins#Handlig_deprecated_functions
for information on regarding deprecated handlers that are defined for
compatibility with older Foswiki versions.

__NOTE:__ When writing handlers, keep in mind that these may be invoked
on included topics. For example, if a plugin generates links to the current
topic, these need to be generated before the afterCommonTagsHandler is run,
as at that point in the rendering loop we have lost the information that we
the text had been included from another topic.

=cut


package Foswiki::Plugins::DebugLogPlugin;

# Always use strict to enforce variable scoping
use strict;

require Foswiki::Func;    # The plugins API
require Foswiki::Plugins; # For the API version

# $VERSION is referred to by Foswiki, and is the only global variable that
# *must* exist in this package.
use vars qw( $VERSION $RELEASE $SHORTDESCRIPTION $debug $pluginName $NO_PREFS_IN_TOPIC
            $Current_topic $Current_web $Current_user $installWeb);

# This should always be $Rev: 0 (17 Jan 2008) $ so that Foswiki can determine the checked-in
# status of the plugin. It is used by the build automation tools, so
# you should leave it alone.
$VERSION = '$Rev: 0 (17 Jan 2008) $';

# This is a free-form string you can use to "name" your own plugin version.
# It is *not* used by the build automation tools, but is reported as part
# of the version number in PLUGINDESCRIPTIONS.
$RELEASE = 'TWiki-4.2';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
$SHORTDESCRIPTION = 'Detailed Debug logging for Foswiki';

# You must set $NO_PREFS_IN_TOPIC to 0 if you want your plugin to use preferences
# stored in the plugin topic. This default is required for compatibility with
# older plugins, but imposes a significant performance penalty, and
# is not recommended. Instead, use $Foswiki::cfg entries set in LocalSite.cfg, or
# if you want the users to be able to change settings, then use standard Foswiki
# preferences that can be defined in your Main.SitePreferences and overridden
# at the web and topic level.
$NO_PREFS_IN_TOPIC = 1;

# Name of this Plugin, only used in this module
$pluginName = 'DebugLogPlugin';

=pod

---++ initPlugin($topic, $web, $user, $installWeb) -> $boolean
   * =$topic= - the name of the topic in the current CGI query
   * =$web= - the name of the web in the current CGI query
   * =$user= - the login name of the user
   * =$installWeb= - the name of the web the plugin is installed in

REQUIRED

Called to initialise the plugin. If everything is OK, should return
a non-zero value. On non-fatal failure, should write a message
using Foswiki::Func::writeWarning and return 0. In this case
%FAILEDPLUGINS% will indicate which plugins failed.

In the case of a catastrophic failure that will prevent the whole
installation from working safely, this handler may use 'die', which
will be trapped and reported in the browser.

You may also call =Foswiki::Func::registerTagHandler= here to register
a function to handle variables that have standard Foswiki syntax - for example,
=%MYTAG{"my param" myarg="My Arg"}%. You can also override internal
Foswiki variable handling functions this way, though this practice is unsupported
and highly dangerous!

__Note:__ Please align variables names with the Plugin name, e.g. if 
your Plugin is called FooBarPlugin, name variables FOOBAR and/or 
FOOBARSOMETHING. This avoids namespace issues.


=cut

sub initPlugin {
    ( $Current_topic, $Current_web, $Current_user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if( $Foswiki::Plugins::VERSION < 1.026 ) {
        Foswiki::Func::writeWarning( "Version mismatch between $pluginName and Plugins.pm" );
        return 0;
    }

    # Example code of how to get a preference value, register a variable handler
    # and register a RESTHandler. (remove code you do not need)
    
    writePOST() if (Foswiki::Func::getCgiQuery()->request_method() eq 'POST');
    

    # Set plugin preferences in LocalSite.cfg, like this:
    # $Foswiki::cfg{Plugins}{DebugLogPlugin}{ExampleSetting} = 1;
    # Always provide a default in case the setting is not defined in
    # LocalSite.cfg. See %SYSTEMWEB%.InstalledPlugins for help in adding your plugin
    # configuration to the =configure= interface.
    my $setting = $Foswiki::cfg{Plugins}{DebugLogPlugin}{ExampleSetting} || 0;
    $debug = $Foswiki::cfg{Plugins}{DebugLogPlugin}{Debug} || 0;

    # register the _EXAMPLETAG function to handle %EXAMPLETAG{...}%
    # This will be called whenever %EXAMPLETAG% or %EXAMPLETAG{...}% is
    # seen in the topic text.
    #Foswiki::Func::registerTagHandler( 'EXAMPLETAG', \&_EXAMPLETAG );

    # Allow a sub to be called from the REST interface 
    # using the provided alias
    #Foswiki::Func::registerRESTHandler('example', \&restExample);

    # Plugin correctly initialized
    return 1;
}

sub writePOST {
    my $text = '';
    #totally non-blocking tick - one file per foswiki op - will scale up to the point where there are too many
    #requests for the FS to deal with
    my $dir = Foswiki::Func::getWorkArea(${pluginName});
    my $script = Foswiki::Func::getCgiQuery()->action();
    #TODO: use Foswiki session id's if available
    my $session = Foswiki::Func::getCgiQuery()->remote_addr();
    $session =~ /^(.*)$/;      #i really don't know why CGI does not intaint this one
    $session = $1;

    my $file = join('-', ('POST', $script,
                          $Current_web.'.'.$Current_topic, $Current_user, $session,
                          Foswiki::Func::formatTime(time(), '$ye:$mo:$day:$hours:$minutes:$seconds', 'gmtime'), rand()
                          ));
    my $tickfile = $dir.'/'.$file;

    Foswiki::Func::writeDebug( "$tickfile" ) if $debug;

    $tickfile =~ /^(.*)$/;      #TODO: need to remove this and untaint at the right source
    $tickfile = $1;

    open( TICK, '>', $tickfile) or warn "$!";
    #print TICK $text;       #a nothing :)
    Foswiki::Func::getCgiQuery()->save(\*TICK);   #save the CGI query params
    close( TICK );
}

sub writeTEXT {
    my $text = shift;
    #totally non-blocking tick - one file per foswiki op - will scale up to the point where there are too many
    #requests for the FS to deal with
    my $dir = Foswiki::Func::getWorkArea(${pluginName});
    my $script = Foswiki::Func::getCgiQuery()->action();
    #TODO: use Foswiki session id's if available
    my $session = Foswiki::Func::getCgiQuery()->remote_addr();
    $session =~ /^(.*)$/;      #i really don't know why CGI does not intaint this one
    $session = $1;

    my $file = join('-', ('topic', $script,
                          $Current_web.'.'.$Current_topic, $Current_user, $session,
                          Foswiki::Func::formatTime(time(), '$ye:$mo:$day:$hours:$minutes:$seconds', 'gmtime'), rand()
                          ));
    my $tickfile = '>'.$dir.'/'.$file;

    Foswiki::Func::writeDebug( "$tickfile" ) if $debug;

    $tickfile =~ /^(.*)$/;      #TODO: need to remove this and untaint at the right source
    $tickfile = $1;

    open( TICK, $tickfile);
    Foswiki::Func::getCgiQuery()->save(\*TICK);   #save the CGI query params
    print TICK "\n==============\n";
    print TICK $text;       #a nothing :)
    close( TICK );
}

# The function used to handle the %EXAMPLETAG{...}% variable
# You would have one of these for each variable you want to process.
sub _EXAMPLETAG {
    my($session, $params, $theTopic, $theWeb) = @_;
    # $session  - a reference to the Foswiki session object (if you don't know
    #             what this is, just ignore it)
    # $params=  - a reference to a Foswiki::Attrs object containing parameters.
    #             This can be used as a simple hash that maps parameter names
    #             to values, with _DEFAULT being the name for the default
    #             parameter.
    # $theTopic - name of the topic in the query
    # $theWeb   - name of the web in the query
    # Return: the result of processing the variable

    # For example, %EXAMPLETAG{'hamburger' sideorder="onions"}%
    # $params->{_DEFAULT} will be 'hamburger'
    # $params->{sideorder} will be 'onions'
}

=pod

---++ mergeHandler( $diff, $old, $new, \%info ) -> $text
Try to resolve a difference encountered during merge. The =differences= 
array is an array of hash references, where each hash contains the 
following fields:
   * =$diff= => one of the characters '+', '-', 'c' or ' '.
      * '+' - =new= contains text inserted in the new version
      * '-' - =old= contains text deleted from the old version
      * 'c' - =old= contains text from the old version, and =new= text
        from the version being saved
      * ' ' - =new= contains text common to both versions, or the change
        only involved whitespace
   * =$old= => text from version currently saved
   * =$new= => text from version being saved
   * =\%info= is a reference to the form field description { name, title,
     type, size, value, tooltip, attributes, referenced }. It must _not_
     be wrtten to. This parameter will be undef when merging the body
     text of the topic.

Plugins should try to resolve differences and return the merged text. 
For example, a radio button field where we have 
={ diff=>'c', old=>'Leafy', new=>'Barky' }= might be resolved as 
='Treelike'=. If the plugin cannot resolve a difference it should return 
undef.

The merge handler will be called several times during a save; once for 
each difference that needs resolution.

If any merges are left unresolved after all plugins have been given a 
chance to intercede, the following algorithm is used to decide how to 
merge the data:
   1 =new= is taken for all =radio=, =checkbox= and =select= fields to 
     resolve 'c' conflicts
   1 '+' and '-' text is always included in the the body text and text
     fields
   1 =&lt;del>conflict&lt;/del> &lt;ins>markers&lt;/ins>= are used to 
     mark 'c' merges in text fields

The merge handler is called whenever a topic is saved, and a merge is 
required to resolve concurrent edits on a topic.

*Since:* Foswiki::Plugins::VERSION = 1.1

=cut

sub mergeHandler {
    #my ($diff, $old, $new, $infoRef) = @_;
    use Data::Dumper;

    writeTEXT(Dumper(@_));
}

=pod

---++ restExample($session) -> $text

This is an example of a sub to be called by the =rest= script. The parameter is:
   * =$session= - The Foswiki object associated to this session.

Additional parameters can be recovered via de query object in the $session.

For more information, check Foswiki:System.Scripts#rest

*Since:* Foswiki::Plugins::VERSION 1.1

=cut

sub restExample {
   #my ($session) = @_;
   return "This is an example of a REST invocation\n\n";
}

1;
