use springboardopt;
SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

DROP INDEX `PRIMARY` ON Student;
DROP INDEX `PRIMARY` ON Professor;
DROP INDEX `PRIMARY` ON Transcript;

-- 5. List the names of students who have taken a course from department v6 (deptId), but not v7.
EXPLAIN ANALYZE
SELECT * FROM Student, 
	(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;
/*
-> Inner hash join (student.id = transcript.studId)  (actual time=0.587..0.922 rows=30 loops=1)
     -> Table scan on Student  (cost=0.07 rows=400) (actual time=0.005..0.294 rows=400 loops=1)
     -> Hash
         -> Nested loop antijoin  (actual time=0.375..0.551 rows=30 loops=1)
             -> Filter: (transcript.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.147..0.265 rows=30 loops=1)
                 -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.146..0.259 rows=30 loops=1)
                     -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.004..0.087 rows=100 loops=1)
                     -> Hash
                         -> Filter: (course.deptId = <cache>((@v6)))  (cost=10.25 rows=10) (actual time=0.021..0.119 rows=26 loops=1)
                             -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.017..0.086 rows=100 loops=1)
             -> Single-row index lookup on <subquery3> using <auto_distinct_key> (studId=transcript.studId)  (actual time=0.000..0.000 rows=0 loops=30)
                 -> Materialize with deduplication  (actual time=0.008..0.008 rows=0 loops=30)
                     -> Filter: (course.crsCode = transcript.crsCode)  (cost=1010.60 rows=10000) (actual time=0.097..0.212 rows=34 loops=1)
                         -> Inner hash join (<hash>(course.crsCode)=<hash>(transcript.crsCode))  (cost=1010.60 rows=10000) (actual time=0.096..0.204 rows=34 loops=1)
                             -> Filter: (course.deptId = <cache>((@v7)))  (cost=0.10 rows=100) (actual time=0.005..0.100 rows=32 loops=1)
                                 -> Table scan on Course  (cost=0.10 rows=100) (actual time=0.002..0.055 rows=100 loops=1)
                             -> Hash
                                 -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.002..0.055 rows=100 loops=1)
 
*/

/*
Test with ctes. The result is worse than the original
*/
EXPLAIN ANALYZE
WITH cte1 AS
(SELECT crsCode
FROM Course WHERE deptId = @v6),
cte2 AS
(SELECT crsCode
FROM Course WHERE deptId = @v7)
SELECT * FROM Student
WHERE Student.id IN (
SELECT studId FROM Transcript, cte1, cte2
WHERE Transcript.crsCode = cte1.crsCode AND
	  Transcript.crsCode != cte2.crsCode )
      ;
/*
-> Inner hash join (student.id = `<subquery2>`.studId)  (actual time=1.333..1.859 rows=26 loops=1)
     -> Table scan on Student  (cost=6.95 rows=400) (actual time=0.013..0.463 rows=400 loops=1)
     -> Hash
         -> Table scan on <subquery2>  (actual time=0.001..0.003 rows=26 loops=1)
             -> Materialize with deduplication  (actual time=1.257..1.261 rows=26 loops=1)
                 -> Filter: (course.crsCode <> course.crsCode)  (cost=220.61 rows=81) (actual time=0.457..0.972 rows=960 loops=1)
                     -> Inner hash join (no condition)  (cost=220.61 rows=81) (actual time=0.456..0.782 rows=960 loops=1)
                         -> Filter: (course.deptId = <cache>((@v7)))  (cost=0.21 rows=9) (actual time=0.008..0.123 rows=32 loops=1)
                             -> Table scan on Course  (cost=0.21 rows=100) (actual time=0.003..0.100 rows=100 loops=1)
                         -> Hash
                             -> Filter: (transcript.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.306..0.414 rows=30 loops=1)
                                 -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.305..0.405 rows=30 loops=1)
                                     -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.007..0.082 rows=100 loops=1)
                                     -> Hash
                                         -> Filter: (course.deptId = <cache>((@v6)))  (cost=10.25 rows=10) (actual time=0.041..0.258 rows=26 loops=1)
                                             -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.034..0.232 rows=100 loops=1)
 
 
*/

/*Test with temp tables. The result is worse than the original*/
CREATE TEMPORARY TABLE t1
SELECT crsCode
FROM Course WHERE deptId = @v6;

CREATE TEMPORARY TABLE t2
SELECT crsCode
FROM Course WHERE deptId = @v7;

EXPLAIN ANALYZE
SELECT * FROM Student, Transcript
WHERE Transcript.crsCode IN (SELECT crsCode from t1) AND 
      studId NOT IN (SELECT crsCode from t2) AND
      Student.id = Transcript.studId;
      
/*
-> Inner hash join (student.id = transcript.studId)  (actual time=2.250..2.758 rows=26 loops=1)
     -> Table scan on Student  (cost=0.52 rows=400) (actual time=0.012..0.436 rows=400 loops=1)
     -> Hash
         -> Filter: (<in_optimizer>(transcript.studId,<exists>(select #3) is false) and (transcript.crsCode = `<subquery2>`.crsCode))  (actual time=0.195..2.164 rows=26 loops=1)
             -> Inner hash join (<hash>(transcript.crsCode)=<hash>(`<subquery2>`.crsCode))  (actual time=0.087..0.217 rows=26 loops=1)
                 -> Table scan on Transcript  (cost=1.28 rows=100) (actual time=0.005..0.095 rows=100 loops=1)
                 -> Hash
                     -> Table scan on <subquery2>  (actual time=0.001..0.002 rows=24 loops=1)
                         -> Materialize with deduplication  (actual time=0.052..0.055 rows=24 loops=1)
                             -> Filter: (t1.crsCode is not null)  (cost=2.85 rows=26) (actual time=0.022..0.034 rows=26 loops=1)
                                 -> Table scan on t1  (cost=2.85 rows=26) (actual time=0.021..0.031 rows=26 loops=1)
             -> Select #3 (subquery in condition; dependent)
                 -> Limit: 1 row(s)  (actual time=0.072..0.072 rows=0 loops=26)
                     -> Filter: <is_not_null_test>(t2.crsCode)  (actual time=0.072..0.072 rows=0 loops=26)
                         -> Filter: ((<cache>(transcript.studId) = t2.crsCode) or (t2.crsCode is null))  (cost=0.86 rows=6) (actual time=0.072..0.072 rows=0 loops=26)
                             -> Table scan on t2  (cost=0.86 rows=32) (actual time=0.002..0.027 rows=32 loops=26)
 
*/      

/*
Add the primary index in Student. 
Retest the original. The actual time reduce nearly 50%
*/
ALTER TABLE Student ADD PRIMARY KEY (id);
EXPLAIN ANALYZE
SELECT * FROM Student, 
	(SELECT studId FROM Transcript, Course WHERE deptId = @v6 AND Course.crsCode = Transcript.crsCode
	AND studId NOT IN
	(SELECT studId FROM Transcript, Course WHERE deptId = @v7 AND Course.crsCode = Transcript.crsCode)) as alias
WHERE Student.id = alias.studId;
/*
-> Nested loop inner join  (actual time=0.324..0.440 rows=30 loops=1)
     -> Nested loop antijoin  (actual time=0.312..0.382 rows=30 loops=1)
         -> Filter: (transcript.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.130..0.186 rows=30 loops=1)
             -> Inner hash join (<hash>(transcript.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.129..0.180 rows=30 loops=1)
                 -> Table scan on Transcript  (cost=0.13 rows=100) (actual time=0.005..0.043 rows=100 loops=1)
                 -> Hash
                     -> Filter: (course.deptId = <cache>((@v6)))  (cost=10.25 rows=10) (actual time=0.022..0.103 rows=26 loops=1)
                         -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.018..0.088 rows=100 loops=1)
         -> Single-row index lookup on <subquery3> using <auto_distinct_key> (studId=transcript.studId)  (actual time=0.000..0.000 rows=0 loops=30)
             -> Materialize with deduplication  (actual time=0.006..0.006 rows=0 loops=30)
                 -> Filter: (course.crsCode = transcript.crsCode)  (cost=1010.60 rows=10000) (actual time=0.098..0.168 rows=34 loops=1)
                     -> Inner hash join (<hash>(course.crsCode)=<hash>(transcript.crsCode))  (cost=1010.60 rows=10000) (actual time=0.098..0.163 rows=34 loops=1)
                         -> Filter: (course.deptId = <cache>((@v7)))  (cost=0.10 rows=100) (actual time=0.005..0.063 rows=32 loops=1)
                             -> Table scan on Course  (cost=0.10 rows=100) (actual time=0.002..0.053 rows=100 loops=1)
                         -> Hash
                             -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.002..0.043 rows=100 loops=1)
     -> Single-row index lookup on Student using PRIMARY (id=transcript.studId)  (cost=0.06 rows=1) (actual time=0.002..0.002 rows=1 loops=30)
 
*/