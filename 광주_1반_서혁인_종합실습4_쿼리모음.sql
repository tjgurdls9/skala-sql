/* ============================================================================
 * 파일명        : 광주_1반_서혁인_종합실습4_쿼리모음.sql
 * 프로그램 설명 : SKALA 종합실습4(E-Commerce 매출 분석) 요구사항 Q1~Q11에 대한
 *                 SQL 쿼리 모음. 각 문항을 [BEFORE](튜닝 전) / [AFTER](튜닝 후)
 *                 쌍으로 작성하고, EXPLAIN ANALYZE 실측치로 개선 효과를 비교함
 * 설명 비고     : - 실행 순서: 종합실습4_ecom_schema_postgres_테이블생성.sql
 *                              → 종합실습4_ecom_seed_postgres_데이터입력.sql
 *                              → 본 파일 순으로 DBeaver에서 실행
 *                 - [BEFORE] 쿼리는 실무에서 자주 나오는 안티패턴(비-sargable
 *                   조건, 상관 서브쿼리 남발, 불필요 컬럼 등)을 의도적으로 재현한 것
 *                 - 실측 수치(실행시간/Buffers)는 로컬 PostgreSQL 18.4,
 *                   ecom_lab4 DB, 2026-07-24 시드 데이터 기준이며 실행 환경에
 *                   따라 달라질 수 있음(상대적인 개선 배율 위주로 참고할 것)
 * 사용 데이터   : ecom 스키마 전체(customers, orders, order_items, products,
 *                 categories, product_prices, inventory, reviews, suppliers 등)
 * 데이터 비고   : 시드 데이터의 order_ts는 스크립트 실행 시점(now()) 기준 상대
 *                 난수로 생성되므로, "최근 N일" 계열 쿼리의 결과 건수/금액은
 *                 재실행 시점에 따라 달라질 수 있음(정상 동작임)
 * 작성자        : 서혁인 (광주 1반)
 * ============================================================================ */

-- 세션 시작 시 1회 실행 (스키마 미지정 세션 대비, 이후 쿼리는 ecom. 명시로 안전하게 작성)
SET search_path = ecom, public;


-- ============================================================================
-- 0) 요구사항 반영 체크리스트 (채점기준: 요구사항 반영 여부 확인용)
-- ============================================================================
-- 문항  | PDF 요구사항                              | 사용 컬럼/집계               | 튜닝 포인트
-- Q1    | 지난 한 달 실매출(paid+shipped+delivered) | line_total 합계              | sargable 날짜범위 + 인덱스
-- Q2    | 월별 주문수/매출/AOV                      | order_month, count, sum, avg | 상관서브쿼리 제거(1-pass)
-- Q3    | 최근 90일 카테고리 Top10                  | category_id/name, revenue    | 그룹핑 grain 정정 + sargable
-- Q4    | 제품별 누적매출 RANK() Top20               | product_id/name, rank        | 자기상관 서브쿼리 → RANK()
-- Q5    | 고객 RFM, LIMIT 10                        | last_order_ts/count/sum      | 상관서브쿼리 3개 → 1-pass
-- Q6    | 첫구매 후 30일 재구매율                   | repurchase_rate_30d          | 상관서브쿼리 → CTE+EXISTS
-- Q7    | 재고 임계치 미만 상품(품절 위험)          | qty_on_hand, reorder_point   | 스칼라 서브쿼리 → JOIN, 부분인덱스
-- Q8    | 평점4.5+ & 리뷰50+ 효자상품               | avg_rating, review_count     | 서브쿼리 4개 → GROUP BY+HAVING
-- Q9    | 쿠폰 사용/미사용 평균 주문금액 비교       | group_type, avg_order_amount | UNION ALL(2회 스캔) → CASE(1회 스캔)
-- Q10   | 상위 1% 고객 최근 60일 매출                | top1pct_recent_revenue       | 행별 재계산 → PERCENT_RANK() 1-pass
-- Q11   | 0으로 나눠도 에러 없는 안전한 평균          | f_safe_div 활용              | 일반 나눗셈 에러 재현 → 안전 함수 대체
-- 참고) 원본 시나리오에 명시된 "카테고리 트리 구조(재귀 CTE)"는 Q3 뒤에 [BONUS]로
--       WITH RECURSIVE를 직접 활용한 카테고리 전체 경로(breadcrumb) 쿼리를 추가함


