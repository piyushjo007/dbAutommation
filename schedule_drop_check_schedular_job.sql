ora_error_mail256 ('email-smtp.us-east-1.amazonaws.com',587,'S3_WALLET','piyushjoshi999@gmail.com','joshi2018piyush@gmail.com',5,'BOjAmI4ZQtiVSwSge9j8/bB+Up/EaFkql7dB+XiRflP2' ,'AKIARYJOZQLJ7HRONBYT' );


begin
    DBMS_SCHEDULER.CREATE_JOB (
         job_name             => 'scan_ora_error256',
         job_type             => 'PLSQL_BLOCK',
         job_action           => 'BEGIN ora_error_mail256 (''email-smtp.us-east-1.amazonaws.com'',587,''S3_WALLET'',''piyushjoshi999@gmail.com'',''joshi2018piyush@gmail.com'',5, ''BOjAmI4ZQtiVSwSge9j8/bB+Up/EaFkql7dB+XiRflP2'', ''AKIARYJOZQLJ7HRONBYT''); END;',
         start_date           => SYSTIMESTAMP,
         repeat_interval      => 'FREQ=MINUTELY;INTERVAL=5;',
         enabled              => TRUE);
end;
/


begin DBMS_SCHEDULER.drop_job (job_name => 'scan_ora_error22'); end;
/
begin DBMS_SCHEDULER.enable (name => 'scan_ora_error'); end;
/

col JOB_NAME for a20
col RUN_DURATION for a20
col SESSION_ID for a20
col ERRORS for a20
col OUTPUT for a20

select JOB_NAME,STATUS,RUN_DURATION,SESSION_ID,ERRORS,OUTPUT from dba_SCHEDULER_JOB_RUN_DETAILS where OWNER='ADMIN' and JOB_NAME=upper('scan_ora_error256');

col OWNER for a20
col JOB_ACTION for a20
select owner,job_name,JOB_TYPE,JOB_ACTION,NUMBER_OF_ARGUMENTS,enabled,state,RUN_COUNT,FAILURE_COUNT FROM dba_scheduler_jobs where owner='ADMIN';
