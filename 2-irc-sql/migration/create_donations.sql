CREATE TABLE IF NOT EXISTS donations (
  donation_id varchar(255) PRIMARY KEY,
  account_id varchar(255),
  amount money,
  is_revenue varchar(255),
  close_date DATE,
  FOREIGN KEY (account_id)
  REFERENCES accounts(account_id)
)