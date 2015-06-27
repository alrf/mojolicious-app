#!/usr/bin/perl -w
use Mojolicious::Lite;
use DBIx::Tree;
use DBI;

my $user = 'root';
my $password = '';
my $host = 'localhost';
my $db = 'test';
my $table = 'tree';

my $dbh = DBI->connect("dbi:mysql:$db:$host", $user, $password) or die "Couldn't connect to database: " . DBI->errstr;


helper create_table => sub {
  my $self = shift;
  warn "Creating table '$table'\n";
  $dbh->do("DROP TABLE IF EXISTS $table");
  $dbh->do("
    CREATE TABLE IF NOT EXISTS $table (
      `id` int(11) NOT NULL AUTO_INCREMENT, `parent_id` int(11) DEFAULT '0', PRIMARY KEY (`id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1;
  ");
  $dbh->do("ALTER TABLE $table ADD INDEX (parent_id)");
};

helper select => sub {
  my $self = shift;

  if (!$dbh->ping) { # processing error: "DBD::mysql::st execute failed: MySQL server has gone away"
    $dbh = $dbh->clone() or die "cannot connect to db";
  }

  use vars '%h';
  %h = ();
  sub disp_tree {
    my %parms = @_;
    my $item  = $parms{item};
    my $level = $parms{level};
    my $id    = $parms{id};
    my $lvl = $level - 1;
    # push data into the hash
    push @{ $h{$lvl} }, "[P:$item ID:$id]";
  }

  my $tree = new DBIx::Tree( connection => $dbh,
                          table      => $table,
                          method     => sub { disp_tree(@_) },
                          columns    => ['id', 'parent_id', 'parent_id'],
                          start_id   => '0');
  $tree->traverse;
  return 1;
};

helper insert => sub {
  my $self = shift;
  my ($pid) = @_;
  my $sth = eval { $dbh->prepare("INSERT INTO $table(`parent_id`) VALUES (?)") } || return undef;
  $sth->execute($pid);
  return 1;
};

# base route
any '/' => sub {
  my $self = shift;
  $self->select;
  $self->stash( hash => \%h );
  $self->render('index');
};

# route for insert data
any '/insert' => sub {
  my $self = shift;
  my $pid = $self->param('pid');
  my $insert = $self->insert($pid);
  $self->redirect_to('/');
};

# route for create table
any '/create' => sub {
  my $self = shift;
  $self->create_table;
  $self->redirect_to('/');
};

app->start;

__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head>
    <title><%= title %></title>
    <style>
      body, table, tr, td {
        font-family: Verdana;
        font-size: 12px;
      }
      #pid {
        width: 50px;
      }
	  /* Error message should be displayed immediately above "Add" button. */
      #pid-error {
        display: block;
      }
    </style>
    <link rel="stylesheet" href="//cdn.jsdelivr.net/99lime/0.94/css/kickstart.css">
  </head>
  <body><%= content %></body>
  <script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js"></script>
  <script src="//cdn.jsdelivr.net/jquery.validation/1.13.1/jquery.validate.min.js"></script>
  <script src="//cdn.jsdelivr.net/99lime/0.94/js/kickstart.js"></script>
  <script type="text/javascript">
    $(document).ready(function() {
	  $("#insert_form").validate({
        rules: {
          pid: {
            required: true,
            digits: true
          }
        }
      });
    });
  </script>
</html>


@@ index.html.ep
% layout 'default';
% title 'Table';
<p>Current Tree:</p>
<table class="sortable striped tight" cellspacing="0" cellpadding="0">
  <thead><tr><th>Depth</th><th>Tree Nodes</th></tr></thead><tbody>
% foreach my $key (sort { $a <=> $b} keys %{$hash}) {
  <tr><td><%= $key %></td><td><%= join(", ", @{ $hash->{$key} }) %></td></tr>
% }
</tbody></table>
<br/>
<form action="<%=url_for('insert')->to_abs%>" method="post" id="insert_form">
  Add Node To: <input type="text" name="pid" placeholder="PID" id="pid" autocomplete="off" autofocus> 
  <p><button type="submit" class="small green">Add</button></p>
</form>


@@ exception.development.html.ep
% title 'Table: Error';
Oops! Something wrong!


@@ exception.html.ep
% title 'Table: Error';
Oops! Something wrong!
