-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 24] 이전 수강 과목 대비 성적 변화 (LAG) 및 최대/최소 격차
-- =================================================================
SELECT '--- [실습 24] 이전 과목 대비 성적 변화 분석 (LAG & Window) ---' AS title;

WITH ScoreConverted AS (
    -- 1. 성적을 숫자 점수로 변환 (CASE 식 활용)
    SELECT 
        student_id,
        course,
        grade,
        CASE grade 
            WHEN 'A' THEN 4 
            WHEN 'B' THEN 3 
            WHEN 'C' THEN 2 
            WHEN 'D' THEN 1 
            ELSE 0 
        END AS score
    FROM enroll
),
LagAndRange AS (
    -- 2. LAG()를 이용해 이전 점수 가져오기 및 학생별 최고/최저점 격차 계산
    SELECT 
        student_id,
        course,
        grade,
        score,
        LAG(score) OVER (PARTITION BY student_id ORDER BY course) AS prev_score,
        MAX(score) OVER (PARTITION BY student_id) - MIN(score) OVER (PARTITION BY student_id) AS score_range
    FROM ScoreConverted
)
-- 3. diff(점수 차이) 계산 및 상승/유지/하락 텍스트 표시
SELECT 
    student_id,
    course,
    grade,
    score,
    prev_score,
    (score - prev_score) AS diff,
    CASE 
        WHEN (score - prev_score) > 0 THEN '상승'
        WHEN (score - prev_score) = 0 THEN '유지'
        WHEN (score - prev_score) < 0 THEN '하락'
        ELSE '이전 데이터 없음' -- 첫 과목이거나 비교 대상이 없을 때
    END AS status,
    score_range
FROM LagAndRange
ORDER BY student_id, course
LIMIT 10;