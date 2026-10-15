#import <Foundation/Foundation.h>
#import "ExpenseStore.h"

static void out(NSString *format, ...) NS_FORMAT_FUNCTION(1, 2);
static void out(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *s = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    fputs([s UTF8String], stdout);
    fputs("\n", stdout);
}

static void usage(void) {
    out(@"Expense Tracker");
    out(@"");
    out(@"Usage:");
    out(@"  expenses add <amount> <category> <description...>");
    out(@"  expenses list");
    out(@"  expenses summary");
    out(@"  expenses delete <id>");
    out(@"");
    out(@"Data file: $EXPENSES_FILE, or ~/.expenses.json by default.");
}

static BOOL parseNumber(NSString *str, double *value) {
    NSScanner *scanner = [NSScanner scannerWithString:str];
    return [scanner scanDouble:value] && [scanner isAtEnd];
}

static void printList(ExpenseStore *store) {
    if (store.expenses.count == 0) {
        out(@"No expenses yet. Add one with: expenses add 12.50 food Lunch");
        return;
    }

    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
    fmt.dateFormat = @"yyyy-MM-dd";

    out(@"%-4s  %-10s  %-12s  %10s  %@", "ID", "DATE", "CATEGORY", "AMOUNT", @"DESCRIPTION");
    for (Expense *e in store.expenses) {
        out(@"%-4ld  %-10s  %-12s  %10.2f  %@",
            (long)e.identifier,
            [[fmt stringFromDate:e.date] UTF8String],
            [e.category UTF8String],
            e.amount,
            e.title);
    }
    out(@"%-4s  %-10s  %-12s  %10.2f", "", "", "TOTAL", [store total]);
}

static void printSummary(ExpenseStore *store) {
    NSDictionary<NSString *, NSNumber *> *totals = [store totalsByCategory];
    if (totals.count == 0) {
        out(@"No expenses yet.");
        return;
    }

    double grand = [store total];
    NSArray<NSString *> *keys = [totals keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
        return [b compare:a]; // biggest first
    }];

    out(@"%-14s  %10s  %6s", "CATEGORY", "TOTAL", "SHARE");
    for (NSString *key in keys) {
        double amount = totals[key].doubleValue;
        out(@"%-14s  %10.2f  %5.1f%%", [key UTF8String], amount, grand > 0 ? amount / grand * 100.0 : 0.0);
    }
    out(@"%-14s  %10.2f", "TOTAL", grand);
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSArray<NSString *> *args = [[NSProcessInfo processInfo] arguments];
        if (args.count < 2) {
            usage();
            return 1;
        }

        NSString *path = [[NSProcessInfo processInfo] environment][@"EXPENSES_FILE"];
        if (path.length == 0) {
            path = [NSHomeDirectory() stringByAppendingPathComponent:@".expenses.json"];
        }

        ExpenseStore *store = [[ExpenseStore alloc] initWithPath:path];
        NSError *error = nil;
        if (![store load:&error]) {
            out(@"Could not read %@: %@", path, error.localizedDescription);
            return 1;
        }

        NSString *command = [args[1] lowercaseString];

        if ([command isEqualToString:@"add"]) {
            if (args.count < 5) {
                out(@"Usage: expenses add <amount> <category> <description...>");
                return 1;
            }
            double amount = 0;
            if (!parseNumber(args[2], &amount) || amount <= 0) {
                out(@"Amount must be a positive number, got '%@'.", args[2]);
                return 1;
            }
            NSString *category = args[3];
            NSString *title = [[args subarrayWithRange:NSMakeRange(4, args.count - 4)] componentsJoinedByString:@" "];

            Expense *e = [store addExpenseWithTitle:title category:category amount:amount];
            if (![store save:&error]) {
                out(@"Could not save: %@", error.localizedDescription);
                return 1;
            }
            out(@"Added #%ld: %.2f [%@] %@", (long)e.identifier, e.amount, e.category, e.title);

        } else if ([command isEqualToString:@"list"]) {
            printList(store);

        } else if ([command isEqualToString:@"summary"]) {
            printSummary(store);

        } else if ([command isEqualToString:@"delete"]) {
            double idValue = 0;
            if (args.count < 3 || !parseNumber(args[2], &idValue)) {
                out(@"Usage: expenses delete <id>");
                return 1;
            }
            if (![store removeExpenseWithIdentifier:(NSInteger)idValue]) {
                out(@"No expense with id %ld.", (long)idValue);
                return 1;
            }
            if (![store save:&error]) {
                out(@"Could not save: %@", error.localizedDescription);
                return 1;
            }
            out(@"Deleted #%ld.", (long)idValue);

        } else {
            usage();
            return 1;
        }
    }
    return 0;
}
