class DatabaseSchema {
  static const int version = 1;
  static const String databaseName = 'sigma_accounting.db';

  static const List<String> createTablesQueries = [
    // Companies
    '''
    CREATE TABLE IF NOT EXISTS companies (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      name_ar TEXT NOT NULL,
      tax_number TEXT,
      commercial_registry TEXT,
      phone TEXT,
      address TEXT,
      currency TEXT NOT NULL DEFAULT 'EGP',
      logo_path TEXT
    );
    ''',

    // Fiscal Years
    '''
    CREATE TABLE IF NOT EXISTS fiscal_years (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      is_closed INTEGER NOT NULL DEFAULT 0
    );
    ''',

    // Accounting Periods (Monthly)
    '''
    CREATE TABLE IF NOT EXISTS accounting_periods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fiscal_year_id INTEGER NOT NULL,
      period_number INTEGER NOT NULL,
      name TEXT NOT NULL,
      start_date TEXT NOT NULL,
      end_date TEXT NOT NULL,
      is_closed INTEGER NOT NULL DEFAULT 0,
      closed_at TEXT,
      closed_by TEXT,
      FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years (id) ON DELETE CASCADE
    );
    ''',

    // Account Groups
    '''
    CREATE TABLE IF NOT EXISTS account_groups (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      name_ar TEXT NOT NULL,
      parent_id INTEGER,
      category TEXT NOT NULL
    );
    ''',

    // Accounts (Chart of Accounts)
    '''
    CREATE TABLE IF NOT EXISTS accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      name_ar TEXT NOT NULL,
      group_id INTEGER,
      parent_id INTEGER,
      account_type TEXT NOT NULL,
      sub_type TEXT NOT NULL,
      normal_balance TEXT NOT NULL DEFAULT 'debit',
      is_active INTEGER NOT NULL DEFAULT 1,
      requires_project INTEGER NOT NULL DEFAULT 0,
      requires_analytical INTEGER NOT NULL DEFAULT 0,
      notes TEXT,
      level INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (group_id) REFERENCES account_groups (id) ON DELETE SET NULL,
      FOREIGN KEY (parent_id) REFERENCES accounts (id) ON DELETE SET NULL
    );
    ''',

    // Projects
    '''
    CREATE TABLE IF NOT EXISTS projects (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      client TEXT,
      start_date TEXT,
      expected_end_date TEXT,
      actual_end_date TEXT,
      status TEXT NOT NULL DEFAULT 'active',
      budget REAL NOT NULL DEFAULT 0.0,
      notes TEXT
    );
    ''',

    // Analytical Items (بند التوجيه التحليلي)
    '''
    CREATE TABLE IF NOT EXISTS analytical_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'عام',
      is_active INTEGER NOT NULL DEFAULT 1,
      notes TEXT
    );
    ''',

    // Units (الوحدات)
    '''
    CREATE TABLE IF NOT EXISTS units (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      symbol TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    );
    ''',

    // Contractors (المقاولين)
    '''
    CREATE TABLE IF NOT EXISTS contractors (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      tax_number TEXT,
      project_id INTEGER,
      opening_balance REAL NOT NULL DEFAULT 0.0,
      notes TEXT,
      is_active INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
    );
    ''',

    // Suppliers (الموردين)
    '''
    CREATE TABLE IF NOT EXISTS suppliers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      tax_number TEXT,
      opening_balance REAL NOT NULL DEFAULT 0.0,
      notes TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    );
    ''',

    // Customers (العملاء)
    '''
    CREATE TABLE IF NOT EXISTS customers (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      phone TEXT,
      address TEXT,
      tax_number TEXT,
      opening_balance REAL NOT NULL DEFAULT 0.0,
      notes TEXT,
      is_active INTEGER NOT NULL DEFAULT 1
    );
    ''',

    // Opening Balances
    '''
    CREATE TABLE IF NOT EXISTS opening_balances (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      fiscal_year_id INTEGER NOT NULL,
      account_id INTEGER NOT NULL,
      project_id INTEGER,
      analytical_item_id INTEGER,
      debit REAL NOT NULL DEFAULT 0.0,
      credit REAL NOT NULL DEFAULT 0.0,
      description TEXT,
      FOREIGN KEY (fiscal_year_id) REFERENCES fiscal_years (id) ON DELETE CASCADE,
      FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
      FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL,
      FOREIGN KEY (analytical_item_id) REFERENCES analytical_items (id) ON DELETE SET NULL
    );
    ''',

    // Journal Entries (Headers)
    '''
    CREATE TABLE IF NOT EXISTS journal_entries (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      entry_number TEXT NOT NULL UNIQUE,
      date TEXT NOT NULL,
      description TEXT NOT NULL,
      reference_number TEXT,
      project_id INTEGER,
      status TEXT NOT NULL DEFAULT 'draft',
      created_by TEXT,
      created_at TEXT NOT NULL,
      posted_by TEXT,
      posted_at TEXT,
      cancelled_by TEXT,
      cancelled_at TEXT,
      cancel_reason TEXT,
      FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL
    );
    ''',

    // Journal Lines (Transaction Lines)
    '''
    CREATE TABLE IF NOT EXISTS journal_lines (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      journal_entry_id INTEGER NOT NULL,
      line_number INTEGER NOT NULL,
      account_id INTEGER NOT NULL,
      project_id INTEGER,
      analytical_item_id INTEGER,
      unit_id INTEGER,
      quantity REAL NOT NULL DEFAULT 0.0,
      unit_price REAL NOT NULL DEFAULT 0.0,
      debit REAL NOT NULL DEFAULT 0.0,
      credit REAL NOT NULL DEFAULT 0.0,
      contractor_id INTEGER,
      supplier_id INTEGER,
      customer_id INTEGER,
      description TEXT,
      reference TEXT,
      FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id) ON DELETE CASCADE,
      FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE RESTRICT,
      FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE SET NULL,
      FOREIGN KEY (analytical_item_id) REFERENCES analytical_items (id) ON DELETE SET NULL,
      FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE SET NULL,
      FOREIGN KEY (contractor_id) REFERENCES contractors (id) ON DELETE SET NULL,
      FOREIGN KEY (supplier_id) REFERENCES suppliers (id) ON DELETE SET NULL,
      FOREIGN KEY (customer_id) REFERENCES customers (id) ON DELETE SET NULL
    );
    ''',

    // Roles
    '''
    CREATE TABLE IF NOT EXISTS roles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      code TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      description TEXT,
      is_system INTEGER NOT NULL DEFAULT 0
    );
    ''',

    // Permissions
    '''
    CREATE TABLE IF NOT EXISTS permissions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      role_id INTEGER NOT NULL,
      permission_key TEXT NOT NULL,
      is_granted INTEGER NOT NULL DEFAULT 1,
      FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
      UNIQUE(role_id, permission_key)
    );
    ''',

    // Users
    '''
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      full_name TEXT NOT NULL,
      email TEXT,
      password_hash TEXT NOT NULL,
      role_id INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      last_login_at TEXT,
      FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE RESTRICT
    );
    ''',

    // Audit Logs
    '''
    CREATE TABLE IF NOT EXISTS audit_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER,
      username TEXT NOT NULL,
      action TEXT NOT NULL,
      record_type TEXT NOT NULL,
      record_id TEXT,
      details TEXT,
      old_values TEXT,
      new_values TEXT,
      created_at TEXT NOT NULL
    );
    ''',

    // Attachments
    '''
    CREATE TABLE IF NOT EXISTS attachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      record_type TEXT NOT NULL,
      record_id INTEGER NOT NULL,
      file_name TEXT NOT NULL,
      file_path TEXT NOT NULL,
      file_size INTEGER,
      mime_type TEXT,
      created_at TEXT NOT NULL
    );
    ''',

    // Indexes for high performance
    'CREATE INDEX IF NOT EXISTS idx_journal_entries_date_status ON journal_entries(date, status);',
    'CREATE INDEX IF NOT EXISTS idx_journal_entries_project ON journal_entries(project_id);',
    'CREATE INDEX IF NOT EXISTS idx_journal_lines_entry ON journal_lines(journal_entry_id);',
    'CREATE INDEX IF NOT EXISTS idx_journal_lines_account ON journal_lines(account_id);',
    'CREATE INDEX IF NOT EXISTS idx_journal_lines_project ON journal_lines(project_id);',
    'CREATE INDEX IF NOT EXISTS idx_journal_lines_contractor ON journal_lines(contractor_id);',
    'CREATE INDEX IF NOT EXISTS idx_journal_lines_analytical ON journal_lines(analytical_item_id);',
    'CREATE INDEX IF NOT EXISTS idx_accounts_code ON accounts(code);',
    'CREATE INDEX IF NOT EXISTS idx_accounts_type ON accounts(account_type);',
    'CREATE INDEX IF NOT EXISTS idx_audit_created ON audit_logs(created_at);',
  ];
}
