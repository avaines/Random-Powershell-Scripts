---
layout: post
title: "Many to one mailmerge | Manager mail merge"
downloadname: "Start-ManagerMailMerge"
downloadlink: "https://github.com/n3rden/Start-ManagerMailMerge"
author: "Aiden Vaines"
categories: powershell
tags: [powershell, script]
image:
  feature: psh-managermailmerge.jpg
---

Sometime it's nessessary to email an individual about multiple people. Sometimes, its nessessary to email loads of people about loads of people.

I needed a way to email managers about staff in their team who were recieving new equipment. As this was multiple people in multiple teams with multiple managers it was a bit out of the scope of what mailmerge is designed to handle.

I put something quick together to take away the manual necessities of such a task. This *finished* script uses my [powershell framework](http://vaines.org/powershell/pstemplate/Powershell-Framework.html) as a base.

The script takes a "source.csv" layed out like this:
|ID|Name|Device|ManagerID|ManagerName|ManagerEmail|
|--|---|----|-----|-----|----|
|1001|Joe Bloggs|iPhone 6|2001|A|A@domain.com|
|1002|Steve Jones|iPhone 5|2001|A|A@domain.com|
|1003|Dan Smith|iPhone 6|2002|B|b@domain.com|

For each unique manager in this list ("A" and "B") a new email will be created based on an html template "_template.htm". addressed to the manager and containing a formatted table with their staff.
<managermailmerge_1.PNG>

Using the table above, manager "A" will recieve and email about employees 1001 & 1002, and manager "B" about employee 1003. 

[Clone this project here](https://github.com/n3rden/Start-ManagerMailMerge)



# Setup

* Edit the *"_template.html*" file in MS Word (to retain the formatting)
* Edit/replace the *"sourcedata.csv"* file, retaining the headers
* Run the script
* All messages will sit in outlooks *"Draft"* folder untill ready to send


# To Do/Extension
1) Automatic sending
    The initial usecase for this script need it to be sent by outlook at a given time

2) More options!

3) Inline processing
    This wasn't required initially but it might be useful to be able to accept the sourcedata table/object via a pipe or argument
