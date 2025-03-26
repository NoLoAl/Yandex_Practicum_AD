/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Смирнов Александр Викторович 
 * Дата: 26.12.2024
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
SELECT count(id) AS total_id, -- общее количество игроков, зарегистрированных в игре
	   sum(payer) AS payer_1, -- количество платящих игроков
	   round(avg(payer) * 100, 2) AS percentage_paying -- доля платящих игроков от общего количества пользователей, зарегистрированных в игре.
FROM fantasy.users u;
-- Общее количество игроков, зарегистрированных в игре 22214, из них платящих игроков 3929
-- Доля платящих игроков от общего количества пользователей 17,69%

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
SELECT race, -- раса персонажа
	   count(id) AS total_id, -- количество платящих игроков
	   sum(payer) AS payer_1, -- общее количество зарегистрированных игроков
	   round(avg(payer) * 100, 2) AS percentage_race -- доля платящих игроков от общего количества пользователей,
 FROM fantasy.users u                                -- зарегистрированных в игре в разрезе каждой расы персонажа.
	JOIN fantasy.race r using(race_id)
GROUP BY race
ORDER BY percentage_race DESC;                                                  
-- Топ три рвссы по между долей платящих игроков и расой персонажа Demon 19.37%. Hobbit 18.06%, Human 17.60%

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
WITH amount_not_null as(
SELECT *
FROM fantasy.events e 
WHERE amount > 0
)
SELECT count(transaction_id) AS total_pur, -- общее количество покупок
	   sum(amount) AS sum_amount, -- суммарную стоимость всех покупок
	   min(amount) AS min_amount, -- минимальная стоимость покупки
	   max(amount) AS max_amount, -- максимальная стоимость покупки
	   round(avg(amount)::NUMERIC , 2) AS avg_amount, -- среднее значение
	   PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount asc) AS median, -- медиана
	   round(STDDEV(amount)::NUMERIC, 2) AS stand_dev --  стандартное отклонение
FROM amount_not_null;
-- При проверке поля amount, было найдено 907 покупок с 0 стоимостью, они были исключены из расчетов. 
-- Всего было совершенно 1.306.771 покупок, на общуюю сумму 686.615.040.
-- Сумма максимальной покупки составила	486.615, а минимальной 0,01. Как по мне минимальная цена слишком маленькая.
-- Среднее значение 526.06, медиана	74.86,  стандартное отклонение	2518.20

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
SELECT count(transaction_id) AS total_buy, -- общее числа покупок
	   count(transaction_id) FILTER (WHERE amount = 0) AS amount_0, -- количество нулевых покупок
	   count(transaction_id) FILTER (WHERE amount = 0)
	   / count(transaction_id)::float AS zero_purchase -- доля нулевых покупок от общего числа покупок
FROM fantasy.events e;
-- При проверке поля amount, было найдено 907 покупок с 0 стоимостью.
 
SELECT id, game_items,
	   count(transaction_id) AS items_0
FROM fantasy.events e 
	JOIN fantasy.items i using(item_code)
WHERE amount = 0
GROUP BY id, game_items
ORDER BY items_0 DESC
LIMIT 5;
-- Все покупки с 0 ценой - это Book of Legends, есть игроки которые получили их несколько раз.
-- А игрок с id 12-1058351, получил Book of Legends бесплатно 810 раз.

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь
WITH total_purchase as( 
SELECT u.id, 
	   payer,
	   sum(amount) AS total_amount, --суммарная стоимость покупок на одного игрока
	   count(transaction_id) AS total_count --  количество покупок 
FROM fantasy.users u 
	LEFT JOIN fantasy.events e using(id)
WHERE amount > 0
GROUP BY u.id, payer
)
SELECT
	   CASE
			when payer = 1 THEN 'Платящий'
			ELSE 'Неплатящий'
	   END AS play,  -- группы игроков — платящие и неплатящие
	   count(id) AS total_play, -- количество игроков
	   round(avg(total_amount)::NUMERIC , 2) AS avg_play, -- средняя суммарная стоимость покупок на одного игрока
	   round(avg(total_count)::NUMERIC , 2) AS avg_tran --  среднее количество покупок 
