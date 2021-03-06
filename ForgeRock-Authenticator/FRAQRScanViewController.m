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
 *
 * Portions Copyright 2013 Nathaniel McCallum, Red Hat
 */

#import "FRAError.h"
#import "FRAQRScanViewController.h"
#import "FRAIdentityDatabase.h"
#import "FRAMechanism.h"
#import "FRAMechanismReaderAction.h"
#import "FRAIdentity.h"

NSString * const FRAQRScanViewControllerStoryboardIdentifer = @"QRScanViewController";

@implementation FRAQRScanViewController

#pragma mark -
#pragma mark UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.session = [[AVCaptureSession alloc] init];
    AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    NSError* error;
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input) {
        self.session = nil;
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self.session addInput:input];

    AVCaptureVideoPreviewLayer* preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    preview.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:preview];

    [self.session startRunning];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    /* NOTE: We start output processing in viewDidAppear() to avoid a
     * race condition when the QR code is scanned before the view appears. */
    if (self.session) {
        AVCaptureMetadataOutput* output = [[AVCaptureMetadataOutput alloc] init];
        [self.session addOutput:output];
        [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    }
}

#pragma mark -
#pragma mark UINavigationController

-(BOOL)hidesBottomBarWhenPushed {
    return YES;
}

#pragma mark -
#pragma mark AVCaptureOutput

- (void)captureOutput:(AVCaptureOutput*)captureOutput didOutputMetadataObjects:(NSArray*)metadataObjects fromConnection:(AVCaptureConnection*) connection {
    for (AVMetadataObject *metadata in metadataObjects) {
        if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString* qrcode = [(AVMetadataMachineReadableCodeObject *)metadata stringValue];
            if (qrcode == nil) {
                continue;
            }
            NSLog(@"Read QR URL: %@", qrcode);
            
            [self setEditing:NO animated:YES];
            [self.mechanismReaderAction read:qrcode view:self.navigationController.view];
            [self.session stopRunning];
            if (self.popover == nil) {
                [self.navigationController popViewControllerAnimated:YES];
            } else {
                [self.popover dismissPopoverAnimated:YES];
            }
            return;
        }
    }
}

@end
