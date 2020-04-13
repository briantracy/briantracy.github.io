
# Creating a NAS

Here are all the acronyms: I made a NAS that communicates via NFS to store files via ZFS on two HDDs in a RAID-1 configuration.

### Equipment

1. Raspberry Pi Model 4B (4 GB on-board main memory)
2. 16 GB microSD card
3. 2x 1 TB Seagate 2.5" Disk Drive
4. 2x USB-3.0 -> 2.5" SATA connector


### Classic macOS Moment

What do you think should happen when you try to connect to an NFS server via macOS and you get the host name correct, but misspell the mount point?

macOS thinks that an error of "permission denied" is the correct answer. I think that "no such mount point: %s" should be the correct answer. This would have saved me much time when attempting to connect to "nfs://10.0.0.86/mnt/nfs*s*share" instead of "nfs://10.0.0.86/mnt/nfsshare"



