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

-- 6. List the names of students who have taken all courses offered by department v8 (deptId).
EXPLAIN ANALYZE
SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		WHERE crsCode IN
		(SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))
		GROUP BY studId
		HAVING COUNT(*) = 
			(SELECT COUNT(*) FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))) as alias
WHERE id = alias.studId;
/*
-> Nested loop inner join  (actual time=4.541..4.541 rows=0 loops=1)
     -> Table scan on Student  (cost=41.00 rows=400) (actual time=0.019..0.184 rows=400 loops=1)
     -> Index lookup on alias using <auto_key0> (studId=student.id)  (actual time=0.000..0.000 rows=0 loops=400)
         -> Materialize  (actual time=0.011..0.011 rows=0 loops=400)
             -> Filter: (count(0) = (select #5))  (actual time=4.185..4.185 rows=0 loops=1)
                 -> Table scan on <temporary>  (actual time=0.001..0.002 rows=19 loops=1)
                     -> Aggregate using temporary table  (actual time=4.180..4.182 rows=19 loops=1)
                         -> Nested loop inner join  (actual time=0.163..0.324 rows=19 loops=1)
                             -> Filter: (transcript.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.004..0.083 rows=100 loops=1)
                                 -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.004..0.070 rows=100 loops=1)
                             -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=transcript.crsCode)  (actual time=0.000..0.001 rows=0 loops=100)
                                 -> Materialize with deduplication  (actual time=0.002..0.002 rows=0 loops=100)
                                     -> Filter: (course.crsCode is not null)  (cost=110.52 rows=100) (actual time=0.084..0.140 rows=19 loops=1)
                                         -> Filter: (teaching.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.084..0.138 rows=19 loops=1)
                                             -> Inner hash join (<hash>(teaching.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.083..0.134 rows=19 loops=1)
                                                 -> Table scan on Teaching  (cost=0.13 rows=100) (actual time=0.003..0.042 rows=100 loops=1)
                                                 -> Hash
                                                     -> Filter: (course.deptId = <cache>((@v8)))  (cost=10.25 rows=10) (actual time=0.009..0.056 rows=19 loops=1)
                                                         -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.003..0.042 rows=100 loops=1)
                 -> Select #5 (subquery in condition; uncacheable)
                     -> Aggregate: count(0)  (actual time=0.190..0.190 rows=1 loops=19)
                         -> Nested loop inner join  (actual time=0.098..0.188 rows=19 loops=19)
                             -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.004..0.074 rows=19 loops=19)
                                 -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.003..0.057 rows=100 loops=19)
                             -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode)  (actual time=0.001..0.001 rows=1 loops=361)
                                 -> Materialize with deduplication  (actual time=0.006..0.006 rows=1 loops=361)
                                     -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.001..0.049 rows=100 loops=19)
             -> Select #5 (subquery in projection; uncacheable)
                 -> Aggregate: count(0)  (actual time=0.190..0.190 rows=1 loops=19)
                     -> Nested loop inner join  (actual time=0.098..0.188 rows=19 loops=19)
                         -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.004..0.074 rows=19 loops=19)
                             -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.003..0.057 rows=100 loops=19)
                         -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode)  (actual time=0.001..0.001 rows=1 loops=361)
                             -> Materialize with deduplication  (actual time=0.006..0.006 rows=1 loops=361)
                                 -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.001..0.049 rows=100 loops=19)
 
*/
/*
In this query, adding Primary index in Student does not help much.
I'm searching for the reasons.
*/
ALTER TABLE Student ADD PRIMARY KEY (id);
EXPLAIN ANALYZE
SELECT name FROM Student,
	(SELECT studId
	FROM Transcript
		WHERE crsCode IN
		(SELECT crsCode FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))
		GROUP BY studId
		HAVING COUNT(*) = 
			(SELECT COUNT(*) FROM Course WHERE deptId = @v8 AND crsCode IN (SELECT crsCode FROM Teaching))) as alias
