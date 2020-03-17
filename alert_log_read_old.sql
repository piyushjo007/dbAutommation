CREATE OR REPLACE PROCEDURE ora_error_mail23 (l_smtp_server IN varchar2,l_smtp_port IN number,l_wallet_dir IN varchar2,l_from IN varchar2,l_to IN varchar2,l_intrv IN number)
AUTHID current_user AS
	cntr NUMBER := 0;
	l_dbname VARCHAR2(10);
	c_msgtext     V$diag_alert_ext.message_text%type;
	c_timestamp VARCHAR2(40);
	c_msg_typ     V$diag_alert_ext. MESSAGE_TYPE%type;
	c_msg_lev     V$diag_alert_ext.MESSAGE_LEVEL%type;
	c_err     VARCHAR2(10);
	l_subject varchar2(128);
	c_body     VARCHAR2(2099);
	c_line VARCHAR2(57) := '---------------------------------------------------------';
	l_user varchar2(128) := 'AKIARYJOZQLJ7HRONBYT'; 
	l_password varchar2(128) := 'BOjAmI4ZQtiVSwSge9j8/bB+Up/EaFkql7dB+XiRflP2' ;
	l_wallet_path varchar2(4000);
	l_conn utl_smtp.connection;
	l_reply utl_smtp.reply;
	l_replies utl_smtp.replies; 
	  
	cursor C1 is select to_char(originating_timestamp,'DD-MM-YY HH24:MI'), message_text,MESSAGE_TYPE,MESSAGE_LEVEL,REGEXP_SUBSTR(message_text,'ORA-+.....',1,1) from V$diag_alert_ext where 
	originating_timestamp > sysdate-l_intrv/1440 and  
	--MESSAGE_LEVEL !=16 and 
	MESSAGE_TEXT like '%ORA-%';


BEGIN
	select name into l_dbname from v$database;
    OPEN C1;
    LOOP
            FETCH C1 INTO c_timestamp,c_msgtext,c_msg_typ,c_msg_lev,c_err;
            EXIT WHEN C1%NOTFOUND;
            l_subject := 'DATABASE : '||l_dbname||' : '||c_err||' ERROR signalled during '||c_timestamp;
            DBMS_OUTPUT.PUT_LINE(l_subject);
            DBMS_OUTPUT.PUT_LINE('...............................................');
            c_body := concat('ERROR Description  :',c_msgtext);
            c_body := c_body|| c_timestamp||chr(10)||c_line||chr(10)||' With warning level => '||to_char(c_msg_lev)||chr(10)||c_line;
            DBMS_OUTPUT.PUT_LINE(c_body);
            DBMS_OUTPUT.PUT_LINE(c_line);
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
