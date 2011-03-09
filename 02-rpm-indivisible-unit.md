### Getting Started

The RPM Spec file is a mis-match of metadata and script.  It can be overwhelming if a new user views a mature RPM spec file for the first time.  However, a spec file can be easily created with a few required fields.

    name: foobar
    version: 1
    release: 0
    license: Proprietary
    summary: Summary of Foobar
    group: organization/function

    %description
    A description of foobar goes here

    %files
    # empty

That defines a package called foobar version 1 release 0.  There are no files, so this is what I call a metapackage.  By itself, it's pretty useless, but when combined with the requires: statement, it becomes extremely useful, but more on that in chapter ###.

Copy the above into a file called foobar.spec.  

    mkdir -p /tmp/wsyr02/{target/RPMS,root}
    cd /tmp/wsyr02
    cat << EOF >> foobar.spec
    name: foobar
    version: 1
    release: 0
    license: Proprietary
    summary: Summary of Foobar
    group: organization/function

    %description
    A description of foobar goes here

    %files
    # empty
    EOF
    rpmbuild -bb --target=x86_64 --define="_topdir $(PWD)/target" --buildroot=${PWD}/root foobar.spec
    
This produces an rpm in: `/tmp/wsyr02/target/RPMS/x86_64/foobar-1-0.x86_64.rpm`

The RPM can be inspected using rpm:

    noahc-mbp:wsyr02 noahcampbell$ rpm -qip /tmp/wsyr02/target/RPMS/x86_64/foobar-1-0.x86_64.rpm
    Name        : foobar                       Relocations: (not relocatable)
    Version     : 1                                 Vendor: (none)
    Release     : 0                             Build Date: Tue Mar  8 13:35:43 2011
    Install Date: (not installed)               Build Host: localhost
    Group       : organization/function         Source RPM: foobar-1-0.src.rpm
    Size        : 0                                License: Proprietary
    Signature   : (none)
    Summary     : Summary of Foobar
    Description :
    A description of foobar goes here

### What's in a name?

It is important to choose a name that is fitting to your package.  Typically the package represents a command since GNU linux is built on small, sharp tools.  

However, when dealing with webscale applications that are comprised of code, assets and environment specific configuration, it is likely more important to choose a name that is specific to project and  adorn it with modifiers, like -application, -assets -configuration.  For example, foobar-application would represent the foobar application.  The best way to do this is to use sub-packages.  Keep in mind that foobar-application will be the base of all packages so starting with foobar and then adding sub-packages for application code, assets, and configuration is easier.

The top-level project can be a metapackage, an empty %files section with proper dependencies declared on application, assets and configuration.  This makes installing an application as simple and typing `yum install foobar`

### Sub-packages

Sub-packages are package declarations within a single .spec file that inherits from the top-level package declaration on release and version.  I've seen engineers try to create multiple spec files for different packages, but it leads to a more complicate build process because rpm will look at the %file directives and throw errors if it detects files it does not know about.  Maintaining the spec file can get potentially unwieldily, at least that is the motivator everyone starts with when splitting into multiple spec files.  In practice, the spec files are easy to manage, even when they consist of 1000s of lines.

Any subpackage will add the `-subpackage` to the top level package name (unless overriden with `-n package-name`).  Building on the example above.  Adding the following

    %package config
    summary: Configuration for foobar
    group: organization/function/configuration
    license: Proprietary
    
    %files config
    # None for now
    
    %description config
    Configuration for foobar

Will result in the generation of foobar-config rpm.

### NVR - Name-Version-Release

NVR refers to Name-Version-Release and is not commonly used on the command line since the latest is typically what is being installed.  However, the NVR becomes increasingly important in dependency resolution.

Typically, the incrementing of a version is unique to the team; however, their are some gotchas.  Pick a dot notation and stick with it.  Going from x.x.x.x to x.x will cause the unexpected results.

### Change log

The change log is incredibly useful to tracking changes made within the new version.  Keep the changelog up to date is important when communicating with SA concerning any changes that might have been made.

The format is:  

    * Tue Mar 8 2011 Noah Campbell <noahcampbell@foobar.com> 1.2
        - Update the acl policy for foobar staging to be stage.

Keeping these up to date is easy to do once you get used to using spec files, especially when you need to rev' the version and release.

### What Should and Not Happen in this Unit

RPM provides the ability to run scripts before and after installing the rpm.  This can be very useful to get a job done, but it should not be abused.  What kind of abuses are there?  One the RPM authors call out is including a tarball within the rpm and then calling tar -zxf in post.  This subverts the rpm database and its ability to track file changes.

It is my belief that RPMs should stick to putting files on the filesystem and any coordination activity like starting/stopping a service should be done in a different layer.  I'll admit that stop/starting a service is a matter of taste and I've seen it done in the field.  However, it leads to failed installs of packages when a script fails to run for some unforeseen reason.  Its better to get the contents of RPM on the filesystem successfully, then to partially install an rpm.

