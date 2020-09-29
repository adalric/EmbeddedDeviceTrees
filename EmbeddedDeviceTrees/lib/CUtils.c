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
    unsigned char _tmp_out_im4p[] = {
      0x30, 0x36, 0x16, 0x04, 0x49, 0x4d, 0x34, 0x50, 0x16, 0x04, 0x64, 0x74,
      0x72, 0x65, 0x16, 0x20, 0x45, 0x6d, 0x62, 0x65, 0x64, 0x64, 0x65, 0x64,
      0x44, 0x65, 0x76, 0x69, 0x63, 0x65, 0x54, 0x72, 0x65, 0x65, 0x73, 0x2d,
      0x34, 0x38, 0x31, 0x31, 0x2e, 0x31, 0x30, 0x30, 0x2e, 0x32, 0x36, 0x33,
      0x04, 0x06, 0x45, 0x4d, 0x50, 0x54, 0x59, 0x0a
    };
    unsigned int _tmp_out_im4p_len = 56;
    
    size_t total, sz;
    unsigned char *buf;
    unsigned char xfer[4096];
    FHANDLE fd, src = memory_open(O_RDONLY, _tmp_out_im4p, _tmp_out_im4p_len);
    if (!src) {
        return NULL;
    }
    total = src->length(src);
//    FHANDLE orig = memory_open(O_RDWR, binArray, binArraySize);
//    if (orig == NULL) {
//        src->close(src);
//        return NULL;
//    }
    fd = img4_reopen(memory_open(O_RDWR, binArray, binArraySize), NULL, FLAG_IMG4_SKIP_DECOMPRESSION);
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
            fd->close(fd);
            fd = NULL;
        }
    }
    src->close(src);
    int rv = fd->ioctl(fd, IOCTL_MEM_GET_DATAPTR, &buf, &sz);
    if (rv) {
        fprintf(stderr, "[e] cannot retrieve data\n");
    } else {
        *outSize = sz;
        return buf;
    }
    return NULL;
    
//    FILE *fp, *fo;
//    FHANDLE fd, orig = NULL;
//    unsigned char *buf;
//    size_t sz;
//
//    fp = fopen("/tmp/base.im4p", "w+");
//    fwrite(_tmp_out_im4p, 1, _tmp_out_im4p_len, fp);
//    fclose(fp);
//
//    fo = fopen("/tmp/data-input.raw", "w+");
//    fwrite(binArray, 1, binArraySize, fo);
//    fclose(fp);
//
//    fd = replace_img4("/tmp/base.im4p", "/tmp/data-input.raw", &orig);
//    int rv = orig->ioctl(orig, IOCTL_MEM_GET_DATAPTR, &buf, &sz);
//    if (rv) {
//        fprintf(stderr, "[e] cannot retrieve data\n");
//    } else {
//        *outSize = sz;
//        return buf;
//    }
//    return NULL;
}
