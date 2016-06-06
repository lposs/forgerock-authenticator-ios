/*
 * The contents of this file are subject to the terms of the Common Development and
 * Distribution License (the License). You may not use this file except in compliance with the
 * License.
 *
 * You can obtain a copy of the License at legal/CDDLv1.0.txt. See the License for the
 * specific language governing permission and limitations under the License.
 *
 * When distributing Covered Software, include this CDDL Header Notice in each file and include
 * the License file at legal/CDDLv1.0.txt. If applicable, add the following below the CDDL
 * Header, with the fields enclosed by brackets [] replaced by your own identifying
 * information: "Portions copyright [year] [name of copyright owner]".
 *
 * Copyright 2016 ForgeRock AS.
 */



#import "FRAIdentityDatabase.h"
#import "FRAMessageUtils.h"
#import "FRAModelObjectProtected.h"
#import "FRANotification.h"
#import "FRAPushMechanism.h"

/*!
 * All notifications are expected to be able to transition from the initial state
 * of pending, to the final state of approved or denied.
 */
@implementation FRANotification {
    NSDateFormatter *formatter;
    BOOL _approved;
    BOOL _pending;
}

@synthesize approved = _approved;
@synthesize pending = _pending;

static double const ONE_MINUTE_IN_SECONDS = 60.0;
static double const ONE_HOUR_IN_SECONDS = 3600.0;
static double const ONE_DAY_IN_SECONDS = 86400.0;
static double const TWO_DAYS_IN_SECONDS = 172800.0;
static double const ONE_WEEK_IN_SECONDS = 604800.0;
static NSString * const STRING_DATE_FORMAT = @"dd/MM/yyyy";

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive pending:(BOOL)pendingState approved:(BOOL)approvedState {
    self = [super initWithDatabase:database identityModel:identityModel];
    if (self) {
        _pending = pendingState;
        _approved = approvedState;
        
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:STRING_DATE_FORMAT];
        _messageId = messageId;
        _challenge = challenge;
        _timeReceived = timeReceived;
        _timeToLive = timeToLive;
        _timeExpired = [timeReceived dateByAddingTimeInterval:timeToLive];
    }
    return self;
}

- (instancetype)initWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive {
    return [self initWithDatabase:database identityModel:identityModel messageId:messageId challenge:challenge timeReceived:timeReceived timeToLive:timeToLive  pending:YES approved:NO];
}

+ (instancetype)notificationWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive pending:(BOOL)pendingState approved:(BOOL)approvedState{
    return [[FRANotification alloc] initWithDatabase:database identityModel:identityModel messageId:messageId challenge:challenge timeReceived:timeReceived timeToLive:timeToLive  pending:pendingState approved:approvedState];
}

+ (instancetype)notificationWithDatabase:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel messageId:(NSString *)messageId challenge:(NSString *)challenge timeReceived:(NSDate *)timeReceived timeToLive:(NSTimeInterval)timeToLive{
    return [[FRANotification alloc] initWithDatabase:database identityModel:identityModel messageId:messageId challenge:challenge timeReceived:timeReceived timeToLive:timeToLive  pending:YES approved:NO];
}

- (NSString *)age {
    NSTimeInterval age = [[NSDate date] timeIntervalSinceDate:self.timeReceived];
    if (age < ONE_MINUTE_IN_SECONDS) {
        return @"less than a minute ago";
    } else if (age < ONE_HOUR_IN_SECONDS) {
        // TODO: Handle "1 minutes ago" as a special case
        return [NSString stringWithFormat:@"%ld minutes ago", (long)((age/ONE_MINUTE_IN_SECONDS)+0.5)];
    } else if (age < ONE_DAY_IN_SECONDS) {
        // TODO: Handle "1 hours ago" as a special case
        return [NSString stringWithFormat:@"%ld hours ago", (long)(age / ONE_HOUR_IN_SECONDS)];
    } else if (age < TWO_DAYS_IN_SECONDS) {
        // TODO: Make this check more accurate, if it's 9am Tuesday then 2 days ago in seconds was 9am Sunday
        //       so time after 9am Sunday would be reported as "Yesterday" which is incorrect :-(
        return @"Yesterday";
    } else if (age < ONE_WEEK_IN_SECONDS) {
        // TODO: Handle "1 days ago" as a special case
        return [NSString stringWithFormat:@"%ld days ago", (long)(age / ONE_DAY_IN_SECONDS)];
    } else {
        return [formatter stringFromDate:self.timeReceived];
    }
}

- (BOOL)approveWithError:(NSError *__autoreleasing*)error {
    return [self sendAuthenticationResponse:YES withError:error];
}

- (BOOL)denyWithError:(NSError *__autoreleasing*)error {
    return [self sendAuthenticationResponse:NO withError:error];
}

- (BOOL)sendAuthenticationResponse:(BOOL)approved withError:(NSError *__autoreleasing*)error {
    _approved = approved;
    _pending = NO;
    if ([self isStored]) {
        if (![self.database updateNotification:self error:error]) {
            return NO;
        }
        FRAPushMechanism *mechanism = (FRAPushMechanism *)self.parent;
        if (mechanism) {
            NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
            data[@"response"] = [FRAMessageUtils generateChallengeResponse:self.challenge secret:mechanism.secret];
            if (!approved) {
                data[@"deny"] = @YES;
            }
            [FRAMessageUtils respondWithEndpoint:mechanism.authEndpoint
                                    base64Secret:mechanism.secret
                                       messageId:self.messageId
                                            data:data
                                         handler:^(NSInteger statusCode, NSError *error) {
                                             if (statusCode != 200) {
                                                 // TODO: Handle error
                                             }
                                         }];
        }
    }
    return YES;
}

- (BOOL)isPending {
    return _pending && ![self isExpired];
}

- (BOOL)isExpired {
    return _pending && [[NSDate date] timeIntervalSinceDate:_timeExpired] > 0;
}

- (BOOL)isApproved {
    return !_pending && _approved;
}

- (BOOL)isDenied {
    return !_pending && !_approved;
}

@end
