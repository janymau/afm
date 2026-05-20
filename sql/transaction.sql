WITH sums AS (
    SELECT
        transactions_cleaned.sender_id,
        transactions_cleaned.receiver_id,
        SUM(transactions_cleaned.amount_kzt) AS sum2
    FROM transactions_cleaned
    WHERE both_valid_id = 1
    GROUP BY
        transactions_cleaned.sender_id,
        transactions_cleaned.receiver_id
),
top_pair_agents AS (
    SELECT
        *,
        DENSE_RANK() OVER (ORDER BY sum2 DESC) AS rnk
    FROM sums
)
SELECT * FROM top_pair_agents
where rnk <= 20;



SELECT
    sender_id,
    DATE_FORMAT(transactions_cleaned.date, '%Y-%m') AS year_month_,
    ROUND(SUM(SUM(amount_kzt)) OVER (
        PARTITION BY sender_id
        ORDER BY DATE_FORMAT(date, '%Y-%m')
    ), 2) AS rolling_sum_kzt
FROM transactions_cleaned
WHERE sender_valid = 1
GROUP BY sender_id, DATE_FORMAT(date, '%Y-%m')
ORDER BY sender_id, year_month_;



with tb1 as (
    select transactions_cleaned.receiver_id,
           transactions_cleaned.sender_id,
           sum(amount_kzt) as total_senders_amount,
           count(*) as sender_count
    from transactions_cleaned
    where receiver_valid = 1
    group by receiver_id, sender_id
    order by receiver_id, total_senders_amount, sender_count

), tb2 as (
    select receiver_id,
           sum(total_senders_amount) as total1,
           sum(sender_count) as total2
    from tb1
    group by receiver_id
), tb3 as (
    select
        tb1.receiver_id,
        tb1.sender_id,
        total_senders_amount / total1 * 100 as pct_senders_amount,
        sender_count / total2 * 100 as pct_senders_count
    from tb1
    join tb2 on tb2.receiver_id = tb1.receiver_id
)
select * from tb3
where pct_senders_count > 70 or pct_senders_amount > 70;





