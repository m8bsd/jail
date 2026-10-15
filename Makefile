SRCS = main.m Expense.m ExpenseStore.m
TARGET = expenses

UNAME := $(shell uname)

ifeq ($(UNAME), Darwin)
  # macOS: Foundation ships with the system
  CC = clang
  CFLAGS = -fobjc-arc -Wall -Wextra
  LIBS = -framework Foundation
else
  # Linux: needs GNUstep (e.g. apt install gnustep-devel clang)
  CC = clang
  CFLAGS = -fobjc-arc -Wall -Wextra $(shell gnustep-config --objc-flags) -fobjc-runtime=gnustep-2.0
  LIBS = $(shell gnustep-config --base-libs)
endif

$(TARGET): $(SRCS) Expense.h ExpenseStore.h
	$(CC) $(CFLAGS) $(SRCS) -o $(TARGET) $(LIBS)

clean:
	rm -f $(TARGET)

.PHONY: clean