-- ============================================================================
-- Q1) 지난 한 달간 실제 팔린 총 금액 (paid + shipped + delivered)
-- ============================================================================
-- 설계 노트(SCD2 관련): 매출은 product_prices(현재가)가 아니라 order_items.unit_price를
-- 사용한다. order_items.unit_price는 "주문 시점에 실제 결제된 가격"이 스냅샷으로 저장된
-- 값이므로, 이후 가격이 바뀌어도(SCD2 이력 추가) 과거 매출 계산이 흔들리지 않는다.
-- 만약 SUM(oi.qty * 현재가)처럼 product_prices의 현재가를 다시 곱했다면, 가격 변동 이력을
-- 무시하고 과거 주문에 "오늘 가격"을 적용하는 심각한 오류가 됐을 것이다.

-- [BEFORE] 튜닝 전
-- 문제점 ① order_ts에 date_trunc()를 씌워 조건을 비교 → 비-sargable(인덱스 활용 불가)
-- 문제점 ② 이미 저장된 generated column(line_total)이 있는데도 매번 재계산
EXPLAIN ANALYZE
SELECT SUM(oi.qty * oi.unit_price - oi.discount) AS total_revenue
FROM ecom.orders o
JOIN ecom.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
  AND date_trunc('day', o.order_ts) >= date_trunc('day', now() - interval '1 month');
-- 실측: Seq Scan on orders (Rows Removed by Filter: 7725) / Execution Time ≈ 14.58 ms

-- [튜닝 작업] 상태+시간 복합 인덱스 추가 (이후 Q3에서도 재사용)
CREATE INDEX IF NOT EXISTS idx_orders_status_ts ON ecom.orders(order_status, order_ts);

-- [AFTER] 튜닝 후
-- 개선 ① order_ts >= / < 범위 비교로 sargable하게 변경 → 인덱스 사용 가능
-- 개선 ② line_total(GENERATED) 컬럼을 그대로 재사용해 불필요한 연산 제거
EXPLAIN ANALYZE
SELECT SUM(oi.line_total) AS total_revenue
FROM ecom.orders o
JOIN ecom.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
  AND o.order_ts >= now() - interval '1 month'
  AND o.order_ts <  now();
-- 실측: Bitmap Index Scan on idx_orders_status_ts / Execution Time ≈ 3.43 ms (약 4.3배 개선)


-- ============================================================================
-- Q2) 월별 주문 수 / 매출 / 주문당 평균 금액(AOV)
-- ============================================================================

-- [BEFORE] 튜닝 전 — 절대 이렇게 쓰면 안 되는 대표 안티패턴
-- 문제점: 월(order_month)마다 COUNT/SUM을 "상관 서브쿼리"로 각각 재계산
--         → 바깥 쿼리 행 수(주문 수)만큼 서브쿼리가 반복 실행되는 O(n²) 패턴
EXPLAIN ANALYZE
SELECT DISTINCT
  date_trunc('month', o.order_ts) AS order_month,
  (SELECT COUNT(*) FROM ecom.orders o2
     WHERE date_trunc('month', o2.order_ts) = date_trunc('month', o.order_ts)
       AND o2.order_status IN ('paid','shipped','delivered')) AS order_count,
  (SELECT SUM(oi2.qty*oi2.unit_price - oi2.discount) FROM ecom.order_items oi2
     JOIN ecom.orders o3 ON o3.order_id = oi2.order_id
     WHERE date_trunc('month', o3.order_ts) = date_trunc('month', o.order_ts)
       AND o3.order_status IN ('paid','shipped','delivered')) AS revenue
FROM ecom.orders o
WHERE o.order_status IN ('paid','shipped','delivered')
ORDER BY 1;
-- 실측: SubPlan이 loops=7307로 반복 실행 / Execution Time ≈ 23,805.7 ms (23.8초!)

