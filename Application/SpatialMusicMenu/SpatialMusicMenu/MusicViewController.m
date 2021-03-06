//
//  MusicViewController.m
//  SpatialMusicMenu
//
//  Created by Jonas Hinge on 15/03/2014.
//  Copyright (c) 2014 Jonas Hinge. All rights reserved.
//

#import "MusicViewController.h"

#import "AppDelegate.h"
#import "Playlist.h"

@interface MusicViewController () <UITableViewDataSource, UITableViewDelegate>

@property UITableView *tablePlaylists;
@property UILabel *lblTrackCounter;
@property UILabel *lblDeezerConnStatus;


// Set the DEBUG_PRINTOUT define to '1' to enable printouts of the received values
#define DEBUG_PRINTOUT      0

#if !DEBUG_PRINTOUT
#define DEBUGLog(format, ...)
#else
#define DEBUGLog(format, ...) NSLog(format, ## __VA_ARGS__)
#endif


@end

@implementation MusicViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:DEEZER_PLAYLIST_INFO_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:DEEZER_PLAYLIST_DATA_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:DEEZER_ALBUM_INFO_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTable) name:DEEZER_ALBUM_DATA_UPDATED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deezerConnectionStatusChanged:) name:DEEZER_CONNECTION_STATUS_CHANGED object:nil];
    
    [self.view setBackgroundColor:UIColorFromRGB(0x3a424c)];
    
    _lblDeezerConnStatus = [[UILabel alloc] initWithFrame:CGRectMake(22, 130, 200, 30)];
    [_lblDeezerConnStatus setFont:[UIFont fontWithName:@"Helvetica" size:14]];
    [_lblDeezerConnStatus setTextColor:[UIColor whiteColor]];
    [_lblDeezerConnStatus setText:@"Disconnected"];
    [self.view addSubview:_lblDeezerConnStatus];
    
    // Setup connect button
    UIButton *btnConnect = [[UIButton alloc] initWithFrame:CGRectMake(20, 65, 100, 50)];
    [btnConnect setTitle:@"Connect" forState:UIControlStateNormal];
    [btnConnect setBackgroundColor:UIColorFromRGB(0xff5335)];
    [btnConnect.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:20]];
    [btnConnect addTarget:self action:@selector(btnConnectPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnConnect];
    
    // Setup sync button
    UIButton *btnSync = [[UIButton alloc] initWithFrame:CGRectMake(160, 65, 100, 50)];
    [btnSync setTitle:@"Sync" forState:UIControlStateNormal];
    [btnSync setBackgroundColor:UIColorFromRGB(0xff5335)];
    [btnSync.titleLabel setFont:[UIFont fontWithName:@"Helvetica-Light" size:20]];
    [btnSync addTarget:self action:@selector(btnSyncPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnSync];
    
    // Setup track counter
    _lblTrackCounter = [[UILabel alloc] initWithFrame:CGRectMake(150, 150, 100, 80)];
    [_lblTrackCounter setFont:[UIFont fontWithName:@"Helvetica" size:48]];
    [_lblTrackCounter setTextColor:[UIColor whiteColor]];
    [_lblTrackCounter setText:[NSString stringWithFormat:@"%d",APP_DELEGATE.persistencyManager.trackNumber]];
    [_lblTrackCounter setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:_lblTrackCounter];
    
    UIStepper *stepperTracks = [[UIStepper alloc] initWithFrame:CGRectMake(150, 240, 160, 60)];
    [stepperTracks setMaximumValue:10];
    [stepperTracks setMinimumValue:3];
    [stepperTracks setValue:APP_DELEGATE.persistencyManager.trackNumber];
    [stepperTracks setTintColor:[UIColor whiteColor]];
    [stepperTracks addTarget:self action:@selector(stepperTracksChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:stepperTracks];
    
    // Table setup
    _tablePlaylists = [[UITableView alloc] initWithFrame:CGRectMake(0, 300, 400, 900) style:UITableViewStylePlain];
    _tablePlaylists.delegate = self;
    _tablePlaylists.dataSource = self;
    _tablePlaylists.backgroundView = nil;
    [_tablePlaylists setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.2]];
    [self.view addSubview:_tablePlaylists];
    
    [self refreshTable];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)deezerConnectionStatusChanged:(NSNotification*)notification
{
    [_lblDeezerConnStatus setText:[notification.userInfo objectForKey:@"status"]];
}

- (void)stepperTracksChanged:(id)stepper
{
    UIStepper *step = stepper;
    _trackCount = [step value];
    
    [APP_DELEGATE.persistencyManager setTrackNumber:_trackCount];
    
    // Update label
    [_lblTrackCounter setText:[NSString stringWithFormat:@"%d",_trackCount]];
}

- (void)btnConnectPressed:(id)btn
{
    [APP_DELEGATE.deezerClient connect];
}

- (void)btnSyncPressed:(id)btn
{
    [APP_DELEGATE.deezerClient sync];
}

- (void)refreshTable
{
    [_tablePlaylists reloadData];
    DEBUGLog(@"%@",[APP_DELEGATE.persistencyManager getPlaylists]);
}


#pragma mark - TableView delegate implementation

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[APP_DELEGATE.persistencyManager getPlaylists] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    }
    
    [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:20]];
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    Playlist *pl = (Playlist *)[[APP_DELEGATE.persistencyManager getPlaylists] objectAtIndex:indexPath.row];
    [cell.textLabel setText:pl.title];
    
    // Sync status
    if([APP_DELEGATE.persistencyManager playlistIsReady:pl])
    {
        [cell.detailTextLabel setText:@"Ready"];
    }
    else
    {
        [cell.detailTextLabel setText:@"Not synced"];
    }
    
    // Active status
    if(pl == [APP_DELEGATE.persistencyManager getActivePlaylist])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [APP_DELEGATE.persistencyManager saveActivePlaylist:[[APP_DELEGATE.persistencyManager getPlaylists] objectAtIndex:indexPath.row]];
    
    [self refreshTable];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0;
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