WHERE id = alias.studId;
/*
-> Nested loop inner join  (actual time=4.032..4.032 rows=0 loops=1)
     -> Table scan on alias  (actual time=0.001..0.001 rows=0 loops=1)
         -> Materialize  (actual time=4.031..4.031 rows=0 loops=1)
             -> Filter: (count(0) = (select #5))  (actual time=4.025..4.025 rows=0 loops=1)
                 -> Table scan on <temporary>  (actual time=0.001..0.002 rows=19 loops=1)
                     -> Aggregate using temporary table  (actual time=4.019..4.021 rows=19 loops=1)
                         -> Nested loop inner join  (actual time=0.169..0.327 rows=19 loops=1)
                             -> Filter: (transcript.crsCode is not null)  (cost=10.25 rows=100) (actual time=0.017..0.093 rows=100 loops=1)
                                 -> Table scan on Transcript  (cost=10.25 rows=100) (actual time=0.016..0.080 rows=100 loops=1)
                             -> Single-row index lookup on <subquery3> using <auto_distinct_key> (crsCode=transcript.crsCode)  (actual time=0.000..0.000 rows=0 loops=100)
                                 -> Materialize with deduplication  (actual time=0.002..0.002 rows=0 loops=100)
                                     -> Filter: (course.crsCode is not null)  (cost=110.52 rows=100) (actual time=0.082..0.135 rows=19 loops=1)
                                         -> Filter: (teaching.crsCode = course.crsCode)  (cost=110.52 rows=100) (actual time=0.082..0.133 rows=19 loops=1)
                                             -> Inner hash join (<hash>(teaching.crsCode)=<hash>(course.crsCode))  (cost=110.52 rows=100) (actual time=0.082..0.129 rows=19 loops=1)
                                                 -> Table scan on Teaching  (cost=0.13 rows=100) (actual time=0.003..0.039 rows=100 loops=1)
                                                 -> Hash
                                                     -> Filter: (course.deptId = <cache>((@v8)))  (cost=10.25 rows=10) (actual time=0.009..0.055 rows=19 loops=1)
                                                         -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.004..0.042 rows=100 loops=1)
                 -> Select #5 (subquery in condition; uncacheable)
                     -> Aggregate: count(0)  (actual time=0.181..0.182 rows=1 loops=19)
                         -> Nested loop inner join  (actual time=0.094..0.180 rows=19 loops=19)
                             -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.004..0.070 rows=19 loops=19)
                                 -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.003..0.055 rows=100 loops=19)
                             -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode)  (actual time=0.000..0.001 rows=1 loops=361)
                                 -> Materialize with deduplication  (actual time=0.005..0.005 rows=1 loops=361)
                                     -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.002..0.047 rows=100 loops=19)
             -> Select #5 (subquery in projection; uncacheable)
                 -> Aggregate: count(0)  (actual time=0.181..0.182 rows=1 loops=19)
                     -> Nested loop inner join  (actual time=0.094..0.180 rows=19 loops=19)
                         -> Filter: ((course.deptId = <cache>((@v8))) and (course.crsCode is not null))  (cost=10.25 rows=10) (actual time=0.004..0.070 rows=19 loops=19)
                             -> Table scan on Course  (cost=10.25 rows=100) (actual time=0.003..0.055 rows=100 loops=19)
                         -> Single-row index lookup on <subquery6> using <auto_distinct_key> (crsCode=course.crsCode)  (actual time=0.000..0.001 rows=1 loops=361)
                             -> Materialize with deduplication  (actual time=0.005..0.005 rows=1 loops=361)
                                 -> Table scan on Teaching  (cost=10.25 rows=100) (actual time=0.002..0.047 rows=100 loops=19)
     -> Single-row index lookup on Student using PRIMARY (id=alias.studId)  (cost=0.63 rows=1) (never executed)
 
*/