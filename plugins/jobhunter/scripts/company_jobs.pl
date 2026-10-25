#!/usr/bin/env perl
# JobHunter company career-page fetcher. Pulls open jobs straight from companies' public ATS
# endpoints (recorded once per company in <workspace>/profile/companies.yaml) and prints only the
# jobs whose title/location match the user's targets — so Claude never reads whole job boards.
#
# Usage:
#   perl company_jobs.pl [--title-re REGEX] [--loc-re REGEX] [--since DAYS] [--max-pages N]
#        --source "<ats>|<board-or-url>|<Company Name>[|<search terms>]" [--source ...]
#   ats: greenhouse | lever | ashby | smartrecruiters | workday | personio | recruitee | rss
#   board examples: greenhouse "airbnb"; lever "spotify"; ashby "openai"; smartrecruiters "BoschGroup" or "BoschGroup@de" (country);
#     workday "https://nvidia.wd5.myworkdayjobs.com/NVIDIAExternalCareerSite" (career-site URL);
#     personio "acme" or "acme.jobs.personio.com"; recruitee "bunq"; rss: full feed URL.
#   --search "term1,term2"  default keyword pre-filter for APIs that support it (workday, smartrecruiters);
#                           a 4th "|terms" field on a --source overrides it for that company
#
# Output (stdout) TSV, one job per line:  id  title  company  location  url  posted
#   ids are source-prefixed and stable (gh:, lv:, ab:, sr:, wd:<host>:, ps:<board>:, rc:, rss:)
# Summary per company on stderr: "<Company>: <n> open · <m> match" or "<Company>: ERROR <reason>".
# Exit code 0 even if some companies fail (they are reported), 2 on usage errors.
# Needs: perl 5.14+ (JSON::PP is core; ships with macOS) and curl. No other installs.
use strict; use warnings; use utf8;
use JSON::PP; use Getopt::Long; use Time::Local;
binmode STDOUT, ':encoding(UTF-8)'; binmode STDERR, ':encoding(UTF-8)';

my ($title_re, $loc_re, $since, $max_pages, $search) = ('', '', 0, 10, '');
my @sources;
GetOptions('title-re=s' => \$title_re, 'loc-re=s' => \$loc_re, 'since=i' => \$since,
           'max-pages=i' => \$max_pages, 'search=s' => \$search, 'source=s' => \@sources)
  or exit 2;