FROM total_purchase
GROUP BY play;
-- Платящих игроков 2444, среднее количество покупок 81.68, средняя суммарная стоимость покупок на одного игрока 55467.74
-- Неплатящих игроков 11348, среднее количество покупок	97.56,средняя суммарная стоимость покупок на одного игрока 48631.74	
-- Хоть платящих игроков всего 17,69%, по стоимость покупок на одного игрока они тратят больше неплатящих
-- А среднее количество покупок	больше у неплатящих.

WITH total_purchase as( 
SELECT u.id, 
	   payer,
	   race_id,
	   sum(amount) AS total_amount, --суммарная стоимость покупок на одного игрока
	   count(transaction_id) AS total_count --  количество покупок 
FROM fantasy.users u 
	LEFT JOIN fantasy.events e using(id)
WHERE amount > 0
GROUP BY u.id, payer, race_id
)
SELECT race,
	   CASE
			when payer = 1 THEN 'Платящий'
			ELSE 'Неплатящий'
	   END AS play,  -- группы игроков — платящие и неплатящие
	   count(id) AS total_play, -- количество игроков
	   round(avg(total_amount)::NUMERIC , 2) AS avg_play, -- средняя суммарная стоимость покупок на одного игрока
	   round(avg(total_count)::NUMERIC , 2) AS avg_tran --  среднее количество покупок 
FROM total_purchase
	JOIN fantasy.race r using(race_id)
GROUP BY play, race;
-- Для большинства рас средние расходы платящих игроков выше, чем у неплатящих, но есть исключения:
-- Elf: У неплатящих средний расход составляет 81.16, а у платящих – 66.59. Это значит, что платящие эльфы тратят меньше, чем неплатящие.
-- Northman: У неплатящих средний расход составляет 88.43, а у платящих – 53.68. Платящие северяне тратят меньше, чем неплатящие.
	
-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь
WITH total_sell as(
SELECT game_items, -- название эпического предмета.
	   count(*) AS total_count, -- общий объем продаж по предметам
	   count(DISTINCT id) AS distinct_count, -- количество уникальных покупателей
	   (SELECT count( DISTINCT id)
	    FROM fantasy.events e) AS total_id -- все покупатели
FROM fantasy.events e 
	JOIN fantasy.items i using(item_code)
WHERE amount > 0
GROUP BY game_items
)
SELECT game_items, -- название эпического предмета.
	   total_count, -- общий объем продаж по предметам
	   round((total_count::float / sum(total_count) OVER() * 100)::NUMERIC, 2) AS relative_share, -- относительная доля продаж
	   distinct_count, -- количество уникальных покупателей
	   round((distinct_count ::float / total_id * 100)::NUMERIC, 2) AS buyer_share -- доля покупателей
FROM total_sell
ORDER BY buyer_share DESC
LIMIT 3;
-- Топ три самых популярных предмета Book of Legends 76.89%, Bag of Holding 20.79%, Necklace of Wisdom 1.06%, относительная доля продаж
-- Больше всего покупок Book of Legends	1.005.423, по сравнению Bag of Holding	271.875 и Necklace of Wisdom 13.828, большая разница
-- Доля игроков, которые купили конкретный предмет хотябы один раз Book of Legends 88,41%, Bag of Holding 86,77%, Necklace of Wisdom 11,8%
-- Равное  количество уникальных покупателей Book of Legends 12.195 и Bag of Holding 11.968,  Necklace of Wisdom 1627
-- Предметы которые не покупали нет, но есть 20 предметов купленных всего один раз.

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь
WITH payer_race as(
SELECT race, -- название расы.
	   count(u.id) AS total_id -- общее количество зарегистрированных игроков
FROM fantasy.users u 
	JOIN fantasy.race r using(race_id)
GROUP BY race
),
one_sum_count as(
SELECT race, -- название расы.
	   count(transaction_id) AS total_buy, -- количество покупок
	   sum(amount) total_sum, -- сумма покупок
	   count(DISTINCT id) AS num_buy, --  количество покупателей
	   count(DISTINCT id) FILTER (WHERE payer = 1) AS payer_1 -- платящих игроков
FROM fantasy.events e
	JOIN fantasy.users u USING(id)
	JOIN fantasy.race r using(race_id)
WHERE amount > 0
GROUP BY race
)
SELECT race, -- название расы.
	   total_id, -- общее количество зарегистрированных игроков
	   num_buy, --  количество покупателей
	   round((num_buy / total_id::float * 100)::NUMERIC , 2) AS num_buy_share, -- доля от общего количества
	   round((payer_1 / num_buy::float * 100)::NUMERIC , 2) AS payer_share, --  доля платящих игроков от количества игроков
	   total_buy / num_buy AS avg_buy_one, -- среднее количество покупок на одного игрока
	   round((total_sum / total_buy)::NUMERIC, 2) AS avg_sum, -- средняя стоимость одной покупки на одного игрока
	   round(((total_buy / num_buy) * (total_sum / total_buy))::NUMERIC, 2) AS avg_total_sum -- средняя суммарная стоимость всех покупок на одного игрока.
