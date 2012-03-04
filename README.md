Inventory Tracker
==============

A quick and dirty Sinatra app for tracking inventory consumption. This is a fork from [Coffee Tracker](http://github.com/pgaspar/Coffee-Tracker "Coffee Tracker") and came to be when we noticed we needed to track other stuff appart from coffee. Tea and sandwiches, for instances.

We're using it at [Connect Coimbra](http://connectcoimbra.com/ "Connect Coimbra") with about 10 people.

![Screenshot (not up to date!)](http://dl.dropbox.com/u/562461/hot-linking/coffee_tracker_github.png "Front Page screen")

Features
--------

* Users and Products managed on an admin section
* Each record is stored with a timestamp, the product type and the price at time of consumption
* Overall stats displayed on the main page
* Easily filter by month (not in the interface at the moment)
* Extremely simple interface / idea

Issues
------

The first version was stitched up in about 4 hours with KISS in mind, so there's a lot of room for improvement!

### Main issues ###

* The login is cookie based but requires no password (the user selects himself from the list of users) - this doesn't scale and has privacy issues
* The views are tightly coupled with our needs and are generally awful (I swear that inline css was already there!)
* Site's copy currently in Portuguese

Powered by
----------

* [Sinatra](http://sinatrarb.com/ "Sinatra")
* [Data Mapper](http://datamapper.org/ "Data Mapper")
* [Twitter Bootstrap](http://twitter.github.com/bootstrap "Twitter Bootstrap")
* The nice people at [Connect Coimbra](http://connectcoimbra.com/ "Connect Coimbra") :)