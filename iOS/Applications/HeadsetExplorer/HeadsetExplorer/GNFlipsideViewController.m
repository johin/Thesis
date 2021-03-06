//
//  GNFlipsideViewController.m
//  HeadsetExplorer
//
//  Created by Lars Johansen on 03/06/13.
//  Copyright (c) 2013 GN Store Nord A/S. All rights reserved.
//

#import "GNFlipsideViewController.h"
#import "GNSoftwareUpdateViewController.h"
#import "GNAppDelegate.h"
#import "NSString+IHSDeviceConnectionState.h"

typedef enum
{
    SectionTypeGPS,
    SectionTypeSensorData,
    SectionTypeDeviceInfo,
    SectionTypeMap,
    SectionTypeCount
} SectionType;

typedef enum
{
    // Map section:
    SectionItemMapType = 0,
    SectionItemMapNorthAnnotation,
    SectionItemMapSouthAnnotation,
    SectionItemMapCount,
    
    // GPS section:
    SectionItemGPSLatitude = 0,
    SectionItemGPSLongitude,
    SectionItemGPSHorizAccuracy,
    SectionItemGPSFusedHeading,
    SectionItemGPSCompassHeading,
    SectionItemGPSCount,
    
    // SensorData section:
    SectionItemSensorDataMagneticFieldStrength = 0,
    SectionItemSensorDataMagneticDisturbance,
    SectionItemSensorDataGyroCalibrationStatus,
    SectionItemSensorDataPitch,
    SectionItemSensorDataRoll,
    SectionItemSensorDataYaw,
    SectionItemSensorDataAccelerometerX,
    SectionItemSensorDataAccelerometerY,
    SectionItemSensorDataAccelerometerZ,
    SectionItemSensorDataCount,

    // DeviceInfo section:
    SectionItemDeviceInfoName = 0,
    SectionItemDeviceInfoConnectionState,
    SectionItemDeviceInfoFirmwareRevision,
    SectionItemDeviceInfoHardwareRevision,
    SectionItemDeviceInfoSoftwareRevision,
    SectionItemDeviceInfoAPIVersion,
    SectionItemDeviceInfoCount,

} SectionItem;

typedef enum
{
    ActionSheetTypeMapType = 1,
    ActionSheetTypeActionsConnected,
    ActionSheetTypeActionsDisconnected,
} ActionSheetType;


@interface GNFlipsideViewController () < UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, GNSoftwareUpdateViewControllerDelegate >

@property (weak, nonatomic) IBOutlet UITableView *tableview;
@property (strong, nonatomic) NSTimer*  updateTimer;
@property (strong, nonatomic) NSMutableDictionary* indexPathToValue;
@property (weak, nonatomic) UIPopoverController*    swupdatePopoverController;

@end

@implementation GNFlipsideViewController {
    UIActionSheet*  _connectionActionSheet;
}

- (void)awakeFromNib
{
    self.contentSizeForViewInPopover = CGSizeMake(320.0, 900.0);
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.indexPathToValue = [NSMutableDictionary new];
}


- (void)viewWillAppear:(BOOL)animated
{
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateContent:) userInfo:nil repeats:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [self dismissConnectionActionSheet];
}


- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.updateTimer invalidate];
    self.updateTimer = nil;
}


- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}


#pragma mark - Actions

- (IBAction)done:(id)sender
{
    [self.delegate flipsideViewControllerDidFinish:self];
}

#pragma mark - Public methods

- (void)ihsDevice:(IHSDevice*)ihsDevice connectedStateChanged:(IHSDeviceConnectionState)connectionState
{
    // Dismiss the connection action sheet if the connection state changes while the action sheet is shown
    [_connectionActionSheet dismissWithClickedButtonIndex:0 animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return SectionTypeCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((SectionType)section)
    {
        case SectionTypeMap:           return SectionItemMapCount;
        case SectionTypeGPS:           return SectionItemGPSCount;
        case SectionTypeDeviceInfo:    return SectionItemDeviceInfoCount;
        case SectionTypeSensorData:    return SectionItemSensorDataCount;

        case SectionTypeCount:         return 0;
    }

    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ((SectionType)section)
    {
        case SectionTypeMap:           title = @"Map setup";               break;
        case SectionTypeGPS:           title = @"Position and heading";    break;
        case SectionTypeDeviceInfo:    title = @"Device info";             break;
        case SectionTypeSensorData:    title = @"Sensor data";             break;

        case SectionTypeCount:                                             break;
    }

    return title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString*   reuseIdentifier = @"text_value_cell";

    if (indexPath.section == SectionTypeMap) {
        if ((indexPath.row == SectionItemMapNorthAnnotation) ||
            (indexPath.row == SectionItemMapSouthAnnotation)) {
            reuseIdentifier = @"text_switch_cell";
        }
    }

    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];

    cell.accessoryType = UITableViewCellAccessoryNone;

    [self updateCell:cell atIndexPath:indexPath];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell ?: [UITableViewCell new];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section)
    {
        case SectionTypeMap:
            if (SectionItemMapType == indexPath.row) {
                UIActionSheet*  as = [[UIActionSheet alloc] initWithTitle:@"Select map type"
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:nil
                                                        otherButtonTitles:@"Standard", @"Hybrid", @"Satellite", nil
                                      ];
                as.tag = ActionSheetTypeMapType;
                [as showInView:self.view];
            }
            break;
        default:
            break;
    }
}

