//
//  UDPServerSocket.m
//  XL_UDPServer
//
//  Created by 李小龙 on 2020/4/16.
//  Copyright © 2020 李小龙. All rights reserved.
//

#import "UDPServerSocket.h"

@implementation UDPServerSocket

- (void)startListenClientSocketMessage{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    GCDAsyncUdpSocket * udpSocket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:queue];
    self.udpSocket = udpSocket;
    self.isSending = NO;
    // 关联端口,监听端口
    NSError * error;
    [udpSocket bindToPort:5279 error:&error];
    
    
    // 接受一次消息（启动一个等待接受，且只接收一次）
    [udpSocket receiveOnce:nil];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    NSString * ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    
    self.clientIP = ip;
    self.clientPort = port;
    
    NSLog(@"sock: %@  didConnectToAddress：ip:%@  port:%d",sock,ip,port);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    NSString * ip = [GCDAsyncUdpSocket hostFromAddress:address];
    uint16_t port = [GCDAsyncUdpSocket portFromAddress:address];
    
    self.clientIP = ip;
    self.clientPort = port;
    
    NSString * messgae = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    
    NSLog(@"sock: %@  接收到消息：ip:%@  port:%d  message:%@",sock,ip,port,messgae);
    if ([self.delegate respondsToSelector:@selector(serverSocketDidReceiveMessage:)]) {
        [self.delegate serverSocketDidReceiveMessage:messgae];
    }
    [self sendBackToHost:ip port:port message:@"***************************************************"];
    
    self.times ++;
//    NSLog(@"times:%ld",self.times);
    
    
    // 再次启动接收等待
    [self.udpSocket receiveOnce:nil];
}

- (void)sendMessage:(NSString *)message{
    [self.messageQueue addObject:message];
    if (!self.isSending) {
        [self sendBackToHost:self.clientIP port:self.clientPort message:message];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"sock: %@  服务端发送失败 %@",sock,[error description]);
    self.resendTimes ++;
    if (self.resendTimes == 4) {
        [self.messageQueue removeObject:self.currentSendingMessage];
        self.currentSendingMessage = nil;
        self.isSending = NO;
    }else{
        [self sendBackToHost:self.clientIP port:self.clientPort message:self.currentSendingMessage];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"sock: %@  服务端发送成功!   message:%@",sock,self.currentSendingMessage);
    [self.messageQueue removeObject:self.currentSendingMessage];
    self.isSending = NO;
    self.currentSendingMessage = nil;
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    NSLog(@"sock: %@  断开连接  %@",sock,[error description]);
}

- (void)sendBackToHost:(NSString *)ip port:(uint16_t)port message:(NSString *)message{
    self.currentSendingMessage = message;
    self.isSending = YES;
    NSData * data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.udpSocket sendData:data toHost:ip port:port withTimeout:-1 tag:0];
}

- (void)setIsSending:(BOOL)isSending{
    _isSending = isSending;
    if (!isSending && self.messageQueue.count) {
        [self sendBackToHost:self.clientIP port:self.clientPort message:[self.messageQueue firstObject]];
    }
}

- (NSMutableArray *)messageQueue{
    if (!_messageQueue) {
        _messageQueue = [[NSMutableArray alloc]init];
    }return _messageQueue;
}
@end
