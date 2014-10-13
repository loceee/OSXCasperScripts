FV Helper
=========

A helper for Casper 9.x FileVault config.

Vague instructions
------------------

1. Setup your FV Config (set it to run at **Current or Next User**)
3. Setup a smart group to catch eligible computers
	* FileVault 2 Eligibility ** is Eligible **
	* **AND** **(** FileVault 2 Partition Encryp State **is not Encrypted**
	* **AND** File Vault 2 Partition 2 Encrypt State **is not Encrypting ) **
	* **AND**  ... your other criteria (eg. computer model like **book**).
5. Create a policy to run the FV config, scope to your smart group - ** No trigger, ongoing **
	* Note down the policy ID of your Policy (copy from the URL bar of your browser)
5. Edit the **fvhelper.sh** and add accounts to skip, and the fvpolicy id
7. Create a policy to run script **fvhelper.sh** - **login trigger, self service (optional)**


 