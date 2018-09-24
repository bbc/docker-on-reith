phoney: all

control=src/DEBIAN/control

# what host are we deploying to - steal from the nginx conf file - grand assumption here
deployTarget=$(shell grep server_name src/etc/nginx/sites-enabled/* | head -1 | awk '{print $$2}' | sed 's/;//g')

# debian package name - always "bbc-" git repo name
pkg=$(shell awk '/Package/{print $$2}' $(control))

# name of the git repo (remove bbc- from package name)
repo=$(shell awk '/Package/{gsub("bbc-",""); print $$2}' $(control))

# the app index file
index=src/opt/bbc/$(repo)/www/index.html

# package version (e.g. 1.0.0) is the current release tag - whatever that is. Defaults to 0.0.0 if no tag found.
version=$(shell git tag | tail -1 | awk '{t=$$1}END{print (t=="")?"0.0.0":t}')

# are we 'clean' against master, or have local changes pending?
gitstatus=$(shell git status|awk '/Changes/{print " - includes un-committed changes";exit}')

url=https://github.com/bbc/$(repo)

hash=$(shell git rev-parse HEAD)

# build number (e.g. xx in 1.0.0.xx) is the total number of git commits made
build=$(shell git rev-list --count HEAD)

# debian package filename
deb=$(pkg).$(version).$(build).deb

now=$(shell date)
hostname=$(shell hostname -s)

# build the deb package (default action when run as 'make')
all:
	# capture git logs
	mkdir -p src/opt/bbc/$(repo)/doc
	git log > src/opt/bbc/$(repo)/doc/changelog

	# append date and git version to the control file
	egrep -v "Version|Date|Vcs-" $(control) > controlX
	echo Date: $(now) >> controlX
	echo Version: $(version).$(build) >> controlX
	echo Vcs-Git: $(url) >> controlX
	echo Vcs-Browser: $(url) >> controlX
	echo Vcs-Revision: $(url)/commit/$(hash)$(gitstatus) >> controlX
	mv controlX $(control)

	# add build info to the index file
	-grep -v 'meta name="generator"' $(index) > indeX
	-awk -v generator="$(deb) on $(hostname) at $(now)" '{print}/application-name/{print "<meta name=\"generator\" content=\""generator"\">"}' indeX > indeX1
	-mv indeX1 $(index)
	-rm -f indeX indeX1

	# run turn src into a debian tree
	fakeroot dpkg-deb -Zgzip --build src $(deb)

	dpkg --info $(deb)
	dpkg --contents $(deb)

	git status

# Deploy will usually be executed as the user jenkins, on jenkins.labs.jupiter.bbc.co.uk
#
# i.e. the Jenkins job should contain just 2 lines...
#
#   make
#   make deploy
#
# Assumes that the target bbcadmin user has been granded sudoers.d permission to passwordlessly exec dpkg and apt
#
deploy:
	-rcp -o StrictHostKeyChecking=no $(deb) bbcadmin@$(deployTarget):
	-ssh -o StrictHostKeyChecking=no bbcadmin@$(deployTarget) 'sudo dpkg -i $(deb) && sudo apt -y -f install'

jenkins:
	@if [ -f ./triggerJenkins ]; then ./triggerJenkins; fi

ver:
	-curl -noproxies '*' -s -L http://$(deployTarget) | grep generator
