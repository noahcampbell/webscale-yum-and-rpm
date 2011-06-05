# Web Scale Yum and RPM - From the Trenches

Yum and RPM are extremely mature tools in the system provisioning tool chain.  However, I am often surprised to catch system administrators bluntly `rpm --force`ing a system into shape only to wonder later why a system can't install any new packages.  Perhaps the lost luster of time has made these tools opaque to the modern sysadmin.  Yum and RPM are not as glamorous as other provisioning tools, but they are both battle hardened and production ready for web scale operations.  These mature tools are incredibly powerful in the hands of skilled administrators, and this books intends to explain the essentials.

Surprisingly, we won't need to go deep into the inner workings Yum and RPM to get results.  What I intend to demonstrate is how Yum and RPM can be used to create a robust system and application provisioning tool chain for release engineers, software engineers and system administrators.  Using one tool throughout the process will shorten the DevOps gap between all parties.

Consider this your field guide to Yum and RPM for your web operations.  While it is generally acknowledge that Yum and RPM do a great job at provisioning a server or desktop provided their complex package dependencies, it almost never considered for packaging application software and even less so for configuration.  Often overlooking RPM for its ability to track change, administrators build complete configuration management systems that emulate RPM built in capability with varying degrees of success.  This field guide details how to use these tools to effectively package application code, deal with environment specific configuration and manage system application stacks.

The benefits of using packaging and distribution tools for system OS provisioning also apply to application code and configuration.  In terms of transparency, assigning version and release metadata to code and configuration increases traceability.  Code can declare dependency on configuration and the constraint system in RPM will prevent an old, or new, configuration from being installed.  This saves hours of tracking down bugs due to initial configuration.  Likewise, reproducing an entire system can be done quickly and consistently, extremely helpful for reproducing errors in offline environments or labs.  Finally, composing application stacks from packages reduces the provision time to near instantaneous, avoiding time consuming and error prone manual processes.

The scope of this field guide is limited to RPM based distributions.  I am aware of folks who have used RPM successfully on other platforms, namely Solaris, but that level of integration is beyond the scope of this guide.  It is also biased towards application stacks that use Yum and RPM to package and distribute their bits, PHP being a great example.  CPAN, gem, pip, npm all provide similar capabilities of RPM and Yum that can be construed as orthogonal, so integrating these two worlds together is reserved for another time.  Also, I do not to intend to discuss how to configure Yum for hosting distributions for world wide consumption as fedorahosted.org provides plenty of material.  Finally, I am not going to compare Yum and RPM to dpkg/aptitude, SYSV, or MSI packaging as they provide capabilities similar to Yum and RPM unique to their operating system.  Perhaps in a follow on series I can apply these same techniques using dpkg and aptitude.  Also, the scope of the book focuses on features that have been in yum and rpm for years.  I will provide references to newer tools in yum and rpm for those running more modern releases.

### Overview

01 - Introduction

### Getting Started

02 - **RPM** the indivisible unit of meta-data

03 - **RPM** for system engineers - How package dependencies define a stack

04 - **RPM** for developers - How to get your code in the package quick and easy.

05 - **Yum** logistics of distribution

### Tools in the tool chest

06 - **yum-utils** leveraging the tools deep in the tool chest
  - repoquery, repotrack

07 - **mirrorlists** scaling Yum is easy as scaling a website
  - explain how they work.

08 - **signing** policy meets implementation

09 - **SRPMs** Creating units of work

### The Yum and RPM Toolchain

10 - **Yum** Configuration Management
  - For Developers
  - For Release Engineers
  - For System Administrators

11 - **Validation** Know it works before releasing
  - Building the image offline.
  - Validating the proper configuration   
