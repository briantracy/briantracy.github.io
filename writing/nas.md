
# Building a NAS

**NOTE: This project is not done. I am having trouble initializing a ZFS file system on the completely empty seagate hard drives I bought**

This is a walk-through of how I created a local backup system for all of my computer files (schoolwork, photographs, movies, ...).

Here is a list prior knowledge (and acronyms) you should be aware of if you want to follow along.

1. [Network Attached Storage](https://en.wikipedia.org/wiki/Network-attached_storage) (NAS)
2. [Network File System](https://en.wikipedia.org/wiki/Network_File_System) (NFS)
3. [ZFS](https://en.wikipedia.org/wiki/ZFS)
4. [Redundant Array of Inexpensive Disks](https://en.wikipedia.org/wiki/RAID) (RAID)
5. [Raspberry Pi](https://en.wikipedia.org/wiki/Raspberry_Pi) (RPi)

### Equipment

1. Raspberry Pi Model 4B (4 GB on-board main memory)
2. 16 GB microSD card
3. 2x 1 TB Seagate 2.5" Disk Drive
4. 2x USB-3.0 -> 2.5" SATA connector

### Operating System

I chose to go with Ubuntu Server instead of Raspbian (what people normally put on an RPi) because ZFS requires a 64bit operating system to work. There have been problems in the past with 64bit operating systems, despite running on 64bit compatible chips, not being able to access the full 4GB of main memory on the RPi. This was recently solved by the folks who make Ubuntu, and the [19.x version of Ubuntu Server](https://ubuntu.com/download/raspberry-pi) incorporates the necessary patch.

### Flashing the OS

The RPi model 4 now has onboard memory that can store OS images, so the SD card is no longer necessary for every boot. However, the first time you boot up the computer, you need to provide an OS image on a microSD card for it to boot off.

### Remote Connection

```
$ sudo raspi-config
```

### Installing Software

### Connecting Hardware

### Configuring Software

https://wiki.ubuntu.com/ZFS/ZPool

### Classic macOS Moment

What do you think should happen when you try to connect to an NFS server via macOS and you get the host name correct, but misspell the mount point?

macOS thinks that an error of "permission denied" is the correct answer. I think that "no such mount point: %s" should be the correct answer. This would have saved me much time when attempting to connect to "nfs://10.0.0.86/mnt/nfs*s*share" instead of "nfs://10.0.0.86/mnt/nfsshare"



