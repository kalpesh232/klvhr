
-- ########## Start of access.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/access.sql
-- Author       : Tim Hall
-- Description  : Lists all objects being accessed in the schema.
-- Call Syntax  : @access (schema-name or all) (object-name or all)
-- Requirements : Access to the v$views.
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 255
SET VERIFY OFF

COLUMN object FORMAT A30

SELECT a.object,
       a.type,
       a.sid,
       b.serial#,
       b.username,
       b.osuser,
       b.program
FROM   v$access a,
       v$session b
WHERE  a.sid    = b.sid
AND    a.owner  = DECODE(UPPER('&1'), 'ALL', a.object, UPPER('&1'))
AND    a.object = DECODE(UPPER('&2'), 'ALL', a.object, UPPER('&2'))
ORDER BY a.object;

-- End of access.sql --

-- ########## Start of active_sessions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/active_sessions.sql
-- Author       : Tim Hall
-- Description  : Displays information on all active database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @active_sessions
-- Last Modified: 16-MAY-2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
FROM   v$session s,
       v$process p
WHERE  s.paddr  = p.addr
AND    s.status = 'ACTIVE'
ORDER BY s.username, s.osuser;

SET PAGESIZE 14


-- End of active_sessions.sql --

-- ########## Start of active_user_sessions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/active_user_sessions.sql
-- Author       : Tim Hall
-- Description  : Displays information on all active database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @active_user_sessions
-- Last Modified: 16-MAY-2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
FROM   v$session s,
       v$process p
WHERE  s.paddr  = p.addr
AND    s.status = 'ACTIVE'
AND    s.username IS NOT NULL
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of active_user_sessions.sql --

-- ########## Start of cache_hit_ratio.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/cache_hit_ratio.sql
-- Author       : Tim Hall
-- Description  : Displays cache hit ratio for the database.
-- Comments     : The minimum figure of 89% is often quoted, but depending on the type of system this may not be possible.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @cache_hit_ratio
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
PROMPT
PROMPT Hit ratio should exceed 89%

SELECT Sum(Decode(a.name, 'consistent gets', a.value, 0)) "Consistent Gets",
       Sum(Decode(a.name, 'db block gets', a.value, 0)) "DB Block Gets",
       Sum(Decode(a.name, 'physical reads', a.value, 0)) "Physical Reads",
       Round(((Sum(Decode(a.name, 'consistent gets', a.value, 0)) +
         Sum(Decode(a.name, 'db block gets', a.value, 0)) -
         Sum(Decode(a.name, 'physical reads', a.value, 0))  )/
           (Sum(Decode(a.name, 'consistent gets', a.value, 0)) +
             Sum(Decode(a.name, 'db block gets', a.value, 0))))
             *100,2) "Hit Ratio %"
FROM   v$sysstat a;

-- End of cache_hit_ratio.sql --

-- ########## Start of call_stack.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/call_stack.sql
-- Author       : Tim Hall
-- Description  : Displays the current call stack.
-- Requirements : Access to DBMS_UTILITY.
-- Call Syntax  : @call_stack
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
DECLARE
  v_stack  VARCHAR2(2000);
BEGIN
  v_stack := Dbms_Utility.Format_Call_Stack;
  Dbms_Output.Put_Line(v_stack);
END;
/

-- End of call_stack.sql --

-- ########## Start of code_dep.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/code_dep.sql
-- Author       : Tim Hall
-- Description  : Displays all dependencies of specified object.
-- Call Syntax  : @code_dep (schema-name or all) (object-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 255
SET PAGESIZE 1000
BREAK ON referenced_type SKIP 1

COLUMN referenced_type FORMAT A20
COLUMN referenced_owner FORMAT A20
COLUMN referenced_name FORMAT A40
COLUMN referenced_link_name FORMAT A20

SELECT a.referenced_type,
       a.referenced_owner,
       a.referenced_name,
       a.referenced_link_name
FROM   all_dependencies a
WHERE  a.owner = DECODE(UPPER('&1'), 'ALL', a.referenced_owner, UPPER('&1'))
AND    a.name  = UPPER('&2')
ORDER BY 1,2,3;

SET VERIFY ON
SET PAGESIZE 22
-- End of code_dep.sql --

-- ########## Start of code_dep_distinct.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/code_dep_distinct.sql
-- Author       : Tim Hall
-- Description  : Displays a tree of dependencies of specified object.
-- Call Syntax  : @code_dep_distinct (schema-name) (object-name) (object_type or all)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 255
SET PAGESIZE 1000

COLUMN referenced_object FORMAT A50
COLUMN referenced_type FORMAT A20
COLUMN referenced_link_name FORMAT A20

SELECT DISTINCT a.referenced_owner || '.' || a.referenced_name AS referenced_object,
       a.referenced_type,
       a.referenced_link_name
FROM   all_dependencies a
WHERE  a.owner NOT IN ('SYS','SYSTEM','PUBLIC')
AND    a.referenced_owner NOT IN ('SYS','SYSTEM','PUBLIC')
AND    a.referenced_type != 'NON-EXISTENT'
AND    a.referenced_type = DECODE(UPPER('&3'), 'ALL', a.referenced_type, UPPER('&3'))
START WITH a.owner = UPPER('&1')
AND        a.name  = UPPER('&2')
CONNECT BY a.owner = PRIOR a.referenced_owner
AND        a.name  = PRIOR a.referenced_name
AND        a.type  = PRIOR a.referenced_type;

SET VERIFY ON
SET PAGESIZE 22
-- End of code_dep_distinct.sql --

-- ########## Start of code_dep_on.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/code_dep_on.sql
-- Author       : Tim Hall
-- Description  : Displays all objects dependant on the specified object.
-- Call Syntax  : @code_dep_on (schema-name or all) (object-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 255
SET PAGESIZE 1000
BREAK ON type SKIP 1

COLUMN owner FORMAT A20

SELECT a.type,
       a.owner,
       a.name
FROM   all_dependencies a
WHERE  a.referenced_owner = DECODE(UPPER('&1'), 'ALL', a.referenced_owner, UPPER('&1'))
AND    a.referenced_name  = UPPER('&2')
ORDER BY 1,2,3;

SET PAGESIZE 22
SET VERIFY ON
-- End of code_dep_on.sql --

-- ########## Start of code_dep_tree.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/code_dep_tree.sql
-- Author       : Tim Hall
-- Description  : Displays a tree of dependencies of specified object.
-- Call Syntax  : @code_dep_tree (schema-name) (object-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 255
SET PAGESIZE 1000

COLUMN referenced_object FORMAT A50
COLUMN referenced_type FORMAT A20
COLUMN referenced_link_name FORMAT A20

SELECT RPAD(' ', level*2, ' ') || a.referenced_owner || '.' || a.referenced_name AS referenced_object,
       a.referenced_type,
       a.referenced_link_name
FROM   all_dependencies a
WHERE  a.owner NOT IN ('SYS','SYSTEM','PUBLIC')
AND    a.referenced_owner NOT IN ('SYS','SYSTEM','PUBLIC')
AND    a.referenced_type != 'NON-EXISTENT'
START WITH a.owner = UPPER('&1')
AND        a.name  = UPPER('&2')
CONNECT BY a.owner = PRIOR a.referenced_owner
AND        a.name  = PRIOR a.referenced_name
AND        a.type  = PRIOR a.referenced_type;

SET VERIFY ON
SET PAGESIZE 22
-- End of code_dep_tree.sql --

-- ########## Start of column_defaults.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/column_defaults.sql
-- Author       : Tim Hall
-- Description  : Displays the default values where present for the specified table.
-- Call Syntax  : @column_defaults (table-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 100
SET VERIFY OFF

SELECT a.column_name "Column",
       a.data_default "Default"
FROM   all_tab_columns a
WHERE  a.table_name = Upper('&1')
AND    a.data_default IS NOT NULL
/
-- End of column_defaults.sql --

-- ########## Start of controlfiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/controlfiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about controlfiles.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @controlfiles
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------

SET LINESIZE 100
COLUMN name FORMAT A80

SELECT name,
       status
FROM   v$controlfile
ORDER BY name;

SET LINESIZE 80
-- End of controlfiles.sql --

-- ########## Start of datafiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/datafiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about datafiles.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @datafiles
-- Last Modified: 17-AUG-2005
-- -----------------------------------------------------------------------------------

SET LINESIZE 200
COLUMN file_name FORMAT A70

SELECT file_id,
       file_name,
       ROUND(bytes/1024/1024/1024) AS size_gb,
       ROUND(maxbytes/1024/1024/1024) AS max_size_gb,
       autoextensible,
       increment_by,
       status
FROM   dba_data_files
ORDER BY file_name;

-- End of datafiles.sql --

-- ########## Start of db_cache_advice.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/db_cache_advice.sql
-- Author       : Tim Hall
-- Description  : Predicts how changes to the buffer cache will affect physical reads.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @db_cache_advice
-- Last Modified: 12/02/2004
-- -----------------------------------------------------------------------------------

COLUMN size_for_estimate          FORMAT 999,999,999,999 heading 'Cache Size (MB)'
COLUMN buffers_for_estimate       FORMAT 999,999,999 heading 'Buffers'
COLUMN estd_physical_read_factor  FORMAT 999.90 heading 'Estd Phys|Read Factor'
COLUMN estd_physical_reads        FORMAT 999,999,999,999 heading 'Estd Phys| Reads'

SELECT size_for_estimate, 
       buffers_for_estimate,
       estd_physical_read_factor,
       estd_physical_reads
FROM   v$db_cache_advice
WHERE  name          = 'DEFAULT'
AND    block_size    = (SELECT value
                        FROM   v$parameter
                        WHERE  name = 'db_block_size')
AND    advice_status = 'ON';

-- End of db_cache_advice.sql --

-- ########## Start of db_info.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/db_info.sql
-- Author       : Tim Hall
-- Description  : Displays general information about the database.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @db_info
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET PAGESIZE 1000
SET LINESIZE 100
SET FEEDBACK OFF

SELECT *
FROM   v$database;

SELECT *
FROM   v$instance;

SELECT *
FROM   v$version;

SELECT a.name,
       a.value
FROM   v$sga a;

SELECT Substr(c.name,1,60) "Controlfile",
       NVL(c.status,'UNKNOWN') "Status"
FROM   v$controlfile c
ORDER BY 1;

SELECT Substr(d.name,1,60) "Datafile",
       NVL(d.status,'UNKNOWN') "Status",
       d.enabled "Enabled",
       LPad(To_Char(Round(d.bytes/1024000,2),'9999990.00'),10,' ') "Size (M)"
FROM   v$datafile d
ORDER BY 1;

SELECT l.group# "Group",
       Substr(l.member,1,60) "Logfile",
       NVL(l.status,'UNKNOWN') "Status"
FROM   v$logfile l
ORDER BY 1,2;

PROMPT
SET PAGESIZE 14
SET FEEDBACK ON



-- End of db_info.sql --

-- ########## Start of db_links.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/db_links.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database links.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @db_links
-- Last Modified: 11/05/2007
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN owner FORMAT A30
COLUMN db_link FORMAT A30
COLUMN username FORMAT A30
COLUMN host FORMAT A30

SELECT owner,
       db_link,
       username,
       host
FROM   dba_db_links
ORDER BY owner, db_link;

-- End of db_links.sql --

-- ########## Start of db_links_open.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/db_links_open.sql
-- Author       : Tim Hall
-- Description  : Displays information on all open database links.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @db_links_open
-- Last Modified: 11/05/2007
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN db_link FORMAT A30

SELECT db_link,
       owner_id,
       logged_on,
       heterogeneous,
       protocol,
       open_cursors,
       in_transaction,
       update_sent,
       commit_point_strength
FROM   v$dblink
ORDER BY db_link;

SET LINESIZE 80

-- End of db_links_open.sql --

-- ########## Start of db_properties.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/db_properties.sql
-- Author       : Tim Hall
-- Description  : Displays all database property values.
-- Call Syntax  : @db_properties
-- Last Modified: 15/09/2006
-- -----------------------------------------------------------------------------------
COLUMN property_value FORMAT A50

SELECT property_name,
       property_value
FROM   database_properties
ORDER BY property_name;

-- End of db_properties.sql --

-- ########## Start of default_tablespaces.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/default_tablespaces.sql
-- Author       : Tim Hall
-- Description  : Displays the default temporary and permanent tablespaces.
-- Requirements : Access to the DATABASE_PROPERTIES views.
-- Call Syntax  : @default_tablespaces
-- Last Modified: 04/06/2019
-- -----------------------------------------------------------------------------------
COLUMN property_name FORMAT A30
COLUMN property_value FORMAT A30
COLUMN description FORMAT A50
SET LINESIZE 200

SELECT *
FROM   database_properties
WHERE  property_name like '%TABLESPACE';

-- End of default_tablespaces.sql --

-- ########## Start of df_free_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/df_free_space.sql
-- Author       : Tim Hall
-- Description  : Displays free space information about datafiles.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @df_free_space.sql
-- Last Modified: 17-AUG-2005
-- -----------------------------------------------------------------------------------

SET LINESIZE 120
COLUMN file_name FORMAT A60

SELECT a.file_name,
       ROUND(a.bytes/1024/1024) AS size_mb,
       ROUND(a.maxbytes/1024/1024) AS maxsize_mb,
       ROUND(b.free_bytes/1024/1024) AS free_mb,
       ROUND((a.maxbytes-a.bytes)/1024/1024) AS growth_mb,
       100 - ROUND(((b.free_bytes+a.growth)/a.maxbytes) * 100) AS pct_used
FROM   (SELECT file_name,
               file_id,
               bytes,
               GREATEST(bytes,maxbytes) AS maxbytes,
               GREATEST(bytes,maxbytes)-bytes AS growth
        FROM   dba_data_files) a,
       (SELeCT file_id,
               SUM(bytes) AS free_bytes
        FROM   dba_free_space
        GROUP BY file_id) b
WHERE  a.file_id = b.file_id
ORDER BY file_name;

-- End of df_free_space.sql --

-- ########## Start of directories.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/directories.sql
-- Author       : Tim Hall
-- Description  : Displays information about all directories.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @directories
-- Last Modified: 04/10/2006
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN owner FORMAT A20
COLUMN directory_name FORMAT A25
COLUMN directory_path FORMAT A80

SELECT *
FROM   dba_directories
ORDER BY owner, directory_name;

-- End of directories.sql --

-- ########## Start of directory_permissions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/directory_permissions.sql
-- Author       : Tim Hall
-- Description  : Displays permission information about all directories.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @directory_permissions (directory_name)
-- Last Modified: 09/02/2016
-- -----------------------------------------------------------------------------------
set linesize 200

column grantee   format a20
column owner     format a10
column grantor   format a20
column privilege format a20

column 
select * 
from   dba_tab_privs 
where  table_name = upper('&1');

-- End of directory_permissions.sql --

-- ########## Start of directory_permissions_all.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/directory_permissions_all.sql
-- Author       : Tim Hall
-- Description  : Displays permissions on all directories.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @directory_permissions_all
-- Last Modified: 27/03/2024
-- -----------------------------------------------------------------------------------
column directory_name format a30
column grantee format a30
column privileges format a20

select table_name as directory_name,
       grantee,
       listagg(privilege,',') as privileges
from   dba_tab_privs 
where  table_name in (select directory_name from dba_directories)
group by table_name, grantee
order by 1, 2;

-- End of directory_permissions_all.sql --

-- ########## Start of dispatchers.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/dispatchers.sql
-- Author       : Tim Hall
-- Description  : Displays dispatcher statistics.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @dispatchers
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT a.name "Name",
       a.status "Status",
       a.accept "Accept",
       a.messages "Total Mesgs",
       a.bytes "Total Bytes",
       a.owned "Circs Owned",
       a.idle "Total Idle Time",
       a.busy "Total Busy Time",
       Round(a.busy/(a.busy + a.idle),2) "Load"
FROM   v$dispatcher a
ORDER BY 1;

SET PAGESIZE 14
SET VERIFY ON
-- End of dispatchers.sql --

-- ########## Start of error_stack.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/error_stack.sql
-- Author       : Tim Hall
-- Description  : Displays contents of the error stack.
-- Call Syntax  : @error_stack
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
DECLARE
  v_stack  VARCHAR2(2000);
BEGIN
  v_stack := Dbms_Utility.Format_Error_Stack;
  Dbms_Output.Put_Line(v_stack);
END;
/

-- End of error_stack.sql --

-- ########## Start of errors.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/errors.sql
-- Author       : Tim Hall
-- Description  : Displays the source line and the associated error after compilation failure.
-- Comments     : Essentially the same as SHOW ERRORS.
-- Call Syntax  : @errors (source-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SELECT To_Char(a.line) || ' - ' || a.text error
FROM   user_source a,
       user_errors b
WHERE  a.name = Upper('&&1')
AND    a.name = b.name
AND    a.type = b.type
AND    a.line = b.line
ORDER BY a.name, a.line;
-- End of errors.sql --

-- ########## Start of explain.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/explain.sql
-- Author       : Tim Hall
-- Description  : Displays a tree-style execution plan of the specified statement after it has been explained.
-- Requirements : Access to the plan table.
-- Call Syntax  : @explain (statement-id)
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET PAGESIZE 100
SET LINESIZE 200
SET VERIFY OFF

COLUMN plan             FORMAT A50
COLUMN object_name      FORMAT A30
COLUMN object_type      FORMAT A15
COLUMN bytes            FORMAT 9999999999
COLUMN cost             FORMAT 9999999
COLUMN partition_start  FORMAT A20
COLUMN partition_stop   FORMAT A20

SELECT LPAD(' ', 2 * (level - 1)) ||
       DECODE (level,1,NULL,level-1 || '.' || pt.position || ' ') ||
       INITCAP(pt.operation) ||
       DECODE(pt.options,NULL,'',' (' || INITCAP(pt.options) || ')') plan,
       pt.object_name,
       pt.object_type,
       pt.bytes,
       pt.cost,
       pt.partition_start,
       pt.partition_stop
FROM   plan_table pt
START WITH pt.id = 0
  AND pt.statement_id = '&1'
CONNECT BY PRIOR pt.id = pt.parent_id
  AND pt.statement_id = '&1';

-- End of explain.sql --

-- ########## Start of file_io.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/file_io.sql
-- Author       : Tim Hall
-- Description  : Displays the amount of IO for each datafile.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @file_io
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET PAGESIZE 1000

SELECT Substr(d.name,1,50) "File Name",
       f.phyblkrd "Blocks Read",
       f.phyblkwrt "Blocks Writen",
       f.phyblkrd + f.phyblkwrt "Total I/O"
FROM   v$filestat f,
       v$datafile d
WHERE  d.file# = f.file#
ORDER BY f.phyblkrd + f.phyblkwrt DESC;

SET PAGESIZE 18
-- End of file_io.sql --

-- ########## Start of find_packaged_proc.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/find_packaged_proc.sql
-- Author       : Tim Hall
-- Description  : Displays tablespaces the user has quotas on.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @find_packaged_proc {procedure_name}
-- Last Modified: 16-JAN-2024
-- -----------------------------------------------------------------------------------

set verify off
column owner format a30
column object_name format a30
column procedure_name format a30

select owner, object_name, procedure_name
from   dba_procedures
where  object_type = 'PACKAGE'
and    procedure_name like '%' || upper('&1') || '%';

-- End of find_packaged_proc.sql --

-- ########## Start of fk_columns.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/fk_columns.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays information on all FKs for the specified schema and table.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @fk_columns (schema-name or all) (table-name or all)
-- Last Modified: 22/09/2005
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 1000
COLUMN column_name FORMAT A30
COLUMN r_column_name FORMAT A30

SELECT c.constraint_name,
       cc.table_name,
       cc.column_name,
       rcc.table_name AS r_table_name,
       rcc.column_name AS r_column_name,
       cc.position
FROM   dba_constraints c
       JOIN dba_cons_columns cc ON c.owner = cc.owner AND c.constraint_name = cc.constraint_name
       JOIN dba_cons_columns rcc ON c.owner = rcc.owner AND c.r_constraint_name = rcc.constraint_name AND cc.position = rcc.position
WHERE  c.owner      = DECODE(UPPER('&1'), 'ALL', c.owner, UPPER('&1'))
AND    c.table_name = DECODE(UPPER('&2'), 'ALL', c.table_name, UPPER('&2'))
ORDER BY c.constraint_name, cc.table_name, cc.position;

-- End of fk_columns.sql --

-- ########## Start of fks.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/fks.sql
-- Author       : Tim Hall
-- Description  : Displays the constraints on a specific table and those referencing it.
-- Call Syntax  : @fks (table-name) (schema)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
PROMPT
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 255
SET PAGESIZE 1000

PROMPT
PROMPT Constraints Owned By Table
PROMPT ==========================
SELECT c.constraint_name "Constraint",
       Decode(c.constraint_type,'P','Primary Key',
                                'U','Unique Key',
                                'C','Check',
                                'R','Foreign Key',
                                c.constraint_type) "Type",
       c.r_owner "Ref Table",
       c.r_constraint_name "Ref Constraint"
FROM   all_constraints c
WHERE  c.table_name = Upper('&&1')
AND    c.owner      = Upper('&&2');


PROMPT
PROMPT Constraints Referencing Table
PROMPT =============================
SELECT c1.table_name "Table",
       c1.constraint_name "Foreign Key",
       c1.r_constraint_name "References"
FROM   all_constraints c1 
WHERE  c1.owner      = Upper('&&2')
AND    c1.r_constraint_name IN (SELECT c2.constraint_name
                                FROM   all_constraints c2
                                WHERE  c2.table_name = Upper('&&1')
                                AND    c2.owner      = Upper('&&2')
                                AND    c2.constraint_type IN ('P','U'));

SET VERIFY ON
SET FEEDBACK ON
SET PAGESIZE 1000
PROMPT

-- End of fks.sql --

-- ########## Start of free_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/free_space.sql
-- Author       : Tim Hall
-- Description  : Displays space usage for each datafile.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @free_space
-- Last Modified: 15-JUL-2000 - Created.
--                12-OCT-2012 - Amended to include auto-extend and maxsize.
-- -----------------------------------------------------------------------------------
SET PAGESIZE 100
SET LINESIZE 265

COLUMN tablespace_name FORMAT A20
COLUMN file_name FORMAT A50

SELECT df.tablespace_name,
       df.file_name,
       df.size_mb,
       f.free_mb,
       df.max_size_mb,
       f.free_mb + (df.max_size_mb - df.size_mb) AS max_free_mb,
       RPAD(' '|| RPAD('X',ROUND((df.max_size_mb-(f.free_mb + (df.max_size_mb - df.size_mb)))/max_size_mb*10,0), 'X'),11,'-') AS used_pct
FROM   (SELECT file_id,
               file_name,
               tablespace_name,
               TRUNC(bytes/1024/1024) AS size_mb,
               TRUNC(GREATEST(bytes,maxbytes)/1024/1024) AS max_size_mb
        FROM   dba_data_files) df,
       (SELECT TRUNC(SUM(bytes)/1024/1024) AS free_mb,
               file_id
        FROM dba_free_space
        GROUP BY file_id) f
WHERE  df.file_id = f.file_id (+)
ORDER BY df.tablespace_name,
         df.file_name;

PROMPT
SET PAGESIZE 14
-- End of free_space.sql --

-- ########## Start of health.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/health.sql
-- Author       : Tim Hall
-- Description  : Lots of information about the database so you can asses the general health of the system.
-- Requirements : Access to the V$ & DBA views and several other monitoring scripts.
-- Call Syntax  : @health (username/password@service)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SPOOL Health_Checks.txt

conn &1
@db_info
@sessions
@ts_full
@max_extents

SPOOL OFF
-- End of health.sql --

-- ########## Start of hidden_parameters.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/hidden_parameters.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays a list of one or all the hidden parameters.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @hidden_parameters (parameter-name or all)
-- Last Modified: 28-NOV-2006
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
COLUMN parameter      FORMAT a37
COLUMN description    FORMAT a30 WORD_WRAPPED
COLUMN session_value  FORMAT a10
COLUMN instance_value FORMAT a10
 
SELECT a.ksppinm AS parameter,
       a.ksppdesc AS description,
       b.ksppstvl AS session_value,
       c.ksppstvl AS instance_value
FROM   x$ksppi a,
       x$ksppcv b,
       x$ksppsv c
WHERE  a.indx = b.indx
AND    a.indx = c.indx
AND    a.ksppinm LIKE '/_%' ESCAPE '/'
AND    a.ksppinm = DECODE(LOWER('&1'), 'all', a.ksppinm, LOWER('&1'))
ORDER BY a.ksppinm;

-- End of hidden_parameters.sql --

-- ########## Start of high_water_mark.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/high_water_mark.sql
-- Author       : Tim Hall
-- Description  : Displays the High Water Mark for the specified table, or all tables.
-- Requirements : Access to the Dbms_Space.
-- Call Syntax  : @high_water_mark (table_name or all) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET VERIFY OFF

DECLARE
  CURSOR cu_tables IS
    SELECT a.owner,
           a.table_name
    FROM   all_tables a
    WHERE  a.table_name = Decode(Upper('&&1'),'ALL',a.table_name,Upper('&&1'))
    AND    a.owner      = Upper('&&2');

  op1  NUMBER;
  op2  NUMBER;
  op3  NUMBER;
  op4  NUMBER;
  op5  NUMBER;
  op6  NUMBER;
  op7  NUMBER;
BEGIN

  Dbms_Output.Disable;
  Dbms_Output.Enable(1000000);
  Dbms_Output.Put_Line('TABLE                             UNUSED BLOCKS     TOTAL BLOCKS  HIGH WATER MARK');
  Dbms_Output.Put_Line('------------------------------  ---------------  ---------------  ---------------');
  FOR cur_rec IN cu_tables LOOP
    Dbms_Space.Unused_Space(cur_rec.owner,cur_rec.table_name,'TABLE',op1,op2,op3,op4,op5,op6,op7);
    Dbms_Output.Put_Line(RPad(cur_rec.table_name,30,' ') ||
                         LPad(op3,15,' ')                ||
                         LPad(op1,15,' ')                ||
                         LPad(Trunc(op1-op3-1),15,' ')); 
  END LOOP;

END;
/

SET VERIFY ON
-- End of high_water_mark.sql --

-- ########## Start of hot_blocks.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/hot_blocks.sql
-- Author       : Tim Hall
-- Description  : Detects hot blocks.
-- Call Syntax  : @hot_blocks
-- Last Modified: 17/02/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET VERIFY OFF

SELECT *
FROM   (SELECT name,
               addr,
               gets,
               misses,
               sleeps
        FROM   v$latch_children
        WHERE  name = 'cache buffers chains'
        AND    misses > 0
        ORDER BY misses DESC)
WHERE  rownum < 11;

ACCEPT address PROMPT "Enter ADDR: "

COLUMN owner FORMAT A15
COLUMN object_name FORMAT A30
COLUMN subobject_name FORMAT A20

SELECT *
FROM   (SELECT o.owner,
               o.object_name,
               o.subobject_name,
               bh.tch,
               bh.obj,
               bh.file#,
               bh.dbablk,
               bh.class,
               bh.state
        FROM   x$bh bh,
               dba_objects o
        WHERE  o.data_object_id = bh.obj
        AND    hladdr = '&address'
        ORDER BY tch DESC)
WHERE  rownum < 11;

-- End of hot_blocks.sql --

-- ########## Start of identify_trace_file.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/identify_trace_file.sql
-- Author       : Tim Hall
-- Description  : Displays the name of the trace file associated with the current session.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @identify_trace_file
-- Last Modified: 17-AUG-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 100
COLUMN trace_file FORMAT A60

SELECT s.sid,
       s.serial#,
       pa.value || '/' || LOWER(SYS_CONTEXT('userenv','instance_name')) ||    
       '_ora_' || p.spid || '.trc' AS trace_file
FROM   v$session s,
       v$process p,
       v$parameter pa
WHERE  pa.name = 'user_dump_dest'
AND    s.paddr = p.addr
AND    s.audsid = SYS_CONTEXT('USERENV', 'SESSIONID');
-- End of identify_trace_file.sql --

-- ########## Start of index_extents.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/index_extents.sql
-- Author       : Tim Hall
-- Description  : Displays number of extents for all indexes belonging to the specified table, or all tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @index_extents (table_name or all) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT i.index_name,
       Count(e.segment_name) extents,
       i.max_extents,
       t.num_rows "ROWS",
       Trunc(i.initial_extent/1024) "INITIAL K",
       Trunc(i.next_extent/1024) "NEXT K",
       t.table_name
FROM   all_tables t,
       all_indexes i,
       dba_extents e
WHERE  i.table_name   = t.table_name
AND    i.owner        = t.owner
AND    e.segment_name = i.index_name
AND    e.owner        = i.owner
AND    i.table_name   = Decode(Upper('&&1'),'ALL',i.table_name,Upper('&&1'))
AND    i.owner        = Upper('&&2')
GROUP BY t.table_name,
         i.index_name,
         i.max_extents,
         t.num_rows,
         i.initial_extent,
         i.next_extent
HAVING   Count(e.segment_name) > 5
ORDER BY Count(e.segment_name) DESC;

SET PAGESIZE 18
SET VERIFY ON
-- End of index_extents.sql --

-- ########## Start of index_monitoring_status.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/index_monitoring_status.sql
-- Author       : Tim Hall
-- Description  : Shows the monitoring status for the specified table indexes.
-- Call Syntax  : @index_monitoring_status (table-name) (index-name or all)
-- Last Modified: 04/02/2005
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

SELECT table_name,
       index_name,
       monitoring
FROM   v$object_usage
WHERE  table_name = UPPER('&1')
AND    index_name = DECODE(UPPER('&2'), 'ALL', index_name, UPPER('&2'));

-- End of index_monitoring_status.sql --

-- ########## Start of index_partitions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/index_partitions.sql
-- Author       : Tim Hall
-- Description  : Displays partition information for the specified index, or all indexes.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @index_patitions (index_name or all) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET FEEDBACK OFF
SET VERIFY OFF

SELECT a.index_name,
       a.partition_name,
       a.tablespace_name,
       a.initial_extent,
       a.next_extent,
       a.pct_increase,
       a.num_rows
FROM   dba_ind_partitions a
WHERE  a.index_name  = Decode(Upper('&&1'),'ALL',a.index_name,Upper('&&1'))
AND    a.index_owner = Upper('&&2')
ORDER BY a.index_name, a.partition_name
/

PROMPT
SET PAGESIZE 14
SET FEEDBACK ON

-- End of index_partitions.sql --

-- ########## Start of index_usage.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/index_usage.sql
-- Author       : Tim Hall
-- Description  : Shows the usage for the specified table indexes.
-- Call Syntax  : @index_usage (table-name) (index-name or all)
-- Last Modified: 04/02/2005
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 200

SELECT table_name,
       index_name,
       used,
       start_monitoring,
       end_monitoring
FROM   v$object_usage
WHERE  table_name = UPPER('&1')
AND    index_name = DECODE(UPPER('&2'), 'ALL', index_name, UPPER('&2'));

-- End of index_usage.sql --

-- ########## Start of invalid_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/invalid_objects.sql
-- Author       : Tim Hall
-- Description  : Lists all invalid objects in the database.
-- Call Syntax  : @invalid_objects
-- Requirements : Access to the DBA views.
-- Last Modified: 18/12/2005
-- -----------------------------------------------------------------------------------
COLUMN owner FORMAT A30
COLUMN object_name FORMAT A30

SELECT owner,
       object_type,
       object_name,
       status
FROM   dba_objects
WHERE  status = 'INVALID'
ORDER BY owner, object_type, object_name;

-- End of invalid_objects.sql --

-- ########## Start of jobs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/jobs.sql
-- Author       : Tim Hall
-- Description  : Displays information about all scheduled jobs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @jobs
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 1000 PAGESIZE 1000

COLUMN log_user FORMAT A15
COLUMN priv_user FORMAT A15
COLUMN schema_user FORMAT A15
COLUMN interval FORMAT A40
COLUMN what FORMAT A50
COLUMN nls_env FORMAT A50
COLUMN misc_env FORMAT A50

SELECT a.job,            
       a.log_user,       
       a.priv_user,     
       a.schema_user,    
       To_Char(a.last_date,'DD-MON-YYYY HH24:MI:SS') AS last_date,      
       --To_Char(a.this_date,'DD-MON-YYYY HH24:MI:SS') AS this_date,      
       To_Char(a.next_date,'DD-MON-YYYY HH24:MI:SS') AS next_date,      
       a.broken,         
       a.interval,       
       a.failures,       
       a.what,
       a.total_time,     
       a.nls_env,        
       a.misc_env          
FROM   dba_jobs a;

SET LINESIZE 80 PAGESIZE 14
-- End of jobs.sql --

-- ########## Start of jobs_running.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/jobs_running.sql
-- Author       : Tim Hall
-- Description  : Displays information about all jobs currently running.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @jobs_running
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT a.job "Job",
       a.sid,
       a.failures "Failures",       
       Substr(To_Char(a.last_date,'DD-Mon-YYYY HH24:MI:SS'),1,20) "Last Date",      
       Substr(To_Char(a.this_date,'DD-Mon-YYYY HH24:MI:SS'),1,20) "This Date"             
FROM   dba_jobs_running a;

SET PAGESIZE 14
SET VERIFY ON
-- End of jobs_running.sql --

-- ########## Start of large_lob_segments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/large_lob_segments.sql
-- Author       : Tim Hall
-- Description  : Displays size of large LOB segments.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @large_lob_segments (rows)
-- Last Modified: 12/09/2017
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 VERIFY OFF
COLUMN owner FORMAT A30
COLUMN table_name FORMAT A30
COLUMN column_name FORMAT A30
COLUMN segment_name FORMAT A30
COLUMN tablespace_name FORMAT A30
COLUMN size_mb FORMAT 99999999.00

SELECT *
FROM   (SELECT l.owner,
               l.table_name,
               l.column_name,
               l.segment_name,
               l.tablespace_name,
               ROUND(s.bytes/1024/1024,2) size_mb
        FROM   dba_lobs l
               JOIN dba_segments s ON s.owner = l.owner AND s.segment_name = l.segment_name
        ORDER BY 6 DESC)
WHERE  ROWNUM <= &1;

SET VERIFY ON
-- End of large_lob_segments.sql --

-- ########## Start of large_segments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/large_segments.sql
-- Author       : Tim Hall
-- Description  : Displays size of large segments.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @large_segments (rows)
-- Last Modified: 12/09/2017
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 VERIFY OFF
COLUMN owner FORMAT A30
COLUMN segment_name FORMAT A30
COLUMN tablespace_name FORMAT A30
COLUMN size_mb FORMAT 99999999.00

SELECT *
FROM   (SELECT owner,
               segment_name,
               segment_type,
               tablespace_name,
               ROUND(bytes/1024/1024,2) size_mb
        FROM   dba_segments
        ORDER BY 5 DESC)
WHERE  ROWNUM <= &1;

SET VERIFY ON
-- End of large_segments.sql --

-- ########## Start of latch_hit_ratios.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/latch_hit_ratios.sql
-- Author       : Tim Hall
-- Description  : Displays current latch hit ratios.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @latch_hit_ratios
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN latch_hit_ratio FORMAT 990.00
 
SELECT l.name,
       l.gets,
       l.misses,
       ((1 - (l.misses / l.gets)) * 100) AS latch_hit_ratio
FROM   v$latch l
WHERE  l.gets   != 0
UNION
SELECT l.name,
       l.gets,
       l.misses,
       100 AS latch_hit_ratio
FROM   v$latch l
WHERE  l.gets   = 0
ORDER BY 4 DESC;

-- End of latch_hit_ratios.sql --

-- ########## Start of latch_holders.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/latch_holders.sql
-- Author       : Tim Hall
-- Description  : Displays information about all current latch holders.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @latch_holders
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

SELECT l.name "Latch Name",
       lh.pid "PID",
       lh.sid "SID",
       l.gets "Gets (Wait)",
       l.misses "Misses (Wait)",
       l.sleeps "Sleeps (Wait)",
       l.immediate_gets "Gets (No Wait)",
       l.immediate_misses "Misses (Wait)"
FROM   v$latch l,
       v$latchholder lh
WHERE  l.addr = lh.laddr
ORDER BY l.name;

-- End of latch_holders.sql --

-- ########## Start of latches.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/latches.sql
-- Author       : Tim Hall
-- Description  : Displays information about all current latches.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @latches
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

SELECT l.latch#,
       l.name,
       l.gets,
       l.misses,
       l.sleeps,
       l.immediate_gets,
       l.immediate_misses,
       l.spin_gets
FROM   v$latch l
ORDER BY l.name;

-- End of latches.sql --

-- ########## Start of library_cache.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/library_cache.sql
-- Author       : Tim Hall
-- Description  : Displays library cache statistics.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @library_cache
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT a.namespace "Name Space",
       a.gets "Get Requests",
       a.gethits "Get Hits",
       Round(a.gethitratio,2) "Get Ratio",
       a.pins "Pin Requests",
       a.pinhits "Pin Hits",
       Round(a.pinhitratio,2) "Pin Ratio",
       a.reloads "Reloads",
       a.invalidations "Invalidations"
FROM   v$librarycache a
ORDER BY 1;

SET PAGESIZE 14
SET VERIFY ON
-- End of library_cache.sql --

-- ########## Start of license.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/license.sql
-- Author       : Tim Hall
-- Description  : Displays session usage for licensing purposes.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @license
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SELECT *
FROM   v$license;

-- End of license.sql --

-- ########## Start of locked_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/locked_objects.sql
-- Author       : DR Timothy S Hall
-- Description  : Lists all locked objects.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @locked_objects
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

COLUMN owner FORMAT A20
COLUMN username FORMAT A20
COLUMN object_owner FORMAT A20
COLUMN object_name FORMAT A30
COLUMN locked_mode FORMAT A15

SELECT lo.session_id AS sid,
       s.serial#,
       NVL(lo.oracle_username, '(oracle)') AS username,
       o.owner AS object_owner,
       o.object_name,
       Decode(lo.locked_mode, 0, 'None',
                             1, 'Null (NULL)',
                             2, 'Row-S (SS)',
                             3, 'Row-X (SX)',
                             4, 'Share (S)',
                             5, 'S/Row-X (SSX)',
                             6, 'Exclusive (X)',
                             lo.locked_mode) locked_mode,
       lo.os_user_name
FROM   v$locked_object lo
       JOIN dba_objects o ON o.object_id = lo.object_id
       JOIN v$session s ON lo.session_id = s.sid
ORDER BY 1, 2, 3, 4;

SET PAGESIZE 14
SET VERIFY ON
-- End of locked_objects.sql --

-- ########## Start of locked_objects_internal.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/locked_objects_internal.sql
-- Author       : Tim Hall
-- Description  : Lists all locks on the specific object.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @locked_objects_internal (object-name)
-- Last Modified: 16/02/2018
-- -----------------------------------------------------------------------------------
SET LINESIZE 1000 VERIFY OFF

COLUMN lock_type FORMAT A20
COLUMN mode_held FORMAT A10
COLUMN mode_requested FORMAT A10
COLUMN lock_id1 FORMAT A50
COLUMN lock_id2 FORMAT A30

SELECT li.session_id AS sid,
       s.serial#,
       li.lock_type,
       li.mode_held,
       li.mode_requested,
       li.lock_id1,
       li.lock_id2
FROM   dba_lock_internal li
       JOIN v$session s ON li.session_id = s.sid
WHERE  UPPER(lock_id1) LIKE UPPER('%&1%');

SET VERIFY ON
-- End of locked_objects_internal.sql --

-- ########## Start of logfiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/logfiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about redo log files.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @logfiles
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------

SET LINESIZE 200
COLUMN member FORMAT A50
COLUMN first_change# FORMAT 99999999999999999999
COLUMN next_change# FORMAT 99999999999999999999

SELECT l.thread#,
       lf.group#,
       lf.member,
       TRUNC(l.bytes/1024/1024) AS size_mb,
       l.status,
       l.archived,
       lf.type,
       lf.is_recovery_dest_file AS rdf,
       l.sequence#,
       l.first_change#,
       l.next_change#   
FROM   v$logfile lf
       JOIN v$log l ON l.group# = lf.group#
ORDER BY l.thread#,lf.group#, lf.member;

SET LINESIZE 80

-- End of logfiles.sql --

-- ########## Start of longops.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/longops.sql
-- Author       : Tim Hall
-- Description  : Displays information on all long operations.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @longops
-- Last Modified: 03/07/2003
-- -----------------------------------------------------------------------------------

COLUMN sid FORMAT 999
COLUMN serial# FORMAT 9999999
COLUMN machine FORMAT A30
COLUMN progress_pct FORMAT 99999999.00
COLUMN elapsed FORMAT A10
COLUMN remaining FORMAT A10

SELECT s.sid,
       s.serial#,
       s.machine,
       ROUND(sl.elapsed_seconds/60) || ':' || MOD(sl.elapsed_seconds,60) elapsed,
       ROUND(sl.time_remaining/60) || ':' || MOD(sl.time_remaining,60) remaining,
       ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
FROM   v$session s,
       v$session_longops sl
WHERE  s.sid     = sl.sid
AND    s.serial# = sl.serial#
AND    time_remaining > 0;

-- End of longops.sql --

-- ########## Start of lru_latch_ratio.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/lru_latch_ratio.sql
-- Author       : Tim Hall
-- Description  : Displays current LRU latch ratios.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @lru_latch_hit_ratio
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
COLUMN "Ratio %" FORMAT 990.00
 
PROMPT
PROMPT Values greater than 3% indicate contention.

SELECT a.child#,
       (a.SLEEPS / a.GETS) * 100 "Ratio %"
FROM   v$latch_children a
WHERE  a.name      = 'cache buffers lru chain'
ORDER BY 1;


SET PAGESIZE 14

-- End of lru_latch_ratio.sql --

-- ########## Start of max_extents.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/max_extents.sql
-- Author       : Tim Hall
-- Description  : Displays all tables and indexes nearing their MAX_EXTENTS setting.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @max_extents
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

PROMPT
PROMPT Tables and Indexes nearing MAX_EXTENTS
PROMPT **************************************
SELECT e.owner,
       e.segment_type,
       Substr(e.segment_name, 1, 30) segment_name,
       Trunc(s.initial_extent/1024) "INITIAL K",
       Trunc(s.next_extent/1024) "NEXT K",
       s.max_extents,
       Count(*) as extents
FROM   dba_extents e,
       dba_segments s
WHERE  e.owner        = s.owner
AND    e.segment_name = s.segment_name
AND    e.owner        NOT IN ('SYS', 'SYSTEM')
GROUP BY e.owner, e.segment_type, e.segment_name, s.initial_extent, s.next_extent, s.max_extents
HAVING Count(*) > s.max_extents - 10
ORDER BY e.owner, e.segment_type, Count(*) DESC;

-- End of max_extents.sql --

-- ########## Start of min_datafile_size.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/min_datafile_size.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays smallest size the datafiles can shrink to without a reorg.
-- Requirements : Access to the V$ and DBA views.
-- Call Syntax  : @min_datafile_size
-- Last Modified: 07/09/2007
-- -----------------------------------------------------------------------------------

COLUMN block_size NEW_VALUE v_block_size

SELECT TO_NUMBER(value) AS block_size
FROM   v$parameter
WHERE  name = 'db_block_size';

COLUMN tablespace_name FORMAT A20
COLUMN file_name FORMAT A50
COLUMN current_bytes FORMAT 999999999999999
COLUMN shrink_by_bytes FORMAT 999999999999999
COLUMN resize_to_bytes FORMAT 999999999999999
SET VERIFY OFF
SET LINESIZE 200

SELECT a.tablespace_name,
       a.file_name,
       a.bytes AS current_bytes,
       a.bytes - b.resize_to AS shrink_by_bytes,
       b.resize_to AS resize_to_bytes
FROM   dba_data_files a,
       (SELECT file_id, MAX((block_id+blocks-1)*&v_block_size) AS resize_to
        FROM   dba_extents
        GROUP by file_id) b
WHERE  a.file_id = b.file_id
ORDER BY a.tablespace_name, a.file_name;

-- End of min_datafile_size.sql --

-- ########## Start of monitor.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/monitor.sql
-- Author       : Tim Hall
-- Description  : Displays SQL statements for the current database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @monitor
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 255
COL SID FORMAT 999
COL STATUS FORMAT A8
COL PROCESS FORMAT A10
COL SCHEMANAME FORMAT A16
COL OSUSER  FORMAT A16
COL SQL_TEXT FORMAT A120 HEADING 'SQL QUERY'
COL PROGRAM	FORMAT A30

SELECT s.sid,
       s.status,
       s.process,
       s.schemaname,
       s.osuser,
       a.sql_text,
       p.program
FROM   v$session s,
       v$sqlarea a,
       v$process p
WHERE  s.SQL_HASH_VALUE = a.HASH_VALUE
AND    s.SQL_ADDRESS = a.ADDRESS
AND    s.PADDR = p.ADDR
/

SET VERIFY ON
SET LINESIZE 255
-- End of monitor.sql --

-- ########## Start of monitor_memory.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/monitor_memory.sql
-- Author       : Tim Hall
-- Description  : Displays memory allocations for the current database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @monitor_memory
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN username FORMAT A20
COLUMN module FORMAT A20

SELECT NVL(a.username,'(oracle)') AS username,
       a.module,
       a.program,
       Trunc(b.value/1024) AS memory_kb
FROM   v$session a,
       v$sesstat b,
       v$statname c
WHERE  a.sid = b.sid
AND    b.statistic# = c.statistic#
AND    c.name = 'session pga memory'
AND    a.program IS NOT NULL
ORDER BY b.value DESC;
-- End of monitor_memory.sql --

-- ########## Start of monitoring_status.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/monitoring_status.sql
-- Author       : Tim Hall
-- Description  : Shows the monitoring status for the specified tables.
-- Call Syntax  : @monitoring_status (schema) (table-name or all)
-- Last Modified: 21/03/2003
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

SELECT table_name, monitoring 
FROM   dba_tables
WHERE  owner = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

-- End of monitoring_status.sql --

-- ########## Start of my_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/my_roles.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all roles and privileges granted to the current user.
-- Requirements : Access to the USER views.
-- Call Syntax  : @user_roles
-- Last Modified: 26/06/2023
-- -----------------------------------------------------------------------------------
set serveroutput on
set verify off

select a.granted_role,
       a.admin_option
from   user_role_privs a
order by a.granted_role;

select a.privilege,
       a.admin_option
from   user_sys_privs a
order by a.privilege;
               
set verify on

-- End of my_roles.sql --

-- ########## Start of nls_params.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/nls_params.sql
-- Author       : Tim Hall
-- Description  : Displays National Language Suppport (NLS) information.
-- Requirements : 
-- Call Syntax  : @nls_params
-- Last Modified: 21-FEB-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 100
COLUMN parameter FORMAT A45
COLUMN value FORMAT A45

PROMPT *** Database parameters ***
SELECT * FROM nls_database_parameters ORDER BY 1;

PROMPT *** Instance parameters ***
SELECT * FROM nls_instance_parameters ORDER BY 1;

PROMPT *** Session parameters ***
SELECT * FROM nls_session_parameters ORDER BY 1;
-- End of nls_params.sql --

-- ########## Start of non_indexed_fks.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/non_indexed_fks.sql
-- Author       : Tim Hall
-- Description  : Displays a list of non-indexes FKs.
-- Requirements : Access to the ALL views.
-- Call Syntax  : @non_indexed_fks
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET PAGESIZE 1000
SET LINESIZE 255
SET FEEDBACK OFF

SELECT t.table_name,
       c.constraint_name,
       c.table_name table2,
       acc.column_name
FROM   all_constraints t,
       all_constraints c,
       all_cons_columns acc
WHERE  c.r_constraint_name = t.constraint_name
AND    c.table_name        = acc.table_name
AND    c.constraint_name   = acc.constraint_name
AND    NOT EXISTS (SELECT '1' 
                   FROM  all_ind_columns aid
                   WHERE aid.table_name  = acc.table_name
                   AND   aid.column_name = acc.column_name)
ORDER BY c.table_name;


PROMPT
SET FEEDBACK ON
SET PAGESIZE 18

-- End of non_indexed_fks.sql --

-- ########## Start of obj_lock.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/obj_lock.sql
-- Author       : Tim Hall
-- Description  : Displays a list of locked objects.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @obj_lock
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SELECT a.type,
       Substr(a.owner,1,30) owner,
       a.sid,
       Substr(a.object,1,30) object
FROM   v$access a
WHERE  a.owner NOT IN ('SYS','PUBLIC')
ORDER BY 1,2,3,4
/

-- End of obj_lock.sql --

-- ########## Start of object_privs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/object_privs.sql
-- Author       : Tim Hall
-- Description  : Displays object privileges on a specified object.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @object_privs (owner) (object-name)
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200 VERIFY OFF

COLUMN owner FORMAT A30
COLUMN object_name FORMAT A30
COLUMN grantor FORMAT A30
COLUMN grantee FORMAT A30

SELECT owner,
       table_name AS object_name,
       grantor,
       grantee,
       privilege,
       grantable,
       hierarchy
FROM   dba_tab_privs
WHERE  owner      = UPPER('&1')
AND    table_name = UPPER('&2')
ORDER BY 1,2,3,4;

SET VERIFY ON
-- End of object_privs.sql --

-- ########## Start of object_status.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/object_status.sql
-- Author       : Tim Hall
-- Description  : Displays a list of objects and their status for the specific schema.
-- Requirements : Access to the ALL views.
-- Call Syntax  : @object_status (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET PAGESIZE 1000
SET LINESIZE 255
SET FEEDBACK OFF
SET VERIFY OFF

SELECT Substr(object_name,1,30) object_name,
       object_type,
       status
FROM   all_objects
WHERE  owner = Upper('&&1');

PROMPT
SET FEEDBACK ON
SET PAGESIZE 18

-- End of object_status.sql --

-- ########## Start of objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/objects.sql
-- Author       : Tim Hall
-- Description  : Displays information about all database objects.
-- Requirements : Access to the dba_objects view.
-- Call Syntax  : @objects [ object-name | % (for all)]
-- Last Modified: 21-FEB-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200 VERIFY OFF

COLUMN owner FORMAT A20
COLUMN object_name FORMAT A30
COLUMN edition_name FORMAT A15

SELECT owner,
       object_name,
       --subobject_name,
       object_id,
       data_object_id,
       object_type,
       TO_CHAR(created, 'DD-MON-YYYY HH24:MI:SS') AS created,
       TO_CHAR(last_ddl_time, 'DD-MON-YYYY HH24:MI:SS') AS last_ddl_time,
       timestamp,
       status,
       temporary,
       generated,
       secondary,
       --namespace,
       edition_name
FROM   dba_objects
WHERE  UPPER(object_name) LIKE UPPER('%&1%')
ORDER BY owner, object_name;

SET VERIFY ON

-- End of objects.sql --

-- ########## Start of open_cursors.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/open_cursors.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all cursors currently open.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @open_cursors
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SELECT a.user_name,
       a.sid,
       a.sql_text
FROM   v$open_cursor a
ORDER BY 1,2
/

-- End of open_cursors.sql --

-- ########## Start of open_cursors_by_sid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/open_cursors_by_sid.sql
-- Author       : Tim Hall
-- Description  : Displays the SQL statement held for a specific SID.
-- Comments     : The SID can be found by running session.sql or top_session.sql.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @open_cursors_by_sid (sid)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT oc.sql_text, cursor_type
FROM   v$open_cursor oc
WHERE  oc.sid = &1
ORDER BY cursor_type;

PROMPT
SET PAGESIZE 14
-- End of open_cursors_by_sid.sql --

-- ########## Start of open_cursors_full_by_sid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/open_cursors_full_by_sid.sql
-- Author       : Tim Hall
-- Description  : Displays the SQL statement held for a specific SID.
-- Comments     : The SID can be found by running session.sql or top_session.sql.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @open_cursors_full_by_sid (sid)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT st.sql_text
FROM   v$sqltext st,
       v$open_cursor oc
WHERE  st.address = oc.address
AND    st.hash_value = oc.hash_value
AND    oc.sid = &1
ORDER BY st.address, st.piece;

PROMPT
SET PAGESIZE 14

-- End of open_cursors_full_by_sid.sql --

-- ########## Start of options.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/options.sql
-- Author       : Tim Hall
-- Description  : Displays information about all database options.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @options
-- Last Modified: 12/04/2013
-- -----------------------------------------------------------------------------------

COLUMN value FORMAT A20

SELECT *
FROM   v$option
ORDER BY parameter;

-- End of options.sql --

-- ########## Start of packaged_procs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/packaged_procs.sql
-- Author       : Tim Hall
-- Description  : Displays tablespaces the user has quotas on.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @packaged_procs {package_name}
-- Last Modified: 16-JAN-2024
-- -----------------------------------------------------------------------------------

set verify off
column owner format a30
column object_name format a30
column procedure_name format a30

select owner, object_name, procedure_name
from   dba_procedures
where  object_type = 'PACKAGE'
and    object_name like '%' || upper('&1') || '%';

-- End of packaged_procs.sql --

-- ########## Start of param_valid_values.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/param_valid_values.sql
-- Author       : Tim Hall
-- Description  : Lists all valid values for the specified parameter.
-- Call Syntax  : @param_valid_values (parameter-name)
-- Requirements : Access to the v$views.
-- Last Modified: 14/05/2013
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

COLUMN value FORMAT A50
COLUMN isdefault FORMAT A10

SELECT value,
       isdefault
FROM   v$parameter_valid_values
WHERE  name = '&1';

-- End of param_valid_values.sql --

-- ########## Start of parameter_diffs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/parameter_diffs.sql
-- Author       : Tim Hall
-- Description  : Displays parameter values that differ between the current value and the spfile.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @parameter_diffs
-- Last Modified: 08-NOV-2004
-- -----------------------------------------------------------------------------------

SET LINESIZE 120
COLUMN name          FORMAT A30
COLUMN current_value FORMAT A30
COLUMN sid           FORMAT A8
COLUMN spfile_value  FORMAT A30

SELECT p.name,
       i.instance_name AS sid,
       p.value AS current_value,
       sp.sid,
       sp.value AS spfile_value      
FROM   v$spparameter sp,
       v$parameter p,
       v$instance i
WHERE  sp.name   = p.name
AND    sp.value != p.value;

COLUMN FORMAT DEFAULT

-- End of parameter_diffs.sql --

-- ########## Start of parameters.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/parameters.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all the parameters.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @parameters
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500

COLUMN name  FORMAT A30
COLUMN value FORMAT A60

SELECT p.name,
       p.type,
       p.value,
       p.isses_modifiable,
       p.issys_modifiable,
       p.isinstance_modifiable
FROM   v$parameter p
ORDER BY p.name;


-- End of parameters.sql --

-- ########## Start of parameters_non_default.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/parameters_non_default.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all the non-default parameters.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @parameters_non_default
-- Last Modified: 11-JAN-2017
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN name FORMAT A50
COLUMN value FORMAT A50

SELECT name,
       value
FROM   v$parameter
WHERE  isdefault = 'FALSE';

-- End of parameters_non_default.sql --

-- ########## Start of part_tables.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/part_tables.sql
-- Author       : Tim Hall
-- Description  : Displays information about all partitioned tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @part_tables
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------

SELECT owner, table_name, partitioning_type, partition_count
FROM   dba_part_tables
WHERE  owner NOT IN ('SYS', 'SYSTEM')
ORDER BY owner, table_name;

-- End of part_tables.sql --

-- ########## Start of patch_registry.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/patch_registry.sql
-- Author       : Tim Hall
-- Description  : Lists all patches applied.
-- Call Syntax  : @patch_registry
-- Requirements : Access to the DBA views.
-- Last Modified: 25/01/2024
-- -----------------------------------------------------------------------------------

set linesize 150
column status format a10
column action_time format a30

select install_id,
       patch_id,
       patch_uid,
       patch_type,
       action,
       status,
       target_version,
       action_time
from   dba_registry_sqlpatch
order by 1;

-- End of patch_registry.sql --

-- ########## Start of pga_target_advice.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/pga_target_advice.sql
-- Author       : Tim Hall
-- Description  : Predicts how changes to the PGA_AGGREGATE_TARGET will affect PGA usage.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @pga_target_advice
-- Last Modified: 12/02/2004
-- -----------------------------------------------------------------------------------

SELECT ROUND(pga_target_for_estimate/1024/1024) target_mb,
       estd_pga_cache_hit_percentage cache_hit_perc,
       estd_overalloc_count
FROM   v$pga_target_advice;
-- End of pga_target_advice.sql --

-- ########## Start of pipes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/pipes.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all database pipes.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @pipes
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 100

COLUMN name FORMAT A40

SELECT ownerid,
       name,
       type,
       pipe_size
FROM   v$db_pipes
ORDER BY 1,2;


-- End of pipes.sql --

-- ########## Start of profiler_run_details.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/profiler_run_details.sql
-- Author       : Tim Hall
-- Description  : Displays details of a specified profiler run.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @profiler_run_details.sql (runid)
-- Last Modified: 25/02/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET VERIFY OFF

COLUMN runid FORMAT 99999
COLUMN unit_number FORMAT 99999
COLUMN unit_type FORMAT A20
COLUMN unit_owner FORMAT A20

SELECT u.runid,
       u.unit_number,
       u.unit_type,
       u.unit_owner,
       u.unit_name,
       d.line#,
       d.total_occur,
       ROUND(d.total_time/d.total_occur) as time_per_occur,
       d.total_time,
       d.min_time,
       d.max_time
FROM   plsql_profiler_units u
       JOIN plsql_profiler_data d ON u.runid = d.runid AND u.unit_number = d.unit_number
WHERE  u.runid = &1
AND    d.total_time > 0
AND    d.total_occur > 0
ORDER BY (d.total_time/d.total_occur) DESC, u.unit_number, d.line#;

-- End of profiler_run_details.sql --

-- ########## Start of profiler_runs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/profiler_runs.sql
-- Author       : Tim Hall
-- Description  : Displays information on all profiler_runs.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @profiler_runs.sql
-- Last Modified: 25/02/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET TRIMOUT ON

COLUMN runid FORMAT 99999
COLUMN run_comment FORMAT A50

SELECT runid,
       run_date,
       run_comment,
       run_total_time
FROM   plsql_profiler_runs
ORDER BY runid;

-- End of profiler_runs.sql --

-- ########## Start of profiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/profiles.sql
-- Author       : Tim Hall
-- Description  : Displays the specified profile(s).
-- Call Syntax  : @profiles (profile | part of profile | all)
-- Last Modified: 28/01/2006
-- -----------------------------------------------------------------------------------

SET LINESIZE 150 PAGESIZE 20 VERIFY OFF

BREAK ON profile SKIP 1

COLUMN profile FORMAT A35
COLUMN resource_name FORMAT A40
COLUMN limit FORMAT A15

SELECT profile,
       resource_type,
       resource_name,
       limit
FROM   dba_profiles
WHERE  profile LIKE (DECODE(UPPER('&1'), 'ALL', '%', UPPER('%&1%')))
ORDER BY profile, resource_type, resource_name;

CLEAR BREAKS
SET LINESIZE 80 PAGESIZE 14 VERIFY ON

-- End of profiles.sql --

-- ########## Start of proxy_sessions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/proxy_sessions.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database proxy sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @proxy_sessions
-- Last Modified: 01-JUN-2021
-- -----------------------------------------------------------------------------------
set linesize 500
set pagesize 1000

column username format a30
column osuser format a20
column spid format a10
column service_name format a15
column module format a45
column machine format a30
column logon_time format a20

select nvl(s.username, '(oracle)') as username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.service_name,
       s.machine,
       s.program,
       to_char(s.logon_time,'dd-mon-yyyy hh24:mi:ss') as logon_time,
       s.last_call_et as last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
from   v$session s,
       v$process p,
       v$session_connect_info sci
where  s.paddr = p.addr
and    s.sid = sci.sid
and    s.serial# = sci.serial#
and    sci.authentication_type = 'PROXY'
order by s.username, s.osuser;

set pagesize 14

-- End of proxy_sessions.sql --

-- ########## Start of proxy_users.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/proxy_users.sql
-- Author       : Tim Hall
-- Description  : Displays information about proxy users.
-- Requirements : Access to the PROXY_USERS views.
-- Call Syntax  : @proxy_users.sql {username or %}
-- Last Modified: 02/06/2020
-- -----------------------------------------------------------------------------------

SET VERIFY OFF

COLUMN proxy FORMAT A30
COLUMN client FORMAT A30

SELECT proxy,
       client,
       authentication,
       flags
FROM   proxy_users
WHERE  proxy LIKE UPPER('%&1%');

-- End of proxy_users.sql --

-- ########## Start of rbs_extents.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/rbs_extents.sql
-- Author       : Tim Hall
-- Description  : Displays information about the rollback segment extents.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @rbs_extents
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT Substr(a.segment_name,1,30) "Segment Name",
       b.status "Status",
       Count(*) "Extents",
       b.max_extents "Max Extents",
       Trunc(b.initial_extent/1024) "Initial Extent (Kb)",
       Trunc(b.next_extent/1024) "Next Extent (Kb)",
       Trunc(c.bytes/1024) "Size (Kb)"
FROM   dba_extents a,
       dba_rollback_segs b,
       dba_segments c
WHERE  a.segment_type = 'ROLLBACK'
AND    b.segment_name = a.segment_name
AND    b.segment_name = c.segment_name
GROUP  BY a.segment_name,
          b.status, 
          b.max_extents,
          b.initial_extent,
          b.next_extent,
          c.bytes
ORDER  BY a.segment_name;

SET PAGESIZE 14
SET VERIFY ON
-- End of rbs_extents.sql --

-- ########## Start of rbs_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/rbs_stats.sql
-- Author       : Tim Hall
-- Description  : Displays rollback segment statistics.
-- Requirements : Access to the v$ & DBA views.
-- Call Syntax  : @rbs_stats
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT b.name "Segment Name",
       Trunc(c.bytes/1024) "Size (Kb)",
       a.optsize "Optimal",
       a.shrinks "Shrinks",
       a.aveshrink "Avg Shrink",
       a.wraps "Wraps",
       a.extends "Extends"
FROM   v$rollstat a,
       v$rollname b,
       dba_segments c
WHERE  a.usn  = b.usn
AND    b.name = c.segment_name
ORDER BY b.name;

SET PAGESIZE 14
SET VERIFY ON
-- End of rbs_stats.sql --

-- ########## Start of recovery_status.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/recovery_status.sql
-- Author       : Tim Hall
-- Description  : Displays the recovery status of each datafile.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @recovery_status
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 500
SET FEEDBACK OFF

SELECT Substr(a.name,1,60) "Datafile",
       b.status "Status"
FROM   v$datafile a,
       v$backup b
WHERE  a.file# = b.file#;

SET PAGESIZE 14
SET FEEDBACK ON
-- End of recovery_status.sql --

-- ########## Start of recyclebin.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/recyclebin.sql
-- Author       : Tim Hall
-- Description  : Displays the contents of the recyclebin.
-- Requirements : Access to the DBA views. Depending on DB version, different columns
--                are available.
-- Call Syntax  : @recyclebin (owner | all)
-- Last Modified: 15/07/2010
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 VERIFY OFF

SELECT owner,
       original_name,
       object_name,
       operation,
       type,
       space AS space_blks,
       ROUND((space*8)/1024,2) space_mb
FROM   dba_recyclebin
WHERE  owner = DECODE(UPPER('&1'), 'ALL', owner, UPPER('&1'))
ORDER BY 1, 2;

SET VERIFY ON
-- End of recyclebin.sql --

-- ########## Start of redo_by_day.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/redo_by_day.sql
-- Author       : Tim Hall
-- Description  : Lists the volume of archived redo by day for the specified number of days.
-- Call Syntax  : @redo_by_day (days)
-- Requirements : Access to the v$views.
-- Last Modified: 11/10/2013
-- -----------------------------------------------------------------------------------

SET VERIFY OFF

SELECT TRUNC(first_time) AS day,
       ROUND(SUM(blocks * block_size)/1024/1024/1024,2) size_gb
FROM   v$archived_log
WHERE  TRUNC(first_time) >= TRUNC(SYSDATE) - &1
GROUP BY TRUNC(first_time)
ORDER BY TRUNC(first_time);

SET VERIFY ON
-- End of redo_by_day.sql --

-- ########## Start of redo_by_hour.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/redo_by_hour.sql
-- Author       : Tim Hall
-- Description  : Lists the volume of archived redo by hour for the specified day.
-- Call Syntax  : @redo_by_hour (day 0=Today, 1=Yesterday etc.)
-- Requirements : Access to the v$views.
-- Last Modified: 11/10/2013
-- -----------------------------------------------------------------------------------

SET VERIFY OFF PAGESIZE 30

WITH hours AS (
  SELECT TRUNC(SYSDATE) - &1 + ((level-1)/24) AS hours
  FROM   dual
  CONNECT BY level < = 24
)
SELECT h.hours AS date_hour,
       ROUND(SUM(blocks * block_size)/1024/1024/1024,2) size_gb
FROM   hours h
       LEFT OUTER JOIN v$archived_log al ON h.hours = TRUNC(al.first_time, 'HH24')
GROUP BY h.hours
ORDER BY h.hours;

SET VERIFY ON PAGESIZE 14
-- End of redo_by_hour.sql --

-- ########## Start of redo_by_min.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/redo_by_min.sql
-- Author       : Tim Hall
-- Description  : Lists the volume of archived redo by min for the specified number of hours.
-- Call Syntax  : @redo_by_min (N number of minutes from now)
-- Requirements : Access to the v$views.
-- Last Modified: 11/10/2013
-- -----------------------------------------------------------------------------------

SET VERIFY OFF PAGESIZE 100

WITH mins AS (
  SELECT TRUNC(SYSDATE, 'MI') - (&1/(24*60)) + ((level-1)/(24*60)) AS mins
  FROM   dual
  CONNECT BY level <= &1
)
SELECT m.mins AS date_min,
       ROUND(SUM(blocks * block_size)/1024/1024,2) size_mb
FROM   mins m
       LEFT OUTER JOIN v$archived_log al ON m.mins = TRUNC(al.first_time, 'MI')
GROUP BY m.mins
ORDER BY m.mins;

SET VERIFY ON PAGESIZE 14
-- End of redo_by_min.sql --

-- ########## Start of registry_history.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/registry_history.sql
-- Author       : Tim Hall
-- Description  : Displays contents of the registry history
-- Requirements : Access to the DBA role.
-- Call Syntax  : @registry_history
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN action_time FORMAT A20
COLUMN action FORMAT A20
COLUMN namespace FORMAT A20
COLUMN version FORMAT A10
COLUMN comments FORMAT A30
COLUMN bundle_series FORMAT A10

SELECT TO_CHAR(action_time, 'DD-MON-YYYY HH24:MI:SS') AS action_time,
       action,
       namespace,
       version,
       id,
       comments,
       bundle_series
FROM   sys.registry$history
ORDER by action_time;
-- End of registry_history.sql --

-- ########## Start of role_privs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/role_privs.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all roles and privileges granted to the specified role.
-- Requirements : Access to the USER views.
-- Call Syntax  : @role_privs (role-name, ALL)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET VERIFY OFF

SELECT a.role,
       a.granted_role,
       a.admin_option
FROM   role_role_privs a
WHERE  a.role = DECODE(UPPER('&1'), 'ALL', a.role, UPPER('&1'))
ORDER BY a.role, a.granted_role;

SELECT a.grantee,
       a.granted_role,
       a.admin_option,
       a.default_role
FROM   dba_role_privs a
WHERE  a.grantee = DECODE(UPPER('&1'), 'ALL', a.grantee, UPPER('&1'))
ORDER BY a.grantee, a.granted_role;

SELECT a.role,
       a.privilege,
       a.admin_option
FROM   role_sys_privs a
WHERE  a.role = DECODE(UPPER('&1'), 'ALL', a.role, UPPER('&1'))
ORDER BY a.role, a.privilege;

SELECT a.role,
       a.owner,
       a.table_name, 
       a.column_name, 
       a.privilege,
       a.grantable
FROM   role_tab_privs a
WHERE  a.role = DECODE(UPPER('&1'), 'ALL', a.role, UPPER('&1'))
ORDER BY a.role, a.owner, a.table_name;
               
SET VERIFY ON

-- End of role_privs.sql --

-- ########## Start of roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/roles.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all roles and privileges granted to the specified user.
-- Requirements : Access to the USER views.
-- Call Syntax  : @roles
-- Last Modified: 27/02/2018
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET VERIFY OFF

COLUMN role FORMAT A30

SELECT a.role,
       a.password_required,
       a.authentication_type
FROM   dba_roles a
ORDER BY a.role;
               
SET VERIFY ON

-- End of roles.sql --

-- ########## Start of search_source.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/search_source.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all code-objects that contain the specified word.
-- Requirements : Access to the ALL views.
-- Call Syntax  : @search_source (text) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
BREAK ON Name Skip 2
SET PAGESIZE 0
SET LINESIZE 500
SET VERIFY OFF

SPOOL Search_Source.txt

SELECT a.name "Name",
       a.line "Line",
       Substr(a.text,1,200) "Text"
FROM   all_source a
WHERE  Instr(Upper(a.text),Upper('&&1')) != 0
AND    a.owner = Upper('&&2')
ORDER BY 1,2;

SPOOL OFF
SET PAGESIZE 14
SET VERIFY ON

-- End of search_source.sql --

-- ########## Start of segment_size.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/segment_size.sql
-- Author       : Tim Hall
-- Description  : Displays size of specified segment.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @segment_size (owner) (segment_name)
-- Last Modified: 15/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 VERIFY OFF
COLUMN segment_name FORMAT A30

SELECT owner,
       segment_name,
       segment_type,
       tablespace_name,
       ROUND(bytes/1024/1024,2) size_mb
FROM   dba_segments
WHERE  owner = UPPER('&1')
AND    segment_name LIKE '%' || UPPER('&2') || '%'
ORDER BY 1, 2;

SET VERIFY ON
-- End of segment_size.sql --

-- ########## Start of segment_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/segment_stats.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays statistics for segments in th specified schema.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @segment_stats
-- Last Modified: 20/10/2006
-- -----------------------------------------------------------------------------------
SELECT statistic#,
       name
FROM   v$segstat_name
ORDER BY statistic#;

ACCEPT l_schema char PROMPT 'Enter Schema: '
ACCEPT l_stat  NUMBER PROMPT 'Enter Statistic#: '
SET VERIFY OFF

SELECT object_name,
       object_type,
       value
FROM   v$segment_statistics 
WHERE  owner = UPPER('&l_schema')
AND    statistic# = &l_stat
ORDER BY value;

-- End of segment_stats.sql --

-- ########## Start of segments_in_ts.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/segments_in_ts.sql
-- Author       : Tim Hall
-- Description  : Lists the objects stored in a tablespace.
-- Call Syntax  : @objects_in_ts (tablespace-name)
-- Last Modified: 15/06/2018
-- -----------------------------------------------------------------------------------

SET PAGESIZE 20
BREAK ON segment_type SKIP 1

COLUMN segment_name FORMAT A30
COLUMN partition_name FORMAT A30

SELECT segment_type,
       segment_name,
       partition_name,
       ROUND(bytes/2014/1024,2) AS size_mb
FROM   dba_segments
WHERE  tablespace_name = UPPER('&1')
ORDER BY 1, 2;

CLEAR BREAKS

-- End of segments_in_ts.sql --

-- ########## Start of session_events.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_events.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database session events.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_events
-- Last Modified: 11/03/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 1000
SET VERIFY OFF

COLUMN username FORMAT A20
COLUMN event FORMAT A40

SELECT NVL(s.username, '(oracle)') AS username,
       s.sid,
       s.serial#,
       se.event,
       se.total_waits,
       se.total_timeouts,
       se.time_waited,
       se.average_wait,
       se.max_wait,
       se.time_waited_micro
FROM   v$session_event se,
       v$session s
WHERE  s.sid = se.sid
AND    s.sid = &1
ORDER BY se.time_waited DESC;

-- End of session_events.sql --

-- ########## Start of session_events_by_sid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_events_by_sid.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database session events for the specified sid.
--                This is a rename of session_events.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_events_by_sid (sid)
-- Last Modified: 06-APR-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 1000
SET VERIFY OFF

COLUMN username FORMAT A20
COLUMN event FORMAT A40

SELECT NVL(s.username, '(oracle)') AS username,
       s.sid,
       s.serial#,
       se.event,
       se.total_waits,
       se.total_timeouts,
       se.time_waited,
       se.average_wait,
       se.max_wait,
       se.time_waited_micro
FROM   v$session_event se,
       v$session s
WHERE  s.sid = se.sid
AND    s.sid = &1
ORDER BY se.time_waited DESC;

-- End of session_events_by_sid.sql --

-- ########## Start of session_events_by_spid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_events_by_spid.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database session events for the specified spid.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_events_by_spid (spid)
-- Last Modified: 06-APR-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 1000
SET VERIFY OFF

COLUMN username FORMAT A20
COLUMN event FORMAT A40

SELECT NVL(s.username, '(oracle)') AS username,
       s.sid,
       s.serial#,
       se.event,
       se.total_waits,
       se.total_timeouts,
       se.time_waited,
       se.average_wait,
       se.max_wait,
       se.time_waited_micro
FROM   v$session_event se,
       v$session s,
       v$process p
WHERE  s.sid = se.sid
AND    s.paddr = p.addr
AND    p.spid = &1
ORDER BY se.time_waited DESC;

-- End of session_events_by_spid.sql --

-- ########## Start of session_io.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_io.sql
-- Author       : Tim Hall
-- Description  : Displays I/O information on all database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_io
-- Last Modified: 21-FEB-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A15

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       si.block_gets,
       si.consistent_gets,
       si.physical_reads,
       si.block_changes,
       si.consistent_changes
FROM   v$session s,
       v$sess_io si
WHERE  s.sid = si.sid
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of session_io.sql --

-- ########## Start of session_pga.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_pga.sql
-- Author       : Tim Hall
-- Description  : Displays information about PGA usage for each session.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_pga
-- Last Modified: 21-FEB-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20
COLUMN pga_used_mem_mb FORMAT 99990.00
COLUMN pga_alloc_mem_mb FORMAT 99990.00
COLUMN pga_freeable_mem_mb FORMAT 99990.00
COLUMN pga_max_mem_mb FORMAT 99990.00

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       ROUND(p.pga_used_mem/1024/1024,2) AS pga_used_mem_mb,
       ROUND(p.pga_alloc_mem/1024/1024,2) AS pga_alloc_mem_mb,
       ROUND(p.pga_freeable_mem/1024/1024,2) AS pga_freeable_mem_mb,
       ROUND(p.pga_max_mem/1024/1024,2) AS pga_max_mem_mb,
       s.lockwait,
       s.status,
       s.service_name,
       s.module,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs
FROM   v$session s,
       v$process p
WHERE  s.paddr = p.addr
ORDER BY s.username, s.osuser;

SET PAGESIZE 14
-- End of session_pga.sql --

-- ########## Start of session_rollback.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_rollback.sql
-- Author       : Tim Hall
-- Description  : Displays rollback information on relevant database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_rollback
-- Last Modified: 29/03/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN username FORMAT A15

SELECT s.username,
       s.sid,
       s.serial#,
       t.used_ublk,
       t.used_urec,
       rs.segment_name,
       r.rssize,
       r.status
FROM   v$transaction t,
       v$session s,
       v$rollstat r,
       dba_rollback_segs rs
WHERE  s.saddr = t.ses_addr
AND    t.xidusn = r.usn
AND   rs.segment_id = t.xidusn
ORDER BY t.used_ublk DESC;

-- End of session_rollback.sql --

-- ########## Start of session_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_stats.sql
-- Author       : Tim Hall
-- Description  : Displays session-specific statistics.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_stats (statistic-name or all)
-- Last Modified: 03/11/2004
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

SELECT sn.name, ss.value
FROM   v$sesstat ss,
       v$statname sn,
       v$session s
WHERE  ss.statistic# = sn.statistic#
AND    s.sid = ss.sid
AND    s.audsid = SYS_CONTEXT('USERENV','SESSIONID')
AND    sn.name LIKE '%' || DECODE(LOWER('&1'), 'all', '', LOWER('&1')) || '%';


-- End of session_stats.sql --

-- ########## Start of session_stats_by_sid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/session_stats_by_sid.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays session-specific statistics.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_stats_by_sid (sid) (statistic-name or all)
-- Last Modified: 19/09/2006
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

SELECT sn.name, ss.value
FROM   v$sesstat ss,
       v$statname sn
WHERE  ss.statistic# = sn.statistic#
AND    ss.sid = &1
AND    sn.name LIKE '%' || DECODE(LOWER('&2'), 'all', '', LOWER('&2')) || '%';


-- End of session_stats_by_sid.sql --

-- ########## Start of session_undo.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_undo.sql
-- Author       : Tim Hall
-- Description  : Displays undo information on relevant database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_undo
-- Last Modified: 29/03/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN username FORMAT A15

SELECT s.username,
       s.sid,
       s.serial#,
       t.used_ublk,
       t.used_urec,
       rs.segment_name,
       r.rssize,
       r.status
FROM   v$transaction t,
       v$session s,
       v$rollstat r,
       dba_rollback_segs rs
WHERE  s.saddr = t.ses_addr
AND    t.xidusn = r.usn
AND    rs.segment_id = t.xidusn
ORDER BY t.used_ublk DESC;

-- End of session_undo.sql --

-- ########## Start of session_waits.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_waits.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database session waits.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_waits
-- Last Modified: 11/03/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 1000

COLUMN username FORMAT A20
COLUMN event FORMAT A30

SELECT NVL(s.username, '(oracle)') AS username,
       s.sid,
       s.serial#,
       sw.event,
       sw.wait_time,
       sw.seconds_in_wait,
       sw.state
FROM   v$session_wait sw,
       v$session s
WHERE  s.sid = sw.sid
ORDER BY sw.seconds_in_wait DESC;

-- End of session_waits.sql --

-- ########## Start of sessions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sessions.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sessions
-- Last Modified: 16-MAY-2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.service_name,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
FROM   v$session s,
       v$process p
WHERE  s.paddr = p.addr
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of sessions.sql --

-- ########## Start of sessions_by_machine.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sessions_by_machine.sql
-- Author       : Tim Hall
-- Description  : Displays the number of sessions for each client machine.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sessions_by_machine
-- Last Modified: 20-JUL-2014
-- -----------------------------------------------------------------------------------
SET PAGESIZE 1000

SELECT machine,
       NVL(active_count, 0) AS active,
       NVL(inactive_count, 0) AS inactive,
       NVL(killed_count, 0) AS killed 
FROM   (SELECT machine, status, count(*) AS quantity
        FROM   v$session
        GROUP BY machine, status)
PIVOT  (SUM(quantity) AS count FOR (status) IN ('ACTIVE' AS active, 'INACTIVE' AS inactive, 'KILLED' AS killed))
ORDER BY machine;

SET PAGESIZE 14
-- End of sessions_by_machine.sql --

-- ########## Start of sessions_by_osuser.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sessions_by_osuser.sql
-- Author       : Tim Hall
-- Description  : Displays the number of sessions for each OS user.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sessions_by_osuser (osuser)
-- Last Modified: 11-MAR-2025
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 PAGESIZE 1000 VERIFY OFF

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.service_name,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
FROM   v$session s,
       v$process p
WHERE  s.paddr = p.addr
AND    lower(s.osuser) = lower('&1')
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of sessions_by_osuser.sql --

-- ########## Start of sessions_by_sid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sessions_by_sid.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sessions_by_sid (sid)
-- Last Modified: 19-NOV-2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 PAGESIZE 1000 VERIFY OFF

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20

SELECT NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.service_name,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
FROM   v$session s,
       v$process p
WHERE  s.paddr = p.addr
AND    s.sid = &1
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of sessions_by_sid.sql --

-- ########## Start of show_indexes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/show_indexes.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays information about specified indexes.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @show_indexes (schema) (table-name or all)
-- Last Modified: 04/10/2006
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 200

COLUMN table_owner FORMAT A20
COLUMN index_owner FORMAT A20
COLUMN index_type FORMAT A12
COLUMN tablespace_name FORMAT A20

SELECT table_owner,
       table_name,
       owner AS index_owner,
       index_name,
       tablespace_name,
       num_rows,
       status,
       index_type
FROM   dba_indexes
WHERE  table_owner = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
ORDER BY table_owner, table_name, index_owner, index_name;

-- End of show_indexes.sql --

-- ########## Start of show_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/show_space.sql
-- Author       : Tom Kyte
-- Description  : Displays free and unused space for the specified object.
-- Call Syntax  : EXEC Show_Space('Tablename');
-- Requirements : SET SERVEROUTPUT ON              
-- Last Modified: 10/09/2002
-- -----------------------------------------------------------------------------------
CREATE OR REPLACE
PROCEDURE show_space
( p_segname IN VARCHAR2,
  p_owner   IN VARCHAR2 DEFAULT user,
  p_type    IN VARCHAR2 DEFAULT 'TABLE' )
AS
  l_free_blks                 NUMBER;
  l_total_blocks              NUMBER;
  l_total_bytes               NUMBER;
  l_unused_blocks             NUMBER;
  l_unused_bytes              NUMBER;
  l_last_used_ext_file_id     NUMBER;
  l_last_used_ext_block_id        NUMBER;
  l_last_used_block           NUMBER;
  
  PROCEDURE p( p_label IN VARCHAR2, p_num IN NUMBER )
  IS
  BEGIN
     DBMS_OUTPUT.PUT_LINE( RPAD(p_label,40,'.') || p_num );
  END;
  
BEGIN
  DBMS_SPACE.FREE_BLOCKS (
    segment_owner     => p_owner,
    segment_name      => p_segname,
    segment_type      => p_type,
    freelist_group_id => 0,
    free_blks         => l_free_blks );

  DBMS_SPACE.UNUSED_SPACE ( 
    segment_owner             => p_owner,
    segment_name              => p_segname,
    segment_type              => p_type,
    total_blocks              => l_total_blocks,
    total_bytes               => l_total_bytes,
    unused_blocks             => l_unused_blocks,
    unused_bytes              => l_unused_bytes,
    last_used_extent_file_id  => l_last_used_ext_file_id,
    last_used_extent_block_id => l_last_used_ext_block_id,
    last_used_block           => l_last_used_block );
 
  p( 'Free Blocks', l_free_blks );
  p( 'Total Blocks', l_total_blocks );
  p( 'Total Bytes', l_total_bytes );
  p( 'Unused Blocks', l_unused_blocks );
  p( 'Unused Bytes', l_unused_bytes );
  p( 'Last Used Ext FileId', l_last_used_ext_file_id );
  p( 'Last Used Ext BlockId', l_last_used_ext_block_id );
  p( 'Last Used Block', l_LAST_USED_BLOCK );
END;
/
-- End of show_space.sql --

-- ########## Start of show_tables.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/show_tables.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays information about specified tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @show_tables (schema)
-- Last Modified: 04/10/2006
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 200

COLUMN owner FORMAT A20
COLUMN table_name FORMAT A30

SELECT t.table_name,
       t.tablespace_name,
       t.num_rows,
       t.avg_row_len,
       t.blocks,
       t.empty_blocks,
       ROUND(t.blocks * ts.block_size/1024/1024,2) AS size_mb
FROM   dba_tables t
       JOIN dba_tablespaces ts ON t.tablespace_name = ts.tablespace_name
WHERE  t.owner = UPPER('&1')
ORDER BY t.table_name;

-- End of show_tables.sql --

-- ########## Start of source.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/source.sql
-- Author       : Tim Hall
-- Description  : Displays the section of code specified. Prompts user for parameters.
-- Requirements : Access to the ALL views.
-- Call Syntax  : @source
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
PROMPT
ACCEPT a_name   PROMPT 'Enter Name: '
ACCEPT a_type   PROMPT 'Enter Type (S,B,P,F): '
ACCEPT a_from   PROMPT 'Enter Line From: '
ACCEPT a_to     PROMPT 'Enter Line To: '
ACCEPT a_owner  PROMPT 'Enter Owner: '
VARIABLE v_name   VARCHAR2(100)
VARIABLE v_type   VARCHAR2(100)
VARIABLE v_from   NUMBER
VARIABLE v_to     NUMBER
VARIABLE v_owner  VARCHAR2(100)
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 300
SET PAGESIZE 0

BEGIN
  :v_name  := Upper('&a_name');
  :v_type  := Upper('&a_type');
  :v_from  := &a_from;
  :v_to    := &a_to;
  :v_owner := Upper('&a_owner');

  IF    :v_type = 'S' THEN
    :v_type := 'PACKAGE';
  ELSIF :v_type = 'B' THEN
    :v_type := 'PACKAGE BODY';
  ELSIF :v_type = 'P' THEN
    :v_type := 'PROCEDURE';
  ELSE
    :v_type := 'FUNCTION';
  END IF;
END;
/

SELECT a.line "Line",
       Substr(a.text,1,200) "Text"
FROM   all_source a
WHERE  a.name = :v_name
AND    a.type = :v_type
AND    a.line BETWEEN :v_from AND :v_to
AND    a.owner = :v_owner;

SET VERIFY ON
SET FEEDBACK ON
SET PAGESIZE 22
PROMPT

-- End of source.sql --

-- ########## Start of spfile_parameters.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/spfile_parameters.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all the spfile parameters.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @spfile_parameters
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500

COLUMN name  FORMAT A30
COLUMN value FORMAT A60
COLUMN displayvalue FORMAT A60

SELECT sp.sid,
       sp.name,
       sp.value,
       sp.display_value
FROM   v$spparameter sp
ORDER BY sp.name, sp.sid;

-- End of spfile_parameters.sql --

-- ########## Start of sql_area.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sql_area.sql
-- Author       : Tim Hall
-- Description  : Displays the SQL statements for currently running processes.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sql_area
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET FEEDBACK OFF

SELECT s.sid,
       s.status "Status",
       p.spid "Process",
       s.schemaname "Schema Name",
       s.osuser "OS User",
       Substr(a.sql_text,1,120) "SQL Text",
       s.program "Program"
FROM   v$session s,
       v$sqlarea a,
       v$process p
WHERE  s.sql_hash_value = a.hash_value (+)
AND    s.sql_address    = a.address (+)
AND    s.paddr          = p.addr;

SET PAGESIZE 14
SET FEEDBACK ON


-- End of sql_area.sql --

-- ########## Start of sql_text.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sql_text.sql
-- Author       : Tim Hall
-- Description  : Displays the SQL statement held at the specified address.
-- Comments     : The address can be found using v$session or Top_SQL.sql.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sql_text (address)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET FEEDBACK OFF
SET VERIFY OFF

SELECT a.sql_text
FROM   v$sqltext_with_newlines a
WHERE  a.address = UPPER('&&1')
ORDER BY a.piece;

PROMPT
SET PAGESIZE 14
SET FEEDBACK ON

-- End of sql_text.sql --

-- ########## Start of sql_text_by_sid.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sql_text_by_sid.sql
-- Author       : Tim Hall
-- Description  : Displays the SQL statement held for a specific SID.
-- Comments     : The SID can be found by running session.sql or top_session.sql.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sql_text_by_sid (sid)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT a.sql_text
FROM   v$sqltext a,
       v$session b
WHERE  a.address = b.sql_address
AND    a.hash_value = b.sql_hash_value
AND    b.sid = &1
ORDER BY a.piece;

PROMPT
SET PAGESIZE 14

-- End of sql_text_by_sid.sql --

-- ########## Start of statistics_prefs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/statistics_prefs.sql
-- Author       : Tim Hall
-- Description  : Displays current statistics preferences.
-- Requirements : Access to the DBMS_STATS package.
-- Call Syntax  : @statistics_prefs
-- Last Modified: 08-NOV-2022
-- -----------------------------------------------------------------------------------

SET LINESIZE 450

COLUMN approximate_ndv_algorithm FORMAT A25
COLUMN auto_stat_extensions FORMAT A20
COLUMN auto_task_status FORMAT A16
COLUMN auto_task_max_run_time FORMAT A22
COLUMN auto_task_interval FORMAT A18
COLUMN cascade FORMAT A23
COLUMN concurrent FORMAT A10
COLUMN degree FORMAT A6
COLUMN estimate_percent FORMAT A27
COLUMN global_temp_table_stats FORMAT A23
COLUMN granularity FORMAT A11
COLUMN incremental FORMAT A11
COLUMN incremental_staleness FORMAT A21
COLUMN incremental_level FORMAT A17
COLUMN method_opt FORMAT A25
COLUMN no_invalidate FORMAT A26
COLUMN options FORMAT A7
COLUMN preference_overrides_parameter FORMAT A30
COLUMN publish FORMAT A7
COLUMN options FORMAT A7
COLUMN stale_percent FORMAT A13
COLUMN stat_category FORMAT A28
COLUMN table_cached_blocks FORMAT A19
COLUMN wait_time_to_update_stats FORMAT A19

SELECT DBMS_STATS.GET_PREFS('APPROXIMATE_NDV_ALGORITHM') AS approximate_ndv_algorithm,
       DBMS_STATS.GET_PREFS('AUTO_STAT_EXTENSIONS') AS auto_stat_extensions,
       DBMS_STATS.GET_PREFS('AUTO_TASK_STATUS') AS auto_task_status,
       DBMS_STATS.GET_PREFS('AUTO_TASK_MAX_RUN_TIME') AS auto_task_max_run_time,
       DBMS_STATS.GET_PREFS('AUTO_TASK_INTERVAL') AS auto_task_interval,
       DBMS_STATS.GET_PREFS('CASCADE') AS cascade,
       DBMS_STATS.GET_PREFS('CONCURRENT') AS concurrent,
       DBMS_STATS.GET_PREFS('DEGREE') AS degree,
       DBMS_STATS.GET_PREFS('ESTIMATE_PERCENT') AS estimate_percent,
       DBMS_STATS.GET_PREFS('GLOBAL_TEMP_TABLE_STATS') AS global_temp_table_stats,
       DBMS_STATS.GET_PREFS('GRANULARITY') AS granularity,
       DBMS_STATS.GET_PREFS('INCREMENTAL') AS incremental,
       DBMS_STATS.GET_PREFS('INCREMENTAL_STALENESS') AS incremental_staleness,
       DBMS_STATS.GET_PREFS('INCREMENTAL_LEVEL') AS incremental_level,
       DBMS_STATS.GET_PREFS('METHOD_OPT') AS method_opt,
       DBMS_STATS.GET_PREFS('NO_INVALIDATE') AS no_invalidate,
       DBMS_STATS.GET_PREFS('OPTIONS') AS options,
       DBMS_STATS.GET_PREFS('PREFERENCE_OVERRIDES_PARAMETER') AS preference_overrides_parameter,
       DBMS_STATS.GET_PREFS('PUBLISH') AS publish,
       DBMS_STATS.GET_PREFS('STALE_PERCENT') AS stale_percent,
       DBMS_STATS.GET_PREFS('STAT_CATEGORY') AS stat_category,
       DBMS_STATS.GET_PREFS('TABLE_CACHED_BLOCKS') AS table_cached_blocks,
       DBMS_STATS.GET_PREFS('WAIT_TIME_TO_UPDATE_STATS') AS wait_time_to_update_stats
FROM   dual;
-- End of statistics_prefs.sql --

-- ########## Start of synonyms_to_missing_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/synonyms_to_missing_objects.sql
-- Author       : Tim Hall
-- Description  : Lists all synonyms that point to missing objects.
-- Call Syntax  : @synonyms_to_missing_objects(object-schema-name or all)
-- Requirements : Access to the DBA views.
-- Last Modified: 07/10/2013
-- -----------------------------------------------------------------------------------
SET LINESIZE 1000 VERIFY OFF

SELECT s.owner,
       s.synonym_name,
       s.table_owner, 
       s.table_name
FROM   dba_synonyms s
WHERE  s.db_link IS NULL
AND    s.table_owner NOT IN ('SYS','SYSTEM')
AND    NOT EXISTS (SELECT 1
                   FROM   dba_objects o
                   WHERE  o.owner       = s.table_owner
                   AND    o.object_name = s.table_name
                   AND    o.object_type != 'SYNONYM')
AND    s.table_owner = DECODE(UPPER('&1'), 'ALL', s.table_owner, UPPER('&1'))
ORDER BY s.owner, s.synonym_name;

SET LINESIZE 80 VERIFY ON

-- End of synonyms_to_missing_objects.sql --

-- ########## Start of system_events.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/system_events.sql
-- Author       : Tim Hall
-- Description  : Displays information on all system events.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @system_events
-- Last Modified: 21-FEB-2005
-- -----------------------------------------------------------------------------------
SELECT event,
       total_waits,
       total_timeouts,
       time_waited,
       average_wait,
       time_waited_micro
FROM v$system_event
ORDER BY event;

-- End of system_events.sql --

-- ########## Start of system_parameters.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/system_parameters.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all the system parameters.
--                Comment out isinstance_modifiable for use prior to 10g.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @system_parameters
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500

COLUMN name  FORMAT A30
COLUMN value FORMAT A60

SELECT sp.name,
       sp.type,
       sp.value,
       sp.isses_modifiable,
       sp.issys_modifiable,
       sp.isinstance_modifiable
FROM   v$system_parameter sp
ORDER BY sp.name;


-- End of system_parameters.sql --

-- ########## Start of system_privs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/system_privs.sql
-- Author       : Tim Hall
-- Description  : Displays users granted the specified system privilege.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @system_privs ("sys-priv")
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200 VERIFY OFF

SELECT privilege,
       grantee,
       admin_option
FROM   dba_sys_privs
WHERE  privilege LIKE UPPER('%&1%')
ORDER BY privilege, grantee;

SET VERIFY ON
-- End of system_privs.sql --

-- ########## Start of system_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/system_stats.sql
-- Author       : Tim Hall
-- Description  : Displays system statistics.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @system_stats (statistic-name or all)
-- Last Modified: 03-NOV-2004
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

COLUMN name FORMAT A50
COLUMN value FORMAT 99999999999999999999

SELECT sn.name, ss.value
FROM   v$sysstat ss,
       v$statname sn
WHERE  ss.statistic# = sn.statistic#
AND    sn.name LIKE '%' || DECODE(LOWER('&1'), 'all', '', LOWER('&1')) || '%';

-- End of system_stats.sql --

-- ########## Start of table_dep.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_dep.sql
-- Author       : Tim Hall
-- Description  : Displays a list dependencies for the specified table.
-- Requirements : Access to the ALL views.
-- Call Syntax  : @table_dep (table-name) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
PROMPT
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 255
SET PAGESIZE 1000


SELECT ad.referenced_name "Object",
       ad.name "Ref Object",
       ad.type "Type",
       Substr(ad.referenced_owner,1,10) "Ref Owner",
       Substr(ad.referenced_link_name,1,20) "Ref Link Name"
FROM   all_dependencies ad
WHERE  ad.referenced_name = Upper('&&1')
AND    ad.owner           = Upper('&&2')
ORDER BY 1,2,3;

SET VERIFY ON
SET FEEDBACK ON
SET PAGESIZE 14
PROMPT

-- End of table_dep.sql --

-- ########## Start of table_extents.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_extents.sql
-- Author       : Tim Hall
-- Description  : Displays a list of tables having more than 1 extent.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @table_extents (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT t.table_name,
       Count(e.segment_name) extents,
       t.max_extents,
       t.num_rows "ROWS",
       Trunc(t.initial_extent/1024) "INITIAL K",
       Trunc(t.next_extent/1024) "NEXT K"
FROM   all_tables t,
       dba_extents e
WHERE  e.segment_name = t.table_name
AND    e.owner        = t.owner
AND    t.owner        = Upper('&&1')
GROUP BY t.table_name,
         t.max_extents,
         t.num_rows,
         t.initial_extent,
         t.next_extent
HAVING   Count(e.segment_name) > 1
ORDER BY Count(e.segment_name) DESC;

SET PAGESIZE 18
SET VERIFY ON
-- End of table_extents.sql --

-- ########## Start of table_growth.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_growth.sql
-- Author       : Tim Hall
-- Description  : Displays information on all active database sessions.
-- Requirements : Access to the DBA_HIST views. Diagnostics and Tuning license.
-- Call Syntax  : @table_growth (schema-name) (table_name)
-- Last Modified: 03-DEC-2019
-- -----------------------------------------------------------------------------------
COLUMN object_name FORMAT A30
 
SELECT TO_CHAR(sn.begin_interval_time,'DD-MON-YYYY HH24:MM') AS begin_interval_time,
       sso.object_name,
       ss.space_used_total
FROM   dba_hist_seg_stat ss,
       dba_hist_seg_stat_obj sso,
       dba_hist_snapshot sn
WHERE  sso.owner = UPPER('&1')
AND    sso.obj# = ss.obj#
AND    sn.snap_id = ss.snap_id
AND    sso.object_name LIKE UPPER('&2') || '%'
ORDER BY sn.begin_interval_time;

-- End of table_growth.sql --

-- ########## Start of table_indexes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_indexes.sql
-- Author       : Tim Hall
-- Description  : Displays index-column information for the specified table.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @table_indexes (schema-name) (table-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500 PAGESIZE 1000 VERIFY OFF

COLUMN index_name      FORMAT A30
COLUMN column_name     FORMAT A30
COLUMN column_position FORMAT 99999

SELECT a.index_name,
       a.column_name,
       a.column_position
FROM   all_ind_columns a,
       all_indexes b
WHERE  b.owner      = UPPER('&1')
AND    b.table_name = UPPER('&2')
AND    b.index_name = a.index_name
AND    b.owner      = a.index_owner
ORDER BY 1,3;

SET PAGESIZE 18 VERIFY ON
-- End of table_indexes.sql --

-- ########## Start of table_partitions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_partitions.sql
-- Author       : Tim Hall
-- Description  : Displays partition information for the specified table, or all tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @table_partitions (table-name or all) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET FEEDBACK OFF
SET VERIFY OFF

SELECT a.table_name,
       a.partition_name,
       a.tablespace_name,
       a.initial_extent,
       a.next_extent,
       a.pct_increase,
       a.num_rows,
       a.avg_row_len
FROM   dba_tab_partitions a
WHERE  a.table_name  = Decode(Upper('&&1'),'ALL',a.table_name,Upper('&&1'))
AND    a.table_owner = Upper('&&2')
ORDER BY a.table_name, a.partition_name
/


SET PAGESIZE 14
SET FEEDBACK ON

-- End of table_partitions.sql --

-- ########## Start of table_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_stats.sql
-- Author       : Tim Hall
-- Description  : Displays the table statistics belonging to the specified schema.
-- Requirements : Access to the DBA and v$ views.
-- Call Syntax  : @table_stats (schema-name) (table-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 300 VERIFY OFF

COLUMN owner FORMAT A20
COLUMN table_name FORMAT A30
COLUMN index_name FORMAT A30

SELECT owner,
       table_name,
       num_rows,
       blocks,
       empty_blocks,
       avg_space
       chain_cnt,
       avg_row_len,
       last_analyzed
FROM   dba_tables
WHERE  owner      = UPPER('&1')
AND    table_name = UPPER('&2');

SELECT index_name,
       blevel,
       leaf_blocks,
       distinct_keys,
       avg_leaf_blocks_per_key,
       avg_data_blocks_per_key,
       clustering_factor,
       num_rows,
       last_analyzed
FROM   dba_indexes
WHERE  table_owner = UPPER('&1')
AND    table_name  = UPPER('&2')
ORDER BY index_name;

COLUMN column_name FORMAT A30
COLUMN low_value FORMAT A40
COLUMN high_value FORMAT A40
COLUMN endpoint_actual_value FORMAT A30

SELECT column_id,
       column_name,
       num_distinct,
       avg_col_len,
       histogram,
       low_value,
       high_value
FROM   dba_tab_columns
WHERE  owner       = UPPER('&1')
AND    table_name  = UPPER('&2')
ORDER BY column_id;

SET VERIFY ON

-- End of table_stats.sql --

-- ########## Start of table_triggers.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/table_triggers.sql
-- Author       : Tim Hall
-- Description  : Lists the triggers for the specified table.
-- Call Syntax  : @table_triggers (schema) (table_name)
-- Last Modified: 07/11/2016
-- -----------------------------------------------------------------------------------
SELECT owner,
       trigger_name,
       status
FROM   dba_triggers
WHERE  table_owner = UPPER('&1')
AND    table_name = UPPER('&2');
-- End of table_triggers.sql --

-- ########## Start of tables_with_locked_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/tables_with_locked_stats.sql
-- Author       : Tim Hall
-- Description  : Displays tables with locked stats.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @tables_with_locked_stats.sql
-- Last Modified: 06-DEC-2013
-- -----------------------------------------------------------------------------------

SELECT owner,
       table_name,
       stattype_locked
FROM   dba_tab_statistics
WHERE  stattype_locked IS NOT NULL
ORDER BY owner, table_name;

-- End of tables_with_locked_stats.sql --

-- ########## Start of tables_with_zero_rows.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/tables_with_zero_rows.sql
-- Author       : Tim Hall
-- Description  : Displays tables with stats saying they have zero rows.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @tables_with_zero_rows.sql
-- Last Modified: 06-DEC-2013
-- -----------------------------------------------------------------------------------

SELECT owner,
       table_name,
       last_analyzed,
       num_rows
FROM   dba_tables
WHERE  num_rows = 0
AND    owner NOT IN ('SYS','SYSTEM','SYSMAN','XDB','MDSYS',
                     'WMSYS','OUTLN','ORDDATA','ORDSYS',
                     'OLAPSYS','EXFSYS','DBNSMP','CTXSYS',
                     'APEX_030200','FLOWS_FILES','SCOTT',
                     'TSMSYS','DBSNMP','APPQOSSYS','OWBSYS',
                     'DMSYS','FLOWS_030100','WKSYS','WK_TEST')
ORDER BY owner, table_name;

-- End of tables_with_zero_rows.sql --

-- ########## Start of tablespaces.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/tablespaces.sql
-- Author       : Tim Hall
-- Description  : Displays information about tablespaces.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @tablespaces
-- Last Modified: 17-AUG-2005
-- -----------------------------------------------------------------------------------

SET LINESIZE 200

SELECT tablespace_name,
       block_size,
       extent_management,
       allocation_type,
       segment_space_management,
       status
FROM   dba_tablespaces
ORDER BY tablespace_name;

-- End of tablespaces.sql --

-- ########## Start of temp_extent_map.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/temp_extent_map.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays temp extents and their locations within the tablespace allowing identification of tablespace fragmentation.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @temp_extent_map (tablespace-name)
-- Last Modified: 25/01/2003
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE 1000000
SET FEEDBACK OFF
SET TRIMOUT ON
SET VERIFY OFF

DECLARE
  CURSOR c_extents IS
    SELECT d.name,
           t.block_id AS start_block,
           t.block_id + t.blocks - 1 AS end_block
    FROM   v$temp_extent_map t,
           v$tempfile d
    WHERE  t.file_id = d.file#
    AND    t.tablespace_name = Upper('&1')
    ORDER BY d.name, t.block_id;
    
  l_last_block_id  NUMBER  := 0;
  l_gaps_only      BOOLEAN := TRUE;
BEGIN
  FOR cur_rec IN c_extents LOOP
    IF cur_rec.start_block > l_last_block_id + 1 THEN
      DBMS_OUTPUT.PUT_LINE('*** GAP *** (' || l_last_block_id || ' -> ' || cur_rec.start_block || ')');
    END IF;
    l_last_block_id := cur_rec.end_block;
    IF NOT l_gaps_only THEN
      DBMS_OUTPUT.PUT_LINE(RPAD(cur_rec.name, 50, ' ') || 
                           ' (' || cur_rec.start_block || ' -> ' || cur_rec.end_block || ')');
    END IF;
  END LOOP;
END;
/

PROMPT
SET FEEDBACK ON
SET PAGESIZE 18



-- End of temp_extent_map.sql --

-- ########## Start of temp_free_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/temp_free_space.sql
-- Author       : Tim Hall
-- Description  : Displays temp space usage for each datafile.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @temp_free_space
-- Last Modified: 15-JUL-2000 - Created.
--                13-OCT-2012 - Amended to include auto-extend and maxsize.
-- -----------------------------------------------------------------------------------
SET LINESIZE 255

COLUMN tablespace_name FORMAT A20
COLUMN file_name FORMAT A40

SELECT tf.tablespace_name,
       tf.file_name,
       tf.size_mb,
       f.free_mb,
       tf.max_size_mb,
       f.free_mb + (tf.max_size_mb - tf.size_mb) AS max_free_mb,
       RPAD(' '|| RPAD('X',ROUND((tf.max_size_mb-(f.free_mb + (tf.max_size_mb - tf.size_mb)))/max_size_mb*10,0), 'X'),11,'-') AS used_pct
FROM   (SELECT file_id,
               file_name,
               tablespace_name,
               TRUNC(bytes/1024/1024) AS size_mb,
               TRUNC(GREATEST(bytes,maxbytes)/1024/1024) AS max_size_mb
        FROM   dba_temp_files) tf,
       (SELECT TRUNC(SUM(bytes)/1024/1024) AS free_mb,
               file_id
        FROM dba_free_space
        GROUP BY file_id) f
WHERE  tf.file_id = f.file_id (+)
ORDER BY tf.tablespace_name,
         tf.file_name;

SET PAGESIZE 14
-- End of temp_free_space.sql --

-- ########## Start of temp_io.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/temp_io.sql
-- Author       : Tim Hall
-- Description  : Displays the amount of IO for each tempfile.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @temp_io
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET PAGESIZE 1000

SELECT SUBSTR(t.name,1,50) AS file_name,
       f.phyblkrd AS blocks_read,
       f.phyblkwrt AS blocks_written,
       f.phyblkrd + f.phyblkwrt AS total_io
FROM   v$tempstat f,
       v$tempfile t
WHERE  t.file# = f.file#
ORDER BY f.phyblkrd + f.phyblkwrt DESC;

SET PAGESIZE 18
-- End of temp_io.sql --

-- ########## Start of temp_segments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/temp_segments.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all temporary segments.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @temp_segments
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500

SELECT owner,
       Trunc(Sum(bytes)/1024) Kb
FROM   dba_segments 
WHERE  segment_type = 'TEMPORARY'
GROUP BY owner;

-- End of temp_segments.sql --

-- ########## Start of temp_usage.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/temp_usage.sql
-- Author       : Tim Hall
-- Description  : Displays temp usage for all session currently using temp space.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @temp_usage
-- Last Modified: 12/02/2004
-- -----------------------------------------------------------------------------------


COLUMN temp_used FORMAT 9999999999

SELECT NVL(s.username, '(background)') AS username,
       s.sid,
       s.serial#,
       ROUND(ss.value/1024/1024, 2) AS temp_used_mb
FROM   v$session s
       JOIN v$sesstat ss ON s.sid = ss.sid
       JOIN v$statname sn ON ss.statistic# = sn.statistic#
WHERE  sn.name = 'temp space allocated (bytes)'
AND    ss.value > 0
ORDER BY 1;

-- End of temp_usage.sql --

-- ########## Start of tempfiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/tempfiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about tempfiles.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @tempfiles
-- Last Modified: 17-AUG-2005
-- -----------------------------------------------------------------------------------

SET LINESIZE 200
COLUMN file_name FORMAT A70

SELECT file_id,
       file_name,
       ROUND(bytes/1024/1024/1024) AS size_gb,
       ROUND(maxbytes/1024/1024/1024) AS max_size_gb,
       autoextensible,
       increment_by,
       status
FROM   dba_temp_files
ORDER BY file_name;

-- End of tempfiles.sql --

-- ########## Start of tempseg_usage.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/tempseg_usage.sql
-- Author       : Tim Hall
-- Description  : Displays temp segment usage for all session currently using temp space.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @tempseg_usage
-- Last Modified: 01/04/2006
-- -----------------------------------------------------------------------------------

SET LINESIZE 200
COLUMN username FORMAT A20

SELECT username,
       session_addr,
       session_num,
       sqladdr,
       sqlhash,
       sql_id,
       contents,
       segtype,
       extents,
       blocks
FROM   v$tempseg_usage
ORDER BY username;
-- End of tempseg_usage.sql --

-- ########## Start of top_latches.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/top_latches.sql
-- Author       : Tim Hall
-- Description  : Displays information about the top latches.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @top_latches
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

SELECT l.latch#,
       l.name,
       l.gets,
       l.misses,
       l.sleeps,
       l.immediate_gets,
       l.immediate_misses,
       l.spin_gets
FROM   v$latch l
WHERE  l.misses > 0
ORDER BY l.misses DESC;

-- End of top_latches.sql --

-- ########## Start of top_sessions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/top_sessions.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database sessions ordered by executions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @top_sessions.sql (reads, execs or cpu)
-- Last Modified: 21/02/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

COLUMN username FORMAT A15
COLUMN machine FORMAT A25
COLUMN logon_time FORMAT A20

SELECT NVL(a.username, '(oracle)') AS username,
       a.osuser,
       a.sid,
       a.serial#,
       c.value AS &1,
       a.lockwait,
       a.status,
       a.module,
       a.machine,
       a.program,
       TO_CHAR(a.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time
FROM   v$session a,
       v$sesstat c,
       v$statname d
WHERE  a.sid        = c.sid
AND    c.statistic# = d.statistic#
AND    d.name       = DECODE(UPPER('&1'), 'READS', 'session logical reads',
                                          'EXECS', 'execute count',
                                          'CPU',   'CPU used by this session',
                                                   'CPU used by this session')
ORDER BY c.value DESC;

SET PAGESIZE 14

-- End of top_sessions.sql --

-- ########## Start of top_sql.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/top_sql.sql
-- Author       : Tim Hall
-- Description  : Displays a list of SQL statements that are using the most resources.
-- Comments     : The address column can be use as a parameter with SQL_Text.sql to display the full statement.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @top_sql (number)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

SELECT *
FROM   (SELECT Substr(a.sql_text,1,50) sql_text,
               Trunc(a.disk_reads/Decode(a.executions,0,1,a.executions)) reads_per_execution, 
               a.buffer_gets, 
               a.disk_reads, 
               a.executions, 
               a.sorts,
               a.address
        FROM   v$sqlarea a
        ORDER BY 2 DESC)
WHERE  rownum <= &&1;

SET PAGESIZE 14

-- End of top_sql.sql --

-- ########## Start of trace_run_details.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/trace_run_details.sql
-- Author       : Tim Hall
-- Description  : Displays details of a specified trace run.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @trace_run_details.sql (runid)
-- Last Modified: 06/05/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET TRIMOUT ON

COLUMN runid FORMAT 99999
COLUMN event_seq FORMAT 99999
COLUMN event_unit_owner FORMAT A20
COLUMN event_unit FORMAT A20
COLUMN event_unit_kind FORMAT A20
COLUMN event_comment FORMAT A30

SELECT e.runid,
       e.event_seq,
       TO_CHAR(e.event_time, 'DD-MON-YYYY HH24:MI:SS') AS event_time,
       e.event_unit_owner,
       e.event_unit,
       e.event_unit_kind,
       e.proc_line,
       e.event_comment
FROM   plsql_trace_events e
WHERE  e.runid = &1
ORDER BY e.runid, e.event_seq;
-- End of trace_run_details.sql --

-- ########## Start of trace_runs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/trace_runs.sql
-- Author       : Tim Hall
-- Description  : Displays information on all trace runs.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @trace_runs.sql
-- Last Modified: 06/05/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET TRIMOUT ON

COLUMN runid FORMAT 99999

SELECT runid,
       run_date,
       run_owner
FROM   plsql_trace_runs
ORDER BY runid;
-- End of trace_runs.sql --

-- ########## Start of ts_datafiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_datafiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about datafiles for the specified tablespace.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @ts_datafiles (tablespace-name)
-- Last Modified: 17-AUG-2005
-- -----------------------------------------------------------------------------------

SET LINESIZE 200
COLUMN file_name FORMAT A70

SELECT file_id,
       file_name,
       ROUND(bytes/1024/1024/1024) AS size_gb,
       ROUND(maxbytes/1024/1024/1024) AS max_size_gb,
       autoextensible,
       increment_by,
       status
FROM   dba_data_files
WHERE  tablespace_name = UPPER('&1')
ORDER BY file_id;

-- End of ts_datafiles.sql --

-- ########## Start of ts_extent_map.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_extent_map.sql
-- Author       : Tim Hall
-- Description  : Displays gaps (empty space) in a tablespace or specific datafile.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @ts_extent_map (tablespace-name) [all | file_id]
-- Last Modified: 25/01/2003
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE 1000000
SET FEEDBACK OFF
SET TRIMOUT ON
SET VERIFY OFF

DECLARE
  l_tablespace_name VARCHAR2(30) := UPPER('&1');
  l_file_id         VARCHAR2(30) := UPPER('&2');

  CURSOR c_extents IS
    SELECT owner,
           segment_name,
           file_id,
           block_id AS start_block,
           block_id + blocks - 1 AS end_block
    FROM   dba_extents
    WHERE  tablespace_name = l_tablespace_name
    AND    file_id = DECODE(l_file_id, 'ALL', file_id, TO_NUMBER(l_file_id))
    ORDER BY file_id, block_id;

  l_block_size     NUMBER  := 0;
  l_last_file_id   NUMBER  := 0;
  l_last_block_id  NUMBER  := 0;
  l_gaps_only      BOOLEAN := TRUE;
  l_total_blocks   NUMBER  := 0;
BEGIN
  SELECT block_size
  INTO   l_block_size
  FROM   dba_tablespaces
  WHERE  tablespace_name = l_tablespace_name;

  DBMS_OUTPUT.PUT_LINE('Tablespace Block Size (bytes): ' || l_block_size);
  FOR cur_rec IN c_extents LOOP
    IF cur_rec.file_id != l_last_file_id THEN
      l_last_file_id  := cur_rec.file_id;
      l_last_block_id := cur_rec.start_block - 1;
    END IF;
    
    IF cur_rec.start_block > l_last_block_id + 1 THEN
      DBMS_OUTPUT.PUT_LINE('*** GAP *** (' || l_last_block_id || ' -> ' || cur_rec.start_block || ')' ||
        ' FileID=' || cur_rec.file_id ||
        ' Blocks=' || (cur_rec.start_block-l_last_block_id-1) || 
        ' Size(MB)=' || ROUND(((cur_rec.start_block-l_last_block_id-1) * l_block_size)/1024/1024,2)
      );
      l_total_blocks := l_total_blocks + cur_rec.start_block - l_last_block_id-1;
    END IF;
    l_last_block_id := cur_rec.end_block;
    IF NOT l_gaps_only THEN
      DBMS_OUTPUT.PUT_LINE(RPAD(cur_rec.owner || '.' || cur_rec.segment_name, 40, ' ') ||
                           ' (' || cur_rec.start_block || ' -> ' || cur_rec.end_block || ')');
    END IF;
  END LOOP;
  DBMS_OUTPUT.PUT_LINE('Total Gap Blocks: ' || l_total_blocks);
  DBMS_OUTPUT.PUT_LINE('Total Gap Space (MB): ' || ROUND((l_total_blocks * l_block_size)/1024/1024,2));
END;
/

PROMPT
SET FEEDBACK ON

-- End of ts_extent_map.sql --

-- ########## Start of ts_free_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_free_space.sql
-- Author       : Tim Hall
-- Description  : Displays a list of tablespaces and their used/full status.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @ts_free_space.sql
-- Last Modified: 13-OCT-2012 - Created. Based on ts_full.sql
--                22-SEP-2017 - LINESIZE set.
-- -----------------------------------------------------------------------------------
SET PAGESIZE 140 LINESIZE 200
COLUMN used_pct FORMAT A11

SELECT tablespace_name,
       size_mb,
       free_mb,
       max_size_mb,
       max_free_mb,
       TRUNC((max_free_mb/max_size_mb) * 100) AS free_pct,
       RPAD(' '|| RPAD('X',ROUND((max_size_mb-max_free_mb)/max_size_mb*10,0), 'X'),11,'-') AS used_pct
FROM   (
        SELECT a.tablespace_name,
               b.size_mb,
               a.free_mb,
               b.max_size_mb,
               a.free_mb + (b.max_size_mb - b.size_mb) AS max_free_mb
        FROM   (SELECT tablespace_name,
                       TRUNC(SUM(bytes)/1024/1024) AS free_mb
                FROM   dba_free_space
                GROUP BY tablespace_name) a,
               (SELECT tablespace_name,
                       TRUNC(SUM(bytes)/1024/1024) AS size_mb,
                       TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
                FROM   dba_data_files
                GROUP BY tablespace_name) b
        WHERE  a.tablespace_name = b.tablespace_name
       )
ORDER BY tablespace_name;

SET PAGESIZE 14
-- End of ts_free_space.sql --

-- ########## Start of ts_full.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_full.sql
-- Author       : Tim Hall
-- Description  : Displays a list of tablespaces that are nearly full.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @ts_full
-- Last Modified: 15-JUL-2000 - Created.
-                 13-OCT-2012 - Included support for auto-extend and maxsize.
-- -----------------------------------------------------------------------------------
SET PAGESIZE 100

PROMPT Tablespaces nearing 0% free
PROMPT ***************************
SELECT tablespace_name,
       size_mb,
       free_mb,
       max_size_mb,
       max_free_mb,
       TRUNC((max_free_mb/max_size_mb) * 100) AS free_pct
FROM   (
        SELECT a.tablespace_name,
               b.size_mb,
               a.free_mb,
               b.max_size_mb,
               a.free_mb + (b.max_size_mb - b.size_mb) AS max_free_mb
        FROM   (SELECT tablespace_name,
                       TRUNC(SUM(bytes)/1024/1024) AS free_mb
                FROM   dba_free_space
                GROUP BY tablespace_name) a,
               (SELECT tablespace_name,
                       TRUNC(SUM(bytes)/1024/1024) AS size_mb,
                       TRUNC(SUM(GREATEST(bytes,maxbytes))/1024/1024) AS max_size_mb
                FROM   dba_data_files
                GROUP BY tablespace_name) b
        WHERE  a.tablespace_name = b.tablespace_name
       )
WHERE  ROUND((max_free_mb/max_size_mb) * 100,2) < 10;

SET PAGESIZE 14
-- End of ts_full.sql --

-- ########## Start of ts_thresholds.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_thresholds.sql
-- Author       : Tim Hall
-- Description  : Displays threshold information for tablespaces.
-- Call Syntax  : @ts_thresholds
-- Last Modified: 13/02/2014 - Created
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN metrics_name FORMAT A30
COLUMN warning_value FORMAT A30
COLUMN critical_value FORMAT A15

SELECT tablespace_name,
       contents,
       extent_management,
       threshold_type,
       metrics_name,
       warning_operator,
       warning_value,
       critical_operator,
       critical_value
FROM   dba_tablespace_thresholds
ORDER BY tablespace_name, metrics_name;

SET LINESIZE 80

-- End of ts_thresholds.sql --

-- ########## Start of ts_thresholds_reset.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_thresholds_reset.sql
-- Author       : Tim Hall
-- Description  : Displays threshold information for tablespaces.
-- Call Syntax  : @ts_thresholds_reset (warning) (critical)
--                @ts_thresholds_reset NULL NULL    -- To reset to defaults
-- Last Modified: 13/02/2014 - Created
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

DECLARE
  g_warning_value      VARCHAR2(4) := '&1';
  g_warning_operator   VARCHAR2(4) := DBMS_SERVER_ALERT.OPERATOR_GE;
  g_critical_value     VARCHAR2(4) := '&2';
  g_critical_operator  VARCHAR2(4) := DBMS_SERVER_ALERT.OPERATOR_GE;

  PROCEDURE set_threshold(p_ts_name  IN VARCHAR2) AS
  BEGIN
    DBMS_SERVER_ALERT.SET_THRESHOLD(
      metrics_id              => DBMS_SERVER_ALERT.TABLESPACE_PCT_FULL,
      warning_operator        => g_warning_operator,
      warning_value           => g_warning_value,
      critical_operator       => g_critical_operator,
      critical_value          => g_critical_value,
      observation_period      => 1,
      consecutive_occurrences => 1,
      instance_name           => NULL,
      object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_TABLESPACE,
      object_name             => p_ts_name);
  END;
BEGIN
  IF g_warning_value  = 'NULL' THEN
    g_warning_value    := NULL;
    g_warning_operator := NULL;
  END IF;
  IF g_critical_value = 'NULL' THEN
    g_critical_value    := NULL;
    g_critical_operator := NULL;
  END IF;

  FOR cur_ts IN (SELECT tablespace_name
                 FROM   dba_tablespace_thresholds
                 WHERE  warning_operator != 'DO NOT CHECK'
                 AND    extent_management = 'LOCAL')
  LOOP
    set_threshold(cur_ts.tablespace_name);
  END LOOP;
END;
/

SET VERIFY ON
-- End of ts_thresholds_reset.sql --

-- ########## Start of ts_thresholds_set_default.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/ts_thresholds_set_default.sql
-- Author       : Tim Hall
-- Description  : Displays threshold information for tablespaces.
-- Call Syntax  : @ts_thresholds_set_default (warning) (critical)
-- Last Modified: 13/02/2014 - Created
-- -----------------------------------------------------------------------------------
SET VERIFY OFF

DECLARE
  l_warning  VARCHAR2(2) := '&1';
  l_critical VARCHAR2(2) := '&2';
BEGIN
    DBMS_SERVER_ALERT.SET_THRESHOLD(
      metrics_id              => DBMS_SERVER_ALERT.TABLESPACE_PCT_FULL,
      warning_operator        => DBMS_SERVER_ALERT.OPERATOR_GE,
      warning_value           => l_warning,
      critical_operator       => DBMS_SERVER_ALERT.OPERATOR_GE,
      critical_value          => l_critical,
      observation_period      => 1,
      consecutive_occurrences => 1,
      instance_name           => NULL,
      object_type             => DBMS_SERVER_ALERT.OBJECT_TYPE_TABLESPACE,
      object_name             => NULL);
END;
/

SET VERIFY ON
-- End of ts_thresholds_set_default.sql --

-- ########## Start of tuning.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/tuning.sql
-- Author       : Tim Hall
-- Description  : Displays several performance indicators and comments on the value.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @tuning
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 1000
SET FEEDBACK OFF

SELECT *
FROM   v$database;
PROMPT

DECLARE
  v_value  NUMBER;

  FUNCTION Format(p_value  IN  NUMBER) 
    RETURN VARCHAR2 IS
  BEGIN
    RETURN LPad(To_Char(Round(p_value,2),'990.00') || '%',8,' ') || '  ';
  END;

BEGIN

  -- --------------------------
  -- Dictionary Cache Hit Ratio
  -- --------------------------
  SELECT (1 - (Sum(getmisses)/(Sum(gets) + Sum(getmisses)))) * 100
  INTO   v_value
  FROM   v$rowcache;

  DBMS_Output.Put('Dictionary Cache Hit Ratio       : ' || Format(v_value));
  IF v_value < 90 THEN
    DBMS_Output.Put_Line('Increase SHARED_POOL_SIZE parameter to bring value above 90%');
  ELSE
    DBMS_Output.Put_Line('Value Acceptable.');  
  END IF;

  -- -----------------------
  -- Library Cache Hit Ratio
  -- -----------------------
  SELECT (1 -(Sum(reloads)/(Sum(pins) + Sum(reloads)))) * 100
  INTO   v_value
  FROM   v$librarycache;

  DBMS_Output.Put('Library Cache Hit Ratio          : ' || Format(v_value));
  IF v_value < 99 THEN
    DBMS_Output.Put_Line('Increase SHARED_POOL_SIZE parameter to bring value above 99%');
  ELSE
    DBMS_Output.Put_Line('Value Acceptable.');  
  END IF;

  -- -------------------------------
  -- DB Block Buffer Cache Hit Ratio
  -- -------------------------------
  SELECT (1 - (phys.value / (db.value + cons.value))) * 100
  INTO   v_value
  FROM   v$sysstat phys,
         v$sysstat db,
         v$sysstat cons
  WHERE  phys.name  = 'physical reads'
  AND    db.name    = 'db block gets'
  AND    cons.name  = 'consistent gets';

  DBMS_Output.Put('DB Block Buffer Cache Hit Ratio  : ' || Format(v_value));
  IF v_value < 89 THEN
    DBMS_Output.Put_Line('Increase DB_BLOCK_BUFFERS parameter to bring value above 89%');
  ELSE
    DBMS_Output.Put_Line('Value Acceptable.');  
  END IF;
  
  -- ---------------
  -- Latch Hit Ratio
  -- ---------------
  SELECT (1 - (Sum(misses) / Sum(gets))) * 100
  INTO   v_value
  FROM   v$latch;

  DBMS_Output.Put('Latch Hit Ratio                  : ' || Format(v_value));
  IF v_value < 98 THEN
    DBMS_Output.Put_Line('Increase number of latches to bring the value above 98%');
  ELSE
    DBMS_Output.Put_Line('Value acceptable.');
  END IF;

  -- -----------------------
  -- Disk Sort Ratio
  -- -----------------------
  SELECT (disk.value/mem.value) * 100
  INTO   v_value
  FROM   v$sysstat disk,
         v$sysstat mem
  WHERE  disk.name = 'sorts (disk)'
  AND    mem.name  = 'sorts (memory)';

  DBMS_Output.Put('Disk Sort Ratio                  : ' || Format(v_value));
  IF v_value > 5 THEN
    DBMS_Output.Put_Line('Increase SORT_AREA_SIZE parameter to bring value below 5%');
  ELSE
    DBMS_Output.Put_Line('Value Acceptable.');  
  END IF;
  
  -- ----------------------
  -- Rollback Segment Waits
  -- ----------------------
  SELECT (Sum(waits) / Sum(gets)) * 100
  INTO   v_value
  FROM   v$rollstat;

  DBMS_Output.Put('Rollback Segment Waits           : ' || Format(v_value));
  IF v_value > 5 THEN
    DBMS_Output.Put_Line('Increase number of Rollback Segments to bring the value below 5%');
  ELSE
    DBMS_Output.Put_Line('Value acceptable.');
  END IF;

  -- -------------------
  -- Dispatcher Workload
  -- -------------------
  SELECT NVL((Sum(busy) / (Sum(busy) + Sum(idle))) * 100,0)
  INTO   v_value
  FROM   v$dispatcher;

  DBMS_Output.Put('Dispatcher Workload              : ' || Format(v_value));
  IF v_value > 50 THEN
    DBMS_Output.Put_Line('Increase MTS_DISPATCHERS to bring the value below 50%');
  ELSE
    DBMS_Output.Put_Line('Value acceptable.');
  END IF;
  
END;
/

PROMPT
SET FEEDBACK ON

-- End of tuning.sql --

-- ########## Start of undo_segments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/undo_segments.sql
-- Author       : Tim Hall
-- Description  : Displays information about undo segments.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @undo_segments {name | all}
-- Last Modified: 20-APR-2021
-- -----------------------------------------------------------------------------------

set verify off linesize 100
column owner format a30
column segment_name format a30
column segment_type format a20

select owner,
       segment_name,
       segment_type
from   dba_segments
where  segment_type in ('TYPE2 UNDO','ROLLBACK')
and    lower(segment_name) like '%' || decode(lower('&1'), 'all', '', lower('&1')) || '%'
order by 1, 2;
-- End of undo_segments.sql --

-- ########## Start of unusable_indexes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/unusable_indexes.sql
-- Author       : Tim Hall
-- Description  : Displays unusable indexes for the specified schema or all schemas.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @unusable_indexes (schema-name or all)
-- Last Modified: 28/01/2018
-- -----------------------------------------------------------------------------------
SET VERIFY OFF LINESIZE 200

COLUMN owner FORMAT A30
COLUMN index_name FORMAT A30
COLUMN table_owner FORMAT A30
COLUMN table_name FORMAT A30

SELECT owner,
       index_name,
       index_type,
       table_owner,
       table_name
       table_type
FROM   dba_indexes
WHERE  owner = DECODE(UPPER('&1'), 'ALL', owner, UPPER('&1'))
AND    status NOT IN ('VALID', 'N/A')
ORDER BY owner, index_name;


-- End of unusable_indexes.sql --

-- ########## Start of unused_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/unused_space.sql
-- Author       : Tim Hall
-- Description  : Displays unused space for each segment.
-- Requirements : Access to the DBMS_SPACE package.
-- Call Syntax  : @unused_space (segment_owner) (segment_name) (segment_type) (partition_name OR NA)
-- Last Modified: 16/05/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET VERIFY OFF
DECLARE
  v_partition_name            VARCHAR2(30) := UPPER('&4');
  v_total_blocks              NUMBER;
  v_total_bytes               NUMBER;
  v_unused_blocks             NUMBER;
  v_unused_bytes              NUMBER;
  v_last_used_extent_file_id  NUMBER;
  v_last_used_extent_block_id NUMBER;
  v_last_used_block           NUMBER;
BEGIN
  IF v_partition_name != 'NA' THEN
    DBMS_SPACE.UNUSED_SPACE (segment_owner              => UPPER('&1'), 
                             segment_name               => UPPER('&2'),
                             segment_type               => UPPER('&3'),
                             total_blocks               => v_total_blocks,
                             total_bytes                => v_total_bytes,
                             unused_blocks              => v_unused_blocks,
                             unused_bytes               => v_unused_bytes,
                             last_used_extent_file_id   => v_last_used_extent_file_id,
                             last_used_extent_block_id  => v_last_used_extent_block_id,
                             last_used_block            => v_last_used_block,
                             partition_name             => v_partition_name);
  ELSE
    DBMS_SPACE.UNUSED_SPACE (segment_owner              => UPPER('&1'), 
                             segment_name               => UPPER('&2'),
                             segment_type               => UPPER('&3'),
                             total_blocks               => v_total_blocks,
                             total_bytes                => v_total_bytes,
                             unused_blocks              => v_unused_blocks,
                             unused_bytes               => v_unused_bytes,
                             last_used_extent_file_id   => v_last_used_extent_file_id,
                             last_used_extent_block_id  => v_last_used_extent_block_id,
                             last_used_block            => v_last_used_block);
  END IF;

  DBMS_OUTPUT.PUT_LINE('v_total_blocks              :' || v_total_blocks);
  DBMS_OUTPUT.PUT_LINE('v_total_bytes               :' || v_total_bytes);
  DBMS_OUTPUT.PUT_LINE('v_unused_blocks             :' || v_unused_blocks);
  DBMS_OUTPUT.PUT_LINE('v_unused_bytes              :' || v_unused_bytes);
  DBMS_OUTPUT.PUT_LINE('v_last_used_extent_file_id  :' || v_last_used_extent_file_id);
  DBMS_OUTPUT.PUT_LINE('v_last_used_extent_block_id :' || v_last_used_extent_block_id);
  DBMS_OUTPUT.PUT_LINE('v_last_used_block           :' || v_last_used_block);
END;
/


-- End of unused_space.sql --

-- ########## Start of user_hit_ratio.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/user_hit_ratio.sql
-- Author       : Tim Hall
-- Description  : Displays the Cache Hit Ratio per user.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @user_hit_ratio
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
COLUMN "Hit Ratio %" FORMAT 999.99

SELECT a.username "Username",
       b.consistent_gets "Consistent Gets",
       b.block_gets "DB Block Gets",
       b.physical_reads "Physical Reads",
       Round(100* (b.consistent_gets + b.block_gets - b.physical_reads) /
       (b.consistent_gets + b.block_gets),2) "Hit Ratio %"
FROM   v$session a,
       v$sess_io b
WHERE  a.sid = b.sid
AND    (b.consistent_gets + b.block_gets) > 0
AND    a.username IS NOT NULL;

-- End of user_hit_ratio.sql --

-- ########## Start of user_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/monitoring/user_objects.sql
-- Author       : Tim Hall
-- Description  : Displays the objects owned by the current user.
-- Requirements : 
-- Call Syntax  : @user_objects
-- Last Modified: 23-OCT-2019
-- -----------------------------------------------------------------------------------

COLUMN object_name FORMAT A30

SELECT object_name, object_type
FROM   user_objects
ORDER BY 1, 2;

-- End of user_objects.sql --

-- ########## Start of user_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/user_roles.sql
-- Author       : Tim Hall
-- Description  : Displays a list of all roles and privileges granted to the specified user.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @user_roles (username)
-- Last Modified: 26/06/2023
-- -----------------------------------------------------------------------------------
set serveroutput on
set verify off

select a.granted_role,
       a.admin_option
from   dba_role_privs a
where  a.grantee = upper('&1')
order by a.granted_role;

select a.privilege,
       a.admin_option
from   dba_sys_privs a
where  a.grantee = upper('&1')
order by a.privilege;
               
set verify on

-- End of user_roles.sql --

-- ########## Start of user_sessions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/user_sessions.sql
-- Author       : Tim Hall
-- Description  : Displays information on all user database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @user_sessions
-- Last Modified: 16-MAY-2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A30
COLUMN osuser FORMAT A20
COLUMN spid FORMAT A10
COLUMN service_name FORMAT A15
COLUMN module FORMAT A45
COLUMN machine FORMAT A30
COLUMN logon_time FORMAT A20

SELECT s.username,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.service_name,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time,
       s.last_call_et AS last_call_et_secs,
       s.module,
       s.action,
       s.client_info,
       s.client_identifier
FROM   v$session s,
       v$process p
WHERE  s.paddr = p.addr
AND    s.username IS NOT NULL
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of user_sessions.sql --

-- ########## Start of user_system_privs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/user_system_privs.sql
-- Author       : Tim Hall
-- Description  : Displays system privileges granted to a specified user.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @user_system_privs (user-name)
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200 VERIFY OFF

SELECT grantee,
       privilege,
       admin_option
FROM   dba_sys_privs
WHERE  grantee = UPPER('&1')
ORDER BY grantee, privilege;

SET VERIFY ON
-- End of user_system_privs.sql --

-- ########## Start of user_temp_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/monitoring/user_temp_space.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays the temp space currently in use by users.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @user_temp_space
-- Last Modified: 12/02/2004
-- -----------------------------------------------------------------------------------

COLUMN tablespace FORMAT A20
COLUMN temp_size FORMAT A20
COLUMN sid_serial FORMAT A20
COLUMN username FORMAT A20
COLUMN program FORMAT A40
SET LINESIZE 200

SELECT b.tablespace,
       ROUND(((b.blocks*p.value)/1024/1024),2)||'M' AS temp_size,
       a.sid||','||a.serial# AS sid_serial,
       NVL(a.username, '(oracle)') AS username,
       a.program
FROM   v$session a,
       v$sort_usage b,
       v$parameter p
WHERE  p.name  = 'db_block_size'
AND    a.saddr = b.session_addr
ORDER BY b.tablespace, b.blocks;

-- End of user_temp_space.sql --

-- ########## Start of user_ts_quotas.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/user_ts_quotas.sql
-- Author       : Tim Hall
-- Description  : Displays tablespaces the user has quotas on.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @user_ts_quotas {username}
-- Last Modified: 16-JAN-2024
-- -----------------------------------------------------------------------------------

set verify off
column tablespace_name format a30

select tablespace_name, blocks, max_blocks
from   dba_ts_quotas
where  username = decode(upper('&1'), 'all', username, upper('&1'))
order by 1;

-- End of user_ts_quotas.sql --

-- ########## Start of user_undo_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/user_undo_space.sql
-- Author       : Tim Hall
-- Description  : Displays the undo space currently in use by users.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @user_undo_space
-- Last Modified: 12/02/2004
-- -----------------------------------------------------------------------------------

COLUMN sid_serial FORMAT A20
COLUMN username FORMAT A20
COLUMN program FORMAT A30
COLUMN undoseg FORMAT A25
COLUMN undo FORMAT A20
SET LINESIZE 120

SELECT TO_CHAR(s.sid)||','||TO_CHAR(s.serial#) AS sid_serial,
       NVL(s.username, '(oracle)') AS username,
       s.program,
       r.name undoseg,
       t.used_ublk * TO_NUMBER(x.value)/1024||'K' AS undo
FROM   v$rollname    r,
       v$session     s,
       v$transaction t,
       v$parameter   x
WHERE  s.taddr = t.addr
AND    r.usn   = t.xidusn(+)
AND    x.name  = 'db_block_size';
-- End of user_undo_space.sql --

-- ########## Start of users.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/users.sql
-- Author       : Tim Hall
-- Description  : Displays information about all database users.
-- Requirements : Access to the dba_users view.
-- Call Syntax  : @users [ username | % (for all)]
-- Last Modified: 21-FEB-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200 VERIFY OFF

COLUMN username FORMAT A20
COLUMN account_status FORMAT A16
COLUMN default_tablespace FORMAT A15
COLUMN temporary_tablespace FORMAT A15
COLUMN profile FORMAT A15

SELECT username,
       account_status,
       TO_CHAR(lock_date, 'DD-MON-YYYY') AS lock_date,
       TO_CHAR(expiry_date, 'DD-MON-YYYY') AS expiry_date,
       default_tablespace,
       temporary_tablespace,
       TO_CHAR(created, 'DD-MON-YYYY') AS created,
       profile,
       initial_rsrc_consumer_group,
       editions_enabled,
       authentication_type
FROM   dba_users
WHERE  username LIKE UPPER('%&1%')
ORDER BY username;

SET VERIFY ON
-- End of users.sql --

-- ########## Start of users_with_role.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/users_with_role.sql
-- Author       : Tim Hall
-- Description  : Displays a list of users granted the specified role.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @user_with_role DBA
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------

SET VERIFY OFF
COLUMN username FORMAT A30

SELECT username,
       lock_date,
       expiry_date
FROM   dba_users
WHERE  username IN (SELECT grantee
                    FROM   dba_role_privs
                    WHERE  granted_role = UPPER('&1'))
ORDER BY username;

SET VERIFY ON
-- End of users_with_role.sql --

-- ########## Start of users_with_sys_priv.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/users_with_sys_priv.sql
-- Author       : Tim Hall
-- Description  : Displays a list of users granted the specified role.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @users_with_sys_priv "UNLIMITED TABLESPACE"
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------

SET VERIFY OFF
COLUMN username FORMAT A30

SELECT username,
       lock_date,
       expiry_date
FROM   dba_users
WHERE  username IN (SELECT grantee
                    FROM   dba_sys_privs
                    WHERE  privilege = UPPER('&1'))
ORDER BY username;

-- End of users_with_sys_priv.sql --

-- ########## Start of active_session_waits.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/active_session_waits.sql
-- Author       : Tim Hall
-- Description  : Displays information on the current wait states for all active database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @active_session_waits
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 250
SET PAGESIZE 1000

COLUMN username FORMAT A15
COLUMN osuser FORMAT A15
COLUMN sid FORMAT 99999
COLUMN serial# FORMAT 9999999
COLUMN wait_class FORMAT A15
COLUMN state FORMAT A19
COLUMN logon_time FORMAT A20

SELECT NVL(a.username, \'(oracle)\') AS username,
       a.osuser,
       a.sid,
       a.serial#,
       d.spid AS process_id,
       a.wait_class,
       a.seconds_in_wait,
       a.state,
       a.blocking_session,
       a.blocking_session_status,
       a.module,
       TO_CHAR(a.logon_Time,\'DD-MON-YYYY HH24:MI:SS\') AS logon_time
FROM   v$session a,
       v$process d
WHERE  a.paddr  = d.addr
AND    a.status = \'ACTIVE\'
ORDER BY 1,2;

SET PAGESIZE 14


-- End of active_session_waits.sql --

-- ########## Start of ash.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/ash.sql
-- Author       : Tim Hall
-- Description  : Displays the minutes spent on each event for the specified time.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @active_session_waits (mins)
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------

SET VERIFY OFF

SELECT NVL(a.event, 'ON CPU') AS event,
       COUNT(*) AS total_wait_time
FROM   v$active_session_history a
WHERE  a.sample_time > SYSDATE - &1/(24*60)
GROUP BY a.event
ORDER BY total_wait_time DESC;

SET VERIFY ON
-- End of ash.sql --

-- ########## Start of datapump_jobs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/datapump_jobs.sql
-- Author       : Tim Hall
-- Description  : Displays information about all Data Pump jobs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @datapump_jobs
-- Last Modified: 28/01/2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN owner_name FORMAT A20
COLUMN job_name FORMAT A30
COLUMN operation FORMAT A10
COLUMN job_mode FORMAT A10
COLUMN state FORMAT A12

SELECT owner_name,
       job_name,
       TRIM(operation) AS operation,
       TRIM(job_mode) AS job_mode,
       state,
       degree,
       attached_sessions,
       datapump_sessions
FROM   dba_datapump_jobs
ORDER BY 1, 2;

-- End of datapump_jobs.sql --

-- ########## Start of db_usage_hwm.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/db_usage_hwm.sql
-- Author       : Tim Hall
-- Description  : Displays high water mark statistics.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @db_usage_hwm
-- Last Modified: 26-NOV-2004
-- -----------------------------------------------------------------------------------

COLUMN name  FORMAT A40
COLUMN highwater FORMAT 999999999999
COLUMN last_value FORMAT 999999999999
SET PAGESIZE 24

SELECT hwm1.name,
       hwm1.highwater,
       hwm1.last_value
FROM   dba_high_water_mark_statistics hwm1
WHERE  hwm1.version = (SELECT MAX(hwm2.version)
                       FROM   dba_high_water_mark_statistics hwm2
                       WHERE  hwm2.name = hwm1.name)
ORDER BY hwm1.name;

COLUMN FORMAT DEFAULT

-- End of db_usage_hwm.sql --

-- ########## Start of dynamic_memory.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/dynamic_memory.sql
-- Author       : Tim Hall
-- Description  : Displays the values of the dynamically memory pools.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @dynamic_memory
-- Last Modified: 08-NOV-2004
-- -----------------------------------------------------------------------------------

COLUMN name  FORMAT A40
COLUMN value FORMAT A40

SELECT name,
       value
FROM   v$parameter
WHERE  SUBSTR(name, 1, 1) = '_'
ORDER BY name;

COLUMN FORMAT DEFAULT

-- End of dynamic_memory.sql --

-- ########## Start of event_histogram.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/event_histogram.sql
-- Author       : Tim Hall
-- Description  : Displays histogram of the event waits times.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @event_histogram "(event-name)"
-- Last Modified: 08-NOV-2005
-- -----------------------------------------------------------------------------------

SET VERIFY OFF
COLUMN event FORMAT A30

SELECT event#,
       event,
       wait_time_milli,
       wait_count
FROM   v$event_histogram
WHERE  event LIKE '%&1%'
ORDER BY event, wait_time_milli;

COLUMN FORMAT DEFAULT
SET VERIFY ON
-- End of event_histogram.sql --

-- ########## Start of feature_usage.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/feature_usage.sql
-- Author       : Tim Hall
-- Description  : Displays feature usage statistics.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @feature_usage
-- Last Modified: 26-NOV-2004
-- -----------------------------------------------------------------------------------

COLUMN name  FORMAT A60
COLUMN detected_usages FORMAT 999999999999

SELECT u1.name,
       u1.detected_usages,
       u1.currently_used,
       u1.version
FROM   dba_feature_usage_statistics u1
WHERE  u1.version = (SELECT MAX(u2.version)
                     FROM   dba_feature_usage_statistics u2
                     WHERE  u2.name = u1.name)
AND    u1.detected_usages > 0
AND    u1.dbid = (SELECT dbid FROM v$database)
ORDER BY u1.name;

COLUMN FORMAT DEFAULT
-- End of feature_usage.sql --

-- ########## Start of flashback_db_info.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/flashback_db_info.sql
-- Author       : Tim Hall
-- Description  : Displays information relevant to flashback database.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @flashback_db_info
-- Last Modified: 21/12/2004
-- -----------------------------------------------------------------------------------
PROMPT Flashback Status
PROMPT ================
select flashback_on from v$database;

PROMPT Flashback Parameters
PROMPT ====================

column name format A30
column value format A50
select name, value
from   v$parameter
where  name in ('db_flashback_retention_target', 'db_recovery_file_dest','db_recovery_file_dest_size')
order by name;

PROMPT Flashback Restore Points
PROMPT ========================

select * from v$restore_point;

PROMPT Flashback Logs
PROMPT ==============

select * from v$flashback_database_log;

-- End of flashback_db_info.sql --

-- ########## Start of generate_multiple_awr_reports.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/10g/generate_multiple_awr_reports.sql
-- Author       : DR Timothy S Hall
-- Description  : Generates AWR reports for all snapsots between the specified start and end point.
-- Requirements : Access to the v$ views, UTL_FILE and DBMS_WORKLOAD_REPOSITORY packages.
-- Call Syntax  : Create the directory with the appropriate path.
--                Adjust the start and end snapshots as required.
--                @generate_multiple_awr_reports.sql
-- Last Modified: 02/08/2007
-- -----------------------------------------------------------------------------------
CREATE OR REPLACE DIRECTORY awr_reports_dir AS '/tmp/';

DECLARE
  -- Adjust before use.
  l_snap_start       NUMBER := 1;
  l_snap_end         NUMBER := 10;
  l_dir              VARCHAR2(50) := 'AWR_REPORTS_DIR';
  
  l_last_snap        NUMBER := NULL;
  l_dbid             v$database.dbid%TYPE;
  l_instance_number  v$instance.instance_number%TYPE;
  l_file             UTL_FILE.file_type;
  l_file_name        VARCHAR(50);

BEGIN
  SELECT dbid
  INTO   l_dbid
  FROM   v$database;

  SELECT instance_number
  INTO   l_instance_number
  FROM   v$instance;
    
  FOR cur_snap IN (SELECT snap_id
                   FROM   dba_hist_snapshot
                   WHERE  instance_number = l_instance_number
                   AND    snap_id BETWEEN l_snap_start AND l_snap_end
                   ORDER BY snap_id)
  LOOP
    IF l_last_snap IS NOT NULL THEN
      l_file := UTL_FILE.fopen(l_dir, 'awr_' || l_last_snap || '_' || cur_snap.snap_id || '.htm', 'w', 32767);
      
      FOR cur_rep IN (SELECT output
                      FROM   TABLE(DBMS_WORKLOAD_REPOSITORY.awr_report_html(l_dbid, l_instance_number, l_last_snap, cur_snap.snap_id)))
      LOOP
        UTL_FILE.put_line(l_file, cur_rep.output);
      END LOOP;
      UTL_FILE.fclose(l_file);
    END IF;
    l_last_snap := cur_snap.snap_id;
  END LOOP;
  
EXCEPTION
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    RAISE; 
END;
/

-- End of generate_multiple_awr_reports.sql --

-- ########## Start of job_chain_rules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_chain_rules.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job chain rules.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_chain_rules
-- Last Modified: 26/10/2011
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN owner FORMAT A10
COLUMN chain_name FORMAT A15
COLUMN rule_owner FORMAT A10
COLUMN rule_name FORMAT A15
COLUMN condition FORMAT A25
COLUMN action FORMAT A20
COLUMN comments FORMAT A25

SELECT owner,
       chain_name,
       rule_owner,
       rule_name,
       condition,
       action,
       comments
FROM   dba_scheduler_chain_rules
ORDER BY owner, chain_name, rule_owner, rule_name;
-- End of job_chain_rules.sql --

-- ########## Start of job_chain_steps.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_chain_steps.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job chain steps.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_chain_steps
-- Last Modified: 26/10/2011
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN owner FORMAT A10
COLUMN chain_name FORMAT A15
COLUMN step_name FORMAT A15
COLUMN program_owner FORMAT A10
COLUMN program_name FORMAT A15

SELECT owner,
       chain_name,
       step_name,
       program_owner,
       program_name,
       step_type
FROM   dba_scheduler_chain_steps
ORDER BY owner, chain_name, step_name;
-- End of job_chain_steps.sql --

-- ########## Start of job_chains.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_chains.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job chains.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_chains
-- Last Modified: 26/10/2011
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN owner FORMAT A10
COLUMN chain_name FORMAT A15
COLUMN rule_set_owner FORMAT A10
COLUMN rule_set_name FORMAT A15
COLUMN comments FORMAT A15

SELECT owner,
       chain_name,
       rule_set_owner,
       rule_set_name,
       number_of_rules,
       number_of_steps,
       enabled,
       comments
FROM   dba_scheduler_chains;
-- End of job_chains.sql --

-- ########## Start of job_classes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_classes.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job classes.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_classes
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN service FORMAT A20
COLUMN comments FORMAT A40

SELECT job_class_name,
       resource_consumer_group,
       service,
       logging_level,
       log_history,
       comments
FROM   dba_scheduler_job_classes
ORDER BY job_class_name;

-- End of job_classes.sql --

-- ########## Start of job_programs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_programs.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job programs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_programs
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 250

COLUMN owner FORMAT A20
COLUMN program_name FORMAT A30
COLUMN program_action FORMAT A50
COLUMN comments FORMAT A40

SELECT owner,
       program_name,
       program_type,
       program_action,
       number_of_arguments,
       enabled,
       comments
FROM   dba_scheduler_programs
ORDER BY owner, program_name;

-- End of job_programs.sql --

-- ########## Start of job_running_chains.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_running_chains.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job running chains.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_running_chains.sql
-- Last Modified: 26/10/2011
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN owner FORMAT A10
COLUMN job_name FORMAT A20
COLUMN chain_owner FORMAT A10
COLUMN chain_name FORMAT A15
COLUMN step_name FORMAT A25

SELECT owner,
       job_name,
       chain_owner,
       chain_name,
       step_name,
       state
FROM   dba_scheduler_running_chains
ORDER BY owner, job_name, chain_name, step_name;
-- End of job_running_chains.sql --

-- ########## Start of job_schedules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/job_schedules.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job schedules.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_schedules
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 250

COLUMN owner FORMAT A20
COLUMN schedule_name FORMAT A30
COLUMN start_date FORMAT A35
COLUMN repeat_interval FORMAT A50
COLUMN end_date FORMAT A35
COLUMN comments FORMAT A40

SELECT owner,
       schedule_name,
       start_date,
       repeat_interval,
       end_date,
       comments
FROM   dba_scheduler_schedules
ORDER BY owner, schedule_name;

-- End of job_schedules.sql --

-- ########## Start of jobs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/jobs.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler job information.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @jobs
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN owner FORMAT A20
COLUMN job_name FORMAT A30
COLUMN job_class FORMAT A30
COLUMN next_run_date FORMAT A36

SELECT owner,
       job_name,
       enabled,
       job_class,
       next_run_date
FROM   dba_scheduler_jobs
ORDER BY owner, job_name;

-- End of jobs.sql --

-- ########## Start of jobs_running.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/jobs_running.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information for running jobs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @jobs_running
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN owner FORMAT A20
COLUMN elapsed_time FORMAT A30

SELECT owner,
       job_name,
       running_instance,
       elapsed_time,
       session_id
FROM   dba_scheduler_running_jobs
ORDER BY owner, job_name;
-- End of jobs_running.sql --

-- ########## Start of lock_tree.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/lock_tree.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays information on all database sessions with the username
--                column displayed as a heirarchy if locks are present.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @lock_tree
-- Last Modified: 18-MAY-2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A30
COLUMN osuser FORMAT A10
COLUMN machine FORMAT A25
COLUMN logon_time FORMAT A20

SELECT level,
       LPAD(' ', (level-1)*2, ' ') || NVL(s.username, '(oracle)') AS username,
       s.osuser,
       s.sid,
       s.serial#,
       s.lockwait,
       s.status,
       s.module,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time
FROM   v$session s
WHERE  level > 1
OR     EXISTS (SELECT 1
               FROM   v$session
               WHERE  blocking_session = s.sid)
CONNECT BY PRIOR s.sid = s.blocking_session
START WITH s.blocking_session IS NULL;

SET PAGESIZE 14

-- End of lock_tree.sql --

-- ########## Start of scheduler_attributes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/scheduler_attributes.sql
-- Author       : Tim Hall
-- Description  : Displays the top-level scheduler parameters.
-- Requirements : Access to the DBMS_SCHEDULER package and the MANAGE SCHEDULER privilege.
-- Call Syntax  : @scheduler_attributes
-- Last Modified: 13-DEC-2016
-- -----------------------------------------------------------------------------------

SET SERVEROUTPUT ON
DECLARE
  PROCEDURE display(p_param IN VARCHAR2) AS
    l_result VARCHAR2(50);
  BEGIN
    DBMS_SCHEDULER.get_scheduler_attribute(
      attribute => p_param,
      value     => l_result);
    DBMS_OUTPUT.put_line(RPAD(p_param, 30, ' ') || ' : ' || l_result);
  END;
BEGIN
  display('current_open_window');
  display('default_timezone');
  display('email_sender');
  display('email_server');
  display('event_expiry_time');
  display('log_history');
  display('max_job_slave_processes');
END;
/

-- End of scheduler_attributes.sql --

-- ########## Start of segment_advisor.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/segment_advisor.sql
-- Author       : Tim Hall
-- Description  : Displays segment advice for the specified segment.
-- Requirements : Access to the DBMS_ADVISOR package.
-- Call Syntax  : Object-type = "tablespace":
--                  @segment_advisor.sql tablespace (tablespace-name) null
--                Object-type = "table" or "index":
--                  @segment_advisor.sql (object-type) (object-owner) (object-name)
-- Last Modified: 08-APR-2005
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON SIZE 1000000
SET LINESIZE 200
SET VERIFY OFF

DECLARE
  l_object_id     NUMBER;
  l_task_name     VARCHAR2(32767) := 'SEGMENT_ADVISOR_TASK';
  l_object_type   VARCHAR2(32767) := UPPER('&1');
  l_attr1         VARCHAR2(32767) := UPPER('&2');
  l_attr2         VARCHAR2(32767) := UPPER('&3');
BEGIN
  IF l_attr2 = 'NULL' THEN
    l_attr2 := NULL;
  END IF;

  DBMS_ADVISOR.create_task (
    advisor_name      => 'Segment Advisor',
    task_name         => l_task_name);

  DBMS_ADVISOR.create_object (
    task_name   => l_task_name,
    object_type => l_object_type,
    attr1       => l_attr1,
    attr2       => l_attr2,
    attr3       => NULL,
    attr4       => 'null',
    attr5       => NULL,
    object_id   => l_object_id);

  DBMS_ADVISOR.set_task_parameter (
    task_name => l_task_name,
    parameter => 'RECOMMEND_ALL',
    value     => 'TRUE');

  DBMS_ADVISOR.execute_task(task_name => l_task_name);


  FOR cur_rec IN (SELECT f.impact,
                         o.type,
                         o.attr1,
                         o.attr2,
                         f.message,
                         f.more_info
                  FROM   dba_advisor_findings f
                         JOIN dba_advisor_objects o ON f.object_id = o.object_id AND f.task_name = o.task_name
                  WHERE  f.task_name = l_task_name
                  ORDER BY f.impact DESC)
  LOOP
    DBMS_OUTPUT.put_line('..');
    DBMS_OUTPUT.put_line('Type             : ' || cur_rec.type);
    DBMS_OUTPUT.put_line('Attr1            : ' || cur_rec.attr1);
    DBMS_OUTPUT.put_line('Attr2            : ' || cur_rec.attr2);
    DBMS_OUTPUT.put_line('Message          : ' || cur_rec.message);
    DBMS_OUTPUT.put_line('More info        : ' || cur_rec.more_info);
  END LOOP;

  DBMS_ADVISOR.delete_task(task_name => l_task_name);
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line('Error            : ' || DBMS_UTILITY.format_error_backtrace);
    DBMS_ADVISOR.delete_task(task_name => l_task_name);
END;
/

-- End of segment_advisor.sql --

-- ########## Start of services.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/services.sql
-- Author       : Tim Hall
-- Description  : Displays information about database services.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @services
-- Last Modified: 05/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN name FORMAT A30
COLUMN network_name FORMAT A50

SELECT name,
       network_name
FROM   dba_services
ORDER BY name;
-- End of services.sql --

-- ########## Start of session_waits.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/session_waits.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database session waits.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_waits
-- Last Modified: 11/03/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 1000

COLUMN username FORMAT A20
COLUMN event FORMAT A30
COLUMN wait_class FORMAT A15

SELECT NVL(s.username, '(oracle)') AS username,
       s.sid,
       s.serial#,
       sw.event,
       sw.wait_class,
       sw.wait_time,
       sw.seconds_in_wait,
       sw.state
FROM   v$session_wait sw,
       v$session s
WHERE  s.sid = sw.sid
ORDER BY sw.seconds_in_wait DESC;

-- End of session_waits.sql --

-- ########## Start of sga_buffers.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : http://www.oracle-base.com/dba/10g/sga_buffers.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays the status of buffers in the SGA.
-- Requirements : Access to the v$ and DBA views.
-- Call Syntax  : @sga_buffers
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN object_name FORMAT A30

SELECT t.name AS tablespace_name,
       o.object_name,
       SUM(DECODE(bh.status, 'free', 1, 0)) AS free,
       SUM(DECODE(bh.status, 'xcur', 1, 0)) AS xcur,
       SUM(DECODE(bh.status, 'scur', 1, 0)) AS scur,
       SUM(DECODE(bh.status, 'cr', 1, 0)) AS cr,
       SUM(DECODE(bh.status, 'read', 1, 0)) AS read,
       SUM(DECODE(bh.status, 'mrec', 1, 0)) AS mrec,
       SUM(DECODE(bh.status, 'irec', 1, 0)) AS irec
FROM   v$bh bh
       JOIN dba_objects o ON o.object_id = bh.objd
       JOIN v$tablespace t ON t.ts# = bh.ts#
GROUP BY t.name, o.object_name;

-- End of sga_buffers.sql --

-- ########## Start of sga_dynamic_components.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/sga_dynamic_components.sql
-- Author       : Tim Hall
-- Description  : Provides information about dynamic SGA components.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @sga_dynamic_components
-- Last Modified: 09/05/2017
-- -----------------------------------------------------------------------------------
COLUMN component FORMAT A30

SELECT  component,
        ROUND(current_size/1024/1024) AS current_size_mb,
        ROUND(min_size/1024/1024) AS min_size_mb,
        ROUND(max_size/1024/1024) AS max_size_mb
FROM    v$sga_dynamic_components
WHERE   current_size != 0
ORDER BY component;

-- End of sga_dynamic_components.sql --

-- ########## Start of sga_dynamic_free_memory.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/sga_dynamic_free_memory.sql
-- Author       : Tim Hall
-- Description  : Provides information about free memory in the SGA.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @sga_dynamic_free_memory
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------

SELECT *
FROM   v$sga_dynamic_free_memory;

-- End of sga_dynamic_free_memory.sql --

-- ########## Start of sga_resize_ops.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/sga_resize_ops.sql
-- Author       : Tim Hall
-- Description  : Provides information about memory resize operations.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @sga_resize_ops
-- Last Modified: 09/05/2017
-- -----------------------------------------------------------------------------------

SET LINESIZE 200

COLUMN parameter FORMAT A25

SELECT start_time,
       end_time,
       component,
       oper_type,
       oper_mode,
       parameter,
       ROUND(initial_size/1024/1024) AS initial_size_mb,
       ROUND(target_size/1024/1024) AS target_size_mb,
       ROUND(final_size/1024/1024) AS final_size_mb,
       status
FROM   v$sga_resize_ops
ORDER BY start_time;

-- End of sga_resize_ops.sql --

-- ########## Start of sysaux_occupants.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/sysaux_occupants.sql
-- Author       : Tim Hall
-- Description  : Displays information about the contents of the SYSAUX tablespace.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @sysaux_occupants
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------
COLUMN occupant_name FORMAT A30
COLUMN schema_name FORMAT A20

SELECT occupant_name,
       schema_name,
       space_usage_kbytes
FROM   v$sysaux_occupants
ORDER BY occupant_name;

-- End of sysaux_occupants.sql --

-- ########## Start of test_calendar_string.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/test_calendar_string.sql
-- Author       : Tim Hall
-- Description  : Displays the schedule associated with a calendar string.
-- Requirements : Access to the DBMS_SCHEDULER package.
-- Call Syntax  : @test_calendar_string (frequency) (interations)
--                @test_calendar_string 'freq=hourly; byminute=0,30; bysecond=0;' 5
-- Last Modified: 27/07/2005
-- -----------------------------------------------------------------------------------

SET SERVEROUTPUT ON;
SET VERIFY OFF
ALTER SESSION SET nls_timestamp_format = 'DD-MON-YYYY HH24:MI:SS';

DECLARE
  l_calendar_string  VARCHAR2(100) := '&1';
  l_iterations       NUMBER        := &2;

  l_start_date         TIMESTAMP := TO_TIMESTAMP('01-JAN-2004 03:04:32',
                                                 'DD-MON-YYYY HH24:MI:SS');
  l_return_date_after  TIMESTAMP := l_start_date;
  l_next_run_date      TIMESTAMP;
BEGIN
  FOR i IN 1 .. l_iterations LOOP
    DBMS_SCHEDULER.evaluate_calendar_string(  
      calendar_string   => l_calendar_string,
      start_date        => l_start_date,
      return_date_after => l_return_date_after,
      next_run_date     => l_next_run_date);
    
    DBMS_OUTPUT.put_line('Next Run Date: ' || l_next_run_date);
    l_return_date_after := l_next_run_date;
  END LOOP;
END;
/
-- End of test_calendar_string.sql --

-- ########## Start of window_groups.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/window_groups.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about window groups.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @window_groups
-- Last Modified: 05/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 250

COLUMN comments FORMAT A40

SELECT window_group_name,
       enabled,
       number_of_windows,
       comments
FROM   dba_scheduler_window_groups
ORDER BY window_group_name;

SELECT window_group_name,
       window_name
FROM   dba_scheduler_wingroup_members
ORDER BY window_group_name, window_name;

-- End of window_groups.sql --

-- ########## Start of windows.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/windows.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about windows.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @windows
-- Last Modified: 05/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 250

COLUMN comments FORMAT A40

SELECT window_name,
       resource_plan,
       enabled,
       active,
       comments
FROM   dba_scheduler_windows
ORDER BY window_name;

-- End of windows.sql --

-- ########## Start of admin_privs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/admin_privs.sql
-- Author       : Tim Hall
-- Description  : Displays the users who currently have admin privileges.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @min_datafile_size
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------

SELECT *
FROM   v$pwfile_users
ORDER BY username;
-- End of admin_privs.sql --

-- ########## Start of autotask_change_window_schedules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/autotask_change_window_schedules.sql
-- Author       : Tim Hall
-- Description  : Use this script to alter the autotask window schedules.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @autotask_change_window_schedules.sql
-- Last Modified: 04-AUG-2022: Ernst Leber fixed the repeat interval, that was forcing "mon" on each window.
-- -----------------------------------------------------------------------------------

DECLARE
  TYPE t_window_tab IS TABLE OF VARCHAR2(30)
    INDEX BY BINARY_INTEGER;
  TYPE t_interval_tab IS TABLE OF VARCHAR2(300) 
    INDEX BY BINARY_INTEGER;
  
  l_tab              t_window_tab;
  l_repeat_interval  t_interval_tab;
  l_duration         NUMBER;
BEGIN

  -- Windows of interest.
  l_tab(1) := 'SYS.MONDAY_WINDOW';
  l_tab(2) := 'SYS.TUESDAY_WINDOW';
  l_tab(3) := 'SYS.WEDNESDAY_WINDOW';
  l_tab(4) := 'SYS.THURSDAY_WINDOW';
  l_tab(5) := 'SYS.FRIDAY_WINDOW';
  --l_tab(6) := 'SYS.SATURDAY_WINDOW';
  --l_tab(7) := 'SYS.SUNDAY_WINDOW';

  -- Adjust as required.
  l_repeat_interval(1) := 'freq=weekly; byday=mon; byhour=23; byminute=0; bysecond=0;';
  l_repeat_interval(2) := 'freq=weekly; byday=tue; byhour=23; byminute=0; bysecond=0;';
  l_repeat_interval(3) := 'freq=weekly; byday=wed; byhour=23; byminute=0; bysecond=0;';
  l_repeat_interval(4) := 'freq=weekly; byday=thu; byhour=23; byminute=0; bysecond=0;';
  l_repeat_interval(5) := 'freq=weekly; byday=fri; byhour=23; byminute=0; bysecond=0;';
  --l_repeat_interval(6) := 'freq=weekly; byday=sat; byhour=23; byminute=0; bysecond=0;';
  --l_repeat_interval(7) := 'freq=weekly; byday=sun; byhour=23; byminute=0; bysecond=0;';
  l_duration        := 240; -- minutes
  
  FOR i IN l_tab.FIRST .. l_tab.LAST LOOP
    DBMS_SCHEDULER.disable(name => l_tab(i), force => TRUE);

    DBMS_SCHEDULER.set_attribute(
      name      => l_tab(i),
      attribute => 'REPEAT_INTERVAL',
      value     =>  l_repeat_interval(i));

    DBMS_SCHEDULER.set_attribute(
      name      => l_tab(i),
      attribute => 'DURATION',
      value     => numtodsinterval(l_duration, 'minute'));

    DBMS_SCHEDULER.enable(name => l_tab(i));
  END LOOP;
END;
/

-- End of autotask_change_window_schedules.sql --

-- ########## Start of autotask_job_history.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/autotask_job_history.sql
-- Author       : Tim Hall
-- Description  : Displays the job history for the automatic maintenance tasks.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @autotask_job_history.sql
-- Last Modified: 14-JUL-2016
-- -----------------------------------------------------------------------------------

COLUMN client_name FORMAT A40
COLUMN window_name FORMAT A20
COLUMN job_start_time FORMAT A40
COLUMN job_duration FORMAT A20
COLUMN job_status FORMAT A10

SELECT client_name,
       window_name,
       job_start_time,
       job_duration,
       job_status,
       job_error
FROM   dba_autotask_job_history
ORDER BY job_start_time;

COLUMN FORMAT DEFAULT

-- End of autotask_job_history.sql --

-- ########## Start of autotask_schedule.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/autotask_schedule.sql
-- Author       : Tim Hall
-- Description  : Displays the window schedule the automatic maintenance tasks.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @autotask_schedule.sql
-- Last Modified: 14-JUL-2016
-- -----------------------------------------------------------------------------------

COLUMN window_name FORMAT A20
COLUMN start_time FORMAT A40
COLUMN duration FORMAT A20

SELECT *
FROM   dba_autotask_schedule
ORDER BY start_time;


COLUMN FORMAT DEFAULT

-- End of autotask_schedule.sql --

-- ########## Start of database_block_corruption.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/database_block_corruption.sql
-- Author       : Tim Hall
-- Description  : Displays the users who currently have admin privileges.
-- Requirements : Access to the V$ and DBA views.
--                Assumes a RMAN VALIDATE has been run against a datafile, tablespace
--                or the whole database before this query is run.
-- Call Syntax  : @database_block_corruption
-- Last Modified: 29/11/2018
-- -----------------------------------------------------------------------------------

COLUMN owner FORMAT A30
COLUMN segment_name FORMAT A30

SELECT DISTINCT owner, segment_name
FROM   v$database_block_corruption dbc
       JOIN dba_extents e ON dbc.file# = e.file_id AND dbc.block# BETWEEN e.block_id and e.block_id+e.blocks-1
ORDER BY 1,2;

-- End of database_block_corruption.sql --

-- ########## Start of default_passwords.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/default_passwords.sql
-- Author       : Tim Hall
-- Description  : Displays users with default passwords.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @default_passwords
-- Last Modified: 26-NOV-2011
-- -----------------------------------------------------------------------------------

SELECT a.username, b.account_status
FROM   dba_users_with_defpwd a
       JOIN dba_users b ON a.username = b.username
ORDER BY 1;

-- End of default_passwords.sql --

-- ########## Start of diag_info.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/diag_info.sql
-- Author       : Tim Hall
-- Description  : Displays the contents of the v$diag_info view.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @diag_info
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN name FORMAT A30
COLUMN value FORMAT A110

SELECT *
FROM   v$diag_info;

-- End of diag_info.sql --

-- ########## Start of extended_stats.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/extended_stats.sql
-- Author       : Tim Hall
-- Description  : Provides information about extended statistics.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @extended_stats
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN owner FORMAT A20
COLUMN extension_name FORMAT A15
COLUMN extension FORMAT A50

SELECT owner, table_name, extension_name, extension
FROM   dba_stat_extensions
ORDER by owner, table_name;
-- End of extended_stats.sql --

-- ########## Start of fda.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/fda.sql
-- Author       : Tim Hall
-- Description  : Displays information about flashback data archives.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @fda
-- Last Modified: 06-JAN-2015
-- -----------------------------------------------------------------------------------

SET LINESIZE 150

COLUMN owner_name FORMAT A20
COLUMN flashback_archive_name FORMAT A22
COLUMN create_time FORMAT A20
COLUMN last_purge_time FORMAT A20

SELECT owner_name,
       flashback_archive_name,
       flashback_archive#,
       retention_in_days,
       TO_CHAR(create_time, 'DD-MON-YYYY HH24:MI:SS') AS create_time,
       TO_CHAR(last_purge_time, 'DD-MON-YYYY HH24:MI:SS') AS last_purge_time,
       status
FROM   dba_flashback_archive
ORDER BY owner_name, flashback_archive_name;

-- End of fda.sql --

-- ########## Start of fda_tables.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/fda_tables.sql
-- Author       : Tim Hall
-- Description  : Displays information about flashback data archives.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @fda_tables
-- Last Modified: 06-JAN-2015
-- -----------------------------------------------------------------------------------

SET LINESIZE 150

COLUMN owner_name FORMAT A20
COLUMN table_name FORMAT A20
COLUMN flashback_archive_name FORMAT A22
COLUMN archive_table_name FORMAT A20

SELECT owner_name,
       table_name,
       flashback_archive_name,
       archive_table_name,
       status
FROM   dba_flashback_archive_tables
ORDER BY owner_name, table_name;

-- End of fda_tables.sql --

-- ########## Start of fda_ts.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/fda_ts.sql
-- Author       : Tim Hall
-- Description  : Displays information about flashback data archives.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @fda_ts
-- Last Modified: 06-JAN-2015
-- -----------------------------------------------------------------------------------

SET LINESIZE 150

COLUMN flashback_archive_name FORMAT A22
COLUMN tablespace_name FORMAT A20
COLUMN quota_in_mb FORMAT A11

SELECT flashback_archive_name,
       flashback_archive#,
       tablespace_name,
       quota_in_mb
FROM   dba_flashback_archive_ts
ORDER BY flashback_archive_name;

-- End of fda_ts.sql --

-- ########## Start of identify_trace_file.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/identify_trace_file.sql
-- Author       : Tim Hall
-- Description  : Displays the name of the trace file associated with the current session.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @identify_trace_file
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------
SET LINESIZE 100
COLUMN value FORMAT A60

SELECT value
FROM   v$diag_info
WHERE  name = 'Default Trace File';
-- End of identify_trace_file.sql --

-- ########## Start of job_credentials.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/job_credentials.sql
-- Author       : Tim Hall
-- Description  : Displays scheduler information about job credentials.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_credentials
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------
COLUMN credential_name FORMAT A25
COLUMN username FORMAT A20
COLUMN windows_domain FORMAT A20

SELECT credential_name,
       username,
       windows_domain
FROM   dba_scheduler_credentials
ORDER BY credential_name;

-- End of job_credentials.sql --

-- ########## Start of job_output_file.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/job_output_file.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays scheduler job information for previous runs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_output_file (job-name) (credential-name)
-- Last Modified: 06/06/2014
-- -----------------------------------------------------------------------------------

SET VERIFY OFF

SET SERVEROUTPUT ON
DECLARE
  l_clob             CLOB;
  l_additional_info  VARCHAR2(4000);
  l_external_log_id  VARCHAR2(50);
BEGIN
  SELECT additional_info, external_log_id
  INTO   l_additional_info, l_external_log_id
  FROM   (SELECT log_id, 
                 additional_info,
                 REGEXP_SUBSTR(additional_info,'job[_0-9]*') AS external_log_id
          FROM   dba_scheduler_job_run_details
          WHERE  job_name = UPPER('&1')
          ORDER BY log_id DESC)
  WHERE  ROWNUM = 1;

  DBMS_OUTPUT.put_line('ADDITIONAL_INFO: ' || l_additional_info);
  DBMS_OUTPUT.put_line('EXTERNAL_LOG_ID: ' || l_external_log_id);

  DBMS_LOB.createtemporary(l_clob, FALSE);

  DBMS_SCHEDULER.get_file(
    source_file     => l_external_log_id ||'_stdout',
    credential_name => UPPER('&2'),
    file_contents   => l_clob,
    source_host     => NULL);

  DBMS_OUTPUT.put_line('stdout:');
  DBMS_OUTPUT.put_line(l_clob);
END;
/

-- End of job_output_file.sql --

-- ########## Start of job_run_details.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/job_run_details.sql
-- Author       : DR Timothy S Hall
-- Description  : Displays scheduler job information for previous runs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @job_run_details (job-name | all)
-- Last Modified: 06/06/2014
-- -----------------------------------------------------------------------------------
SET LINESIZE 300 VERIFY OFF

COLUMN log_date FORMAT A35
COLUMN owner FORMAT A20
COLUMN job_name FORMAT A30
COLUMN error FORMAT A20
COLUMN req_start_date FORMAT A35
COLUMN actual_start_date FORMAT A35
COLUMN run_duration FORMAT A20
COLUMN credential_owner FORMAT A20
COLUMN credential_name FORMAT A20
COLUMN additional_info FORMAT A30

SELECT log_date,
       owner,
       job_name,
       status
       error,
       req_start_date,
       actual_start_date,
       run_duration,
       credential_owner,
       credential_name,
       additional_info
FROM   dba_scheduler_job_run_details
WHERE  job_name = DECODE(UPPER('&1'), 'ALL', job_name, UPPER('&1'))
ORDER BY log_date;

-- End of job_run_details.sql --

-- ########## Start of memory_dynamic_components.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/memory_dynamic_components.sql
-- Author       : Tim Hall
-- Description  : Provides information about dynamic memory components.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @memory_dynamic_components
-- Last Modified: 09/05/2017
-- -----------------------------------------------------------------------------------
COLUMN component FORMAT A30

SELECT  component,
        ROUND(current_size/1024/1024) AS current_size_mb,
        ROUND(min_size/1024/1024) AS min_size_mb,
        ROUND(max_size/1024/1024) AS max_size_mb
FROM    v$memory_dynamic_components
WHERE   current_size != 0
ORDER BY component;

-- End of memory_dynamic_components.sql --

-- ########## Start of memory_resize_ops.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/memory_resize_ops.sql
-- Author       : Tim Hall
-- Description  : Provides information about memory resize operations.
-- Requirements : Access to the v$ views.
-- Call Syntax  : @memory_resize_ops
-- Last Modified: 09/05/2017
-- -----------------------------------------------------------------------------------

SET LINESIZE 200

COLUMN parameter FORMAT A25

SELECT start_time,
       end_time,
       component,
       oper_type,
       oper_mode,
       parameter,
       ROUND(initial_size/1024/1024) AS initial_size_mb,
       ROUND(target_size/1024/1024) AS target_size_mb,
       ROUND(final_size/1024/1024) AS final_size_mb,
       status
FROM   v$memory_resize_ops
ORDER BY start_time;

-- End of memory_resize_ops.sql --

-- ########## Start of memory_target_advice.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/memory_target_advice.sql
-- Author       : Tim Hall
-- Description  : Provides information to help tune the MEMORY_TARGET parameter.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @memory_target_advice
-- Last Modified: 23/08/2008
-- -----------------------------------------------------------------------------------
SELECT *
FROM   v$memory_target_advice
ORDER BY memory_size;
-- End of memory_target_advice.sql --

-- ########## Start of network_acl_privileges.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/network_acl_privileges.sql
-- Author       : Tim Hall
-- Description  : Displays privileges for the network ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @network_acl_privileges
-- Last Modified: 22/05/2023
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN acl FORMAT A50
COLUMN principal FORMAT A20
COLUMN privilege FORMAT A10

SELECT nap.acl,
       host,
       lower_port,
       upper_port,
       nap.principal,
       nap.privilege,
       nap.is_grant,
       TO_CHAR(nap.start_date, 'DD-MON-YYYY') AS start_date,
       TO_CHAR(nap.end_date, 'DD-MON-YYYY') AS end_date
FROM   dba_network_acl_privileges nap
       JOIN dba_network_acls na on na.acl = nap.acl
ORDER BY nap.acl, nap.principal, nap.privilege;

SET LINESIZE 80

-- End of network_acl_privileges.sql --

-- ########## Start of network_acl_privileges_by_host.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/network_acl_privileges_by_host.sql
-- Author       : Tim Hall
-- Description  : Displays privileges for the network ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @network_acl_privileges_by_host (host | all)
-- Last Modified: 22/05/2023
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN acl FORMAT A50
COLUMN principal FORMAT A20
COLUMN privilege FORMAT A10

SELECT nap.acl,
       host,
       lower_port,
       upper_port,
       nap.principal,
       nap.privilege,
       nap.is_grant,
       TO_CHAR(nap.start_date, 'DD-MON-YYYY') AS start_date,
       TO_CHAR(nap.end_date, 'DD-MON-YYYY') AS end_date
FROM   dba_network_acl_privileges nap
       JOIN dba_network_acls na on na.acl = nap.acl
WHERE  host LIKE DECODE(UPPER('&1'), 'ALL', host, '%&1%')
ORDER BY nap.acl, nap.principal, nap.privilege;

SET LINESIZE 80

-- End of network_acl_privileges_by_host.sql --

-- ########## Start of network_acls.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/network_acls.sql
-- Author       : Tim Hall
-- Description  : Displays information about network ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @network_acls
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN host FORMAT A40
COLUMN acl FORMAT A50

SELECT host, lower_port, upper_port, acl
FROM   dba_network_acls
ORDER BY host;

SET LINESIZE 80
-- End of network_acls.sql --

-- ########## Start of result_cache_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/result_cache_objects.sql
-- Author       : Tim Hall
-- Description  : Displays information about the objects in the result cache.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @result_cache_objects
-- Last Modified: 07/11/2012
-- -----------------------------------------------------------------------------------
SET LINESIZE 1000

SELECT *
FROM v$result_cache_objects;

-- End of result_cache_objects.sql --

-- ########## Start of result_cache_report.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/result_cache_report.sql
-- Author       : Tim Hall
-- Description  : Displays the result cache report.
-- Requirements : Access to the DBMS_RESULT_CACHE package.
-- Call Syntax  : @result_cache_report
-- Last Modified: 07/11/2012
-- -----------------------------------------------------------------------------------

SET SERVEROUTPUT ON
EXEC DBMS_RESULT_CACHE.memory_report(detailed => true);

-- End of result_cache_report.sql --

-- ########## Start of result_cache_statistics.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/result_cache_statistics.sql
-- Author       : Tim Hall
-- Description  : Displays result cache statistics.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @result_cache_statistics
-- Last Modified: 07/11/2012
-- -----------------------------------------------------------------------------------

COLUMN name FORMAT A30
COLUMN value FORMAT A30

SELECT id,
       name,
       value
FROM   v$result_cache_statistics
ORDER BY id;

CLEAR COLUMNS
-- End of result_cache_statistics.sql --

-- ########## Start of result_cache_status.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/result_cache_status.sql
-- Author       : Tim Hall
-- Description  : Displays the status of the result cache.
-- Requirements : Access to the DBMS_RESULT_CACHE package.
-- Call Syntax  : @result_cache_status
-- Last Modified: 07/11/2012
-- -----------------------------------------------------------------------------------

SELECT DBMS_RESULT_CACHE.status FROM dual;
-- End of result_cache_status.sql --

-- ########## Start of session_fix.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/session_fix.sql
-- Author       : Tim Hall
-- Description  : Provides information about session fixes for the specified phrase and version.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_fix (session_id | all) (phrase | all) (version | all)
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 300

COLUMN sql_feature FORMAT A35
COLUMN optimizer_feature_enable FORMAT A9

SELECT *
FROM   v$session_fix_control
WHERE  session_id = DECODE('&1', 'all', session_id, '&1')
AND    LOWER(description) LIKE DECODE('&2', 'all', '%', '%&2%')
AND    optimizer_feature_enable = DECODE('&3', 'all', optimizer_feature_enable, '&3');
-- End of session_fix.sql --

-- ########## Start of statistics_global_prefs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/statistics_global_prefs.sql
-- Author       : Tim Hall
-- Description  : Displays the top-level global statistics preferences.
-- Requirements : Access to the DBMS_STATS package.
-- Call Syntax  : @statistics_global_prefs
-- Last Modified: 08-NOV-2022
-- -----------------------------------------------------------------------------------

SET SERVEROUTPUT ON
DECLARE
  PROCEDURE display(p_param IN VARCHAR2) AS
    l_result VARCHAR2(32767);
  BEGIN
    l_result := DBMS_STATS.get_prefs (pname => p_param);
    DBMS_OUTPUT.put_line(RPAD(p_param, 30, ' ') || ' : ' || l_result);
  END;
BEGIN
  display('APPROXIMATE_NDV_ALGORITHM');
  display('AUTO_STAT_EXTENSIONS');
  display('AUTO_TASK_STATUS');
  display('AUTO_TASK_MAX_RUN_TIME');
  display('AUTO_TASK_INTERVAL');
  display('CASCADE');
  display('CONCURRENT');
  display('DEGREE');
  display('ESTIMATE_PERCENT');
  display('GLOBAL_TEMP_TABLE_STATS');
  display('GRANULARITY');
  display('INCREMENTAL');
  display('INCREMENTAL_STALENESS');
  display('INCREMENTAL_LEVEL');
  display('METHOD_OPT');
  display('NO_INVALIDATE');
  display('OPTIONS');
  display('PREFERENCE_OVERRIDES_PARAMETER');
  display('PUBLISH');
  display('STALE_PERCENT');
  display('STAT_CATEGORY');
  display('TABLE_CACHED_BLOCKS');
  display('WAIT_TIME_TO_UPDATE_STATS');
END;
/


-- End of statistics_global_prefs.sql --

-- ########## Start of system_fix.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/system_fix.sql
-- Author       : Tim Hall
-- Description  : Provides information about system fixes for the specified phrase and version.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @system_fix (phrase | all) (version | all)
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET LINESIZE 300

COLUMN sql_feature FORMAT A35
COLUMN optimizer_feature_enable FORMAT A9

SELECT *
FROM   v$system_fix_control
WHERE  LOWER(description) LIKE DECODE('&1', 'all', '%', '%&1%')
AND    optimizer_feature_enable = DECODE('&2', 'all', optimizer_feature_enable, '&2');
-- End of system_fix.sql --

-- ########## Start of system_fix_count.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/system_fix_count.sql
-- Author       : Tim Hall
-- Description  : Provides information about system fixes per version.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @system_fix_count
-- Last Modified: 30/11/2011
-- -----------------------------------------------------------------------------------
SELECT optimizer_feature_enable,
       COUNT(*)
FROM   v$system_fix_control
GROUP BY optimizer_feature_enable
ORDER BY optimizer_feature_enable;
-- End of system_fix_count.sql --

-- ########## Start of temp_free_space.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/temp_free_space.sql
-- Author       : Tim Hall
-- Description  : Displays information about temporary tablespace usage.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @temp_free_space
-- Last Modified: 23-AUG-2008
-- -----------------------------------------------------------------------------------
SELECT *
FROM   dba_temp_free_space;
-- End of temp_free_space.sql --

-- ########## Start of cdb_resource_plan_directives.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/cdb_resource_plan_directives.sql
-- Author       : Tim Hall
-- Description  : Displays CDB resource plan directives.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @cdb_resource_plan_directives.sql (plan-name or all)
-- Last Modified: 22-MAR-2014
-- -----------------------------------------------------------------------------------

COLUMN plan FORMAT A30
COLUMN pluggable_database FORMAT A25
SET LINESIZE 100 VERIFY OFF

SELECT plan, 
       pluggable_database, 
       shares, 
       utilization_limit AS util,
       parallel_server_limit AS parallel
FROM   dba_cdb_rsrc_plan_directives
WHERE  plan = DECODE(UPPER('&1'), 'ALL', plan, UPPER('&1'))
ORDER BY plan, pluggable_database;

SET VERIFY ON
-- End of cdb_resource_plan_directives.sql --

-- ########## Start of cdb_resource_plans.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/cdb_resource_plans.sql
-- Author       : Tim Hall
-- Description  : Displays CDB resource plans.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @cdb_resource_plans.sql
-- Last Modified: 22-MAR-2014
-- -----------------------------------------------------------------------------------

COLUMN plan FORMAT A30
COLUMN comments FORMAT A30
COLUMN status FORMAT A10
SET LINESIZE 100

SELECT plan_id,
       plan,
       comments,
       status,
       mandatory
FROM   dba_cdb_rsrc_plans
ORDER BY plan;

-- End of cdb_resource_plans.sql --

-- ########## Start of cdb_resource_profile_directives.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/cdb_resource_profile_directives.sql
-- Author       : Tim Hall
-- Description  : Displays CDB resource profile directives.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @cdb_resource_profile_directives.sql (plan-name or all)
-- Last Modified: 10-JAN-2017
-- -----------------------------------------------------------------------------------

COLUMN plan FORMAT A30
COLUMN pluggable_database FORMAT A25
COLUMN profile FORMAT A25
SET LINESIZE 150 VERIFY OFF

SELECT plan,
       pluggable_database,
       profile,
       shares,
       utilization_limit AS util,
       parallel_server_limit AS parallel
FROM   dba_cdb_rsrc_plan_directives
WHERE  plan = DECODE(UPPER('&1'), 'ALL', plan, UPPER('&1'))
ORDER BY plan, pluggable_database, profile;

SET VERIFY ON
-- End of cdb_resource_profile_directives.sql --

-- ########## Start of clustering_dimensions.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/clustering_dimensions.sql
-- Author       : Tim Hall
-- Description  : Display clustering dimensions in the specified schema, or all schemas.
-- Call Syntax  : @clustering_dimensions (schema or all)
-- Last Modified: 24/12/2020
-- -----------------------------------------------------------------------------------
set linesize 200 verify off trimspool on
column owner form a30
column table_name form a30
column dimension_owner form a30
column dimension_name form a30

select owner,
       table_name,
       dimension_owner,
       dimension_name
from   dba_clustering_dimensions
where  owner = decode(upper('&1'), 'ALL', owner, upper('&1'))
order by owner, table_name;

-- End of clustering_dimensions.sql --

-- ########## Start of clustering_joins.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/clustering_joins.sql
-- Author       : Tim Hall
-- Description  : Display clustering joins in the specified schema, or all schemas.
-- Call Syntax  : @clustering_joins (schema or all)
-- Last Modified: 24/12/2020
-- -----------------------------------------------------------------------------------
set linesize 260 verify off trimspool on
column owner format a30
column table_name form a30
column tab1_owner form a30
column tab1_name form a30
column tab1_column form a30
column tab2_owner form a30
column tab2_name form a30
column tab2_column form a31

select owner,
       table_name,
       tab1_owner,
       tab1_name,
       tab1_column,
       tab2_owner,
       tab2_name,
       tab2_column
from   dba_clustering_joins
where  owner = decode(upper('&1'), 'ALL', owner, upper('&1'))
order by owner, table_name;

-- End of clustering_joins.sql --

-- ########## Start of clustering_keys.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/clustering_keys.sql
-- Author       : Tim Hall
-- Description  : Display clustering keys in the specified schema, or all schemas.
-- Call Syntax  : @clustering_keys (schema or all)
-- Last Modified: 24/12/2020
-- -----------------------------------------------------------------------------------
set linesize 200 verify off trimspool on
column owner format a30
column table_name format a30
column detail_owner format a30
column detail_name format a30
column detail_column format a30

select owner,
       table_name,
       detail_owner,
       detail_name,
       detail_column,
       position,
       groupid
from   dba_clustering_keys
where  owner = decode(upper('&1'), 'ALL', owner, upper('&1'))
order by owner, table_name;

-- End of clustering_keys.sql --

-- ########## Start of clustering_tables.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/clustering_tables.sql
-- Author       : Tim Hall
-- Description  : Display clustering tables in the specified schema, or all schemas.
-- Call Syntax  : @clustering_tables (schema or all)
-- Last Modified: 24/12/2020
-- -----------------------------------------------------------------------------------
set linesize 200 verify off trimspool on
column owner format a30
column table_name format a30
column clustering_type format a25
column on_load format a7
column on_datamovement format a15
column valid format a5
column with_zonemap format a12
column last_load_clst format a30
column last_datamove_clst format a30

select owner,
       table_name,
       clustering_type,
       on_load,
       on_datamovement,
       valid,
       with_zonemap,
       last_load_clst,
       last_datamove_clst
from   dba_clustering_tables
where  owner = decode(upper('&1'), 'ALL', owner, upper('&1'))
order by owner, table_name;

-- End of clustering_tables.sql --

-- ########## Start of credentials.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/credentials.sql
-- Author       : Tim Hall
-- Description  : Displays information about credentials.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @credentials
-- Last Modified: 18/12/2013
-- -----------------------------------------------------------------------------------
COLUMN credential_name FORMAT A25
COLUMN username FORMAT A20
COLUMN windows_domain FORMAT A20

SELECT credential_name,
       username,
       windows_domain
FROM   dba_credentials
ORDER BY credential_name;
-- End of credentials.sql --

-- ########## Start of host_aces.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/host_aces.sql
-- Author       : Tim Hall
-- Description  : Displays information about host ACEs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @host_aces
-- Last Modified: 10/09/2014
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN host FORMAT A20
COLUMN principal FORMAT A30
COLUMN privilege FORMAT A30
COLUMN start_date FORMAT A11
COLUMN end_date FORMAT A11

SELECT host,
       lower_port,
       upper_port,
       ace_order,
       TO_CHAR(start_date, 'DD-MON-YYYY') AS start_date,
       TO_CHAR(end_date, 'DD-MON-YYYY') AS end_date,
       grant_type,
       inverted_principal,
       principal,
       principal_type,
       privilege
FROM   dba_host_aces
ORDER BY host, ace_order;

SET LINESIZE 80
-- End of host_aces.sql --

-- ########## Start of host_acls.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/host_acls.sql
-- Author       : Tim Hall
-- Description  : Displays information about host ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @host_acls
-- Last Modified: 10/09/2014
-- -----------------------------------------------------------------------------------
SET LINESIZE 150

COLUMN acl FORMAT A50
COLUMN host FORMAT A20
COLUMN acl_owner FORMAT A10

SELECT HOST,
       LOWER_PORT,
       UPPER_PORT,
       ACL,
       ACLID,
       ACL_OWNER
FROM   dba_host_acls
ORDER BY host;

SET LINESIZE 80
-- End of host_acls.sql --

-- ########## Start of lockdown_profiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/lockdown_profiles.sql
-- Author       : Tim Hall
-- Description  : Displays information about lockdown profiles.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @lockdown_profiles
-- Last Modified: 05/01/2019 - Increase the LINESIZE setting and include PDB ID and name.
--                             Switch to LEFT OUTER JOIN. Alter column order.
-- -----------------------------------------------------------------------------------
SET LINESIZE 250

COLUMN pdb_name FORMAT A30
COLUMN profile_name FORMAT A30
COLUMN rule_type FORMAT A20
COLUMN rule FORMAT A20
COLUMN clause FORMAT A20
COLUMN clause_option FORMAT A20
COLUMN option_value FORMAT A20
COLUMN min_value FORMAT A20
COLUMN max_value FORMAT A20
COLUMN list FORMAT A20

SELECT lp.con_id,
       p.pdb_name,
       lp.profile_name,
       lp.rule_type,
       lp.status,
       lp.rule,
       lp.clause,
       lp.clause_option,
       lp.option_value,
       lp.min_value,
       lp.max_value,
       lp.list
FROM   cdb_lockdown_profiles lp
       LEFT OUTER JOIN cdb_pdbs p ON lp.con_id = p.con_id
ORDER BY 1, 3;

-- End of lockdown_profiles.sql --

-- ########## Start of login.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/login.sql
-- Author       : Tim Hall
-- Description  : Resets the SQL*Plus prompt when a new connection is made.
--                Includes PDB:CDB.
-- Call Syntax  : @login
-- Last Modified: 21/04/2014
-- -----------------------------------------------------------------------------------
SET FEEDBACK OFF
SET TERMOUT OFF

COLUMN X NEW_VALUE Y
SELECT LOWER(USER || '@' || 
             SYS_CONTEXT('userenv', 'con_name') || ':' || 
             SYS_CONTEXT('userenv', 'instance_name')) X
FROM dual;
SET SQLPROMPT '&Y> '

ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS'; 
ALTER SESSION SET NLS_TIMESTAMP_FORMAT='DD-MON-YYYY HH24:MI:SS.FF'; 

SET TERMOUT ON
SET FEEDBACK ON
SET LINESIZE 100
SET TAB OFF
SET TRIM ON
SET TRIMSPOOL ON
-- End of login.sql --

-- ########## Start of pdb_spfiles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/pdb_spfiles.sql
-- Author       : Tim Hall
-- Description  : Displays information from the pdb_spfile$ table.
-- Requirements : Access to pdb_spfile$ and v$pdbs.
-- Call Syntax  : @pdb_spfiles
-- Last Modified: 04/05/2021
-- -----------------------------------------------------------------------------------
set linesize 120
column pdb_name format a10
column name format a30
column value$ format a30

select ps.db_uniq_name,
       ps.pdb_uid,
       p.name as pdb_name,
       ps.name,
       ps.value$
from   pdb_spfile$ ps
       join v$pdbs p on ps.pdb_uid = p.con_uid
order by 1, 2, 3;

-- End of pdb_spfiles.sql --

-- ########## Start of pdbs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/pdbs.sql
-- Author       : Tim Hall
-- Description  : Displays information about all PDBs in the current CDB.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @pdbs
-- Last Modified: 01/01/2019 - Added format for NAME column.
-- -----------------------------------------------------------------------------------

COLUMN pdb_name FORMAT A20

SELECT pdb_name, status
FROM   dba_pdbs
ORDER BY pdb_name;

COLUMN name FORMAT A20

SELECT name, open_mode
FROM   v$pdbs
ORDER BY name;

-- End of pdbs.sql --

-- ########## Start of plugin_violations.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/plugin_violations.sql
-- Author       : Tim Hall
-- Description  : Displays information about recent PDB plugin violations.
-- Requirements : 
-- Call Syntax  : @plugin_violations
-- Last Modified: 09-JAN-2017
-- -----------------------------------------------------------------------------------

SET LINESIZE 200

COLUMN time FORMAT A30
COLUMN name FORMAT A30
COLUMN cause FORMAT A30
COLUMN message FORMAT A30

SELECT time, name, cause, message
FROM   pdb_plug_in_violations
WHERE  time > TRUNC(SYSTIMESTAMP)
ORDER BY time;
-- End of plugin_violations.sql --

-- ########## Start of priv_captures.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/priv_captures.sql
-- Author       : Tim Hall
-- Description  : Displays privilege capture policies.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @priv_captures.sql
-- Last Modified: 22-APR-2014
-- -----------------------------------------------------------------------------------

COLUMN name FORMAT A15
COLUMN description FORMAT A30
COLUMN roles FORMAT A20
COLUMN context FORMAT A30
SET LINESIZE 200

SELECT name,
       description,
       type,
       enabled,
       roles,
       context
FROM   dba_priv_captures
ORDER BY name;
-- End of priv_captures.sql --

-- ########## Start of redaction_columns.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/redaction_columns.sql
-- Author       : Tim Hall
-- Description  : Displays information about columns related to redaction policies.
-- Requirements : Access to the REDACTION_COLUMNS view.
-- Call Syntax  : @redaction_columns (schema | all) (object | all)
-- Last Modified: 27-NOV-2014
-- -----------------------------------------------------------------------------------

SET LINESIZE 300 VERIFY OFF

COLUMN object_owner FORMAT A20
COLUMN object_name FORMAT A30
COLUMN column_name FORMAT A30
COLUMN function_parameters FORMAT A30
COLUMN regexp_pattern FORMAT A30
COLUMN regexp_replace_string FORMAT A30
COLUMN column_description FORMAT A20

SELECT object_owner,
       object_name,
       column_name,
       function_type,
       function_parameters,
       regexp_pattern,
       regexp_replace_string,
       regexp_position,
       regexp_occurrence,
       regexp_match_parameter,
       column_description
FROM   redaction_columns
WHERE  object_owner = DECODE(UPPER('&1'), 'ALL', object_owner, UPPER('&1'))
AND    object_name  = DECODE(UPPER('&2'), 'ALL', object_name, UPPER('&2'))
ORDER BY 1, 2, 3;

SET VERIFY ON
-- End of redaction_columns.sql --

-- ########## Start of redaction_policies.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/redaction_policies.sql
-- Author       : Tim Hall
-- Description  : Displays redaction policy information.
-- Requirements : Access to the REDACTION_POLICIES view.
-- Call Syntax  : @redaction_policies
-- Last Modified: 27-NOV-2014
-- -----------------------------------------------------------------------------------

SET LINESIZE 200

COLUMN object_owner FORMAT A20
COLUMN object_name FORMAT A30
COLUMN policy_name FORMAT A30
COLUMN expression FORMAT A30
COLUMN policy_description FORMAT A20

SELECT object_owner,
       object_name,
       policy_name,
       expression,
       enable,
       policy_description
FROM   redaction_policies
ORDER BY 1, 2, 3;
-- End of redaction_policies.sql --

-- ########## Start of redaction_value_defaults.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/12c/redaction_value_defaults.sql
-- Author       : Tim Hall
-- Description  : Displays information about redaction defaults.
-- Requirements : Access to the REDACTION_VALUES_FOR_TYPE_FULL view.
-- Call Syntax  : @redaction_value_defaults
-- Last Modified: 27-NOV-2014
-- -----------------------------------------------------------------------------------

SET LINESIZE 250
COLUMN char_value FORMAT A10
COLUMN varchar_value FORMAT A10
COLUMN nchar_value FORMAT A10
COLUMN nvarchar_value FORMAT A10
COLUMN timestamp_value FORMAT A27
COLUMN timestamp_with_time_zone_value FORMAT A32
COLUMN blob_value FORMAT A20
COLUMN clob_value FORMAT A10
COLUMN nclob_value FORMAT A10

SELECT *
FROM   redaction_values_for_type_full;

-- End of redaction_value_defaults.sql --

-- ########## Start of services.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/services.sql
-- Author       : Tim Hall
-- Description  : Displays information about database services.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @services
-- Last Modified: 05/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
COLUMN name FORMAT A30
COLUMN network_name FORMAT A50
COLUMN pdb FORMAT A20

SELECT name,
       network_name,
       pdb
FROM   dba_services
ORDER BY name;
-- End of services.sql --

-- ########## Start of lockdown_rules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/18c/lockdown_rules.sql
-- Author       : Tim Hall
-- Description  : Displays information about lockdown rules applis in the current container.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @lockdown_rules
-- Last Modified: 06/01/2019 - Switch to OUTER JOIN and alter ORDER BY.
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN rule_type FORMAT A20
COLUMN rule FORMAT A20
COLUMN clause FORMAT A20
COLUMN clause_option FORMAT A20
COLUMN pdb_name FORMAT A30

SELECT lr.rule_type,
       lr.rule,
       lr.status,
       lr.clause,
       lr.clause_option,
       lr.users,
       lr.con_id,
       p.pdb_name
FROM   v$lockdown_rules lr
       LEFT OUTER JOIN cdb_pdbs p ON lr.con_id = p.con_id
ORDER BY 1, 2;

-- End of lockdown_rules.sql --

-- ########## Start of max_pdb_snapshots.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/18c/max_pdb_snapshots.sql
-- Author       : Tim Hall
-- Description  : Displays the MAX_PDB_SNAPSHOTS setting for each container.
-- Requirements : Access to the CDB views.
-- Call Syntax  : @max_pdb_snapshots
-- Last Modified: 01/01/2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 150 TAB OFF

COLUMN property_name FORMAT A20
COLUMN pdb_name FORMAT A10
COLUMN property_value FORMAT A15
COLUMN description FORMAT A50

SELECT pr.con_id,
       p.pdb_name,
       pr.property_name, 
       pr.property_value,
       pr.description 
FROM   cdb_properties pr
       JOIN cdb_pdbs p ON pr.con_id = p.con_id 
WHERE  pr.property_name = 'MAX_PDB_SNAPSHOTS' 
ORDER BY pr.property_name;

-- End of max_pdb_snapshots.sql --

-- ########## Start of pdb_snapshot_mode.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/18c/pdb_snapshot_mode.sql
-- Author       : Tim Hall
-- Description  : Displays the SNAPSHOT_MODE and SNAPSHOT_INTERVAL setting for each container.
-- Requirements : Access to the CDB views.
-- Call Syntax  : @pdb_snapshot_mode
-- Last Modified: 01/01/2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 150 TAB OFF

COLUMN pdb_name FORMAT A10
COLUMN snapshot_mode FORMAT A15

SELECT p.con_id,
       p.pdb_name,
       p.snapshot_mode,
       p.snapshot_interval
FROM   cdb_pdbs p
ORDER BY 1;

-- End of pdb_snapshot_mode.sql --

-- ########## Start of pdb_snapshots.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/18c/pdb_snapshots.sql
-- Author       : Tim Hall
-- Description  : Displays the snapshots for all PDBs.
-- Requirements : Access to the CDB views.
-- Call Syntax  : @pdb_snapshots
-- Last Modified: 01/01/2019
-- -----------------------------------------------------------------------------------
SET LINESIZE 150 TAB OFF

COLUMN con_name FORMAT A10
COLUMN snapshot_name FORMAT A30
COLUMN snapshot_scn FORMAT 9999999
COLUMN full_snapshot_path FORMAT A50

SELECT con_id,
       con_name,
       snapshot_name, 
       snapshot_scn,
       full_snapshot_path 
FROM   cdb_pdb_snapshots
ORDER BY con_id, snapshot_scn;

-- End of pdb_snapshots.sql --

-- ########## Start of auto_index_config.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/19c/auto_index_config.sql
-- Author       : Tim Hall
-- Description  : Displays the auto-index configuration for each container.
-- Requirements : Access to the CDB views.
-- Call Syntax  : @auto_index_config
-- Last Modified: 04/06/2019
-- -----------------------------------------------------------------------------------
COLUMN parameter_name FORMAT A40
COLUMN parameter_value FORMAT A40

SELECT con_id, parameter_name, parameter_value 
FROM   cdb_auto_index_config
ORDER BY 1, 2;

-- End of auto_index_config.sql --

-- ########## Start of auto_indexes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/19c/auto_indexes.sql
-- Author       : Tim Hall
-- Description  : Displays auto indexes for the specified schema or all schemas.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @auto_indexes (schema-name or all)
-- Last Modified: 04/06/2019
-- -----------------------------------------------------------------------------------
SET VERIFY OFF LINESIZE 200

COLUMN owner FORMAT A30
COLUMN index_name FORMAT A30
COLUMN table_owner FORMAT A30
COLUMN table_name FORMAT A30

SELECT owner,
       index_name,
       index_type,
       table_owner,
       table_name
       table_type
FROM   dba_indexes
WHERE  owner = DECODE(UPPER('&1'), 'ALL', owner, UPPER('&1'))
AND    auto = 'YES'
ORDER BY owner, index_name;


-- End of auto_indexes.sql --

-- ########## Start of blockchain_tables.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/21c/blockchain_tables.sql
-- Author       : Tim Hall
-- Description  : Display blockchain tables in the specified schema, or all schemas.
-- Call Syntax  : @blockchain_tables (schema or all)
-- Last Modified: 23/12/2020
-- -----------------------------------------------------------------------------------
set linesize 200 verify off trimspool on

column schema_name format a30
column table_name format a30
column row_retention format a13
column row_retention_locked format a20
column table_inactivity_retention format a26
column hash_algorithm format a14

SELECT schema_name,
       table_name,
       row_retention,
       row_retention_locked, 
       table_inactivity_retention,
       hash_algorithm  
FROM   dba_blockchain_tables 
WHERE  schema_name = DECODE(UPPER('&1'), 'ALL', schema_name, UPPER('&1'));


-- End of blockchain_tables.sql --

-- ########## Start of certificates.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/21c/certificates.sql
-- Author       : Tim Hall
-- Description  : Display certificates in the specified schema, or all schemas.
-- Call Syntax  : @certificates (schema or all)
-- Last Modified: 23/12/2020
-- -----------------------------------------------------------------------------------
set linesize 200 verify off trimspool on

column user_name format a10
column distinguished_name format a30
column certificate format a30

select user_name,
       certificate_guid,
       distinguished_name,
       substr(certificate, 1, 25) || '...' as certificate
from   dba_certificates
where  user_name = DECODE(UPPER('&1'), 'ALL', user_name, UPPER('&1'))
order by user_name;

-- End of certificates.sql --

-- ########## Start of sql_macros.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/21c/sql_macros.sql
-- Author       : Tim Hall
-- Description  : Displays information about SQL macros for the specific schema, or all schemas.
-- Call Syntax  : @sql_macros (schema or all)
-- Last Modified: 27/12/2020
-- -----------------------------------------------------------------------------------
set linesize 150 verify off trimspool on
column owner format a30
column object_name format a30
column procedure_name format a30
column sql_macro format a9

select p.owner,
       o.object_type,
       p.sql_macro,
       p.object_name,
       p.procedure_name
from   dba_procedures p
       join dba_objects  o on p.object_id = o.object_id
where  p.sql_macro != 'NULL'
and    p.owner = decode(upper('&1'), 'ALL', p.owner, upper('&1'))
order by p.owner, o.object_type, p.sql_macro, p.object_name, p.procedure_name;

-- End of sql_macros.sql --

-- ########## Start of disable_chk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/disable_chk.sql
-- Author       : Tim Hall
-- Description  : Disables all check constraints for a specified table, or all tables.
-- Call Syntax  : @disable_chk (table-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' || a.constraint_name || '";'
FROM   all_constraints a
WHERE  a.constraint_type = 'C'
AND    a.owner           = UPPER('&2');
AND    a.table_name      = DECODE(UPPER('&1'),'ALL',a.table_name,UPPER('&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of disable_chk.sql --

-- ########## Start of disable_fk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/disable_fk.sql
-- Author       : Tim Hall
-- Description  : Disables all Foreign Keys belonging to the specified table, or all tables.
-- Call Syntax  : @disable_fk (table-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' || a.constraint_name || '";'
FROM   all_constraints a
WHERE  a.constraint_type = 'R'
AND    a.table_name      = DECODE(Upper('&1'),'ALL',a.table_name,Upper('&1'))
AND    a.owner           = Upper('&2');

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of disable_fk.sql --

-- ########## Start of disable_pk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/disable_pk.sql
-- Author       : Tim Hall
-- Description  : Disables the Primary Key for the specified table, or all tables.
-- Call Syntax  : @disable_pk (table-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE PRIMARY KEY;'
FROM   all_constraints a
WHERE  a.constraint_type = 'P'
AND    a.owner           = Upper('&2')
AND    a.table_name      = DECODE(Upper('&1'),'ALL',a.table_name,Upper('&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of disable_pk.sql --

-- ########## Start of disable_ref_fk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/disable_ref_fk.sql
-- Author       : Tim Hall
-- Description  : Disables all Foreign Keys referencing a specified table, or all tables.
-- Call Syntax  : @disable_ref_fk (table-name) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" DISABLE CONSTRAINT "' || a.constraint_name || '";' enable_constraints
FROM   all_constraints a
WHERE  a.owner      = Upper('&2')
AND    a.constraint_type = 'R'
AND    a.r_constraint_name IN (SELECT a1.constraint_name
                               FROM   all_constraints a1
                               WHERE  a1.table_name = DECODE(Upper('&1'),'ALL',a.table_name,Upper('&1'))
                               AND    a1.owner      = Upper('&2'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of disable_ref_fk.sql --

-- ########## Start of enable_chk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/enable_chk.sql
-- Author       : Tim Hall
-- Description  : Enables all check constraints for a specified table, or all tables.
-- Call Syntax  : @enable_chk (table-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE CONSTRAINT "' || a.constraint_name || '";'
FROM   all_constraints a
WHERE  a.constraint_type = 'C'
AND    a.owner           = Upper('&2');
AND    a.table_name      = DECODE(Upper('&1'),'ALL',a.table_name,UPPER('&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of enable_chk.sql --

-- ########## Start of enable_fk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/enable_fk.sql
-- Author       : Tim Hall
-- Description  : Enables all Foreign Keys belonging to the specified table, or all tables.
-- Call Syntax  : @enable_fk (table-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE CONSTRAINT "' || a.constraint_name || '";'
FROM   all_constraints a
WHERE  a.constraint_type = 'R'
AND    a.table_name      = DECODE(Upper('&1'),'ALL',a.table_name,Upper('&1'))
AND    a.owner           = Upper('&2');

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of enable_fk.sql --

-- ########## Start of enable_pk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/enable_pk.sql
-- Author       : Tim Hall
-- Description  : Enables the Primary Key for the specified table, or all tables.
-- Call Syntax  : @disable_pk (table-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE PRIMARY KEY;'
FROM   all_constraints a
WHERE  a.constraint_type = 'P'
AND    a.owner           = Upper('&2')
AND    a.table_name      = DECODE(Upper('&1'),'ALL',a.table_name,Upper('&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of enable_pk.sql --

-- ########## Start of enable_ref_fk.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/constraints/enable_ref_fk.sql
-- Author       : Tim Hall
-- Description  : Enables all Foreign Keys referencing a specified table, or all tables.
-- Call Syntax  : @enable_ref_fk (table-name) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TABLE "' || a.table_name || '" ENABLE CONSTRAINT "' || a.constraint_name || '";'
FROM   all_constraints a
WHERE  a.owner           = Upper('&2')
AND    a.constraint_type = 'R'
AND    a.r_constraint_name IN (SELECT a1.constraint_name
                               FROM   all_constraints a1
                               WHERE  a1.table_name = DECODE(Upper('&1'),'ALL',a.table_name,Upper('&1'))
                               AND    a1.owner      = Upper('&2'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of enable_ref_fk.sql --

-- ########## Start of analyze_all.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/analyze_all.sql
-- Author       : Tim Hall
-- Description  : Outdated script to analyze all tables for the specified schema.
-- Comment      : Use DBMS_UTILITY.ANALYZE_SCHEMA or DBMS_STATS.GATHER_SCHEMA_STATS if your server allows it.
-- Call Syntax  : @ananlyze_all (schema-name)
-- Last Modified: 26/02/2002
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ANALYZE TABLE "' || table_name || '" COMPUTE STATISTICS;'
FROM   all_tables
WHERE  owner = Upper('&1')
ORDER BY 1;

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of analyze_all.sql --

-- ########## Start of base64decode.sql ##########--
CREATE OR REPLACE FUNCTION base64decode(p_clob CLOB)
  RETURN BLOB
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/base64decode.sql
-- Author       : Tim Hall
-- Description  : Decodes a Base64 CLOB into a BLOB
-- Last Modified: 09/11/2011
-- -----------------------------------------------------------------------------------
IS
  l_blob    BLOB;
  l_raw     RAW(32767);
  l_amt     NUMBER := 7700;
  l_offset  NUMBER := 1;
  l_temp    VARCHAR2(32767);
BEGIN
  BEGIN
    DBMS_LOB.createtemporary (l_blob, FALSE, DBMS_LOB.CALL);
    LOOP
      DBMS_LOB.read(p_clob, l_amt, l_offset, l_temp);
      l_offset := l_offset + l_amt;
      l_raw    := UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(l_temp));
      DBMS_LOB.append (l_blob, TO_BLOB(l_raw));
    END LOOP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
  END;
  RETURN l_blob;
END;
/
-- End of base64decode.sql --

-- ########## Start of base64encode.sql ##########--
CREATE OR REPLACE FUNCTION base64encode(p_blob IN BLOB)
  RETURN CLOB
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/base64encode.sql
-- Author       : Tim Hall
-- Description  : Encodes a BLOB into a Base64 CLOB.
-- Last Modified: 09/11/2011
-- -----------------------------------------------------------------------------------
IS
  l_clob CLOB;
  l_step PLS_INTEGER := 12000; -- make sure you set a multiple of 3 not higher than 24573
BEGIN
  FOR i IN 0 .. TRUNC((DBMS_LOB.getlength(p_blob) - 1 )/l_step) LOOP
    l_clob := l_clob || UTL_RAW.cast_to_varchar2(UTL_ENCODE.base64_encode(DBMS_LOB.substr(p_blob, l_step, i * l_step + 1)));
  END LOOP;
  RETURN l_clob;
END;
/
-- End of base64encode.sql --

-- ########## Start of blob_to_clob.sql ##########--
CREATE OR REPLACE FUNCTION blob_to_clob (p_data  IN  BLOB)
  RETURN CLOB
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/blob_to_clob.sql
-- Author       : Tim Hall
-- Description  : Converts a BLOB to a CLOB.
-- Last Modified: 26/12/2016
-- -----------------------------------------------------------------------------------
AS
  l_clob         CLOB;
  l_dest_offset  PLS_INTEGER := 1;
  l_src_offset   PLS_INTEGER := 1;
  l_lang_context PLS_INTEGER := DBMS_LOB.default_lang_ctx;
  l_warning      PLS_INTEGER;
BEGIN

  DBMS_LOB.createTemporary(
    lob_loc => l_clob,
    cache   => TRUE);

  DBMS_LOB.converttoclob(
   dest_lob      => l_clob,
   src_blob      => p_data,
   amount        => DBMS_LOB.lobmaxsize,
   dest_offset   => l_dest_offset,
   src_offset    => l_src_offset, 
   blob_csid     => DBMS_LOB.default_csid,
   lang_context  => l_lang_context,
   warning       => l_warning);
   
   RETURN l_clob;
END;
/

-- End of blob_to_clob.sql --

-- ########## Start of blob_to_file.sql ##########--
CREATE OR REPLACE PROCEDURE blob_to_file (p_blob      IN  BLOB,
                                          p_dir       IN  VARCHAR2,
                                          p_filename  IN  VARCHAR2)
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/blob_to_file.sql
-- Author       : Tim Hall
-- Description  : Writes the contents of a BLOB to a file.
-- Last Modified: 26/02/2019 - Taken from 2005 article.
--                22/05/2020 - BLOB parameter switched from IN OUT NOCOPY to IN.
-- -----------------------------------------------------------------------------------
AS
  l_file      UTL_FILE.FILE_TYPE;
  l_buffer    RAW(32767);
  l_amount    BINARY_INTEGER := 32767;
  l_pos       INTEGER := 1;
  l_blob_len  INTEGER;
BEGIN
  l_blob_len := DBMS_LOB.getlength(p_blob);
  
  -- Open the destination file.
  l_file := UTL_FILE.fopen(p_dir, p_filename,'wb', 32767);

  -- Read chunks of the BLOB and write them to the file until complete.
  WHILE l_pos <= l_blob_len LOOP
    DBMS_LOB.read(p_blob, l_amount, l_pos, l_buffer);
    UTL_FILE.put_raw(l_file, l_buffer, TRUE);
    l_pos := l_pos + l_amount;
  END LOOP;
  
  -- Close the file.
  UTL_FILE.fclose(l_file);
  
EXCEPTION
  WHEN OTHERS THEN
    -- Close the file if something goes wrong.
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    RAISE;
END blob_to_file;
/

-- End of blob_to_file.sql --

-- ########## Start of clob_to_blob.sql ##########--
CREATE OR REPLACE FUNCTION clob_to_blob (p_data  IN  CLOB)
  RETURN BLOB
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/clob_to_blob.sql
-- Author       : Tim Hall
-- Description  : Converts a CLOB to a BLOB.
-- Last Modified: 26/12/2016
-- -----------------------------------------------------------------------------------
AS
  l_blob         BLOB;
  l_dest_offset  PLS_INTEGER := 1;
  l_src_offset   PLS_INTEGER := 1;
  l_lang_context PLS_INTEGER := DBMS_LOB.default_lang_ctx;
  l_warning      PLS_INTEGER := DBMS_LOB.warn_inconvertible_char;
BEGIN

  DBMS_LOB.createtemporary(
    lob_loc => l_blob,
    cache   => TRUE);

  DBMS_LOB.converttoblob(
   dest_lob      => l_blob,
   src_clob      => p_data,
   amount        => DBMS_LOB.lobmaxsize,
   dest_offset   => l_dest_offset,
   src_offset    => l_src_offset, 
   blob_csid     => DBMS_LOB.default_csid,
   lang_context  => l_lang_context,
   warning       => l_warning);

   RETURN l_blob;
END;
/

-- End of clob_to_blob.sql --

-- ########## Start of clob_to_file.sql ##########--
CREATE OR REPLACE PROCEDURE clob_to_file (p_clob      IN  CLOB,
                                          p_dir       IN  VARCHAR2,
                                          p_filename  IN  VARCHAR2)
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/clob_to_file.sql
-- Author       : Tim Hall
-- Description  : Writes the contents of a CLOB to a file.
-- Last Modified: 26/02/2019 - Taken from 2005 article.
--                22/05/2020 - BLOB parameter switched from IN OUT NOCOPY to IN.
--                03/07/2024 - Added FFLUSH, as suggested by Paul Joyce.
-- -----------------------------------------------------------------------------------
AS
  l_file    UTL_FILE.FILE_TYPE;
  l_buffer  VARCHAR2(32767);
  l_amount  BINARY_INTEGER := 32767;
  l_pos     INTEGER := 1;
BEGIN
  l_file := UTL_FILE.fopen(p_dir, p_filename, 'w', 32767);

  LOOP
    DBMS_LOB.read (p_clob, l_amount, l_pos, l_buffer);
    UTL_FILE.put(l_file, l_buffer);
    UTL_FILE.fflush(l_file);
    l_pos := l_pos + l_amount;
  END LOOP;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- Expected end.
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    RAISE;
END clob_to_file;
/

-- End of clob_to_file.sql --

-- ########## Start of column_comments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/column_comments.sql
-- Author       : Tim Hall
-- Description  : Displays comments associate with specific tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @column_comments (schema) (table-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
SET PAGESIZE 100
COLUMN column_name FORMAT A20
COLUMN comments    FORMAT A50

SELECT column_name,
       comments
FROM   dba_col_comments
WHERE  owner      = UPPER('&1')
AND    table_name = UPPER('&2')
ORDER BY column_name;

-- End of column_comments.sql --

-- ########## Start of comments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/comments.sql
-- Author       : Tim Hall
-- Description  : Displays all comments for the specified table and its columns.
-- Call Syntax  : @comments (table-name) (schema-name)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
PROMPT
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 255
SET PAGESIZE 1000

SELECT a.table_name "Table",
       a.table_type "Type",
       Substr(a.comments,1,200) "Comments"
FROM   all_tab_comments a
WHERE  a.table_name = Upper('&1')
AND    a.owner      = Upper('&2');

SELECT a.column_name "Column",
       Substr(a.comments,1,200) "Comments"
FROM   all_col_comments a
WHERE  a.table_name = Upper('&1')
AND    a.owner      = Upper('&2');

SET VERIFY ON
SET FEEDBACK ON
SET PAGESIZE 14
PROMPT

-- End of comments.sql --

-- ########## Start of compile_all.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid objects for specified schema, or all schema.
-- Requirements : Requires all other "Compile_All" scripts.
-- Call Syntax  : @compile_all (schema-name or all)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
@Compile_All_Specs &&1
@Compile_All_Bodies &&1
@Compile_All_Procs &&1
@Compile_All_Funcs &&1
@Compile_All_Views &&1

-- End of compile_all.sql --

-- ########## Start of compile_all_bodies.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all_bodies.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid package bodies for specified schema, or all schema.
-- Call Syntax  : @compile_all_bodies (schema-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER PACKAGE ' || a.owner || '.' || a.object_name || ' COMPILE BODY;'
FROM    all_objects a
WHERE   a.object_type = 'PACKAGE BODY'
AND     a.status      = 'INVALID'
AND     a.owner       = Decode(Upper('&&1'), 'ALL',a.owner, Upper('&&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of compile_all_bodies.sql --

-- ########## Start of compile_all_funcs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all_funcs.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid functions for specified schema, or all schema.
-- Call Syntax  : @compile_all_funcs (schema-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER FUNCTION ' || a.owner || '.' || a.object_name || ' COMPILE;'
FROM    all_objects a
WHERE   a.object_type = 'FUNCTION'
AND     a.status      = 'INVALID'
AND     a.owner       = Decode(Upper('&&1'), 'ALL',a.owner, Upper('&&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of compile_all_funcs.sql --

-- ########## Start of compile_all_procs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all_procs.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid procedures for specified schema, or all schema.
-- Call Syntax  : @compile_all_procs (schema-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER PROCEDURE ' || a.owner || '.' || a.object_name || ' COMPILE;'
FROM    all_objects a
WHERE   a.object_type = 'PROCEDURE'
AND     a.status      = 'INVALID'
AND     a.owner       = Decode(Upper('&&1'), 'ALL',a.owner, Upper('&&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of compile_all_procs.sql --

-- ########## Start of compile_all_specs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all_specs.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid package specifications for specified schema, or all schema.
-- Call Syntax  : @compile_all_specs (schema-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER PACKAGE ' || a.owner || '.' || a.object_name || ' COMPILE;'
FROM    all_objects a
WHERE   a.object_type = 'PACKAGE'
AND     a.status      = 'INVALID'
AND     a.owner       = Decode(Upper('&&1'), 'ALL',a.owner, Upper('&&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of compile_all_specs.sql --

-- ########## Start of compile_all_trigs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all_trigs.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid triggers for specified schema, or all schema.
-- Call Syntax  : @compile_all_trigs (schema-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER TRIGGER ' || a.owner || '.' || a.object_name || ' COMPILE;'
FROM    all_objects a
WHERE   a.object_type = 'TRIGGER'
AND     a.status      = 'INVALID'
AND     a.owner       = Decode(Upper('&&1'), 'ALL',a.owner, Upper('&&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of compile_all_trigs.sql --

-- ########## Start of compile_all_views.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/compile_all_views.sql
-- Author       : Tim Hall
-- Description  : Compiles all invalid views for specified schema, or all schema.
-- Call Syntax  : @compile_all_views (schema-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER VIEW ' || a.owner || '.' || a.object_name || ' COMPILE;'
FROM    all_objects a
WHERE   a.object_type = 'VIEW'
AND     a.status      = 'INVALID'
AND     a.owner       = Decode(Upper('&&1'), 'ALL',a.owner, Upper('&&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of compile_all_views.sql --

-- ########## Start of conversion_api.sql ##########--
CREATE OR REPLACE PACKAGE conversion_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/conversion_api.sql
-- Author       : Tim Hall
-- Description  : Provides some base conversion functions.
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   10-SEP-2003  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

FUNCTION to_base(p_dec   IN  NUMBER,
                 p_base  IN  NUMBER) RETURN VARCHAR2;

FUNCTION to_dec (p_str        IN  VARCHAR2,
                 p_from_base  IN  NUMBER DEFAULT 16) RETURN NUMBER;

FUNCTION to_hex(p_dec  IN  NUMBER) RETURN VARCHAR2;

FUNCTION to_bin(p_dec  IN  NUMBER) RETURN VARCHAR2;

FUNCTION to_oct(p_dec  IN  NUMBER) RETURN VARCHAR2;

END conversion_api;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY conversion_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/conversion_api.sql
-- Author       : Tim Hall
-- Description  : Provides some base conversion functions.
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   10-SEP-2003  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
FUNCTION to_base(p_dec   IN  NUMBER,
                 p_base  IN  NUMBER) RETURN VARCHAR2 IS
-- ----------------------------------------------------------------------------
	l_str	VARCHAR2(255) DEFAULT NULL;
	l_num	NUMBER	      DEFAULT p_dec;
	l_hex	VARCHAR2(16)  DEFAULT '0123456789ABCDEF';
BEGIN
	IF (TRUNC(p_dec) <> p_dec OR p_dec < 0) THEN
		RAISE PROGRAM_ERROR;
	END IF;
	LOOP
		l_str := SUBSTR(l_hex, MOD(l_num,p_base)+1, 1) || l_str;
		l_num := TRUNC(l_num/p_base);
		EXIT WHEN (l_num = 0);
	END LOOP;
	RETURN l_str;
END to_base;
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
FUNCTION to_dec (p_str        IN  VARCHAR2,
                 p_from_base  IN  NUMBER DEFAULT 16) RETURN NUMBER IS
-- ----------------------------------------------------------------------------
	l_num   NUMBER       DEFAULT 0;
	l_hex   VARCHAR2(16) DEFAULT '0123456789ABCDEF';
BEGIN
	FOR i IN 1 .. LENGTH(p_str) LOOP
		l_num := l_num * p_from_base + INSTR(l_hex,UPPER(SUBSTR(p_str,i,1)))-1;
	END LOOP;
	RETURN l_num;
END to_dec;
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
FUNCTION to_hex(p_dec  IN  NUMBER) RETURN VARCHAR2 IS
-- ----------------------------------------------------------------------------
BEGIN
	RETURN to_base(p_dec, 16);
END to_hex;
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
FUNCTION to_bin(p_dec  IN  NUMBER) RETURN VARCHAR2 IS
-- ----------------------------------------------------------------------------
BEGIN
	RETURN to_base(p_dec, 2);
END to_bin;
-- ----------------------------------------------------------------------------


-- ----------------------------------------------------------------------------
FUNCTION to_oct(p_dec  IN  NUMBER) RETURN VARCHAR2 IS
-- ----------------------------------------------------------------------------
BEGIN
	RETURN to_base(p_dec, 8);
END to_oct;
-- ----------------------------------------------------------------------------

END conversion_api;
/
SHOW ERRORS

-- End of conversion_api.sql --

-- ########## Start of csv.sql ##########--
CREATE OR REPLACE PACKAGE csv AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/cvs.sql
-- Author       : Tim Hall
-- Description  : Basic CSV API. For usage notes see:
--                  https://oracle-base.com/articles/9i/GeneratingCSVFiles.php
--
--                  CREATE OR REPLACE DIRECTORY dba_dir AS '/u01/app/oracle/dba/';
--
--                  EXEC csv.generate('DBA_DIR', 'generate.csv', p_query => 'SELECT * FROM emp');
--
-- Requirements : UTL_FILE, DBMS_SQL
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   14-MAY-2005  Tim Hall  Initial Creation
--   19-MAY-2016  Tim Hall  Add REF CURSOR support.
--   15-JAN-2019  Tim Hall  Add DBMS_OUTPUT support.
--   31-JAN-2019  Tim Hall  Add set_quotes procedure.
--   22-NOV-2020  Tim Hall  Amend set_quotes to allow control of string escaping.
--   16-MAY-2021  Tim Hall  Add set_date_format procedure.
--   23-NOV-2021  Tim Hall  Add timestamp support.
-- --------------------------------------------------------------------------

PROCEDURE generate (p_dir        IN  VARCHAR2,
                    p_file       IN  VARCHAR2,
                    p_query      IN  VARCHAR2);

PROCEDURE generate_rc (p_dir        IN  VARCHAR2,
                       p_file       IN  VARCHAR2,
                       p_refcursor  IN OUT SYS_REFCURSOR);

PROCEDURE output (p_query  IN  VARCHAR2);

PROCEDURE output_rc (p_refcursor  IN OUT SYS_REFCURSOR);

PROCEDURE set_separator (p_sep  IN  VARCHAR2);

PROCEDURE set_date_format (p_date_format  IN  VARCHAR2);

PROCEDURE set_ts_format (p_ts_format  IN  VARCHAR2);

PROCEDURE set_ts_ltz_format (p_ts_ltz_format  IN  VARCHAR2);

PROCEDURE set_ts_tz_format (p_ts_tz_format  IN  VARCHAR2);

PROCEDURE set_quotes (p_add_quotes  IN  BOOLEAN := TRUE,
                      p_quote_char  IN  VARCHAR2 := '"',
                      p_escape      IN  BOOLEAN := TRUE);

END csv;
/
SHOW ERRORS

CREATE OR REPLACE PACKAGE BODY csv AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/cvs.sql
-- Author       : Tim Hall
-- Description  : Basic CSV API. For usage notes see:
--                  https://oracle-base.com/articles/9i/GeneratingCSVFiles.php
--
--                  CREATE OR REPLACE DIRECTORY dba_dir AS '/u01/app/oracle/dba/';
--
--                  -- Query
--                  EXEC csv.generate('DBA_DIR', 'generate.csv', p_query => 'SELECT * FROM emp');
--
--                  -- Ref Cursor
--                  DECLARE
--                    l_refcursor  SYS_REFCURSOR;
--                  BEGIN
--                    OPEN l_refcursor FOR
--                      SELECT * FROM emp;
--                     
--                    csv.generate_rc('DBA_DIR','generate.csv', l_refcursor);
--                  END;
--                  /
--
--
-- Requirements : UTL_FILE, DBMS_SQL
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   14-MAY-2005  Tim Hall  Initial Creation
--   19-MAY-2016  Tim Hall  Add REF CURSOR support.
--   15-JAN-2019  Tim Hall  Add DBMS_OUTPUT support.
--   31-JAN-2019  Tim Hall  Add quotes to strings. Code suggested by Moose T.
--   22-NOV-2020  Tim Hall  Amend set_quotes to allow control of string escaping.
--                          Amend generate_all to include optional string escapes.
--                          Suggested by Anssi Kanninen.
--   02-MAR-2021  Tim Hall  Amend generate_all to also escape the escape character
--                          when present in the string.
--                          Suggested by Anssi Kanninen.
--   16-MAY-2021  Tim Hall  Add set_date_format procedure.
--                          Alter generate_all to use the date format.
--   23-NOV-2021  Tim Hall  Add timestamp support.
-- --------------------------------------------------------------------------

g_out_type         VARCHAR2(1)   := 'F';
g_sep              VARCHAR2(5)   := ',';
g_date_format      VARCHAR2(100) := 'yyyy-mm-dd hh24:mi:ss';
g_ts_format        VARCHAR2(100) := 'yyyy-mm-dd hh24:mi:ss.xff';
g_ts_ltz_format    VARCHAR2(100) := 'yyyy-mm-dd hh24:mi:ss.Xff am tzr';
g_ts_tz_format     VARCHAR2(100) := 'yyyy-mm-dd hh24:mi:ss.Xff am tzr';
g_add_quotes       BOOLEAN       := TRUE;
g_quote_char       VARCHAR2(1)   := '"';
g_escape           BOOLEAN       := TRUE;

-- Prototype for hidden procedures.
PROCEDURE generate_all (p_dir        IN  VARCHAR2,
                        p_file       IN  VARCHAR2,
                        p_query      IN  VARCHAR2,
                        p_refcursor  IN OUT SYS_REFCURSOR);

PROCEDURE put (p_file  IN  UTL_FILE.file_type,
               p_text  IN  VARCHAR2);

PROCEDURE new_line (p_file  IN  UTL_FILE.file_type);



-- Stub to generate a CSV from a query.
PROCEDURE generate (p_dir        IN  VARCHAR2,
                    p_file       IN  VARCHAR2,
                    p_query      IN  VARCHAR2) AS
  l_cursor  SYS_REFCURSOR;
BEGIN
  g_out_type := 'F';

  generate_all (p_dir        => p_dir,
                p_file       => p_file,
                p_query      => p_query,
                p_refcursor  => l_cursor);
END generate;


-- Stub to generate a CVS from a REF CURSOR.
PROCEDURE generate_rc (p_dir        IN  VARCHAR2,
                       p_file       IN  VARCHAR2,
                       p_refcursor  IN OUT SYS_REFCURSOR) AS
BEGIN
  g_out_type := 'F';

  generate_all (p_dir        => p_dir,
                p_file       => p_file,
                p_query      => NULL,
                p_refcursor  => p_refcursor);
END generate_rc;


-- Stub to output a CSV from a query.
PROCEDURE output (p_query  IN  VARCHAR2) AS
  l_cursor  SYS_REFCURSOR;
BEGIN
  g_out_type := 'D';

  generate_all (p_dir        => NULL,
                p_file       => NULL,
                p_query      => p_query,
                p_refcursor  => l_cursor);
END output;


-- Stub to output a CVS from a REF CURSOR.
PROCEDURE output_rc (p_refcursor  IN OUT SYS_REFCURSOR) AS
BEGIN
  g_out_type := 'D';

  generate_all (p_dir        => NULL,
                p_file       => NULL,
                p_query      => NULL,
                p_refcursor  => p_refcursor);
END output_rc;


-- Do the actual work.
PROCEDURE generate_all (p_dir        IN  VARCHAR2,
                        p_file       IN  VARCHAR2,
                        p_query      IN  VARCHAR2,
                        p_refcursor  IN OUT  SYS_REFCURSOR) AS
  l_cursor        PLS_INTEGER;
  l_rows          PLS_INTEGER;
  l_col_cnt       PLS_INTEGER;
  l_desc_tab      DBMS_SQL.desc_tab2;
  l_buffer        VARCHAR2(32767);
  l_date          DATE;
  l_ts            TIMESTAMP;
  l_ts_ltz        TIMESTAMP WITH LOCAL TIME ZONE;
  l_ts_tz         TIMESTAMP WITH TIME ZONE;
  l_is_str        BOOLEAN;
  l_is_date       BOOLEAN;
  l_is_ts         BOOLEAN;
  l_is_ts_ltz     BOOLEAN;
  l_is_ts_tz      BOOLEAN;

  l_file          UTL_FILE.file_type;
BEGIN
  IF p_query IS NOT NULL THEN
    l_cursor := DBMS_SQL.open_cursor;
    DBMS_SQL.parse(l_cursor, p_query, DBMS_SQL.native);
  ELSIF p_refcursor%ISOPEN THEN
     l_cursor := DBMS_SQL.to_cursor_number(p_refcursor);
  ELSE
    RAISE_APPLICATION_ERROR(-20000, 'You must specify a query or a REF CURSOR.');
  END IF;
  
  DBMS_SQL.describe_columns2 (l_cursor, l_col_cnt, l_desc_tab);

  FOR i IN 1 .. l_col_cnt LOOP
    CASE
      WHEN l_desc_tab(i).col_type = DBMS_TYPES.typecode_date THEN
        DBMS_SQL.define_column(l_cursor, i, l_date);
      WHEN l_desc_tab(i).col_type = 180 THEN
        DBMS_SQL.define_column(l_cursor, i, l_ts);
      WHEN l_desc_tab(i).col_type = 231 THEN
        DBMS_SQL.define_column(l_cursor, i, l_ts_ltz);
      WHEN l_desc_tab(i).col_type = 181 THEN
        DBMS_SQL.define_column(l_cursor, i, l_ts_tz);
      ELSE
        DBMS_SQL.define_column(l_cursor, i, l_buffer, 32767);
    END CASE;
  END LOOP;

  IF p_query IS NOT NULL THEN
    l_rows := DBMS_SQL.execute(l_cursor);
  END IF;
  
  IF g_out_type = 'F' THEN
    l_file := UTL_FILE.fopen(p_dir, p_file, 'w', 32767);
  END IF;

  -- Output the column names.
  FOR i IN 1 .. l_col_cnt LOOP
    IF i > 1 THEN
      put(l_file, g_sep);
    END IF;
    put(l_file, l_desc_tab(i).col_name);
  END LOOP;
  new_line(l_file);

  -- Output the data.
  LOOP
    EXIT WHEN DBMS_SQL.fetch_rows(l_cursor) = 0;

    FOR i IN 1 .. l_col_cnt LOOP
      IF i > 1 THEN
        put(l_file, g_sep);
      END IF;

      -- Reset flags.
      l_is_date   := FALSE;
      l_is_ts     := FALSE;
      l_is_ts_ltz := FALSE;
      l_is_ts_tz  := FALSE;
      l_is_str    := FALSE;

      dbms_output.put_line('Before : ' || l_desc_tab(i).col_type);

      -- Check if this is a date column.
      IF l_desc_tab(i).col_type = DBMS_TYPES.typecode_date THEN
        dbms_output.put_line('DATE : ' || l_desc_tab(i).col_type);
        l_is_date := TRUE;
        l_is_str := TRUE;
      END IF;

      -- Check if this is a timestamp column.
      IF l_desc_tab(i).col_type = 180  THEN
        dbms_output.put_line('TIMESTAMP : ' || l_desc_tab(i).col_type);
        l_is_ts := TRUE;
        l_is_str := TRUE;
      END IF;

      -- Check if this is a timestamp with local time zone column.
      IF l_desc_tab(i).col_type = 231  THEN
        dbms_output.put_line('TIMESTAMP WITH LOCAL TIME ZONE: ' || l_desc_tab(i).col_type);
        l_is_ts_ltz := TRUE;
        l_is_str := TRUE;
      END IF;

      -- Check if this is a timestamp with time zone column.
      IF l_desc_tab(i).col_type = 181  THEN
        dbms_output.put_line('TIMESTAMP WITH TIME ZONE: ' || l_desc_tab(i).col_type);
        l_is_ts_tz := TRUE;
        l_is_str := TRUE;
      END IF;

      -- Check if this is a string column.
      IF l_desc_tab(i).col_type IN (DBMS_TYPES.typecode_varchar,
                                    DBMS_TYPES.typecode_varchar2,
                                    DBMS_TYPES.typecode_char,
                                    DBMS_TYPES.typecode_clob,
                                    DBMS_TYPES.typecode_nvarchar2,
                                    DBMS_TYPES.typecode_nchar,
                                    DBMS_TYPES.typecode_nclob) THEN
        dbms_output.put_line('STRING : ' || l_desc_tab(i).col_type);
        l_is_str := TRUE;
      END IF;

      -- Get the value into the buffer in the correct format.
      CASE
        WHEN l_is_date THEN
          DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_date);
          l_buffer := to_char(l_date, g_date_format);
        WHEN l_is_ts THEN
          DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_ts);
          l_buffer := to_char(l_ts, g_ts_format);
        WHEN l_is_ts_ltz THEN
          DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_ts_ltz);
          l_buffer := to_char(l_ts_ltz, g_ts_ltz_format);
        WHEN l_is_ts_tz THEN
          DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_ts_tz);
          l_buffer := to_char(l_ts_tz, g_ts_tz_format);
        ELSE
          DBMS_SQL.COLUMN_VALUE(l_cursor, i, l_buffer);
      END CASE;

      -- Optionally add quotes for strings.
      IF g_add_quotes AND l_is_str THEN
        -- Optionally escape the quote character and the escape character in the string.
        IF g_escape THEN
          l_buffer := replace(l_buffer, '\', '\\');
          l_buffer := replace(l_buffer, g_quote_char, '\'||g_quote_char);
        END IF;
        l_buffer := g_quote_char || l_buffer || g_quote_char;
      END IF;

      -- Write the buffer to the file.
      put(l_file, l_buffer);
    END LOOP;
    new_line(l_file);
  END LOOP;

  IF UTL_FILE.is_open(l_file) THEN
    UTL_FILE.fclose(l_file);
  END IF;
  DBMS_SQL.close_cursor(l_cursor);
EXCEPTION
  WHEN OTHERS THEN
    IF UTL_FILE.is_open(l_file) THEN
      UTL_FILE.fclose(l_file);
    END IF;
    IF DBMS_SQL.is_open(l_cursor) THEN
      DBMS_SQL.close_cursor(l_cursor);
    END IF;
    DBMS_OUTPUT.put_line('ERROR: ' || DBMS_UTILITY.format_error_backtrace);
    RAISE;
END generate_all;


-- Alter separator from default.
PROCEDURE set_separator (p_sep  IN  VARCHAR2) AS
BEGIN
  g_sep := p_sep;
END set_separator;


-- Alter date format from default.
PROCEDURE set_date_format (p_date_format  IN  VARCHAR2) AS
BEGIN
  g_date_format := p_date_format;
END set_date_format;


-- Alter timestamp format from default.
PROCEDURE set_ts_format (p_ts_format  IN  VARCHAR2) AS
BEGIN
  g_ts_format := p_ts_format;
END set_ts_format;


-- Alter timestamp with local timezone format from default.
PROCEDURE set_ts_ltz_format (p_ts_ltz_format  IN  VARCHAR2) AS
BEGIN
  g_ts_ltz_format := p_ts_ltz_format;
END set_ts_ltz_format;


-- Alter timestamp with timezone format from default.
PROCEDURE set_ts_tz_format (p_ts_tz_format  IN  VARCHAR2) AS
BEGIN
  g_ts_tz_format := p_ts_tz_format;
END set_ts_tz_format;


-- Alter separator from default.
PROCEDURE set_quotes (p_add_quotes  IN  BOOLEAN := TRUE,
                      p_quote_char  IN  VARCHAR2 := '"',
                      p_escape      IN  BOOLEAN := TRUE) AS
BEGIN
  g_add_quotes := NVL(p_add_quotes, TRUE);
  g_quote_char := NVL(SUBSTR(p_quote_char,1,1), '"');
  g_escape     := NVL(p_escape, TRUE);
END set_quotes;


-- Handle put to file or screen.
PROCEDURE put (p_file  IN  UTL_FILE.file_type,
               p_text  IN  VARCHAR2) AS
BEGIN
  IF g_out_type = 'F' THEN
    UTL_FILE.put(p_file, p_text);
  ELSE
    DBMS_OUTPUT.put(p_text);
  END IF;
END put;


-- Handle newline to file or screen.
PROCEDURE new_line (p_file  IN  UTL_FILE.file_type) AS
BEGIN
  IF g_out_type = 'F' THEN
    UTL_FILE.new_line(p_file);
  ELSE
    DBMS_OUTPUT.new_line;
  END IF;
END new_line;

END csv;
/
SHOW ERRORS
-- End of csv.sql --

-- ########## Start of date_api.sql ##########--
CREATE OR REPLACE PACKAGE date_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/date_api.sql
-- Author       : Tim Hall
-- Description  : A package to hold date utilities.
-- Requirements : 
-- Amendments   :
--   When         Who       What
--   ===========  ========  =================================================
--   04-FEB-2015  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

FUNCTION oracle_to_unix (p_date IN DATE) RETURN NUMBER;
FUNCTION unix_to_oracle (p_unix IN NUMBER) RETURN DATE;

END date_api;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY date_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/date_api.sql
-- Author       : Tim Hall
-- Description  : A package to hold date utilities.
-- Requirements : 
-- Amendments   :
--   When         Who       What
--   ===========  ========  =================================================
--   04-FEB-2015  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

FUNCTION oracle_to_unix (p_date IN DATE) RETURN NUMBER AS
  l_number NUMBER;
BEGIN
  l_number := (p_date - TO_DATE('01/01/1970', 'DD/MM/YYYY'));
  RETURN  l_number * 86400000;
END oracle_to_unix;

FUNCTION unix_to_oracle (p_unix IN NUMBER) RETURN DATE AS
BEGIN
  RETURN TO_DATE('01/01/1970', 'DD/MM/YYYY') + (p_unix * 86400000);
END unix_to_oracle;

END date_api;
/
SHOW ERRORS

-- End of date_api.sql --

-- ########## Start of dict_comments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/dict_comments.sql
-- Author       : Tim Hall
-- Description  : Displays comments associate with specific tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @dict_comments (table-name or partial match)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
PROMPT
SET VERIFY OFF
SET FEEDBACK OFF
SET LINESIZE 255
SET PAGESIZE 1000

SELECT a.table_name "Table",
       Substr(a.comments,1,200) "Comments"
FROM   dictionary a
WHERE  a.table_name LIKE Upper('%&1%');

SET VERIFY ON
SET FEEDBACK ON
SET PAGESIZE 14
PROMPT

-- End of dict_comments.sql --

-- ########## Start of digest_auth_api.sql ##########--
CREATE OR REPLACE PACKAGE digest_auth_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/digest_auth_api.sql
-- Author       : Tim Hall
-- Description  : API to allow digest authentication when using UTL_HTTP.
--                The aim is this only replaces UTL_HTTP.BEGIN_REQUEST.
--                All other coding (wallet handling and processing the response)
--                are still done by you, in the normal way.
--
-- References   : This is heavily inspired by the blog post by Gary Myers.
--                http://blog.sydoracle.com/2014/03/plsql-utlhttp-and-digest-authentication.html
--                I make liberal use of the ideas, and in some cases the code, he discussed in
--                that blog post!
--                For setting up certificates and wallets, see this article.
--                https://oracle-base.com/articles/misc/utl_http-and-ssl
--
-- License      : Free for personal and commercial use.
--                You can amend the code, but leave existing the headers, current
--                amendments history and links intact.
--                Copyright and disclaimer available here:
--                https://oracle-base.com/misc/site-info.php#copyright
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   11-DEC-2015  Tim Hall  Initial Creation
--   30-JUN-2016  Tim Hall  Add debug_on and debug_off procedures.
-- --------------------------------------------------------------------------

/*
Example call.

SET SERVEROUTPUT ON
DECLARE
  l_url            VARCHAR2(32767) := 'https://example.com/ws/get-something';
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_text           VARCHAR2(32767);
BEGIN
  -- Set wallet credentials.
  UTL_HTTP.set_wallet('file:/path/to/wallet', 'wallet-password');

  -- Make a HTTP request and get the response.
  l_http_request  := digest_auth_api.begin_request(p_url          => l_url,
                                                   p_username     => 'my-username',
                                                   p_password     => 'my-password',
                                                   p_method       => 'GET');

  l_http_response := UTL_HTTP.get_response(l_http_request);

  -- Loop through the response.
  BEGIN
    LOOP
      UTL_HTTP.read_text(l_http_response, l_text, 32767);
      DBMS_OUTPUT.put_line (l_text);
    END LOOP;
  EXCEPTION
    WHEN UTL_HTTP.end_of_body THEN
      UTL_HTTP.end_response(l_http_response);
  END;

EXCEPTION
  WHEN OTHERS THEN
    UTL_HTTP.end_response(l_http_response);
    RAISE;
END;

*/
-- --------------------------------------------------------------------------

PROCEDURE debug_on;

PROCEDURE debug_off;

FUNCTION begin_request(p_url          IN VARCHAR2,
                       p_username     IN VARCHAR2,
                       p_password     IN VARCHAR2,
                       p_method       IN VARCHAR2 DEFAULT 'GET',
                       p_http_version IN VARCHAR2 DEFAULT 'HTTP/1.1',
                       p_req_cnt      IN PLS_INTEGER DEFAULT 1)
  RETURN UTL_HTTP.req;

END digest_auth_api;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY digest_auth_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/digest_auth_api.sql
-- Author       : Tim Hall
-- Description  : API to allow digest authentication when using UTL_HTTP.
--                The aim is this only replaces UTL_HTTP.BEGIN_REQUEST.
--                All other coding (wallet handling and processing the response)
--                are still done by you, in the normal way.
--
-- References   : This is heavily inspired by the blog post by Gary Myers.
--                http://blog.sydoracle.com/2014/03/plsql-utlhttp-and-digest-authentication.html
--                I make liberal use of the ideas, and in some cases the code, he discussed in
--                that blog post!
--                For setting up certificates and wallets, see this article.
--                https://oracle-base.com/articles/misc/utl_http-and-ssl
--
-- License      : Free for personal and commercial use.
--                You can amend the code, but leave existing the headers, current
--                amendments history and links intact.
--                Copyright and disclaimer available here:
--                https://oracle-base.com/misc/site-info.php#copyright
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   11-DEC-2015  Tim Hall  Initial Creation
--   30-JUN-2016  Tim Hall  Add debug_on and debug_off procedures.
-- --------------------------------------------------------------------------

-- Package variables.
g_debug   BOOLEAN := FALSE;

-- Set by call to get_header_info.
g_server  VARCHAR2(32767);
g_realm   VARCHAR2(32767);
g_qop     VARCHAR2(32767);
g_nonce   VARCHAR2(32767);
g_opaque  VARCHAR2(32767);
g_cnonce  VARCHAR2(32767);

-- Prototypes.
PROCEDURE debug (p_text IN VARCHAR2);

PROCEDURE init;

PROCEDURE get_header_info (p_http_response IN OUT NOCOPY UTL_HTTP.resp);

FUNCTION get_response (p_username IN VARCHAR2,
                       p_password IN VARCHAR2,
                       p_uri      IN VARCHAR2,
                       p_method   IN VARCHAR2 DEFAULT 'GET',
                       p_req_cnt  IN NUMBER DEFAULT 1)
RETURN VARCHAR2;



-- Real stuff starts here.

-- -----------------------------------------------------------------------------
PROCEDURE debug_on AS
BEGIN
  g_debug := TRUE;
END debug_on;
-- -----------------------------------------------------------------------------



-- -----------------------------------------------------------------------------
PROCEDURE debug_off AS
BEGIN
  g_debug := FALSE;
END debug_off;
-- -----------------------------------------------------------------------------



-- -----------------------------------------------------------------------------
PROCEDURE debug (p_text IN VARCHAR2) AS
BEGIN
  IF g_debug THEN
    DBMS_OUTPUT.put_line(p_text);
  END IF;
END debug;
-- -----------------------------------------------------------------------------



-- -----------------------------------------------------------------------------
PROCEDURE init IS
BEGIN
  g_server  := NULL;
  g_realm   := NULL;
  g_qop     := NULL;
  g_nonce   := NULL;
  g_opaque  := NULL;
  g_cnonce  := NULL;
END init;
-- -----------------------------------------------------------------------------



-- -----------------------------------------------------------------------------
PROCEDURE get_header_info (p_http_response IN OUT NOCOPY UTL_HTTP.resp) IS

  l_name            VARCHAR2(256);
  l_value           VARCHAR2(1024);
BEGIN
  FOR i IN 1..UTL_HTTP.get_header_count(p_http_response) LOOP
    UTL_HTTP.get_header(p_http_response, i, l_name, l_value);
    debug('------ Header (' || i || ') ------');
    debug('l_name=' || l_name);
    debug('l_value=' || l_value);
    IF l_name = 'Server' THEN
      g_server := l_value;
      debug('g_server=' || g_server);
    END IF;

    IF l_name = 'WWW-Authenticate' THEN
      g_realm  := SUBSTR(REGEXP_SUBSTR(l_value, 'realm="[^"]+' ),8);
      g_qop    := SUBSTR(REGEXP_SUBSTR(l_value, 'qop="[^"]+'   ),6);
      g_nonce  := SUBSTR(REGEXP_SUBSTR(l_value, 'nonce="[^"]+' ),8);
      g_opaque := SUBSTR(REGEXP_SUBSTR(l_value, 'opaque="[^"]+'),9);

      debug('g_realm=' || g_realm);
      debug('g_qop=' || g_qop);
      debug('g_nonce=' || g_nonce);
      debug('g_opaque=' || g_opaque);
    END IF;
  END LOOP;

  g_cnonce := LOWER(UTL_RAW.cast_to_raw(DBMS_OBFUSCATION_TOOLKIT.md5(input_string => DBMS_RANDOM.value)));
  debug('g_cnonce=' || g_cnonce);
END get_header_info;
-- -----------------------------------------------------------------------------



-- -----------------------------------------------------------------------------
FUNCTION get_response (p_username IN VARCHAR2,
                       p_password IN VARCHAR2,
                       p_uri      IN VARCHAR2,
                       p_method   IN VARCHAR2 DEFAULT 'GET',
                       p_req_cnt  IN NUMBER DEFAULT 1)
RETURN VARCHAR2 IS
  l_text      VARCHAR2(2000);
  l_raw       RAW(2000);
  l_out       VARCHAR2(60);
  l_ha1       VARCHAR2(40);
  l_ha2       VARCHAR2(40);
BEGIN
  l_text := p_username || ':' || g_realm || ':' || p_password;
  l_raw  := UTL_RAW.cast_to_raw(l_text);
  l_out  := DBMS_OBFUSCATION_TOOLKIT.md5(input => l_raw);
  l_ha1  := LOWER(l_out);

  l_text := p_method || ':' || p_uri;
  l_raw  := UTL_RAW.cast_to_raw(l_text);
  l_out  := DBMS_OBFUSCATION_TOOLKIT.md5(input => l_raw);
  l_ha2  := LOWER(l_out);

  l_text := l_ha1 || ':' || g_nonce || ':' || LPAD(p_req_cnt,8,0) || ':' || g_cnonce || ':' || g_qop || ':' || l_ha2;
  l_raw  := UTL_RAW.cast_to_raw(l_text);
  l_out  := DBMS_OBFUSCATION_TOOLKIT.md5(input => l_raw);

  RETURN LOWER(l_out);
END get_response;
-- -----------------------------------------------------------------------------



-- -----------------------------------------------------------------------------
FUNCTION begin_request(p_url          IN VARCHAR2,
                       p_username     IN VARCHAR2,
                       p_password     IN VARCHAR2,
                       p_method       IN VARCHAR2 DEFAULT 'GET',
                       p_http_version IN VARCHAR2 DEFAULT 'HTTP/1.1',
                       p_req_cnt      IN PLS_INTEGER DEFAULT 1)
  RETURN UTL_HTTP.req
AS
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_text           VARCHAR2(32767);
  l_uri            VARCHAR2(32767);
  l_response       VARCHAR2(32767);
BEGIN
  init;

  -- Make a request that will fail to get the header information.
  -- This will be used to build up the pieces for the digest authentication
  -- using a call to get_header_info.
  l_http_request  := UTL_HTTP.begin_request(p_url, p_method);
  l_http_response := UTL_HTTP.get_response(l_http_request);
  get_header_info (l_http_response);
  UTL_HTTP.end_response(l_http_response);

  -- Get everything after the domain as the URI.
  l_uri := SUBSTR(p_url, INSTR(p_url, '/', 1, 3));

  l_response := get_response(p_username => p_username,
                             p_password => p_password,
                             p_uri      => l_uri,
                             p_method   => p_method,
                             p_req_cnt  => p_req_cnt);

  -- Build the final digest string.
  l_text := 'Digest username="' || p_username ||'",'||
            ' realm="'          || g_realm ||'",'||
            ' nonce="'          || g_nonce ||'",'||
            ' uri="'            || l_uri ||'",'||
            ' response="'       || l_response ||'",'||
            ' qop='             || g_qop ||',' ||
            ' nc='              || LPAD(p_req_cnt,8,0) ||',' ||
            ' cnonce="'         || g_cnonce      ||'"';

  IF g_opaque IS NOT NULL THEN
    l_text := l_text || ',opaque="'||g_opaque||'"';
  END IF;
  debug(l_text);

  -- Make the new request and set the digest authorization.
  l_http_request  := UTL_HTTP.begin_request(p_url, p_method);
  UTL_HTTP.SET_HEADER(l_http_request, 'Authorization', l_text);

  RETURN l_http_request;
EXCEPTION
  WHEN OTHERS THEN
    UTL_HTTP.end_response(l_http_response);
    RAISE;
END begin_request;
-- -----------------------------------------------------------------------------

END digest_auth_api;
/
SHOW ERRORS

-- End of digest_auth_api.sql --

-- ########## Start of drop_all.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/drop_all.sql
-- Author       : Tim Hall
-- Description  : Drops all objects within the current schema.
-- Call Syntax  : @drop_all
-- Last Modified: 20/01/2006
-- Notes        : Loops a maximum of 5 times, allowing for failed drops due to dependencies.
--                Quits outer loop if no drops were atempted.
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
DECLARE
  l_count    NUMBER;
  l_cascade  VARCHAR2(20);
BEGIN
  << dependency_failure_loop >>
  FOR i IN 1 .. 5 LOOP
    EXIT dependency_failure_loop WHEN l_count = 0;
    l_count := 0;
    
    FOR cur_rec IN (SELECT object_name, object_type 
                    FROM   user_objects) LOOP
      BEGIN
        l_count := l_count + 1;
        l_cascade := NULL;
        IF cur_rec.object_type = 'TABLE' THEN
          l_cascade := ' CASCADE CONSTRAINTS';
        END IF;
        EXECUTE IMMEDIATE 'DROP ' || cur_rec.object_type || ' "' || cur_rec.object_name || '"' || l_cascade;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    END LOOP;
    -- Comment out the following line if you are pre-10g, or want to preserve the recyclebin contents. 
    EXECUTE IMMEDIATE 'PURGE RECYCLEBIN';
    DBMS_OUTPUT.put_line('Pass: ' || i || '  Drops: ' || l_count);
  END LOOP;
END;
/

-- End of drop_all.sql --

-- ########## Start of file_to_blob.sql ##########--
CREATE OR REPLACE PROCEDURE file_to_blob (p_blob      IN OUT NOCOPY BLOB,
                                          p_dir       IN  VARCHAR2,
                                          p_filename  IN  VARCHAR2)
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/file_to_blob.sql
-- Author       : Tim Hall
-- Description  : Loads the contents of a file into a BLOB.
-- Last Modified: 26/02/2019 - Taken from 2005 article.
-- -----------------------------------------------------------------------------------
AS
  l_bfile  BFILE;

  l_dest_offset INTEGER := 1;
  l_src_offset  INTEGER := 1;
BEGIN
  l_bfile := BFILENAME(p_dir, p_filename);
  DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
  DBMS_LOB.trim(p_blob, 0);
  IF DBMS_LOB.getlength(l_bfile) > 0 THEN
    DBMS_LOB.loadblobfromfile (
      dest_lob    => p_blob,
      src_bfile   => l_bfile,
      amount      => DBMS_LOB.lobmaxsize,
      dest_offset => l_dest_offset,
      src_offset  => l_src_offset);
  END IF;
  DBMS_LOB.fileclose(l_bfile);
END file_to_blob;
/

-- End of file_to_blob.sql --

-- ########## Start of file_to_clob.sql ##########--
CREATE OR REPLACE PROCEDURE file_to_clob (p_clob      IN OUT NOCOPY CLOB,
                                          p_dir       IN  VARCHAR2,
                                          p_filename  IN  VARCHAR2)
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/file_to_clob.sql
-- Author       : Tim Hall
-- Description  : Loads the contents of a file into a CLOB.
-- Last Modified: 26/02/2019 - Taken from 2005 article.
-- -----------------------------------------------------------------------------------
AS
  l_bfile  BFILE;

  l_dest_offset   INTEGER := 1;
  l_src_offset    INTEGER := 1;
  l_bfile_csid    NUMBER  := 0;
  l_lang_context  INTEGER := 0;
  l_warning       INTEGER := 0;
BEGIN
  l_bfile := BFILENAME(p_dir, p_filename);
  DBMS_LOB.fileopen(l_bfile, DBMS_LOB.file_readonly);
  DBMS_LOB.trim(p_clob, 0);
  DBMS_LOB.loadclobfromfile (
    dest_lob      => p_clob,
    src_bfile     => l_bfile,
    amount        => DBMS_LOB.lobmaxsize,
    dest_offset   => l_dest_offset,
    src_offset    => l_src_offset,
    bfile_csid    => l_bfile_csid ,
    lang_context  => l_lang_context,
    warning       => l_warning);
  DBMS_LOB.fileclose(l_bfile);
END file_to_clob;
/

-- End of file_to_clob.sql --

-- ########## Start of find_object.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/find_object.sql
-- Author       : Tim Hall
-- Description  : Lists all objects with a similar name to that specified.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @find_object (object-name)
-- Last Modified: 26-JUL-2016
-- -----------------------------------------------------------------------------------

SET VERIFY OFF LINESIZE 200

COLUMN object_name FORMAT A30
COLUMN owner FORMAT A20

SELECT object_name, owner, object_type, status
FROM   dba_objects
WHERE  LOWER(object_name) LIKE '%' || LOWER('&1') || '%'
ORDER BY 1, 2, 3;

-- End of find_object.sql --

-- ########## Start of gen_health.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/gen_health.sql
-- Author       : Tim Hall
-- Description  : Miscellaneous queries to check the general health of the system.
-- Call Syntax  : @gen_health
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SELECT file_id, 
       tablespace_name, 
       file_name, 
       status 
FROM   sys.dba_data_files; 

SELECT file#, 
       name, 
       status, 
       enabled 
FROM   v$datafile;

SELECT * 
FROM   v$backup;

SELECT * 
FROM   v$recovery_status;

SELECT * 
FROM   v$recover_file;

SELECT * 
FROM   v$recovery_file_status;

SELECT * 
FROM   v$recovery_log;

SELECT username, 
       command, 
       status, 
       module 
FROM   v$session;


-- End of gen_health.sql --

-- ########## Start of get_pivot.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/get_pivot.sql
-- Author       : Tim Hall
-- Description  : Creates a function to produce a virtual pivot table with the specific values.
-- Requirements : CREATE TYPE, CREATE PROCEDURE
-- Call Syntax  : @get_pivot.sql
-- Last Modified: 13/08/2003
-- -----------------------------------------------------------------------------------

CREATE OR REPLACE TYPE t_pivot AS TABLE OF NUMBER;
/

CREATE OR REPLACE FUNCTION get_pivot(p_max   IN  NUMBER,
                                     p_step  IN  NUMBER DEFAULT 1) 
  RETURN t_pivot AS
  l_pivot t_pivot := t_pivot();
BEGIN
  FOR i IN 0 .. TRUNC(p_max/p_step) LOOP
    l_pivot.extend;
    l_pivot(l_pivot.last) := 1 + (i * p_step);
  END LOOP;
  RETURN l_pivot;
END;
/
SHOW ERRORS

SELECT column_value
FROM   TABLE(get_pivot(17,2));
                            

-- End of get_pivot.sql --

-- ########## Start of get_stat.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/get_stat.sql
-- Author       : Tim Hall
-- Description  : A function to return the specified statistic value.
-- Requirements : Select on V_$MYSTAT and V_$STATNAME.
-- Call Syntax  : Example of checking the amount of PGA memory allocated.
-- 
-- DECLARE
--   l_start NUMBER;
-- BEGIN
--   l_start := get_stat('session pga memory');
-- 
--   -- Do something.
-- 
--   DBMS_OUTPUT.put_line('PGA Memory Allocated : ' || (get_stat('session pga memory') - g_start) || ' bytes');
-- END;
-- /
-- 
-- Last Modified: 05/03/2018
-- -----------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_stat (p_stat IN VARCHAR2) RETURN NUMBER AS
  l_return  NUMBER;
BEGIN
  SELECT ms.value
  INTO   l_return
  FROM   v$mystat ms,
         v$statname sn
  WHERE  ms.statistic# = sn.statistic#
  AND    sn.name = p_stat;
  RETURN l_return;
END get_stat;
/
-- End of get_stat.sql --

-- ########## Start of login.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/login.sql
-- Author       : Tim Hall
-- Description  : Resets the SQL*Plus prompt when a new connection is made.
-- Call Syntax  : @login
-- Last Modified: 04/03/2004
-- -----------------------------------------------------------------------------------
SET FEEDBACK OFF
SET TERMOUT OFF

COLUMN X NEW_VALUE Y
SELECT LOWER(USER || '@' || SYS_CONTEXT('userenv', 'instance_name')) X FROM dual;
SET SQLPROMPT '&Y> '

ALTER SESSION SET NLS_DATE_FORMAT='DD-MON-YYYY HH24:MI:SS'; 
ALTER SESSION SET NLS_TIMESTAMP_FORMAT='DD-MON-YYYY HH24:MI:SS.FF'; 

SET TERMOUT ON
SET FEEDBACK ON
SET LINESIZE 100
SET TAB OFF
SET TRIM ON
SET TRIMSPOOL ON

-- End of login.sql --

-- ########## Start of part_hv_to_date.sql ##########--
CREATE OR REPLACE FUNCTION part_hv_to_date (p_table_owner    IN  VARCHAR2,
                                            p_table_name     IN VARCHAR2,
                                            p_partition_name IN VARCHAR2)
  RETURN DATE
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/part_hv_to_date.sql
-- Author       : Tim Hall
-- Description  : Create a function to turn partition HIGH_VALUE column to a date.
-- Call Syntax  : @part_hv_to_date
-- Last Modified: 19/01/2012
-- Notes        : Has to re-select the value from the view as LONG cannot be passed as a parameter.
--                Example call:
--
-- SELECT a.partition_name, 
--        part_hv_to_date(a.table_owner, a.table_name, a.partition_name) as high_value
-- FROM   all_tab_partitions a;
--
-- Does no error handling. 
-- -----------------------------------------------------------------------------------
AS
  l_high_value VARCHAR2(32767);
  l_date DATE;
BEGIN
  SELECT high_value
  INTO   l_high_value
  FROM   all_tab_partitions
  WHERE  table_owner    = p_table_owner
  AND    table_name     = p_table_name
  AND    partition_name = p_partition_name;
  
  EXECUTE IMMEDIATE 'SELECT ' || l_high_value || ' FROM dual' INTO l_date;
  RETURN l_date;
END;
/
-- End of part_hv_to_date.sql --

-- ########## Start of print_table.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/print_table.sql
-- Author       : Tom Kyte
-- Reference    : https://asktom.oracle.com/pls/apex/f?p=100:11:0::::P11_QUESTION_ID:1035431863958#14442395195806
-- Description  : Turns resultset columns into rows for any query.
-- Requirements : 
-- Call Syntax  : set server output on
--                exec print_table('select * from my_table');
-- Last Modified: 18-DEC-2003
-- -----------------------------------------------------------------------------------

create or replace
procedure print_table
( p_query in varchar2,
p_date_fmt in varchar2 default 'dd-mon-yyyy hh24:mi:ss' )

-- this utility is designed to be installed ONCE in a database and used
-- by all. Also, it is nice to have roles enabled so that queries by
-- DBA's that use a role to gain access to the DBA_* views still work
-- that is the purpose of AUTHID CURRENT_USER
AUTHID CURRENT_USER
is
l_theCursor integer default dbms_sql.open_cursor;
l_columnValue varchar2(4000);
l_status integer;
l_descTbl dbms_sql.desc_tab;
l_colCnt number;
l_cs varchar2(255);
l_date_fmt varchar2(255);

-- small inline procedure to restore the sessions state
-- we may have modified the cursor sharing and nls date format
-- session variables, this just restores them
procedure restore
is
begin
if ( upper(l_cs) not in ( 'FORCE','SIMILAR' ))
then
execute immediate
'alter session set cursor_sharing=exact';
end if;
if ( p_date_fmt is not null )
then
execute immediate
'alter session set nls_date_format=''' || l_date_fmt || '''';
end if;
dbms_sql.close_cursor(l_theCursor);
end restore;
begin
-- I like to see the dates print out with times, by default, the
-- format mask I use includes that. In order to be "friendly"
-- we save the date current sessions date format and then use
-- the one with the date and time. Passing in NULL will cause
-- this routine just to use the current date format
if ( p_date_fmt is not null )
then
select sys_context( 'userenv', 'nls_date_format' )
into l_date_fmt
from dual;

execute immediate
'alter session set nls_date_format=''' || p_date_fmt || '''';
end if;

-- to be bind variable friendly on this ad-hoc queries, we
-- look to see if cursor sharing is already set to FORCE or
-- similar, if not, set it so when we parse -- literals
-- are replaced with binds
if ( dbms_utility.get_parameter_value
( 'cursor_sharing', l_status, l_cs ) = 1 )
then
if ( upper(l_cs) not in ('FORCE','SIMILAR'))
then
execute immediate
'alter session set cursor_sharing=force';
end if;
end if;

-- parse and describe the query sent to us. we need
-- to know the number of columns and their names.
dbms_sql.parse( l_theCursor, p_query, dbms_sql.native );
dbms_sql.describe_columns
( l_theCursor, l_colCnt, l_descTbl );

-- define all columns to be cast to varchar2's, we
-- are just printing them out
for i in 1 .. l_colCnt loop
if ( l_descTbl(i).col_type not in ( 113 ) )
then
dbms_sql.define_column
(l_theCursor, i, l_columnValue, 4000);
end if;
end loop;

-- execute the query, so we can fetch
l_status := dbms_sql.execute(l_theCursor);

-- loop and print out each column on a separate line
-- bear in mind that dbms_output only prints 255 characters/line
-- so we'll only see the first 200 characters by my design...
while ( dbms_sql.fetch_rows(l_theCursor) > 0 )
loop
for i in 1 .. l_colCnt loop
if ( l_descTbl(i).col_type not in ( 113 ) )
then
dbms_sql.column_value
( l_theCursor, i, l_columnValue );
dbms_output.put_line
( rpad( l_descTbl(i).col_name, 30 )
|| ': ' ||
substr( l_columnValue, 1, 200 ) );
end if;
end loop;
dbms_output.put_line( '-----------------' );
end loop;

-- now, restore the session state, no matter what
restore;
exception
when others then
restore;
raise;
end;
/

-- End of print_table.sql --

-- ########## Start of proc_defs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/proc_defs.sql
-- Author       : Tim Hall
-- Description  : Lists the parameters for the specified package and procedure.
-- Call Syntax  : @proc_defs (package-name) (procedure-name or all)
-- Last Modified: 24/09/2003
-- -----------------------------------------------------------------------------------
COLUMN "Object Name" FORMAT A30
COLUMN ol FORMAT A2
COLUMN sq FORMAT 99
COLUMN "Argument Name" FORMAT A32
COLUMN "Type" FORMAT A15
COLUMN "Size" FORMAT A6
BREAK ON ol SKIP 2
SET PAGESIZE 0
SET LINESIZE 200
SET TRIMOUT ON
SET TRIMSPOOL ON
SET VERIFY OFF

SELECT object_name AS "Object Name",
       overload AS ol,
       sequence AS sq,
       RPAD(' ', data_level*2, ' ') || argument_name AS "Argument Name",
       data_type AS "Type",
       (CASE
         WHEN data_type IN ('VARCHAR2','CHAR') THEN TO_CHAR(data_length)
         WHEN data_scale IS NULL OR data_scale = 0 THEN TO_CHAR(data_precision)
         ELSE TO_CHAR(data_precision) || ',' || TO_CHAR(data_scale)
       END) "Size",
       in_out AS "In/Out",
       default_value
FROM   user_arguments
WHERE  package_name = UPPER('&1')
AND    object_name  = DECODE(UPPER('&2'), 'ALL', object_name, UPPER('&2'))
ORDER BY object_name, overload, sequence;

SET PAGESIZE 14
SET LINESIZE 80

-- End of proc_defs.sql --

-- ########## Start of rebuild_index.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/rebuild_index.sql
-- Author       : Tim Hall
-- Description  : Rebuilds the specified index, or all indexes.
-- Call Syntax  : @rebuild_index (index-name or all) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'ALTER INDEX ' || a.index_name || ' REBUILD;'
FROM   all_indexes a
WHERE  index_name  = DECODE(Upper('&1'),'ALL',a.index_name,Upper('&1'))
AND    table_owner = Upper('&2')
ORDER BY 1
/

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of rebuild_index.sql --

-- ########## Start of smart_quotes_api.sql ##########--
CREATE OR REPLACE PACKAGE smart_quotes_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/smart_quotes_api.sql
-- Author       : Tim Hall
-- Description  : Routines to help deal with smart quotes..
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   07-JUN-2017  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

FUNCTION contains_smart_quote_bool (p_clob IN CLOB) RETURN BOOLEAN;
FUNCTION contains_smart_quote_bool (p_text IN VARCHAR2) RETURN BOOLEAN;
FUNCTION contains_smart_quote_num (p_clob IN CLOB) RETURN NUMBER;
FUNCTION contains_smart_quote_num (p_text IN VARCHAR2) RETURN NUMBER;

PROCEDURE remove_smart_quotes (p_clob IN OUT NOCOPY CLOB);
PROCEDURE remove_smart_quotes (p_text IN OUT VARCHAR2);
FUNCTION  remove_smart_quotes (p_clob IN CLOB) RETURN CLOB;
FUNCTION  remove_smart_quotes (p_text IN VARCHAR2) RETURN VARCHAR2;

END smart_quotes_api;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY smart_quotes_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/smart_quotes_api.sql
-- Author       : Tim Hall
-- Description  : Routines to help deal with smart quotes..
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   07-JUN-2017  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

TYPE t_sq_arr IS TABLE OF VARCHAR2(10)
  INDEX BY VARCHAR2 (10);

g_sq_arr t_sq_arr;


-- --------------------------------------------------------------------------
FUNCTION contains_smart_quote_bool (p_clob IN CLOB) RETURN BOOLEAN AS
  l_idx VARCHAR2(10);
BEGIN
  l_idx := g_sq_arr.FIRST;

  WHILE l_idx IS NOT NULL LOOP
    IF INSTR(p_clob, l_idx) > 0 THEN
      RETURN TRUE;
    END IF;
    l_idx := g_sq_arr.NEXT(l_idx);
  END LOOP display_loop;

  RETURN FALSE;
END contains_smart_quote_bool;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
FUNCTION contains_smart_quote_bool (p_text IN VARCHAR2) RETURN BOOLEAN AS
  l_idx VARCHAR2(10);
BEGIN
  l_idx := g_sq_arr.FIRST;

  WHILE l_idx IS NOT NULL LOOP
    IF INSTR(p_text, l_idx) > 0 THEN
      RETURN TRUE;
    END IF;
    l_idx := g_sq_arr.NEXT(l_idx);
  END LOOP display_loop;

  RETURN FALSE;
END contains_smart_quote_bool;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
FUNCTION contains_smart_quote_num (p_clob IN CLOB) RETURN NUMBER AS
BEGIN
  IF contains_smart_quote_bool (p_clob => p_clob) = TRUE THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END contains_smart_quote_num;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
FUNCTION contains_smart_quote_num (p_text IN VARCHAR2) RETURN NUMBER AS
BEGIN
  IF contains_smart_quote_bool (p_text => p_text) = TRUE THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;
END contains_smart_quote_num;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
PROCEDURE remove_smart_quotes (p_clob IN OUT NOCOPY CLOB) AS
-- --------------------------------------------------------------------------
  l_idx VARCHAR2(10);
BEGIN
  l_idx := g_sq_arr.FIRST;

  WHILE l_idx IS NOT NULL LOOP
    p_clob := REPLACE(p_clob, l_idx, g_sq_arr(l_idx));
    l_idx := g_sq_arr.NEXT(l_idx);
  END LOOP display_loop;
END remove_smart_quotes;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
PROCEDURE remove_smart_quotes (p_text IN OUT VARCHAR2) AS
-- --------------------------------------------------------------------------
  l_idx VARCHAR2(10);
BEGIN
  l_idx := g_sq_arr.FIRST;

  WHILE l_idx IS NOT NULL LOOP
    p_text := REPLACE(p_text, l_idx, g_sq_arr(l_idx));
    l_idx := g_sq_arr.NEXT(l_idx);
  END LOOP display_loop;
END remove_smart_quotes;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
FUNCTION remove_smart_quotes (p_clob IN CLOB) RETURN CLOB AS
-- --------------------------------------------------------------------------
  l_clob CLOB;
BEGIN
  l_clob := p_clob;
  remove_smart_quotes (p_clob => l_clob);
  RETURN l_clob;
END remove_smart_quotes;
-- --------------------------------------------------------------------------



-- --------------------------------------------------------------------------
FUNCTION remove_smart_quotes (p_text IN VARCHAR2) RETURN VARCHAR2 AS
-- --------------------------------------------------------------------------
  l_text VARCHAR2(32767);
BEGIN
  l_text := p_text;
  remove_smart_quotes (p_text => l_text);
  RETURN l_text;
END remove_smart_quotes;
-- --------------------------------------------------------------------------


BEGIN
  -- Initialise Array of Smart Quotes.
  -- Array Index = Smart Quote.
  -- Array Value = Replacement Value.
  g_sq_arr(CHR(145)) := '''';
  g_sq_arr(CHR(146)) := '''';
  --g_sq_arr(CHR(8216)) := '''';
  --g_sq_arr(CHR(8217)) := '''';

  g_sq_arr(CHR(147)) := '"';
  g_sq_arr(CHR(148)) := '"';
  g_sq_arr(CHR(8220)) := '"';
  g_sq_arr(CHR(8221)) := '"';

  g_sq_arr(CHR(151)) := '--';
  g_sq_arr(CHR(150)) := '-';
  g_sq_arr(CHR(133)) := '...';
  g_sq_arr(CHR(149)) := CHR(38)||'bull;';

  g_sq_arr(CHR(49855)) := '-';
  g_sq_arr(CHR(50578)) := CHR(38)||'OElig;';
  g_sq_arr(CHR(50579)) := CHR(38)||'oelig;';
  g_sq_arr(CHR(50592)) := 'S';
  g_sq_arr(CHR(50593)) := 's';
  g_sq_arr(CHR(50616)) := 'Y';
  g_sq_arr(CHR(50834)) := 'f';
  g_sq_arr(CHR(52102)) := '^';
  g_sq_arr(CHR(52124)) := '~';
  g_sq_arr(CHR(14844051)) := '-';
  g_sq_arr(CHR(14844052)) := '-';
  g_sq_arr(CHR(14844053)) := '-';
  g_sq_arr(CHR(14844056)) := '''';
  g_sq_arr(CHR(14844057)) := '''';
  g_sq_arr(CHR(14844058)) := ',';
  g_sq_arr(CHR(14844060)) := '"';
  g_sq_arr(CHR(14844061)) := '"';
  g_sq_arr(CHR(14844062)) := '"';
  g_sq_arr(CHR(14844064)) := CHR(38)||'dagger;';
  g_sq_arr(CHR(14844064)) := CHR(38)||'Dagger;';
  g_sq_arr(CHR(14844066)) := '.';
  g_sq_arr(CHR(14844070)) := '...';
  g_sq_arr(CHR(14844080)) := CHR(38)||'permil;';
  g_sq_arr(CHR(14844089)) := '<';
  g_sq_arr(CHR(14844090)) := '>';
  g_sq_arr(CHR(14845090)) := CHR(38)||'trade;';

END smart_quotes_api;
/
SHOW ERRORS

-- End of smart_quotes_api.sql --

-- ########## Start of soap_api.sql ##########--
CREATE OR REPLACE PACKAGE soap_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/soap_api.sql
-- Author       : Tim Hall
-- Description  : SOAP related functions for consuming web services.
-- License      : Free for personal and commercial use.
--                You can amend the code, but leave existing the headers, current
--                amendments history and links intact.
--                Copyright and disclaimer available here:
--                https://oracle-base.com/misc/site-info.php#copyright
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   04-OCT-2003  Tim Hall  Initial Creation
--   23-FEB-2006  Tim Hall  Parameterized the "soap" envelope tags.
--   25-MAY-2012  Tim Hall  Added debug switch.
--   29-MAY-2012  Tim Hall  Allow parameters to have no type definition.
--                          Change the default envelope tag to "soap".
--                          add_complex_parameter: Include parameter XML manually.
--   24-MAY-2014  Tim Hall  Added license information.
-- --------------------------------------------------------------------------

TYPE t_request IS RECORD (
  method        VARCHAR2(256),
  namespace     VARCHAR2(256),
  body          VARCHAR2(32767),
  envelope_tag  VARCHAR2(30)
);

TYPE t_response IS RECORD
(
  doc           XMLTYPE,
  envelope_tag  VARCHAR2(30)
);

FUNCTION new_request(p_method        IN  VARCHAR2,
                     p_namespace     IN  VARCHAR2,
                     p_envelope_tag  IN  VARCHAR2 DEFAULT 'soap')
  RETURN t_request;


PROCEDURE add_parameter(p_request  IN OUT NOCOPY  t_request,
                        p_name     IN             VARCHAR2,
                        p_value    IN             VARCHAR2,
                        p_type     IN             VARCHAR2 := NULL);

PROCEDURE add_complex_parameter(p_request  IN OUT NOCOPY  t_request,
                                p_xml      IN             VARCHAR2);

FUNCTION invoke(p_request  IN OUT NOCOPY  t_request,
                p_url      IN             VARCHAR2,
                p_action   IN             VARCHAR2)
  RETURN t_response;

FUNCTION get_return_value(p_response   IN OUT NOCOPY  t_response,
                          p_name       IN             VARCHAR2,
                          p_namespace  IN             VARCHAR2)
  RETURN VARCHAR2;

PROCEDURE debug_on;
PROCEDURE debug_off;

END soap_api;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY soap_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/soap_api.sql
-- Author       : Tim Hall
-- Description  : SOAP related functions for consuming web services.
-- License      : Free for personal and commercial use.
--                You can amend the code, but leave existing the headers, current
--                amendments history and links intact.
--                Copyright and disclaimer available here:
--                https://oracle-base.com/misc/site-info.php#copyright
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   04-OCT-2003  Tim Hall  Initial Creation
--   23-FEB-2006  Tim Hall  Parameterized the "soap" envelope tags.
--   25-MAY-2012  Tim Hall  Added debug switch.
--   29-MAY-2012  Tim Hall  Allow parameters to have no type definition.
--                          Change the default envelope tag to "soap".
--                          add_complex_parameter: Include parameter XML manually.
--   24-MAY-2014  Tim Hall  Added license information.
-- --------------------------------------------------------------------------

g_debug  BOOLEAN := FALSE;

PROCEDURE show_envelope(p_env     IN  VARCHAR2,
                        p_heading IN  VARCHAR2 DEFAULT NULL);



-- ---------------------------------------------------------------------
FUNCTION new_request(p_method        IN  VARCHAR2,
                     p_namespace     IN  VARCHAR2,
                     p_envelope_tag  IN  VARCHAR2 DEFAULT 'soap')
  RETURN t_request AS
-- ---------------------------------------------------------------------
  l_request  t_request;
BEGIN
  l_request.method       := p_method;
  l_request.namespace    := p_namespace;
  l_request.envelope_tag := p_envelope_tag;
  RETURN l_request;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE add_parameter(p_request  IN OUT NOCOPY  t_request,
                        p_name     IN             VARCHAR2,
                        p_value    IN             VARCHAR2,
                        p_type     IN             VARCHAR2 := NULL) AS
-- ---------------------------------------------------------------------
BEGIN
  IF p_type IS NULL THEN
    p_request.body := p_request.body||'<'||p_name||'>'||p_value||'</'||p_name||'>';
  ELSE
    p_request.body := p_request.body||'<'||p_name||' xsi:type="'||p_type||'">'||p_value||'</'||p_name||'>';
  END IF;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE add_complex_parameter(p_request  IN OUT NOCOPY  t_request,
                                p_xml      IN             VARCHAR2) AS
-- ---------------------------------------------------------------------
BEGIN
  p_request.body := p_request.body||p_xml;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE generate_envelope(p_request  IN OUT NOCOPY  t_request,
		                        p_env      IN OUT NOCOPY  VARCHAR2) AS
-- ---------------------------------------------------------------------
BEGIN
  p_env := '<'||p_request.envelope_tag||':Envelope xmlns:'||p_request.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/" ' ||
               'xmlns:xsi="http://www.w3.org/1999/XMLSchema-instance" xmlns:xsd="http://www.w3.org/1999/XMLSchema">' ||
             '<'||p_request.envelope_tag||':Body>' ||
               '<'||p_request.method||' '||p_request.namespace||' '||p_request.envelope_tag||':encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">' ||
                   p_request.body ||
               '</'||p_request.method||'>' ||
             '</'||p_request.envelope_tag||':Body>' ||
           '</'||p_request.envelope_tag||':Envelope>';
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE show_envelope(p_env     IN  VARCHAR2,
                        p_heading IN  VARCHAR2 DEFAULT NULL) AS
-- ---------------------------------------------------------------------
  i      PLS_INTEGER;
  l_len  PLS_INTEGER;
BEGIN
  IF g_debug THEN
    IF p_heading IS NOT NULL THEN
      DBMS_OUTPUT.put_line('*****' || p_heading || '*****');
    END IF;

    i := 1; l_len := LENGTH(p_env);
    WHILE (i <= l_len) LOOP
      DBMS_OUTPUT.put_line(SUBSTR(p_env, i, 60));
      i := i + 60;
    END LOOP;
  END IF;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE check_fault(p_response IN OUT NOCOPY  t_response) AS
-- ---------------------------------------------------------------------
  l_fault_node    XMLTYPE;
  l_fault_code    VARCHAR2(256);
  l_fault_string  VARCHAR2(32767);
BEGIN
  l_fault_node := p_response.doc.extract('/'||p_response.envelope_tag||':Fault',
                                         'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/');
  IF (l_fault_node IS NOT NULL) THEN
    l_fault_code   := l_fault_node.extract('/'||p_response.envelope_tag||':Fault/faultcode/child::text()',
                                           'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
    l_fault_string := l_fault_node.extract('/'||p_response.envelope_tag||':Fault/faultstring/child::text()',
                                           'xmlns:'||p_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/').getstringval();
    RAISE_APPLICATION_ERROR(-20000, l_fault_code || ' - ' || l_fault_string);
  END IF;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
FUNCTION invoke(p_request IN OUT NOCOPY  t_request,
                p_url     IN             VARCHAR2,
                p_action  IN             VARCHAR2)
  RETURN t_response AS
-- ---------------------------------------------------------------------
  l_envelope       VARCHAR2(32767);
  l_http_request   UTL_HTTP.req;
  l_http_response  UTL_HTTP.resp;
  l_response       t_response;
BEGIN
  generate_envelope(p_request, l_envelope);
  show_envelope(l_envelope, 'Request');
  l_http_request := UTL_HTTP.begin_request(p_url, 'POST','HTTP/1.1');
  UTL_HTTP.set_header(l_http_request, 'Content-Type', 'text/xml');
  UTL_HTTP.set_header(l_http_request, 'Content-Length', LENGTH(l_envelope));
  UTL_HTTP.set_header(l_http_request, 'SOAPAction', p_action);
  UTL_HTTP.write_text(l_http_request, l_envelope);
  l_http_response := UTL_HTTP.get_response(l_http_request);
  UTL_HTTP.read_text(l_http_response, l_envelope);
  UTL_HTTP.end_response(l_http_response);
  show_envelope(l_envelope, 'Response');
  l_response.doc := XMLTYPE.createxml(l_envelope);
  l_response.envelope_tag := p_request.envelope_tag;
  l_response.doc := l_response.doc.extract('/'||l_response.envelope_tag||':Envelope/'||l_response.envelope_tag||':Body/child::node()',
                                           'xmlns:'||l_response.envelope_tag||'="http://schemas.xmlsoap.org/soap/envelope/"');
  check_fault(l_response);
  RETURN l_response;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
FUNCTION get_return_value(p_response   IN OUT NOCOPY  t_response,
                          p_name       IN             VARCHAR2,
                          p_namespace  IN             VARCHAR2)
  RETURN VARCHAR2 AS
-- ---------------------------------------------------------------------
BEGIN
  RETURN p_response.doc.extract('//'||p_name||'/child::text()',p_namespace).getstringval();
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE debug_on AS
-- ---------------------------------------------------------------------
BEGIN
  g_debug := TRUE;
END;
-- ---------------------------------------------------------------------



-- ---------------------------------------------------------------------
PROCEDURE debug_off AS
-- ---------------------------------------------------------------------
BEGIN
  g_debug := FALSE;
END;
-- ---------------------------------------------------------------------

END soap_api;
/
SHOW ERRORS
-- End of soap_api.sql --

-- ########## Start of string_agg.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/string_agg.sql
-- Author       : Tim Hall (based on an a method suggested by Tom Kyte).
--                http://asktom.oracle.com/pls/ask/f?p=4950:8:::::F4950_P8_DISPLAYID:229614022562
-- Description  : Aggregate function to concatenate strings.
-- Call Syntax  : Incorporate into queries as follows:
--                  COLUMN employees FORMAT A50
--                  
--                  SELECT deptno, string_agg(ename) AS employees
--                  FROM   emp
--                  GROUP BY deptno;
--                  
--                      DEPTNO EMPLOYEES
--                  ---------- --------------------------------------------------
--                          10 CLARK,KING,MILLER
--                          20 SMITH,FORD,ADAMS,SCOTT,JONES
--                          30 ALLEN,BLAKE,MARTIN,TURNER,JAMES,WARD
--                  
-- Last Modified: 03-JAN-2018 : Correction to separator handling in ODCIAggregateTerminate
--                              and ODCIAggregateMerge, suggested by Kim Berg Hansen.
-- -----------------------------------------------------------------------------------
CREATE OR REPLACE TYPE t_string_agg AS OBJECT
(
  g_string  VARCHAR2(32767),

  STATIC FUNCTION ODCIAggregateInitialize(sctx  IN OUT  t_string_agg)
    RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateIterate(self   IN OUT  t_string_agg,
                                       value  IN      VARCHAR2 )
     RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateTerminate(self         IN   t_string_agg,
                                         returnValue  OUT  VARCHAR2,
                                         flags        IN   NUMBER)
    RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateMerge(self  IN OUT  t_string_agg,
                                     ctx2  IN      t_string_agg)
    RETURN NUMBER
);
/
SHOW ERRORS


CREATE OR REPLACE TYPE BODY t_string_agg IS
  STATIC FUNCTION ODCIAggregateInitialize(sctx  IN OUT  t_string_agg)
    RETURN NUMBER IS
  BEGIN
    sctx := t_string_agg(NULL);
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateIterate(self   IN OUT  t_string_agg,
                                       value  IN      VARCHAR2 )
    RETURN NUMBER IS
  BEGIN
    SELF.g_string := self.g_string || ',' || value;
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateTerminate(self         IN   t_string_agg,
                                         returnValue  OUT  VARCHAR2,
                                         flags        IN   NUMBER)
    RETURN NUMBER IS
  BEGIN
    returnValue := SUBSTR(SELF.g_string, 2);
    RETURN ODCIConst.Success;
  END;

  MEMBER FUNCTION ODCIAggregateMerge(self  IN OUT  t_string_agg,
                                     ctx2  IN      t_string_agg)
    RETURN NUMBER IS
  BEGIN
    SELF.g_string := SELF.g_string || ctx2.g_string;
    RETURN ODCIConst.Success;
  END;
END;
/
SHOW ERRORS


CREATE OR REPLACE FUNCTION string_agg (p_input VARCHAR2)
RETURN VARCHAR2
PARALLEL_ENABLE AGGREGATE USING t_string_agg;
/
SHOW ERRORS

-- End of string_agg.sql --

-- ########## Start of string_api.sql ##########--
CREATE OR REPLACE PACKAGE string_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/string_api.sql
-- Author       : Tim Hall
-- Description  : A package to hold string utilities.
-- Requirements : 
-- Amendments   :
--   When         Who       What
--   ===========  ========  =================================================
--   02-DEC-2004  Tim Hall  Initial Creation
--   19-JAN-2017  Tim Hall  Add get_uri_paramter_value function.
-- --------------------------------------------------------------------------

-- Public types
TYPE t_split_array IS TABLE OF VARCHAR2(4000);

FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ',')
  RETURN t_split_array;

PROCEDURE print_clob (p_clob  IN  CLOB);
PROCEDURE print_clob_old (p_clob  IN  CLOB);

PROCEDURE print_clob_htp (p_clob  IN  CLOB);
PROCEDURE print_clob_htp_old (p_clob  IN  CLOB);

FUNCTION get_uri_paramter_value (p_uri         IN  VARCHAR2,
                                 p_param_name  IN  VARCHAR2)
  RETURN VARCHAR2;

END string_api;
/
SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY string_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/string_api.sql
-- Author       : Tim Hall
-- Description  : A package to hold string utilities.
-- Requirements : 
-- Amendments   :
--   When         Who       What
--   ===========  ========  =================================================
--   02-DEC-2004  Tim Hall  Initial Creation
--   31-AUG-2017  Tim Hall  SUBSTR parameters switched.
--   19-JAN-2017  Tim Hall  Add get_uri_paramter_value function.
--   20-NOV-2018  Tim Hall  Reduce the chunk sizes to allow for multibyte character sets.
-- --------------------------------------------------------------------------

-- Variables to support the URI functionality.
TYPE t_uri_array IS TABLE OF VARCHAR2(32767) INDEX BY VARCHAR2(32767);
g_last_uri VARCHAR2(32767) := 'initialized';
g_uri_tab  t_uri_array;



-- ----------------------------------------------------------------------------
FUNCTION split_text (p_text       IN  CLOB,
                     p_delimeter  IN  VARCHAR2 DEFAULT ',')
  RETURN t_split_array IS
-- ----------------------------------------------------------------------------
-- Could be replaced by APEX_UTIL.STRING_TO_TABLE.
-- ----------------------------------------------------------------------------
  l_array  t_split_array   := t_split_array();
  l_text   CLOB := p_text;
  l_idx    NUMBER;
BEGIN
  l_array.delete;

  IF l_text IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'P_TEXT parameter cannot be NULL');
  END IF;

  WHILE l_text IS NOT NULL LOOP
    l_idx := INSTR(l_text, p_delimeter);
    l_array.extend;
    IF l_idx > 0 THEN
      l_array(l_array.last) := SUBSTR(l_text, 1, l_idx - 1);
      l_text := SUBSTR(l_text, l_idx + 1);
    ELSE
      l_array(l_array.last) := l_text;
      l_text := NULL;
    END IF;
  END LOOP;
  RETURN l_array;
END split_text;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 255;
BEGIN
  LOOP
    EXIT WHEN l_offset > LENGTH(p_clob);
    DBMS_OUTPUT.put_line(SUBSTR(p_clob, l_offset, l_chunk));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob_old (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 255;
BEGIN
  LOOP
    EXIT WHEN l_offset > DBMS_LOB.getlength(p_clob);
    DBMS_OUTPUT.put_line(DBMS_LOB.substr(p_clob, l_offset, l_chunk));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob_old;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob_htp (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 3000;
BEGIN
  LOOP
    EXIT WHEN l_offset > LENGTH(p_clob);
    HTP.prn(SUBSTR(p_clob, l_offset, l_chunk));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob_htp;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
PROCEDURE print_clob_htp_old (p_clob IN CLOB) IS
-- ----------------------------------------------------------------------------
  l_offset NUMBER := 1;
  l_chunk  NUMBER := 3000;
BEGIN
  LOOP
    EXIT WHEN l_offset > DBMS_LOB.getlength(p_clob);
    HTP.prn(DBMS_LOB.substr(p_clob, l_offset, l_chunk));
    l_offset := l_offset + l_chunk;
  END LOOP;
END print_clob_htp_old;
-- ----------------------------------------------------------------------------



-- ----------------------------------------------------------------------------
FUNCTION get_uri_paramter_value (p_uri         IN  VARCHAR2,
                                 p_param_name  IN  VARCHAR2)
  RETURN VARCHAR2 IS
-- ----------------------------------------------------------------------------
-- Example:
-- l_uri := 'https://localhost:8080/my_page.php?param1=value1&param2=value2&param3=value3';
-- l_value := string_api.get_uri_paramter_value(l_uri, 'param1')
-- ----------------------------------------------------------------------------
  l_uri    VARCHAR2(32767);
  l_array  t_split_array   := t_split_array();
  l_idx    NUMBER;
BEGIN
  IF p_uri IS NULL OR p_param_name IS NULL THEN
    RAISE_APPLICATION_ERROR(-20000, 'p_uri and p_param_name must be specified.');
  END IF;
  
  IF p_uri != g_last_uri THEN
    -- First time we've seen this URI, so build the key-value table.
    g_uri_tab.DELETE;
    g_last_uri := p_uri;
    l_uri      := TRANSLATE(g_last_uri, '&?', '^^');
    l_array    := split_text(l_uri, '^');
    FOR i IN 1 .. l_array.COUNT LOOP
      l_idx := INSTR(l_array(i), '=');
      IF l_idx != 0 THEN
        g_uri_tab(SUBSTR(l_array(i), 1, l_idx - 1)) := SUBSTR(l_array(i), l_idx + 1);
        --DBMS_OUTPUT.put_line('param_name=' || SUBSTR(l_array(i), 1, l_idx - 1) ||
        --                     ' | param_value=' || SUBSTR(l_array(i), l_idx + 1));
      END IF;
    END LOOP;
  END IF;
  
  RETURN g_uri_tab(p_param_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END get_uri_paramter_value;
-- ----------------------------------------------------------------------------

END string_api;
/
SHOW ERRORS

-- End of string_api.sql --

-- ########## Start of switch_schema.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/switch_schema.sql
-- Author       : Tim Hall
-- Description  : Allows developers to switch synonyms between schemas where a single instance
--              : contains multiple discrete schemas.
-- Requirements : Must be loaded into privileged user such as SYS.
-- Usage        : Create the package in a user that has the appropriate privileges to perform the actions (SYS)
--              : Amend the list of schemas in the "reset_grants" FOR LOOP as necessary.
--              : Call SWITCH_SCHEMA.RESET_GRANTS once to grant privileges to the developer role.
--              : Assign the developer role to all developers.
--              : Tell developers to use EXEC SWITCH_SCHEMA.RESET_SCHEMA_SYNONYMS ('SCHEMA-NAME'); to switch
--              : there synonyms between schemas.
-- Call Syntax  : EXEC SWITCH_SCHEMA.RESET_SCHEMA_SYNONYMS ('SCHEMA-NAME');
-- Last Modified: 02/06/2003
-- -----------------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE switch_schema AS

PROCEDURE reset_grants;
PROCEDURE reset_schema_synonyms (p_schema  IN  VARCHAR2);

END;
/

SHOW ERRORS


CREATE OR REPLACE PACKAGE BODY switch_schema AS

PROCEDURE reset_grants IS
BEGIN
  FOR cur_obj IN (SELECT owner, object_name, object_type
                  FROM   all_objects
                  WHERE  owner IN ('SCHEMA1','SCHEMA2','SCHEMA3','SCHEMA4')
                  AND    object_type IN ('TABLE','VIEW','SEQUENCE', 'PACKAGE', 'PROCEDURE', 'FUNCTION', 'TYPE'))
  LOOP
    CASE 
      WHEN cur_obj.object_type IN ('TABLE','VIEW') THEN
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || cur_obj.owner || '."' || cur_obj.object_name || '" TO developer';
      WHEN cur_obj.object_type IN ('SEQUENCE') THEN
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || cur_obj.owner || '."' || cur_obj.object_name || '" TO developer';
      WHEN cur_obj.object_type IN ('PACKAGE', 'PROCEDURE', 'FUNCTION', 'TYPE') THEN
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || cur_obj.owner || '."' || cur_obj.object_name || '" TO developer';
    END CASE;
  END LOOP;
END;

PROCEDURE reset_schema_synonyms (p_schema  IN  VARCHAR2) IS
  v_user  VARCHAR2(30) := USER;
BEGIN
  -- Drop all existing synonyms
  FOR cur_obj IN (SELECT synonym_name
                  FROM   all_synonyms
                  WHERE  owner = v_user)
  LOOP
    EXECUTE IMMEDIATE 'DROP SYNONYM ' || v_user || '."' || cur_obj.synonym_name || '"';
  END LOOP;

  -- Create new synonyms
  FOR cur_obj IN (SELECT object_name, object_type
                  FROM   all_objects
                  WHERE  owner = p_schema
                  AND    object_type IN ('TABLE','VIEW','SEQUENCE'))
  LOOP
    EXECUTE IMMEDIATE 'CREATE SYNONYM ' || v_user || '."' || cur_obj.object_name || '" FOR ' || p_schema || '."' || cur_obj.object_name || '"';
  END LOOP;
END;

END;
/

SHOW ERRORS

CREATE PUBLIC SYNONYM switch_schema FOR switch_schema;
GRANT EXECUTE ON switch_schema TO PUBLIC;

CREATE ROLE developer;

-- End of switch_schema.sql --

-- ########## Start of table_comments.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/table_comments.sql
-- Author       : Tim Hall
-- Description  : Displays comments associate with specific tables.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @table_comments (schema or all) (table-name or partial match)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET VERIFY OFF
COLUMN table_name FORMAT A30
COLUMN comments   FORMAT A40

SELECT table_name,
       comments
FROM   dba_tab_comments
WHERE  owner = DECODE(UPPER('&1'), 'ALL', owner, UPPER('&1'))
AND    table_name LIKE UPPER('%&2%')
ORDER BY table_name;

-- End of table_comments.sql --

-- ########## Start of table_defs.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/table_defs.sql
-- Author       : Tim Hall
-- Description  : Lists the column definitions for the specified table.
-- Call Syntax  : @table_defs (tablee-name or all)
-- Last Modified: 24/09/2003
-- -----------------------------------------------------------------------------------
COLUMN column_id FORMAT 99
COLUMN data_type FORMAT A10
COLUMN nullable FORMAT A8
COLUMN size FORMAT A6
BREAK ON table_name SKIP 2
SET PAGESIZE 0
SET LINESIZE 200
SET TRIMOUT ON
SET TRIMSPOOL ON
SET VERIFY OFF

SELECT table_name,
       column_id,
       column_name,
       data_type,
       (CASE
         WHEN data_type IN ('VARCHAR2','CHAR') THEN TO_CHAR(data_length)
         WHEN data_scale IS NULL OR data_scale = 0 THEN TO_CHAR(data_precision)
         ELSE TO_CHAR(data_precision) || ',' || TO_CHAR(data_scale)
       END) "SIZE",
       DECODE(nullable, 'Y', '', 'NOT NULL') nullable
FROM   user_tab_columns
WHERE  table_name = DECODE(UPPER('&1'), 'ALL', table_name, UPPER('&1'))
ORDER BY table_name, column_id;

SET PAGESIZE 14
SET LINESIZE 80

-- End of table_defs.sql --

-- ########## Start of table_differences.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/miscellaneous/table_differences.sql
-- Author       : Tim Hall
-- Description  : Checks column differences between a specified table or ALL tables.
--              : The comparison is done both ways so datatype/size mismatches will
--              : be listed twice per column.
--              : Log into the first schema-owner. Make sure a DB Link is set up to
--              : the second schema owner. Use this DB Link in the definition of 
--              : the c_table2 cursor and amend v_owner1 and v_owner2 accordingly
--              : to make output messages sensible.
--              : The result is spooled to the Tab_Diffs.txt file in the working directory.
-- Call Syntax  : @table_differences (table-name or all)
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 500
SET VERIFY OFF
SET FEEDBACK OFF
PROMPT

SPOOL Tab_Diffs.txt

DECLARE

  CURSOR c_tables IS
    SELECT a.table_name
    FROM   user_tables a
    WHERE  a.table_name = Decode(Upper('&&1'),'ALL',a.table_name,Upper('&&1'));
    
  CURSOR c_table1 (p_table_name   IN  VARCHAR2,
                   p_column_name  IN  VARCHAR2) IS
    SELECT a.column_name,
           a.data_type,
           a.data_length,
           a.data_precision,
           a.data_scale,
           a.nullable
    FROM   user_tab_columns a
    WHERE  a.table_name  = p_table_name
    AND    a.column_name = NVL(p_column_name,a.column_name);

  CURSOR c_table2 (p_table_name   IN  VARCHAR2,
                   p_column_name  IN  VARCHAR2) IS
    SELECT a.column_name,
           a.data_type,
           a.data_length,
           a.data_precision,
           a.data_scale,
           a.nullable
    FROM   user_tab_columns@pdds a
    WHERE  a.table_name  = p_table_name
    AND    a.column_name = NVL(p_column_name,a.column_name);

  v_owner1  VARCHAR2(10) := 'DDDS2';
  v_owner2  VARCHAR2(10) := 'PDDS';
  v_data    c_table1%ROWTYPE;
  v_work    BOOLEAN := FALSE;
  
BEGIN

  Dbms_Output.Disable;
  Dbms_Output.Enable(1000000);
  
  FOR cur_tab IN c_tables LOOP
    v_work := FALSE;
    FOR cur_rec IN c_table1 (cur_tab.table_name, NULL) LOOP
      v_work := TRUE;
      
      OPEN  c_table2 (cur_tab.table_name, cur_rec.column_name);
      FETCH c_table2
      INTO  v_data;
      IF c_table2%NOTFOUND THEN
        Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : Present in ' || v_owner1 || ' but not in ' || v_owner2);
      ELSE
        IF cur_rec.data_type != v_data.data_type THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_TYPE differs between ' || v_owner1 || ' and ' || v_owner2);
        END IF;
        IF cur_rec.data_length != v_data.data_length THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_LENGTH differs between ' || v_owner1 || ' and ' || v_owner2);
        END IF;
        IF cur_rec.data_precision != v_data.data_precision THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_PRECISION differs between ' || v_owner1 || ' and ' || v_owner2);
        END IF;
        IF cur_rec.data_scale != v_data.data_scale THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_SCALE differs between ' || v_owner1 || ' and ' || v_owner2);
        END IF;
        IF cur_rec.nullable != v_data.nullable THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : NULLABLE differs between ' || v_owner1 || ' and ' || v_owner2);
        END IF;
      END IF;
      CLOSE c_table2; 
    END LOOP;
    
    FOR cur_rec IN c_table2 (cur_tab.table_name, NULL) LOOP
      v_work := TRUE;
      
      OPEN  c_table1 (cur_tab.table_name, cur_rec.column_name);
      FETCH c_table1
      INTO  v_data;
      IF c_table1%NOTFOUND THEN
        Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : Present in ' || v_owner2 || ' but not in ' || v_owner1);
      ELSE
        IF cur_rec.data_type != v_data.data_type THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_TYPE differs between ' || v_owner2 || ' and ' || v_owner1);
        END IF;
        IF cur_rec.data_length != v_data.data_length THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_LENGTH differs between ' || v_owner2 || ' and ' || v_owner1);
        END IF;
        IF cur_rec.data_precision != v_data.data_precision THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_PRECISION differs between ' || v_owner2 || ' and ' || v_owner1);
        END IF;
        IF cur_rec.data_scale != v_data.data_scale THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : DATA_SCALE differs between ' || v_owner2 || ' and ' || v_owner1);
        END IF;
        IF cur_rec.nullable != v_data.nullable THEN
          Dbms_Output.Put_Line(cur_tab.table_name || '.' || cur_rec.column_name || ' : NULLABLE differs between ' || v_owner2 || ' and ' || v_owner1);
        END IF;
      END IF;
      CLOSE c_table1; 
    END LOOP;
    
    IF v_work = FALSE THEN
      Dbms_Output.Put_Line(cur_tab.table_name || ' does not exist!');
    END IF;  
  END LOOP;
END;
/

SPOOL OFF

PROMPT
SET FEEDBACK ON

-- End of table_differences.sql --

-- ########## Start of ts_move_api.sql ##########--
CREATE OR REPLACE PACKAGE ts_move_api AUTHID CURRENT_USER AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/ts_move_api.sql
-- Author       : Tim Hall
-- Description  : Allows you to move objects between tablespaces.
-- Requirements : The package should be run by a DBA user.
--
--                The following grants are needed for this package to compile.
--
--                GRANT SELECT ON dba_tables TO username;
--                GRANT SELECT ON dba_tab_partitions TO username;
--                GRANT SELECT ON dba_indexes TO username;
--                GRANT SELECT ON dba_ind_partitions TO username;
--                GRANT SELECT ON dba_lobs TO username;
--
-- License      : Free for personal and commercial use.
--                You can amend the code, but leave existing the headers, current
--                amendments history and links intact.
--                Copyright and disclaimer available here:
--                https://oracle-base.com/misc/site-info.php#copyright
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   20-JUN-2010  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

PROCEDURE move_tables(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
);

PROCEDURE move_part_tables(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
);

PROCEDURE move_indexes(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
);

PROCEDURE move_part_indexes(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
);

PROCEDURE move_lobs(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
);

END ts_move_api;
/
SHOW ERRORS



CREATE OR REPLACE PACKAGE BODY ts_move_api AS
-- --------------------------------------------------------------------------
-- Name         : https://oracle-base.com/dba/miscellaneous/ts_move_api.sql
-- Author       : Tim Hall
-- Description  : Allows you to move objects between tablespaces.
-- Requirements : The package should be run by a DBA user.
--
--                The following grants are needed for this package to compile.
--
--                GRANT SELECT ON dba_tables TO username;
--                GRANT SELECT ON dba_tab_partitions TO username;
--                GRANT SELECT ON dba_indexes TO username;
--                GRANT SELECT ON dba_ind_partitions TO username;
--                GRANT SELECT ON dba_lobs TO username;
--
-- License      : Free for personal and commercial use.
--                You can amend the code, but leave existing the headers, current
--                amendments history and links intact.
--                Copyright and disclaimer available here:
--                https://oracle-base.com/misc/site-info.php#copyright
-- Ammedments   :
--   When         Who       What
--   ===========  ========  =================================================
--   20-JUN-2010  Tim Hall  Initial Creation
-- --------------------------------------------------------------------------

g_sql VARCHAR2(32767);

-- -----------------------------------------------------------------------------
PROCEDURE move_tables(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
) AS

BEGIN
  FOR cur_rec IN (SELECT owner, table_name
                  FROM   dba_tables
                  WHERE  tablespace_name = UPPER(p_from_ts)
                  AND    partitioned = 'NO'
                  AND    temporary = 'N')
  LOOP
    BEGIN
      g_sql := 'ALTER TABLE "' || cur_rec.owner || '"."' || cur_rec.table_name || '" MOVE TABLESPACE ' || p_to_ts;
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;
END move_tables;
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
PROCEDURE move_part_tables(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
) AS

BEGIN
  -- Table partitions.
  FOR cur_rec IN (SELECT table_owner, table_name, partition_name
                  FROM   dba_tab_partitions
                  WHERE  tablespace_name = UPPER(p_from_ts))
  LOOP
    BEGIN
      g_sql := 'ALTER TABLE "' || cur_rec.table_owner || '"."' || cur_rec.table_name || '" MOVE PARTITION "' || cur_rec.partition_name || '" TABLESPACE ' || p_to_ts;
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;

  -- Partitioned table defaults.
  FOR cur_rec IN (SELECT owner, table_name
                  FROM   dba_tables
                  WHERE  tablespace_name = UPPER(p_from_ts)
                  AND    partitioned = 'YES')
  LOOP
    BEGIN
      g_sql := 'ALTER TABLE "' || cur_rec.owner || '"."' || cur_rec.table_name || '" MODIFY DEFAULT ATTRIBUTES TABLESPACE ' || p_to_ts;
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;
END move_part_tables;
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
PROCEDURE move_indexes(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
) AS

BEGIN
  FOR cur_rec IN (SELECT owner, index_name
                  FROM   dba_indexes
                  WHERE  tablespace_name = UPPER(p_from_ts)
                  AND    partitioned = 'NO'
                  AND    index_type != 'LOB')
  LOOP
    BEGIN
      g_sql := 'ALTER INDEX "' || cur_rec.owner || '"."' || cur_rec.index_name || '" REBUILD TABLESPACE ' || p_to_ts;
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;
END move_indexes;
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
PROCEDURE move_part_indexes(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
) AS

BEGIN
  -- Index partitions.
  FOR cur_rec IN (SELECT index_owner, index_name, partition_name
                  FROM   dba_ind_partitions
                  WHERE  tablespace_name = UPPER(p_from_ts))
  LOOP
    BEGIN
      g_sql := 'ALTER INDEX "' || cur_rec.index_owner || '"."' || cur_rec.index_name || '" REBUILD PARTITION "' || cur_rec.partition_name || '" TABLESPACE ' || p_to_ts;
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;

  -- Partitioned index default.
  FOR cur_rec IN (SELECT owner, index_name
                  FROM   dba_indexes
                  WHERE  tablespace_name = UPPER(p_from_ts)
                  AND    partitioned = 'YES')
  LOOP
    BEGIN
      g_sql := 'ALTER INDEX "' || cur_rec.owner || '"."' || cur_rec.index_name || '" MODIFY DEFAULT ATTRIBUTES TABLESPACE ' || p_to_ts;
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;
END move_part_indexes;
-- -----------------------------------------------------------------------------


-- -----------------------------------------------------------------------------
PROCEDURE move_lobs(
  p_from_ts  IN VARCHAR2,
  p_to_ts    IN VARCHAR2
) AS

BEGIN
  FOR cur_rec IN (SELECT owner, table_name, column_name
                  FROM   dba_lobs
                  WHERE  tablespace_name = UPPER(p_from_ts)
                  AND    partitioned = 'NO')
  LOOP
    BEGIN
      g_sql := 'ALTER TABLE "' || cur_rec.owner || '"."' || cur_rec.table_name || '" MOVE LOB("' || cur_rec.column_name || '") STORE AS (TABLESPACE ' || p_to_ts || ')';
      EXECUTE IMMEDIATE g_sql;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.put_line('ERROR: ' || g_sql);
        DBMS_OUTPUT.put_line('ERROR: ' || SQLERRM);
    END;
  END LOOP;
END move_lobs;
-- -----------------------------------------------------------------------------

END ts_move_api;
/
SHOW ERRORS

-- End of ts_move_api.sql --

-- ########## Start of locked_objects_rac.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/locked_objects.sql
-- Author       : Tim Hall
-- Description  : Lists all locked objects for whole RAC.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @locked_objects
-- Last Modified: 15/07/2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000
SET VERIFY OFF

COLUMN owner FORMAT A20
COLUMN username FORMAT A20
COLUMN object_owner FORMAT A20
COLUMN object_name FORMAT A30
COLUMN locked_mode FORMAT A15

SELECT b.inst_id,
       b.session_id AS sid,
       NVL(b.oracle_username, '(oracle)') AS username,
       a.owner AS object_owner,
       a.object_name,
       Decode(b.locked_mode, 0, 'None',
                             1, 'Null (NULL)',
                             2, 'Row-S (SS)',
                             3, 'Row-X (SX)',
                             4, 'Share (S)',
                             5, 'S/Row-X (SSX)',
                             6, 'Exclusive (X)',
                             b.locked_mode) locked_mode,
       b.os_user_name
FROM   dba_objects a,
       gv$locked_object b
WHERE  a.object_id = b.object_id
ORDER BY 1, 2, 3, 4;

SET PAGESIZE 14
SET VERIFY ON


-- End of locked_objects_rac.sql --

-- ########## Start of longops_rac.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/longops_rac.sql
-- Author       : Tim Hall
-- Description  : Displays information on all long operations for whole RAC.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @longops_rac
-- Last Modified: 03/07/2003
-- -----------------------------------------------------------------------------------

SET LINESIZE 200
COLUMN sid FORMAT 9999
COLUMN serial# FORMAT 9999999
COLUMN machine FORMAT A30
COLUMN progress_pct FORMAT 99999999.00
COLUMN elapsed FORMAT A10
COLUMN remaining FORMAT A10

SELECT s.inst_id,
       s.sid,
       s.serial#,
       s.username,
       s.module,
       ROUND(sl.elapsed_seconds/60) || ':' || MOD(sl.elapsed_seconds,60) elapsed,
       ROUND(sl.time_remaining/60) || ':' || MOD(sl.time_remaining,60) remaining,
       ROUND(sl.sofar/sl.totalwork*100, 2) progress_pct
FROM   gv$session s,
       gv$session_longops sl
WHERE  s.sid     = sl.sid
AND    s.inst_id = sl.inst_id
AND    s.serial# = sl.serial#;

-- End of longops_rac.sql --

-- ########## Start of monitor_memory_rac.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/monitor_memory_rac.sql
-- Author       : Tim Hall
-- Description  : Displays memory allocations for the current database sessions for the whole RAC.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @monitor_memory_rac
-- Last Modified: 15-JUL-2000
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN username FORMAT A20
COLUMN module FORMAT A20

SELECT a.inst_id,
       NVL(a.username,'(oracle)') AS username,
       a.module,
       a.program,
       Trunc(b.value/1024) AS memory_kb
FROM   gv$session a,
       gv$sesstat b,
       gv$statname c
WHERE  a.sid = b.sid
AND    a.inst_id = b.inst_id
AND    b.statistic# = c.statistic#
AND    b.inst_id = c.inst_id
AND    c.name = 'session pga memory'
AND    a.program IS NOT NULL
ORDER BY b.value DESC;
-- End of monitor_memory_rac.sql --

-- ########## Start of session_undo_rac.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/session_undo_rac.sql
-- Author       : Tim Hall
-- Description  : Displays undo information on relevant database sessions.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_undo_rac
-- Last Modified: 20/12/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200

COLUMN username FORMAT A15

SELECT s.inst_id,
       s.username,
       s.sid,
       s.serial#,
       t.used_ublk,
       t.used_urec,
       rs.segment_name,
       r.rssize,
       r.status
FROM   gv$transaction t,
       gv$session s,
       gv$rollstat r,
       dba_rollback_segs rs
WHERE  s.saddr = t.ses_addr
AND    s.inst_id = t.inst_id
AND    t.xidusn = r.usn
AND    t.inst_id = r.inst_id
AND    rs.segment_id = t.xidusn
ORDER BY t.used_ublk DESC;

-- End of session_undo_rac.sql --

-- ########## Start of session_waits_rac.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/10g/session_waits_rac.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database session waits for the whole RAC.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @session_waits_rac
-- Last Modified: 02/07/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET PAGESIZE 1000

COLUMN username FORMAT A20
COLUMN event FORMAT A30
COLUMN wait_class FORMAT A15

SELECT s.inst_id,
       NVL(s.username, '(oracle)') AS username,
       s.sid,
       s.serial#,
       sw.event,
       sw.wait_class,
       sw.wait_time,
       sw.seconds_in_wait,
       sw.state
FROM   gv$session_wait sw,
       gv$session s
WHERE  s.sid     = sw.sid
AND    s.inst_id = sw.inst_id
ORDER BY sw.seconds_in_wait DESC;

-- End of session_waits_rac.sql --

-- ########## Start of sessions_rac.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/monitoring/sessions_rac.sql
-- Author       : Tim Hall
-- Description  : Displays information on all database sessions for whole RAC.
-- Requirements : Access to the V$ views.
-- Call Syntax  : @sessions_rac
-- Last Modified: 21/02/2005
-- -----------------------------------------------------------------------------------
SET LINESIZE 500
SET PAGESIZE 1000

COLUMN username FORMAT A15
COLUMN machine FORMAT A25
COLUMN logon_time FORMAT A20

SELECT NVL(s.username, '(oracle)') AS username,
       s.inst_id,
       s.osuser,
       s.sid,
       s.serial#,
       p.spid,
       s.lockwait,
       s.status,
       s.module,
       s.machine,
       s.program,
       TO_CHAR(s.logon_Time,'DD-MON-YYYY HH24:MI:SS') AS logon_time
FROM   gv$session s,
       gv$process p
WHERE  s.paddr   = p.addr
AND    s.inst_id = p.inst_id
ORDER BY s.username, s.osuser;

SET PAGESIZE 14

-- End of sessions_rac.sql --

-- ########## Start of active_plan.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/resource_manager/active_plan.sql
-- Author       : Tim Hall
-- Description  : Lists the currently active resource plan if one is set.
-- Call Syntax  : @active_plan
-- Requirements : Access to the v$ views.
-- Last Modified: 12/11/2004
-- -----------------------------------------------------------------------------------
SELECT name,
       is_top_plan
FROM   v$rsrc_plan
ORDER BY name;

-- End of active_plan.sql --

-- ########## Start of consumer_group_usage.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/resource_manager/consumer_group_usage.sql
-- Author       : Tim Hall
-- Description  : Lists usage information of consumer groups.
-- Call Syntax  : @consumer_group_usage
-- Requirements : Access to the v$ views.
-- Last Modified: 12/11/2004
-- -----------------------------------------------------------------------------------
SELECT name,
       consumed_cpu_time
FROM   v$rsrc_consumer_group
ORDER BY name;

-- End of consumer_group_usage.sql --

-- ########## Start of consumer_groups.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/resource_manager/consumer_groups.sql
-- Author       : Tim Hall
-- Description  : Lists all consumer groups.
-- Call Syntax  : @consumer_groups
-- Requirements : Access to the DBA views.
-- Last Modified: 12/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET VERIFY OFF

COLUMN status FORMAT A10
COLUMN comments FORMAT A50

SELECT consumer_group,
       status,
       comments
FROM   dba_rsrc_consumer_groups
ORDER BY consumer_group;
-- End of consumer_groups.sql --

-- ########## Start of plan_directives.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/resource_manager/plan_directives.sql
-- Author       : Tim Hall
-- Description  : Lists all plan directives.
-- Call Syntax  : @plan_directives (plan-name or all)
-- Requirements : Access to the DBA views.
-- Last Modified: 12/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET VERIFY OFF

SELECT plan,
       group_or_subplan,
       cpu_p1,
       cpu_p2,
       cpu_p3,
       cpu_p4
FROM   dba_rsrc_plan_directives
WHERE  plan = DECODE(UPPER('&1'), 'ALL', plan, UPPER('&1'))
ORDER BY plan, cpu_p1 DESC, cpu_p2 DESC, cpu_p3 DESC;

-- End of plan_directives.sql --

-- ########## Start of resource_plans.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/resource_manager/resource_plans.sql
-- Author       : Tim Hall
-- Description  : Lists all resource plans.
-- Call Syntax  : @resource_plans
-- Requirements : Access to the DBA views.
-- Last Modified: 12/11/2004
-- -----------------------------------------------------------------------------------
SET LINESIZE 200
SET VERIFY OFF

COLUMN status FORMAT A10
COLUMN comments FORMAT A50

SELECT plan,
       status,
       comments
FROM   dba_rsrc_plans
ORDER BY plan;
-- End of resource_plans.sql --

-- ########## Start of backup.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/backup.sql
-- Author       : Tim Hall
-- Description  : Creates a very basic hot-backup script. A useful starting point.
-- Call Syntax  : @backup
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 1000
SET TRIMOUT ON
SET FEEDBACK OFF
SPOOL Backup.txt

DECLARE

    CURSOR c_tablespace IS
        SELECT a.tablespace_name
        FROM   dba_tablespaces a
        ORDER BY 1;

    CURSOR c_datafiles (in_ts_name  IN  VARCHAR2) IS
        SELECT a.file_name
        FROM   dba_data_files a
        WHERE  a.tablespace_name = in_ts_name
        ORDER BY 1;

    CURSOR c_archive_redo IS
        SELECT a.value 
        FROM   v$parameter a
        WHERE  a.name = \'log_archive_dest\';

    v_sid            VARCHAR2(100) := \'ORCL\';
    v_backup_com     VARCHAR2(100) := \'!ocopy \';
    v_remove_com     VARCHAR2(100) := \'!rm\';
    v_dest_loc       VARCHAR2(100) := \'/opt/oracleddds/dbs1/oradata/ddds/\';

BEGIN

    DBMS_Output.Disable;
    DBMS_Output.Enable(1000000);

    DBMS_Output.Put_Line(\'svrmgrl\');
    DBMS_Output.Put_Line(\'connect internal\');

    DBMS_Output.Put_Line(\'	\');
    DBMS_Output.Put_Line(\'-- ----------------------\');
    DBMS_Output.Put_Line(\'-- Backup all tablespaces\');
    DBMS_Output.Put_Line(\'-- ----------------------\');
    FOR cur_ts IN c_tablespace LOOP
        DBMS_Output.Put_Line(\'	\');
        DBMS_Output.Put_Line(\'ALTER TABLESPACE \' || cur_ts.tablespace_name || \' BEGIN BACKUP;\');
        FOR cur_df IN c_datafiles (in_ts_name => cur_ts.tablespace_name) LOOP
            DBMS_Output.Put_Line(v_backup_com || \' \' || cur_df.file_name || \' \' || 
                                 v_dest_loc || SUBSTR(cur_df.file_name, INSTR(cur_df.file_name, \'/\', -1)+1));
        END LOOP;
        DBMS_Output.Put_Line(\'ALTER TABLESPACE \' || cur_ts.tablespace_name || \' END BACKUP;\');
    END LOOP;

    DBMS_Output.Put_Line(\'	\');
    DBMS_Output.Put_Line(\'-- -----------------------------\');
    DBMS_Output.Put_Line(\'-- Backup the archived redo logs\');
    DBMS_Output.Put_Line(\'-- -----------------------------\');
    FOR cur_ar IN c_archive_redo LOOP
        DBMS_Output.Put_Line(v_backup_com || \' \' || cur_ar.value || \'/* \' ||
                             v_dest_loc);
    END LOOP;


    DBMS_Output.Put_Line(\'	\');
    DBMS_Output.Put_Line(\'-- ----------------------\');
    DBMS_Output.Put_Line(\'-- Backup the controlfile\');
    DBMS_Output.Put_Line(\'-- ----------------------\');
    DBMS_Output.Put_Line(\'ALTER DATABASE BACKUP CONTROLFILE TO \'\'\' || v_dest_loc || v_sid || \'Controlfile.backup\'\';\');
    DBMS_Output.Put_Line(v_backup_com || \' \' || v_dest_loc || v_sid || \'Controlfile.backup\');
    DBMS_Output.Put_Line(v_remove_com || \' \' || v_dest_loc || v_sid || \'Controlfile.backup\');

    DBMS_Output.Put_Line(\'	\');
    DBMS_Output.Put_Line(\'EXIT\');

END;
/

PROMPT
SPOOL OFF
SET LINESIZE 80
SET FEEDBACK ON
-- End of backup.sql --

-- ########## Start of build_api.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/build_api.sql
-- Author       : Tim Hall
-- Description  : Generates a basic API package for the specific table.
-- Requirements : USER_% and ALL_% views.
-- Call Syntax  : @build_api (table-name) (schema)
-- Last Modified: 08/01/2002
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET VERIFY OFF
SET ECHO OFF
SET TERMOUT OFF
SET FEEDBACK OFF

SPOOL Package.pkh

DECLARE
  
  v_table_name VARCHAR2(30)  := Upper('&1');
  v_owner      VARCHAR2(30)  := Upper('&2');
  
  CURSOR c_pk_columns IS
    SELECT a.position,
           a.column_name
    FROM   all_cons_columns a,
           all_constraints b
    WHERE  a.owner           = v_owner
    AND    a.table_name      = v_table_name
    AND    a.constraint_name = b.constraint_name
    AND    b.constraint_type = 'P'
    AND    b.owner           = a.owner
    AND    b.table_name      = a.table_name
    ORDER BY position;

  CURSOR c_columns IS
    SELECT atc.column_name
    FROM   all_tab_columns atc
    WHERE  atc.owner      = v_owner
    AND    atc.table_name = v_table_name; 
    
  CURSOR c_non_pk_columns (p_nullable  IN  VARCHAR2) IS
    SELECT atc.column_name
    FROM   all_tab_columns atc
    WHERE  atc.owner      = v_owner
    AND    atc.table_name = v_table_name
    AND    atc.nullable   = p_nullable
    AND    atc.column_name NOT IN (SELECT a.column_name
                                   FROM   all_cons_columns a,
                                          all_constraints b
                                   WHERE  a. owner          = v_owner
                                   AND    a.table_name      = v_table_name
                                   AND    a.constraint_name = b.constraint_name
                                   AND    b.constraint_type = 'P'
                                   AND    b.owner           = a.owner
                                   AND    b.table_name      = a.table_name); 
    
  PROCEDURE GetParameterList IS
  BEGIN
    FOR cur_col IN c_pk_columns LOOP
      DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(cur_col.column_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '.' || Lower(cur_col.column_name) || '%TYPE,');
    END LOOP;
    FOR cur_col IN c_non_pk_columns('N') LOOP
      DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(cur_col.column_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '.' || Lower(cur_col.column_name) || '%TYPE,');
    END LOOP;
    FOR cur_col IN c_non_pk_columns('Y') LOOP
      DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(cur_col.column_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '.' || Lower(cur_col.column_name) || '%TYPE DEFAULT NULL,');
    END LOOP;
    DBMS_Output.Put(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
  END;
  
  PROCEDURE GetPKParameterList IS
  BEGIN
    FOR cur_col IN c_pk_columns LOOP
      DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(cur_col.column_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '.' || Lower(cur_col.column_name) || '%TYPE,');
    END LOOP;
    DBMS_Output.Put(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
  END;
  
  PROCEDURE GetInsertColumnList IS
  BEGIN
    FOR cur_col IN c_columns LOOP
      IF c_columns%ROWCOUNT != 1 THEN
        DBMS_Output.Put_Line(',');
      END IF;
      DBMS_Output.Put(Chr(9) || Chr(9) || Lower(cur_col.column_name));
    END LOOP;
    DBMS_Output.New_Line;
  END;

  PROCEDURE GetInsertValueList IS
  BEGIN
    FOR cur_col IN c_columns LOOP
      IF c_columns%ROWCOUNT != 1 THEN
        DBMS_Output.Put_Line(',');
      END IF;
      DBMS_Output.Put(Chr(9) || Chr(9) || 'p_' || Lower(cur_col.column_name));
    END LOOP;
    DBMS_Output.New_Line;
  END;

  PROCEDURE GetUpdateSetList IS
  BEGIN
    FOR cur_col IN c_columns LOOP
      IF c_columns%ROWCOUNT != 1 THEN
        DBMS_Output.Put_Line(',');
        DBMS_Output.Put(Chr(9) || Chr(9) || Chr(9) || Chr(9));
      ELSE
        DBMS_Output.Put(Chr(9) || 'SET    ');
      END IF;
      DBMS_Output.Put(RPad(Lower(cur_col.column_name), 30, ' ') || ' = p_' || Lower(cur_col.column_name));
    END LOOP;
    DBMS_Output.New_Line;
  END;
  
  PROCEDURE GetPKWhere (p_for_update  IN  VARCHAR2 DEFAULT NULL) IS
  BEGIN
    FOR cur_col IN c_pk_columns LOOP
      IF c_pk_columns%ROWCOUNT = 1 THEN
        DBMS_Output.Put(Chr(9) || 'WHERE  ');
      ELSE
        DBMS_Output.New_Line;
        DBMS_Output.Put(Chr(9) || 'AND    ');
      END IF;
      DBMS_Output.Put(RPad(Lower(cur_col.column_name), 30, ' ') || ' = p_' || Lower(cur_col.column_name));
    END LOOP;
    
    IF p_for_update = 'Y' THEN
      DBMS_Output.New_Line;
      DBMS_Output.Put(Chr(9) || 'FOR UPDATE');
    END IF;
    DBMS_Output.Put_Line(';');
  END;
  
  PROCEDURE GetCommit IS
  BEGIN
    DBMS_Output.Put_Line(Chr(9) || 'IF p_commit = ''Y'' THEN');
    DBMS_Output.Put_Line(Chr(9) || Chr(9) || 'COMMIT;');
    DBMS_Output.Put_Line(Chr(9) || 'END IF;');
    DBMS_Output.New_Line;
  END;

  PROCEDURE GetSeparator IS
  BEGIN
    DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  END;
  
BEGIN

  DBMS_Output.Enable(1000000);
  
  -- ---------------------
  -- Package Specification
  -- ---------------------
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('-- Name        : ' || Lower(v_table_name) || '_api.pkh');
  DBMS_Output.Put_Line('-- Created By  : Tim Hall');
  DBMS_Output.Put_Line('-- Created Date: ' || To_Char(Sysdate, 'DD-Mon-YYYY'));
  DBMS_Output.Put_Line('-- Description : API procedures for the ' || v_table_name || ' table.');
  DBMS_Output.Put_Line('-- Ammendments :');
  DBMS_Output.Put_Line('--   ' || To_Char(Sysdate, 'DD-Mon-YYYY') || '  TSH  Initial Creation');
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('CREATE OR REPLACE PACKAGE ' || Lower(v_table_name) || '_api AS');
  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line('TYPE cursor_type IS REF CURSOR;');
  DBMS_Output.Put_Line(Chr(9));
  
  DBMS_Output.Put_Line('PROCEDURE Sel (');
  GetPKParameterList;
  DBMS_Output.New_Line;
  DBMS_Output.Put_Line(Chr(9) || RPad('p_recordset', 32, ' ') || '  OUT cursor_type');
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('PROCEDURE Ins (');
  GetParameterList;
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('PROCEDURE Upd (');
  GetParameterList;
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('PROCEDURE Del (');
  GetPKParameterList;
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('END ' || Lower(v_table_name) || '_api;');
  DBMS_Output.Put_Line('/');

  -- ------------
  -- Package Body
  -- ------------
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('-- Name        : ' || Lower(v_table_name) || '_api.pkg');
  DBMS_Output.Put_Line('-- Created By  : Tim Hall');
  DBMS_Output.Put_Line('-- Created Date: ' || To_Char(Sysdate, 'DD-Mon-YYYY'));
  DBMS_Output.Put_Line('-- Description : API procedures for the ' || v_table_name || ' table.');
  DBMS_Output.Put_Line('-- Ammendments :');
  DBMS_Output.Put_Line('--   ' || To_Char(Sysdate, 'DD-Mon-YYYY') || '  TSH  Initial Creation');
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('CREATE OR REPLACE PACKAGE BODY ' || Lower(v_table_name) || '_api AS');
  DBMS_Output.Put_Line(Chr(9));

  -- Select
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Sel (');
  GetPKParameterList;
  DBMS_Output.New_Line;
  DBMS_Output.Put_Line(Chr(9) || RPad('p_recordset', 32, ' ') || '  OUT cursor_type');
  DBMS_Output.Put_Line(') IS');
  GetSeparator;

  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line(Chr(9) || 'OPEN p_recordset FOR');
  DBMS_Output.Put_Line(Chr(9) || 'SELECT'); 
  GetInsertColumnList;
  DBMS_Output.Put_Line(Chr(9) || 'FROM ' || Lower(v_table_name)); 
  GetPKWhere;

  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line('END Sel;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));


  -- Insert
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Ins (');
  GetParameterList;
  DBMS_Output.Put_Line(') IS');
  GetSeparator;
  
  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));
  
  DBMS_Output.Put_Line(Chr(9) || 'INSERT INTO ' || Lower(v_table_name));
  DBMS_Output.Put_Line(Chr(9) || '(');
  GetInsertColumnList;
  DBMS_Output.Put_Line(Chr(9) || ')');
  DBMS_Output.Put_Line(Chr(9) || 'VALUES');
  DBMS_Output.Put_Line(Chr(9) || '(');
  GetInsertValueList;
  DBMS_Output.Put_Line(Chr(9) || ');');
  DBMS_Output.Put_Line(Chr(9));
  
  GetCommit;
  DBMS_Output.Put_Line('END Ins;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));

  -- Update
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Upd (');
  GetParameterList;
  DBMS_Output.Put_Line(') IS');
  GetSeparator;
  
  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line(Chr(9) || 'UPDATE ' || Lower(v_table_name));
  GetUpdateSetList;
  GetPKWhere;
  DBMS_Output.Put_Line(Chr(9));
  
  GetCommit;
  DBMS_Output.Put_Line('END Upd;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));

  -- Delete
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Del (');
  GetPKParameterList;
  DBMS_Output.Put_Line(') IS');
  GetSeparator;
  
  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line(Chr(9) || 'DELETE FROM ' || Lower(v_table_name));
  GetPKWhere;
  DBMS_Output.Put_Line(Chr(9));

  GetCommit;
  DBMS_Output.Put_Line('END Del;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('END ' || Lower(v_table_name) || '_api;');
  DBMS_Output.Put_Line('/');

END;
/

SPOOL OFF

SET ECHO ON
SET TERMOUT ON
SET FEEDBACK ON

-- End of build_api.sql --

-- ########## Start of build_api2.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/build_api2.sql
-- Author       : Tim Hall
-- Description  : Generates a basic API package for the specific table.
--                Update of build_api to use ROWTYPEs as parameters.
-- Requirements : USER_% and ALL_% views.
-- Call Syntax  : @build_api2 (table-name) (schema)
-- Last Modified: 08/01/2002
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET VERIFY OFF
SET ECHO OFF
SET TERMOUT OFF
SET TRIMSPOOL ON
SET FEEDBACK OFF

SPOOL Package.pkh

DECLARE
  
  v_table_name VARCHAR2(30)  := Upper('&&1');
  v_owner      VARCHAR2(30)  := Upper('&&2');
  
  CURSOR c_pk_columns IS
    SELECT a.position,
           a.column_name
    FROM   all_cons_columns a,
           all_constraints b
    WHERE  a.owner           = v_owner
    AND    a.table_name      = v_table_name
    AND    a.constraint_name = b.constraint_name
    AND    b.constraint_type = 'P'
    AND    b.owner           = a.owner
    AND    b.table_name      = a.table_name
    ORDER BY position;

  CURSOR c_columns IS
    SELECT atc.column_name
    FROM   all_tab_columns atc
    WHERE  atc.owner      = v_owner
    AND    atc.table_name = v_table_name; 
    
  CURSOR c_non_pk_columns (p_nullable  IN  VARCHAR2) IS
    SELECT atc.column_name
    FROM   all_tab_columns atc
    WHERE  atc.owner      = v_owner
    AND    atc.table_name = v_table_name
    AND    atc.nullable   = p_nullable
    AND    atc.column_name NOT IN (SELECT a.column_name
                                   FROM   all_cons_columns a,
                                          all_constraints b
                                   WHERE  a. owner          = v_owner
                                   AND    a.table_name      = v_table_name
                                   AND    a.constraint_name = b.constraint_name
                                   AND    b.constraint_type = 'P'
                                   AND    b.owner           = a.owner
                                   AND    b.table_name      = a.table_name); 
    
  PROCEDURE GetPKParameterList(p_commit  IN  BOOLEAN  DEFAULT TRUE) IS
  BEGIN
    FOR cur_col IN c_pk_columns LOOP
      DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(cur_col.column_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '.' || Lower(cur_col.column_name) || '%TYPE,');
    END LOOP;
    IF p_commit THEN
      DBMS_Output.Put(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
    END IF;
  END;
  
  PROCEDURE GetInsertColumnList IS
  BEGIN
    FOR cur_col IN c_columns LOOP
      IF c_columns%ROWCOUNT != 1 THEN
        DBMS_Output.Put_Line(',');
      END IF;
      DBMS_Output.Put(Chr(9) || Chr(9) || Lower(cur_col.column_name));
    END LOOP;
    DBMS_Output.New_Line;
  END;

  PROCEDURE GetInsertValueList IS
  BEGIN
    FOR cur_col IN c_columns LOOP
      IF c_columns%ROWCOUNT != 1 THEN
        DBMS_Output.Put_Line(',');
      END IF;
      DBMS_Output.Put(Chr(9) || Chr(9) || 'p_' || Lower(v_table_name) || '.' || Lower(cur_col.column_name));
    END LOOP;
    DBMS_Output.New_Line;
  END;

  PROCEDURE GetUpdateSetList IS
  BEGIN
    FOR cur_col IN c_columns LOOP
      IF c_columns%ROWCOUNT != 1 THEN
        DBMS_Output.Put_Line(',');
        DBMS_Output.Put(Chr(9) || Chr(9) || Chr(9) || Chr(9));
      ELSE
        DBMS_Output.Put(Chr(9) || 'SET    ');
      END IF;
      DBMS_Output.Put(RPad(Lower(cur_col.column_name), 30, ' ') || ' = p_' || Lower(v_table_name) || '.' || Lower(cur_col.column_name));
    END LOOP;
    DBMS_Output.New_Line;
  END;
  
  PROCEDURE GetPKWhere (p_record      IN  VARCHAR2 DEFAULT NULL,
                        p_for_update  IN  VARCHAR2 DEFAULT NULL) IS
  BEGIN
    FOR cur_col IN c_pk_columns LOOP
      IF c_pk_columns%ROWCOUNT = 1 THEN
        DBMS_Output.Put(Chr(9) || 'WHERE  ');
      ELSE
        DBMS_Output.New_Line;
        DBMS_Output.Put(Chr(9) || 'AND    ');
      END IF;
      IF p_record = 'Y' THEN
        DBMS_Output.Put(RPad(Lower(cur_col.column_name), 30, ' ') || ' = p_' || Lower(v_table_name) || '.' || Lower(cur_col.column_name));
      ELSE
        DBMS_Output.Put(RPad(Lower(cur_col.column_name), 30, ' ') || ' = p_' || Lower(cur_col.column_name));
      END IF;
    END LOOP;
    
    IF p_for_update = 'Y' THEN
      DBMS_Output.New_Line;
      DBMS_Output.Put(Chr(9) || 'FOR UPDATE');
    END IF;
    DBMS_Output.Put_Line(';');
  END;
  
  PROCEDURE GetCommit IS
  BEGIN
    DBMS_Output.Put_Line(Chr(9) || 'IF p_commit = ''Y'' THEN');
    DBMS_Output.Put_Line(Chr(9) || Chr(9) || 'COMMIT;');
    DBMS_Output.Put_Line(Chr(9) || 'END IF;');
    DBMS_Output.New_Line;
  END;

  PROCEDURE GetSeparator IS
  BEGIN
    DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  END;
  
BEGIN

  DBMS_Output.Enable(1000000);
  
  -- ---------------------
  -- Package Specification
  -- ---------------------
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('-- Name        : ' || Lower(v_table_name) || '_api.pkh');
  DBMS_Output.Put_Line('-- Created By  : Tim Hall');
  DBMS_Output.Put_Line('-- Created Date: ' || To_Char(Sysdate, 'DD-Mon-YYYY'));
  DBMS_Output.Put_Line('-- Description : API procedures for the ' || v_table_name || ' table.');
  DBMS_Output.Put_Line('-- Ammendments :');
  DBMS_Output.Put_Line('--   ' || To_Char(Sysdate, 'DD-Mon-YYYY') || '  TSH  Initial Creation');
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('CREATE OR REPLACE PACKAGE ' || Lower(v_table_name) || '_api AS');
  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line('TYPE cursor_type IS REF CURSOR;');
  DBMS_Output.Put_Line(Chr(9));
  
  DBMS_Output.Put_Line('PROCEDURE Sel (');
  GetPKParameterList(FALSE);
  DBMS_Output.New_Line;
  DBMS_Output.Put_Line(Chr(9) || RPad('p_recordset', 32, ' ') || '  OUT cursor_type');
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('PROCEDURE Ins (');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(v_table_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '%ROWTYPE,');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('PROCEDURE Upd (');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(v_table_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '%ROWTYPE,');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('PROCEDURE Del (');
  GetPKParameterList;
  DBMS_Output.Put_Line(');');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('END ' || Lower(v_table_name) || '_api;');
  DBMS_Output.Put_Line('/');

  -- ------------
  -- Package Body
  -- ------------
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('-- Name        : ' || Lower(v_table_name) || '_api.pkg');
  DBMS_Output.Put_Line('-- Created By  : Tim Hall');
  DBMS_Output.Put_Line('-- Created Date: ' || To_Char(Sysdate, 'DD-Mon-YYYY'));
  DBMS_Output.Put_Line('-- Description : API procedures for the ' || v_table_name || ' table.');
  DBMS_Output.Put_Line('-- Ammendments :');
  DBMS_Output.Put_Line('--   ' || To_Char(Sysdate, 'DD-Mon-YYYY') || '  TSH  Initial Creation');
  DBMS_Output.Put_Line('-- -----------------------------------------------------------------------');
  DBMS_Output.Put_Line('CREATE OR REPLACE PACKAGE BODY ' || Lower(v_table_name) || '_api AS');
  DBMS_Output.Put_Line(Chr(9));

  -- Select
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Sel (');
  GetPKParameterList(FALSE);
  DBMS_Output.New_Line;
  DBMS_Output.Put_Line(Chr(9) || RPad('p_recordset', 32, ' ') || '  OUT cursor_type');
  DBMS_Output.Put_Line(') IS');
  GetSeparator;

  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line(Chr(9) || 'OPEN p_recordset FOR');
  DBMS_Output.Put_Line(Chr(9) || 'SELECT'); 
  GetInsertColumnList;
  DBMS_Output.Put_Line(Chr(9) || 'FROM ' || Lower(v_table_name)); 
  GetPKWhere;

  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line('END Sel;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));


  -- Insert
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Ins (');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(v_table_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '%ROWTYPE,');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
  DBMS_Output.Put_Line(') IS');
  GetSeparator;
  
  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));
  
  DBMS_Output.Put_Line(Chr(9) || 'INSERT INTO ' || Lower(v_table_name));
  DBMS_Output.Put_Line(Chr(9) || '(');
  GetInsertColumnList;
  DBMS_Output.Put_Line(Chr(9) || ')');
  DBMS_Output.Put_Line(Chr(9) || 'VALUES');
  DBMS_Output.Put_Line(Chr(9) || '(');
  GetInsertValueList;
  DBMS_Output.Put_Line(Chr(9) || ');');
  DBMS_Output.Put_Line(Chr(9));
  
  GetCommit;
  DBMS_Output.Put_Line('END Ins;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));

  -- Update
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Upd (');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad(Lower(v_table_name), 30, ' ') || '  IN  ' || Lower(v_table_name) || '%ROWTYPE,');
  DBMS_Output.Put_Line(Chr(9) || 'p_' || RPad('commit', 30, ' ') || '  IN  VARCHAR2 DEFAULT ''Y''');
  DBMS_Output.Put_Line(') IS');
  GetSeparator;
  
  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line(Chr(9) || 'UPDATE ' || Lower(v_table_name));
  GetUpdateSetList;
  GetPKWhere('Y');
  DBMS_Output.Put_Line(Chr(9));
  
  GetCommit;
  DBMS_Output.Put_Line('END Upd;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));

  -- Delete
  GetSeparator;
  DBMS_Output.Put_Line('PROCEDURE Del (');
  GetPKParameterList;
  DBMS_Output.Put_Line(') IS');
  GetSeparator;
  
  DBMS_Output.Put_Line('BEGIN');
  DBMS_Output.Put_Line(Chr(9));
  DBMS_Output.Put_Line(Chr(9) || 'DELETE FROM ' || Lower(v_table_name));
  GetPKWhere;
  DBMS_Output.Put_Line(Chr(9));

  GetCommit;
  DBMS_Output.Put_Line('END Del;');
  GetSeparator;
  DBMS_Output.Put_Line(Chr(9));

  DBMS_Output.Put_Line('END ' || Lower(v_table_name) || '_api;');
  DBMS_Output.Put_Line('/');

END;
/

SPOOL OFF

SET ECHO ON
SET TERMOUT ON
SET FEEDBACK ON

-- End of build_api2.sql --

-- ########## Start of create_data.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/create_data.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL to repopulate the specified table.
-- Call Syntax  : @create_data (table-name) (schema)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET LINESIZE 1000
SET SERVEROUTPUT ON
SET FEEDBACK OFF
SET PAGESIZE 0
SET VERIFY OFF
SET TRIMSPOOL ON
SET TRIMOUT ON

ALTER SESSION SET nls_date_format = 'DD-MON-YYYY HH24:MI:SS';
 
SPOOL temp.sql

DECLARE

  CURSOR c_columns (p_table_name  IN  VARCHAR2,
                    p_owner       IN  VARCHAR2) IS
    SELECT Lower(a.column_name) column_name,
           a.data_type
    FROM   all_tab_columns a
    WHERE  a.table_name = p_table_name
    AND    a.owner      = p_owner
    AND    a.data_type  IN ('CHAR','VARCHAR2','DATE','NUMBER','INTEGER');
    
  v_table_name  VARCHAR2(30) := Upper('&&1');
  v_owner       VARCHAR2(30) := Upper('&&2');
  
  
  FUNCTION Format_Col(p_column    IN  VARCHAR2,
                      p_datatype  IN  VARCHAR2) 
    RETURN VARCHAR2 IS
  BEGIN
    IF p_datatype IN ('CHAR','VARCHAR2','DATE') THEN
      RETURN ''' || Decode(' || p_column || ',NULL,''NULL'','''''''' || ' || p_column || ' || '''''''') || ''';
    ELSE 
      RETURN ''' || Decode(' || p_column || ',NULL,''NULL'',' || p_column || ') || ''';
    END IF;
  END;
    
BEGIN

  Dbms_Output.Disable;
  Dbms_Output.Enable(1000000);
  
  Dbms_Output.Put_Line('SELECT ''INSERT INTO ' || Lower(v_owner) || '.' || Lower(v_table_name));
  Dbms_Output.Put_Line('(');
  << Columns_Loop >>
  FOR cur_rec IN c_columns (v_table_name, v_owner) LOOP
    IF c_columns%ROWCOUNT != 1 THEN
      Dbms_Output.Put_Line(',');
    END IF;
    Dbms_Output.Put(cur_rec.column_name);
  END LOOP Columns_Loop;
  Dbms_Output.New_Line;
  Dbms_Output.Put_Line(')');
  Dbms_Output.Put_Line('VALUES');
  Dbms_Output.Put_Line('(');
  
  << Data_Loop >>
  FOR cur_rec IN c_columns (v_table_name, v_owner) LOOP
    IF c_columns%ROWCOUNT != 1 THEN
      Dbms_Output.Put_Line(',');
    END IF;
    Dbms_Output.Put(Format_Col(cur_rec.column_name, cur_rec.data_type));
  END LOOP Data_Loop;
  Dbms_Output.New_Line;
  Dbms_Output.Put_Line(');''');
  Dbms_Output.Put_Line('FROM ' || Lower(v_owner) || '.' || Lower(v_table_name) );
  Dbms_Output.Put_Line('/');

END;
/

SPOOL OFF

SET LINESIZE 1000
SPOOL table_data.sql

@temp.sql

SPOOL OFF

SET PAGESIZE 14
SET FEEDBACK ON
-- End of create_data.sql --

-- ########## Start of db_link_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/db_link_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for DB links for the specific schema, or all schemas.
-- Call Syntax  : @db_link_ddl (schema or all)
-- Last Modified: 16/03/2013
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('DB_LINK', db_link, owner)
FROM   dba_db_links
WHERE  owner = DECODE(UPPER('&1'), 'ALL', owner, UPPER('&1'));

SET PAGESIZE 14 LINESIZE 1000 FEEDBACK ON VERIFY ON
-- End of db_link_ddl.sql --

-- ########## Start of directory_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/directory_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for specified directory, or all directories.
-- Call Syntax  : @directory_ddl (directory or all)
-- Last Modified: 16/03/2013
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('DIRECTORY', directory_name)
FROM   dba_directories
WHERE  directory_name = DECODE(UPPER('&1'), 'ALL', directory_name, UPPER('&1'));

SET PAGESIZE 14 LINESIZE 1000 FEEDBACK ON VERIFY ON
-- End of directory_ddl.sql --

-- ########## Start of drop_cons_on_table.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/drop_cons_on_table.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL to drop the UK & PK constraints on the specified table, or all tables.
-- Call Syntax  : @drop_cons_on_table (table-name or all) (schema)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 100
SET VERIFY OFF
SET FEEDBACK OFF
PROMPT

DECLARE

    CURSOR cu_cons IS
        SELECT *
        FROM   all_constraints a
        WHERE  a.table_name = Decode(Upper('&&1'),'ALL',a.table_name,Upper('&&1'))
        AND    a.owner      = Upper('&&2')
        AND    a.constraint_type IN ('P','U');

    -- ----------------------------------------------------------------------------------------
    FUNCTION Con_Columns(p_tab  IN  VARCHAR2,
                         p_con  IN  VARCHAR2)
        RETURN VARCHAR2 IS
    -- ----------------------------------------------------------------------------------------    
        CURSOR cu_col_cursor IS
            SELECT  a.column_name
            FROM    all_cons_columns a
            WHERE   a.table_name      = p_tab
            AND     a.constraint_name = p_con
            AND     a.owner           = Upper('&&2')
            ORDER BY a.position;
     
        l_result    VARCHAR2(1000);        
    BEGIN    
        FOR cur_rec IN cu_col_cursor LOOP
            IF cu_col_cursor%ROWCOUNT = 1 THEN
                l_result   := cur_rec.column_name;
            ELSE
                l_result   := l_result || ',' || cur_rec.column_name;
            END IF;
        END LOOP;
        RETURN Lower(l_result);        
    END;
    -- ----------------------------------------------------------------------------------------

BEGIN

    DBMS_Output.Disable;
    DBMS_Output.Enable(1000000);
    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Droping Constraints on ' || Upper('&&1'));
    FOR cur_rec IN cu_cons LOOP
        IF    cur_rec.constraint_type = 'P' THEN
            DBMS_Output.Put_Line('ALTER TABLE ' || Lower(cur_rec.table_name) || ' DROP PRIMARY KEY;');
        ELSIF cur_rec.constraint_type = 'R' THEN
            DBMS_Output.Put_Line('ALTER TABLE ' || Lower(cur_rec.table_name) || ' DROP CONSTRAINT ' || Lower(cur_rec.constraint_name) || ';');
        ELSIF cur_rec.constraint_type = 'U' THEN
            DBMS_Output.Put_Line('ALTER TABLE ' || Lower(cur_rec.table_name) || ' DROP UNIQUE (' || Con_Columns(cur_rec.table_name, cur_rec.constraint_name) || ');');
        END IF;
    END LOOP; 
 
END;
/

PROMPT
SET VERIFY ON
SET FEEDBACK ON



	


-- End of drop_cons_on_table.sql --

-- ########## Start of drop_fks_on_table.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/drop_fks_on_table.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL to drop the foreign keys on the specified table.
-- Call Syntax  : @drop_fks_on_table (table-name) (schema)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 100
SET VERIFY OFF
SET FEEDBACK OFF
PROMPT

DECLARE

    CURSOR cu_fks IS
        SELECT *
        FROM   all_constraints a
        WHERE  a.constraint_type = 'R'
        AND    a.table_name = Decode(Upper('&&1'),'ALL',a.table_name,Upper('&&1'))
        AND    a.owner      = Upper('&&2');

BEGIN

    DBMS_Output.Disable;
    DBMS_Output.Enable(1000000);
    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Droping Foreign Keys on ' || Upper('&&1'));
    FOR cur_rec IN cu_fks LOOP
        DBMS_Output.Put_Line('ALTER TABLE ' || Lower(cur_rec.table_name) || ' DROP CONSTRAINT ' || Lower(cur_rec.constraint_name) || ';');
    END LOOP; 

END;
/

PROMPT
SET VERIFY ON
SET FEEDBACK ON



	


-- End of drop_fks_on_table.sql --

-- ########## Start of drop_fks_ref_table.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/drop_fks_ref_table.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL to drop the foreign keys that referenece the specified table.
-- Call Syntax  : @drop_fks_ref_table (table-name) (schema)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 100
SET VERIFY OFF
SET FEEDBACK OFF
PROMPT

DECLARE

    CURSOR cu_fks IS
        SELECT *
        FROM   all_constraints a
        WHERE  a.owner      = Upper('&&2')
        AND    a.constraint_type = 'R'
        AND    a.r_constraint_name IN (SELECT a1.constraint_name
                                       FROM   all_constraints a1
                                       WHERE  a1.table_name = Upper('&&1')
                                       AND    a1.owner      = Upper('&&2'));

BEGIN

    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Droping Foreign Keys to ' || Upper('&&1'));
    FOR cur_rec IN cu_fks LOOP
        DBMS_Output.Put_Line('ALTER TABLE ' || Lower(cur_rec.table_name) || ' DROP CONSTRAINT ' || Lower(cur_rec.constraint_name) || ';');
    END LOOP; 

END;
/

PROMPT
SET VERIFY ON
SET FEEDBACK ON



	


-- End of drop_fks_ref_table.sql --

-- ########## Start of drop_indexes.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/drop_indexes.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL to drop the indexes on the specified table, or all tables.
-- Call Syntax  : @drop_indexes (table-name or all) (schema)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 100
SET VERIFY OFF
SET FEEDBACK OFF
PROMPT

DECLARE

    CURSOR cu_idx IS
        SELECT *
        FROM   all_indexes a
        WHERE  a.table_name = Decode(Upper('&&1'),'ALL',a.table_name,Upper('&&1'))
        AND    a.owner      = Upper('&&2');

BEGIN

    DBMS_Output.Disable;
    DBMS_Output.Enable(1000000);
    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Droping Indexes on ' || Upper('&&1'));
    FOR cur_rec IN cu_idx LOOP
        DBMS_Output.Put_Line('DROP INDEX ' || Lower(cur_rec.index_name) || ';');
    END LOOP; 

END;
/

PROMPT
SET VERIFY ON
SET FEEDBACK ON



	


-- End of drop_indexes.sql --

-- ########## Start of fks_on_table_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/fks_on_table_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the foreign keys on the specified table, or all tables.
-- Call Syntax  : @fks_on_table_ddl (schema) (table-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('REF_CONSTRAINT', constraint_name, owner)
FROM   all_constraints
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
AND    constraint_type = 'R';

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON

-- End of fks_on_table_ddl.sql --

-- ########## Start of fks_ref_table_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/fks_ref_table_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the foreign keys that reference the specified table.
-- Call Syntax  : @fks_ref_table_ddl (schema) (table-name)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('REF_CONSTRAINT', ac1.constraint_name, ac1.owner)
FROM   all_constraints ac1
       JOIN all_constraints ac2 ON ac1.r_owner = ac2.owner AND ac1.r_constraint_name = ac2.constraint_name
WHERE  ac2.owner      = UPPER('&1')
AND    ac2.table_name = UPPER('&2')
AND    ac2.constraint_type IN ('P','U')
AND    ac1.constraint_type = 'R';

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of fks_ref_table_ddl.sql --

-- ########## Start of index_monitoring_off.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/index_monitoring_on.sql
-- Author       : Tim Hall
-- Description  : Sets monitoring off for the specified table indexes.
-- Call Syntax  : @index_monitoring_on (schema) (table-name or all)
-- Last Modified: 04/02/2005
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SPOOL temp.sql

SELECT 'ALTER INDEX "' || i.owner || '"."' || i.index_name || '" NOMONITORING USAGE;'
FROM   dba_indexes i
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

SPOOL OFF

SET PAGESIZE 18
SET FEEDBACK ON

@temp.sql


-- End of index_monitoring_off.sql --

-- ########## Start of index_monitoring_on.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/index_monitoring_on.sql
-- Author       : Tim Hall
-- Description  : Sets monitoring on for the specified table indexes.
-- Call Syntax  : @index_monitoring_on (schema) (table-name or all)
-- Last Modified: 04/02/2005
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SPOOL temp.sql

SELECT 'ALTER INDEX "' || i.owner || '"."' || i.index_name || '" MONITORING USAGE;'
FROM   dba_indexes i
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

SPOOL OFF

SET PAGESIZE 18
SET FEEDBACK ON

@temp.sql


-- End of index_monitoring_on.sql --

-- ########## Start of job_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/job_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified job.
-- Call Syntax  : @job_ddl (schema-name) (job-name)
-- Last Modified: 31/12/2018
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('PROCOBJ', job_name, owner)
FROM   all_scheduler_jobs
WHERE  owner    = UPPER('&1')
AND    job_name = DECODE(UPPER('&2'), 'ALL', job_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of job_ddl.sql --

-- ########## Start of logon_as_user.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/logon_as_user.sql
-- Author       : Tim Hall
-- Description  : Displays the DDL for a specific user.
--                Better approaches included here.
--                https://oracle-base.com/articles/misc/proxy-users-and-connect-through
-- Call Syntax  : @logon_as_user (username)
-- Last Modified: 28/01/2006 - Added link to article.
-- -----------------------------------------------------------------------------------

set serveroutput on verify off
declare
  l_username VARCHAR2(30) :=  upper('&1');
  l_orig_pwd VARCHAR2(32767);
begin 
  select password
  into   l_orig_pwd
  from   sys.user$
  where  name = l_username;

  dbms_output.put_line('--');
  dbms_output.put_line('alter user ' || l_username || ' identified by DummyPassword1;');
  dbms_output.put_line('conn ' || l_username || '/DummyPassword1');

  dbms_output.put_line('--');
  dbms_output.put_line('-- Do something here.');
  dbms_output.put_line('--');

  dbms_output.put_line('conn / as sysdba');
  dbms_output.put_line('alter user ' || l_username || ' identified by values '''||l_orig_pwd||''';');
end;
/

-- End of logon_as_user.sql --

-- ########## Start of logon_as_user_orig.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/logon_as_user_orig.sql
-- Author       : Tim Hall
-- Description  : Displays the DDL for a specific user.
--                Better approaches included here.
--                https://oracle-base.com/articles/misc/proxy-users-and-connect-through
-- Call Syntax  : @logon_as_user_orig (username)
-- Last Modified: 06/06/2019 - Added link to article.
-- -----------------------------------------------------------------------------------

set serveroutput on verify off
declare
  l_username VARCHAR2(30) :=  upper('&1');
  l_orig_pwd VARCHAR2(32767);
begin 
  select password
  into   l_orig_pwd
  from   dba_users
  where  username = l_username;

  dbms_output.put_line('--');
  dbms_output.put_line('alter user ' || l_username || ' identified by DummyPassword1;');
  dbms_output.put_line('conn ' || l_username || '/DummyPassword1');

  dbms_output.put_line('--');
  dbms_output.put_line('-- Do something here.');
  dbms_output.put_line('--');

  dbms_output.put_line('conn / as sysdba');
  dbms_output.put_line('alter user ' || l_username || ' identified by values '''||l_orig_pwd||''';');
end;
/

-- End of logon_as_user_orig.sql --

-- ########## Start of monitoring_off.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/monitoring_on.sql
-- Author       : Tim Hall
-- Description  : Sets monitoring off for the specified tables.
-- Call Syntax  : @monitoring_on (schema) (table-name or all)
-- Last Modified: 21/03/2003
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SPOOL temp.sql

SELECT 'ALTER TABLE "' || owner || '"."' || table_name || '" NOMONITORING;'
FROM   dba_tables
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
AND    monitoring = 'YES';

SPOOL OFF

SET PAGESIZE 18
SET FEEDBACK ON

@temp.sql


-- End of monitoring_off.sql --

-- ########## Start of monitoring_on.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/monitoring_on.sql
-- Author       : Tim Hall
-- Description  : Sets monitoring on for the specified tables.
-- Call Syntax  : @monitoring_on (schema) (table-name or all)
-- Last Modified: 21/03/2003
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF
SPOOL temp.sql

SELECT 'ALTER TABLE "' || owner || '"."' || table_name || '" MONITORING;'
FROM   dba_tables
WHERE  owner       = UPPER('&1')
AND    table_name  = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
AND    monitoring != 'YES';

SPOOL OFF

SET PAGESIZE 18
SET FEEDBACK ON

@temp.sql


-- End of monitoring_on.sql --

-- ########## Start of network_acls_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/11g/network_acls_ddl.sql
-- Author       : Tim Hall
-- Description  : Displays DDL for all network ACLs.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @network_acls_ddl
-- Last Modified: 28-JUL-2017
-- -----------------------------------------------------------------------------------

SET SERVEROUTPUT ON FORMAT WRAPPED LINESIZE 300
DECLARE
  l_last_acl       dba_network_acls.acl%TYPE                 := '~';
  l_last_principal dba_network_acl_privileges.principal%TYPE := '~';
  l_last_privilege dba_network_acl_privileges.privilege%TYPE := '~';
  l_last_host      dba_network_acls.host%TYPE                := '~';

  FUNCTION get_timestamp (p_timestamp IN TIMESTAMP WITH TIME ZONE)
    RETURN VARCHAR2
  AS
    l_return  VARCHAR2(32767);
  BEGIN
    IF p_timestamp IS NULL THEN
      RETURN 'NULL';
    END IF;
    RETURN 'TO_TIMESTAMP_TZ(''' || TO_CHAR(p_timestamp, 'DD-MON-YYYY HH24:MI:SS.FF TZH:TZM') || ''',''DD-MON-YYYY HH24:MI:SS.FF TZH:TZM'')';
  END;
BEGIN
  FOR i IN (SELECT a.acl,
                   a.host,
                   a.lower_port,
                   a.upper_port,
                   b.principal,
                   b.privilege,
                   b.is_grant,
                   b.start_date,
                   b.end_date
            FROM   dba_network_acls a
                   JOIN dba_network_acl_privileges b ON a.acl = b.acl
            ORDER BY a.acl, a.host, a.lower_port, a.upper_port)
  LOOP
    IF l_last_acl <> i.acl THEN
      -- First time we've seen this ACL, so create a new one.
      l_last_host := '~';

      DBMS_OUTPUT.put_line('-- -------------------------------------------------');
      DBMS_OUTPUT.put_line('-- ' || i.acl);
      DBMS_OUTPUT.put_line('-- -------------------------------------------------');
      DBMS_OUTPUT.put_line('BEGIN');
      DBMS_OUTPUT.put_line('  DBMS_NETWORK_ACL_ADMIN.drop_acl (');
      DBMS_OUTPUT.put_line('    acl          => ''' || i.acl || ''');');
      DBMS_OUTPUT.put_line('  COMMIT;');
      DBMS_OUTPUT.put_line('END;');
      DBMS_OUTPUT.put_line('/');
      DBMS_OUTPUT.put_line(' ');
      DBMS_OUTPUT.put_line('BEGIN');
      DBMS_OUTPUT.put_line('  DBMS_NETWORK_ACL_ADMIN.create_acl (');
      DBMS_OUTPUT.put_line('    acl          => ''' || i.acl || ''',');
      DBMS_OUTPUT.put_line('    description  => ''' || i.acl || ''',');
      DBMS_OUTPUT.put_line('    principal    => ''' || i.principal || ''',');
      DBMS_OUTPUT.put_line('    is_grant     => ' || i.is_grant || ',');
      DBMS_OUTPUT.put_line('    privilege    => ''' || i.privilege || ''',');
      DBMS_OUTPUT.put_line('    start_date   => ' || get_timestamp(i.start_date) || ',');
      DBMS_OUTPUT.put_line('    end_date     => ' || get_timestamp(i.end_date) || ');');
      DBMS_OUTPUT.put_line('  COMMIT;');
      DBMS_OUTPUT.put_line('END;');
      DBMS_OUTPUT.put_line('/');
      DBMS_OUTPUT.put_line(' ');
      l_last_acl := i.acl;
      l_last_principal := i.principal;
      l_last_privilege := i.privilege;
    END IF;

    IF l_last_principal <> i.principal 
    OR (l_last_principal = i.principal AND l_last_privilege <> i.privilege) THEN
      -- Add another principal to an existing ACL.
      DBMS_OUTPUT.put_line('BEGIN');
      DBMS_OUTPUT.put_line('  DBMS_NETWORK_ACL_ADMIN.add_privilege (');
      DBMS_OUTPUT.put_line('    acl       => ''' || i.acl || ''',');
      DBMS_OUTPUT.put_line('    principal => ''' || i.principal || ''',');
      DBMS_OUTPUT.put_line('    is_grant  => ' || i.is_grant || ',');
      DBMS_OUTPUT.put_line('    privilege => ''' || i.privilege || ''',');
      DBMS_OUTPUT.put_line('    start_date   => ' || get_timestamp(i.start_date) || ',');
      DBMS_OUTPUT.put_line('    end_date     => ' || get_timestamp(i.end_date) || ');');
      DBMS_OUTPUT.put_line('  COMMIT;');
      DBMS_OUTPUT.put_line('END;');
      DBMS_OUTPUT.put_line('/');
      DBMS_OUTPUT.put_line(' ');
      l_last_principal := i.principal;
      l_last_privilege := i.privilege;
    END IF;

    IF l_last_host <> i.host||':'||i.lower_port||':'||i.upper_port THEN
      DBMS_OUTPUT.put_line('BEGIN');
      DBMS_OUTPUT.put_line('  DBMS_NETWORK_ACL_ADMIN.assign_acl (');
      DBMS_OUTPUT.put_line('    acl         => ''' || i.acl || ''',');
      DBMS_OUTPUT.put_line('    host        => ''' || i.host || ''',');
      DBMS_OUTPUT.put_line('    lower_port  => ' || NVL(TO_CHAR(i.lower_port),'NULL') || ',');
      DBMS_OUTPUT.put_line('    upper_port  => ' || NVL(TO_CHAR(i.upper_port),'NULL') || ');');
      DBMS_OUTPUT.put_line('  COMMIT;');
      DBMS_OUTPUT.put_line('END;');
      DBMS_OUTPUT.put_line('/');
      DBMS_OUTPUT.put_line(' ');
      l_last_host := i.host||':'||i.lower_port||':'||i.upper_port;
    END IF;
  END LOOP;
END;
/

-- End of network_acls_ddl.sql --

-- ########## Start of object_grants.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/object_grants.sql
-- Author       : Tim Hall
-- Description  : Displays the DDL for all grants on a specific object.
-- Call Syntax  : @object_grants (owner) (object_name)
-- Last Modified: 28/01/2006
-- -----------------------------------------------------------------------------------

set long 1000000 linesize 1000 pagesize 0 feedback off trimspool on verify off
column ddl format a1000

begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/
 
select dbms_metadata.get_dependent_ddl('OBJECT_GRANT', UPPER('&2'), UPPER('&1')) AS ddl
from   dual;

set linesize 80 pagesize 14 feedback on trimspool on verify on

-- End of object_grants.sql --

-- ########## Start of profile_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/profile_ddl.sql
-- Author       : Tim Hall
-- Description  : Displays the DDL for the specified profile(s).
-- Call Syntax  : @profile_ddl (profile | part of profile)
-- Last Modified: 28/01/2006
-- -----------------------------------------------------------------------------------

set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a1000

begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/

select dbms_metadata.get_ddl('PROFILE', profile) as profile_ddl
from   (select distinct profile
        from   dba_profiles)
where  profile like upper('%&1%');

set linesize 80 pagesize 14 feedback on verify on

-- End of profile_ddl.sql --

-- ########## Start of rbs_structure.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/rbs_structure.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for specified segment, or all segments.
-- Call Syntax  : @rbs_structure (segment-name or all)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 100
SET VERIFY OFF
SET FEEDBACK OFF
PROMPT

DECLARE

    CURSOR cu_rs IS
        SELECT a.segment_name,
               a.tablespace_name,
               a.initial_extent,
               a.next_extent,
               a.min_extents,
               a.max_extents,
               a.pct_increase,
               b.bytes
        FROM   dba_rollback_segs a,
               dba_segments      b
        WHERE  a.segment_name = b.segment_name
        AND    a.segment_name  = Decode(Upper('&&1'), 'ALL',a.segment_name, Upper('&&1'))
        ORDER BY a.segment_name;
 
BEGIN

    DBMS_Output.Disable;
    DBMS_Output.Enable(1000000);

    FOR cur_rs IN cu_rs LOOP
        DBMS_Output.Put_Line('PROMPT');
        DBMS_Output.Put_Line('PROMPT Creating Rollback Segment ' || cur_rs.segment_name);
        DBMS_Output.Put_Line('CREATE ROLLBACK SEGMENT ' || Lower(cur_rs.segment_name));
        DBMS_Output.Put_Line('TABLESPACE ' || Lower(cur_rs.tablespace_name));        
        DBMS_Output.Put_Line('STORAGE	(');
        DBMS_Output.Put_Line('		INITIAL     ' || Trunc(cur_rs.initial_extent/1024) || 'K');
        DBMS_Output.Put_Line('		NEXT        ' || Trunc(cur_rs.next_extent/1024) || 'K');
        DBMS_Output.Put_Line('		MINEXTENTS  ' || cur_rs.min_extents);
        DBMS_Output.Put_Line('		MAXEXTENTS  ' || cur_rs.max_extents);
        DBMS_Output.Put_Line('		PCTINCREASE ' || cur_rs.pct_increase);
        DBMS_Output.Put_Line('	)');
        DBMS_Output.Put_Line('/');        
        DBMS_Output.Put_Line('	');        
    END LOOP;

    DBMS_Output.Put_Line('	');

END;
/

SET VERIFY ON
SET FEEDBACK ON
-- End of rbs_structure.sql --

-- ########## Start of recreate_table.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/recreate_table.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL to recreate the specified table.
-- Comments     : Mostly used when dropping columns prior to Oracle 8i. Not updated since Oracle 7.3.4.
-- Requirements : Requires a number of the other creation scripts.
-- Call Syntax  : @recreate_table (table-name) (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET SERVEROUTPUT ON
SET LINESIZE 100
SET VERIFY OFF
SET FEEDBACK OFF
SET TERMOUT OFF
SPOOL ReCreate_&&1
PROMPT

-- ----------------------------------------------
-- Reset the buffer size and display script title
-- ----------------------------------------------
BEGIN
    DBMS_Output.Disable;
    DBMS_Output.Enable(1000000);
    DBMS_Output.Put_Line('-------------------------------------------------------------');
    DBMS_Output.Put_Line('-- Author        : Tim Hall');
    DBMS_Output.Put_Line('-- Creation Date : ' || To_Char(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    DBMS_Output.Put_Line('-- Description   : Re-creation script for ' ||  Upper('&&1'));
    DBMS_Output.Put_Line('-------------------------------------------------------------');
END;
/
       
-- ------------------------------------
-- Drop existing FKs to specified table
-- ------------------------------------
@Drop_FKs_Ref_Table &&1 &&2    

-- -----------------
-- Drop FKs on table
-- -----------------
@Drop_FKs_On_Table &&1 &&2  
    
-- -------------------------
-- Drop constraints on table
-- -------------------------
@Drop_Cons_On_Table &&1 &&2  
    
-- ---------------------
-- Drop indexes on table
-- ---------------------
@Drop_Indexes &&1 &&2 
    
-- -----------------------------------------
-- Rename existing table - prefix with 'tmp'
-- -----------------------------------------
SET VERIFY OFF
SET FEEDBACK OFF
BEGIN
    DBMS_Output.Put_Line('	');
    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Renaming ' || Upper('&&1') || ' to TMP_' || Upper('&&1'));
    DBMS_Output.Put_Line('RENAME ' || Lower('&&1') || ' TO tmp_' || Lower('&&1'));
    DBMS_Output.Put_Line('/');
END;
/
    
-- ---------------
-- Re-Create table
-- ---------------
@Table_Structure &&1 &&2

-- ---------------------
-- Re-Create constraints
-- ---------------------
@Table_Constraints &&1 &&2

-- ---------------------
-- Recreate FKs on table
-- ---------------------
@FKs_On_Table &&1 &&2

-- -----------------
-- Re-Create indexes
-- -----------------
@Table_Indexes &&1 &&2
    
-- --------------------------
-- Build up population insert
-- --------------------------
SET VERIFY OFF
SET FEEDBACK OFF
DECLARE

    CURSOR cu_columns IS
        SELECT Lower(column_name) column_name
        FROM   all_tab_columns atc
        WHERE  atc.table_name = Upper('&&1')
        AND    atc.owner      = Upper('&&2');

BEGIN

    DBMS_Output.Put_Line('	');
    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Populating ' || Upper('&&1') || ' from TPM_' || Upper('&&1'));
    DBMS_Output.Put_Line('INSERT INTO ' || Lower('&&1'));
    DBMS_Output.Put('SELECT ');
    FOR cur_rec IN cu_columns LOOP
        IF cu_columns%ROWCOUNT != 1 THEN
            DBMS_Output.Put_Line(',');
        END IF;
        DBMS_Output.Put('	a.' || cur_rec.column_name);
    END LOOP; 
    DBMS_Output.New_Line;
    DBMS_Output.Put_Line('FROM	tmp_' || Lower('&&1') || ' a');
    DBMS_Output.Put_Line('/');
      
    -- --------------
    -- Drop tmp table
    -- --------------
    DBMS_Output.Put_Line('	');
    DBMS_Output.Put_Line('PROMPT');
    DBMS_Output.Put_Line('PROMPT Droping TMP_' || Upper('&&1'));
    DBMS_Output.Put_Line('DROP TABLE tmp_' || Lower('&&1'));
    DBMS_Output.Put_Line('/');

END;
/

-- ---------------------
-- Recreate FKs to table
-- ---------------------
@FKs_Ref_Table &&1 &&2

SET VERIFY OFF
SET FEEDBACK OFF
BEGIN    
    DBMS_Output.Put_Line('	');
    DBMS_Output.Put_Line('-------------------------------------------------------------');
    DBMS_Output.Put_Line('-- END Re-creation script for ' || Upper('&&1'));
    DBMS_Output.Put_Line('-------------------------------------------------------------');
END;
/

SPOOL OFF
PROMPT
SET VERIFY ON
SET FEEDBACK ON
SET TERMOUT ON


-- End of recreate_table.sql --

-- ########## Start of role_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/role_ddl.sql
-- Author       : Tim Hall
-- Description  : Displays the DDL for a specific role.
-- Call Syntax  : @role_ddl (role)
-- Last Modified: 27/07/2022 - Increase long to 1000000.
-- -----------------------------------------------------------------------------------

set long 1000000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a1000

begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/
 
variable v_role VARCHAR2(30);

exec :v_role := upper('&1');

select dbms_metadata.get_ddl('ROLE', r.role) AS ddl
from   dba_roles r
where  r.role = :v_role
union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_role
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  sp.grantee = :v_role
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  tp.grantee = :v_role
and    rownum = 1
/

set linesize 80 pagesize 14 feedback on verify on

-- End of role_ddl.sql --

-- ########## Start of sequence_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/sequence_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified sequence, or all sequences.
-- Call Syntax  : @sequence_ddl (schema-name) (sequence-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('SEQUENCE', sequence_name, sequence_owner)
FROM   all_sequences
WHERE  sequence_owner = UPPER('&1')
AND    sequence_name  = DECODE(UPPER('&2'), 'ALL', sequence_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of sequence_ddl.sql --

-- ########## Start of synonym_by_object_owner_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/synonym_by_object_owner_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified synonym, or all synonyms.
--                Search based on owner of the object, not the synonym.
-- Call Syntax  : @synonym_by_object_owner_ddl (schema-name) (synonym-name or all)
-- Last Modified: 08/07/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('SYNONYM', synonym_name, owner)
FROM   all_synonyms
WHERE  table_owner = UPPER('&1')
AND    synonym_name  = DECODE(UPPER('&2'), 'ALL', synonym_name, UPPER('&2'));

SET PAGESIZE 14 FEEDBACK ON VERIFY ON
-- End of synonym_by_object_owner_ddl.sql --

-- ########## Start of synonym_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/synonym_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified synonym, or all synonyms.
--                Search based on owner of the synonym.
-- Call Syntax  : @synonym_ddl (schema-name) (synonym-name or all)
-- Last Modified: 08/07/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('SYNONYM', synonym_name, owner)
FROM   all_synonyms
WHERE  owner = UPPER('&1')
AND    synonym_name  = DECODE(UPPER('&2'), 'ALL', synonym_name, UPPER('&2'));

SET PAGESIZE 14 FEEDBACK ON VERIFY ON
-- End of synonym_ddl.sql --

-- ########## Start of synonym_public_remote_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/synonym_public_remote_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for public synonyms to remote objects.
-- Call Syntax  : @synonym_remote_ddl
-- Last Modified: 08/07/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('SYNONYM', synonym_name, owner)
FROM   dba_synonyms
WHERE  owner = 'PUBLIC'
AND    db_link IS NOT NULL;

SET PAGESIZE 14 FEEDBACK ON VERIFY ON
-- End of synonym_public_remote_ddl.sql --

-- ########## Start of table_constraints_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/table_constraints_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the UK & PK constraint DDL for specified table, or all tables.
-- Call Syntax  : @table_constraints_ddl (schema-name) (table-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('CONSTRAINT', constraint_name, owner)
FROM   all_constraints
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'))
AND    constraint_type IN ('U', 'P');

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON

-- End of table_constraints_ddl.sql --

-- ########## Start of table_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/table_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for specified table, or all tables.
-- Call Syntax  : @table_ddl (schema) (table-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
   -- Uncomment the following lines if you need them.
   --DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SEGMENT_ATTRIBUTES', false);
   --DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'STORAGE', false);
END;
/

SELECT DBMS_METADATA.get_ddl ('TABLE', table_name, owner)
FROM   all_tables
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of table_ddl.sql --

-- ########## Start of table_grants_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/table_grants_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for all grants on the specified table.
-- Call Syntax  : @table_grants_ddl (schema) (table_name)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT dbms_metadata.get_dependent_ddl('OBJECT_GRANT', UPPER('&2'), UPPER('&1')) from dual;

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of table_grants_ddl.sql --

-- ########## Start of table_indexes_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/table_indexes_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the index DDL for specified table, or all tables.
-- Call Syntax  : @table_indexes_ddl (schema-name) (table-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
   -- Uncomment the following lines if you need them.
   --DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SEGMENT_ATTRIBUTES', false);
   --DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'STORAGE', false);
END;
/

SELECT DBMS_METADATA.get_ddl ('INDEX', index_name, owner)
FROM   all_indexes
WHERE  owner      = UPPER('&1')
AND    table_name = DECODE(UPPER('&2'), 'ALL', table_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of table_indexes_ddl.sql --

-- ########## Start of table_triggers_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/table_triggers_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for all triggers on the specified table.
-- Call Syntax  : @table_triggers_ddl (schema) (table_name)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('TRIGGER', trigger_name, owner)
FROM   all_triggers
WHERE  table_owner = UPPER('&1')
AND    table_name  = UPPER('&2');

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of table_triggers_ddl.sql --

-- ########## Start of tablespace_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/tablespace_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified tablespace, or all tablespaces.
-- Call Syntax  : @tablespace_ddl (tablespace-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('TABLESPACE', tablespace_name)
FROM   dba_tablespaces
WHERE  tablespace_name = DECODE(UPPER('&1'), 'ALL', tablespace_name, UPPER('&1'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of tablespace_ddl.sql --

-- ########## Start of tablespace_structure.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/tablespace_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified tablespace, or all tablespaces.
-- Call Syntax  : @tablespace_ddl (tablespace-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('TABLESPACE', tablespace_name)
FROM   dba_tablespaces
WHERE  tablespace_name = DECODE(UPPER('&1'), 'ALL', tablespace_name, UPPER('&1'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of tablespace_structure.sql --

-- ########## Start of trigger_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/trigger_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for specified trigger, or all trigger.
-- Call Syntax  : @trigger_ddl (schema) (trigger-name or all)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('TRIGGER', trigger_name, owner)
FROM   all_triggers
WHERE  owner        = UPPER('&1')
AND    trigger_name = DECODE(UPPER('&2'), 'ALL', trigger_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of trigger_ddl.sql --

-- ########## Start of user_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/user_ddl.sql
-- Author       : Tim Hall
-- Description  : Displays the DDL for a specific user.
-- Call Syntax  : @user_ddl (username)
-- Last Modified: 07/08/2018
-- -----------------------------------------------------------------------------------

set long 20000 longchunksize 20000 pagesize 0 linesize 1000 feedback off verify off trimspool on
column ddl format a1000

begin
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'SQLTERMINATOR', true);
   dbms_metadata.set_transform_param (dbms_metadata.session_transform, 'PRETTY', true);
end;
/
 
variable v_username VARCHAR2(30);

exec :v_username := upper('&1');

select dbms_metadata.get_ddl('USER', u.username) AS ddl
from   dba_users u
where  u.username = :v_username
union all
select dbms_metadata.get_granted_ddl('TABLESPACE_QUOTA', tq.username) AS ddl
from   dba_ts_quotas tq
where  tq.username = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('ROLE_GRANT', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('SYSTEM_GRANT', sp.grantee) AS ddl
from   dba_sys_privs sp
where  sp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('OBJECT_GRANT', tp.grantee) AS ddl
from   dba_tab_privs tp
where  tp.grantee = :v_username
and    rownum = 1
union all
select dbms_metadata.get_granted_ddl('DEFAULT_ROLE', rp.grantee) AS ddl
from   dba_role_privs rp
where  rp.grantee = :v_username
and    rp.default_role = 'YES'
and    rownum = 1
union all
select to_clob('/* Start profile creation script in case they are missing') AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
and    rownum = 1
union all
select dbms_metadata.get_ddl('PROFILE', u.profile) AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
union all
select to_clob('End profile creation script */') AS ddl
from   dba_users u
where  u.username = :v_username
and    u.profile <> 'DEFAULT'
and    rownum = 1
/

set linesize 80 pagesize 14 feedback on trimspool on verify on

-- End of user_ddl.sql --

-- ########## Start of view_ddl.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/script_creation/view_ddl.sql
-- Author       : Tim Hall
-- Description  : Creates the DDL for the specified view.
-- Call Syntax  : @view_ddl (schema-name) (view-name)
-- Last Modified: 16/03/2013 - Rewritten to use DBMS_METADATA
-- -----------------------------------------------------------------------------------
SET LONG 20000 LONGCHUNKSIZE 20000 PAGESIZE 0 LINESIZE 1000 FEEDBACK OFF VERIFY OFF TRIMSPOOL ON

BEGIN
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'SQLTERMINATOR', true);
   DBMS_METADATA.set_transform_param (DBMS_METADATA.session_transform, 'PRETTY', true);
END;
/

SELECT DBMS_METADATA.get_ddl ('VIEW', view_name, owner)
FROM   all_views
WHERE  owner      = UPPER('&1')
AND    view_name = DECODE(UPPER('&2'), 'ALL', view_name, UPPER('&2'));

SET PAGESIZE 14 LINESIZE 100 FEEDBACK ON VERIFY ON
-- End of view_ddl.sql --

-- ########## Start of grant_delete.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/grant_delete.sql
-- Author       : Tim Hall
-- Description  : Grants delete on current schemas tables to the specified user/role.
-- Call Syntax  : @grant_delete (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'GRANT DELETE ON "' || u.table_name || '" TO &1;'
FROM   user_tables u
WHERE  NOT EXISTS (SELECT '1'
                   FROM   all_tab_privs a
                   WHERE  a.grantee    = UPPER('&1')
                   AND    a.privilege  = 'DELETE'
                   AND    a.table_name = u.table_name);

SPOOL OFF

@temp.sql

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of grant_delete.sql --

-- ########## Start of grant_execute.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/grant_execute.sql
-- Author       : Tim Hall
-- Description  : Grants execute on current schemas code objects to the specified user/role.
-- Call Syntax  : @grant_execute (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'GRANT EXECUTE ON "' || u.object_name || '" TO &1;'
FROM   user_objects u
WHERE  u.object_type IN ('PACKAGE','PROCEDURE','FUNCTION')
AND    NOT EXISTS (SELECT '1'
                   FROM   all_tab_privs a
                   WHERE  a.grantee    = UPPER('&1')
                   AND    a.privilege  = 'EXECUTE'
                   AND    a.table_name = u.object_name);

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of grant_execute.sql --

-- ########## Start of grant_insert.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/grant_insert.sql
-- Author       : Tim Hall
-- Description  : Grants insert on current schemas tables to the specified user/role.
-- Call Syntax  : @grant_insert (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'GRANT INSERT ON "' || u.table_name || '" TO &1;'
FROM   user_tables u
WHERE  NOT EXISTS (SELECT '1'
                   FROM   all_tab_privs a
                   WHERE  a.grantee    = UPPER('&1')
                   AND    a.privilege  = 'INSERT'
                   AND    a.table_name = u.table_name);

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of grant_insert.sql --

-- ########## Start of grant_select.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/grant_select.sql
-- Author       : Tim Hall
-- Description  : Grants select on current schemas tables, views & sequences to the specified user/role.
-- Call Syntax  : @grant_select (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'GRANT SELECT ON "' || u.object_name || '" TO &1;'
FROM   user_objects u
WHERE  u.object_type IN ('TABLE','VIEW','SEQUENCE')
AND    NOT EXISTS (SELECT '1'
                   FROM   all_tab_privs a
                   WHERE  a.grantee    = UPPER('&1')
                   AND    a.privilege  = 'SELECT'
                   AND    a.table_name = u.object_name);

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of grant_select.sql --

-- ########## Start of grant_update.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/grant_update.sql
-- Author       : Tim Hall
-- Description  : Grants update on current schemas tables to the specified user/role.
-- Call Syntax  : @grant_update (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'GRANT UPDATE ON "' || u.table_name || '" TO &1;'
FROM   user_tables u
WHERE  NOT EXISTS (SELECT '1'
                   FROM   all_tab_privs a
                   WHERE  a.grantee    = UPPER('&1')
                   AND    a.privilege  = 'UPDATE'
                   AND    a.table_name = u.table_name);

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of grant_update.sql --

-- ########## Start of package_synonyms.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/package_synonyms.sql
-- Author       : Tim Hall
-- Description  : Creates synonyms in the current schema for all code objects in the specified schema.
-- Call Syntax  : @package_synonyms (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'CREATE SYNONYM "' || a.object_name || '" FOR "' || a.owner || '"."' || a.object_name || '";'
FROM   all_objects a
WHERE  a.object_type IN ('PACKAGE','PROCEDURE','FUNCTION')
AND    a.owner = UPPER('&1')
AND    NOT EXISTS (SELECT '1'
                   FROM   user_synonyms u
                   WHERE  u.synonym_name = a.object_name
                   AND    u.table_owner  = UPPER('&1'));


SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of package_synonyms.sql --

-- ########## Start of schema_write_access.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/schema_write_access.sql
-- Author       : Tim Hall
-- Description  : Displays the users with write access to a specified schema.
-- Requirements : Access to the DBA views.
-- Call Syntax  : @schema_write_access.sql (schema-name)
-- Last Modified: 05-MAY-2012
-- -----------------------------------------------------------------------------------

set verify off

-- Direct grants
select distinct grantee
from   dba_tab_privs
where  privilege in ('INSERT', 'UPDATE', 'DELETE')
and    owner = upper('&1')
union
-- Grants via a role
select distinct grantee
from   dba_role_privs
       join dba_users on grantee = username
where  granted_role IN (select distinct role
                        from   role_tab_privs
                        where  privilege in ('INSERT', 'UPDATE', 'DELETE')
                        and    owner = upper('&1')
                        union
                        select distinct role
                        from   role_sys_privs
                        where  privilege in ('INSERT ANY TABLE', 'UPDATE ANY TABLE', 'DELETE ANY TABLE'))
union
-- Access via ANY sys privileges
select distinct grantee
from   dba_sys_privs
join   dba_users on grantee = username
where  privilege in ('INSERT ANY TABLE', 'UPDATE ANY TABLE', 'DELETE ANY TABLE');

-- End of schema_write_access.sql --

-- ########## Start of sequence_synonyms.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/sequence_synonyms.sql
-- Author       : Tim Hall
-- Description  : Creates synonyms in the current schema for all sequences in the specified schema.
-- Call Syntax  : @sequence_synonyms (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'CREATE SYNONYM "' || a.object_name || '" FOR "' || a.owner || '"."' || a.object_name || '";'
FROM   all_objects a
WHERE  a.object_type = 'SEQUENCE'
AND    a.owner       = UPPER('&1')
AND    NOT EXISTS (SELECT '1'
                   FROM   user_synonyms a1
                   WHERE  a1.synonym_name = a.object_name
                   AND    a1.table_owner  = UPPER('&1'));


SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of sequence_synonyms.sql --

-- ########## Start of table_synonyms.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/table_synonyms.sql
-- Author       : Tim Hall
-- Description  : Creates synonyms in the current schema for all tables in the specified schema.
-- Call Syntax  : @table_synonyms (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'CREATE SYNONYM "' || a.table_name || '" FOR "' || a.owner || '"."' || a.table_name || '";'
FROM   all_tables a
WHERE  NOT EXISTS (SELECT '1'
                   FROM   user_synonyms u
                   WHERE  u.synonym_name = a.table_name
                   AND    u.table_owner  = UPPER('&1'))
AND    a.owner = UPPER('&1');

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of table_synonyms.sql --

-- ########## Start of view_synonyms.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/view_synonyms.sql
-- Author       : Tim Hall
-- Description  : Creates synonyms in the current schema for all views in the specified schema.
-- Call Syntax  : @view_synonyms (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
SET PAGESIZE 0
SET FEEDBACK OFF
SET VERIFY OFF

SPOOL temp.sql

SELECT 'CREATE SYNONYM "' || a.view_name || '" FOR "' || a.owner || '"."' || a.view_name || '";'
FROM   all_views a
WHERE  a.owner = UPPER('&1')
AND    NOT EXISTS (SELECT '1'
                   FROM   user_synonyms u
                   WHERE  u.synonym_name = a.view_name
                   AND    u.table_owner  = UPPER('&1'));

SPOOL OFF

-- Comment out following line to prevent immediate run
@temp.sql

SET PAGESIZE 14
SET FEEDBACK ON
SET VERIFY ON

-- End of view_synonyms.sql --

-- ########## Start of dba_ords_client_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_client_roles.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS client roles.
-- Call Syntax  : @dba_ords_client_roles
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column client_name format a30
column role_name format a20

select client_id, client_name, role_id, role_name
from   dba_ords_client_roles
order by client_name, role_name;
-- End of dba_ords_client_roles.sql --

-- ########## Start of dba_ords_clients.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_clients.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS clients.
-- Call Syntax  : @dba_ords_clients
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a30
column client_secret format a30

select id, name, client_id, client_secret
from   dba_ords_clients
order by 1;
-- End of dba_ords_clients.sql --

-- ########## Start of dba_ords_handler_content.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_handler_content.sql
-- Author       : Tim Hall
-- Description  : Displays handler content.
-- Call Syntax  : @dba_ords_handler_content (handler-id)
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 200 lone 1000000 verify off pagesize 100
column source format a100

select h.method,
       h.source
from   dba_ords_handlers h
where  h.id = &1
order by h.method;
-- End of dba_ords_handler_content.sql --

-- ########## Start of dba_ords_handlers.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_handlers.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS enabled handlers.
-- Call Syntax  : @dba_ords_handlers
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 200
column parsing_schema format a20
column source_type format a20
column source format a50

select s.parsing_schema,
       m.name as module_name,
       t.uri_template,
       h.id as handler_id,
       h.source_type,
       h.method
from   dba_ords_handlers h
       join dba_ords_templates t on t.id = h.template_id
       join dba_ords_modules m on m.id = t.module_id
       join dba_ords_schemas s on s.id = m.schema_id
order by s.parsing_schema, m.name, t.uri_template;

-- End of dba_ords_handlers.sql --

-- ########## Start of dba_ords_modules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_modules.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS modules.
-- Call Syntax  : @dba_ords_modules
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column parsing_schema format a20
column module_name format a20
column uri_prefix format a20

select s.parsing_schema,
       m.id as module_id,
       m.name as module_name,
       m.uri_prefix,
       m.status
from   dba_ords_modules m
       join dba_ords_schemas s on s.id = schema_id
order by s.parsing_schema, m.name;

-- End of dba_ords_modules.sql --

-- ########## Start of dba_ords_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_objects.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS AutoRest objects.
-- Call Syntax  : @dba_ords_objects
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 150 

column parsing_schema format a20
column parsing_object format a30
column object_alias format a40

select parsing_schema,
       parsing_object,
       object_alias,
       type,
       status
from   dba_ords_enabled_objects
order by 1, 2;
-- End of dba_ords_objects.sql --

-- ########## Start of dba_ords_privilege_mappings.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_privilege_mappings.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privilege mappings.
-- Call Syntax  : @dba_ords_privilege_mappings
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column privilege_name format a60
column pattern format a60

select s.parsing_schema, p.name as privilege_name, p.pattern
from   dba_ords_privilege_mappings p
       join dba_ords_schemas s on s.id = p.schema_id
order by s.parsing_schema, p.name;
-- End of dba_ords_privilege_mappings.sql --

-- ########## Start of dba_ords_privilege_modules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_privilege_modules.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privilege and associated modules.
-- Call Syntax  : @dba_ords_privilege_modules
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a60
column pattern format a60

select s.parsing_schema, p.module_id, p.module_name, p.privilege_id, p.privilege_name
from   dba_ords_privilege_modules p
       join dba_ords_schemas s on s.id = p.schema_id
order by s.parsing_schema, p.module_name, p.privilege_name;
-- End of dba_ords_privilege_modules.sql --

-- ########## Start of dba_ords_privilege_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_privilege_roles.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privilege and role associations.
-- Call Syntax  : @dba_ords_privilege_roles
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column privilege_name format a60
column role_name format a60

select privilege_id, privilege_name, role_id, role_name
from   dba_ords_privilege_roles
order by privilege_name, role_name;
-- End of dba_ords_privilege_roles.sql --

-- ########## Start of dba_ords_privileges.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_privileges.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privileges.
-- Call Syntax  : @dba_ords_privileges
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a60
column description format a60

select id, name
from   dba_ords_privileges
order by 1;
-- End of dba_ords_privileges.sql --

-- ########## Start of dba_ords_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_roles.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS roles.
-- Call Syntax  : @dba_ords_roles
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a60

select id, name
from   dba_ords_roles
order by 1;
-- End of dba_ords_roles.sql --

-- ########## Start of dba_ords_schemas.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_schemas.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS enabled schemas.
-- Call Syntax  : @dba_ords_schemas
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 100
column parsing_schema format a20
column pattern format a30
column status format a10

select id,
       parsing_schema,
       pattern,
       status
from   dba_ords_schemas
order by parsing_schema;
-- End of dba_ords_schemas.sql --

-- ########## Start of dba_ords_templates.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_templates.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS templates.
-- Call Syntax  : @dba_ords_templates
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column parsing_schema format a20
column name format a20
column uri_template format a40

select s.parsing_schema,
       m.name as module_name,
       t.id as template_id,
       t.uri_template
from   dba_ords_templates t
       join dba_ords_modules m on m.id = t.module_id
       join dba_ords_schemas s on s.id = m.schema_id
order by s.parsing_schema, m.name, t.uri_template;
-- End of dba_ords_templates.sql --

-- ########## Start of dba_ords_views.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/dba_ords_views.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS DBA views.
-- Call Syntax  : @dba_ords_views
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column object_name format a30

select object_name
from   all_objects
where  object_name like 'DBA_ORDS%'
and    object_type = 'VIEW'
order by 1;
-- End of dba_ords_views.sql --

-- ########## Start of user_ords_client_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_client_roles.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS client roles.
-- Call Syntax  : @v_ords_client_roles
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column client_name format a30
column role_name format a20

select client_id, client_name, role_id, role_name
from   user_ords_client_roles
order by client_name, role_name;
-- End of user_ords_client_roles.sql --

-- ########## Start of user_ords_clients.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_clients.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS clients.
-- Call Syntax  : @user_ords_clients
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a30
column client_secret format a30

select id, name, client_id, client_secret
from   user_ords_clients
order by 1;
-- End of user_ords_clients.sql --

-- ########## Start of user_ords_handler_content.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_handler_content.sql
-- Author       : Tim Hall
-- Description  : Displays handler content.
-- Call Syntax  : @user_ords_handler_content (handler-id)
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 200 lone 1000000 verify off pagesize 100
column source format a100

select h.method,
       h.source
from   user_ords_handlers h
where  h.id = &1
order by h.method;
-- End of user_ords_handler_content.sql --

-- ########## Start of user_ords_handlers.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_handlers.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS enabled handlers.
-- Call Syntax  : @user_ords_handlers
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 200
column parsing_schema format a20
column source_type format a20
column source format a50

select s.parsing_schema,
       m.name as module_name,
       t.uri_template,
       h.id as handler_id,
       h.source_type,
       h.method
from   user_ords_handlers h
       join user_ords_templates t on t.id = h.template_id
       join user_ords_modules m on m.id = t.module_id
       join user_ords_schemas s on s.id = m.schema_id
order by s.parsing_schema, m.name, t.uri_template;
-- End of user_ords_handlers.sql --

-- ########## Start of user_ords_modules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_modules.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS modules.
-- Call Syntax  : @user_ords_modules
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column parsing_schema format a20
column module_name format a20
column uri_prefix format a20

select s.parsing_schema,
       m.id as module_id,
       m.name as module_name,
       m.uri_prefix,
       m.status
from   user_ords_modules m
       join user_ords_schemas s on s.id = schema_id
order by s.parsing_schema, m.name;
-- End of user_ords_modules.sql --

-- ########## Start of user_ords_objects.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_objects.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS AutoRest objects.
-- Call Syntax  : @user_ords_objects
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 150 

column parsing_schema format a20
column parsing_object format a30
column object_alias format a40

select parsing_schema,
       parsing_object,
       object_alias,
       type,
       status
from   user_ords_enabled_objects
order by 1, 2;
-- End of user_ords_objects.sql --

-- ########## Start of user_ords_privilege_mappings.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_privilege_mappings.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privilege mappings.
-- Call Syntax  : @user_ords_privilege_mappings
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column privilege_name format a60
column pattern format a60

select pm.name as privilege_name, pm.pattern
from   user_ords_privilege_mappings pm
order by pm.name, pm.pattern;

-- End of user_ords_privilege_mappings.sql --

-- ########## Start of user_ords_privilege_modules.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_privilege_modules.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privilege and associated modules.
-- Call Syntax  : @user_ords_privilege_modules
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a60
column pattern format a60

select s.parsing_schema, p.module_id, p.module_name, p.privilege_id, p.privilege_name
from   user_ords_privilege_modules p
       join user_ords_schemas s on s.id = p.schema_id
order by s.parsing_schema, p.module_name, p.privilege_name;
-- End of user_ords_privilege_modules.sql --

-- ########## Start of user_ords_privilege_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_privilege_roles.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privilege and role associations.
-- Call Syntax  : @dba_ords_privilege_roles
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column privilege_name format a60
column role_name format a60

select privilege_id, privilege_name, role_id, role_name
from   user_ords_privilege_roles
order by privilege_name, role_name;
-- End of user_ords_privilege_roles.sql --

-- ########## Start of user_ords_privileges.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_privileges.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS privileges.
-- Call Syntax  : @user_ords_privileges
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a60
column description format a60

select id, name
from   user_ords_privileges
order by 1;
-- End of user_ords_privileges.sql --

-- ########## Start of user_ords_roles.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_roles.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS roles.
-- Call Syntax  : @user_ords_roles
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column name format a60

select id, name
from   user_ords_roles
order by 1;
-- End of user_ords_roles.sql --

-- ########## Start of user_ords_schemas.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_schemas.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS enabled schemas.
-- Call Syntax  : @user_ords_schemas
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
set linesize 100
column parsing_schema format a20
column pattern format a30
column status format a10

select id,
       parsing_schema,
       pattern,
       status
from   user_ords_schemas
order by parsing_schema;
-- End of user_ords_schemas.sql --

-- ########## Start of user_ords_templates.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_templates.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS templates.
-- Call Syntax  : @user_ords_templates
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column parsing_schema format a20
column name format a20
column uri_template format a40

select s.parsing_schema,
       m.name as module_name,
       t.id as template_id,
       t.uri_template
from   user_ords_templates t
       join user_ords_modules m on m.id = t.module_id
       join user_ords_schemas s on s.id = m.schema_id
order by s.parsing_schema, m.name, t.uri_template;
-- End of user_ords_templates.sql --

-- ########## Start of user_ords_views.sql ##########--
-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/ords/user_ords_views.sql
-- Author       : Tim Hall
-- Description  : Displays all ORDS DBA views.
-- Call Syntax  : @user_ords_views
-- Last Modified: 23/06/2025
-- -----------------------------------------------------------------------------------
column object_name format a30

select object_name
from   all_objects
where  object_name like 'USER_ORDS%'
and    object_type = 'VIEW'
order by 1;
-- End of user_ords_views.sql --
