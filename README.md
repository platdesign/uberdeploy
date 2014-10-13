#uberdeploy

A little git-repository-deployment tool for uberspace (e.g.).

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

`uberdeploy deploy`

**That's it! =)**



##Commands
- **init**

	*Example:* `uberdeploy init` or `uberdeploy init myApp`
	
	Creates a new repository and adds a `.uberdeploy`-config file.

- **create**

	*Example:* `uberdeploy create` or `uberdeploy create myApp`
	
	After initializing a new repository with `init` a remote (bare) repository will be created with your given `SSH-Authority`.

- **deploy**
	
	*Example:* `uberdeploy deploy`
	
	Adds all files to the stage with `git add --all`, commits the stage and pushes the repository to remote `uberspace`. After push the workingtree will be checked out on the remote server.

- **destroy**

	*Example:* `uberdeploy destroy`
	
	Destroyes the current project.


	
- **update**

	*Example:* `uberdeploy update`

	Checks for new version of uberdeploy and updates your local machine to the latest one.
	
- **join**

	*Example:* `uberdeploy join`
	
	Asks for projectname and SSH-Authority. Clones the remote repository to your local machine and adds remote `uberspace`.
	
	
##Options
| Option | Description |
|:---|:----|
| -v / --version | Displays the current version installed on your machine. |
| -h / --help | Displays the help page. |



##Contact##

- [mail@platdesign.de](mailto:mail@platdesign.de)
- [platdesign](https://twitter.com/platdesign) on Twitter