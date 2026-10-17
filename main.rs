use std::collections::BTreeMap;
use std::env;
use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use std::process;
use std::time::{SystemTime, UNIX_EPOCH};

/// One expense. Amounts are stored in cents to avoid floating-point errors.
struct Expense {
    id: u32,
    date: String,
    cents: i64,
    category: String,
    description: String,
}

const HELP: &str = "\
Simple expense tracker

USAGE:
    expense add <amount> <category> [description...]
    expense list [category]
    expense summary
    expense delete <id>
    expense help

EXAMPLES:
    expense add 12.50 food lunch with Sam
    expense list food
    expense delete 3

Data file: $EXPENSE_FILE, or ~/.expenses.tsv if unset.";

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();
    let result = match args.first().map(String::as_str) {
        Some("add") => cmd_add(&args[1..]),
        Some("list") | Some("ls") => cmd_list(&args[1..]),
        Some("summary") => cmd_summary(),
        Some("delete") | Some("rm") => cmd_delete(&args[1..]),
        Some("help") | Some("--help") | Some("-h") | None => {
            println!("{HELP}");
            Ok(())
        }
        Some(other) => Err(format!("unknown command '{other}'\n\n{HELP}")),
    };
    if let Err(msg) = result {
        eprintln!("error: {msg}");
        process::exit(1);
    }
}

// ---------- commands ----------

fn cmd_add(args: &[String]) -> Result<(), String> {
    if args.len() < 2 {
        return Err("usage: expense add <amount> <category> [description...]".into());
    }
    let cents = parse_amount(&args[0])?;
    let category = args[1].to_lowercase();
    let description = args[2..].join(" ");

    let mut expenses = load()?;
    let id = expenses.iter().map(|e| e.id).max().unwrap_or(0) + 1;
    expenses.push(Expense {
        id,
        date: today(),
        cents,
        category: sanitize(&category),
        description: sanitize(&description),
    });
    save(&expenses)?;
    println!("Added #{id}: {} [{}]", format_cents(cents), category);
    Ok(())
}

fn cmd_list(args: &[String]) -> Result<(), String> {
    let filter = args.first().map(|c| c.to_lowercase());
    let expenses = load()?;
    let rows: Vec<&Expense> = expenses
        .iter()
        .filter(|e| filter.as_ref().map_or(true, |f| &e.category == f))
        .collect();

    if rows.is_empty() {
        println!("No expenses found.");
        return Ok(());
    }

    println!("{:>4}  {:<10}  {:>10}  {:<12}  {}", "ID", "DATE", "AMOUNT", "CATEGORY", "DESCRIPTION");
    for e in &rows {
        println!(
            "{:>4}  {:<10}  {:>10}  {:<12}  {}",
            e.id,
            e.date,
            format_cents(e.cents),
            e.category,
            e.description
        );
    }
    let total: i64 = rows.iter().map(|e| e.cents).sum();
    println!("{:>4}  {:<10}  {:>10}", "", "TOTAL", format_cents(total));
    Ok(())
}

fn cmd_summary() -> Result<(), String> {
    let expenses = load()?;
    if expenses.is_empty() {
        println!("No expenses yet.");
        return Ok(());
    }

    let mut by_category: BTreeMap<&str, i64> = BTreeMap::new();
    for e in &expenses {
        *by_category.entry(&e.category).or_insert(0) += e.cents;
    }
    let total: i64 = by_category.values().sum();

    // Biggest spend first.
    let mut rows: Vec<(&str, i64)> = by_category.into_iter().collect();
    rows.sort_by(|a, b| b.1.cmp(&a.1));

    println!("{:<14} {:>10} {:>6}", "CATEGORY", "TOTAL", "SHARE");
    for (cat, cents) in rows {
        let share = if total != 0 { cents as f64 * 100.0 / total as f64 } else { 0.0 };
        println!("{:<14} {:>10} {:>5.1}%", cat, format_cents(cents), share);
    }
    println!("{:<14} {:>10}", "ALL", format_cents(total));
    Ok(())
}

fn cmd_delete(args: &[String]) -> Result<(), String> {
    let id: u32 = args
        .first()
        .ok_or("usage: expense delete <id>")?
        .parse()
        .map_err(|_| "id must be a positive number".to_string())?;

    let mut expenses = load()?;
    let before = expenses.len();
    expenses.retain(|e| e.id != id);
    if expenses.len() == before {
        return Err(format!("no expense with id {id}"));
    }
    save(&expenses)?;
    println!("Deleted #{id}");
    Ok(())
}

// ---------- storage (tab-separated: id, date, cents, category, description) ----------