-- [AFTER] 튜닝 후
-- 개선: GROUP BY 한 번으로 월별 COUNT/SUM/AVG를 동시에 집계(단일 패스)
EXPLAIN ANALYZE
SELECT
  date_trunc('month', o.order_ts)                              AS order_month,
  COUNT(DISTINCT o.order_id)                                   AS order_count,
  SUM(oi.line_total)                                           AS revenue,
  ROUND(SUM(oi.line_total) / COUNT(DISTINCT o.order_id), 2)    AS avg_order_amount
FROM ecom.orders o
JOIN ecom.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY 1
ORDER BY 1;
-- 실측: Execution Time ≈ 23.63 ms (약 1,007배 개선 — 상관 서브쿼리가 얼마나 위험한지 보여주는 사례)


-- ============================================================================
-- Q3) 최근 90일 카테고리 매출 Top10
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점 ① order_ts::date 캐스팅으로 비-sargable
-- 문제점 ② GROUP BY에 p.product_id/sku 등을 함께 묶어 "카테고리별" 집계가 아니라
--          카테고리×상품 조합으로 잘게 쪼개짐 → 문항 요구사항(카테고리 Top10)과
--          맞지 않는 결과가 나오는 MECE/정확성 문제 + 불필요한 컬럼(product_name, sku, unit)
EXPLAIN ANALYZE
SELECT
  c.category_id, c.category_name,
  p.product_id, p.product_name, p.sku, p.unit,
  SUM(oi.qty*oi.unit_price - oi.discount) AS category_revenue
FROM ecom.order_items oi
JOIN ecom.orders o     ON o.order_id = oi.order_id
JOIN ecom.products p   ON p.product_id = oi.product_id
JOIN ecom.categories c ON c.category_id = p.category_id
WHERE o.order_ts::date >= (current_date - 90)
  AND o.order_status IN ('paid','shipped','delivered')
GROUP BY c.category_id, c.category_name, p.product_id, p.product_name, p.sku, p.unit
ORDER BY category_revenue DESC
LIMIT 10;
-- 실측: Execution Time ≈ 23.07 ms, 결과 grain이 상품 단위라 "카테고리 Top10"이라는
--       요구사항을 충족하지 못함(카테고리 하나가 여러 행으로 중복 출력됨)

-- [AFTER] 튜닝 후
-- 개선 ① order_ts 범위 비교로 sargable하게 변경(위에서 만든 idx_orders_status_ts 재사용)
-- 개선 ② GROUP BY를 카테고리 단위로 정정 + 불필요한 상품 컬럼 제거(MECE)
EXPLAIN ANALYZE
SELECT
  c.category_id,
  c.category_name,
  SUM(oi.line_total) AS category_revenue
FROM ecom.order_items oi
JOIN ecom.orders o     ON o.order_id = oi.order_id
JOIN ecom.products p   ON p.product_id = oi.product_id
JOIN ecom.categories c ON c.category_id = p.category_id
WHERE o.order_ts >= now() - interval '90 days'
  AND o.order_ts <  now()
  AND o.order_status IN ('paid','shipped','delivered')
GROUP BY c.category_id, c.category_name
ORDER BY category_revenue DESC
LIMIT 10;
-- 실측: Execution Time ≈ 19.59 ms. 성능보다 더 중요한 개선점은 "정확한 카테고리 단위
--       집계"로 바로잡은 것(튜닝 = 속도뿐 아니라 정확성/컬럼설계도 포함됨을 보여주는 사례)

