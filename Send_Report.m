setpref('Internet','E_mail',mail);
setpref('Internet','SMTP_Server','smtp.naver.com');
% setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',mail);
setpref('Internet','SMTP_Password',password);
props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', 'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

% To. Title. Body. File
sendmail(To_mail,mail_title,mail_body,mail_file);
