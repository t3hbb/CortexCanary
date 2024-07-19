# CortexCanary
Tooling related to discovery of Cortex XDR canary files.


## Cortex XDR Ransomware Protection, Chocolate Teapots and Inflatable Dartboards

**Honeypot1.ps1** - Powershell script to search for canary files, determine the Cyvera\Ransomware folder location a display all of the files.

**CIA_IS_OK.ps1** - Powershell script that does the same as Honeypot1 but also tests against a directory to see which files can be safely encrypted. This has been neutered in the script but if you comment out a few lines it will XOR the files with 0xBB. You may want to add a small delay to avoid behavioural detection when smashing loads of files.

**DirectoryComparison.java** - Java script to show the difference between what Java and CMD see for directory contents

Issue was reported to Palo Alto but it was deemed a non issue as the Confidentiality, Integrity and Availibility of the agent was not impacted. 

![image](https://github.com/user-attachments/assets/5c4a1bb3-5392-48ce-a72c-bfb239d19cdf)

CIA is OK :/ 

![image](https://github.com/user-attachments/assets/d11f8d33-7325-4b78-afaa-816dca210001)


Code is pretty rough, it is just a prototype POC - please run the CIA_IS_OK with $ErrorActionPreference = 'SilentlyContinue'

[TODO] - add blog post links.
