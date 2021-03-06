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

#import "FRAMechanism.h"
#import "FRAIdentityModel.h"

#ifndef FRAMechanismFactory_h
#define FRAMechanismFactory_h


#endif /* FRAMechanismFactory_h */

@protocol FRAMechanismFactory

/*!
 * Build a FRA Mechanism object using the database and the model provided
 *
 * @param uri The uri string containing the mechanism information.
 * @param database The database to persist the new mechanism to.
 * @param identityModel The identity model to place the new mechanism into.
 * @param handler The block to invoke when asynchronous operation is completed.
 * @param error If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 * @return The mechanism built from the uri.
 */
- (FRAMechanism *) buildMechanism:(NSURL *)uri database:(FRAIdentityDatabase *)database identityModel:(FRAIdentityModel *)identityModel handler:(void (^)(BOOL, NSError *))handler error:(NSError *__autoreleasing *)error;

/*!
 * Gets whether this FRAMechanismFactory supports the mechnaism type in the given uri
 *
 * @param uri the uri string contianing the mechanism informaiton
 */
- (bool) supports:(NSURL *)uri;

/*!
 * Gets the supproted protocol for the FRAMechanism FRAMechanismFactory
 */
- (NSString *) getSupportedProtocol;

@end