fn data_path() -> PathBuf {
    if let Ok(p) = env::var("EXPENSE_FILE") {
        return PathBuf::from(p);
    }
    let home = env::var("HOME").or_else(|_| env::var("USERPROFILE")).unwrap_or_else(|_| ".".into());
    PathBuf::from(home).join(".expenses.tsv")
}

fn load() -> Result<Vec<Expense>, String> {
    let path = data_path();
    let text = match fs::read_to_string(&path) {
        Ok(t) => t,
        Err(e) if e.kind() == io::ErrorKind::NotFound => return Ok(Vec::new()),
        Err(e) => return Err(format!("could not read {}: {e}", path.display())),
    };

    let mut out = Vec::new();
    for (n, line) in text.lines().enumerate().filter(|(_, l)| !l.trim().is_empty()) {
        let f: Vec<&str> = line.splitn(5, '\t').collect();
        if f.len() < 4 {
            return Err(format!("{} line {}: malformed entry", path.display(), n + 1));
        }
        out.push(Expense {
            id: f[0].parse().map_err(|_| format!("{} line {}: bad id", path.display(), n + 1))?,
            date: f[1].to_string(),
            cents: f[2].parse().map_err(|_| format!("{} line {}: bad amount", path.display(), n + 1))?,
            category: f[3].to_string(),
            description: f.get(4).unwrap_or(&"").to_string(),
        });
    }
    Ok(out)
}

fn save(expenses: &[Expense]) -> Result<(), String> {
    let path = data_path();
    let tmp = path.with_extension("tmp");
    let mut buf = String::new();
    for e in expenses {
        buf.push_str(&format!("{}\t{}\t{}\t{}\t{}\n", e.id, e.date, e.cents, e.category, e.description));
    }
    // Write to a temp file then rename, so a crash can't corrupt the data.
    let mut file = fs::File::create(&tmp).map_err(|e| format!("could not write {}: {e}", tmp.display()))?;
    file.write_all(buf.as_bytes()).map_err(|e| e.to_string())?;
    fs::rename(&tmp, &path).map_err(|e| format!("could not save {}: {e}", path.display()))
}

// ---------- helpers ----------

/// Tabs and newlines would break the file format, so flatten them to spaces.
fn sanitize(s: &str) -> String {
    s.replace(['\t', '\n', '\r'], " ").trim().to_string()
}

/// Parse "12", "12.5" or "12.50" into cents. Rejects zero, negatives and junk.
fn parse_amount(s: &str) -> Result<i64, String> {
    let bad = || format!("'{s}' is not a valid amount (try 12.50)");
    let (whole, frac) = match s.split_once('.') {
        Some((w, f)) => (w, f),
        None => (s, ""),
    };
    if whole.is_empty() && frac.is_empty() {
        return Err(bad());
    }
    if !whole.chars().all(|c| c.is_ascii_digit()) || !frac.chars().all(|c| c.is_ascii_digit()) || frac.len() > 2 {
        return Err(bad());
    }
    let whole: i64 = if whole.is_empty() { 0 } else { whole.parse().map_err(|_| bad())? };
    let frac: i64 = match frac.len() {
        0 => 0,
        1 => frac.parse::<i64>().map_err(|_| bad())? * 10,
        _ => frac.parse().map_err(|_| bad())?,
    };
    let cents = whole.checked_mul(100).and_then(|w| w.checked_add(frac)).ok_or_else(bad)?;
    if cents == 0 {
        return Err("amount must be greater than zero".into());
    }
    Ok(cents)
}

fn format_cents(cents: i64) -> String {
    format!("{}.{:02}", cents / 100, cents % 100)
}

/// Today's date (UTC) as YYYY-MM-DD, without needing a date crate.
fn today() -> String {
    let secs = SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0);
    let days = (secs / 86_400) as i64;
    // Civil-from-days algorithm (Howard Hinnant).
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097);
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let y = yoe + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let y = if m <= 2 { y + 1 } else { y };
    format!("{y:04}-{m:02}-{d:02}")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_amounts() {
        assert_eq!(parse_amount("12"), Ok(1200));
        assert_eq!(parse_amount("12.5"), Ok(1250));
        assert_eq!(parse_amount("12.05"), Ok(1205));
        assert_eq!(parse_amount(".99"), Ok(99));
        assert!(parse_amount("abc").is_err());
        assert!(parse_amount("-5").is_err());
        assert!(parse_amount("1.234").is_err());
        assert!(parse_amount("0").is_err());
    }

    #[test]
    fn formats_cents() {
        assert_eq!(format_cents(1205), "12.05");
        assert_eq!(format_cents(5), "0.05");
    }
}
