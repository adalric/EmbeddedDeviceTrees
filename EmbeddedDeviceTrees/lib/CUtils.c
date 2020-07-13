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

uint8_t* getIM4P(uint8_t* binArray, size_t binArraySize, size_t* outSize){
    char base[50] = { 0x30, 0x30, 0x16, 0x04, 0x49, 0x4D, 0x34, 0x50, 0x16, 0x04, 0x64, 0x74, 0x72, 0x65, 0x16, 0x20, 0x45, 0x6D, 0x62, 0x65, 0x64, 0x64, 0x65, 0x64, 0x44, 0x65, 0x76, 0x69, 0x63, 0x65, 0x54, 0x72, 0x65, 0x65, 0x73, 0x2D, 0x34, 0x38, 0x31, 0x31, 0x2E, 0x31, 0x30, 0x30, 0x2E, 0x32, 0x36, 0x33, 0x04, 0x00 };
    
    size_t total;
    unsigned char xfer[4096];
    FHANDLE fd, src = memory_open(O_RDONLY, &base, 50);
    if (!src) {
        return NULL;
    }
    unsigned char *buf;
    total = src->length(src);
    fd = memory_open(O_RDWR, binArray, binArraySize);
    if (fd) {
        fd->ftruncate(fd, total);
        fd->lseek(fd, 0, SEEK_SET);
        for (;;) {
            ssize_t n, written;
            n = src->read(src, xfer, sizeof(xfer));
            if (n <= 0) {
                break;
            }
            written = fd->write(fd, xfer, n);
            if (written != n) {
                break;
            }
            total -= written;
        }
        if (total) {
            int rv = fd->ioctl(fd, IOCTL_MEM_GET_DATAPTR, &buf, outSize);
            fd->close(fd);
            fd = NULL;
            if (rv) {
                fprintf(stderr, "wops\n");
                return NULL;
            } else {
                return buf;
            }
        }
    }
    return NULL;
}
