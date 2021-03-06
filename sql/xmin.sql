\set VERBOSITY terse

-- predictability
SET synchronous_commit = on;

SELECT 'init' FROM pg_create_logical_replication_slot('regression_slot', 'wal2json');

DROP TABLE IF EXISTS xmin ;

CREATE TABLE xmin (id integer PRIMARY KEY);
INSERT INTO xmin values (1);

-- xmin is often (always?) 0, but this should be forward compat should that change in the future
SELECT max(((data::json) -> 'xmin')::text::int) = (SELECT coalesce(xmin::text::int, 0) FROM pg_replication_slots WHERE slot_name = 'regression_slot') FROM pg_logical_slot_peek_changes('regression_slot', NULL, NULL, 'include-xmins', '1');
SELECT max(((data::json) -> 'catxmin')::text::int) = (SELECT catalog_xmin::text::int FROM pg_replication_slots WHERE slot_name = 'regression_slot') FROM pg_logical_slot_peek_changes('regression_slot', NULL, NULL, 'include-xmins', '1');

SELECT data FROM pg_logical_slot_peek_changes('regression_slot', NULL, NULL) where ((data::json) -> 'catxmin') IS NOT NULL;
SELECT data FROM pg_logical_slot_peek_changes('regression_slot', NULL, NULL) where ((data::json) -> 'xmin') IS NOT NULL;
SELECT 'stop' FROM pg_drop_replication_slot('regression_slot');
