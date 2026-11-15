#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#define SWP_DOMAIN CFSTR("com.vn.showwifipass")

static const void *kSWPDone = &kSWPDone;

static BOOL prefBool(CFStringRef key, BOOL def) {
    CFPreferencesAppSynchronize(SWP_DOMAIN);
    CFPropertyListRef v = CFPreferencesCopyAppValue(key, SWP_DOMAIN);
    if (!v) return def;
    BOOL r = def;
    if (CFGetTypeID(v) == CFBooleanGetTypeID()) r = CFBooleanGetValue(v);
    else if (CFGetTypeID(v) == CFNumberGetTypeID()) { int n = 0; CFNumberGetValue(v, kCFNumberIntType, &n); r = (n != 0); }
    CFRelease(v);
    return r;
}

static BOOL classLooksWiFi(Class c) {
    if (!c) return NO;
    NSString *n = [NSStringFromClass(c) lowercaseString];
    if ([n hasPrefix:@"wf"] || [n containsString:@"wifi"] || [n containsString:@"airport"]) return YES;
    const char *img = class_getImageName(c);
    if (img) {
        NSString *s = [[NSString stringWithUTF8String:img] lowercaseString];
        if ([s containsString:@"wifi"] || [s containsString:@"airport"]) return YES;
    }
    return NO;
}

static NSString *chainDescription(UITextField *tf) {
    NSMutableArray *a = [NSMutableArray array];
    UIResponder *r = tf; int g = 0;
    while (r && g++ < 40) {
        [a addObject:NSStringFromClass([r class])];
        if ([r isKindOfClass:[UIViewController class]]) {
            UIViewController *p = ((UIViewController *)r).presentingViewController; int k = 0;
            while (p && k++ < 10) { [a addObject:[@"presenter:" stringByAppendingString:NSStringFromClass([p class])]]; p = p.presentingViewController; }
        }
        r = r.nextResponder;
    }
    return [a componentsJoinedByString:@" > "];
}

static BOOL isWiFiField(UITextField *tf) {
    UIResponder *r = tf; int g = 0;
    while (r && g++ < 40) {
        if (classLooksWiFi([r class])) return YES;
        if ([r isKindOfClass:[UIViewController class]]) {
            UIViewController *p = ((UIViewController *)r).presentingViewController; int k = 0;
            while (p && k++ < 10) {
                if (classLooksWiFi([p class])) return YES;
                for (UIViewController *c in p.childViewControllers) if (classLooksWiFi([c class])) return YES;
                p = p.presentingViewController;
            }
        }
        r = r.nextResponder;
    }
    return NO;
}

static void updateIcon(UIButton *b, BOOL secure) {
    UIImageSymbolConfiguration *cfg = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightRegular];
    [b setImage:[UIImage systemImageNamed:(secure ? @"eye.slash" : @"eye") withConfiguration:cfg] forState:UIControlStateNormal];
}

static void setSecure(UITextField *tf, UIButton *b, BOOL secure) {
    NSString *text = tf.text;
    NSInteger loc = 0, len = 0;
    UITextRange *sel = tf.selectedTextRange;
    if (sel) {
        loc = [tf offsetFromPosition:tf.beginningOfDocument toPosition:sel.start];
        len = [tf offsetFromPosition:sel.start toPosition:sel.end];
    }
    tf.secureTextEntry = secure;
    // Workaround: đổi secureTextEntry khi đang gõ có thể làm mất/đổi chữ
    tf.text = nil;
    tf.text = text;
    if (sel) {
        UITextPosition *s = [tf positionFromPosition:tf.beginningOfDocument offset:loc];
        UITextPosition *e = s ? [tf positionFromPosition:s offset:len] : nil;
        if (s && e) tf.selectedTextRange = [tf textRangeFromPosition:s toPosition:e];
    }
    updateIcon(b, secure);
}

static void setupField(UITextField *tf) {
    if (objc_getAssociatedObject(tf, kSWPDone)) return;
    if (!tf.secureTextEntry) return;
    if (!prefBool(CFSTR("enabled"), YES)) return;

    BOOL inPrefs = [[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.Preferences"];
    if (prefBool(CFSTR("debug"), NO)) NSLog(@"[ShowWiFiPass] secure field: %@", chainDescription(tf));
    BOOL ok = isWiFiField(tf) || (inPrefs && prefBool(CFSTR("allSecure"), NO));
    if (!ok) return;
    if (tf.rightView) return;

    objc_setAssociatedObject(tf, kSWPDone, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UIButton *b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.frame = CGRectMake(0, 0, 38, 30);
    b.tintColor = [UIColor secondaryLabelColor];
    updateIcon(b, YES);

    __weak UITextField *wtf = tf;
    __weak UIButton *wb = b;
    [b addAction:[UIAction actionWithHandler:^(__kindof UIAction *a) {
        UITextField *t = wtf; UIButton *bb = wb;
        if (t && bb) setSecure(t, bb, !t.secureTextEntry);
    }] forControlEvents:UIControlEventTouchUpInside];

    tf.rightView = b;
    tf.rightViewMode = UITextFieldViewModeAlways;

    if (prefBool(CFSTR("defaultVisible"), NO)) setSecure(tf, b, NO);
}

%hook UITextField
- (void)didMoveToWindow {
    %orig;
    if (self.window) setupField(self);
}
- (BOOL)becomeFirstResponder {
    BOOL r = %orig;
    setupField(self);
    return r;
}
%end
