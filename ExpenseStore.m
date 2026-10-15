#import "ExpenseStore.h"

@interface ExpenseStore ()
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSMutableArray<Expense *> *items;
@end

@implementation ExpenseStore

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        _path = [path copy];
        _items = [NSMutableArray array];
    }
    return self;
}

- (NSArray<Expense *> *)expenses {
    return [self.items copy];
}

- (BOOL)load:(NSError **)error {
    [self.items removeAllObjects];

    if (![[NSFileManager defaultManager] fileExistsAtPath:self.path]) {
        return YES; // First run: nothing saved yet.
    }

    NSData *data = [NSData dataWithContentsOfFile:self.path options:0 error:error];
    if (!data) return NO;

    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (!json) return NO;

    if (![json isKindOfClass:[NSArray class]]) {
        if (error) {
            *error = [NSError errorWithDomain:@"ExpenseStore" code:1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Data file is not a JSON array."}];
        }
        return NO;
    }

    for (id entry in (NSArray *)json) {
        if (![entry isKindOfClass:[NSDictionary class]]) continue;
        Expense *e = [Expense expenseFromDictionary:entry];
        if (e) [self.items addObject:e];
    }
    return YES;
}

- (BOOL)save:(NSError **)error {
    NSMutableArray *dicts = [NSMutableArray arrayWithCapacity:self.items.count];
    for (Expense *e in self.items) {
        [dicts addObject:[e toDictionary]];
    }

    NSData *data = [NSJSONSerialization dataWithJSONObject:dicts
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:error];
    if (!data) return NO;
    return [data writeToFile:self.path options:NSDataWritingAtomic error:error];
}

- (NSInteger)nextIdentifier {
    NSInteger maxId = 0;
    for (Expense *e in self.items) {
        if (e.identifier > maxId) maxId = e.identifier;
    }
    return maxId + 1;
}

- (Expense *)addExpenseWithTitle:(NSString *)title
                        category:(NSString *)category
                          amount:(double)amount {
    Expense *e = [[Expense alloc] initWithIdentifier:[self nextIdentifier]
                                               title:title
                                            category:category
                                              amount:amount
                                                date:[NSDate date]];
    [self.items addObject:e];
    return e;
}

- (BOOL)removeExpenseWithIdentifier:(NSInteger)identifier {
    for (Expense *e in self.items) {
        if (e.identifier == identifier) {
            [self.items removeObject:e];
            return YES;
        }
    }
    return NO;
}

- (double)total {
    double sum = 0;
    for (Expense *e in self.items) sum += e.amount;
    return sum;
}

- (NSDictionary<NSString *, NSNumber *> *)totalsByCategory {
    NSMutableDictionary<NSString *, NSNumber *> *totals = [NSMutableDictionary dictionary];
    for (Expense *e in self.items) {
        NSString *key = [e.category lowercaseString];
        totals[key] = @([totals[key] doubleValue] + e.amount);
    }
    return totals;
}

@end
