/*
	Version: 1.1
*/


INSTALL SONAME 'ha_connect';


CREATE DATABASE IF NOT EXISTS `_`
	DEFAULT CHARACTER SET = 'utf8'
	DEFAULT COLLATE = 'utf8_general_ci';
USE `_`;


-- replace this with proper data
DROP SERVER IF EXISTS `_`;
CREATE SERVER `_`
	FOREIGN DATA WRAPPER MYSQL
	OPTIONS
	(
		  HOST '127.0.0.1'
		, USER 'root'
		, PASSWORD 'root'
		, PORT 3306
		, DATABASE '_'
	)
;


DROP PROCEDURE IF EXISTS `_`.`materialize_sql`;
DELIMITER ||
CREATE PROCEDURE `_`.`materialize_sql`(IN p_db_name VARCHAR(64), IN p_tab_name VARCHAR(64), IN p_sql TEXT)
        MODIFIES SQL DATA
BEGIN
	-- the warning must be raised later,
	-- because the diagnostics area is emptied during the routine
	DECLARE trx_warning BOOL DEFAULT @@in_transaction;
	
	DECLARE EXIT HANDLER
		FOR 1939
	BEGIN
		RESIGNAL SET
			  CLASS_ORIGIN = 'materialize'
			, MESSAGE_TEXT = 'CONNECT table could not be created; check your SQL'
			;
	END;
	
	IF @@in_transaction = 1 THEN
		SIGNAL SQLSTATE '01000' SET
			  CLASS_ORIGIN = 'materialize'
			, MESSAGE_TEXT = 'materialize_sql() will implicitly commit current transaction'
			;
	END IF;
	
	SET p_db_name := CONCAT('`', REPLACE(p_db_name, '`', '``'), '`');
	SET p_tab_name := CONCAT('`', REPLACE(p_tab_name, '`', '``'), '`');
        
        -- create table
        SET @__materialized_sql := CONCAT_WS('',
                  'CREATE OR REPLACE TABLE ', p_db_name, '.', p_tab_name
                , ' ENGINE = CONNECT'
                , ' TABLE_TYPE = MYSQL'
                , ' SRCDEF = ''', REPLACE(p_sql, '''', ''''''), ''''
                , ' CONNECTION = ''', IFNULL(@__connect_server, '_'), ''''
                );
        PREPARE __stmt_materialized_sql FROM @__materialized_sql;
        EXECUTE __stmt_materialized_sql;
	
	-- if @__autoselect is enabled, show results
	IF @__autoselect IS TRUE OR @__autodrop IS TRUE THEN
		SET @__materialized_sql := CONCAT_WS('', 'SELECT * FROM ', p_db_name, '.', p_tab_name);
		PREPARE __stmt_materialized_sql FROM @__materialized_sql;
		EXECUTE __stmt_materialized_sql;
	END IF;
	
	-- if @__autodrop is enabled, table is now dropped
	IF @__autodrop IS TRUE THEN
		SET @__materialized_sql := CONCAT_WS('', 'DROP TABLE ', p_db_name, '.', p_tab_name);
		PREPARE __stmt_materialized_sql FROM @__materialized_sql;
		EXECUTE __stmt_materialized_sql;
	END IF;
	
	SET @__materialized_sql := NULL;
	DEALLOCATE PREPARE __stmt_materialized_sql;
	
	IF trx_warning THEN
		SIGNAL SQLSTATE '01000' SET
			  CLASS_ORIGIN = 'materialize'
			, MESSAGE_TEXT = 'administrative_sql() has implicitly committed a transaction'
			;
	END IF;
END ||
DELIMITER ;


DROP PROCEDURE IF EXISTS `_`.`administrative_sql`;
DELIMITER ||
CREATE PROCEDURE `_`.`administrative_sql`(IN p_sql TEXT)
	MODIFIES SQL DATA
BEGIN
	DECLARE trx_warning BOOL DEFAULT @@in_transaction;
	
	-- contains resultsets for OPTIMIZE, ANALYZE, CHECK, REPAIR
	CREATE OR REPLACE TABLE `_`.`administrative_sql`
	(
		  `Table` VARCHAR(64) NOT NULL
		, `Op` VARCHAR(255) NOT NULL
		, `Msg_type` VARCHAR(255) NOT NULL
		, `Msg_text` VARCHAR(255) NOT NULL
	)
		ENGINE = CONNECT
		TABLE_TYPE = MYSQL
		SRCDEF = 'CHECK TABLE t'
		CONNECTION = '_'
	;
	
	SET @v_administrative_sql := CONCAT_WS('', 'ALTER TABLE _.administrative_sql SRCDEF = \'', p_sql, '\'');
	PREPARE stmt_administrative_sql FROM @v_administrative_sql;
	EXECUTE stmt_administrative_sql;
	DEALLOCATE PREPARE stmt_administrative_sql;
	SET @v_administrative_sql := NULL;
	SELECT * FROM _.administrative_sql;
	
	IF trx_warning THEN
		SIGNAL SQLSTATE '01000' SET
			  CLASS_ORIGIN = 'materialize'
			, MESSAGE_TEXT = 'administrative_sql() has implicitly committed a transaction'
			;
	END IF;
END ||
DELIMITER ;


CREATE OR REPLACE TABLE `_`.`show_authors`
	CHARACTER SET latin1
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW AUTHORS'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_binary_logs`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW BINARY LOGS'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_binlog_events`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW BINLOG EVENTS'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_engine_innodb_status`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW ENGINE InnoDB STATUS'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_engine_innodb_mutex`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW ENGINE InnoDB MUTEX'
	CONNECTION = '_'
;


-- SHOW EVENTS, without IN clause, shows events in current db.
-- Since we can't pass parameters, implementing the table makes no sense.


-- Deprecated synonym of SHOW ENGINE InnoDB STATUS
CREATE OR REPLACE VIEW `_`.`show_innodb_status` AS
	SELECT * FROM `_`.`show_engine_innodb_status`;


CREATE OR REPLACE TABLE `_`.`show_engine_performance_schema_status`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW ENGINE PERFORMANCE_SCHEMA STATUS'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_contributors`
	CHARACTER SET latin1
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW CONTRIBUTORS'
	CONNECTION = '_'
;


DROP TABLE IF EXISTS `_`.`show_errors`;


CREATE OR REPLACE VIEW `_`.`show_master_logs` AS
	SELECT * FROM `_`.`show_binary_logs`;


CREATE OR REPLACE TABLE `_`.`show_master_status`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW MASTER STATUS'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_open_tables`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW OPEN TABLES'
	CONNECTION = '_'
;


CREATE OR REPLACE TABLE `_`.`show_privileges`
	ENGINE = CONNECT
	TABLE_TYPE = MYSQL
	SRCDEF = 'SHOW PRIVILEGES'
	CONNECTION = '_'
;


-- SHOW PROFILE and SHOW PROFILES only work within the session.


DROP TABLE IF EXISTS `_`.`show_warnings`;

