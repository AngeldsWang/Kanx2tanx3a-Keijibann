create table if not exists users (
  uid integer primary key autoincrement,
  email string not null,
  name string not null,
  password string not null
);