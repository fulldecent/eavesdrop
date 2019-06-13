# Eavesdrop

*Listen in on your network*

Originally written by Eric Baur, now maintained by William Entriken. Licensed under GPL, version 2.

**Eavesdrop** is an application for listening in on TCP conversations on the network your computer is attached to.  It can also open up tcpdump / Ethereal capture files for analysis.

## Quick start

For most users with a single network connection (ie: only ethernet or airport active, not both), you can simply start up the application and click "Start Capture" (you will be asked to authenticate).  The application will start to list any TCP conversations it sees on the network.

## Licensing

Tiis application is licensed under the GPL, version 2.

## Acknowledgments

I would like to thank Jean-Edouard Babin for his code contributions.  He added support for PNG graphics and fixed a display bug in the ASCII / HEX view.  I would also like to thank Snowmint Creative solutions (http://developer.snowmintcs.com) for their excellent graphing classes for Cocoa.  The graphing features look a lot better than they would have under my design alone.  The code related to graphing is not covered under the GPL and is not public domain, please see their web site for details on their open source license.

## Requirements

* macOS 10.10 or greater
* Administrative rights (for live captures)
* Network connection (ethernet/airport) or tcpdump capture files

## Features

* TCP conversation tracking
* Show last TCP flags sent and flag history
* `tcpdump` filter syntax
* Live syntax checking
* Payload reconstruction — display in ASCII or HEX
* Read tcpdump files
* Remove or hide idle conversations to save memory or simplify the interface
* Display images contained in the capture
* Search for an IP or payload contents
* Graphing of conversation meta-data (can also export data)

## Known Issues

* Packet info can be edited in conversation window
* No image details
* Missing statistics
* "CaptureTool" process can get zombied when app crashes or window is closed during a capture
* A capture file can be processed by re-running the capture, this results in duplicated information
* No ability to save

## v0.5a4

Compiled as a Universal Binary.  Promiscuous mode and file capture both work.  Added a button to save images to TIFF (thanks, Will!).  Removed the "Save" and "Save As..." menu options.  Although this does not address the underlying issue, it will reduce questions until the next major release, which should fix that.

## v0.5a3u

Compiled as a Universal Binary.  Limited release only (to specific testers).

## v0.5a3

Fixed promiscuous mode.

## v0.5a2

Added more graphing options.  Not released publically.

## v0.5a1

Added graphing capabilities.  Moved around a lot of the user interface to (hopefully) be a little less cluttered.  There are a lot more sub-sections now, but I think it layed out more logically.

I had started to add some HTML support, but it was so far from complete that I took the interfaces for it back out.  The graphing support was more important to me (in order to use this for analysis of data) and so it got worked on first.

CPU performance used to go through the roof when running a capture and then remain high after the capture was stopped.  Now, the CPU is still busy during (although not as much) and goes back to normal afterwards.  On a related note, this version will not leave around orphaned or zombied processes under normal usage (although I have seen issues when a capture is not stopped before closing a window).

This is considered an alpha release because the graphs are implemented in an inconsistant mannor and the statistics are not in place yet.

## v0.4b3

Major change in this version was getting authentication working properly.  While working on this, I've split the app into separate display and capture applications.  This should help some with performance as well.  Some other minor bugs and irritations have been solved as well.

## v0.4b1

First public release.  Major features are complete with some remaining issues and interface elements that don't do anything.  This is a major reworking from the previous version, which worked better (in some ways), but had performance issues and dropped packets.