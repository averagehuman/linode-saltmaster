
linode-saltmaster
=================

Scripted deployment of a `saltstack`_ master node on `linode`_ via `vagrant`_
and `ansible`_.

Also installs `jenkins`_ on the same box.


Quickstart
----------

Get a linode api key and create a file called .linode like the following
example::


    LINODE_API_KEY := <your api key>
    LINODE_SSH_USER := $(USER)
    LINODE_SSH_KEY_LOCATION := ~/.ssh/id_rsa
    ANSIBLE_SSH_PORT := 1234

(This is makefile syntax).

Then run::

    $ make deploy

If that succeeded you should be able to ssh to the new linode machine::

    $ make ssh

Keep this ssh session open and in another terminal run::

    $ make provision-saltmaster

which will invoke ansible to complete the installation.


