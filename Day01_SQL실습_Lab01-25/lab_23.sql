-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 23-1] 학과별 GPA 상위 3명 추출 (서브쿼리 방식)
-- =================================================================
SELECT '--- [실습 23-1] 학과별 GPA 상위 3명 (서브쿼리 방식) ---' AS title;

SELECT *
FROM (
    SELECT 
        student_id,
        name,
        major,
        gpa,
        -- 1. 무조건 고유한 순위 (동점이어도 1, 2, 3...)
        ROW_NUMBER() OVER(PARTITION BY major ORDER BY gpa DESC, student_id ASC) AS row_num,
        -- 2. 동점자는 같은 순위, 다음 순위는 건너뜀 (예: 1, 1, 3...)
        RANK() OVER(PARTITION BY major ORDER BY gpa DESC, student_id ASC) AS rnk,
        -- 3. 동점자는 같은 순위, 다음 순위는 촘촘하게 (예: 1, 1, 2...)
        DENSE_RANK() OVER(PARTITION BY major ORDER BY gpa DESC, student_id ASC) AS dense_rnk,
        -- 4. 학과별 전체 학생 수
        COUNT(student_id) OVER(PARTITION BY major) AS total_in_major
    FROM student
) sub
WHERE row_num <= 3
ORDER BY major, row_num
LIMIT 15;

-- =================================================================
-- [실습 23-2] 학과별 GPA 상위 3명 추출 (CTE 방식 - 실무에서 더 권장됨)
-- =================================================================
SELECT '--- [실습 23-2] 학과별 GPA 상위 3명 (CTE 방식) ---' AS title;

WITH RankedStudents AS (
    SELECT 
        student_id,
        name,
        major,
        gpa,
        ROW_NUMBER() OVER(PARTITION BY major ORDER BY gpa DESC, student_id ASC) AS row_num,
        RANK() OVER(PARTITION BY major ORDER BY gpa DESC, student_id ASC) AS rnk,
        DENSE_RANK() OVER(PARTITION BY major ORDER BY gpa DESC, student_id ASC) AS dense_rnk,
        COUNT(student_id) OVER(PARTITION BY major) AS total_in_major
    FROM student
)
SELECT *
FROM RankedStudents
WHERE row_num <= 3
ORDER BY major, row_num
LIMIT 15;