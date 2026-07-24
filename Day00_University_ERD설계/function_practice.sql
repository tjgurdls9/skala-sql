-- [실습 1] 교수 퇴직일이 NULL일 경우 '재직중'으로 치환 (COALESCE)
SELECT '--- [실습 1] 교수 퇴직일 NULL 대체 (COALESCE) ---' AS title;
SELECT prof_id, name, dept_code, COALESCE(resign_date::text, '재직중') AS status_info
FROM professor;

-- [실습 2] 학생 부전공/복수전공이 없으면 '미등록'으로 표시 (COALESCE)
SELECT '--- [실습 2] 학생 부전공/복수전공 미등록 대체 (COALESCE) ---' AS title;
SELECT student_id, name, 
       COALESCE(minor_code, '없음') AS minor, 
       COALESCE(double_major_code, '없음') AS double_major
FROM student;

-- [실습 3] 학생 학년을 기준으로 학년별 그룹명 부여 (CASE WHEN)
SELECT '--- [실습 3] 학생 학년 그룹 분류 (CASE WHEN) ---' AS title;
SELECT student_id, name, year,
       CASE 
           WHEN year IN (1, 2) THEN '저학년'
           WHEN year IN (3, 4) THEN '고학년'
           ELSE '기타'
       END AS year_group
FROM student;

-- [실습 4] 시험 점수에 따라 학점 구간 메시지 부여 (CASE WHEN)
SELECT '--- [실습 4] 시험 점수 등급 분류 (CASE WHEN) ---' AS title;
SELECT student_id, course_code, exam_score,
       CASE 
           WHEN exam_score >= 45 THEN '최우수 (A)'
           WHEN exam_score >= 35 THEN '우수 (B)'
           WHEN exam_score >= 25 THEN '보통 (C)'
           ELSE '노력 필요 (F)'
       END AS score_evaluation
FROM enrollment
ORDER BY exam_score DESC;

-- [실습 5] 강의 정원에 따른 수용 규모 상태 분류 (CASE WHEN)
SELECT '--- [실습 5] 강의 정원 규모 상태 분류 (CASE WHEN) ---' AS title;
SELECT course_code, course_name, capacity,
       CASE 
           WHEN capacity >= 45 THEN '대형 강의실 필요'
           WHEN capacity >= 35 THEN '중형 강의실 필요'
           ELSE '소형 강의실 가능'
       END AS room_requirement
FROM course;

-- [실습 6] 교수 재직 기간(년수) 계산 (날짜 연산 및 함수)
SELECT '--- [실습 6] 교수 근속 연수 계산 (날짜 연산) ---' AS title;
SELECT prof_id, name, hire_date,
       EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS working_years
FROM professor;

-- [실습 7] 특정 연도 이후에 입학한 학생 조회 (날짜 조건 추출)
SELECT '--- [실습 7] 특정 연도 이후 입학 학생 조회 (EXTRACT) ---' AS title;
SELECT history_id, student_id, status, change_date
FROM academic_history
WHERE EXTRACT(YEAR FROM change_date) >= 2024
ORDER BY change_date DESC;

-- [실습 8] 교수 채용 월(Month) 추출 및 정렬 (날짜 함수)
SELECT '--- [실습 8] 교수 채용 월 추출 (EXTRACT MONTH) ---' AS title;
SELECT prof_id, name, hire_date,
       EXTRACT(MONTH FROM hire_date) AS hire_month
FROM professor
ORDER BY hire_month ASC;

-- [실습 9] CASE WHEN과 COALESCE를 조합한 복합 정보 조회
SELECT '--- [실습 9] CASE 및 COALESCE 복합 활용 ---' AS title;
SELECT student_id, name, major_code,
       COALESCE(double_major_code, major_code) AS primary_or_double,
       CASE 
           WHEN year = 4 THEN '졸업예정'
           ELSE '재학중'
       END AS enrollment_status
FROM student;

-- [실습 10] 날짜 포맷 변환 및 최근 학적 변동 조회 (TO_CHAR / 날짜)
SELECT '--- [실습 10] 날짜 포맷 변환 조회 (TO_CHAR) ---' AS title;
SELECT student_id, status,
       TO_CHAR(change_date, 'YYYY년 MM월 DD일') AS formatted_date
FROM academic_history
ORDER BY change_date DESC;