//
//  ProductViewController.m
//  iBeacon_Retail
//
//  Created by shruthi on 02/03/15.
//  Copyright (c) 2015 TAVANT. All rights reserved.
//

#import "ProductViewController.h"
#import "prodCell.h"
#import "Products.h"
#import "CartItem.h"
#import "NetworkOperations.h"
#import "GlobalVariables.h"

#import "UIImageView+WebCache.h"

@interface ProductViewController ()

@property(nonatomic,strong) Products * product;
@property(nonatomic,strong) NetworkOperations *networks;
//@property(nonatomic,strong) NSMutableArray *productImagesArray;
@property(nonatomic,strong) GlobalVariables *globals;
@property (nonatomic,strong) UIRefreshControl* refreshControl;
@end

@implementation ProductViewController
@synthesize globals;

- (void)viewDidLoad {
    
    [super viewDidLoad];
    globals=[GlobalVariables getInstance];
    UINib *cellNib = [UINib nibWithNibName:@"prodCell" bundle:nil];
    [self.prodCollectionView registerNib:cellNib forCellWithReuseIdentifier:@"prodCell"];
   
    if(![globals.productDataArray count]>0){
          [self getProductListing];
    }
    [self loadRefreshControlForProductListing];
    [self startUserActivities];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    UIButton *rtButton  = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [rtButton setImage:[UIImage imageNamed:@"icon_cart.png"] forState:UIControlStateNormal];
    [rtButton addTarget:[GlobalVariables getInstance] action:@selector(loadCartScreen) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rtButton];
    [SlideNavigationController sharedInstance].rightBarButtonItem = rightBarButtonItem;
    self.navigationItem.title = @"Products";
    if([self.products count] == 0 && [globals.productDataArray count]>0){
        self.products = globals.productDataArray;
        self.searchFilteredProducts = globals.productDataArray;
    }else{
        if(self.searchString){
            self.searchBar.text = self.searchString;
        }
    }
    [self.prodCollectionView reloadData];
    
    
//    [self startUserActivities];
//    self.userActivity.needsSave = YES;
    [self updateUserActivityState:self.screenActivity];
   
}
- (void)viewWillDisappear:(BOOL)animated{
    [self.screenActivity invalidate];
    [super viewWillDisappear:animated];
}

-(void) startUserActivities{
    self.screenActivity =  [[NSUserActivity alloc] initWithActivityType:TavantIBeaconRetailContinutiyViewScreen];
    self.screenActivity.title = @"Viewing Product List Screen";
    NSDictionary* activityData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:BeaconRetailProductIndex],@"menuIndex", [GlobalVariables getCartItems], @"cartItems", self.products, @"products", self.searchFilteredProducts, @"filteredProducts",@"", @"searchString", nil];
    self.screenActivity.userInfo = [NSDictionary dictionaryWithObjectsAndKeys:activityData,TavantIBeaconRetailContinutiyScreenData, nil];
    self.userActivity = self.screenActivity;
    [self.userActivity becomeCurrent];
}

-(void)updateUserActivityState:(NSUserActivity *)activity{
    NSString* searchString=@"";
    if(![self.searchBar.text isEqualToString:@""]){
        searchString = self.searchBar.text;
    }
    NSDictionary* activityData = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:BeaconRetailProductIndex],@"menuIndex", [GlobalVariables getCartItems], @"cartItems", self.products, @"products", self.searchFilteredProducts, @"filteredProducts", searchString, @"searchString", nil];
    [activity addUserInfoEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:activityData,TavantIBeaconRetailContinutiyScreenData, nil]];
    //    [self.screenActivity becomeCurrent];
    [super updateUserActivityState:activity];
    
}

