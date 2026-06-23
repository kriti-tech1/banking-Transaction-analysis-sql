									--PROJECT TITLE-- 
					/*** Banking Transaction Analysis using PostgreSQL ***/
					
/* : PROJECT OVERVIEW --

.This project analyzes customer banking transactions using PostgreSQL.
.The database includes customers, accounts, and transactions tables.
.Various SQL concepts such as joins, CTEs, subqueries, and window functions were used to solve business problems.*/

CREATE DATABASE practice ;

-- customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(50),
    city VARCHAR(30)
);

INSERT INTO customers (customer_id, customer_name, city)
VALUES
(1, 'Rahul', 'Delhi'),
(2, 'Priya', 'Mumbai'),
(3, 'Amit', 'Jaipur'),
(4, 'Sneha', 'Delhi'),
(5, 'Karan', 'Pune');

--Accounts Table
CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    customer_id INT,
    account_type VARCHAR(20),
    balance DECIMAL(10,2),
    FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
);

INSERT INTO accounts (account_id, customer_id, account_type, balance)
VALUES
(101, 1, 'Savings', 50000),
(102, 2, 'Current', 75000),
(103, 3, 'Savings', 30000),
(104, 4, 'Savings', 90000),
(105, 5, 'Current', 45000);

--Transactions Table
CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    account_id INT,
    transaction_date DATE,
    transaction_type VARCHAR(20),
    amount DECIMAL(10,2),
    FOREIGN KEY (account_id)
    REFERENCES accounts(account_id)
);

INSERT INTO transactions(transaction_id, account_id, transaction_date, transaction_type, amount)
VALUES(1, 101, '2025-01-10', 'Deposit', 10000),
		(2, 101, '2025-01-15', 'Withdrawal', 5000),
		(3, 102, '2025-01-12', 'Deposit', 15000),
		(4, 103, '2025-01-14', 'Deposit', 8000),
		(5, 104, '2025-01-18', 'Withdrawal', 10000),
		(6, 105, '2025-01-20', 'Deposit', 12000),
		(7, 101, '2025-01-22', 'Deposit', 7000),
		(8, 102, '2025-01-25', 'Withdrawal', 4000),
		(9, 104, '2025-01-27', 'Deposit', 5000),
		(10, 105, '2025-01-29', 'Withdrawal', 3000);

SELECT * FROM customers;
SELECT * FROM accounts;
SELECT * FROM transactions;



	/*          **ER DIAGRAM**
       customers → accounts → transactions   


	         **SQL CONCEPTS USED**
			 
- JOIN
- GROUP BY
- HAVING
- CTE
- Subqueries
- Correlated Subqueries
- Window Functions
- RANK()
- LAG()
- Running Totals  */ 




--q1)Find customers who have made more than 1 transaction.
WITH transaction_cte AS (
			SELECT account_id ,
			COUNT(*) AS total_transaction
			FROM transactions
			GROUP BY account_id 
			HAVING (COUNT(*))>1
)
SELECT 
		c.customer_name ,
		t.total_transaction
		
FROM 
		customers c
JOIN
		 accounts a
ON c.customer_id= a.customer_id
JOIN
      transaction_cte t
ON a.account_id = t.account_id ;

--q2)Find the total deposited amount by each customer.
WITH total_trans AS (
		  SELECT account_id ,
      		SUM(amount)AS total_deposit 
		FROM transactions 
			WHERE transaction_type='Deposit'
			GROUP BY account_id
)
SELECT 
		c.customer_name,
		ct.total_deposit

FROM
		customers c
JOIN
       accounts a
ON c.customer_id = a.customer_id
JOIN 
     total_trans ct 
ON ct.account_id = a.account_id
ORDER BY total_deposit DESC;


--q3)Find the customer(s) whose account balance is greater than the average account balance.
WITH avg_cte AS (
	SELECT
		AVG(balance) AS avg_balance
	FROM accounts
	 
	     
)
SELECT 
	  
      c.customer_name ,
	  a.balance 
	  
FROM 
    customers c
JOIN
  	accounts  a
ON a.customer_id=c.customer_id
WHERE balance >(
       SELECT avg_balance 
	   FROM avg_cte 
);

--q4)Rank customers based on account balance.
SELECT 
      c.customer_name ,
	  a.balance ,
	  RANK() OVER (ORDER BY a.balance DESC) AS ranking 
FROM 
   customers  c
JOIN
   accounts a
ON a.customer_id = c.customer_id ;



--****q5)Find customers who have made both a Deposit and a Withdrawal transaction.
WITH trans_cte AS (
       SELECT 
	   		account_id 
	   FROM transactions 
	   WHERE transaction_type IN ('Deposit','Withdrawal')
	   GROUP BY account_id 
	   HAVING (COUNT(DISTINCT transaction_type)) = 2
)

SELECT 
		c.customer_name 
		
FROM 
      customers c
JOIN 
     accounts a
ON a.customer_id = c.customer_id 
JOIN 
    trans_cte tc
ON tc.account_id=a.account_id ;

