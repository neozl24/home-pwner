//
//  DetailViewController.m
//  HomePwner
//
//  Created by 钟立 on 16/10/25.
//  Copyright © 2016年 钟立. All rights reserved.
//

#import "DetailViewController.h"
#import "Item.h"
#import "ItemStore.h"
#import "ImageStore.h"
#import "AssetTypeViewController.h"
#import "AppDelegate.h"

@interface DetailViewController () <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIPopoverControllerDelegate>

@property (strong, nonatomic) UIPopoverController *imagePickerPopover;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *serialNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UITextField *nameField;
@property (weak, nonatomic) IBOutlet UITextField *serialNumberField;
@property (weak, nonatomic) IBOutlet UITextField *valueField;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cameraButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *assetTypeButton;

@end

@implementation DetailViewController

- (instancetype)initForNewItem:(BOOL)isNew {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.restorationIdentifier = NSStringFromClass([self class]);
        self.restorationClass = [self class];
        
        if (isNew) {
            UIBarButtonItem *doneItem = [[UIBarButtonItem alloc]
                                         initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                         target:self
                                         action:@selector(save:)];
            self.navigationItem.rightBarButtonItem = doneItem;
            
            UIBarButtonItem *cancelItem = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                           target:self
                                           action:@selector(cancel:)];
            self.navigationItem.leftBarButtonItem = cancelItem;
        }
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(updateFonts) name:UIContentSizeCategoryDidChangeNotification object:nil];        
    }
    return self;
}

- (void)dealloc {
    NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
    [defaultCenter removeObserver:self];
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    @throw [NSException exceptionWithName:@"Wrong initializer"
                                   reason:@"Use initForNewItem:"
                                 userInfo:nil];
    return nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImageView *iv = [[UIImageView alloc] initWithImage:nil];
    iv.contentMode = UIViewContentModeScaleAspectFit;
    iv.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:iv];
    self.imageView = iv;
    
    NSDictionary *nameMap = @{ @"imageView" : self.imageView,
                               @"dateLabel" : self.dateLabel,
                               @"toolbar" : self.toolbar };
    
    NSArray *horizontalConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-65-[imageView]-65-|"
                                            options:0 metrics:nil views:nameMap];
    
    NSArray *verticalConstraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[dateLabel]-8-[imageView]-20-[toolbar]"
                                            options:0 metrics:nil views:nameMap];
    
    [self.view addConstraints:horizontalConstraints];
    [self.view addConstraints:verticalConstraints];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIInterfaceOrientation io = [[UIApplication sharedApplication] statusBarOrientation];
    [self prepareViewsForOrientation:io];
    
    Item *item = self.item;
    
    self.nameField.text = item.itemName;
    self.serialNumberField.text = item.serialNumber;
    self.valueField.text = [NSString stringWithFormat:@"%d", item.valueInDollars];
    
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateStyle = NSDateFormatterMediumStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
    }
    self.dateLabel.text = [dateFormatter stringFromDate:item.dateCreated];
    
    NSString *itemKey = _item.itemKey;
    
    if (itemKey) {
        UIImage *imageToDisplay = [[ImageStore sharedStore] imageForKey:itemKey];
        self.imageView.image = imageToDisplay;
    } else {
        self.imageView.image = nil;
    }
    
    NSString *typeLabel = [self.item.assetType valueForKey:@"label"];
    if (!typeLabel) {
        typeLabel = NSLocalizedString(@"None", @"Type label None");
    }
    self.assetTypeButton.title = [NSString stringWithFormat:NSLocalizedString(@"Type: %@", @"Asset type button"), typeLabel];
    
    [self updateFonts];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.view endEditing:YES];
    
    Item *item = self.item;
    item.itemName = self.nameField.text;
    item.serialNumber = self.serialNumberField.text;
    
    int newValue = [self.valueField.text intValue];
    
    if (newValue != item.valueInDollars) {
        item.valueInDollars = newValue;
        [[NSUserDefaults standardUserDefaults] setInteger:newValue forKey:NextItemValuePrefsKey];
    }
}

- (void)setItem:(Item *)item {
    _item = item;
    self.navigationItem.title = _item.itemName;
}

- (IBAction)takePicture:(id)sender {
    if ([self.imagePickerPopover isPopoverVisible]) {
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
        return;
    }
    
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    NSArray *availableTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
    ipc.mediaTypes = availableTypes;
//    ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        ipc.sourceType = UIImagePickerControllerSourceTypeCamera;
    } else {
        ipc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    ipc.delegate = self;
//    [self presentViewController:ipc animated:YES completion:nil];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        self.imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:ipc];
        self.imagePickerPopover.delegate = self;
        
        [self.imagePickerPopover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:ipc animated:YES completion:nil];
    }
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    NSLog(@"User dismissed popover");
    self.imagePickerPopover = nil;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    
    [self.item setThumbnailFromImage:image];
    
    [[ImageStore sharedStore] setImage:image forKey:self.item.itemKey];
    
    self.imageView.image = image;
    
    NSURL *mediaURL = info[UIImagePickerControllerMediaURL];
    
    if (mediaURL) {
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([mediaURL path])) {
            UISaveVideoAtPathToSavedPhotosAlbum([mediaURL path], nil, nil, nil);
            
            [[NSFileManager defaultManager] removeItemAtPath:[mediaURL path] error:nil];
        }
    }
    
//    [self dismissViewControllerAnimated:YES completion:nil];
    if (self.imagePickerPopover) {
        [self.imagePickerPopover dismissPopoverAnimated:YES];
        self.imagePickerPopover = nil;
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (IBAction)backgroundTapped:(id)sender {
    [self.view endEditing:YES];
}

- (void)prepareViewsForOrientation:(UIInterfaceOrientation)orientation {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return;
    }
    
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        self.imageView.hidden = YES;
        self.cameraButton.enabled = NO;
    } else {
        self.imageView.hidden = NO;
        self.cameraButton.enabled = YES;
    }
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self prepareViewsForOrientation:toInterfaceOrientation];
}

- (void)save:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

- (void)cancel:(id)sender {
    [[ItemStore sharedStore] removeItem:self.item];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:self.dismissBlock];
}

- (void)updateFonts {
    UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    self.nameLabel.font = font;
    self.serialNumberLabel.font = font;
    self.valueLabel.font = font;
    self.nameField.font = font;
    self.serialNumberField.font = font;
    self.valueField.font = font;
    self.dateLabel.font = font;
}

- (IBAction)showAssetTypePicker:(UIBarButtonItem *)sender {
    [self.view endEditing:YES];
    AssetTypeViewController *avc = [[AssetTypeViewController alloc] init];
    avc.item = self.item;
    [self.navigationController pushViewController:avc animated:YES];
}

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray *)path coder:(NSCoder *)coder {
    BOOL isNew = NO;
    if ([path count] == 3) {
        isNew = YES;
    }
    return [[self alloc] initForNewItem:isNew];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.item.itemKey forKey:@"item.itemKey"];
    self.item.itemName = self.nameField.text;
    self.item.serialNumber = self.serialNumberField.text;
    self.item.valueInDollars = [self.valueField.text intValue];
    
    [[ItemStore sharedStore] saveChanges];
    
    [super encodeRestorableStateWithCoder:coder];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
    NSString *itemKey = [coder decodeObjectForKey:@"item.itemKey"];
    
    for (Item *item in [[ItemStore sharedStore] allItems]) {
        if ([itemKey isEqualToString:item.itemKey]) {
            self.item = item;
            break;
        }
    }
    [super decodeRestorableStateWithCoder:coder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