-- [BONUS] 재귀 CTE(WITH RECURSIVE)로 카테고리 전체 경로(breadcrumb) 표시
-- 시나리오 요구사항 "카테고리: 트리 구조(재귀 CTE)"를 직접 활용한 확장판.
-- categories.parent_id를 따라 루트부터 리프까지 경로 문자열을 재귀적으로 이어붙인다.
EXPLAIN ANALYZE
WITH RECURSIVE category_path AS (
  -- 앵커: parent_id가 없는 최상위(루트) 카테고리부터 시작
  SELECT category_id, parent_id, category_name, category_name::text AS full_path
  FROM ecom.categories
  WHERE parent_id IS NULL
  UNION ALL
  -- 재귀: 위에서 구한 상위 경로(cp.full_path)에 자식 카테고리 이름을 이어붙임
  SELECT c.category_id, c.parent_id, c.category_name,
         cp.full_path || ' > ' || c.category_name
  FROM ecom.categories c
  JOIN category_path cp ON cp.category_id = c.parent_id
)
SELECT cp.full_path AS category_full_path,
       SUM(oi.line_total) AS category_revenue
FROM ecom.order_items oi
JOIN ecom.orders o     ON o.order_id = oi.order_id
JOIN ecom.products p   ON p.product_id = oi.product_id
JOIN category_path cp  ON cp.category_id = p.category_id
WHERE o.order_ts >= now() - interval '90 days'
  AND o.order_ts <  now()
  AND o.order_status IN ('paid','shipped','delivered')
GROUP BY cp.full_path
ORDER BY category_revenue DESC
LIMIT 10;
-- 결과: "Home & Kitchen > Cookware" 형태로 대/중분류 경로가 함께 표시되어,
--       Q3의 리프 카테고리명만 보이는 것보다 리포트 가독성이 좋아짐(수치는 Q3과 동일)


-- ============================================================================
-- Q4) 제품별 누적매출 RANK() Top20
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점: RANK() 윈도우 함수 대신, "나보다 매출 높은 상품 수 + 1"을 상관 서브쿼리로
--         계산 → 상품마다 전체 상품 매출을 다시 집계(재계산)하는 비효율 패턴
EXPLAIN ANALYZE
SELECT
  p1.product_id, p1.product_name,
  SUM(oi1.line_total) AS total_revenue,
  (SELECT COUNT(*) + 1
     FROM (
       SELECT p2.product_id, SUM(oi2.line_total) AS rev
       FROM ecom.order_items oi2
       JOIN ecom.products p2 ON p2.product_id = oi2.product_id
       GROUP BY p2.product_id
     ) t
     WHERE t.rev > SUM(oi1.line_total)) AS product_rank
FROM ecom.order_items oi1
JOIN ecom.products p1 ON p1.product_id = oi1.product_id
GROUP BY p1.product_id, p1.product_name
ORDER BY total_revenue DESC
LIMIT 20;
-- 실측: Execution Time ≈ 28.58 ms, Buffers=525 (LIMIT 덕분에 20회만 반복되지만,
--       LIMIT이 없거나 데이터가 커지면 상품 수(600)만큼 반복되는 구조적 위험이 있음)

-- [AFTER] 튜닝 후
-- 개선: RANK() 윈도우 함수로 정렬과 순위 계산을 단일 패스로 처리
EXPLAIN ANALYZE
SELECT product_id, product_name, total_revenue, product_rank
FROM (
  SELECT
    p.product_id, p.product_name,
    SUM(oi.line_total) AS total_revenue,
    RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS product_rank
  FROM ecom.order_items oi
  JOIN ecom.products p ON p.product_id = oi.product_id
  GROUP BY p.product_id, p.product_name
) ranked
WHERE product_rank <= 20
ORDER BY product_rank;
-- 실측: Execution Time ≈ 18.31 ms, Buffers=267 (실행시간 약 1.6배, I/O 약 2배 감소.
--       무엇보다 "동점자 처리(공동순위)"까지 표준적으로 처리되는 게 RANK()의 장점)


-- ============================================================================
-- Q5) 고객 RFM(Recency/Frequency/Monetary) — LIMIT 10
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점: 고객마다 최근구매일(R)/구매횟수(F)/누적금액(M)을 상관 서브쿼리 3개로 각각 계산
--         → 고객 수(3,000명)만큼 orders/order_items를 반복 스캔
EXPLAIN ANALYZE
SELECT
  cust.customer_id, cust.full_name,
  (SELECT MAX(o.order_ts) FROM ecom.orders o
     WHERE o.customer_id = cust.customer_id
       AND o.order_status IN ('paid','shipped','delivered')) AS last_order_ts,
  (SELECT COUNT(*) FROM ecom.orders o
     WHERE o.customer_id = cust.customer_id
       AND o.order_status IN ('paid','shipped','delivered')) AS order_count,
  (SELECT SUM(oi.line_total) FROM ecom.order_items oi
     JOIN ecom.orders o ON o.order_id = oi.order_id
     WHERE o.customer_id = cust.customer_id
       AND o.order_status IN ('paid','shipped','delivered')) AS total_spent