#pragma mark - Actions, UIActionSheetDelegate
- (void) switchChanged:(id)sender
{
    UISwitch*   theSwitch = sender;

    NSLog(@"Switch with tag %ld changed to %d", (long)theSwitch.tag, theSwitch.on);

    switch (theSwitch.tag)
    {
        case SectionItemMapNorthAnnotation:
            self.playNorthSound = theSwitch.on;
            break;

        case SectionItemMapSouthAnnotation:
            self.playSouthSound = theSwitch.on;
            break;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == ActionSheetTypeMapType) {
        switch (buttonIndex)
        {
            case 0:
                self.mapType = MKMapTypeStandard;
                break;
            case 1:
                self.mapType = MKMapTypeHybrid;
                break;
            case 2:
                self.mapType = MKMapTypeSatellite;
                break;
        }

        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:SectionItemMapType inSection:SectionTypeMap];
        [self.tableview reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if (actionSheet.tag == ActionSheetTypeActionsDisconnected) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // Manually present the IHS device selection UI
            [self.delegate flipsideViewControllerManuallyConnectWasSelected:self];
        }
    }
    else if (actionSheet.tag == ActionSheetTypeActionsConnected) {
        if (buttonIndex == actionSheet.destructiveButtonIndex) {
            // Reset the IHS device connection
            [APP_DELEGATE resetDeviceConnection];
            [self.delegate flipsideViewControllerDidResetConnection:self];
        }
        else if (buttonIndex == 1) {
            [self performSegueWithIdentifier:@"swupdate_segue" sender:self];
        }
    }
}

#pragma mark - utilities

