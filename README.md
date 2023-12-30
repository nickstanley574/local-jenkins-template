# Local Jenkins

This is a set of scripts and configs to allow for a Jenkins container to run locally for personal project CI/CD. This is design for local development only and should not be use in prod-like environments.  

## Quick Start
```
./run-local.jenkins.sh
```

## Details

When working on a personal project, I am often in need of a CI/CD process. While GitHub Workflows is a option, I prefer to keep some projects private and avoid the costs of running Workflows in private repos. This project is my solution for my need, a local Jenkins template designed to run my local projects.

To us it, I clone this project into a project repos, enabling a container of Jenkins to start fully configured ready to use, including the job themselves. This approach allows for the execution of my project CI/CD in an isolated environment, maintaining package version consistency, and closely replicating the production runtime environment. Essentially, I am taking advantage of the purpose and promise of containers.

The core of this process involves the automatic updating of Jenkins jobs. When using a Jenkinsfile, changes are only applied after another job run, a known limitation documented in Stack Overflow and Jenkins project tickets.

- [How to make sure list of parameters are updated before running a Jenkins pipeline?- stackoverflow.com](https://stackoverflow.com/questions/46680573/how-to-make-sure-list-of-parameters-are-updated-before-running-a-jenkins-pipelin)
- [How to force jenkins to reload a jenkinsfile? - stackoverflow.com](https://stackoverflow.com/questions/44422691/how-to-force-jenkins-to-reload-a-jenkinsfile)
- [JENKINS-50365 Reload pipeline script without executing the job](https://issues.jenkins.io/browse/JENKINS-50365)

In the past, I have addressed this by using a 'refresh' parameter that skips all the stages when selected, but that approach is clunky and prone to errors.

To solve this I used the Jenkins Configuration as Code Plugin which allows you to load in [`pipelineJob`](https://jenkinsci.github.io/job-dsl-plugin/#path/pipelineJob) based on a script location. This combined with mounting the project directory to the jenkins docker container allowed for a file watcher to trigger the     `jenkins-cli.jar` `reload-jcasc-configuration` command to reload on a file change within the `entrypoint.sh` of the Docker image. This ensures that when a build is run it is the same configs that is in the Jenkinsfile without the need to running the job to get the latest configs.

## Design Decisions

### Docker

Running Jenkins in a container allows it to be isolated from the local system, but in order for the Jenkins container to run other containers I wanted to use the host's docker engine. When a container is started up it called via the container to the local docker bin and docker socket via volume mounting. The advantage of this is for debugging you can run `docker` command from your command line to see what is running and `exec` into running container started by Jenkins if needed. 

Since I run docker in [rootless mode](https://docs.docker.com/engine/security/rootless/), which I think should be the standard practice, there is a permissions issues between the container `jenkins` user and the local permissions of the docker socket. The jenkins user doesn't have the needed permissions to the `docker.sock` and if the host `docker.sock` permissions are updated it could affect the host. This problem could be solved by running the Jenkins container Jenkins process as `root`, but using root should alway be questioned. 

The solution was to use [Linux Access Control Lists (ACLs)](https://www.redhat.com/sysadmin/linux-access-control-lists) on the container and setup during the docker build while the build was still running as `root` to install `acl` and provided a config that tells the container that the `jenkins` user can access the `docker.sock`. The trick is that since the docker.sock file is not in the image itself and is amount the image build provided a `/etc/sudoers` configs to allow the `jenkins` user to `sudo setfacl` the `docker.sock` file. Since the acl config is isolated to the container it doesn't affect permissions on the host.

### Getting the Code to Jenkins

Most Jenkins jobs I have encountered pull their Jenkinsfile from a external git repo. Since I want to run the code I have locally to test changes to both the code and the Jenkinsfile itself before committing this isn't a option. I don't want to have do the full git commit flow and pull just because I missed a comma in a Jenkinsfile during init development. Again the solution to this is to use docker volume mount of the locally project and use the `jenkins.yaml` to tell the job where the jenkinsfile is.

### Insecure Settings

Since this is running locally, I've adjusted security settings for simplicity of use, akin to local development where you have access to admin settings for the applications and databases. For example, at start up a password in needed for the admin user which is `admin:admin` after the init config I remove the need to any authenticated login since this will design to run locally via `authorizationStrategy: unsecured`. This unsecured setting are comment with reasoning when applied.


## Final Thoughts

This project serves as a good example of how a seemingly simple end-state and solution are, in fact, a specific combination of specific features across many tools, achieved by research and experimentation, ultimately leading to the desired outcome. 