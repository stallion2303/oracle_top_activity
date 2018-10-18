#!/bin/bash

export ORACLE_SID=''
export ORACLE_HOME=''
export PATH=$ORACLE_HOME/bin:${PATH}
CONNECT=''
ORACLE_SID=''

read -r -d '' SQL<<INPUT_SQL
SELECT
'{'||
'"user_session_active":"' || USA || '",' ||
'"guser_session_active":"' || GUSA || '",' ||
'"active_session_history_cpu":"' || ASH_CPU || '",' ||
'"active_session_history_userio":"' || NVL(rtrim(to_char(wc_userio/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_systemio":"' || NVL(rtrim(to_char(wc_systemio/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_commit":"' || NVL(rtrim(to_char(wc_commit/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_concurrency":"' || NVL(rtrim(to_char(wc_concurrency/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_administrative":"' || NVL(rtrim(to_char(wc_administrative/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_application":"' || NVL(rtrim(to_char(wc_application/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_cluster":"' || NVL(rtrim(to_char(wc_cluster/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_configuration":"' || NVL(rtrim(to_char(wc_configuration/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_idle":"' || NVL(rtrim(to_char(wc_idle/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_network":"' || NVL(rtrim(to_char(wc_network/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_other":"' || NVL(rtrim(to_char(wc_other/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_queue":"' || NVL(rtrim(to_char(wc_queue/60,'FM999999999999990.99'),'.'),0) || '",' ||
'"active_session_history_scheduler":"' || NVL(rtrim(to_char(wc_scheduler/60,'FM999999999999990.99'),'.'),0) || '"' ||
'}'
FROM
(SELECT TO_CHAR(COUNT(1)-1) USA FROM v\$session WHERE username IS NOT NULL AND status='ACTIVE'),
(SELECT TO_CHAR(COUNT(1)-1) GUSA FROM gv\$session WHERE username IS NOT NULL AND status='ACTIVE'),
(SELECT NVL(rtrim(to_char(COUNT(1)/60,'FM999999999999990.99'),'.'),0) ASH_CPU FROM gv\$active_session_history WHERE TRUNC(sample_time+0,'MI')=TRUNC(systimestamp-1/1440,'MI') AND session_state='ON CPU'),
(
SELECT * FROM
(
SELECT wait_class FROM gv\$active_session_history WHERE TRUNC(sample_time+0,'MI')=TRUNC(systimestamp-1/1440,'MI')
)
PIVOT
(
COUNT(wait_class) FOR wait_class IN
('User I/O' AS wc_userio,
 'System I/O' AS wc_systemio,
 'Commit' AS wc_commit,
 'Concurrency' AS wc_concurrency,
 'Administrative' AS wc_administrative,
 'Application' AS wc_application,
 'Cluster' AS wc_cluster,
 'Configuration' AS wc_configuration,
 'Idle' AS wc_idle,
 'Network' AS wc_network,
 'Other' AS wc_other,
 'Queue' AS wc_queue,
 'Scheduler' AS wc_scheduler)
)
);
INPUT_SQL

RES=$(
$ORACLE_HOME/bin/sqlplus -s ${CONNECT}@${ORACLE_SID} <<EOF
set feedback off heading off
set line 1000
alter session set NLS_NUMERIC_CHARACTERS='.,';
$SQL
commit;
EOF
)

echo $RES
