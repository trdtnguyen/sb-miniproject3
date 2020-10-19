use springboardopt;
SET @v1 = 1612521;
SET @v2 = 1145072;
SET @v3 = 1828467;
SET @v4 = 'MGT382';
SET @v5 = 'Amber Hill';
SET @v6 = 'MGT';
SET @v7 = 'EE';			  
SET @v8 = 'MAT';

/*
The query using full table scan for the range query that is slow.
Solution: create primary index on uid
*/

-- 2. List the names of students with id in the range of v2 (id) to v3 (inclusive).
EXPLAIN analyze
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;
DROP INDEX `PRIMARY` ON Student;

/*
-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=41.00 rows=44) (actual time=0.060..0.344 rows=278 loops=1)
     -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.030..0.289 rows=400 loops=1)
*/

ALTER TABLE Student ADD PRIMARY KEY (id);
EXPLAIN analyze
SELECT name FROM Student WHERE id BETWEEN @v2 AND @v3;
/*
-> Filter: (student.id between <cache>((@v2)) and <cache>((@v3)))  (cost=56.47 rows=278) (actual time=0.060..0.246 rows=278 loops=1)
     -> Index range scan on Student using PRIMARY  (cost=56.47 rows=278) (actual time=0.058..0.201 rows=278 loops=1)
*/