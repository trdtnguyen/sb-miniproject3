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
DROP INDEX `PRIMARY` ON Transcript;

-- 4. List the names of students who have taken a course taught by professor v5 (name).
EXPLAIN ANALYZE
SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;

/*
-> Inner hash join (student.id = transcript.studId)  (cost=1313.72 rows=160) (actual time=0.300..0.300 rows=0 loops=1)
     -> Table scan on Student  (cost=0.03 rows=400) (never executed)
     -> Hash
         -> Inner hash join (professor.id = teaching.profId)  (cost=1144.90 rows=4) (actual time=0.276..0.276 rows=0 loops=1)
             -> Filter: (professor.`name` = <cache>((@v5)))  (cost=0.95 rows=4) (never executed)
                 -> Table scan on Professor  (cost=0.95 rows=400) (never executed)
             -> Hash
                 -> Filter: ((teaching.semester = transcript.semester) and (teaching.crsCode = transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.253..0.253 rows=0 loops=1)
                     -> Inner hash join (<hash>(teaching.semester)=<hash>(transcript.semester)), (<hash>(teaching.crsCode)=<hash>(transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.253..0.253 rows=0 loops=1)
                         -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.017..0.088 rows=100 loops=1)
                         -> Hash
                             -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.018..0.075 rows=100 loops=1)
 
*/

/*
Multiple joins make the query slow
Solution1: create indexes on tables. Note that we only create primary indexes on large tables i.e., Student and Professor.
For small tables such as Teaching, Transcript, use Table scan is better'.
Additional optimization: We reduce the query result on Professor table to one row (Professor.name = @v5) then use CTE as the join of teaching and thhe "one row".
That help reduce the query result for join significantly.

*/
ALTER TABLE Student ADD PRIMARY KEY (id);
ALTER TABLE Professor ADD PRIMARY KEY (id);


EXPLAIN ANALYZE
SELECT name FROM Student,
	(SELECT studId FROM Transcript,
		(SELECT crsCode, semester FROM Professor
			JOIN Teaching
			WHERE Professor.name = @v5 AND Professor.id = Teaching.profId) as alias1
	WHERE Transcript.crsCode = alias1.crsCode AND Transcript.semester = alias1.semester) as alias2
WHERE Student.id = alias2.studId;

/*
-> Inner hash join (professor.id = teaching.profId)  (cost=1231.79 rows=4) (actual time=0.223..0.223 rows=0 loops=1)
     -> Filter: (professor.`name` = <cache>((@v5)))  (cost=1.09 rows=4) (never executed)
         -> Table scan on Professor  (cost=1.09 rows=400) (never executed)
     -> Hash
         -> Nested loop inner join  (cost=1083.20 rows=100) (actual time=0.208..0.208 rows=0 loops=1)
             -> Filter: ((teaching.semester = transcript.semester) and (teaching.crsCode = transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.207..0.207 rows=0 loops=1)
                 -> Inner hash join (<hash>(teaching.semester)=<hash>(transcript.semester)), (<hash>(teaching.crsCode)=<hash>(transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.206..0.206 rows=0 loops=1)
                     -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.006..0.046 rows=100 loops=1)
                     -> Hash
                         -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.044..0.087 rows=100 loops=1)
             -> Single-row index lookup on Student using PRIMARY (id=transcript.studId)  (cost=0.63 rows=1) (never executed)
 
*/


EXPLAIN ANALYZE
WITH cte AS (
SELECT crsCode, semester
FROM Teaching WHERE profId IN(
	SELECT id FROM Professor WHERE Professor.name = @v5))
SELECT Student.name, Transcript.studId, Transcript.crsCode, Transcript.semester
FROM Student, Transcript, cte
WHERE Transcript.crsCode = cte.crsCode AND Transcript.semester = cte.semester AND
	   Student.id = Transcript.studId;
/*
-> Nested loop inner join  (cost=1131.32 rows=10) (actual time=0.174..0.174 rows=0 loops=1)
     -> Nested loop inner join  (cost=1120.70 rows=100) (actual time=0.173..0.173 rows=0 loops=1)
         -> Filter: ((teaching.semester = transcript.semester) and (teaching.crsCode = transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.173..0.173 rows=0 loops=1)
             -> Inner hash join (<hash>(teaching.semester)=<hash>(transcript.semester)), (<hash>(teaching.crsCode)=<hash>(transcript.crsCode))  (cost=1010.70 rows=100) (actual time=0.172..0.172 rows=0 loops=1)
                 -> Table scan on Teaching  (cost=0.01 rows=100) (actual time=0.004..0.049 rows=100 loops=1)
                 -> Hash
                     -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.018..0.067 rows=100 loops=1)
         -> Single-row index lookup on Student using PRIMARY (id=transcript.studId)  (cost=1.00 rows=1) (never executed)
     -> Filter: (professor.`name` = <cache>((@v5)))  (cost=0.01 rows=0) (never executed)
         -> Single-row index lookup on Professor using PRIMARY (id=teaching.profId)  (cost=0.01 rows=1) (never executed)
 
*/