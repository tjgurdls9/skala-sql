-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 6] 한 과목 이상 수강한 학생 목록 (중복 제거)
-- =================================================================
SELECT '--- [실습 6] 한 과목 이상 수강한 학생 목록 (DISTINCT) ---' AS title;
SELECT DISTINCT s.student_id, s.name
FROM student s
JOIN enroll e ON s.student_id = e.student_id
ORDER BY s.student_id
LIMIT 5;

-- =================================================================
-- [실습 7] 고객별 주문건수 / 총액 (GROUP BY + COUNT + SUM)
-- =================================================================
SELECT '--- [실습 7] 고객별 주문건수 및 총액 집계 ---' AS title;
SELECT c.customer_id, c.customer_name, 
       COUNT(o.order_id) AS total_orders, 
       SUM(o.amount) AS total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_amount DESC
LIMIT 5;

-- =================================================================
-- [실습 8] 총액 상위 10명과 금액 (GROUP BY + ORDER BY + LIMIT)
-- =================================================================
SELECT '--- [실습 8] 주문 총액 상위 10명 고객 조회 ---' AS title;
SELECT c.customer_id, c.customer_name, 
       SUM(o.amount) AS total_amount
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_amount DESC
LIMIT 10;

-- =================================================================
-- [실습 9] 모든 직원과 그 매니저 이름 (SELF JOIN)
-- =================================================================
SELECT '--- [실습 9] 모든 직원과 매니저 이름 조회 (SELF JOIN) ---' AS title;
SELECT e.emp_id, e.name AS employee_name, 
       COALESCE(m.name, '최상위(CEO)') AS manager_name
FROM emp e
LEFT JOIN emp m ON e.manager_id = m.emp_id
ORDER BY e.emp_id
LIMIT 5;

-- =================================================================
-- [실습 10] "모든 학생 기준"으로 과목 분포를 보고 싶다 -> LEFT JOIN + 집계
-- =================================================================
SELECT '--- [실습 10] 모든 학생 기준 수강 과목 수 분포 집계 ---' AS title;
SELECT s.student_id, s.name, 
       COUNT(e.course) AS enrolled_course_count
FROM student s
LEFT JOIN enroll e ON s.student_id = e.student_id
GROUP BY s.student_id, s.name
ORDER BY enrolled_course_count DESC, s.student_id ASC
LIMIT 5;