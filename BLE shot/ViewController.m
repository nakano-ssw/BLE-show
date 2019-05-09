//
//  ViewController.m
//  BLE test
//
//  Created by nakano on 2019/03/26.
//  Copyright © 2019 nakano. All rights reserved.
//

#import "ViewController.h"
#import "CameraViewController.h"

@interface Item : NSObject
@property(nonatomic, retain) NSString * name;
@property(nonatomic, assign) double ble;
@end

@implementation Item
@end


@interface ViewController () {
    NSMutableArray * _items;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _items = [[NSMutableArray alloc] init];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera target:self action:@selector(cameraButtonPressed)];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self searchRawFile];
    [self getBle];
    [self.tableView reloadData];
}

- (void)searchRawFile
{
    [_items removeAllObjects];
    NSFileManager * fm = [NSFileManager defaultManager];
    NSString * docDirPath = [self documentDirPath];
    NSArray<NSString*> * files = [fm contentsOfDirectoryAtPath:docDirPath error:nil];
    files = [files sortedArrayUsingComparator:^(id obj1, id obj2) {
        NSString * o1 = obj1;
        NSString * o2 = obj2;
        return [o1 compare:o2];
    }];
    for (NSString * fileName in files) {
        NSString * ext = [fileName.pathExtension lowercaseString];
        if ([ext isEqualToString:@"dng"] || [ext isEqualToString:@"raf"]) {
            Item * item = [[Item alloc] init];
            item.name = fileName;
            [_items addObject:item];
        }
    }
}

- (void)getBle
{
    NSString * docDirPath = [self documentDirPath];
    NSDictionary * option = @{ };
    for (Item * item in _items) {
        NSString * path = [docDirPath stringByAppendingPathComponent:item.name];
        NSData * data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedIfSafe error:nil];
        NSLog(@"%@ %ld", path, [data length]);
        CIFilter * rawConverter = [CIFilter filterWithImageData:data options:option];
        NSNumber * value = [rawConverter valueForKey:kCIInputBaselineExposureKey];
        item.ble = [value doubleValue];
    }
}

- (NSString*)documentDirPath {
    NSArray * array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * docDirPath = [array objectAtIndex:0];
    return docDirPath;
}

#pragma mark Action
- (void)cameraButtonPressed
{
    CameraViewController * vc = [[CameraViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_items count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellId];
    }
    NSInteger index = indexPath.row;
    Item * item = [_items objectAtIndex:index];
    cell.textLabel.text = item.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"BLE: %f", item.ble];
    return cell;
}
@end