- (void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    switch ((SectionType)indexPath.section)
    {
        case SectionTypeMap:
            switch ((SectionItem)indexPath.row)
        {
            case SectionItemMapType:
                cell.textLabel.text = @"Map type";
                switch (self.mapType)
            {
                case MKMapTypeStandard:
                    cell.detailTextLabel.text = @"Standard";
                    break;
                case MKMapTypeHybrid:
                    cell.detailTextLabel.text = @"Hybrid";
                    break;
                case MKMapTypeSatellite:
                    cell.detailTextLabel.text = @"Satellite";
                    break;
            }

                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;

            case SectionItemMapNorthAnnotation:
            {
                cell.textLabel.text = @"North sound";
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                cell.accessoryView = switchView;
                switchView.tag = SectionItemMapNorthAnnotation;
                switchView.on = self.playNorthSound;
                [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                break;
            }

            case SectionItemMapSouthAnnotation:
            {
                cell.textLabel.text = @"South sound";
                UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                cell.accessoryView = switchView;
                switchView.tag = SectionItemMapSouthAnnotation;
                switchView.on = self.playSouthSound;
                [switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
                break;
            }

            default:
                break;
        }

            break;

        case SectionTypeGPS:
            switch ((SectionItem)indexPath.row)
        {
            case SectionItemGPSLatitude:
                cell.textLabel.text = @"Latitude";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.6f °", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemGPSLongitude:
                cell.textLabel.text = @"Longitude";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.6f °", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemGPSFusedHeading:
                cell.textLabel.text = @"Fused heading";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f °", [[self valueForRowAtIndexPath:indexPath] floatValue] ];
                break;
            case SectionItemGPSCompassHeading:
                cell.textLabel.text = @"Compass heading";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f °", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemGPSHorizAccuracy:
                cell.textLabel.text = @"Horiz accuracy";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%.1f m", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;

            default:
                break;
        }
            break;


        case SectionTypeSensorData:
            switch ((SectionItem)indexPath.row)
        {
            case SectionItemSensorDataMagneticFieldStrength:
                cell.textLabel.text = @"Magnetic field strength";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%d mG", [[self valueForRowAtIndexPath:indexPath] integerValue]];
                break;
            case SectionItemSensorDataMagneticDisturbance:
                cell.textLabel.text = @"Magnetic disturbance";
                cell.detailTextLabel.text = [self valueForRowAtIndexPath:indexPath];
                break;
            case SectionItemSensorDataGyroCalibrationStatus:
                cell.textLabel.text = @"Gyro calibrated";
                cell.detailTextLabel.text = [self valueForRowAtIndexPath:indexPath];
                break;
            case SectionItemSensorDataPitch:
                cell.textLabel.text = @"Pitch";
                cell.detailTextLabel.text =  [NSString stringWithFormat:@"%.1f °", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemSensorDataRoll:
                cell.textLabel.text = @"Roll";
                cell.detailTextLabel.text =  [NSString stringWithFormat:@"%.1f °", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemSensorDataYaw:
                cell.textLabel.text = @"Yaw";
                cell.detailTextLabel.text =  [NSString stringWithFormat:@"%.1f °", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemSensorDataAccelerometerX:
                cell.textLabel.text = @"Accelerometer X";
                cell.detailTextLabel.text =  [NSString stringWithFormat:@"%.2f G", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemSensorDataAccelerometerY:
                cell.textLabel.text = @"Accelerometer Y";
                cell.detailTextLabel.text =  [NSString stringWithFormat:@"%.2f G", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;
            case SectionItemSensorDataAccelerometerZ:
                cell.textLabel.text = @"Accelerometer Z";
                cell.detailTextLabel.text =  [NSString stringWithFormat:@"%.2f G", [[self valueForRowAtIndexPath:indexPath] floatValue]];
                break;

            default:
                break;
        }
            break;

        case SectionTypeDeviceInfo:
            switch ((SectionItem)indexPath.row)
        {
            case SectionItemDeviceInfoName:
                cell.textLabel.text = @"Name";
                cell.detailTextLabel.text = APP_DELEGATE.ihsDevice.name;
                break;
            case SectionItemDeviceInfoConnectionState:
                cell.textLabel.text = @"State";
                cell.detailTextLabel.text = [NSString stringFromIHSDeviceConnectionState:APP_DELEGATE.ihsDevice.connectionState];
                break;
            case SectionItemDeviceInfoFirmwareRevision:
                cell.textLabel.text = @"Firmware";
                cell.detailTextLabel.text = APP_DELEGATE.ihsDevice.firmwareRevision;
                break;
            case SectionItemDeviceInfoHardwareRevision:
                cell.textLabel.text = @"Hardware";
                cell.detailTextLabel.text = APP_DELEGATE.ihsDevice.hardwareRevision;
                break;
            case SectionItemDeviceInfoSoftwareRevision:
                cell.textLabel.text = @"Software";
                cell.detailTextLabel.text = APP_DELEGATE.ihsDevice.softwareRevision;
                break;
            case SectionItemDeviceInfoAPIVersion:
                cell.textLabel.text = @"API version";
                cell.detailTextLabel.text = APP_DELEGATE.ihsDevice.apiVersion;
                break;

            default:
                break;
        }
            break;

        case SectionTypeCount:
            // Here to avoid compiler warnings
            break;
    }
}


- (id) valueForRowAtIndexPath:(NSIndexPath*)indexPath
{
    id  result;

    switch ((SectionType)indexPath.section)
    {
        case SectionTypeMap:
            break;

        case SectionTypeGPS:
            switch ((SectionItem)indexPath.row) {
                case SectionItemGPSLatitude:
                    result = isnan(APP_DELEGATE.ihsDevice.horizontalAccuracy) ? @(NAN) : @(APP_DELEGATE.ihsDevice.latitude);
                    break;
                case SectionItemGPSLongitude:
                    result = isnan(APP_DELEGATE.ihsDevice.horizontalAccuracy) ? @(NAN) : @(APP_DELEGATE.ihsDevice.longitude);
                    break;
                case SectionItemGPSFusedHeading:
                    result = @(APP_DELEGATE.ihsDevice.fusedHeading);
                    break;
                case SectionItemGPSCompassHeading:
                    result = @(APP_DELEGATE.ihsDevice.compassHeading);
                    break;
                case SectionItemGPSHorizAccuracy:
                    result = @(APP_DELEGATE.ihsDevice.horizontalAccuracy);
                    break;

                default:
                    break;
            }
            break;

        case SectionTypeSensorData:
            switch ((SectionItem)indexPath.row) {
                case SectionItemSensorDataMagneticFieldStrength:
                    result = @(APP_DELEGATE.ihsDevice.magneticFieldStrength);
                    break;
                case SectionItemSensorDataMagneticDisturbance:
                    result = APP_DELEGATE.ihsDevice.magneticDisturbance ? @"Yes" : @"No";
                    break;
                case SectionItemSensorDataGyroCalibrationStatus:
                    result = APP_DELEGATE.ihsDevice.gyroUncalibrated ? @"No" : @"Yes";
                    break;
                case SectionItemSensorDataPitch:
                    result = @(APP_DELEGATE.ihsDevice.pitch);
                    break;
                case SectionItemSensorDataRoll:
                    result = @(APP_DELEGATE.ihsDevice.roll);
                    break;
                case SectionItemSensorDataYaw:
                    result = @(APP_DELEGATE.ihsDevice.yaw);
                    break;
                case SectionItemSensorDataAccelerometerX:
                    result = @(APP_DELEGATE.ihsDevice.accelerometerData.x);
                    break;
                case SectionItemSensorDataAccelerometerY:
                    result = @(APP_DELEGATE.ihsDevice.accelerometerData.y);
                    break;
                case SectionItemSensorDataAccelerometerZ:
                    result = @(APP_DELEGATE.ihsDevice.accelerometerData.z);
                    break;

                default:
                    break;
            }
            break;

        case SectionTypeDeviceInfo:
            switch ((SectionItem)indexPath.row) {
                case SectionItemDeviceInfoName:
                    result = APP_DELEGATE.ihsDevice.name;
                    break;
                case SectionItemDeviceInfoConnectionState:
                    result = [NSString stringFromIHSDeviceConnectionState:APP_DELEGATE.ihsDevice.connectionState];
                    break;
                case SectionItemDeviceInfoFirmwareRevision:
                    result = APP_DELEGATE.ihsDevice.firmwareRevision;
                    break;
                case SectionItemDeviceInfoHardwareRevision:
                    result = APP_DELEGATE.ihsDevice.hardwareRevision;
                    break;
                case SectionItemDeviceInfoSoftwareRevision:
                    result = APP_DELEGATE.ihsDevice.softwareRevision;
                    break;
                case SectionItemDeviceInfoAPIVersion:
                    // No updates for these.
                    break;

                default:
                    break;
            }
            break;


        default:
            break;
    }

    return result;
}


- (BOOL) shouldUpdateCellAtIndexPath:(NSIndexPath*)indexPath
{
    BOOL    shouldUpdate = NO;
    id      value        = [self valueForRowAtIndexPath:indexPath];
    id      lastValue    = self.indexPathToValue[indexPath];

    if (value) {
        if (![lastValue isEqual:value]) {
            shouldUpdate = YES;
        }

        self.indexPathToValue[indexPath] = value;
    }

    return shouldUpdate;
}


- (BOOL)shouldUpdateCellAtRow:(NSInteger)row inSection:(NSInteger)section withValue:(id)value
{
    return [self shouldUpdateCellAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
}


- (void)updateContent:(NSTimer*)theTimer
{
    for (UITableViewCell* visibleCell in [self.tableview visibleCells]) {
        NSIndexPath* indexPath = [self.tableview indexPathForCell:visibleCell];
        if ([self shouldUpdateCellAtIndexPath:indexPath]) {
            [self updateCell:visibleCell atIndexPath:indexPath];
        }
    }
}


- (void)dismissConnectionActionSheet
{
    _connectionActionSheet.delegate = nil;
    [_connectionActionSheet dismissWithClickedButtonIndex:0 animated:YES];
    _connectionActionSheet = nil;
}


- (IBAction)onActionClicked:(id)sender
{
    if (APP_DELEGATE.ihsDevice.connectionState == IHSDeviceConnectionStateConnecting ||
        APP_DELEGATE.ihsDevice.connectionState == IHSDeviceConnectionStateConnected) {
        _connectionActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Maintain action sheet cancel button text")
                                               destructiveButtonTitle:NSLocalizedString(@"Disconnect", @"Maintain action sheet disconnect button text")
                                                    otherButtonTitles:NSLocalizedString(@"Software update", @"Maintain action sheet software update button text"), nil];
        _connectionActionSheet.tag = ActionSheetTypeActionsConnected;
    }
    else {
        _connectionActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Maintain action sheet cancel button text")
                                               destructiveButtonTitle:NSLocalizedString(@"Manually connect", @"Maintain action sheet manually connect button text")
                                                    otherButtonTitles:nil];
        _connectionActionSheet.tag = ActionSheetTypeActionsDisconnected;
    }

    [_connectionActionSheet showInView:self.view];
}

#pragma mark - segue handling

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"swupdate_segue"]) {
        if ([segue respondsToSelector:@selector(popoverController)]) {
            self.swupdatePopoverController = [(UIStoryboardPopoverSegue *)segue popoverController];
            GNSoftwareUpdateViewController* vc = segue.destinationViewController;
            vc.delegate = self;
        }
    }
}


- (void)softwareUpdateViewControllerDidFinish:(GNSoftwareUpdateViewController *)controller
{
    [self.swupdatePopoverController dismissPopoverAnimated:YES];
}

@end
