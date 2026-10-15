#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Expense : NSObject

@property (nonatomic, readonly) NSInteger identifier;
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, readonly) double amount;
@property (nonatomic, strong, readonly) NSDate *date;

- (instancetype)initWithIdentifier:(NSInteger)identifier
                             title:(NSString *)title
                          category:(NSString *)category
                            amount:(double)amount
                              date:(NSDate *)date;

- (NSDictionary<NSString *, id> *)toDictionary;
+ (nullable instancetype)expenseFromDictionary:(NSDictionary<NSString *, id> *)dict;

@end

NS_ASSUME_NONNULL_END
