/* ============================================================================
 * 파일명        : 광주_1반_서혁인_종합실습4_MV.sql
 * 프로그램 설명 : 일별 총매출(GMV) 리포트를 가속하기 위한 Materialized View
 *                 (mv_daily_gmv) 생성/조회/갱신 스크립트
 * 설명 비고     : - mv_daily_gmv 자체는 종합실습4_ecom_schema_postgres_테이블생성.sql
 *                   에 이미 정의되어 있음(본 파일은 활용/갱신 전략을 별도 정리)
 *                 - "매번 orders/order_items를 JOIN + SUM 하면 느리다"는 문제를
 *                   Materialized View로 해결하는 BEFORE/AFTER 비교 포함
 *                 - 갱신 전략: 데이터가 하루 단위로 누적되는 리포트 성격상,
 *                   실시간 반영이 필요 없다고 보고 "매일 오후 3시" 1회 갱신으로 설계
 * 사용 데이터   : ecom.orders, ecom.order_items, ecom.mv_daily_gmv
 * 데이터 비고   : REFRESH 전에는 MV가 최신 데이터를 반영하지 않으므로, 시드 데이터를
 *                 새로 넣거나(TRUNCATE 후 재적재) 주문이 추가되면 REFRESH 필요
 * 작성자        : 서혁인 (광주 1반)
 * ============================================================================ */

SET search_path = ecom, public;


-- ============================================================================
-- 1) BEFORE: Materialized View 없이 매번 JOIN + SUM으로 일별 매출 조회
-- ============================================================================
EXPLAIN ANALYZE
SELECT date_trunc('day', o.order_ts) AS day,
       SUM(oi.line_total)            AS gmv
FROM ecom.orders o
JOIN ecom.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY 1
ORDER BY 1;
-- 실측: Execution Time ≈ 16.91 ms, Buffers=377
-- (테이블이 지금은 작아서 체감이 크지 않지만, 주문/주문상세가 수백만 건으로 늘어나면
--  이 JOIN+GROUP BY는 리포트를 열 때마다 매번 무거운 풀스캔을 반복하게 됨)


-- ============================================================================
-- 2) Materialized View 정의 (참고용 재게시 — 원본은 스키마 파일에 있음)
-- ============================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS ecom.mv_daily_gmv AS
SELECT date_trunc('day', o.order_ts) AS day,
       SUM(oi.line_total)            AS gmv
FROM ecom.orders o
JOIN ecom.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status IN ('paid','shipped','delivered')
GROUP BY 1;

-- REFRESH CONCURRENTLY(조회 락 없이 갱신)를 쓰려면 UNIQUE 인덱스가 반드시 필요
CREATE UNIQUE INDEX IF NOT EXISTS ux_mv_daily_gmv_day ON ecom.mv_daily_gmv(day);


-- ============================================================================
-- 3) 최초 1회 데이터 적재 (생성 직후에는 비어 있을 수 있으므로 반드시 실행)
-- ============================================================================
REFRESH MATERIALIZED VIEW CONCURRENTLY ecom.mv_daily_gmv;


-- ============================================================================
-- 4) AFTER: Materialized View를 조회 (JOIN/SUM 없이 이미 집계된 결과만 SELECT)
-- ============================================================================
EXPLAIN ANALYZE
SELECT day, gmv
FROM ecom.mv_daily_gmv
ORDER BY day;
-- 실측: Execution Time ≈ 0.096 ms, Buffers=4
-- (BEFORE 대비 실행시간 약 176배, 버퍼 접근량 약 94배 감소 — 리포트용 쿼리를
--  "미리 계산해서 저장해두고 읽기만 하는" 방식으로 바꾼 효과)


-- ============================================================================
-- 5) 갱신(REFRESH) 전략 설계 — 매일 오후 3시(15:00) 1회 갱신
-- ============================================================================
-- [왜 오후 3시인가?]
--   - GMV 리포트는 "실시간"이 아니라 "일 단위 경영 지표" 성격이라 초 단위 최신성이
--     필요 없음 (요구사항: "데이터가 얼마나 자주 바뀌는지에 맞춰 갱신 주기를 설계")
--   - 오전 중 발생한 주문/취소/환불이 어느 정도 정리되는 시점(오후)에 한 번 갱신하면,
--     "당일 오전 매출까지 반영된 리포트"를 오후 업무 시간에 볼 수 있어 실무적으로 합리적
--   - 새벽 배치(예: 03:00)와 겹치지 않도록 피크 시간대를 벗어난 오후로 지정
--
-- [왜 REFRESH CONCURRENTLY 인가?]
--   - 일반 REFRESH MATERIALIZED VIEW는 갱신 중 해당 뷰에 ACCESS EXCLUSIVE 락을 걸어
--     갱신이 끝날 때까지 리포트 조회 자체가 막힘
--   - CONCURRENTLY 옵션은 새 스냅샷을 만든 뒤 원자적으로 교체하는 방식이라, 갱신 중에도
--     기존 데이터로 계속 조회 가능(단, UNIQUE 인덱스가 필요 — 위 3)번에서 이미 생성함)
--
-- [로컬 PC 환경에서의 스케줄링 방법]
--   실습 환경은 로컬 PostgreSQL이라 서버용 확장(pg_cron)이 기본 설치되어 있지 않음.
--   실무에서는 아래 중 하나를 선택:
--     (A) pg_cron 확장이 설치된 서버라면:
--         SELECT cron.schedule('daily-gmv-refresh', '0 15 * * *',
--           'REFRESH MATERIALIZED VIEW CONCURRENTLY ecom.mv_daily_gmv;');
--     (B) 로컬/온프레미스 서버라면 OS 스케줄러(macOS launchd, Linux cron)에서
--         매일 15:00에 아래 명령을 실행하도록 등록:
--           psql -U postgres -h localhost -d ecom_lab4 \
--             -c "REFRESH MATERIALIZED VIEW CONCURRENTLY ecom.mv_daily_gmv;"
--         (Linux/macOS crontab 예시: 0 15 * * * psql ... 위 명령)
--
-- 아래는 수동 갱신 예시(오후 3시가 되면 위 스케줄러가 이 명령을 대신 실행해 줌):
REFRESH MATERIALIZED VIEW CONCURRENTLY ecom.mv_daily_gmv;
