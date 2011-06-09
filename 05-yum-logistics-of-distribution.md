
# Yum - Logistics of Distribution

## Yum - Standing on the shoulders of RPM

Up to this point, I have covered only RPMs and alluded to yum, especially for dependency management.  RPM by itself introduces what is commonly referred to as dependency hell when trying to install your latest rpm that has many transitive dependencies.  This stigma still haunts it today, but typically among the un-initiated.  Yum alleviates this burden by providing the dependency resolution for you automatically.  Yum + RPM is extremely powerful and ready for webscale applications.

## The end to dependency hell

Yum keeps an index of all the RPMs in a repository.  This index is then consulted when yum attempts to solve any dependencies a rpm may have.  By associating what a repository has and where to find a particular rpm, Yum addressed dependency hell and made life much easier for the system administrator.  But Yum didn't stop there.

What Yum also provides is a way to aggregate many repositories into a single consolidated view.  Looking at Fedora Core 14, I find the following repositories that are currently visible:

    [noahcampbell@vm-fedora-02 beagle]$ yum repolist
    Loaded plugins: langpacks, presto, refresh-packagekit
    Adding en_US to language list
    repo id                       repo name                                  status
    fedora                        Fedora 14 - x86_64                         22,161
    google-chrome                 google-chrome                                   3
    rundeck-release               Rundeck - Release                               4
    updates                       Fedora 14 - x86_64 - Updates                7,325
    repolist: 29,493

There are four repos listed: fedora, google-chrome, rundeck-release, and updates.  The google and rundeck repositories are ones I added by installing those two pieces of software.  fedora and updates comes from Fedora.

Note earlier that I said currently visible.  If I modify my command slightly and elevate my privileges I see:

    [noahcampbell@vm-fedora-02 beagle]$ sudo yum --enablerepo='*' repolist
    Loaded plugins: langpacks, presto, refresh-packagekit
    Adding en_US to language list
    repo id                      repo name                                   status
    fedora                       Fedora 14 - x86_64                          22,161
    fedora-debuginfo             Fedora 14 - x86_64 - Debug                   5,333
    fedora-source                Fedora 14 - Source                               0
    google-chrome                google-chrome                                    3
    rundeck-bleeding             Rundeck - Bleeding Edge                          3
    rundeck-release              Rundeck - Release                                4
    rundeck-updates              Rundeck - Updates                                0
    updates                      Fedora 14 - x86_64 - Updates                 7,325
    updates-debuginfo            Fedora 14 - x86_64 - Updates - Debug         1,385
    updates-source               Fedora 14 - Updates Source                       0
    updates-testing              Fedora 14 - x86_64 - Test Updates            1,422
    updates-testing-debuginfo    Fedora 14 - x86_64 - Test Updates Debug        207
    updates-testing-source       Fedora 14 - Test Updates Source                  0
    repolist: 37,843

I see quite a different view.  An additional 8000+ packages are not available for installation via yum.

What yum is doing every time it runs, is merging the indexes of all the repos it knows about before searching for any dependencies.  The character of a system managed by yum is defined by where it draws it packages.

## Configuring Yum

Where do these repo definitions get configured?  The requisite files are found in `/etc/yum.conf` and `/etc/yum.repos.d/*.conf`.  Each .conf file in /etc/yum.repos.d/ contains a collection of repository definitions that looks like:

    [noahcampbell@vm-fedora-02 beagle]$ cat /etc/yum.repos.d/rundeck.repo 
    [rundeck-release]
    name=Rundeck - Release
    baseurl=http://rundeck.org/repo/rundeck/1/release
    gpgkey=http://rundeck.org/repo/RPM-GPG-KEY-RunDeck.org
    gpgcheck=0

    [rundeck-updates]
    name=Rundeck - Updates
    baseurl=http://rundeck.org/repo/rundeck/1/updates
    gpgkey=http://rundeck.org/repo/RPM-GPG-KEY-RunDeck.org
    gpgcheck=0
    enabled=0

    [rundeck-bleeding]
    name=Rundeck - Bleeding Edge
    baseurl=http://rundeck.org/repo/rundeck/1/bleedingedge
    gpgcheck=0
    enabled=0

An INI file format with properties set to describe the repository, the INI section id.  The key thing to point out is that the baseurl is a url, in this case http.  That means the repo can be located across the globe on some server, or more realistically, on a set of machines in your datacenter.  This means Yum is a distribution model for packages.  A model that can be exploited to our very needs.

## Web Scale Distribution

If you have not already noticed, the url that hosts the package repositories is an HTTP url (other protocols are available).  Given that the metadata and the package themselves are static files, the distribution of packages can leverage the plethora of scaling choices available to content web servers.  Apache HTTPd provides a great platform hosting this data.  Proxies like squid and varnish can allow for packages to be cached and served closer to the server, offloading central or seed servers.  

Within Yum, plugins like presto reduce the payload size, further streamlining the distribution of packages.

The difference between yum for distros and yum for webscale deployment is the frequency that the metadata updates.  The default cache expiry of metadata is 1.5 hours.  This is typically not satisfactory for continuous deployment.  Setting this to 1 minute or 0 is completely acceptable for your repositories.  Remember to keep the distro repositories set to something respectful, unless you mirror those repos and are changing them, not recommend, frequently.

