
# RPM - The Indivisible Unit

The RPM Spec file is a mis-match of metadata and script.  It can be overwhelming if a new user views a mature RPM spec file for the first time.  However, a spec file can be easily created with a few required fields.  For example:

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

The above example defines a package called foobar version 1 release 0.  There are no files, so this is what I call a metapackage.  By itself, it is pretty useless, but when combined with the `requires:` statement, it becomes extremely useful, but more on that in the chapter on configuration management.

To show how easy it is to create a spec file, follow the steps below to create a spec file.  

    
    mkdir -p /tmp/wsyr02/{target/RPMS,root} # Create the nessary files for rpmbuild
    cd /tmp/wsyr02                          # Change directories and create the spec.
    cat << EOF >> firehose.spec               
    name: firehose
    version: 1
    release: 0
    license: Proprietary
    summary: Summary of Firehose
    group: organization/function

    %description
    A description of firehose goes here

    %files
    # empty
    EOF
    rpmbuild -bb --target=x86_64 \          # Build a binary rpm (-bb)
      --define="_topdir $(PWD)/target" \    # Place the resulting rpm in the target directory.
      --buildroot=${PWD}/root \             # Use root as the source
      firehose.spec                         # The spec file
    
The resulting steps produce a RPM in: `/tmp/wsyr02/target/RPMS/x86_64/foobar-1-0.x86_64.rpm`.  The contents of this rpm are not installed on the system, it just an archive, like a tar or zip file.

The RPM can be inspected using rpm:

    $ rpm -qip /tmp/wsyr02/target/RPMS/x86_64/firehose-1-0.x86_64.rpm
    Name        : firehose                     Relocations: (not relocatable)
    Version     : 1                                 Vendor: (none)
    Release     : 0                             Build Date: Tue Mar  8 13:35:43 2011
    Install Date: (not installed)               Build Host: localhost
    Group       : organization/function         Source RPM: firehose-1-0.src.rpm
    Size        : 0                                License: Proprietary
    Signature   : (none)
    Summary     : Summary of Firehose
    Description :
    A description of Firehose goes here

If you breezed through the above example, then perfect this book is for you.  However, if this resulted in more questions, I suggest you start with the following introductions to RPM.  Good guides can be found here:

  - http://www.rpm.org/max-rpm/ - A great source of information (keep next to your computer)
  - http://rpm5.org/docs/rpm-guide.html - Based on a version of RPM not found on most OS, normally rpm 4.x, but still a good source of information.

## What's in a name?

It is important to choose a name that is fitting to your package.  Typically the package name represents a binary since GNU linux is built on small, sharp tools.  However, packages like PHP, Python and Perl have relaxed this convention.

When faced with webscale applications that are comprised of code, assets and environment specific configuration, choose a name that is specific to project.  This root name is then adorn it with qualifiers, like `-application`, `-assets` or `-configuration`.  For example, firehose-application would represent the firehose application code.  With RPM, the best way manage these interdependent packages is to create sub-packages.  Choose firehose as the base packages and proceed to add sub-packages for application code, assets, and configuration is easier to maintain within the package spec file.

The top-level package should be a metapackage with an empty %files section and `requires:` declared on application, assets and configuration.  This makes installing an application as simple and typing `yum install firehose` to install a complete working system.  

### Sub-packages

Sub-packages are package declarations within a single .spec file that build on the top-level package declarations.  For example, the release and version metadata will flow into a sub-package if the sub-package doesn't declare it.  

A common approach I've seen in the field are engineers trying to create multiple spec files for different packages, but this leads to a more complicated build process.  The way %files sections are processed during `rpmbuild -bb` section looks at all package and sub-package declarations to reconcile the package contents.  Missing files or extraneous files are marked as failures.  Overriding the check is a symptom of misguided decision early on, since these checks will catch inconsistencies early on.  The fear is maintaining the spec file can get potentially unwieldily with a large number of sub-pacakges and motivates splitting sub-packages.  In practice, the spec files are easy to manage, even when they consist of 1000s of lines and the robust tools like diff, patch, svn, git, etc to manage change.

Practically speaking, any subpackage will add the `-subpackage` to the top level package name (unless overriden with `-n package-name`).  Building on the example above.  Adding the following:

    %package config
    summary: Configuration for firehose
    group: organization/function/configuration
    license: Proprietary
    
    %files config
    # None for now
    
    %description config
    Configuration for foobar

will result in the generation of firehose-config rpm.  Notice that we don't declare the release or version for this sub-package?  These values are flow through and result in an rpm called `/tmp/wsyr02/target/RPMS/x86_64/firehose-config-1-0.x86_64.rpm`.

### NVR - Name-Version-Release

NVR refers to Name-Version-Release and is not commonly used on the command line since most user are only interested in the latest release.  However, the NVR becomes increasingly important in dependency resolution.

Typically, the incrementing of a version is unique to the team; however, their are some gotchas.  Pick a dot notation and stick with it.  Going from x.x.x.x to x.x will cause the unexpected results.  There are ways around changing a versioning scheme, but those are exceptions and can be avoided resulting in much saner releases.

### Change log

The change log is incredibly useful for tracking changes.  Keeping the %changelog up to date is important when communicating with operation teams, since their concern is managing the change to the environment.

The format is straightforward:

    * Tue Mar 8 2011 Noah Campbell <noahcampbell@webscalebook.com> 1.2
        - Update the acl policy for foobar staging to be stage.

Keeping these up to date is easy to do once you get in the habit.  Any change that is made to an rpm, either to the spec or the files within it require and update the version and release.  Adding a comment to the change log can become second nature.

If you're running a more recent distribution a handy tool that can be used to script the updating of a spec file can be found in the `rpmdev-tools` package.  The specific command is `rpmdev-bumpspec`.  Combining `rpmdev-bumpspec` with your SCM should be straight forward.

## What Should and Should Not Happen in this Unit

RPM provides the ability to run scripts before and after installing the rpm.  This can be very useful to get the job done, but it should not be abused.  What kind of abuses are there?  The most onerous example is packaging a tarball within the rpm and then calling tar -zxf in `%post`.  This subverts the rpm database and its ability to track file changes.  Don't do it.

It is my belief that RPMs should stick to putting files on the filesystem and any coordination activity like starting/stopping a service should be done with a control layer (Chef, RunDeck, puppet).  I'll admit that stop/starting a service is a matter of taste and I've seen it done in the field.  However, it leads to failed installs of packages when a script fails to run for some unforeseen reason.  Its better to get the contents of RPM on the filesystem successfully, then to partially install an rpm and break the installation step.

