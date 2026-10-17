# expense

A simple command-line expense tracker written in Rust. No dependencies, just the standard library.

## Build

```
cargo build --release
```

The binary is created at `target/release/expense`. Copy it somewhere on your `PATH` to use it from anywhere:

```
cp target/release/expense ~/.local/bin/
```

## Usage

```
expense add <amount> <category> [description...]
expense list [category]
expense summary
expense delete <id>
expense help
```

### Examples

```
$ expense add 12.50 food lunch with Sam
Added #1: 12.50 [food]

$ expense add 40 transport taxi
Added #2: 40.00 [transport]

$ expense list
  ID  DATE            AMOUNT  CATEGORY      DESCRIPTION
   1  2026-10-17       12.50  food          lunch with Sam
   2  2026-10-17       40.00  transport     taxi
      TOTAL            52.50

$ expense summary
CATEGORY            TOTAL  SHARE
transport           40.00  76.2%
food                12.50  23.8%
ALL                 52.50

$ expense delete 2
Deleted #2
```

### Commands

| Command | Description |
| --- | --- |
| `add <amount> <category> [description...]` | Record an expense. The description is optional and can be several words. |
| `list [category]` | Show all expenses with a total, optionally filtered by category. Alias: `ls`. |
| `summary` | Show totals and percentage share per category, biggest first. |
| `delete <id>` | Remove an expense by its ID. Alias: `rm`. |
| `help` | Show usage. |

## Details

- **Amounts** accept `12`, `12.5` or `12.50`. They must be greater than zero and have at most two decimal places. They are stored as whole cents, so totals never suffer floating-point rounding errors.
- **Categories** are case-insensitive and stored in lowercase, so `Food` and `food` are the same category.
- **Dates** are set automatically to today's date in UTC (`YYYY-MM-DD`).
- **IDs** are never reused while newer entries exist: a new expense gets the highest existing ID plus one.

## Data file

Expenses are stored as tab-separated text, one per line:

```
id <TAB> date <TAB> cents <TAB> category <TAB> description
```

The file location is, in order of priority:

1. The path in the `EXPENSE_FILE` environment variable
2. `~/.expenses.tsv`

```
EXPENSE_FILE=./work-expenses.tsv expense add 25 office printer paper
```

Saves are written to a temporary file and then renamed into place, so a crash mid-write cannot corrupt your data.

## Tests

```
cargo test
```