@sources or do { print STDERR "usage: see header of $0\n"; exit 2 };
our @terms = grep { length } map { s/^\s+|\s+$//gr } split /,/, $search;
my $json = JSON::PP->new->utf8->allow_nonref;
my $cutoff = $since ? time - $since * 86400 : 0;

sub http {   # returns decoded body or undef; uses curl (handles TLS/proxies like the user's system)
  my ($url, $post) = @_;
  my @cmd = ('curl', '-sL', '--compressed', '-m', '60', '-A', 'Mozilla/5.0 (JobHunter personal job search)');
  push @cmd, ('-X', 'POST', '-H', 'Content-Type: application/json', '-H', 'Accept: application/json', '-d', $post) if defined $post;
  push @cmd, ('-w', "\n%{http_code}", $url);
  open(my $fh, '-|', @cmd) or return undef;
  local $/; my $out = <$fh>; close $fh;
  return undef unless defined $out && $out =~ s/\n(\d{3})\z//;
  return $1 =~ /^2/ ? $out : undef;
}
sub getjson { my $b = http(@_); return undef unless defined $b; my $d = eval { $json->decode($b) }; return $d }
sub clean { my $s = shift // ''; $s =~ s/[\t\r\n]+/ /g; $s =~ s/\s{2,}/ /g; $s =~ s/^\s+|\s+$//g; return $s }
sub epoch {  # ISO date / epoch ms / RFC822 -> epoch seconds (0 if unknown)
  my $v = shift // ''; return int($v / 1000) if $v =~ /^\d{12,}$/; return $v if $v =~ /^\d{9,10}$/;
  return timegm(0, 0, 0, $3, $2 - 1, $1) if $v =~ /^(\d{4})-(\d{2})-(\d{2})/;
  my %m = (Jan=>0,Feb=>1,Mar=>2,Apr=>3,May=>4,Jun=>5,Jul=>6,Aug=>7,Sep=>8,Oct=>9,Nov=>10,Dec=>11);
  return timegm(0, 0, 0, $1, $m{$2}, $3) if $v =~ /(\d{1,2}) (\w{3}) (\d{4})/ && exists $m{$2};
  return 0;
}
sub ymd { my $e = shift; return '' unless $e; my @t = gmtime $e; sprintf '%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3] }

for my $src (@sources) {
  my ($ats, $board, $company, $own_search) = map { clean($_) } split /\|/, $src, 4;
  $company ||= $board;
  local @terms = (defined $own_search && length $own_search)
    ? (grep { length } map { s/^\s+|\s+$//gr } split /,/, $own_search) : @terms;
  my (@jobs, $err);
  eval {
    if ($ats eq 'greenhouse') {
      my $d = getjson("https://boards-api.greenhouse.io/v1/boards/$board/jobs") or die "no response\n";
      push @jobs, map { { id => "gh:$_->{id}", title => $_->{title}, loc => ($_->{location} || {})->{name},
                          url => $_->{absolute_url}, posted => $_->{first_published} || $_->{updated_at} } } @{ $d->{jobs} || [] };
    } elsif ($ats eq 'lever') {
      my $host = $board =~ /^eu:/ ? 'api.eu.lever.co' : 'api.lever.co'; (my $b = $board) =~ s/^eu://;
      my $d = getjson("https://$host/v0/postings/$b?mode=json") or die "no response\n";
      push @jobs, map { my $c = $_->{categories} || {};
                        { id => "lv:$_->{id}", title => $_->{text}, loc => $c->{location} || join(', ', @{ $c->{allLocations} || [] }),
                          url => $_->{hostedUrl}, posted => $_->{createdAt} } } @{ ref $d eq 'ARRAY' ? $d : [] };
    } elsif ($ats eq 'ashby') {
      my $d = getjson("https://api.ashbyhq.com/posting-api/job-board/$board") or die "no response\n";
      push @jobs, map { { id => "ab:$_->{id}", title => $_->{title},
                          loc => join(', ', grep { defined && length } $_->{location}, ($_->{isRemote} ? 'Remote' : ())),
                          url => $_->{jobUrl}, posted => $_->{publishedAt} } } grep { !defined $_->{isListed} || $_->{isListed} } @{ $d->{jobs} || [] };
    } elsif ($ats eq 'smartrecruiters') {
      my ($sb, $cc) = split /@/, $board, 2;
      for my $q (@terms ? @terms : ('')) {
        for (my $off = 0, my $p = 0; $p < $max_pages; $p++, $off += 100) {
          my $u = "https://api.smartrecruiters.com/v1/companies/$sb/postings?limit=100&offset=$off" . (length $q ? "&q=" . uri($q) : '') . ($cc ? "&country=$cc" : '');
          my $d = getjson($u) or die "no response\n";
          my $c = $d->{content} || [];
          push @jobs, map { my $l = $_->{location} || {};
                            { id => "sr:$_->{id}", title => $_->{name}, loc => join(', ', grep { defined && length } $l->{city}, $l->{country}, ($l->{remote} ? 'Remote' : ())),
                              url => "https://jobs.smartrecruiters.com/$sb/$_->{id}", posted => $_->{releasedDate} } } @$c;
          last if @$c < 100;
        }
      }
    } elsif ($ats eq 'workday') {
      my ($host, $site) = $board =~ m{^https?://([^/]+)/(?:[a-z]{2}-[A-Z]{2}/)?([^/?#]+)} or die "workday board must be the career-site URL\n";
      my ($tenant) = $host =~ /^([^.]+)\./;
      for my $q (@terms ? @terms : ('')) {
        for (my $off = 0, my $p = 0; $p < $max_pages; $p++, $off += 20) {
          my $d = getjson("https://$host/wday/cxs/$tenant/$site/jobs", $json->encode({ limit => 20, offset => $off, searchText => $q, appliedFacets => {} })) or die "no response\n";
          my $c = $d->{jobPostings} || [];
          for (@$c) { my ($rid) = ($_->{externalPath} // '') =~ /_([A-Za-z0-9-]+)$/;
            push @jobs, { id => "wd:$tenant:" . ($rid // $_->{externalPath}), title => $_->{title}, loc => $_->{locationsText},
                          url => "https://$host/$site$_->{externalPath}", posted => '' } }   # postedOn is relative text ("Posted 3 Days Ago")
          last if @$c < 20;
        }
      }
    } elsif ($ats eq 'personio') {
      my $host = $board =~ /\./ ? $board : "$board.jobs.personio.de";
      my $x = http("https://$host/xml?language=en") // http("https://$host/xml") // die "no response\n";
      utf8::decode($x);
      while ($x =~ m{<position>(.*?)</position>}gs) {
        my $p = $1; my %f; $f{$1} = $2 while $p =~ m{<(id|name|office|createdAt)>(.*?)</\1>}gs;
        for (values %f) { s/&amp;/&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g; s/&#39;/'/g }
        push @jobs, { id => "ps:$board:$f{id}", title => $f{name}, loc => $f{office}, url => "https://$host/job/$f{id}", posted => $f{createdAt} };
      }
    } elsif ($ats eq 'recruitee') {
      my $d = getjson("https://$board.recruitee.com/api/offers/") or die "no response\n";
      push @jobs, map { { id => "rc:$_->{id}", title => $_->{title}, loc => $_->{location} || join(', ', grep { defined && length } $_->{city}, $_->{country}),
                          url => $_->{careers_url}, posted => $_->{published_at} } } @{ $d->{offers} || [] };
    } elsif ($ats eq 'rss') {
      my $x = http($board) // die "no response\n"; utf8::decode($x);
      while ($x =~ m{<item\b[^>]*>(.*?)</item>}gs) {
        my $i = $1; my %f; $f{$1} = $2 while $i =~ m{<(title|link|guid|pubDate)\b[^>]*>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</\1>}gs;
        my $id = $f{guid} || $f{link} || $f{title}; $id =~ s{^https?://}{};
        push @jobs, { id => "rss:$id", title => $f{title}, loc => '', url => $f{link}, posted => $f{pubDate} };
      }
    } else { die "unknown ats '$ats'\n" }
    1;
  } or do { $err = clean($@) || 'failed' };
  if ($err) { print STDERR "$company: ERROR $err\n"; next }

  my (%dup, $match);
  for my $j (@jobs) {
    next if !defined $j->{id} || $dup{ $j->{id} }++;
    my ($t, $l) = (clean($j->{title}), clean($j->{loc}));
    next if length $title_re && $t !~ /$title_re/i;
    next if length $loc_re && length $l && $l !~ /$loc_re/i;   # unknown location -> keep (evaluator decides)
    my $e = epoch($j->{posted});
    next if $cutoff && $e && $e < $cutoff;
    $match++;
    print join("\t", $j->{id}, $t, clean($company), $l, clean($j->{url}), ymd($e)), "\n";
  }
  printf STDERR "%s: %d open · %d match\n", $company, scalar(keys %dup), $match // 0;
}
sub uri { my $s = shift; utf8::encode($s); $s =~ s/([^A-Za-z0-9\-._~])/sprintf '%%%02X', ord $1/ge; $s }
