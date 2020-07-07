//
//  CUtils.h
//  EmbeddedDeviceTrees
//
//  Created by Alexander Bradley on 7/6/20.
//  Copyright © 2020 Alexander Bradley. All rights reserved.
//

#ifndef CUtils_h
#define CUtils_h

#include <libvfs/vfs.h>

uint8_t* read_from_file(const char* filename, size_t* size, char* typeImg4, char* buildInfo);

#endif /* CUtils_h */
