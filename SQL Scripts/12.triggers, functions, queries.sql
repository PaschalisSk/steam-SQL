--1.Create a function that returns the % discount of a user based on the
--amount of referrers he has.

CREATE OR REPLACE FUNCTION get_refferer_disc
(id ps_users.user_id%TYPE)
RETURN NUMBER
IS
	referrals NUMBER;
	discount NUMBER;
BEGIN
	SELECT COUNT(*)
	INTO referrals
	FROM ps_users
	WHERE user_referrer_id = id;
	
	SELECT referrer_discount_percent
	INTO discount
	FROM ps_referrer_discounts
	WHERE referrer_discount_start = (SELECT MAX(referrer_discount_start)
									 FROM ps_referrer_discounts
									 WHERE referrer_discount_start <= referrals);
	
	RETURN discount/100;
END;

SELECT get_refferer_disc(1)
from DUAL;

--2.Create a function that returns the % discount for a game based on the age of that game.

CREATE OR REPLACE FUNCTION get_aged_game_disc
(id ps_games.game_id%TYPE, date_of_interest DATE)
RETURN NUMBER
IS
	age NUMBER;
	discount NUMBER;
BEGIN
	SELECT (date_of_interest - game_publish_date)/365
	INTO age
	FROM ps_games
	WHERE game_id = id;
	
	SELECT aged_game_discount_percent
	INTO discount
	FROM ps_aged_game_discounts
	WHERE aged_game_discount_age = (SELECT MAX(aged_game_discount_age)
									 FROM ps_aged_game_discounts
									 WHERE aged_game_discount_age <= age);
	
	RETURN discount/100;
END;

SELECT get_aged_game_disc(730, SYSDATE)
FROM DUAL;

--3.All our times are stored in GMT+0 time. Create a function that returns the local time of a user.

CREATE OR REPLACE FUNCTION get_user_time
(id ps_users.user_id%TYPE, gmt_time DATE)
RETURN VARCHAR2
IS
	time_offset NUMBER;
	local_date DATE;
	local_time DATE;
BEGIN
	SELECT country_gmt_difference
	INTO time_offset
	FROM ps_countries
	WHERE country_code = (SELECT country_code
						  FROM ps_users
						  WHERE user_id = id);
	
	local_date := gmt_time + time_offset/24;
	
	RETURN TO_CHAR(local_date, 'HH24:MI:SS');
END;

--User with ID 1 is from Germany so GMT+1 we expect 05:27:00 and the result is correct.
SELECT get_user_time(1, TO_DATE('2016-02-03 04:27:00','YYYY-MM-DD HH24:MI:SS'))
FROM DUAL;

--4.Add a trigger to activities in order to update the total time a user has spent playing games.
CREATE OR REPLACE TRIGGER user_total_actv
AFTER INSERT ON ps_activities
FOR EACH ROW
DECLARE
	id ps_users.user_id%TYPE;
	current_total_actv NUMBER;
	actv_duration NUMBER;
	total_actv NUMBER;
BEGIN
	SELECT user_id
	INTO id
	FROM ps_purchases
	WHERE purchase_id = :NEW.purchase_id;
	
	actv_duration := :NEW.actv_duration_mins;
	
	SELECT user_total_actv_mins
	INTO current_total_actv
	FROM ps_users
	WHERE user_id = id;
	
	total_actv := current_total_actv + actv_duration;
	
	UPDATE ps_users
	SET user_total_actv_mins = total_actv
	WHERE user_id = id;
END;

--After uploading 7.insertActivities.sql
SELECT * FROM ps_users;

--5.The table ps_purchases has an auto-increment style primary key(purchase_id) but when we created
--the database we forgot to implement it and now we have the last PK being 580.
--Create a trigger so we don't have to manually enter a PK when we are inserting into ps_purchases.

CREATE SEQUENCE seq START WITH 581 INCREMENT BY 1 nomaxvalue;

CREATE TRIGGER purchases_pk_trigger
BEFORE INSERT ON ps_purchases
FOR EACH ROW
BEGIN
 SELECT seq.nextval INTO :NEW.purchase_id FROM dual;
END;

--Testing.
INSERT INTO ps_purchases(user_id, game_id, purchase_date) VALUES (1, 730, SYSDATE);

SELECT * FROM (
    SELECT * FROM ps_purchases ORDER BY purchase_id DESC
) WHERE ROWNUM = 1;

--6.Create a function that returns the price of a purchase then create a view
--of purchases with the price.
CREATE OR REPLACE FUNCTION get_purchase_price
(id ps_purchases.purchase_id%TYPE)
RETURN NUMBER
IS
	purchase_user_id NUMBER;
	purchase_game_id NUMBER;
	date_of_purchase DATE;
	user_discount NUMBER;
	game_discount NUMBER;
	initial_game_price NUMBER;
BEGIN
	SELECT user_id INTO purchase_user_id FROM ps_purchases WHERE purchase_id = id;
	SELECT game_id INTO purchase_game_id FROM ps_purchases WHERE purchase_id = id;
	SELECT purchase_date INTO date_of_purchase FROM ps_purchases WHERE purchase_id = id;
	
	user_discount := get_refferer_disc(purchase_user_id);
	game_discount := get_aged_game_disc(purchase_game_id, date_of_purchase);
	
	SELECT game_price INTO initial_game_price FROM ps_games WHERE game_id = purchase_game_id;
	
	RETURN initial_game_price*(user_discount+game_discount);
END;

CREATE VIEW purchases_with_price AS
SELECT p.*, get_purchase_price(p.purchase_id) "PRICE"
FROM ps_purchases p;

--7. Show the percentage distribution of the time of date that users start playing games(based on their local time)
--in order for the company to know at what time of day to improve the server capacity.
WITH total_actvs AS (SELECT COUNT(*) total_actvs FROM ps_activities)
SELECT SUBSTR(get_user_time(p.user_id, a.actv_datetime),0,2)||':00' "FROM", 
	  (TO_NUMBER(SUBSTR(get_user_time(p.user_id, a.actv_datetime),0,2))+1)||':00' "TO",
	  COUNT(*)*100/(SELECT total_actvs FROM total_actvs) || '%' "PERCENTAGE"
FROM ps_activities a
NATURAL JOIN ps_purchases p
GROUP BY SUBSTR(get_user_time(p.user_id, a.actv_datetime),0,2)
ORDER BY SUBSTR(get_user_time(p.user_id, a.actv_datetime),0,2);

--From the results we see that there is a normal distribution of the time of day
--the users are playing, so the company should have higher server capacity from 10:00 to 15:00