
# Yum and RPM for Configuration management

Configuration management is often tossed around as something that is desperately needed but push on what it is, and there is little to find.  I present in this chapter a solution for configuration management using only yum and rpm.  

This is a solution that requires coordination across development, release engineering and system administration, but does accommodate configuration management in a methodical and repeatable process.  Because the simplicity of the approach, it is often overlooked, but in its simplicity, it quite reliable and flexible.

## For Developers

A developer must build with configuration in mind.  This is often not done, or considered as an afterthought.  At the time of this writing, finding any patterns for developers to follow on configuration is not easy.  It is masked by software configuration management, which is about managing change within source code.  It doesn't address what happens once software is released into staging, production.

These are the patterns I found to be most helpful and not intended as an exhaustive list.

## The .properties or .ini or .yaml

All configuration needs to be stored in a text file using key value properties or more exotic formats like yaml.  I did not list JSON or XML.  It is natural for developers to gravitate towards XML because the tooling support within the language is typically very robust.  However, consider the primary expert users of your software are not "in" the language when they have to change the configuration.  They're toolchain consists of text editors like vi and tools like sed, awk, grep, etc.  These are all line orientated tools.  XML and JSON are block orientated and therefore present a mismatch between two users.

Keeping the configuration in line orientated file formats make managing the configuration easier downstream.

## The conf.d directory

Configuration files that are hard coded in the application pose a potential challenge when maintaining the configuration using the package centric approach.

