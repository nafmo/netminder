Netminder
=========

A small script to be notified about changes in web pages.

Configuration
-------------

Edit the `Settings` section of `netmind.sh`. Set `DIRECTORY` to point at the
directory in which you place the `netmind.urls` file.

Populate `netmind.urls` with the list of web pages to monitor on the form

    key=url

To post-edit the output of lynx, create a file on the name key.sed with
a script that can be called from sed. For example:

    echo '/Comments:/,$ d' > key.sed

The file netmind.config should contain your e-mail address

    echo me@example.com > netmind.config

Now call netmind.sh once to set up the initial files, and then set up
(for instance) a daily run through cron.

Requires: lynx, GNU sed, GNU date, GNU diff, sendmail (or compatible)
