#import <Foundation/Foundation.h>
#import "Expense.h"

NS_ASSUME_NONNULL_BEGIN

@interface ExpenseStore : NSObject

@property (nonatomic, copy, readonly) NSArray<Expense *> *expenses;

- (instancetype)initWithPath:(NSString *)path;

- (BOOL)load:(NSError **)error;
- (BOOL)save:(NSError **)error;

- (Expense *)addExpenseWithTitle:(NSString *)title
                        category:(NSString *)category
                          amount:(double)amount;
- (BOOL)removeExpenseWithIdentifier:(NSInteger)identifier;

- (double)total;
- (NSDictionary<NSString *, NSNumber *> *)totalsByCategory;

@end

NS_ASSUME_NONNULL_END
