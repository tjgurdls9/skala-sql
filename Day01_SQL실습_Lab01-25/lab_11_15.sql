-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 11] DB 과목을 듣지 않은 모든 학생을 나열 (NOT IN / NOT EXISTS)
-- =================================================================
SELECT '--- [실습 11] DB 과목 미수강 학생 목록 ---' AS title;
SELECT s.student_id, s.name
FROM student s
WHERE s.student_id NOT IN (
    SELECT student_id 
    FROM enroll 
    WHERE course = 'DB'
)
ORDER BY s.student_id
LIMIT 5;

-- =================================================================
-- [실습 12] 과목별 매니저 매핑 테이블 생성 및 리포트 조회
-- =================================================================
SELECT '--- [실습 12] 과목별 운영 매니저 매핑 및 수강 인원 리포트 ---' AS title;
-- 임시 테이블(CTE)을 활용해 course_owner 매핑 구조를 구현하고 집계합니다.
WITH course_owner AS (
    SELECT DISTINCT e1.course AS course, e2.name AS manager_id
    FROM enroll e1
    JOIN (
        SELECT name FROM emp WHERE name LIKE 'Mgr_%'
    ) e2 ON (ASCII(e1.course) % 10) = (ASCII(e2.name) % 10)
)
SELECT co.course, co.manager_id, COUNT(en.student_id) AS student_count
FROM course_owner co
LEFT JOIN enroll en ON co.course = en.course
GROUP BY co.course, co.manager_id
ORDER BY student_count DESC
LIMIT 5;

-- =================================================================
-- [실습 13] 학생 × 과목 전체 조합으로 "학생별 과목 추천 후보" 생성 (샘플 10건)
-- =================================================================
SELECT '--- [실습 13] 학생별 과목 추천 후보 조합 (CROSS JOIN) ---' AS title;
SELECT s.student_id, s.name, c.course
FROM student s
CROSS JOIN (SELECT DISTINCT course FROM enroll) c
LIMIT 10;

-- =================================================================
-- [실습 14] 스칼라 서브쿼리(SELECT 절) 사용: 학생 + 소속 학과명 붙이기 효과
-- =================================================================
SELECT '--- [실습 14] 스칼라 서브쿼리를 이용한 정보 확장 ---' AS title;
SELECT s.student_id, s.name, s.major,
       (SELECT COUNT(*) FROM enroll e WHERE e.student_id = s.student_id) AS personal_enroll_count
FROM student s
LIMIT 5;

-- =================================================================
-- [실습 15] 전체 평균 GPA 보다 높은 학생 조회 (WHERE 서브쿼리)
-- =================================================================
SELECT '--- [실습 15] 전체 평균 GPA 초과 우수 학생 조회 ---' AS title;
SELECT student_id, name, major, gpa
FROM student
WHERE gpa > (SELECT AVG(gpa) FROM student)
ORDER BY gpa DESC
LIMIT 5;