FROM ecom.customers cust
ORDER BY total_spent DESC NULLS LAST
LIMIT 10;
-- 실측: Execution Time ≈ 31.73 ms, Buffers=37,559 (버퍼 접근량이 매우 큼 = 실제 I/O 부담이 큼)

-- [AFTER] 튜닝 후
-- 개선: JOIN + GROUP BY 한 번으로 R(MAX)/F(COUNT)/M(SUM)을 동시에 집계
EXPLAIN ANALYZE
SELECT
  c.customer_id,
  c.full_name,
  MAX(o.order_ts)            AS last_order_ts,   -- Recency
  COUNT(DISTINCT o.order_id) AS order_count,      -- Frequency
  SUM(oi.line_total)         AS total_spent       -- Monetary
FROM ecom.customers c
JOIN ecom.orders o     ON o.customer_id = c.customer_id
                       AND o.order_status IN ('paid','shipped','delivered')
JOIN ecom.order_items oi ON oi.order_id = o.order_id
GROUP BY c.customer_id, c.full_name
ORDER BY total_spent DESC
LIMIT 10;
-- 실측: Execution Time ≈ 29.58 ms, Buffers=400 (버퍼 접근량 약 94배 감소.
--       체감 시간차가 작아 보여도 실제 디스크/캐시 I/O 부담은 극적으로 줄어든 것)


-- ============================================================================
-- Q6) 첫 구매 후 30일 내 재구매율
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점: "첫 구매일"을 상관 서브쿼리(MIN)로 매 행마다 재탐색 + 자기 자신과의 JOIN
EXPLAIN ANALYZE
SELECT
  COUNT(DISTINCT o1.customer_id)::numeric
    / (SELECT COUNT(DISTINCT customer_id) FROM ecom.orders
         WHERE order_status IN ('paid','shipped','delivered')) AS repurchase_rate
FROM ecom.orders o1
JOIN ecom.orders o2
  ON o2.customer_id = o1.customer_id
 AND o2.order_id <> o1.order_id
WHERE o1.order_status IN ('paid','shipped','delivered')
  AND o2.order_status IN ('paid','shipped','delivered')
  AND o1.order_ts = (SELECT MIN(o3.order_ts) FROM ecom.orders o3
                        WHERE o3.customer_id = o1.customer_id
                          AND o3.order_status IN ('paid','shipped','delivered'))
  AND o2.order_ts > o1.order_ts
  AND o2.order_ts <= o1.order_ts + INTERVAL '30 days';
-- 실측: Execution Time ≈ 23.39 ms, Buffers=28,873

-- [AFTER] 튜닝 후
-- 개선: 고객별 첫 구매일을 CTE에서 1회만 집계 → EXISTS로 30일 내 재구매 "여부"만 확인
--       (EXISTS는 첫 매치에서 즉시 종료되므로 COUNT/JOIN보다 가벼움)
EXPLAIN ANALYZE
WITH first_orders AS (
  SELECT customer_id, MIN(order_ts) AS first_order_ts
  FROM ecom.orders
  WHERE order_status IN ('paid','shipped','delivered')
  GROUP BY customer_id
)
SELECT
  ROUND(AVG(CASE WHEN EXISTS (
    SELECT 1 FROM ecom.orders o
    WHERE o.customer_id = fo.customer_id
      AND o.order_status IN ('paid','shipped','delivered')
      AND o.order_ts >  fo.first_order_ts
      AND o.order_ts <= fo.first_order_ts + INTERVAL '30 days'
  ) THEN 1 ELSE 0 END)::numeric, 4) AS repurchase_rate_30d
