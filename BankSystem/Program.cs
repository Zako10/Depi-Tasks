using System;
using System.Collections.Generic;
using System.Linq;

namespace BankSystem
{
    class Transaction
    {
        public DateTime Date { get; }
        public string Type { get; }
        public decimal Amount { get; }
        public string Note { get; }

        public Transaction(string type, decimal amount, string note = "")
        {
            Date = DateTime.Now;
            Type = type;
            Amount = amount;
            Note = note;
        }

        public override string ToString()
        {
            return $"{Date:G} | {Type,-12} | Amount: {Amount,8} | {Note}";
        }
    }

    abstract class BankAccount
    {
        private static int _nextAccountNumber = 1000;

        public int AccountNumber { get; }
        public DateTime DateOpened { get; }
        protected decimal _balance;

        private readonly List<Transaction> _transactions = new List<Transaction>();

        public decimal Balance => _balance;

        protected BankAccount(decimal initialBalance)
        {
            if (initialBalance < 0) throw new ArgumentException("Initial balance cannot be negative.");
            AccountNumber = _nextAccountNumber++;
            DateOpened = DateTime.Now;
            _balance = initialBalance;

            if (initialBalance > 0)
                _transactions.Add(new Transaction("Deposit", initialBalance, "Initial balance"));
        }

        public virtual void Deposit(decimal amount)
        {
            if (amount <= 0) throw new ArgumentException("Deposit amount must be positive.");
            _balance += amount;
            _transactions.Add(new Transaction("Deposit", amount));
        }

        public virtual bool Withdraw(decimal amount)
        {
            if (amount <= 0) throw new ArgumentException("Withdraw amount must be positive.");
            if (!CanWithdraw(amount)) return false;

            _balance -= amount;
            _transactions.Add(new Transaction("Withdraw", amount));
            return true;
        }

        public bool TransferTo(BankAccount target, decimal amount)
        {
            if (target == null) throw new ArgumentNullException(nameof(target));
            if (Withdraw(amount))
            {
                target.Deposit(amount);
                _transactions.Add(new Transaction("TransferOut", amount, $"To #{target.AccountNumber}"));
                target._transactions.Add(new Transaction("TransferIn", amount, $"From #{AccountNumber}"));
                return true;
            }
            return false;
        }

        protected abstract bool CanWithdraw(decimal amount);

        public abstract decimal CalculateMonthlyInterest();

        public virtual void ShowAccountDetails()
        {
            Console.WriteLine($"Account Number: {AccountNumber}");
            Console.WriteLine($"Opened On     : {DateOpened}");
            Console.WriteLine($"Balance       : {Balance}");
        }

        public void ShowTransactionHistory()
        {
            Console.WriteLine($"--- Transactions for Account #{AccountNumber} ---");
            if (_transactions.Count == 0)
            {
                Console.WriteLine("No transactions.");
                return;
            }

            foreach (var t in _transactions)
                Console.WriteLine(t);
        }
    }

    class SavingsAccount : BankAccount
    {
        public decimal InterestRate { get; set; } 

        public SavingsAccount(decimal initialBalance, decimal interestRate)
            : base(initialBalance)
        {
            if (interestRate < 0) throw new ArgumentException("Interest rate cannot be negative.");
            InterestRate = interestRate;
        }

        protected override bool CanWithdraw(decimal amount)
        {
            return _balance >= amount;
        }

        public override decimal CalculateMonthlyInterest()
        {
            return _balance * (InterestRate / 100m) / 12m;
        }

        public override void ShowAccountDetails()
        {
            base.ShowAccountDetails();
            Console.WriteLine($"Type          : Savings");
            Console.WriteLine($"Interest Rate : {InterestRate}%");
        }
    }

    class CurrentAccount : BankAccount
    {
        public decimal OverdraftLimit { get; set; }

        public CurrentAccount(decimal initialBalance, decimal overdraftLimit)
            : base(initialBalance)
        {
            if (overdraftLimit < 0) throw new ArgumentException("Overdraft limit cannot be negative.");
            OverdraftLimit = overdraftLimit;
        }

        protected override bool CanWithdraw(decimal amount)
        {
            return _balance - amount >= -OverdraftLimit;
        }

        public override decimal CalculateMonthlyInterest()
        {

            return 0m;
        }

        public override void ShowAccountDetails()
        {
            base.ShowAccountDetails();
            Console.WriteLine($"Type          : Current");
            Console.WriteLine($"Overdraft Lim.: {OverdraftLimit}");
        }
    }


    class Customer
    {
        private static int _nextCustomerId = 1;

        public int Id { get; }
        public string FullName { get; private set; }
        public string NationalId { get; }
        public DateTime DateOfBirth { get; private set; }

        private readonly List<BankAccount> _accounts = new List<BankAccount>();
        public IReadOnlyList<BankAccount> Accounts => _accounts;

