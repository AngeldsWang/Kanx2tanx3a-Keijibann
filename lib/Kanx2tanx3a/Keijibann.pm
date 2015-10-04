package Kanx2tanx3a::Keijibann;
use Dancer2;
use Dancer2::Plugin::Captcha;
use DBI;
use File::Spec;
use File::Slurper qw/ read_text /;
use Template;
use Encode qw/ decode /;

set 'database' => File::Spec->catfile(File::Spec->updir(), 'harmonies.db');
#set 'session'  => 'Simple';

our $VERSION = '0.1';

my $flash;
my $is_valid_data;

sub set_flash {
	my $message = shift;
	$flash = $message;
}

sub get_flash {
	my $msg = $flash;
	$flash = "";
	return $msg;
}

sub get_offset {
	my $offset = int(rand(3)) + 1;
	return $offset;
}

sub get_noise_color {
	my @color_list = ('success_color', 'warning_color', 'danger_color', 'info_color', 'primary_color');
	my $idx = int(rand($#color_list + 1));
	return $color_list[$idx];
}

sub connect_db {
	my $dbh = DBI->connect("dbi:SQLite:dbname=".setting('database')) or
	die $DBI::errstr;
	return $dbh;
}

sub init_noises {
	my $db = connect_db();
	my $schema_noise = read_text('./schema/noise.sql');
	my $schema_user = read_text('./schema/user.sql');
	$db->do($schema_noise) or die $db->errstr;
	$db->do($schema_user) or die $db->errstr;
}

hook before_template => sub {
	my $tokens = shift;
	$tokens->{'signin_url'} = uri_for('/signin');
	$tokens->{'signup_url'} = uri_for('/signup');
};

get '/' => sub {
	my $db = connect_db();
	my $sql = 'select * from noises order by timestamp desc';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute or die $sth->errstr;
	template 'show_noises.tt', {
		'msg' => get_flash(),
		'mkanoise_url' => uri_for('/mkanoise'),
		'noises' => $sth->fetchall_hashref('nid'),
    'decode_fun' => \&decode,		# decode subroutine handler for encoded (Unicode) data in sqlite
    'get_color_fun' => \&get_noise_color,
    'get_offset_fun' => \&get_offset,
  };
};

any ['get', 'post'] => '/mkanoise' => sub {
	if ( not session('logged_in') ) {
		redirect '/signin';
	}
	if (request->method() eq "POST") {
		if (params->{'inputTitle'} eq "") {
			set_flash('Please input noise title!');
		}
		elsif (params->{'inputText'} eq "") {
			set_flash('Please input noise content!');
		}
		elsif (params->{'captchaText'} eq "") {
			set_flash('Please enter the captcha!');
		}
		elsif (not is_valid_captcha(params->{'captchaText'})) {
			set_flash('Incorrect captcha!');
			remove_captcha;
		} else {
			my $db = connect_db();
			my $sql = 'insert into noises (title, text, username, timestamp) values (?, ?, ?, ?)';
			my $sth = $db->prepare($sql) or die $db->errstr;
			my $timestamp = localtime;
			$sth->execute(params->{'inputTitle'}, params->{'inputText'}, session('cur_user'), $timestamp) or die $sth->errstr;
			set_flash('New noise posted!');
			redirect '/';
		}
		my $cur_user = session('cur_user');
		my $db = connect_db();
		my $sql = 'select * from noises where username = ? order by timestamp desc';
		my $sth = $db->prepare($sql) or die $db->errstr;
		$sth->execute(($cur_user)) or die $sth->errstr;
		template 'show_noises.tt', {
			'curr_title' => params->{'inputTitle'},
			'curr_text' => params->{'inputText'},
			'msg' => get_flash(),
			'mkanoise_url' => uri_for('/mkanoise'),
			'noises' => $sth->fetchall_hashref('nid'),
	    'decode_fun' => \&decode,		# decode subroutine handler for encoded (Unicode) data in sqlite
	    'get_color_fun' => \&get_noise_color,
	    'get_offset_fun' => \&get_offset,
		};
	}
};

get '/logout' => sub {
	app->destroy_session;
	redirect '/';
};

any ['get', 'post']  => '/signup' => sub  {
	my $err;
	if (request->method() eq "POST") {
		print params->{'inputEmail'} . "\n";
		if (params->{'inputEmail'} =~ /^\S+@\S+\.\S+$/) {	# validate the email address
			my $db = connect_db();
			my $sql = 'insert into users (email, name, password) values (?, ?, ?)';
			my $sth = $db->prepare($sql) or die $db->errstr;
			$sth->execute(params->{'inputEmail'}, params->{'inputUserName'}, params->{'inputPassword'}) or die $sth->errstr;
			set_flash('Sign up succeeded! Have a fun.');
			session 'logged_in' => true;
			session 'cur_user' => params->{'inputUserName'};
			redirect '/';
			} else {
				$err = 'Invalid email address.';
			}
		}

	# for get request just show the form
	template 'user_sign_up.tt', {
		'err' => $err,
	};
};

any ['get', 'post'] => '/signin' => sub  {
	my $err;
	if (request->method() eq "POST") {
		my @row;
		my $db = connect_db();
		my $sql = 'select name, password from users where name = ?';
		my $sth = $db->prepare($sql) or die $db->errstr;
		$sth->execute((params->{'inputUserName'})) or die $sth->errstr;

		while (@row = $sth->fetchrow_array) { # asume unique user name
			if ($row[1] == params->{'inputPassword'}) {
				session 'logged_in' => true;
				session 'cur_user' => params->{'inputUserName'};
				set_flash('Sign in successfully.');
				redirect '/';
				} else {
					$err = 'Invalid password.';
				}
		}
		my $rows = $sth->rows();
		if ($rows < 1) {	# Dose not exist the user
			$err = 'Invalid user name or password.';
		}
	}

	# for get request just show the form
	template 'user_sign_in.tt', {
		'err' => $err,
	};
};

get '/list' => sub {
	my $cur_user = session('cur_user');
	my @row;
	my $db = connect_db();
	my $sql = 'select * from noises where username = ?';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute(($cur_user)) or die $sth->errstr;

	template 'user_noise_list.tt', {
		'msg' => get_flash(),
		'mkanoise_url' => uri_for('/mkanoise'),
		'edit_url' => uri_for('/edit'),
		'delete_url' => uri_for('/delete'),
		'user_noise' => $sth->fetchall_hashref('nid'),
    'decode_fun' => \&decode,		# decode subroutine handler for encoded (Unicode) data in sqlite
    'get_color_fun' => \&get_noise_color,
    'get_offset_fun' => \&get_offset,
  };
};

post '/edit/:id' => sub {
	my $cur_user = session('cur_user');
	my @row;
	my $noise_id = params->{id};
	my $text_area = 'inputText' . "$noise_id";
	my $modified_text = params->{$text_area};
	my $db = connect_db();
	my $sql = 'update noises set text = ? where nid = ?';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute($modified_text, $noise_id) or die $sth->errstr;

	redirect '/list'; # return the cur_user's noises list
};

get '/delete/:id' => sub {
	my $cur_user = session('cur_user');
	my @row;
	my $noise_id = params->{id};
	print "$noise_id\n";
	my $db = connect_db();
	my $sql = 'delete from noises where nid = ?';
	my $sth = $db->prepare($sql) or die $db->errstr;
	$sth->execute(($noise_id)) or die $sth->errstr;		# delete noise by id

	redirect '/list';	# return the cur_user's noises list
};

# captcha
get '/get_captcha' => sub {
    return generate_captcha();
};
 
# post '/validate_captcha' => sub {
#     return "Invalid captcha code."
#         unless (is_valid_captcha(request->params->{captcha}));
 
#     remove_captcha;
# };

init_noises();

true;
