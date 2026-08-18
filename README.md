# skala-sql

SKALA SQL 실습. ERD 설계와 기본 쿼리부터 실행계획 기반 튜닝까지 다룹니다. PostgreSQL 기준입니다.

## 구성

### `Day00_University_ERD설계/`
대학 수강 도메인 ERD를 직접 설계하고 SQL로 구현했습니다.

`create_table.sql` (스키마) · `insert_data.sql` (샘플 데이터) · `select_practice.sql` · `join_practice.sql` · `function_practice.sql`

### `Day01_SQL실습_Lab01-25/`
Lab 25문항. `setup_skala_db.sql`로 실습 DB를 만든 뒤 `lab_01_05.sql`부터 순서대로 진행합니다. 뒤쪽 21~25번은 문항별로 파일이 나뉘어 있습니다.

### 종합실습 4 — 쿼리 튜닝
e-commerce 스키마를 대상으로 느린 쿼리 11개를 튜닝했습니다.

- `종합실습4_ecom_schema_postgres_테이블생성.sql` · `종합실습4_ecom_seed_postgres_데이터입력.sql` — 실습 환경 구축
- `광주_1반_서혁인_종합실습4_쿼리모음.sql` — 튜닝 대상 쿼리와 개선안
- `광주_1반_서혁인_종합실습4_MV.sql` — Materialized View 적용
- `광주_1반_서혁인_종합실습4_조인비교_옵티마이저.html` — 조인 방식별 옵티마이저 동작 비교
- `광주_1반_서혁인.html` — 최종 제출 리포트

`captures/`에 문항별 튜닝 **전/후 실행 결과**와 쿼리 스크린샷이 `Q1_before_result.png` / `Q1_after_result.png` 형태로 짝지어 들어 있습니다. Materialized View는 `MV_` 접두사로 refresh 결과까지 포함했습니다.

### `SQL튜닝_학습자료.html`
튜닝 파트 정리 노트.

## 실행

```bash
psql -U <user> -d <db> -f Day01_SQL실습_Lab01-25/setup_skala_db.sql
```
