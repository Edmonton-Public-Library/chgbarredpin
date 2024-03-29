# Project Notes

Initialized: Wed Nov 18 09:55:09 MST 2015.

Currently we have a nightly process that automatically changes the PIN on BARRED customer accounts to a random number. We would like to extend this process to **EPL_CANCEL, LOSTCARD,EPL_ADLTNR, EPL_CONCOR, EPL_GMU, EPL_JONLIN, EPL_JUV, EPL_JUV01,EPL_JUV05, EPL_JUV10, EPL_JUVIND, EPL_JUVNR, EPL_KINGS, EPL_METRO, EPL_METROJ, EPL_NORQ, EPL_SELF, EPL_TAL, EPL_TRESID, EPL_UAL, EPL_VISITR** customer accounts.

In addition to the above accounts, the script now also select any accounts that expired yesterday (or earlier) and changes their password to an eight (8) character password.

The criteria for expired account profiles are **EPL_CANCEL, LOSTCARD, EPL_ADLTNR, EPL_CONCOR, EPL_GMU, EPL_JONLIN, EPL_JUV, EPL_JUV01, EPL_JUV05, EPL_JUV10, EPL_JUVIND, EPL_JUVNR, EPL_KINGS, EPL_METRO, EPL_METROJ, EPL_NORQ, EPL_SELF, EPL_TAL, EPL_TRESID, EPL_UAL, EPL_VISITR**

## Instructions for Running:
```
chgbarredpin.pl -x
```

# Product Description:

Perl script written by Andrew Nisbet for Edmonton Public Library, distributable by the enclosed license.

SSO will authenticate library customers through EZproxy to provide access to most of the library's online resources. BC refuses to amend their code to test the status of a customer before approving authentication. The result is that BARRED customers are still allowed to use online resources. To accommodate BC  this script will change the PINs on all BARRED customer accounts.

There are a few ways to run the script depending on how you want the PINs changed. 
* If you don't use -Ut, you will end up with a list of users that will get changed, listed in a file in the temp directory.
* If you want you can change all the users' PINs to a new random value, otherwise the the default is 4617.
* If you would like all the user PINs to be changed to unique random numbers use -URt. This will create a shell script called 'change_barred_pins.sh' in the directory you ran the <code>chgbarredpin.pl</code> script in. To actually make the changes to accounts, change the shell script file's permissions to 700 and run.

To get the barred customers do this:
```
seluserstatus -tBARRED -oUt | seluser -iU -p<PROFILE> -oU
```
To change a PIN use edituserstatus which will preserve last activity for customer.
```
echo <user_key> | edituserstatus -R<new_pin>
```

Runtime:
12560 accounts -URt start 3:39, end 3:52 or 12 minutes.

# Repository Information:

This product is under version control using Git.
[Visit GitHub](https://github.com/Edmonton-Public-Library)

## Dependencies:

* seluser
* seluserstatus
* edituserstatus
* [pipe.pl](https://github.com/anisbet/pipe)
* transdate


# Known Issues:

None
