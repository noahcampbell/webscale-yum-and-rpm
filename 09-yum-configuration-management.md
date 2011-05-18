Configuration management is often tossed around as something that is desperately needed but push on what it is, and there is little to find.  I present in this chapter a solution for configuration management using only yum and rpm.  

This is a solution that requires coordination across development, release engineering and system administration, but does accommodate configuration management in a methodical and repeatable process.  Because the simplicity of the approach, it is often overlooked, but in its simplicity, it quite reliable and flexible.

# For Developers

A developer must build with configuration in mind.  This is often not done, or considered as an afterthought.  At the time of this writing, finding any patterns for developers to follow on configuration is not easy.  It is masked by software configuration management, which is about managing change within source code.  It doesn't address what happens once software is released into staging, production.

These are the patterns I found to be most helpful and not intended as an exhaustive list.

## The .properties or .ini or .yaml

All configuration needs to be stored in a text file using key value properties or more exotic formats like yaml.  I did not list JSON or XML.  It is natural for developers to gravitate towards XML because the tooling support within the language is typically very robust.  However, consider the primary expert users of your software are not "in" the language when they have to change the configuration.  They're toolchain consists of text editors like vi and tools like sed, awk, grep, etc.  These are all line orientated tools.  XML and JSON are block orientated and therefore present a mismatch between two users.

Keeping the configuration in line orientated file formats make managing the configuration easier downstream.

## The conf.d directory

Configuration files that are hard coded in the application pose a potential challenge when maintaining the configuration using the package centric approach.

The requirement is that configuration is read from a directory following some pattern.  For example, /etc/app/conf.d/*.conf.  The specific rules of how the files are evaluated, sorted order, timestamp, etc. is not really important as long as it is done consistently.

In bash

    for config in $(find /etc/app/conf.d -maxdepth 1 -type f -name \*.conf); do source ${config}; done

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

# Additional patterns

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

# Additional Considerations

  * Keep the configuration as concise as possible.  
  * Provide units of measure.  
  * Provide acceptable ranges.  
  * Provide explanation around magic values (0 means unlimited).
  * Provide example configurations 

# For Release Engineers



# For System Administrators