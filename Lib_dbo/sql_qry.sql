SELECT sequence_name
FROM all_sequences
WHERE sequence_owner = 'LIBRARY_ETL';


select * from authors;

delete from authors where author_id <= 100;