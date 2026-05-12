create database miniprojectss15;
use miniprojectss15; 

create table users (
   user_id int primary key auto_increment,
   user_name varchar(50) unique not null,
   password	varchar(255) not null,
   email varchar(100) unique not null,
   created_at datetime default current_timestamp
);
create table posts (
   post_id int primary key auto_increment,
   user_id int not null,
   content text not null,
   like_count int default 0,
   comment_count int default 0,
   created_at datetime default current_timestamp
);
create table comments (
   comment_id int primary key auto_increment,
   post_id int not null,
   user_id int not null,
   content text not null,
   created_at datetime default current_timestamp,
   foreign key (post_id) references posts (post_id),
   foreign key (user_id) references users (user_id)
);
create table likes (
   like_id int primary key auto_increment,
   user_id int not null,
   post_id int not null,
   created_at datetime default current_timestamp,
   UNIQUE(user_id, post_id)
);
create table friends (
   friendship_id int primary key auto_increment,
   user_id int not null,
   friend_id int not null,
   status varchar(20) check (status in ('pending','accepted')),
   created_at datetime default current_timestamp,
   foreign key (user_id) references users (user_id),
   foreign key (friend_id) references users (user_id),
   UNIQUE ((LEAST(user_id, friend_id)), (GREATEST(user_id, friend_id))),
   CHECK (user_id != friend_id)
);
CREATE TABLE post_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT,
    post_content TEXT,
    deleted_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO users(user_name, password, email)
VALUES
('alice', '123456', 'alice@gmail.com'),
('bob', '123456', 'bob@gmail.com'),
('charlie', '123456', 'charlie@gmail.com');


INSERT INTO posts(user_id, content)
VALUES
(1, 'Hello everyone'),
(2, 'Learning MySQL'),
(3, 'Social network project');


INSERT INTO comments(post_id, user_id, content)
VALUES
(1, 2, 'Nice post'),
(1, 3, 'Very good');


INSERT INTO likes(user_id, post_id)
VALUES
(1, 2),
(2, 1),
(3, 1);

INSERT INTO friends(user_id, friend_id, status)
VALUES
(1, 2, 'accepted'),
(1, 3, 'pending');

-- Chức năng 1: 
create view view_user_info 
as select user_id,user_name,email,created_at 
from users;
-- Chức năng 2: 
delimiter // 
create procedure sp_add_user (
   in p_user_name varchar(50),
   in p_password varchar(255),
   in p_email varchar(100)
)
begin
   if p_user_name not in (select user_name
						  from users) and p_email not in (select email
						                                      from users) then 
   insert into users(user_name,password,email)
   values(p_user_name,p_password,p_email);
   else SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đã có dữ liệu bị trùng';
   end if;
end // 
delimiter ;
-- Chức năng 3: 
delimiter // 
create trigger tg_after_like_insert 
after insert on likes 
for each row
begin
   update posts
   set like_count = like_count + 1
   where post_id = new.post_id;
end // 
delimiter ;

delimiter // 
create trigger tg_after_comment_insert 
after insert on comments 
for each row
begin
   update posts
   set comment_count = comment_count + 1
   where post_id = new.post_id;
end // 
delimiter ;

delimiter // 
create trigger tg_after_like_delete 
after delete on likes 
for each row
begin
   update posts
   set like_count = like_count - 1
   where post_id = old.post_id and old.like_count > 0;
end // 
delimiter ;

delimiter // 
create trigger tg_after_comment_delete 
after delete on comments
for each row
begin
   update posts
   set comment_count = comment_count - 1
   where post_id = old.post_id and old.comment_count > 0;
end // 
delimiter ;
-- Chức năng 4: 
delimiter // 
create procedure sp_user_activity_report ()
begin
   select u.user_id,count(p.post_id) as count_post,sum(p.like_count) as total_like,sum(p.comment_count) as total_comment 
   from users u
   left join posts p 
   on u.user_id = p.user_id
   group by u.user_id;
end //
delimiter ; 
-- Chức năng 5 
delimiter // 
create procedure sp_delete_user (
   in p_user_id int
)

begin
DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Đã có dữ liệu bị trùng';
    END;
start transaction;
   delete from likes 
   where user_id = p_user_id;
   
   delete from comments
   where user_id = p_user_id;
   
   delete from friends
   where user_id = p_user_id;
   
   delete from posts
   where user_id = p_user_id;
   
   delete from users
   where user_id = p_user_id;
   commit;
end // 
delimiter ;
-- Chức năng 6: 
delimiter // 
create trigger tg_before_friend_insert 
before insert on friends 
for each row
begin
   if new.user_id = new.friend_id then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể tự kết bạn với chính mình';
   end if;
   if (select count(*)
       from friends
	   where user_id = new.user_id and friend_id = new.friend_id) > 0 then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Không thể kết bạn khi đã là bạn bè của nhau'; 
   end if; 
	if (select count(*)
       from friends
	   where user_id = new.friend_id and friend_id = new.user_id) > 0 then SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bạn không thể gửi lời mời kết bạn'; 
   end if; 
end // 
delimiter ; 
