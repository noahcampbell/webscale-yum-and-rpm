# Web Scale Yum and RPM - From the Dev2Ops Trenches

Yum and RPM are extremely mature, yet surprisingly mysterious, pieces to the system provisioning tool chain.  Yum and RPM are not as glamorous as some other provisioning tools currently in vogue and each tool has its warts, but they are battle hardened by over a decade of use in production systems.  

What is surprising is that most users of Yum and RPM barely scratch the surface of what these two tools can provide, often spending a great deal of time and energy emulating their capability with mixed success.  I am not about to compare Yum and RPM to dpkg/aptitude, SYSV, or MSI packaging as they provide capabilities similar to Yum and RPM plus those unique to their operating system.  Perhaps in a follow on series I can apply these same techniques using dpkg and aptitude.  What I intend to demonstrate is how Yum and RPM can be used to create a robust system provisioning tool chain for release engineers, software engineers and system administrators that helps bridge the DevOps gap.

Consider this as your field guide to using Yum and RPM in your web operations.  While its generally acknowledge that Yum and RPM do a great job at provisioning a server or desktop and its complex dependencies, it almost never considered for packaging application software and even less so for configuration.  RPM is often overlooked for its ability to track change and can be a powerful tool for configuration management.  This field guide details how to use these tools to effectively package application code, deal with environment specific configuration and manage application stacks.

The benefits of using packaging and distribution tools for system OS provisioning also apply to application code and configuration.  In terms of transparency, assigning version and release metadata to code and configuration open to door to traceability of what code is using what configuration.  Code can declare dependency on configuration and the constraint system in RPM will prevent an invalid configuration from being installed saving countless hours of tracing down configuration issues.  Likewise, reproducing an entire system can be done quickly and consistently, extremely helpful for reproducing errors in other environments.  Finally, composing application stacks from packages reduces the provision time to near instantaneous avoid time consuming and error prone manual approaches.

The scope of this field guide is limited to RPM based distributions.  I am aware of folks who have used RPM successfully on other platforms, namely Solaris, but that level of integration is beyond the scope of this guide.  It is also biased towards application stacks that use Yum and RPM to package and distribute their bits, PHP being a great example.  CPAN, gem, pip, npm all provide similar capabilities of RPM and Yum that can be construed as orthogonal, so integrate these two worlds together is not covered as well.  Also, I do not to intend to discuss how to configure Yum for hosting distributions for world wide consumption.

### Overview

01 - Introduction

### Getting Started

02 - **RPM** the indivisible unit of meta-data

03 - **RPM** for system engineers - How package dependencies define a stack

04 - **RPM** for developers - How to get your code in the package quick and easy.

05 - **Yum** logistics of distribution

### Tools in the tool chest

06 - **yum-utils** leveraging the tools deep in the tool chest

07 - **mirrorlists** scaling Yum is easy as scaling a website

08 - **signing** policy meets implementation

### Establishing the Tool Chain

09 - **Yum** virtual packages and configuration

10 - **Validation** Know it works before releasing

11 - **Package Factory** Koji

12 - **Repo Maintenance** Introducing package-transfer
