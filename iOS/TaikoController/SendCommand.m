//
//  SendCommand.m
//  TaikoController
//
//  Created by Jack on 19/11/2016.
//  Copyright © 2016 Jack. All rights reserved.
//

#import <Foundation/Foundation.h>


enum {
    PTExampleFrameTypeDeviceInfo = 100,
    PTExampleFrameTypeTextMessage = 101,
    PTExampleFrameTypePing = 102,
    PTExampleFrameTypePong = 103,
};

typedef struct _TaikoCommandFrame {
    uint8_t value;
} TaikoCommandFrame;



static dispatch_data_t TaikoCommandFrameWithValue(uint8_t value) {
    // Use a custom struct
    TaikoCommandFrame *frame = CFAllocatorAllocate(nil, sizeof(TaikoCommandFrame), 0);
    frame->value = value;
    
    // Wrap the textFrame in a dispatch data object
    return dispatch_data_create((const void*)frame, sizeof(TaikoCommandFrame), nil, ^{
        CFAllocatorDeallocate(nil, frame);
    });
}