The requirement is that configuration is read from a directory following some pattern.  For example, /etc/app/conf.d/*.conf.  The specific rules of how the files are evaluated, sorted order, timestamp, etc. is not really important as long as it is done consistently.

In bash

    for config in $(find /etc/app/conf.d -maxdepth 1 -type f -name \*.conf); do 
      source ${config}; 
    done

Will find all the files in /etc/app/conf.d that are files who name consists of *.conf and source those files.  Python, Ruby, Java, C, etc. can all achieve the same.  

The flexibility provided by this situation is that configuration can be split into multiple files, maintained by different organizations and be subject to difference SDLC.  The example that best crystalizes the need for this pattern is the issue with managing credentials.  Lets assume that username and password for a database are managed by the security department.  In the /etc/app/conf.d directory there would be:

    /etc/app/conf.d/credentials.conf
    /etc/app/conf.d/database.conf
    
These two files, when read together, will provide the required information to access the database.

Another example, is dealing with specific environments.  Imagine a staging and production environment.  To keep the configuration consistent between environment, the following can be employed:

    /etc/app/conf.d/credentials.conf
    /etc/app/conf.d/database-common.conf
    /etc/app/conf.d/database-production.conf

The above clearly breaks out the configuration from the environment to the common configuration.

### Additional patterns

The two patterns above are critical for package centric configuration management.  The following patterns should be given strong consideration, but not required.

## Configuration should focus on links between software components

In the example above, I mentioned the connection to the database as an example.  It's also a great example of a link between software components.  A link typically has the following properties:

  * Touch the network layer
  * Can be tuned
  * Controls credentials
  * Touches the filesystem, read/write.
  * Feature Flags (these are opaque, but they change the behavior of the code)
  * Buffer/Queue tuning parameters
  * Thread pool parameter

What is probably not of interest to release engineers or system administrators and should be removed.  The point is to keep the signal to noise ratio high.

  * Wiring configuration (Spring wiring, etc)
  * Module configuration, constants
  * Configuration only a developer would understand

## Configuration is static

Try to make the configuration as static as possible.  The reason for this is that if someone needs to have a mental model of how something will be "compiled" or "execute" then there is a burden on the end-user the need to acquire and maintain this knowledge.  An expert in Perl can figure out what some Ruby code is trying to do, but it requires time and experimentation, something not afforded during a site wide outage.

### Additional Considerations

  * Keep the configuration as concise as possible.  
  * Provide units of measure.  
  * Provide acceptable ranges.  
  * Provide explanation around magic values (0 means unlimited).
  * Provide example configurations 

## For Release Engineers

Release engineers are the glue between getting code that works, to realizing the full systems.  This role is often filled by various people during the promotion of code from developer tools to fully running systems.

### Defining a version identifier semantics

There are numerous ways of dealing with version identifiers.  Finding the right semantic meaning of the version numbers should fall to the release engineers since they'll be coordinating packaging where these numbers are significant.

RPM imposes a Version-Release construct the numbering system, and by practice, Version represents the code version as defined by the author of the code and release is significant to the release engineer.  Within version and release, any dotted and dash notation can be used.  For example, major.minor.patch.build is a common scheme.  What each increment means, is up to the business to decide.  For example, minor increments ensure compatibility in apis, but may change the semantics of api.  For release, it's often a number-build where number is an auto-generated serial number and build represents a target environemnt (fc14 for fedora core 14 or acme-4 for acme's standard image number 4).

Some general guidance, adapt to fit your needs.

major.minor for the version is often good enough
release should be tied to build number at the very least. 

???? MORE EXAMPLES ????

### Building from Source

The first step during code promotion is building from source.  Often this is first automation step and targets the testing environment or staging area.  It can represent the full integration build.  

Building from source also represents the first injection of configuration not used by a developer.  Configuration for localhost is replaced with real live systems.  Data from production systems are replicated into similar database systems.  It's the first time things go wrong because assumptions in the configuration are being tested.  A hord-coded port number is caught during this stage.

Using yum and rpm, this is first place to start classifying environmental configuration.  Is it staging, alfa, beta, perf-test, production?  Where does the configuration come from. As much as possible, a release engineer needs to track down this information and capture it in the configuration files.  If the developer has followed the patterns listed above, then adding these values should be relatively straight-forward.  If not, then the release engineer will need to create a build process that can accommodate the different environments, often rebuilding the entire system from scratch.

### Code Management Through Versioning and Dependencies

As a build is being made, the code and configuration are both getting version stamps.  Perhaps they're lock step or they evolve on their life cycles.  Either way, the spec file needs to capture the dependencies.  For example:

    require: app-config = 1
    
In the respective app-config-staging, app-config-production, each config package provides this virtual package.

    name: app-config-staging
    version: 1
    provides: app-config
    ...

Only version 1 of the app-config can be installed, but the environment specific version is variable.

### Dependency Management

It's often difficult to capture what a developer has configured on their box.  Often packages get install manually (i.e. yum install 3rd-party-lib) and the spec file is not updated.  Creating a build environment that simulates an install in a chroot jail or virtual machine should be common practice.  This will help identify missing dependencies.  Tying this into the CI should also be a goal of release engineering.  Having this type immediate feedback will ensure it's properly managed.

### Developer Sandboxes

Given the capability of most developer workstations, running a VM is extremely easy.  Tools like Vagrant provide a easy way to release production, or near production systems to the developer to test on, or build on entirely.  These sandboxes should be created from the system image inventory directly as to not introduce yet another environment to maintain.  If production is running CentOS 5.2, then the developer should have a CentOS 5.2 image on their machine.

### System Image Management

## For System Administrators

### Working With System Administrators

One thing to note is that this technique tries not to interfere with a systems administrators need to make changes to a system to keep the system running during a time of emergency.  Since RPM doesn't enforce file integrity after it's laid down the bits, a sys admin is free to make changes as necessary.  Obviously, the goal is avoid such specific changes as part of the standard operating procedure, but when they need to get down, it can be done quickly and efficiently without any surprises.

Once an change has been made, RPM and Yum can be used to detect that change and report accordingly.  rpm -V package will verify the integrity of the files it has in its %files section.  If any have changed, either content or file attributes, rpm will report back.  Yum can also be used to check if new packages have been installed (???? yum -version check with skvidal????) will report any differences.  Think of it as a checksum on what's installed.  This checksum should align to the system inventory used for provisioning new machines.

### Metrics

Because RPM and Yum can be used to monitor changes made to any files, it's important to monitor the time the change is made.  This can be done two ways.  One such way is to report if a box has failed it's validation check, i.e. running rpm -V ??? or yum ???.  This sets a flag that the report agent can track.  This information is aggregated against all the nodes in your environment.  If one node has changed then it should stand out against those who haven't.  

Another metric to track is the mount of time its been since the configuration has been updated

Another metric to track is the number changes between what's currently installed and what's currently available.  Acceptable levels would be 1 change, anything else should be a warning or error.  

### Updating Configuration

### Rollback configuration

Much Needed Chapter



