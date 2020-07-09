//
//  CUtils.c
//  EmbeddedDeviceTrees
//
//  Created by Alexander Bradley on 7/6/20.
//  Copyright © 2020 Alexander Bradley. All rights reserved.
//

#include <stdio.h>
#include <libvfs/vfs.h>
#include <fcntl.h>
#include <string.h>

#include "CUtils.h"

uint8_t* read_from_file(const char* filename, size_t* size, unsigned* typeImg4, char** buildInfo) {
    FHANDLE fd = NULL;
    unsigned char *buf;
    int rv = 0;
    fd = img4_reopen(file_open(filename, O_RDONLY), NULL, 0);
    fd->ioctl(fd, IOCTL_IMG4_GET_TYPE, typeImg4);
    char *version;
    size_t length;
    rv = fd->ioctl(fd, IOCTL_IMG4_GET_VERSION, &version, &length);
    version[length]=0;
    memcpy(*buildInfo, version, length+1);
    rv = fd->ioctl(fd, IOCTL_MEM_GET_DATAPTR, &buf, size);
    if (rv) {
        fprintf(stderr, "wops\n");
        return NULL;
    } else {
        return buf;
    }
}
