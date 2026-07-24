-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 25-1] 누적 주문금액, 3개 주문 이동평균, 고객별 누적 구매금액
-- =================================================================
SELECT '--- [실습 25-1] 누적합 및 이동평균 (ROWS BETWEEN) ---' AS title;

SELECT 
    order_id,
    customer_id,
    amount,
    -- 1. 전체 누적 주문금액
    SUM(amount) OVER (
        ORDER BY order_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS total_cumulative_sum,
    -- 2. 3개 주문 이동평균 (현재 행 포함 이전 2개)
    AVG(amount) OVER (
        ORDER BY order_id 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg_3,
    -- 3. 고객별 누적 구매금액
    SUM(amount) OVER (
        PARTITION BY customer_id 
        ORDER BY order_id 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cust_cumulative_sum
FROM orders
ORDER BY order_id
LIMIT 15;

-- =================================================================
-- [실습 25-2] 누적합이 전체 합의 50%를 초과하는 첫 번째 order_id 찾기
-- =================================================================
SELECT '--- [실습 25-2] 누적합 50% 돌파 지점 찾기 ---' AS title;

WITH TotalSum AS (
    -- 전체 총합을 먼저 구함
    SELECT SUM(amount) AS grand_total FROM orders
),
RunningTotal AS (
    -- 행별 누적합을 계산
    SELECT 
        order_id,
        amount,
        SUM(amount) OVER (
            ORDER BY order_id 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sum,
        (SELECT grand_total FROM TotalSum) AS grand_total
    FROM orders
)
-- 누적합이 총합의 50%를 넘는 것 중 가장 첫 번째(ORDER BY + LIMIT 1)를 추출
SELECT 
    order_id, 
    amount, 
    cumulative_sum, 
    grand_total
FROM RunningTotal
WHERE cumulative_sum > (grand_total * 0.5)
ORDER BY order_id
LIMIT 1;