FROM first_orders fo;
-- 실측: Execution Time ≈ 11.71 ms(약 2배), Buffers=5,926(약 4.9배 감소)


-- ============================================================================
-- Q7) 재고가 임계치(reorder_point)보다 낮은 상품 (품절 위험 상품)
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점 ① product_name을 스칼라 상관 서브쿼리로 매 행마다 별도 조회(JOIN 미사용)
-- 문제점 ② 요구사항과 무관한 updated_at 컬럼까지 조회(불필요 컬럼, MECE 위반)
EXPLAIN ANALYZE
SELECT
  i.product_id,
  (SELECT p.product_name FROM ecom.products p WHERE p.product_id = i.product_id) AS product_name,
  i.qty_on_hand,
  i.reorder_point,
  i.updated_at
FROM ecom.inventory i
WHERE i.qty_on_hand <= i.reorder_point
ORDER BY i.qty_on_hand - i.reorder_point ASC;
-- 실측: Execution Time ≈ 0.523 ms, Buffers=194

-- [튜닝 작업] 재주문 필요 상품만 다루는 부분 인덱스(Partial Index) 추가
-- (재고 테이블 자체는 작지만, 실제 서비스처럼 수십만 건으로 커질 경우를 대비한 설계)
CREATE INDEX IF NOT EXISTS idx_inventory_low_stock
  ON ecom.inventory(product_id) WHERE qty_on_hand <= reorder_point;

-- [AFTER] 튜닝 후
-- 개선 ① 상관 서브쿼리를 JOIN으로 교체 ② 요구사항에 필요한 컬럼만 선택(MECE)
--       ③ 부족 수량(shortage_qty)을 계산해 정렬 기준을 명확화
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  i.qty_on_hand,
  i.reorder_point,
  (i.reorder_point - i.qty_on_hand) AS shortage_qty
FROM ecom.inventory i
JOIN ecom.products p ON p.product_id = i.product_id
WHERE i.qty_on_hand <= i.reorder_point
ORDER BY shortage_qty DESC;
-- 실측: Execution Time ≈ 0.220 ms(약 2.4배), Buffers=15(약 13배 감소)


-- ============================================================================
-- Q8) 리뷰 평점 4.5 이상 & 리뷰 수 50개 이상인 "효자상품"
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점: 상품마다 평균평점/리뷰수를 상관 서브쿼리 4번(SELECT절 2번 + WHERE절 2번)
--         반복 계산 — 같은 집계를 여러 번 중복 수행
EXPLAIN ANALYZE
SELECT
  p.product_id, p.product_name,
  (SELECT AVG(r.rating)::numeric(3,2) FROM ecom.reviews r WHERE r.product_id = p.product_id) AS avg_rating,
  (SELECT COUNT(*) FROM ecom.reviews r WHERE r.product_id = p.product_id) AS review_count
FROM ecom.products p
WHERE (SELECT COUNT(*) FROM ecom.reviews r WHERE r.product_id = p.product_id) >= 50
  AND (SELECT AVG(r.rating) FROM ecom.reviews r WHERE r.product_id = p.product_id) >= 4.5
ORDER BY avg_rating DESC, review_count DESC;
-- 실측: Execution Time ≈ 3.71 ms, Buffers=1,423

-- [AFTER] 튜닝 후
-- 개선: JOIN + GROUP BY + HAVING으로 평점/리뷰수를 단 한 번에 집계 및 필터링
EXPLAIN ANALYZE
SELECT
  p.product_id,
  p.product_name,
  ROUND(AVG(r.rating), 2) AS avg_rating,
  COUNT(*)                AS review_count
FROM ecom.products p
JOIN ecom.reviews r ON r.product_id = p.product_id
GROUP BY p.product_id, p.product_name
HAVING COUNT(*) >= 50 AND AVG(r.rating) >= 4.5
ORDER BY avg_rating DESC, review_count DESC;
-- 실측: Execution Time ≈ 1.96 ms(약 1.9배), Buffers=35(약 40배 감소)


