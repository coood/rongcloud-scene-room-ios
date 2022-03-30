
#import <RongIMLibCore/RongIMLibCore.h>

@interface RCChatroomEnter : RCMessageContent

/**
 用户 Id
*/
@property(nonatomic, copy, nonnull) NSString *userId;

/**
 用户名称
*/
@property(nonatomic, copy, nonnull) NSString *userName;

@end
