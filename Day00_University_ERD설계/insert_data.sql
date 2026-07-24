-- 1. 기존 데이터 초기화 (외래키 순서 고려)
TRUNCATE TABLE ACADEMIC_HISTORY CASCADE;
TRUNCATE TABLE ENROLLMENT CASCADE;
TRUNCATE TABLE COURSE CASCADE;
TRUNCATE TABLE STUDENT CASCADE;
TRUNCATE TABLE PROFESSOR CASCADE;
TRUNCATE TABLE DEPARTMENT CASCADE;

-- 2. DEPARTMENT (전공) 데이터 삽입 (10건)
INSERT INTO DEPARTMENT (dept_code, dept_name) VALUES 
('CS', '컴퓨터공학과'),
('BA', '경영학과'),
('DS', '데이터사이언스학과'),
('ENG', '영어영문학과'),
('EE', '전자공학과'),
('ME', '기계공학과'),
('AI', '인공지능학과'),
('MATH', '수학과'),
('PHYS', '물리학과'),
('CHEM', '화학과');

-- 3. PROFESSOR (교수) 데이터 삽입 (10건)
INSERT INTO PROFESSOR (prof_id, name, contact, hire_date, resign_date, dept_code) VALUES 
('P001', '김데이터', 'data.kim@univ.ac.kr', '2015-03-01', NULL, 'CS'),
('P002', '이알고', 'algo.lee@univ.ac.kr', '2018-09-01', NULL, 'CS'),
('P003', '박경영', 'biz.park@univ.ac.kr', '2010-03-01', NULL, 'BA'),
('P004', '최통계', 'stat.choi@univ.ac.kr', '2020-03-01', NULL, 'DS'),
('P005', '정문학', 'lit.jung@univ.ac.kr', '2005-03-01', '2024-02-28', 'ENG'),
('P006', '오회로', 'circuit.oh@univ.ac.kr', '2012-03-01', NULL, 'EE'),
('P007', '강기계', 'mech.kang@univ.ac.kr', '2016-09-01', NULL, 'ME'),
('P008', '한AI', 'ai.han@univ.ac.kr', '2022-03-01', NULL, 'AI'),
('P009', '윤수학', 'math.yoon@univ.ac.kr', '2008-03-01', NULL, 'MATH'),
('P010', '임물리', 'phys.lim@univ.ac.kr', '2014-03-01', NULL, 'PHYS');

-- 4. STUDENT (학생) 데이터 삽입 (10건)
INSERT INTO STUDENT (student_id, name, year, major_code, minor_code, double_major_code, advisor_id) VALUES 
('S202301', '김민수', 3, 'CS', NULL, NULL, 'P001'),
('S202402', '이지은', 2, 'BA', 'CS', NULL, 'P003'),
('S202203', '박태용', 4, 'DS', NULL, 'BA', 'P004'),
('S202504', '최유리', 1, 'ENG', NULL, NULL, NULL),
('S202305', '한지후', 3, 'CS', 'BA', NULL, 'P002'),
('S202206', '오서준', 4, 'EE', NULL, NULL, 'P006'),
('S202407', '서지우', 2, 'ME', 'EE', NULL, 'P007'),
('S202508', '신예준', 1, 'AI', NULL, NULL, 'P008'),
('S202309', '배하은', 3, 'MATH', 'CS', NULL, 'P009'),
('S202210', '권도윤', 4, 'PHYS', NULL, 'MATH', 'P010');

-- 5. COURSE (강의) 데이터 삽입 (10건)
INSERT INTO COURSE (course_code, course_name, course_type, capacity, credits, dept_code, prof_id) VALUES 
('C101', '데이터베이스 개론', '전공필수', 40, 3, 'CS', 'P001'),
('C102', '자료구조', '전공필수', 40, 3, 'CS', 'P002'),
('C201', '마케팅 원론', '전공필수', 50, 3, 'BA', 'P003'),
('C301', '인공지능 기초', '전공선택', 30, 3, 'DS', 'P004'),
('C401', '영문학 개론', '전공필수', 40, 3, 'ENG', 'P005'),
('C501', '회로이론', '전공필수', 35, 3, 'EE', 'P006'),
('C601', '역학', '전공필수', 30, 3, 'ME', 'P007'),
('C701', '머신러닝', '전공선택', 25, 3, 'AI', 'P008'),
('C801', '선형대수학', '전공필수', 50, 3, 'MATH', 'P009'),
('C901', '일반물리학', '전공필수', 50, 3, 'PHYS', 'P010');

-- 6. ENROLLMENT (수강) 데이터 삽입 (12건 이상)
INSERT INTO ENROLLMENT (student_id, course_code, attendance_score, assignment_score, exam_score, final_grade) VALUES 
('S202301', 'C101', 20, 30, 45, 'A+'),
('S202301', 'C102', 20, 25, 40, 'B+'),
('S202301', 'C301', 20, 30, 40, 'A0'),
('S202402', 'C101', 18, 28, 35, 'B0'),
('S202402', 'C201', 20, 30, 50, 'A+'),
('S202402', 'C102', 15, 25, 45, 'B+'),
('S202203', 'C301', 20, 20, 30, 'C+'),
('S202203', 'C201', 15, 25, 35, 'C+'),
('S202504', 'C401', 20, 20, 20, 'D0'),
('S202504', 'C201', 10, 15, 30, 'C0'),
('S202305', 'C101', 20, 28, 42, 'A0'),
('S202305', 'C102', 19, 27, 44, 'A+'),
('S202206', 'C501', 20, 30, 48, 'A+'),
('S202407', 'C601', 18, 25, 40, 'B0');

-- 7. ACADEMIC_HISTORY (학적 변동) 데이터 삽입 (10건)
INSERT INTO ACADEMIC_HISTORY (student_id, status, change_date) VALUES 
('S202301', '입학', '2023-03-02'),
('S202402', '입학', '2024-03-02'),
('S202402', '휴학', '2024-09-01'),
('S202402', '복학', '2025-03-02'),
('S202203', '입학', '2022-03-02'),
('S202504', '입학', '2025-03-02'),
('S202305', '입학', '2023-03-02'),
('S202206', '입학', '2022-03-02'),
('S202407', '입학', '2024-03-02'),
('S202210', '입학', '2022-03-02');

SELECT 
    schemaname,
    relname AS table_name,
    n_live_tup AS rows
FROM 
    pg_stat_user_tables
ORDER BY 
    table_name;