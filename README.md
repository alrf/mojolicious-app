This web based application allows the user to view an existing, initially empty, tree and add nodes to it.  
Tree nodes stored in the MySQL database. Program able to read them from the database to display the tree, 
and add new nodes to the tree upon user request. Each node identified by a unique node ID and have a parent P.  

This application uses the Mojolicious framework (Perl based) and DBIx::Tree module for build the tree.  
On deployment machine should be: Perl, Mojolicious::Lite, DBI, DBIx::Tree.  
Also Mojolicious have the internal web-server. This makes easy to start the application (for test and development).  

Deployment instructions:  
1) Install Mojolicious and modules:  
`# cpanm Mojolicious::Lite`  
`# cpanm DBI`  
`# cpanm DBIx::Tree`  
2) Upload file index.pl on the deployment machine, change the DB connect settings ($user, $password, $host, $db, $table in the index.pl file) and run application:  
`# ./index.pl daemon`  
3) Open the link in browser: `http://<your_server_ip>:3000/create`  
It is creating table in the DB and performing redirect to "/".  

You can use the application: `http://<your_server_ip>:3000`  

==========
Some explanations for deployment on CentOS: `yum install mc cpan gcc perl-App-cpanminus.noarch perl-DBI perl-DBD-MySQL mariadb-server`
