-- DBeaver 또는 psql 실행 시 스키마 지정
SET search_path TO lab;

-- =================================================================
-- [실습 22-1] WITH RECURSIVE로 모든 직원의 계층 경로와 깊이 출력
-- =================================================================
SELECT '--- [실습 22-1] 조직도 계층 트리 탐색 (WITH RECURSIVE) ---' AS title;

WITH RECURSIVE emp_tree AS (
    -- 1. Anchor (시작점): CEO (manager_id가 NULL인 사람)
    SELECT emp_id, 
           name, 
           manager_id, 
           0 AS depth, 
           CAST(name AS VARCHAR(500)) AS path
    FROM emp
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- 2. Recursive (반복): 상위 매니저와 연결되는 부하 직원들
    SELECT e.emp_id, 
           e.name, 
           e.manager_id, 
           t.depth + 1 AS depth, 
           CAST(t.path || ' > ' || e.name AS VARCHAR(500)) AS path
    FROM emp e
    JOIN emp_tree t ON e.manager_id = t.emp_id
)
SELECT emp_id, name, depth, path
FROM emp_tree
ORDER BY path
LIMIT 10;

-- =================================================================
-- [실습 22-2] 매니저별 직속 부하 직원 수 집계 (별도 작성)
-- =================================================================
SELECT '--- [실습 22-2] 매니저별 직속 부하 직원 수 집계 ---' AS title;

SELECT m.emp_id AS manager_id, 
       m.name AS manager_name, 
       COUNT(e.emp_id) AS direct_reports
FROM emp m
JOIN emp e ON m.emp_id = e.manager_id
GROUP BY m.emp_id, m.name
ORDER BY direct_reports DESC
LIMIT 5;