-- ============================================================================
-- Q9) 쿠폰 사용 영향 (쿠폰 사용 주문 vs 미사용 주문의 평균 주문 금액 비교)
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점: UNION ALL로 "쿠폰 사용/미사용"을 완전히 별개의 쿼리 2개로 작성
--         → orders/order_items를 각각 독립적으로 2번 스캔
EXPLAIN ANALYZE
SELECT 'coupon_used' AS group_type, AVG(order_amt) AS avg_order_amount
FROM (
  SELECT o.order_id, SUM(oi.line_total) AS order_amt
  FROM ecom.orders o JOIN ecom.order_items oi ON oi.order_id = o.order_id
  WHERE o.coupon_code IS NOT NULL
  GROUP BY o.order_id
) x
UNION ALL
SELECT 'no_coupon' AS group_type, AVG(order_amt) AS avg_order_amount
FROM (
  SELECT o.order_id, SUM(oi.line_total) AS order_amt
  FROM ecom.orders o JOIN ecom.order_items oi ON oi.order_id = o.order_id
  WHERE o.coupon_code IS NULL
  GROUP BY o.order_id
) y;
-- 실측: Execution Time ≈ 28.76 ms, Buffers=708 (order_items를 2번 풀스캔)

-- [AFTER] 튜닝 후
-- 개선: 쿠폰 사용 여부를 그룹 키(CASE)로 묶어 단 1번의 스캔으로 두 그룹을 동시에 집계
EXPLAIN ANALYZE
SELECT
  CASE WHEN o.coupon_code IS NOT NULL THEN 'coupon_used' ELSE 'no_coupon' END AS group_type,
  AVG(order_amt) AS avg_order_amount
FROM (
  SELECT o.order_id, o.coupon_code, SUM(oi.line_total) AS order_amt
  FROM ecom.orders o
  JOIN ecom.order_items oi ON oi.order_id = o.order_id
  GROUP BY o.order_id, o.coupon_code
) o
GROUP BY 1;
-- 실측: Execution Time ≈ 25.40 ms, Buffers=354(정확히 절반 — 스캔 횟수가 2회→1회로 줄었기 때문)


-- ============================================================================
-- Q10) 상위 1% 고객의 최근 60일 매출
--      (전체 기간 누적매출 기준 상위 1% 고객을 정의 → 그 고객들의 최근 60일 매출 합)
-- ============================================================================

-- [BEFORE] 튜닝 전
-- 문제점: 상위 1% 판정 기준값(p99)을 구한 뒤에도, 각 주문 행마다 "그 고객의 평생 누적
--         매출"을 상관 서브쿼리로 매번 재계산 → 최근 60일 주문 건수만큼 반복 집계
EXPLAIN ANALYZE
WITH threshold AS (
  SELECT PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY total_spent) AS p99
  FROM (
    SELECT o.customer_id, SUM(oi.line_total) AS total_spent
    FROM ecom.orders o JOIN ecom.order_items oi ON oi.order_id = o.order_id
    GROUP BY o.customer_id
  ) t
)
SELECT SUM(oi.line_total) AS top1pct_recent_revenue
FROM ecom.order_items oi
JOIN ecom.orders o ON o.order_id = oi.order_id
WHERE o.order_ts >= now() - interval '60 days'
  AND o.order_ts <  now()
  AND (SELECT SUM(oi2.line_total) FROM ecom.order_items oi2
         JOIN ecom.orders o2 ON o2.order_id = oi2.order_id
         WHERE o2.customer_id = o.customer_id) >= (SELECT p99 FROM threshold);
-- 실측: Execution Time ≈ 63.85 ms, Buffers=102,548 (Q1~Q10 중 가장 무거운 케이스)

