-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 21] 학과별/GPA 구간별 인원 집계 및 소계/총계 (ROLLUP)
-- =================================================================
SELECT '--- [실습 21] 학과별/GPA 구간별 집계 (ROLLUP & GROUPING) ---' AS title;

SELECT 
    CASE WHEN GROUPING(major) = 1 THEN '전체(총계)' ELSE major END AS major,
    CASE WHEN GROUPING(gpa_tier) = 1 THEN '소계' ELSE gpa_tier END AS gpa_tier,
    COUNT(*) AS student_count
FROM (
    -- 1단계: GPA 구간(gpa_tier) 파생 컬럼 생성
    SELECT major,
           CASE 
               WHEN gpa < 3.0 THEN '3.0 미만'
               WHEN gpa >= 3.0 AND gpa <= 3.5 THEN '3.0~3.5'
               WHEN gpa > 3.5 THEN '3.5 초과'
           END AS gpa_tier
    FROM student
) s
-- 2단계: 학과와 GPA 구간을 기준으로 다차원 집계 (소계 및 총계 생성)
GROUP BY ROLLUP(major, gpa_tier)
-- 3단계: 소계(GROUPING 1)가 하단으로 가도록 정렬 처리
ORDER BY 
    GROUPING(major),       -- 총계 행을 맨 아래로
    major,                 -- 학과 알파벳 순
    GROUPING(gpa_tier),    -- 학과 내에서 소계 행을 맨 아래로
    gpa_tier               -- 구간 이름 순
LIMIT 15;