--drop tables

drop table ps_friends;
drop table ps_activities;
drop table ps_purchases;
drop table ps_users;
drop table ps_countries;
drop table ps_genres;
drop table ps_games;
drop table ps_referrer_discounts;
drop table ps_aged_game_discounts;
--create tables

create table ps_games (
game_id number,
game_name varchar2(255),
game_developer varchar2(255),
game_score number,
game_price number,
game_publish_date date,
constraint ps_games_pk primary key (game_id)
);

create table ps_genres (
game_id number,
genre_name varchar2(255),
constraint ps_genres_pk primary key (game_id, genre_name)
);

create table ps_countries (
country_code varchar(2),
country_name varchar(255),
country_gmt_difference number,
constraint ps_countries_pk primary key (country_code)
);

create table ps_users (
user_id number,
user_username varchar2(255),
user_first_name varchar2(255),
user_last_name varchar2(255),
user_email varchar2(255),
country_code varchar2(2),
user_date_of_birth date,
user_referrer_id number,
user_total_actv_mins number,
constraint ps_users_pk primary key (user_id)
);

create table ps_friends (
friend1_id number,
friend2_id number,
constraint ps_friends_pk primary key (friend1_id, friend2_id)
);

create table ps_purchases (
purchase_id number,
user_id number,
game_id number,
purchase_date date,
constraint ps_purchases_pk primary key (purchase_id)
);

create table ps_activities (
purchase_id number,
actv_duration_mins number,
actv_datetime date
);

create table ps_referrer_discounts (
referrer_discount_start number,
referrer_discount_percent number,
constraint ps_referrer_discounts_pk primary key (referrer_discount_start)
);

create table ps_aged_game_discounts (
aged_game_discount_age number,
aged_game_discount_percent number,
constraint ps_aged_game_discounts_pk primary key (aged_game_discount_age)
);

--foreign key constraints

alter table ps_genres 
add constraint ps_genres_game_fk foreign key (game_id) references ps_games (game_id);

alter table ps_users 
add constraint ps_users_user_referrer_id_fk foreign key (user_referrer_id) references ps_users (user_id);

alter table ps_users 
add constraint ps_users_country_code_fk foreign key (country_code) references ps_countries (country_code);

alter table ps_friends 
add constraint ps_friends_friend1_id_fk foreign key (friend1_id) references ps_users (user_id);

alter table ps_friends 
add constraint ps_friends_friend2_id_fk foreign key (friend2_id) references ps_users (user_id);

alter table ps_purchases 
add constraint ps_purchases_user_id_fk foreign key (user_id) references ps_users (user_id);

alter table ps_purchases 
add constraint ps_purchases_game_id_fk foreign key (game_id) references ps_games (game_id);

alter table ps_activities 
add constraint ps_activities_purchase_id_fk foreign key (purchase_id) references ps_purchases (purchase_id);


