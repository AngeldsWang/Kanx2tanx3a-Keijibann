create table if not exists noises (
  nid integer primary key autoincrement,
  title string not null,
  text string not null,
  username string not null,
  timestamp string not null
);