--q6)Find the customer with the 2nd highest account balance.
WITH rank_cte AS (
   SELECT
         customer_id,balance ,
        DENSE_RANK()OVER (ORDER BY balance DESC)  AS ranking
	FROM 
	    accounts 
)
SELECT 
     c.customer_name ,
	 rc.balance 
	 
FROM 
    customers c
JOIN 
    rank_cte rc
ON rc.customer_id =c.customer_id 
WHERE ranking=2;

--q7)Find the customer who has performed the highest number of transactions.
WITH trans_cte AS (
       SELECT 
	   		account_id ,
	     	COUNT(*) AS total_transaction ,
			DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS ranking
		FROM 
		 	transactions 
		GROUP BY account_id 
)
SELECT 
	c.customer_name,
	tc.total_transaction 
FROM 
	customers c
JOIN 
	accounts a
ON a.customer_id = c.customer_id 
JOIN 
    trans_cte tc
ON tc.account_id = a.account_id
WHERE ranking=1;
 ;
/* ORDER BY total_transaction DESC (because it is not so accurate what if there is more than 1 customer 
who has performed the highest no. of transaction)
 LIMIT 1 ;*/


/*q8) For each customer, show:
.customer_name
.total_deposit
.total_withdrawal*/

WITH 
total_trans1 AS (
     	SELECT  
		 		account_id, 
				SUM(amount) AS total_deposit
		FROM 
			transactions
		WHERE transaction_type='Deposit'
		GROUP BY account_id 
),
	total_trans2 AS (
     	SELECT  
		 		account_id, 
				SUM(amount) AS total_withdrawal
		FROM 
			transactions
		WHERE transaction_type='Withdrawal'
		GROUP BY account_id 
)

SELECT  
	c.customer_name,
	COALESCE(tt1.total_deposit,0) AS total_deposit,      --main point is coalesce 
	COALESCE(tt2.total_withdrawal,0) AS total_withdrawal
	
FROM 
	customers c
JOIN 
	accounts a
ON a.customer_id = c.customer_id 
JOIN 
    total_trans1 tt1
ON tt1.account_id = a.account_id 
LEFT JOIN                          -- main point is left join 
	total_trans2 tt2
ON tt1.account_id = tt2.account_id;

--other easy solution 
SELECT 
		c.customer_name,
		SUM(
			CASE
				WHEN t.transaction_type ='Deposit'
				THEN t.amount 
				ELSE 
				0
			END
		)AS total_deposit,

		SUM(
			CASE
				WHEN t.transaction_type ='Withdrawal'
				THEN t.amount 
				ELSE 
				0
			END
		)AS total_withdrawal
		
FROM
		customers c
JOIN 
     accounts a
ON a.customer_id = c.customer_id 
JOIN 
     transactions t
ON t.account_id = a.account_id
GROUP BY c.customer_name;


-- q9)Find customers whose account balance is higher than the balance of Rahul.
SELECT 
		c.customer_name ,
		a.balance 
FROM
    customers c
JOIN 
	accounts a
ON a.customer_id = c.customer_id 
WHERE a.balance >(
  	SELECT  a.balance 
	FROM
	     customers c
	JOIN 
		accounts a 
	ON a.customer_id = c.customer_id 
	WHERE c.customer_name ='Rahul'
);

--q10)Show each transaction along with the previous transaction amount for the same account.
SELECT 
		a.account_id,
		t.transaction_date,
		t.amount,
		LAG(t.amount) OVER (PARTITION BY a.account_id ORDER BY transaction_date ASC )AS previous_amount 
FROM 
    accounts a
JOIN 
	transactions t
ON t.account_id = a.account_id ;



-- q11)Find customers whose balance is greater than the average balance of all customers from their city.
SELECT 
     c.customer_name ,
	 c.city,
	 a.balance 
FROM 
	customers c
JOIN 
	accounts a
ON a.customer_id = c.customer_id 
WHERE a.balance >(
    SELECT
		 AVG(a2.balance)   
	FROM  customers c2
	JOIN accounts a2
	ON a2.customer_id = c2.customer_id
		WHERE c2.city = c.city          ---**** main point 
		
);

-- other method 
WITH avg_cte AS (
		SELECT
		 c.customer_id	,
		AVG(a.balance) OVER(PARTITION BY c.city) AS avg_balance  
		FROM  customers c
		JOIN accounts a
		ON a.customer_id = c.customer_id
)

SELECT 
     c.customer_name ,
	 c.city,
	 a.balance 
FROM 
	customers c
JOIN 
	accounts a
ON a.customer_id = c.customer_id 
JOIN 
	avg_cte ac 
ON ac.customer_id = c.customer_id 
WHERE a.balance>avg_balance;

--q12)Show the running total of transactions for each account ordered by transaction date.
SELECT 
		    account_id, 
			transaction_date ,
			amount ,
			SUM(amount) OVER (PARTITION BY account_id ORDER BY transaction_date) AS running_total
		FROM 
			transactions 

-- DAY 7 --
--q13)Show the next transaction amount for each account using LEAD().
SELECT 
 		account_id ,
		transaction_date,
		amount ,
		LEAD(amount) OVER (PARTITION BY account_id ORDER BY transaction_date) AS next_amount