-(void)restoreUserActivityState:(NSUserActivity *)activity{
    if([activity.activityType isEqualToString:TavantIBeaconRetailContinutiyViewScreen]){
        NSDictionary* activityInfo = [activity.userInfo objectForKey:TavantIBeaconRetailContinutiyScreenData];
        self.products = [activityInfo objectForKey:@"products"];
        self.searchFilteredProducts = [activityInfo objectForKey:@"filteredProducts"];
        if([activityInfo objectForKey:@"searchString"]){
            self.searchBar.text = [activityInfo objectForKey:@"searchString"];
            self.searchString = [activityInfo objectForKey:@"searchString"];
        }
        [self.prodCollectionView reloadData];
        
//        NSLog(@"TEST");
    }else if([activity.activityType isEqualToString:TavantIBeaconRetailContinutiyViewProduct]){
        NSDictionary* activityInfo = [activity.userInfo objectForKey:TavantIBeaconRetailContinutiyScreenData];
        self.products = [activityInfo objectForKey:@"products"];
        self.searchFilteredProducts = [activityInfo objectForKey:@"filteredProducts"];
        if([activityInfo objectForKey:@"searchString"]){
            self.searchBar.text = [activityInfo objectForKey:@"searchString"];
            self.searchString = [activityInfo objectForKey:@"searchString"];
        }
        [self.prodCollectionView reloadData];
        
        ProductDetailViewController* prodDetailVC = [[ProductDetailViewController alloc] initWithNibName:@"ProductDetailViewController" bundle:nil];
        prodDetailVC.product = (Products*)[activityInfo objectForKey:@"product"];
        prodDetailVC.prevScreen = BeaconRetailProductIndex;
        prodDetailVC.prevVCForUserActivityFlow = self;
        [prodDetailVC restoreUserActivityState:activity];
        [[SlideNavigationController sharedInstance] pushViewController:prodDetailVC animated:YES];
    }
    [super restoreUserActivityState:activity];
}

