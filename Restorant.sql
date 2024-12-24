select * from menu_items
select * from order_details

--===Display the first 5 rows from the order_details table.
select top 5 * from order_details

--===Filtering and Sorting:
--Select the item_name and price columns for items in the 'Main Course' category.
--Sort the result by price in descending order
select item_name,price from menu_items
where item_name like '%Burger%' or item_name like '%steak%' or item_name like '%chicken%'
order by price desc

--===Aggregate Functions:
--Calculate the average price of menu items.
select AVG(price) as AVG_Price from menu_items

--Find the total number of orders placed.
select count(distinct(order_id)) as Total_Orders
from order_details

--===Joins:
--Retrieve the item_name, order_date, and order_time for all items in the order_details table, including their respective menu item details.
select item_name,order_date,order_time
from order_details 
join menu_items on order_details.item_id =menu_items.menu_item_id

--===Subqueries:
--List the menu items (item_name) with a price greater than the average price of all menu items.
select item_name, price from menu_items
where price>(select avg(price) from menu_items)

--===Date and Time Functions:
--Extract the month from the order_date and count the number of orders placed in each month.
select MONTH(order_date) as Order_Month , COUNT(*)as Total_Orders
from order_details
group by MONTH(order_date)
order by Order_Month

--===Group By and Having:
--Show the categories with the average price greater than $15.
--Include the count of items in each category.
select category ,AVG(price) as avg_item_count,count(*) as item_count
from menu_items
group by category
having AVG(price)>15 

--===Conditional Statements:
--Display the item_name and price, and indicate if the item is priced above $20 with a new column named 'Expensive'.
select item_name,price,
      case 
	     when price>20 then 'Yes'
		 else 'No'
	 end as exppensive 
from menu_items
--===Data Modification - Update:
--Update the price of the menu item with item_id = 101 to $25
update menu_items
set price = 25
where menu_item_id =101

--===Data Modification - Insert:
--Insert a new record into the menu_items table for a dessert item.
insert into menu_items(menu_item_id,item_name,category,price)
values (106,'chocolate cake' ,'dessert',8.5)

--===Data Modification - Delete:
--Delete all records from the order_details table where the order_id is less than 100.
delete from order_details
where order_id<100

--===Window Functions - Rank:
--Rank menu items based on their prices, displaying the item_name and its rank
select item_name,price,RANK() over(order by price desc) as Price_Rank 
from menu_items

--===Window Functions - Lag and Lead:
--Display the item_name and the price difference from the previous and next menu item.
select item_name,price,
       lag(price,1) over (order by price) as previous_price,
	   lead(price,1) over (order by price) as next_price,
	   price - lag(price,1) over (order by price) as price_diff_previous,
	   lead(price,1) over (order by price) - price as price_diff_next
from menu_items
--===Common Table Expressions (CTE):
--Create a CTE that lists menu items with prices above $15.
--Use the CTE to retrieve the count of such items.
with ExpensiveItems as (
   select item_name,price
   from menu_items
   where price>15
)
select count(*) as Expensive_Item_Count
from ExpensiveItems

--===Advanced Joins:
--Retrieve the order_id, item_name, and price for all orders with their respective menu item details.
--Include rows even if there is no matching menu item.
select order_id,item_name,price
from order_details
left join menu_items on order_details.item_id = menu_items.menu_item_id

--===Unpivot Data:
--Unpivot the menu_items table to show a list of menu item properties (item_id, item_name, category, price).
select menu_item_id as item_id, 
    property,
    value
from (select menu_item_id,cast(item_name as nvarchar(max)) as item_name,
             cast(category as nvarchar(max)) as category ,
			 cast(price as nvarchar(max)) as price
      from menu_items )as sourse_table
unpivot (
    value for property in
(item_name,category ,price)) as unpvt;

--===Dynamic SQL:
--Write a dynamic SQL query that allows users to filter menu items based on category and price range.
declare @category nvarchar(50)='Dessert'; --category
declare @MinPrice Decimal(10,2)=10.00;-- minimum price
declare @MaxPrice Decimal(10,2)=20.00; --maximum price
declare @sql nvarchar(max);
set @sql='
select item_name,category,price
from menue_items
where 1=1';
if @category is not null
    set @sql += 'and category =  @category';
if @MinPrice is not null and
@MaxPrice is not null
    set @sql += 'and price between @MinPrice and @MaxPrice';
exec sp_executesql @sql, N'@category nvarchar(50),@MinPrice Decimal(10,2), @MaxPrice Decimal(10,2)',
    @category = @category,
	@MinPrice = @MinPrice,
	@MaxPrice = @MaxPrice;

--===Stored Procedure:
--Create a stored procedure that takes a menu category as input and returns the average price for that category.
create procedure 
GetAvaragePriceByCategory @category nvarchar(50)
as 
begin
     set nocount on;
	 select
	    category,AVG(price)as AvgPrice
	from menu_items
	where category =@category
	group by category;
end;

Exec GetAvaragePriceByCategory @category ='Dessert';

--===Triggers:
--Design a trigger that updates a log table whenever a new order is inserted into the order_details table
create table order_log(log_id int identity(1,1) primary key,
             order_id int,log_message nvarchar(255),log_item datetime default
getdate()
);

create trigger trg_insertOrderLog on order_details
after insert 
as 
begin
     set nocount on;
	 insert into order_log (order_id,log_message)
	 select inserted.order_id,'new order inserted with id:'
	+ cast(inserted.order_id as nvarchar(50))
	 from inserted;
end;

insert into order_details(order_id,menue_item_id,quantity,order_date,order_time)
values (201,5,2,'2024-06-15','12:30:00');

--===Recursive Common Table Expressions (CTE):
--Implement a recursive CTE to display the hierarchy of menu items with their subcategories.
with MenueHierarchy as (
   select menu_item_id,item_name,category,1 as level 
   from menu_items
   where category is not null
   union all 

   select m.menu_item_id,m.item_name,m.category,mh.level +1 as level
   from menu_items as m
   inner join MenueHierarchy as mh on m.category=mh.category
   where mh.level<5
)

select menu_item_id,item_name,category,level
from MenueHierarchy 
order by category,level
option (MAXRECURSION 5)

--===Temporal Tables:
--Design a temporal table structure to track changes in menu item prices over time.

alter database [Restorant]
set allow_snapshot_isolation on;
alter database [Restorant]
set read_committed_snapshot on;

create table menue_item_history(item_id int not null primary key,
                               item_name nvarchar(100) not null,
							   category nvarchar(50) not null,
							   price decimal (10,2) not null,
							   valid_from datetime2 generated always  as row start not null,
							   valid_to datetime2 generated always  as row end not null,
							   period for system_time(valid_form,valid_to))
							   with (system_versioning = on (history_table = abd.menue_item_history));
