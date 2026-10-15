#import "Expense.h"

@implementation Expense

- (instancetype)initWithIdentifier:(NSInteger)identifier
                             title:(NSString *)title
                          category:(NSString *)category
                            amount:(double)amount
                              date:(NSDate *)date {
    self = [super init];
    if (self) {
        _identifier = identifier;
        _title = [title copy];
        _category = [category copy];
        _amount = amount;
        _date = date;
    }
    return self;
}

- (NSDictionary<NSString *, id> *)toDictionary {
    return @{
        @"id": @(self.identifier),
        @"title": self.title,
        @"category": self.category,
        @"amount": @(self.amount),
        @"date": @([self.date timeIntervalSince1970])
    };
}

+ (nullable instancetype)expenseFromDictionary:(NSDictionary<NSString *, id> *)dict {
    NSNumber *ident = dict[@"id"];
    NSString *title = dict[@"title"];
    NSString *category = dict[@"category"];
    NSNumber *amount = dict[@"amount"];
    NSNumber *ts = dict[@"date"];

    if (![ident isKindOfClass:[NSNumber class]] ||
        ![title isKindOfClass:[NSString class]] ||
        ![category isKindOfClass:[NSString class]] ||
        ![amount isKindOfClass:[NSNumber class]] ||
        ![ts isKindOfClass:[NSNumber class]]) {
        return nil;
    }

    return [[Expense alloc] initWithIdentifier:ident.integerValue
                                         title:title
                                      category:category
                                        amount:amount.doubleValue
                                          date:[NSDate dateWithTimeIntervalSince1970:ts.doubleValue]];
}

@end
