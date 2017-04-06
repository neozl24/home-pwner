//
//  ItemsViewController.m
//  HomePwner
//
//  Created by 钟立 on 16/10/24.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import "ItemsViewController.h"
#import "DetailViewController.h"
#import "ImageViewController.h"
#import "Item.h"
#import "ItemStore.h"
#import "ImageStore.h"

@interface ItemsViewController () <UIPopoverControllerDelegate, UIDataSourceModelAssociation>

@property (nonatomic, strong) UIPopoverController *imagePopover;

//@property (nonatomic, strong) IBOutlet UIView *headerView;

@end

@implementation ItemsViewController

#pragma mark - Controller life cycle
- (instancetype)init {
    return [self initWithStyle:UITableViewStyleGrouped];
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        UINavigationItem *navItem = self.navigationItem;
        navItem.title = NSLocalizedString(@"Homepwner", @"Name of application");
        
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        UIBarButtonItem *bbi = [[UIBarButtonItem alloc]
                                initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                target:self
                                action:@selector(addNewItem:)];
        navItem.rightBarButtonItem = bbi;
        
        navItem.leftBarButtonItem = self.editButtonItem;
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(updateTableViewForDynamicTypeSize) name:UIContentSizeCategoryDidChangeNotification object:nil];
        
        [nc addObserver:self selector:@selector(localeChanged:)
                   name:NSCurrentLocaleDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self];
}

#pragma mark - View life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
//    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    
    //    UIView *header = self.headerView;
    //    [self.tableView setTableHeaderView:header];
    
    UINib *nib = [UINib nibWithNibName:@"ItemCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:@"ItemCell"];
    
    self.tableView.restorationIdentifier = @"ItemsViewControllerTableView";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self updateTableViewForDynamicTypeSize];
}


#pragma mark - Actions
- (void)addNewItem:(id)sender {
    Item *newItem = [[ItemStore sharedStore] createItem];
    
//    NSInteger lastRow = [[[ItemStore sharedStore] allItems] indexOfObject:newItem];
//    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lastRow inSection:0];
//    
//    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    DetailViewController *detailViewController = [[DetailViewController alloc] initForNewItem:YES];
    detailViewController.item = newItem;
    
    detailViewController.dismissBlock = ^{
        [self.tableView reloadData];
    };
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    navController.restorationIdentifier = NSStringFromClass([navController class]);
    
    navController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:navController animated:YES completion:nil];
}

- (void)localeChanged:(NSNotification *)note {
    [self.tableView reloadData];
}

#pragma mark - table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[ItemStore sharedStore] allItems].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UITableViewCell"];
    ItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ItemCell" forIndexPath:indexPath];
    NSArray *items = [[ItemStore sharedStore] allItems];
    Item *item = items[indexPath.row];
    
    cell.nameLabel.text = item.itemName;
    cell.serialNumberLabel.text = item.serialNumber;
    
    static NSNumberFormatter *currencyFormatter = nil;
    if (currencyFormatter == nil) {
        currencyFormatter = [[NSNumberFormatter alloc] init];
        currencyFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    }
    cell.valueLabel.text = [currencyFormatter stringFromNumber:@(item.valueInDollars)];
    
    cell.thumbnailView.image = item.thumbnail;
    
    __weak ItemCell *weakCell = cell;
    
    cell.actionBlock = ^{
        NSLog(@"Going to show image for %@", item);
        
        ItemCell *strongCell = weakCell;
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            NSString *itemKey = item.itemKey;
            
            UIImage *image = [[ImageStore sharedStore] imageForKey:itemKey];
            if (!image) {
                return;
            }
            
            CGRect rect = [self.view convertRect:strongCell.thumbnailView.bounds fromView:strongCell.thumbnailView];
            
            ImageViewController *ivc = [[ImageViewController alloc] init];
            ivc.image = image;
            
            self.imagePopover = [[UIPopoverController alloc] initWithContentViewController:ivc];
            self.imagePopover.delegate = self;
            self.imagePopover.popoverContentSize = CGSizeMake(600, 600);
            [self.imagePopover presentPopoverFromRect:rect inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    };
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSArray *items = [[ItemStore sharedStore] allItems];
        Item *item = items[indexPath.row];
        [[ItemStore sharedStore] removeItem:item];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    
    [[ItemStore sharedStore] moveItemAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
}

//- (UIView *)headerView {
//    if (!_headerView) {
//        [[NSBundle mainBundle] loadNibNamed:@"HeaderView"
//                                      owner:self
//                                    options:nil];
//    }
//    return _headerView;
//}


//- (IBAction)toggleEditingMode:(id)sender {
//    if (self.isEditing) {
//        [sender setTitle:@"Edit" forState:UIControlStateNormal];
//        [self setEditing:NO animated:YES];
//    } else {
//        [sender setTitle:@"Done" forState:UIControlStateNormal];
//        [self setEditing:YES animated:YES];
//    }
//}

#pragma mark - Tabel view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DetailViewController *detailViewController = [[DetailViewController alloc] initForNewItem:NO];
    
    NSArray *items = [[ItemStore sharedStore] allItems];
    Item *selectedItem = items[indexPath.row];
    detailViewController.item = selectedItem;
    
    [self.navigationController pushViewController:detailViewController animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.imagePopover = nil;
}

- (void)updateTableViewForDynamicTypeSize {
    static NSDictionary *cellHeightDictionary;
    
    if (!cellHeightDictionary) {
        cellHeightDictionary = @{
                                 UIContentSizeCategoryExtraSmall : @44,
                                 UIContentSizeCategorySmall : @44,
                                 UIContentSizeCategoryMedium : @44,
                                 UIContentSizeCategoryLarge : @44,
                                 UIContentSizeCategoryExtraLarge : @55,
                                 UIContentSizeCategoryExtraExtraLarge: @65,
                                 UIContentSizeCategoryExtraExtraExtraLarge: @75
                                 };
    }
    
    NSString *userSize = [[UIApplication sharedApplication] preferredContentSizeCategory];
    
    NSNumber *cellHeight = cellHeightDictionary[userSize];
    [self.tableView setRowHeight:cellHeight.floatValue];
    [self.tableView reloadData];
}

#pragma mark - State Restoration protocol for UIViewController
+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
    return [[self alloc] init];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeBool:self.isEditing forKey:@"TableViewIsEditing"];
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    self.editing = [coder decodeBoolForKey:@"TableViewIsEditing"];
    [super decodeRestorableStateWithCoder:coder];
}

- (NSString *)modelIdentifierForElementAtIndexPath:(NSIndexPath *)idx inView:(UIView *)view {
    NSString *identifier = nil;
    if (idx && view) {
        Item *item = [[ItemStore sharedStore] allItems][idx.row];
        identifier = item.itemKey;
    }
    return identifier;
}

- (NSIndexPath *)indexPathForElementWithModelIdentifier:(NSString *)identifier inView:(UIView *)view {
    NSIndexPath *indexPath = nil;
    if (identifier && view) {
        NSArray *items = [[ItemStore sharedStore] allItems];
        for (Item *item in items) {
            if ([identifier isEqualToString:item.itemKey]) {
                NSInteger row = [items indexOfObjectIdenticalTo:item];
                indexPath = [NSIndexPath indexPathForRow:row inSection:0];
            }
        }
    }
    return indexPath;
}

@end