FROM
		transactions ;

--q14)Find the top 2 customers with the highest total deposit amount.
WITH trans_cte AS(
		SELECT 
				account_id ,
				SUM(amount)  AS total_amount,
				DENSE_RANK() OVER (ORDER BY (SUM(amount)) DESC ) AS ranking 
		FROM 
				transactions 
				WHERE transaction_type='Deposit'
				GROUP BY account_id 
)
SELECT 
		c.customer_name ,
		t.total_amount 
FROM 
	customers c
JOIN 
	accounts a
on a.customer_id = c.customer_id 
JOIN 
	trans_cte  t
ON t.account_id = a.account_id 
WHERE ranking <= 2 ;


--q15)Assign a unique transaction number for each account based on transaction date.
SELECT 
		account_id ,
		transaction_date ,
		amount ,
		ROW_NUMBER () OVER (PARTITION BY account_id ORDER BY transaction_date ASC) AS transaction_number 
FROM 
		transactions 

--q16)Find the total transaction amount for each month.
SELECT 
		TO_CHAR(transaction_date,'yyyy-mm') AS month,
		SUM(amount) AS total_amount 
FROM 
		transactions 
GROUP BY month;


--q17) Classify customers based on account balance:
.balance ≥ 70000 → 'High Balance'
.balance between 40000 and 69999 → 'Medium Balance'
.otherwise → 'Low Balance'
Also:
.display rounded balance
.sort output by highest balance   */

SELECT 
	c.customer_name ,
	ROUND(a.balance) AS rounded_balance ,
  CASE 
		WHEN a.balance >= 70000  THEN  'High Balance'
		WHEN a.balance between 40000 and 69999 THEN 'Medium Balance'
       ELSE 'Low Balance'
	END AS balance_category
FROM 
     customers c
JOIN 
	accounts a
ON a.customer_id =c.customer_id 
ORDER BY ROUND(a.balance) DESC ;

--q18)Find all transactions that happened after the 15th day of the month 
--and whose amount is greater than the average transaction amount.
SELECT 
		transaction_id,
		transaction_date ,
		amount 
FROM transactions 
WHERE (EXTRACT(DAY FROM transaction_date )) > 15
AND 
amount > (
     SELECT avg(amount)
	 FROM transactions
)


-- q19)Find customers who have made at least one withdrawal transaction.
/*   WITH trans_cte AS (
		SELECT 
				account_id,
				transaction_type 
		FROM 
			transactions 
		WHERE transaction_type='Withdrawal'
)
SELECT 
		c.customer_name 
		
FROM 
	customers c
JOIN 
	accounts a 
ON c.customer_id = a.customer_id 
JOIN 
	trans_cte t
ON t.account_id = a.account_id ;     */

--other solution 
SELECT 
	c.customer_name 
FROM 
  customers c
JOIN 
	accounts a
ON a.customer_id = c.customer_id 
WHERE EXISTS (
	SELECT 1 
	FROM transactions t
	WHERE t.account_id = a.account_id 
	AND transaction_type ='Withdrawal'
	
);

--q20)Show the latest transaction for each account.
WITH trans_cte AS (
     SELECT 
	 	account_id ,
		transaction_date ,
			amount,
			transaction_type,
	      ROW_NUMBER()OVER(PARTITION BY account_id ORDER BY transaction_date DESC) AS ranking 
	FROM 
	    transactions 
)

SELECT 
		account_id ,
		transaction_date ,
		amount,
		transaction_type 
		
FROM     	
   trans_cte t
WHERE t.ranking = 1;

--DAY 11--
--q21)Find customers who have never made a withdrawal transaction.
SELECT 
    c.customer_name 
FROM
	customers c
JOIN 
	accounts a
ON c.customer_id = a.customer_id 
WHERE NOT EXISTS (
	SELECT 1
	FROM transactions t 
	WHERE t.account_id = a.account_id 
	AND transaction_type='Withdrawal'
)	;

--q22)Find customers whose name length is greater than the average customer name length.
SELECT 
		customer_name ,
		LENGTH(customer_name) AS name_length
		
FROM 
    customers 
WHERE (LENGTH(customer_name))> (
     SELECT 
	     AVG(LENGTH(customer_name)) 
	  FROM 
	  customers 
);


--q23)Find customers whose names start with 'R' or end with 'a'.
SELECT 
      customer_name
FROM
	customers 
WHERE customer_name LIKE 'R%' 
OR customer_name LIKE '%a';
	  
--q24)Find the number of distinct transaction types performed by each customer.
WITH trans_cte AS(
      	SELECT 
		  	account_id ,
		     COUNT(DISTINCT transaction_type) AS distinct_transaction_types 
		FROM 
			transactions 
		GROUP BY account_id 
)
SELECT 
	c.customer_name ,
	t. distinct_transaction_types 
FROM 
   customers c
JOIN 
	accounts a
ON c.customer_id = a.customer_id 
JOIN 
   trans_cte  t
ON t.account_id =a.account_id  ; 
	  
    