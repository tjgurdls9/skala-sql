-- 1. DEPARTMENT (학과) 테이블 생성
CREATE TABLE department (
    dept_code VARCHAR(10) PRIMARY KEY,
    dept_name VARCHAR(50) NOT NULL UNIQUE
);

-- 2. PROFESSOR (교수) 테이블 생성
CREATE TABLE professor (
    prof_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    contact VARCHAR(100),
    hire_date DATE NOT NULL DEFAULT CURRENT_DATE,
    resign_date DATE,
    dept_code VARCHAR(10) NOT NULL REFERENCES department(dept_code)
);

-- 3. STUDENT (학생) 테이블 생성
CREATE TABLE student (
    student_id VARCHAR(10) PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    year INT NOT NULL CHECK (year BETWEEN 1 AND 4),
    major_code VARCHAR(10) NOT NULL REFERENCES department(dept_code),
    minor_code VARCHAR(10) REFERENCES department(dept_code),
    double_major_code VARCHAR(10) REFERENCES department(dept_code),
    advisor_id VARCHAR(10) REFERENCES professor(prof_id)
);

-- 4. COURSE (강의) 테이블 생성
CREATE TABLE course (
    course_code VARCHAR(10) PRIMARY KEY,
    course_name VARCHAR(50) NOT NULL,
    course_type VARCHAR(20) NOT NULL,
    capacity INT NOT NULL CHECK (capacity > 0),
    credits INT NOT NULL CHECK (credits BETWEEN 1 AND 4),
    dept_code VARCHAR(10) NOT NULL REFERENCES department(dept_code),
    prof_id VARCHAR(10) REFERENCES professor(prof_id)
);

-- 5. ENROLLMENT (수강신청) 교차 테이블 생성
CREATE TABLE enrollment (
    student_id VARCHAR(10) REFERENCES student(student_id),
    course_code VARCHAR(10) REFERENCES course(course_code),
    attendance_score INT NOT NULL DEFAULT 0,
    assignment_score INT NOT NULL DEFAULT 0,
    exam_score INT NOT NULL DEFAULT 0,
    final_grade VARCHAR(5),
    PRIMARY KEY (student_id, course_code)
);

-- 6. ACADEMIC_HISTORY (학적 변동) 테이블 생성
CREATE TABLE academic_history (
    history_id SERIAL PRIMARY KEY,
    student_id VARCHAR(10) NOT NULL REFERENCES student(student_id),
    status VARCHAR(20) NOT NULL,
    change_date DATE NOT NULL DEFAULT CURRENT_DATE
);