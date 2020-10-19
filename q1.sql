use springboardopt;
SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';


-- 1. List the name of the student with id equal to v1 (id).
EXPLAIN ANALYZE
SELECT name FROM Student WHERE id = @v1;

/*
-> Filter: (student.id = <cache>((@v1)))  (cost=41.00 rows=40) (actual time=0.927..0.927 rows=0 loops=1)
     -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.048..0.225 rows=400 loops=1)
 
*/

/*
The query using full table scan that is slow. 
The reason is the original table doesn't have any index.
Solution: create primary index on uid
*/
ALTER TABLE Student ADD PRIMARY KEY (id);
EXPLAIN analyze
SELECT Student.name FROM Student WHERE id = @v1;
/*
-> Rows fetched before execution  (actual time=0.000..0.000 rows=1 loops=1)
*/

-- 2. List the names of students with id in the range of v2 (id) to v3 (inclusive).
EXPLAIN analyze
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;
DROP INDEX `PRIMARY` ON Student;

/*
-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=41.00 rows=44) (actual time=0.060..0.344 rows=278 loops=1)
     -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.030..0.289 rows=400 loops=1)
*/
/*
The query using full table scan for the range query that is slow.
Solution: create primary index on uid
*/
ALTER TABLE Student ADD PRIMARY KEY (id);
EXPLAIN analyze
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;
/*
-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=56.47 rows=278) (actual time=0.060..0.246 rows=278 loops=1)
     -> Index range scan on Student using PRIMARY  (cost=56.47 rows=278) (actual time=0.058..0.201 rows=278 loops=1)
*/
DROP INDEX `PRIMARY` ON Student;

-- 3. List the names of students who have taken course v4 (crsCode).
EXPLAIN ANALYZE
SELECT name FROM Student WHERE id IN (SELECT studId FROM Transcript WHERE crsCode = @v4);
/*
-> Inner hash join (student.id = `<subquery2>`.studId)  (actual time=0.171..0.331 rows=2 loops=1)
     -> Table scan on Student  (cost=5.04 rows=400) (actual time=0.007..0.175 rows=400 loops=1)
     -> Hash
         -> Table scan on <subquery2>  (actual time=0.000..0.001 rows=2 loops=1)
             -> Materialize with deduplication  (actual time=0.094..0.094 rows=2 loops=1)
                 -> Filter: (transcript.studId is not null)  (cost=10.25 rows=10) (actual time=0.050..0.087 rows=2 loops=1)
                     -> Filter: (transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.049..0.086 rows=2 loops=1)
                         -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.030..0.071 rows=100 loops=1)
 
*/
EXPLAIN ANALYZE
SELECT name
FROM Student INNER JOIN Transcript ON Student.id = Transcript.studId
WHERE Transcript.crsCode = @v4;
/*
-> Inner hash join (student.id = transcript.studId)  (cost=411.29 rows=400) (actual time=0.139..0.280 rows=2 loops=1)
     -> Table scan on Student  (cost=0.50 rows=400) (actual time=0.005..0.161 rows=400 loops=1)
     -> Hash
         -> Filter: (transcript.crsCode = <cache>((@v4)))  (cost=10.25 rows=10) (actual time=0.035..0.069 rows=2 loops=1)
             -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.018..0.055 rows=100 loops=1)
*/