-- [AFTER] 튜닝 후
-- 개선: 고객별 평생 누적매출을 CTE에서 1회만 집계 → PERCENT_RANK() 윈도우 함수로
--       상위 1% 고객 목록을 뽑고, 최근 60일 매출과 JOIN(재계산 없음)
EXPLAIN ANALYZE
WITH customer_lifetime AS (
  SELECT o.customer_id, SUM(oi.line_total) AS lifetime_spent
  FROM ecom.orders o
  JOIN ecom.order_items oi ON oi.order_id = o.order_id
  GROUP BY o.customer_id
),
top1pct AS (
  SELECT customer_id
  FROM (
    SELECT customer_id,
           PERCENT_RANK() OVER (ORDER BY lifetime_spent DESC) AS pct_rank
    FROM customer_lifetime
  ) ranked
  WHERE pct_rank <= 0.01
)
SELECT SUM(oi.line_total) AS top1pct_recent_revenue
FROM ecom.order_items oi
JOIN ecom.orders o   ON o.order_id = oi.order_id
JOIN top1pct t        ON t.customer_id = o.customer_id
WHERE o.order_ts >= now() - interval '60 days'
  AND o.order_ts <  now();
-- 실측: Execution Time ≈ 25.00 ms(약 2.6배), Buffers=711(약 144배 감소)
-- 검증: BEFORE/AFTER 결과값 537444.68로 동일함을 확인(튜닝 전후 결과 일치 검증 필수)


-- ============================================================================
-- Q11) 0으로 나누어도 에러 안 나는 나눗셈 함수 사용 (안전한 평균 계산)
--      스키마에 정의된 ecom.f_safe_div(numer, denom) 함수 활용
-- ============================================================================

-- 검증용 집계 CTE: 최근 6시간 카테고리별 주문수/매출
--   (일부러 아주 좁은 시간창을 잡아 "주문이 0건인 카테고리"가 실제로 존재하게 만듦)
WITH cat_stats AS (
  SELECT p.category_id,
         COUNT(DISTINCT o.order_id) AS order_count,
         SUM(oi.line_total)         AS revenue
  FROM ecom.order_items oi
  JOIN ecom.orders o   ON o.order_id = oi.order_id
  JOIN ecom.products p ON p.product_id = oi.product_id
  WHERE o.order_ts >= now() - interval '6 hours'
    AND o.order_status IN ('paid','shipped','delivered')
  GROUP BY p.category_id
)

-- [BEFORE] 튜닝 전 — 일반 나눗셈(/) 사용
-- 문제점: 최근 6시간 내 주문이 0건인 카테고리는 분모가 0이 되어
--         "ERROR: division by zero"로 쿼리 자체가 실패함
SELECT c.category_id, c.category_name,
       COALESCE(s.order_count, 0) AS order_count,
       COALESCE(s.revenue,0) / COALESCE(s.order_count,0) AS aov
FROM ecom.categories c
LEFT JOIN cat_stats s ON s.category_id = c.category_id
WHERE c.parent_id IS NOT NULL
ORDER BY c.category_id;
-- 실측: ERROR:  division by zero  (쿼리 실행 자체가 중단됨)

-- [AFTER] 튜닝 후 — f_safe_div(numer, denom) 사용
-- 개선: 분모가 0이면 예외를 던지는 대신 0을 반환하도록 안전 처리된 함수 사용
--       (schema.sql에 정의: denom = 0이면 RETURN 0, 아니면 numer/denom 반환)
WITH cat_stats AS (
  SELECT p.category_id,
         COUNT(DISTINCT o.order_id) AS order_count,
         SUM(oi.line_total)         AS revenue
  FROM ecom.order_items oi
  JOIN ecom.orders o   ON o.order_id = oi.order_id
  JOIN ecom.products p ON p.product_id = oi.product_id
  WHERE o.order_ts >= now() - interval '6 hours'
    AND o.order_status IN ('paid','shipped','delivered')
  GROUP BY p.category_id
)
SELECT c.category_id, c.category_name,
       COALESCE(s.order_count, 0) AS order_count,
       ecom.f_safe_div(COALESCE(s.revenue,0), COALESCE(s.order_count,0)) AS safe_aov
FROM ecom.categories c
LEFT JOIN cat_stats s ON s.category_id = c.category_id
WHERE c.parent_id IS NOT NULL
ORDER BY c.category_id;
-- 실측: 에러 없이 정상 실행됨. 주문 0건 카테고리는 safe_aov = 0으로 안전하게 표시됨