        public Customer(string fullName, string nationalId, DateTime dob)
        {
            if (string.IsNullOrWhiteSpace(fullName)) throw new ArgumentException("Name required.");
            if (string.IsNullOrWhiteSpace(nationalId)) throw new ArgumentException("National ID required.");

            Id = _nextCustomerId++;
            FullName = fullName;
            NationalId = nationalId;
            DateOfBirth = dob;
        }

        public void UpdateDetails(string newName, DateTime newDob)
        {
            if (string.IsNullOrWhiteSpace(newName)) throw new ArgumentException("Name required.");
            FullName = newName;
            DateOfBirth = newDob;
        }

        public void AddAccount(BankAccount account)
        {
            if (account == null) throw new ArgumentNullException(nameof(account));
            _accounts.Add(account);
        }

        public bool CanBeRemoved()
        {
            return _accounts.All(a => a.Balance == 0);
        }

        public decimal TotalBalance()
        {
            return _accounts.Sum(a => a.Balance);
        }

        public void ShowCustomerReport()
        {
            Console.WriteLine($"Customer #{Id} | {FullName} | NID: {NationalId} | DOB: {DateOfBirth:d}");
            if (_accounts.Count == 0)
            {
                Console.WriteLine("  No accounts.");
                return;
            }

            foreach (var acc in _accounts)
            {
                Console.WriteLine("  -------------------------");
                acc.ShowAccountDetails();
            }

            Console.WriteLine($"  Total Balance: {TotalBalance()}");
        }
    }
    class Bank
    {
        public string Name { get; }
        public string BranchCode { get; }

        private readonly List<Customer> _customers = new List<Customer>();

        public Bank(string name, string branchCode)
        {
            if (string.IsNullOrWhiteSpace(name)) throw new ArgumentException("Bank name required.");
            if (string.IsNullOrWhiteSpace(branchCode)) throw new ArgumentException("Branch code required.");
            Name = name;
            BranchCode = branchCode;
        }

        public Customer AddCustomer(string fullName, string nationalId, DateTime dob)
        {
            var customer = new Customer(fullName, nationalId, dob);
            _customers.Add(customer);
            return customer;
        }

        public bool RemoveCustomer(int customerId)
        {
            var c = _customers.FirstOrDefault(x => x.Id == customerId);
            if (c == null) return false;
            if (!c.CanBeRemoved()) return false;

            _customers.Remove(c);
            return true;
        }

        public IEnumerable<Customer> SearchCustomer(string query)
        {
            if (string.IsNullOrWhiteSpace(query)) return Enumerable.Empty<Customer>();

            return _customers.Where(c =>
                c.FullName.Contains(query, StringComparison.OrdinalIgnoreCase) ||
                c.NationalId.Contains(query, StringComparison.OrdinalIgnoreCase));
        }

        public Customer? GetCustomerById(int id)
        {
            return _customers.FirstOrDefault(c => c.Id == id);
        }

        public void ShowBankReport()
        {
            Console.WriteLine($"=== Bank Report: {Name} ({BranchCode}) ===");
            if (_customers.Count == 0)
            {
                Console.WriteLine("No customers.");
                return;
            }

            foreach (var c in _customers)
            {
                Console.WriteLine("----------------------------------------");
                c.ShowCustomerReport();
            }
        }
    }

    class Program
    {
        static void Main(string[] args)
        {
            Bank bank = new Bank("Amr Bank", "BR001");

            Customer c1 = bank.AddCustomer("Amr Soliman", "12345678901234", new DateTime(2005, 1, 19));
            Customer c2 = bank.AddCustomer("Khaled Soliman", "98765432109876", new DateTime(2008, 7, 16));

            var sa1 = new SavingsAccount(initialBalance: 10000m, interestRate: 6m);
            var ca1 = new CurrentAccount(initialBalance: 2000m, overdraftLimit: 1500m);

            c1.AddAccount(sa1);
            c1.AddAccount(ca1);

            var sa2 = new SavingsAccount(initialBalance: 5000m, interestRate: 5m);
            c2.AddAccount(sa2);

            sa1.Deposit(500m);
            ca1.Withdraw(2500m); 
            sa1.TransferTo(sa2, 1000m);

            bank.ShowBankReport();

            Console.WriteLine("\n=== Monthly Interest Calculation ===");
            foreach (var acc in c1.Accounts)
            {
                Console.WriteLine($"Account #{acc.AccountNumber} Interest: {acc.CalculateMonthlyInterest()}");
            }

            Console.WriteLine();
            sa1.ShowTransactionHistory();
            Console.WriteLine();
            ca1.ShowTransactionHistory();

            Console.WriteLine("\n=== Search for 'Amr' ===");
            foreach (var cust in bank.SearchCustomer("Amr"))
            {
                Console.WriteLine($"Found: {cust.FullName} (ID: {cust.Id})");
            }

            Console.ReadLine();
        }
    }
}
