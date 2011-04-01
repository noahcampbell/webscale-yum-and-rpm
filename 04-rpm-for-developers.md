### Single Spec file for the entire project

One aspect of spec files that most developers bump into, is using a single spec file for their entire project.  Not using a single spec files requires quite a bit of overhead in keep the various files organized so that each rpm has the files it needs to know about.  In my experience, this leads to very cumbersome and brittle builds scripts that the next person responsible for maintaining your code will only scratch their head.  The spec file will get long (especially if there are many, many files found in python, ruby, php or other interpreted languages), but it is not difficult to maintain with a decent editor with build in search.

Keeping a single spec file also reinforces a package to sub-package naming convention.  Since sub-packages are appended to the the top level package name, this is easy to maintain, especially when refactoring a package name.

When running rpmbuild, all files are identified in the %file section of all defined packages defined in the spec file.  If any missing or additional files are found rpmbuild will fail.  This provides a fail safe in identifying files that might be potentially forgotten otherwise.

For those using subversion, or other SCMs that maintain control files within each directory, rpmbuild will quickly point out that the .svn folder is not called out in any %files section.  A simple `svn export` will copy only the source, without the .svn files to a working directory.

### Project organization

To get started with building rpms, I recommend the following directory structure.  Obviously, modify for your own use as you see fit.

    .
    |-- .dist #1
    |-- root  #2
    |   |-- etc
    |   `-- home
    `-- target
        `-- RPMS
            `-- noarch


1. This .dist directory is used by rpmbuild and really only necessary if you need to assemble your files from a build script.
2. I recommend creating a root directory and placing the files in this directory as you'd expect to find them once the package is installed.  I recommend following the [FHS][1]

[1]: http://www.pathname.com/fhs/pub/fhs-2.3.html

Here is a Makefile that takes advantage of the file structure

    .PHONY: yourpackage.spec

    yourpackage.spec:
    	@mkdir -p target/RPMS/noarch  #1
    	@rm -rf .dist
    	svn export root .dist         #2
    	rpmbuild -bb --target noarch-linux --define "_topdir ${PWD}/target" --buildroot ${PWD}/.dist $@  #3

    clean:
    	@rm -rf .dist target

Feel free to use the above Makefile as starter, or translate into your favorite build language.

Some key highlights:

1. You must create the destination target for your rpm.  The noarch corresponds to the --target in #3. 
2. This is specific for svn, to strip the .svn directories from the source code.
3. This is the main action.  Note the use of _topdir to specify the destination (this is often a source of headache for folks trying to automate a build).

### Listing files

Generally speaking, I prefer explicit over implicit declaration of files in the %files section.  However, if the number of app files are quite large, then I prefer explicit configuration files and implicit application files.

Listing files in %files is quite easy.  You simply give the absolute path of the file as it exists in `--buildroot`.  For example:

    /etc/application/server.conf
    
This can be adorned with various modifiers, typically the `%attr()`, %dir or `%config`.  A great [description of `%config`][config-defn] and its behavior is provided by Jon Warbrick.  [%attr is well described here][attr-defn].  I won't go into too much detail.

[config-defn]: http://www-uxsup.csx.cam.ac.uk/~jw35/docs/rpm_config.html
[attr-defn]: http://www.rpm.org/max-rpm/s1-rpm-inside-files-list-directives.html

Another aspect of %files is the ability to use an external file.  %files -n myfilelist tells `rpmbuild` to use myfilelist as an input.  It follows the exact same format as the %files section.  This has been handy when dealing with asset files that range in the 100s to 1000s, since they can typically be found using `find` or other similar techniques.

    Nice example goes here.

What's nice about %files -n is that it is not mutually exclusive with the contents of %files.  You can use a file list and explicitly list out files that you want to track that are not captured in your file list.

Finally, you can list a directory in your `--buildroot` and all the files will be include, but not the directories.  The consequence, is that the when a package is laid down, the directories are created by rpm.  When the same package is removed, the files are removed, leaving the directories.  That may not be a big deal to some, but I find it best to be explicit if you can.

Another thing to note is that unless specifically called out, directories are not managed by rpm or your package.  This requires the %dir directive on folders.  In one particular scenario, I knew a particular folder would always be present when an application package was installed.  I would use rpm -qf /path/to/directory to know which version of a package was installed without having to rely on a particular file in the application.  Without a %dir directive, this wouldn't have been possible and the logic I used to determine the currently install application would have been much more complex.

### Specifying Dependencies and Virtual Packages

Now for the power of RPM, being able to define dependencies your code relies on.  If you're writing a php application, you can add the following to your package definition:

    requires: php
    
You can even include a specific version:

    requires: php >= 5.2
    
Going a bit further, you can even box your dependencies.  Lets say you want php, but you are not ready for 6 when it comes out.  This can be accomplished by stating the following:

    requires: php >= 5.2
    requires: php < 6
    
It takes two statements, but the effect is that you're application will install the latest version of php greater or equal to 5.2, but nothing greater than 6.  

If you application is still chugging along when 6 roles out, it will not install on a machine running version 6 or greater.  This can help avoid unintentional upgrades of the underlying system.

What's also nice is that you can create virtual packages very easily:

    requires: mysuperdupper-package >= 3
    
This allows you as the software developer, to create any dependency you want fulfilled in order for your application to be installed.  If that package is not met, then RPM (and Yum) will complain, preventing the installation.

### Configuration as Virtual Packages

The package best suit for creation by a developer is the configuration virtual package.  Consider that configuration represents the first input required by your application for it to even start.  It is an artifact, just like a source file or a built binary.  You expect a certain format and location of this input.  System administrators need to manage this artifact independent of your development lifecycle so by creating a virtual package, you are providing an interface for system administrators and software engineers to communicate what is needed to get the application to run.  It is as simple as:

    requires: myapp-config >= 1
    
To make the above statement does require documentation of what is to go into the configuration file.  A great way to showcase what goes into a virtual package is to create a development sub-package such that it provides the virtual package you require:
    
    ...
    %name config-development
    version = 2
    provides: myapp-config
    ...
    %files
    /etc/app1/config.properties
    
When you build the rpm, a corresponding packagename-config-development-2-1.noarch.rpm will be generated.  This file can be inspected by a system admin for details on what was configured.  I would strong urge you to also provide the documentation through traditional mediums like user guides, wikis, READMEs, documentation, etc.  Provide a url: in the subpackage to the documentation.