-(void) getProductListing{
    self.networks=[[NetworkOperations alloc] init];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSLog(@"The product Api is %@",[dict objectForKey:@"Prod_Api"]);
 // send block as parameter to get callbacks
//    [self shouldHideLoadingIndicator:NO];
    [self.networks fetchDataFromServer:[dict objectForKey:@"Prod_Api"] withreturnMethod:^(NSMutableArray* data){
        self.products = self.searchFilteredProducts = globals.productDataArray = data;
        NSLog(@"The product Api is %lu",(unsigned long)[globals.productDataArray count]);
        dispatch_async(dispatch_get_main_queue(), ^
                       {
                           [self.prodCollectionView reloadData];
                           [self shouldHideLoadingIndicator:YES];
                           if (self.refreshControl) {
                               [self.refreshControl endRefreshing];
                           }
                           
                       });
        
    }];
   // [self.prodCollectionView reloadData];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark - For Status Bar
-(UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

#pragma Collection view delegate methods
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    if([self.searchFilteredProducts count] > 0){
        self.prodCollectionView.backgroundView = nil;
        return 1;
    }else{
        // Display a message when the table is empty
        UILabel *messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
        
        messageLabel.text = @"No data is currently available.\nTap to refresh.";
        messageLabel.textColor = [UIColor blackColor];
        messageLabel.numberOfLines = 0;
        messageLabel.textAlignment = NSTextAlignmentCenter;
        messageLabel.font = [UIFont fontWithName:@"AvenirNext-UltraLightItalic" size:18];
        [messageLabel sizeToFit];
        
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(getProductListing)];
        tapGestureRecognizer.numberOfTapsRequired = 1;
        [messageLabel addGestureRecognizer:tapGestureRecognizer];
        messageLabel.userInteractionEnabled = YES;        
        self.prodCollectionView.backgroundView = messageLabel;
    }
    return 0;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section
{
    return [self.searchFilteredProducts count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath; {
    prodCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"prodCell" forIndexPath:indexPath];
    cell.frame = CGRectMake(0, cell.frame.origin.y, self.prodCollectionView.frame.size.width, cell.frame.size.height);
    //cell.backgroundColor = [UIColor whiteColor];
    
    Products *prodObject= [[Products alloc] initWithDictionary:[self.searchFilteredProducts objectAtIndex:indexPath.row]];
   // prodObject.prodImage=[NSString stringWithFormat:@"%@.png",prodObject.prodName];
    
    cell.product = prodObject;
    cell.productName.text=prodObject.prodName;
    cell.prodDescription.text = prodObject.prodDescription;
    cell.offerPrice.text = prodObject.price;
    cell.size.text = prodObject.size;
    
    //  using SDWEbimage for lazy loading of images
    NSString* result = [prodObject.prodImage stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    [cell.productImage sd_setImageWithURL:[NSURL URLWithString:result] placeholderImage:[UIImage imageNamed:@"Default_imageHolder.png"]];

    
  //  cell.availableColor1.backgroundColor = [UIColor redColor];
    cell.availableColor1.layer.cornerRadius = (CGFloat)cell.availableColor1.frame.size.height/2;
    
  //  cell.availableColor2.backgroundColor = [UIColor blueColor];
    cell.availableColor2.layer.cornerRadius = (CGFloat)cell.availableColor2.frame.size.height/2;
    
  //  cell.availableColor3.backgroundColor = [UIColor blackColor];
    cell.availableColor3.layer.cornerRadius = (CGFloat)cell.availableColor3.frame.size.height/2;
    
   // cell.availableColor4.backgroundColor = [UIColor yellowColor];
    cell.availableColor4.layer.cornerRadius = (CGFloat)cell.availableColor4.frame.size.height/2;
    
    return cell;
 
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    Products *prodObject= [[Products alloc] initWithDictionary:[self.searchFilteredProducts objectAtIndex:indexPath.row]];
    ProductDetailViewController* prodDetailVC = [[ProductDetailViewController alloc] initWithNibName:@"ProductDetailViewController" bundle:nil];
    prodDetailVC.product = prodObject;
    prodDetailVC.prevScreen = BeaconRetailProductIndex;
    self.searchString = self.searchBar.text;
    prodDetailVC.prevVCForUserActivityFlow = self;
    [[SlideNavigationController sharedInstance] pushViewController:prodDetailVC animated:YES];
}

#pragma searchBar delegates

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    //[self applyFilters:[NSSet setWithObject:searchBar.text]];
    [self updateUserActivityState:self.userActivity];
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchBar.text=@"";
    [self filterRetailerList];
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(searchText.length == 0){
        [self filterRetailerList];
        
    }else{
        searchBar.showsCancelButton = YES;
    }
    if([[searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet  whitespaceAndNewlineCharacterSet]] isEqualToString:@""]) return;
    [self filterRetailerList];
}
-(BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar{
    NSLog(@"YES!!!!!!!");
    if(searchBar.text.length > 0){
        searchBar.showsCancelButton = YES;
    }else{
        searchBar.showsCancelButton = NO;
    }
    return YES;
}
- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar{
    searchBar.showsCancelButton = NO;
    return YES;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [[event allTouches] anyObject];
    if ([self.searchBar isFirstResponder] && [touch view] != self.searchBar) {
        [self.searchBar resignFirstResponder];
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)filterRetailerList
{
    NSPredicate *searchKeyWordPredicate;    
    //Setting predicate if there is a keyword entered in the searchbar
    NSString* trimmedString = [self.searchBar.text stringByTrimmingCharactersInSet:[NSCharacterSet  whitespaceAndNewlineCharacterSet]];
    if(trimmedString.length > 0){
                searchKeyWordPredicate = [NSPredicate predicateWithFormat:@"productName CONTAINS[cd] %@",trimmedString];
    }else{
        searchKeyWordPredicate = [NSPredicate predicateWithValue:YES]; // returns all products
    }
//    NSArray*  temp =  [[NSArray alloc] initWithArray:[self.products filteredArrayUsingPredicate:searchKeyWordPredicate]];
    self.searchFilteredProducts = [self.products filteredArrayUsingPredicate:searchKeyWordPredicate];
    [self updateUserActivityState:self.screenActivity];
    [self.prodCollectionView reloadData];
}

#pragma mark Slide view delegate method
- (BOOL)slideNavigationControllerShouldDisplayLeftMenu
{
    return YES;
}

- (BOOL)slideNavigationControllerShouldDisplayRightMenu
{
    return YES;
}

-(void) shouldHideLoadingIndicator:(BOOL) state{
        self.loadingIndicatorView.hidden=state;
}

-(void)loadRefreshControlForProductListing{
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.backgroundColor = [UIColor colorWithRed:74/255.00 green:170/255.00 blue:192/255.00 alpha:1];
    self.refreshControl.tintColor = [UIColor whiteColor];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MMM d, h:mm a"];
    NSString *title = [NSString stringWithFormat:@"Last update: %@", [formatter stringFromDate:[NSDate date]]];
    NSDictionary *attrsDictionary = [NSDictionary dictionaryWithObject:[UIColor whiteColor]
                                                                forKey:NSForegroundColorAttributeName];
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:attrsDictionary];
    self.refreshControl.attributedTitle = attributedTitle;
    
    [self.refreshControl addTarget:self action:@selector(getProductListing) forControlEvents:UIControlEventValueChanged];
    [self.prodCollectionView addSubview:self.refreshControl];
}

@end