FROM payer_race
	JOIN one_sum_count using(race);
-- Demon: Высокая доля игроков, совершающих покупки, и высокие общие расходы указывают на возможную сложность игры за эту расу.
-- Elf и Northman: Несмотря на низкий процент игроков, делающих покупки, их средние расходы на покупки высоки, 
-- что также может свидетельствовать о необходимости приобретения дорогих предметов для успешного прохождения.
-- Human и Hobbit: Низкий процент игроков, совершающих покупки, и низкие общие расходы могут указывать на легкость прохождения игры за эти расы.
-- Чтобы устранить дисбаланс в игре, рекомендуется пересмотреть баланс игровых механик и предметов для рас Demon, Elf и Northman, возможно, 
-- упростив прохождение для них, а также усложнив прохождение для Human и Hobbit. В идеале начать изучение с статов расы.

-- Задача 2: Частота покупок
-- Напишите ваш запрос здесь
WITH id_date as(
SELECT id, --идентификатор игрока.
	   transaction_id, --идентификатор покупки
	   date, -- дата покупки.
	   lag(date) OVER (PARTITION BY id ORDER BY date) AS prev_date, -- количество дней между последовательными покупками 
	   amount, -- стоимость покупки во внутриигровой валюте «райские лепестки».
	   date::date - (lag(date) OVER (PARTITION BY id ORDER BY date))::date  AS days_between_purc
FROM fantasy.events e 
WHERE amount > 0
),
filter_date as(
SELECT id, --идентификатор игрока.
	   count(transaction_id) AS total_buy, -- общее количество покупок
	   round(avg(days_between_purc), 2) AS avg_days_between, --среднее значение по количеству дней между покупками
	   payer, --значение, которое указывает, является ли игрок платящим
	   NTILE(3) over(ORDER BY avg(days_between_purc), count(transaction_id)) AS group_rank -- ранжирование игроков	   
FROM id_date
	JOIN fantasy.users u using(id)
GROUP BY id, --идентификатор игрока.
	     payer -- значение, которое указывает, является ли игрок платящим
HAVING count(transaction_id) >= 25
)
SELECT CASE 
			when group_rank = 1 THEN 'высокая частота'
			when group_rank = 2 THEN 'умеренная частота'
			ELSE 'низкая частота'
	   END AS group_rank, -- ранжирование игроков
	   count(id) AS total_players, --количество игроков, которые совершили покупки;
	   sum(CASE 
	   			when payer = 1 THEN 1
	   			ELSE 0
	   	   END) AS paying_players, --количество платящих игроков, совершивших покупки
	   round((sum(CASE 
	   			when payer = 1 THEN 1
	   			ELSE 0
	   	   END)::float / count(id))::NUMERIC, 2)  AS paying_ratio,--доля от общего количества игроков, совершивших покупку
	   round(avg(total_buy), 2) AS avg_total_buy,--среднее количество покупок на одного игрока;
	   round(avg(avg_days_between), 2) AS avg_days_between_purchases --среднее количество дней между покупками на одного игрока.
FROM filter_date
GROUP BY group_rank;