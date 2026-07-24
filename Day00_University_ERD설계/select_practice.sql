-- [실습 1] 특정 학과 소속 교수 조회
SELECT '--- [실습 1] 특정 학과 소속 교수 조회 (WHERE) ---' AS title;
SELECT prof_id, name, contact, hire_date 
FROM professor 
WHERE dept_code = 'CS';

-- [실습 2] 특정 학년 이상 학생 조회
SELECT '--- [실습 2] 특정 학년 이상 학생 조회 (WHERE + ORDER BY) ---' AS title;
SELECT student_id, name, year, major_code 
FROM student 
WHERE year >= 3 
ORDER BY year DESC, name ASC;

-- [실습 3] 재직 중인 교수 목록 조회
SELECT '--- [실습 3] 재직 중인 교수 목록 조회 (IS NULL) ---' AS title;
SELECT prof_id, name, dept_code, hire_date 
FROM professor 
WHERE resign_date IS NULL;

-- [실습 4] 복수전공 또는 부전공을 가진 학생 조회
SELECT '--- [실습 4] 복수전공 또는 부전공을 가진 학생 조회 (OR 조건) ---' AS title;
SELECT student_id, name, major_code, minor_code, double_major_code 
FROM student 
WHERE minor_code IS NOT NULL OR double_major_code IS NOT NULL;

-- [실습 5] 특정 학점 이상인 강의 조회
SELECT '--- [실습 5] 특정 학점 이상인 강의 조회 (비교 연산) ---' AS title;
SELECT course_code, course_name, course_type, credits, capacity 
FROM course 
WHERE credits >= 3 AND capacity >= 40;

-- [실습 6] 학점순 및 강의명순 정렬 조회
SELECT '--- [실습 6] 학점순 및 강의명순 정렬 조회 (다중 ORDER BY) ---' AS title;
SELECT course_code, course_name, credits, dept_code 
FROM course 
ORDER BY credits DESC, course_name ASC;

-- [실습 7] 시험 점수 40점 이상 고득점 수강 내역 조회
SELECT '--- [실습 7] 시험 점수 40점 이상 고득점 수강 내역 조회 ---' AS title;
SELECT student_id, course_code, exam_score, final_grade 
FROM enrollment 
WHERE exam_score >= 40 
ORDER BY exam_score DESC;

-- [실습 8] 특정 학점(A+, A0 등)을 받은 수강 내역 조회
SELECT '--- [실습 8] 특정 학점(A+, A0 등)을 받은 수강 내역 조회 (IN) ---' AS title;
SELECT student_id, course_code, exam_score, final_grade 
FROM enrollment 
WHERE final_grade IN ('A+', 'A0')
ORDER BY exam_score DESC;

-- [실습 9] 특정 성씨를 가진 학생 조회
SELECT '--- [실습 9] 특정 성씨를 가진 학생 조회 (LIKE) ---' AS title;
SELECT student_id, name, year, major_code 
FROM student 
WHERE name LIKE '김%';

-- [실습 10] 2024년 이후에 입학한 학적 변동 내역 조회
SELECT '--- [실습 10] 2024년 이후 학적 변동 내역 조회 (날짜 조건) ---' AS title;
SELECT history_id, student_id, status, change_date 
FROM academic_history 
WHERE change_date >= '2024-01-01' 
ORDER BY change_date DESC;