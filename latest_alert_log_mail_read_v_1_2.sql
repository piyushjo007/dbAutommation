CREATE OR REPLACE PROCEDURE ora_error_mail256 (l_smtp_server IN varchar2,l_smtp_port IN number,l_wallet_dir IN varchar2,l_from IN varchar2,l_to IN varchar2,l_intrv IN number,l_password IN varchar2 ,l_user IN varchar2 )
AUTHID current_user AS
	cntr NUMBER := 0;
	c_body     VARCHAR2(2099);
	c_err     VARCHAR2(10);
	c_line VARCHAR2(57) := '---------------------------------------------------------';
	c_msg_lev     V$diag_alert_ext.MESSAGE_LEVEL%type;
	c_msgtext     V$diag_alert_ext.message_text%type;
	c_msgtyp VARCHAR2(20) := 'NORMAL';
	c_timestamp VARCHAR2(40);
	c_wlevel VARCHAR2(20) := 'NORMAL';
	l_conn utl_smtp.connection;
	l_dbname VARCHAR2(10);
	l_msg_typ     V$diag_alert_ext. MESSAGE_TYPE%type;
	l_replies utl_smtp.replies; 
	l_reply utl_smtp.reply;
	l_subject varchar2(128);
	l_wallet_path varchar2(4000);
	cursor C1 is select to_char(ORIGINATING_TIMESTAMP,'DD-MM-YY HH24:MI'), message_text,MESSAGE_TYPE,MESSAGE_LEVEL,REGEXP_SUBSTR(message_text,'ORA-+.....',1,1) from V$diag_alert_ext where 
	originating_timestamp > sysdate-l_intrv/1440 and  
	--MESSAGE_LEVEL !=16 and 
	MESSAGE_TEXT like '%ORA-%';


BEGIN
	select name into l_dbname from v$database;
    OPEN C1;
    LOOP
            FETCH C1 INTO c_timestamp,c_msgtext,l_msg_typ,c_msg_lev,c_err;
            EXIT WHEN C1%NOTFOUND;
            -- capturing message level
            
            IF c_msg_lev = 1 THEN
            	c_wlevel := 'CRITICAL !!';
            ELSIF c_msg_lev = 2 THEN
            	c_wlevel := 'SEVERE';
            ELSIF c_msg_lev = 8 THEN
            	c_wlevel := 'IMPORTANT';
            ELSE
            	c_wlevel := 'NORMAL';
            END IF;
            
            -- capturing message type   
                     
            IF l_msg_typ = 1 THEN
            	c_msgtyp := 'UNKNOWN';
            ELSIF l_msg_typ = 2 THEN
            	c_msgtyp := 'UNKNOWN';
            ELSIF l_msg_typ = 3 THEN
            	c_msgtyp := 'ERROR';
             ELSIF l_msg_typ = 4 THEN
            	c_msgtyp := 'WARNING';
             ELSIF l_msg_typ = 5 THEN
            	c_msgtyp := 'NOTIFICATION';
            ELSE
            	c_msgtyp := 'TRACE';
            END IF;
            
            l_subject := 'SEVERITY LEVEL: '||c_wlevel||' : DATABASE: '||l_dbname||' : '||c_err||' ERROR signalled during '||c_timestamp;
            DBMS_OUTPUT.PUT_LINE(l_subject);
            DBMS_OUTPUT.PUT_LINE('...............................................');
            --c_body := concat('ERROR Description  :',c_msgtext);
            c_body := 'MESSAGE TYPE: '||c_msgtyp||chr(10)||c_timestamp||chr(10)||c_line||chr(10)||' WARNING LEVEL =>  '||c_wlevel||chr(10)||c_line||chr(10)||c_msgtext;
            --c_body := concat('MESSAGE TYPE: ',c_msgtext);
            DBMS_OUTPUT.PUT_LINE(c_body);
            -- error captured next step to mailing
            
            select 'file:/' || directory_path into l_wallet_path from
			dba_directories where directory_name=l_wallet_dir;

			l_reply := utl_smtp.open_connection(
				host => l_smtp_server,
				port => l_smtp_port,
				c => l_conn,
				wallet_path => l_wallet_path,
				secure_connection_before_smtp => false
			);
			
			
			dbms_output.put_line('opened connection, received reply ' || l_reply.code || '/' || l_reply.text);


			l_replies := utl_smtp.ehlo(l_conn, 'localhost');
			for r in 1..l_replies.count loop
				dbms_output.put_line('ehlo (server config) : ' || l_replies(r).code || '/' || l_replies(r).text);
			end loop;


			l_reply := utl_smtp.starttls(l_conn);
			dbms_output.put_line('starttls, received reply ' || l_reply.code || '/' || l_reply.text);


			l_replies := utl_smtp.ehlo(l_conn, 'localhost');
			for r in 1..l_replies.count loop
				dbms_output.put_line('ehlo (server config) : ' || l_replies(r).code || '/' || l_replies(r).text);
			end loop;

			utl_smtp.auth(l_conn, l_user, l_password,utl_smtp.all_schemes);

			utl_smtp.mail(l_conn, l_from);
			utl_smtp.rcpt(l_conn, l_to);
			utl_smtp.open_data(l_conn);
			utl_smtp.write_data(l_conn, 'Date: ' || to_char(SYSDATE, 'DDMON-YYYYHH24:MI:SS') || utl_tcp.crlf);
			utl_smtp.write_data(l_conn, 'From: ' || l_from ||utl_tcp.crlf);
			utl_smtp.write_data(l_conn, 'To: ' || l_to || utl_tcp.crlf);
			utl_smtp.write_data(l_conn, 'Subject: ' || l_subject ||utl_tcp.crlf);
			utl_smtp.write_data(l_conn,'' || utl_tcp.crlf);
			utl_smtp.write_data(l_conn, c_body || utl_tcp.crlf);
            utl_smtp.close_data(l_conn);

    END LOOP ;
    l_reply := utl_smtp.quit(l_conn);
    
CLOSE C1;
END;
/
