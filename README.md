#uberdeploy

A little git-repository-deployment tool for uberspace (e.g.).

##Install

**Copy, paste to shell, enter**

	bash -c "$(curl -fsSL https://raw.githubusercontent.com/platdesign/uberdeploy/master/install.sh)"

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


For a detailed example have a look at [uberdeploy-nodejs-sampleapp](https://github.com/platdesign/uberdeploy-nodejs-sampleapp).



##Commands
- **create**

	*Example:* `uberdeploy create` or `uberdeploy create myApp`
	
	Guides you through the process of creating a new project folder.


- **deploy**
	
	*Example:* `uberdeploy deploy`
	
	Deployes your project to given remote server by commiting changes, pushing the repository, checking out the worktree and calling `deploy/post-receive` from your project files. `deploy/post-receive` gives you the opportunity to customize your deployment-process.


- **destroy**

	*Example:* `uberdeploy destroy`
	
	Destroyes a project guided.

- **init**

	*Example:* `uberdeploy init` or `uberdeploy init myApp`
	
	Creates a new project folder without remote-connection.

	
- **update**

	*Example:* `uberdeploy update`

	Checks for a new release of uberdeploy and updates your local version.
	
- **log**

	*Example:* `uberdeploy log`
	
	Displayes projects log file from remote.

	
	
##Options
| Option | Description |
|:---|:----|
| -v / --version | Displays the current version installed on your machine. |
| -h / --help | Displays the help page. |



##Contact##

- [mail@platdesign.de](mailto:mail@platdesign.de)
- [platdesign](https://twitter.com/platdesign) on Twitter