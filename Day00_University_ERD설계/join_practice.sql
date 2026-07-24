-- [실습 1] 학생과 소속 학과 정보를 함께 조회 (INNER JOIN)
SELECT '--- [실습 1] 학생 및 소속 학과 조회 (INNER JOIN) ---' AS title;
SELECT s.student_id, s.name AS student_name, s.year, d.dept_name 
FROM student s
JOIN department d ON s.major_code = d.dept_code;

-- [실습 2] 교수가 소속된 학과 정보와 함께 조회 (INNER JOIN)
SELECT '--- [실습 2] 교수 및 소속 학과 조회 (INNER JOIN) ---' AS title;
SELECT p.prof_id, p.name AS professor_name, d.dept_name, p.contact 
FROM professor p
JOIN department d ON p.dept_code = d.dept_code;

-- [실습 3] 강의를 개설한 학과와 담당 교수 이름까지 함께 조회 (MULTI JOIN)
SELECT '--- [실습 3] 강의 개설 학과 및 담당 교수 조회 (MULTI JOIN) ---' AS title;
SELECT c.course_code, c.course_name, d.dept_name, p.name AS professor_name, c.capacity 
FROM course c
JOIN department d ON c.dept_code = d.dept_code
JOIN professor p ON c.prof_id = p.prof_id;

-- [실습 4] 학생이 수강 중인 강의 코드와 성적 정보 조회 (ENROLLMENT JOIN)
SELECT '--- [실습 4] 학생별 수강 및 성적 조회 (ENROLLMENT JOIN) ---' AS title;
SELECT s.student_id, s.name AS student_name, e.course_code, e.exam_score, e.final_grade 
FROM student s
JOIN enrollment e ON s.student_id = e.student_id
ORDER BY s.student_id, e.course_code;

-- [실습 5] 수강신청 내역에 강의명과 학점 정보를 함께 조회 (ENROLLMENT + COURSE)
SELECT '--- [실습 5] 수강신청 강의 상세 정보 조회 ---' AS title;
SELECT s.name AS student_name, c.course_name, c.credits, e.exam_score, e.final_grade 
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course c ON e.course_code = c.course_code
ORDER BY e.exam_score DESC;

-- [실습 6] 학생과 지도교수(Advisor) 이름을 매칭하여 조회 (LEFT JOIN)
SELECT '--- [실습 6] 학생 및 지도교수 매칭 조회 (LEFT JOIN) ---' AS title;
SELECT s.student_id, s.name AS student_name, COALESCE(p.name, '지도교수 없음') AS advisor_name 
FROM student s
LEFT JOIN professor p ON s.advisor_id = p.prof_id;

-- [실습 7] 모든 교수 목록과 그 교수가 담당하는 강의 수 조회 (LEFT JOIN + GROUP BY)
SELECT '--- [실습 7] 교수별 담당 강의 개수 조회 (LEFT JOIN & GROUP BY) ---' AS title;
SELECT p.prof_id, p.name AS professor_name, COUNT(c.course_code) AS lecture_count 
FROM professor p
LEFT JOIN course c ON p.prof_id = c.prof_id
GROUP BY p.prof_id, p.name
ORDER BY lecture_count DESC;

-- [실습 8] 학과별 소속 학생 수 집계 조회 (JOIN + GROUP BY)
SELECT '--- [실습 8] 학과별 학생 수 집계 조회 ---' AS title;
SELECT d.dept_code, d.dept_name, COUNT(s.student_id) AS student_count 
FROM department d
LEFT JOIN student s ON d.dept_code = s.major_code
GROUP BY d.dept_code, d.dept_name
ORDER BY student_count DESC;

-- [실습 9] 학생별 총 수강 과목 수 및 평균 시험 점수 조회 (AGGREGATE JOIN)
SELECT '--- [실습 9] 학생별 수강 과목 수 및 평균 점수 조회 ---' AS title;
SELECT s.student_id, s.name AS student_name, 
       COUNT(e.course_code) AS total_courses, 
       ROUND(AVG(e.exam_score), 2) AS avg_exam_score 
FROM student s
JOIN enrollment e ON s.student_id = e.student_id
GROUP BY s.student_id, s.name
ORDER BY avg_exam_score DESC;

-- [실습 10] 학생, 수강 강의, 담당 교수까지 모두 결합한 종합 조회 (FULL MULTI JOIN)
SELECT '--- [실습 10] 학생-강의-교수 종합 정보 조회 ---' AS title;
SELECT s.name AS student_name, c.course_name, p.name AS professor_name, e.final_grade 
FROM enrollment e
JOIN student s ON e.student_id = s.student_id
JOIN course c ON e.course_code = c.course_code
JOIN professor p ON c.prof_id = p.prof_id
ORDER BY s.name;