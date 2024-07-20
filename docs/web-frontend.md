# The Web Frontend

Faaso Comes with a web-based frontend for simple
administrative tasks. While not necessary, it can
be handy.

Once you have [configured your FaaSO server](server-setup.html) you can access it by visiting the URL of your server in a web browser.

The default username is `admin` and the password is the one you configured yourself.

The web frontend is a simple interface that allows you to:

* Start/Stop funkos
* See their status, whether they are up to date or stale
* If they are healthy or not
* See logs
* Access a terminal session
* Add, remove and edit secrets

I am most definitely not a frontender, so the bar was set at "not worse than a router's admin page". I think I managed to clear that bar.

Here are some screenshots:

{{% figure faaso1 src="faaso1.png" caption="The funkos admin page" %}}
{{% figure faaso2 src="faaso2.png" caption="The secrets admin page" %}}
{{% figure faaso3 src="faaso3.png" caption="The secret editing dialog" %}}
