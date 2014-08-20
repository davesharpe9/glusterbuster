i# Candidate Challenge VM

First create a params.conf. An example is provided in the source.

At a minimum you need AWS keys as follows:
```
AWS_ACCESS_KEY_ID=AKIDSAFASDFASDFADF
AWS_SECRET_ACCESS_KEY=dasfdjasfadsjflhuoiewurjnzcvxfdafadfsfw
```
First you need to run `bootstrap.sh`. You can either define everything, or you can pass variables on the command line:

```
./bootstrap.sh -s aws_ssh_key_name -p path_to_ssh_key -i a_unique_short_string -r region -n subnet_id
```
If a region is not specified, ap-southeast-2 is the default.

Once bootstrap.sh has been run, you can the run `setup.sh`.

This will use the vagrantfile and run the shell and puppet provisioners to setup the machines ready for use.

Once you have collected everything you want from the candidate and proxy vm, e.g. history, log files, and the captureX.log files from `/home/ubuntu` on the proxy instance, you can now run `cleanup.sh`.

Good luck.
