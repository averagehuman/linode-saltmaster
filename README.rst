
linode-saltmaster
=================

Remote deploy a `saltstack`_ master together with `jenkins`_ on `linode`_.

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

    $ make init

This will create the box and run an initial shell script to set the hostname and update
the sshd config (including changing the default ssh port).

If that succeeded you should now be able to ssh to the new linode machine::

    $ make ssh

Keep this ssh session open in case any problems come up.

Now in another terminal run::

    $ make provision

which will invoke `ansible`_ to complete the installation.


.. _saltstack: https://saltstack.com/
.. _jenkins: https://jenkins.io/
.. _linode: https://www.linode.com/
.. _ansible: https://www.ansible.com/

