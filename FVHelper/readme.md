FV Helper
=========

####A helper for Casper 9.x FileVault configuration

Casper handles FileVault very well, with an admin GUI and key escrow. FVHelper aims to assist you with automating the initiation of the encryption process and minimise the possibility of the incorrect account becoming the primary FV user.

By leveraging the FileVault config built into Casper, we can utilise jamf's key escrow without re-inventing the wheel. We also can tell FVhelper to skip certain accounts (perhaps your local management or admin accounts) to prevent your L2 or desktop support accidentally activating FV for these accounts instead of the enduser.

Launching FVHelper on the login trigger means that the first user to logon to a FV "eligible" unencrypted Mac will be prompted to enable Filevault. From the enduser or desktop support perspective, FV is enabled in the background, they are prompted that in order to complete the process they must be logged out and enter their password again.

##### New: Defer Mode!

**TODO:** handle additional FV unlock accounts post FV enable.

Vague instructions
------------------

1. Setup your FV config (set it to run at **Current or Next User**) equiv of. *fdesetup -defer*
3. Setup a smart group to catch eligible computers
	* FileVault 2 Eligibility **is Eligible**
	* **AND** **(** FileVault 2 Partition Encryp State **is not Encrypted**
	* **AND** File Vault 2 Partition 2 Encrypt State **is not Encrypting )**
	* **AND**  ... your other criteria (eg. computer model like **book**).
5. Create a policy to run the FV config, scope to your smart group - **No trigger, ongoing** (or a custom trigger you might want to initiate manually, fvhelper.sh can handle both)
	* Note down the policy ID of your FV policy (copy from the URL bar of your browser) unless using a custom trigger.
5. Edit the **fvhelper.sh** and add accounts to skip, and set the fvpolicy varliable to either the ="-id xxx" or "-trigger xxx" that calls your FV policy.
7. Create a policy to run script **fvhelper.sh** - **login trigger, self service (optional)**
8. Scope the *FVHelper* policy to your FV smart group
	* This policy calls the your FV Policy, so ensure this is scoped to the Macs you wish to FV.


Thanks for Quam Sodji for a much better walkthrough here... [http://jumpt.wordpress.com/2014/10/13/leveraging-filevault-on-casper/](http://jumpt.wordpress.com/2014/10/13/leveraging-filevault-on-casper/)








 