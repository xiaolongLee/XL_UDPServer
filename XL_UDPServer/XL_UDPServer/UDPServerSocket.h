//
//  UDPServerSocket.h
//  XL_UDPServer
//
//  Created by 李小龙 on 2020/4/16.
//  Copyright © 2020 李小龙. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "GCDAsyncUdpSocket.h"

@protocol UDPServerSocketDelegate <NSObject>

- (void)serverSocketDidReceiveMessage:(NSString *)message;

@end

@interface UDPServerSocket : NSObject <GCDAsyncUdpSocketDelegate>

@property (nonatomic, weak)id <UDPServerSocketDelegate>delegate;

@property (nonatomic, strong)GCDAsyncUdpSocket * udpSocket;

@property (nonatomic, copy)NSString * clientIP;
@property (nonatomic, assign)uint16_t clientPort;
@property (nonatomic, assign)BOOL isSending;
@property (nonatomic, strong)NSMutableArray * messageQueue;
@property (nonatomic, copy)NSString * currentSendingMessage;
@property (nonatomic,assign)NSInteger times;
@property (nonatomic,assign)NSInteger resendTimes;

- (void)startListenClientSocketMessage;

- (void)sendMessage:(NSString *)message;

@end
