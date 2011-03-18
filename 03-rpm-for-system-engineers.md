### What is RPM under the covers?

RPM is a...well lets ask RPM.

    $ rpm -qf --list `which rpm`
    /bin/rpm
    /etc/rpm
    /usr/bin/rpm2cpio
    /usr/bin/rpmdb
    /usr/bin/rpmquery
    /usr/bin/rpmsign
    /usr/bin/rpmverify
    /usr/lib/rpm
    /usr/lib/rpm/macros
    /usr/lib/rpm/platform
    ...macros...
    ...db maintenance files...
    ...docs...
    /var/lib/rpm
    ...db files....

For brevity I condensed the output above into what is basically the executables, a configuration file, and the support files around documentation.  Most importantly, there is a database that lives in /var/lib/rpm and stores all the metadata about the system as it is currently installed.  

Let me repeat, it is a database that contains all the metadata about what is currently installed on this particular host.  I think this is worth saying twice because there are a number of current systems out there that attempt to duplicate this information, inaccurately, when the absolute source of truth is installed, and queryable from a login shell. 

The kind of information that is available can be queried through the rpm -q interface.  What I'll show below is the type of information most interesting for a system engineer.

### Interrogating the system

rpm -q is the primary interface to accessing the rpm database.  There are plenty of options to choose from, but the ones I find most useful are:

`rpm -qf '/path/to/some/file'` which will return information on the package that contains the file.

`rpm -qp 'package.rpm'` which returns information on a package identified.  This is particularly powerful when you can provide a url like http://yum/path/to/package.rpm.  RPM does the work of grabbing the file for you.

Finally, `rpm -q package` which returns information about the package if it's installed.

All three of the approaches above allow you to query an rpm for its metadata.  

Specific flags, like `-i` will return all the information that you put in the spec file.  `-l` lists all the files in the package.  `--requires` lists all the immediate dependencies.  Transitive dependencies are not list, but can be discovered using yum and a tool called repoquery allows for similar queries when using a yum repo. 

On individual rpms, the above is probably all I use on a daily basis.  Real dependency management is addressed with yum and covered later.

### Dependencies

Creating system stacks that work every time requires being explicit about what your stack depends on.  RPM will provide the guard rails to prevent you from breaking any of those explicit dependencies.  I've seen folks fight this capability to where they don't use dependencies at all.  This turns RPM into a glorified tar ball database and while there is still value, RPM can do so much more.

As a systems engineer, your primary concern is the construction of metapackages that capture your requirements.

For example, a webserver metapackage would require httpd and php.

    name: webserver
    ...
    requires: httpd
    requires: php

This would ensure that apache and php are installed whenever the webserver metapackage is installed.  If someone tries to upgrade php, the above package doesn't complain one bit.  However, it is common for such simple sounding upgrades to break in unforeseen ways.  By put explicit version dependencies on our webserver metapackage

    name: webserver
    ...
    requires: php >= 5.2
    
You can lock down a version.  Let say you don't want allow folks to install php 5.3.  You can add another requires statement:

    name: webserver
    requires: php >= 5.2
    requires: php < 5.3
    
That would allow for minor versions and any release such that it falls within the range.  If someone attempts to install php 5.3, RPM will block the transaction because one of the rules `php < 5.3` is made invalid.

### Project/Environment/Configuration

The world of configuration management and packaging is about to collide, right here before your eyes.  What I've taken for granted in my evolution of webscale yum and rpm apparently is non-obvious to system engineers.  

Configuration files must be packaged and versioned just like application code. 

Application code depends on the configuration and vice versa.  This also forces the application to not change between versions, an exercise I will explore in the next chapter for developers.  It also means that version 4.53-7 of your application is deployed in development, uat, staging and production.  As it the application code is promoted from environment to environment, you can gain confidence that it will work in the next environment.

Configuration is environment specific, always is and always will be.  The database used in development, staging and production is always different.  Maybe its localhost, maybe its db-prd-master-01.corp, but it is always specific to the environment.

I have taken that stance that configuration should not move.  Configuration goes in a property file, yaml file or any other static file format.  This makes it predictable and repeatable.  Nothing should be runtime dependent and if it is, it is application state and probably deserves to live in a database.  This is my take, I'm sure there are folks who will want more form an ruby/erb file, etc and that is their decision.  Whatever the format, it goes in a package.  If you have control over the application package definition, then the requirement for a virtual package is declared:

    name: servicefoo
    require: servicefoo-config

From the application spec file, it doesn't really matter if it is a virtual package or not.  The configuration package needs to satisfy the requirement.  Either by matching the package name exactly, which is probably a futile effort since you want to give environment specific configuration an environment specific package name anyway.  So given a package spec, heres how you construct a configuration package, lets start with the skeleton.

    name: servicefoo-config
    ...
    %package development
    ...
    %package staging
    ...
    %package production
    ...
    
The package name is servicefoo-config, but this will not have a %files section, so a package will not be created.  The sub packages creates will be **servicefoo-config-development**, **servicefoo-config-staging**, **servicefoo-config-production**.  Note that none of these will satisfy the servicefoo-config requires in the application package.  Lets fix this:

    name: servicefoo-config
    ...
    %package development
    provides: servicefoo-config
    ...
    %package staging
    provides: servicefoo-config
    ...
    %package production
    provides: servicefoo-config
    ...
    
Now each configuration package provides the virtual package servicefoo-config.  When someone tries to rpm -i servicefoo.rpm, they'll have to provide one of the configuration packages to suit their environment requirements.  rpm -i servicefoo.rpm servicefoo-config-staging.rpm will install the app code and the configuration for the environment.  When YUM is introduced, the command becomes yum install servicefoo and with proper repo management, the appropriate configuration file is automatically installed.

The approach described above is how you link configuration to application code in such a way that supports multiple environments.  The same rules apply to version dependencies of the config.  Typically the application spec file will lead the version...i.e. require a newer version of servicefoo-config > 1.4.