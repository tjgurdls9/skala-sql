-- DBeaver에서 실행하실 때는 lab 스키마를 기본으로 잡거나 아래 명령어를 먼저 실행하세요.
SET search_path TO lab;

-- =================================================================
-- [실습 1] 학생과 수강을 INNER JOIN하여 수강 존재 학생의 과목/성적을 조회
-- =================================================================
SELECT '--- [실습 1] 학생과 수강 INNER JOIN ---' AS title;
SELECT s.student_id, s.name, e.course, e.grade
FROM student s
INNER JOIN enroll e ON s.student_id = e.student_id 
LIMIT 5;

-- =================================================================
-- [실습 2] 모든 학생 기준으로 수강을 붙이고, 과목(없으면 NULL)까지 보이기
-- =================================================================
SELECT '--- [실습 2] 모든 학생 기준 수강 조회 (LEFT JOIN) ---' AS title;
SELECT s.student_id, s.name, e.course, e.grade
FROM student s
LEFT JOIN enroll e ON s.student_id = e.student_id 
LIMIT 5;

-- =================================================================
-- [실습 3] 수강이 기준. 학생이 없으면 학생 정보가 NULL
-- =================================================================
SELECT '--- [실습 3] 수강 기준 학생 조회 (RIGHT JOIN) ---' AS title;
SELECT e.course, e.grade, s.student_id, s.name
FROM student s
RIGHT JOIN enroll e ON s.student_id = e.student_id 
LIMIT 5;

-- =================================================================
-- [실습 4] 학생/수강 모두 포함
-- =================================================================
SELECT '--- [실습 4] 학생과 수강 모두 포함 (FULL OUTER JOIN) ---' AS title;
SELECT s.student_id, s.name, e.course, e.grade
FROM student s
FULL OUTER JOIN enroll e ON s.student_id = e.student_id 
LIMIT 5;

-- =================================================================
-- [실습 5] 한 번도 수강하지 않은 학생 목록
-- =================================================================
SELECT '--- [실습 5] 미수강 학생 목록 (LEFT JOIN + IS NULL) ---' AS title;
SELECT s.student_id, s.name
FROM student s
LEFT JOIN enroll e ON s.student_id = e.student_id
WHERE e.course IS NULL 
LIMIT 5;