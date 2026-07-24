-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 16] 자신의 학과 평균 GPA보다 높은 학생 (Correlated Subquery)
-- =================================================================
SELECT '--- [실습 16] 학과 평균 GPA 초과 학생 (상관 서브쿼리) ---' AS title;
SELECT s1.student_id, s1.name, s1.major, s1.gpa
FROM student s1
WHERE s1.gpa > (
    SELECT AVG(s2.gpa)
    FROM student s2
    WHERE s2.major = s1.major
)
ORDER BY s1.major, s1.gpa DESC
LIMIT 5;

-- =================================================================
-- [실습 17] 수강(enroll) 기록이 있는 학생만 (EXISTS 활용)
-- =================================================================
SELECT '--- [실습 17] 수강 이력 존재 학생 조회 (EXISTS) ---' AS title;
SELECT s.student_id, s.name
FROM student s
WHERE EXISTS (
    SELECT 1 
    FROM enroll e 
    WHERE e.student_id = s.student_id
)
ORDER BY s.student_id
LIMIT 5;

-- =================================================================
-- [실습 18] 한 번도 수강하지 않은 학생 (NOT EXISTS)
-- =================================================================
SELECT '--- [실습 18] 미수강 학생 조회 (NOT EXISTS) ---' AS title;
SELECT s.student_id, s.name
FROM student s
WHERE NOT EXISTS (
    SELECT 1 
    FROM enroll e 
    WHERE e.student_id = s.student_id
)
ORDER BY s.student_id
LIMIT 5;

-- =================================================================
-- [실습 19] HR 학과 학생 일부와의 비교 데모 (ANY / IN 활용)
-- =================================================================
SELECT '--- [실습 19] HR 학과 학생과 GPA 비교 조회 ---' AS title;
SELECT student_id, name, major, gpa
FROM student
WHERE gpa > ANY (
    SELECT gpa 
    FROM student 
    WHERE major = 'HR'
)
ORDER BY gpa DESC
LIMIT 5;

-- =================================================================
-- [실습 20] CS 학과 학생 또는 DB 과목을 수강한 학생 목록 (UNION 조합)
-- =================================================================
SELECT '--- [실습 20] CS 학과 소속 또는 DB 과목 수강생 목록 (UNION) ---' AS title;
SELECT s.student_id, s.name, s.major
FROM student s
WHERE s.major = 'CS'
UNION
SELECT s.student_id, s.name, s.major
FROM student s
JOIN enroll e ON s.student_id = e.student_id
WHERE e.course = 'DB'
ORDER BY student_id
LIMIT 5;