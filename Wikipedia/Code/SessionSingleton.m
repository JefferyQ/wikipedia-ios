//  Created by Monte Hurd on 12/6/13.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

#import "SessionSingleton.h"
#import "WikipediaAppUtils.h"
#import "QueuesSingleton.h"
#import "WMFURLCache.h"
#import "WMFAssetsFile.h"
#import "MediaWikiKit.h"
#import "Wikipedia-Swift.h"


@interface SessionSingleton ()

@property (strong, nonatomic, readwrite) MWKDataStore* dataStore;

@property (strong, nonatomic) WMFAssetsFile* mainPages;

@property (strong, nonatomic, readwrite) NSURL* currentArticleDomainURL;

@property (strong, nonatomic) NSURL* currentArticleURL;

@end

@implementation SessionSingleton
@synthesize currentArticle = _currentArticle;

#pragma mark - Setup

+ (SessionSingleton*)sharedInstance {
    static dispatch_once_t onceToken;
    static SessionSingleton* sharedInstance;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    return sharedInstance;
}

- (instancetype)init {
    return [self initWithDataStore:[[MWKDataStore alloc] initWithBasePath:[[MWKDataStore class] mainDataStorePath]]];
}

- (instancetype)initWithDataStore:(MWKDataStore*)dataStore {
    self = [super init];
    if (self) {
        [WikipediaAppUtils copyAssetsFolderToAppDataDocuments];

        WMFURLCache* urlCache = [[WMFURLCache alloc] initWithMemoryCapacity:MegabytesToBytes(64)
                                                               diskCapacity:MegabytesToBytes(128)
                                                                   diskPath:nil];
        [NSURLCache setSharedURLCache:urlCache];

        self.zeroConfigState             = [[ZeroConfigState alloc] init];
        self.zeroConfigState.disposition = NO;

        self.dataStore = dataStore;

        _currentArticleDomainURL = [self lastKnownSite];
    }
    return self;
}

- (MWKUserDataStore*)userDataStore {
    return self.dataStore.userDataStore;
}

#pragma mark - Site

- (void)setCurrentArticleDomainURL:(NSURL*)currentArticleDomainURL {
    NSParameterAssert(currentArticleDomainURL);
    if (!currentArticleDomainURL || [_currentArticleDomainURL isEqual:currentArticleDomainURL]) {
        return;
    }
    _currentArticleDomainURL = [currentArticleDomainURL wmf_domainURL];
    [[NSUserDefaults standardUserDefaults] setObject:currentArticleDomainURL.wmf_language forKey:@"CurrentArticleDomain"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - Article

- (void)setCurrentArticleURL:(NSURL*)currentArticleURL {
    NSParameterAssert(currentArticleURL);
    if (!_currentArticleURL || [_currentArticleURL isEqual:currentArticleURL]) {
        return;
    }
    _currentArticleURL = currentArticleURL;
    [[NSUserDefaults standardUserDefaults] setObject:currentArticleURL.wmf_title forKey:@"CurrentArticleTitle"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setCurrentArticle:(MWKArticle*)currentArticle {
    if (!currentArticle || [_currentArticle isEqual:currentArticle]) {
        return;
    }
    _currentArticle              = currentArticle;
    self.currentArticleURL       = currentArticle.url;
    self.currentArticleDomainURL = currentArticle.url;
}

- (MWKArticle*)currentArticle {
    if (!_currentArticle) {
        self.currentArticle = [self lastLoadedArticle];
    }
    return _currentArticle;
}

#pragma mark - Last known/loaded

- (NSURL*)lastKnownSite {
    return [NSURL wmf_URLWithDefaultSiteAndlanguage:[[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleDomain"]];
}

- (NSURL*)lastLoadedArticleURL {
    NSURL* lastKnownSite = [self lastKnownSite];
    NSString* titleText  = [[NSUserDefaults standardUserDefaults] objectForKey:@"CurrentArticleTitle"];
    if (!titleText.length) {
        return nil;
    }
    return [lastKnownSite wmf_URLWithTitle:titleText];
}

- (MWKArticle*)lastLoadedArticle {
    NSURL* lastLoadedURL = [self lastLoadedArticleURL];
    if (!lastLoadedURL) {
        return nil;
    }
    MWKArticle* article = [self.dataStore articleWithURL:lastLoadedURL];
    return article;
}

#pragma mark - Language URL

- (NSURL*)urlForLanguage:(NSString*)language {
    return self.fallback ? [[NSURL wmf_URLWithDefaultSiteAndlanguage:language] wmf_desktopAPIURL] : [[NSURL wmf_URLWithDefaultSiteAndlanguage:language] wmf_mobileAPIURL];
}

#pragma mark - Usage Reports

- (BOOL)shouldSendUsageReports {
    return [[NSUserDefaults standardUserDefaults] wmf_sendUsageReports];
}

- (void)setShouldSendUsageReports:(BOOL)sendUsageReports {
    if (sendUsageReports == [self shouldSendUsageReports]) {
        return;
    }
    [[NSUserDefaults standardUserDefaults] wmf_setSendUsageReports:sendUsageReports];
    [[QueuesSingleton sharedInstance] reset];
}

@end
