#uberdeploy

A little git-deployment tool for uberspace.

##Install

**OSX**

`bash -c "$(curl -fsSL https://raw.githubusercontent.com/platdesign/uberdeploy/master/installOSX.sh)"`


No configuration required!

##Example

Go to a directory where you want to place your project

`cd ~/myProjects`

Initialize a new project with

`uberdeploy create myProject`

After some questions and a bit of time... switch to new project directory. 

`cd myProject`

Make some changes, add some files/directories - simply work on your project...

Ready for deployment? Type:

`uberdeploy deploy firstDeploy`

**That's it! =)**


