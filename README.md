#uberdeploy

The easiest way to deploy projects to your server.

	$ uberdeploy create firstProject
	$ cd firstProject
	$ uberdeploy deploy

All you need is *git*, *ssh*, a server where you can login via ssh and a project which likes to be deployed. ;)

##Install

**Copy & paste to shell & enter**

The following code downloads `install.sh` which will start a guided installation  on your machine. After that, you are ready to use uberdeploy. =)
	
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/platdesign/uberdeploy/master/install.sh)"


##Example

Switch to a folder where you want to place your project

	$ cd ~/allMyProjects

Initialize a new project.

	$ uberdeploy create myProject
	
Switch to your new project.

	$ cd myProject

Make some changes, add files/directories - simply work on your project...
When you are ready for deployment you only have to execute:

	$ uberdeploy deploy



**That's it! =)** Uberdeploy will do the rest for you.

For another example look at [uberdeploy-nodejs-sampleapp](https://github.com/platdesign/uberdeploy-nodejs-sampleapp). This could be used as base for nodejs-applications. Have a special look at the `deploy/post-receive`-file as an approach to handle a service which controls your app.



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


##.uberdeploy
Each project has a file `.uberdeploy` where you can configure and specify the behaviour of your project on the remote server.

**Syntax**

	<KEY> : <VALUE>;
	or
	<KEY>: '<VALUE>';

**Supported Options**

| Option | Description | Example
|:---|:----|:-----|
| WORKTREE | Defines a second directory, which will be checked out after each deployment on the remote server. | `/var/www`
| RUN | If you have set a `RUN`-command, uberdeploy will create a `service`-file in your remote project folder on each deployment. A `service`-file could be used to controle your app by a system-service. | `node app.js`


##Contact##

- [mail@platdesign.de](mailto:mail@platdesign.de)
- [platdesign](https://twitter.com/platdesign) on Twitter