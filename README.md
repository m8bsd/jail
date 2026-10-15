# Expense Tracker (Objective-C)

A simple command-line expense tracker written in Objective-C using only Foundation (ARC). Expenses are stored as JSON.

## Files

- `Expense.h` / `Expense.m`: the expense model (id, title, category, amount, date) with JSON conversion.
- `ExpenseStore.h` / `ExpenseStore.m`: loads and saves expenses, adds and removes them, computes totals.
- `main.m`: the command-line interface.
- `Makefile`: builds the `expenses` executable on macOS or Linux (GNUstep).

## Build

macOS (Xcode command-line tools installed):

    make

Linux (install GNUstep and clang first, e.g. `apt install gnustep-devel clang`):

    make

To remove the build: `make clean`

## Usage

    ./expenses add <amount> <category> <description...>
    ./expenses list
    ./expenses summary
    ./expenses delete <id>

Examples:

    ./expenses add 12.50 food Lunch with Sara
    ./expenses add 40 transport Taxi to airport
    ./expenses list
    ./expenses summary
    ./expenses delete 1

- `add` requires a positive numeric amount.
- `list` shows ID, date, category, amount and description, with a total.
- `summary` shows per-category totals and each category's share, largest first.
- `delete` removes an expense by its ID.

## Data file

Expenses are saved to `~/.expenses.json` by default. Set the `EXPENSES_FILE` environment variable to use a different file:

    EXPENSES_FILE=./my-expenses.json ./expenses list

## Status

This project has not been compiled or tested yet. If you hit a build error, check that Foundation (macOS) or GNUstep (Linux) is installed.
