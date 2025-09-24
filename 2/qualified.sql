SELECT
    COUNT(*) AS user_count
FROM (
    SELECT
        user_id
    FROM
        event_log
    WHERE
        FROM_UNIXTIME(event_timestamp) >= '2020-09-01' 
        AND FROM_UNIXTIME(event_timestamp) < '2020-10-01'
    GROUP BY
        user_id
    HAVING
        COUNT(*) >= 1000
        AND COUNT(*) < 2000
) AS qualified_users;
