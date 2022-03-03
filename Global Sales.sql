use Global_Sales
go

-- Giả Sử Trưởng Phòng Phân Phối Sản Phẩm Muốn Biết Thông Tin Về Tình Hình Hàng Hóa Tại Từng Khu Vực Để Ra Quyết Định Phân Bổ Lượng Hàng Hóa Sắp Tới Phù Hợp => Cần Các Thông Tin Sau:

-- 1.Kết quả kinh doanh với Product

with overview as (
select 
	prod_dimen.Product_Category , 
	year(orders_dimen.Order_Date) as Order_Year, 
	market_fact.Sales, market_fact.Profit, 
	market_fact.Shipping_Cost
from 
	market_fact
left join prod_dimen on market_fact.Prod_id = prod_dimen.Prod_id
left join orders_dimen on market_fact.Ord_id = orders_dimen.Ord_id
)

-- Tính Profit Margin và %Shipping_Cost
, profit_margin as (
select 
	overview.Product_Category, 
	overview.Order_Year, 
	sum(overview.Sales) as Sales, 
	sum(overview.Profit) as Profit, 
	sum(overview.Shipping_Cost) as Shipping_Cost, 
	round(sum(overview.Profit)/sum(overview.Sales),2) as Profit_Margin, 
	round(sum(overview.Shipping_Cost)/sum(overview.Sales),2) as Percent_Shipping_Cost 
from 
	overview
group by 
	overview.Product_Category, 
	overview.Order_Year
)

select *,
	case 
		when profit_margin.Profit_Margin - profit_margin.Percent_Shipping_Cost > 0.1 then 'Profit Margin So Much'
		when profit_margin.Profit_Margin - profit_margin.Percent_Shipping_Cost between 0 and 0.05 then 'Profit Margin'
		when profit_margin.Profit_Margin < profit_margin.Percent_Shipping_Cost then 'Shipping Cost So Much'
		else 'No Profit'
	end as Check_Shipping_Cost
from 
	profit_margin
order by 
	profit_margin.Product_Category, 
	profit_margin.Order_Year

-- 2.Kết quả kinh doanh từng khu vực
with overview_region as (
select 
	cust_dimen.Region , 
	year(orders_dimen.Order_Date) as Order_Year, 
	market_fact.Sales, market_fact.Profit, 
	market_fact.Shipping_Cost
from 
	market_fact
left join cust_dimen on market_fact.Cust_id = cust_dimen.Cust_id
left join orders_dimen on market_fact.Ord_id = orders_dimen.Ord_id
)

-- Tính Profit Margin và %Shipping_Cost
, profit_margin_region as (
select 
	overview_region.Region, 
	overview_region.Order_Year, 
	sum(overview_region.Sales) as Sales, 
	sum(overview_region.Profit) as Profit, 
	sum(overview_region.Shipping_Cost) as Shipping_Cost, 
	round(sum(overview_region.Profit)/sum(overview_region.Sales),2) as Profit_Margin, 
	round(sum(overview_region.Shipping_Cost)/sum(overview_region.Sales),2) as Percent_Shipping_Cost 
from 
	overview_region
group by 
	overview_region.Region, 
	overview_region.Order_Year
)

select *,
	case 
		when profit_margin_region.Profit_Margin - profit_margin_region.Percent_Shipping_Cost > 0.1 then 'Profit Margin So Much'
		when profit_margin_region.Profit_Margin - profit_margin_region.Percent_Shipping_Cost between 0 and 0.1 then 'Profit Margin'
		when profit_margin_region.Profit_Margin < profit_margin_region.Percent_Shipping_Cost then 'Shipping Cost So Much'
		else 'No Profit'
	end as Check_Shipping_Cost
from 
	profit_margin_region
order by 
	profit_margin_region.Region, 
	profit_margin_region.Order_Year

-- 3. Số đơn hàng theo nhóm KH và mặt hàng
select 
	sum(market_fact.Order_Quantity) as Quantity, 
	cust_dimen.Customer_Segment 
from 
	market_fact
left join cust_dimen on cust_dimen.Cust_id = market_fact.Cust_id
group by 
	cust_dimen.Customer_Segment

select 
	sum(market_fact.Order_Quantity) as Order_Quantity, 
	cust_dimen.Customer_Segment, 
	prod_dimen.Product_Category 
from 
	market_fact
left join cust_dimen on cust_dimen.Cust_id = market_fact.Cust_id
left join prod_dimen on prod_dimen.Prod_id = market_fact.Prod_id
group by 
	cust_dimen.Customer_Segment, 
	prod_dimen.Product_Category
order by 
	cust_dimen.Customer_Segment, 
	prod_dimen.Product_Category

-- 4.Số đơn hàng theo mức độ ưu tiên và thời gian chuẩn bị hàng
select 
	sum(market_fact.Order_Quantity) as Order_Quantity, 
	orders_dimen.Order_Priority, 
	avg(DATEDIFF(day,Order_Date,Ship_Date)) as Avg_Prepare_Time 
from 
	market_fact
left join orders_dimen on orders_dimen.Ord_id = market_fact.Ord_id
left join shipping_dimen on shipping_dimen.Ship_id = market_fact.Ship_id
group by 
	Order_Priority

-- 5. Khoảng thời gian chốt được nhiều đơn hàng nhất và mặt hàng nào cao điểm
with order_time as ( 
select 
	Product_Category, 
	Region , 
	Customer_Segment, 
	month(Order_Date) as Month_Order,
	year(Order_Date) as Year_Order,
	Sales, 
	Order_Quantity
from
	market_fact
left join orders_dimen on orders_dimen.Ord_id = market_fact.Ord_id
left join prod_dimen on prod_dimen.Prod_id = market_fact.Prod_id
left join cust_dimen on cust_dimen.Cust_id = market_fact.Cust_id
)

select
	Product_Category, 
	Region , 
	Customer_Segment, 
	Month_Order,
	Year_Order,
	sum(Sales) as Sales, 
	sum(Order_Quantity) as Order_Quantity
from order_time
where
	Year_Order = 2012 and
	Product_Category = 'OFFICE SUPPLIES' and
	Customer_Segment = 'CORPORATE'
group by 
	Product_Category, 
	Region, 
	Customer_Segment,
	Month_Order,
	Year_Order
order by Sales DESC


-- 6. Thể Hiện Hàng Hóa Bán Chạy Có Do Discount Nhiều Hay Không (Theo Khu Vực)
-- Chuyển Discount sang dạng float
alter table market_fact
alter column Discount float

select 
	Product_Category, 
	Region, 
	sum(Sales) as Sales, 
	round(sum(Profit)/sum(Sales),2) as Profit_Margin ,
	round(stdev(Discount),2) as STD_Discount 
from 
	market_fact
left join cust_dimen on cust_dimen.Cust_id = market_fact.Cust_id
left join prod_dimen on prod_dimen.Prod_id = market_fact.Prod_id
group by 
	Product_Category, 
	Region
order by Profit_Margin DESC

-- 7. %Doanh Thu Từng Mặt Hàng, %Số Đơn Hàng Theo Từng Khu Vực 

with sales as (
select
	region,
	Product_Category,
	sum(Sales) as Net_Sales,
	sum(Order_Quantity) as Sum_Order_Quantity
from
	market_fact
left join cust_dimen on market_fact.Cust_id = cust_dimen.Cust_id
left join prod_dimen on market_fact.Prod_id = prod_dimen.Prod_id
group by region, Product_Category
)

select 
	*,
	sum(Net_Sales) over (partition by region) as Total_Sales,
	sum(Sum_Order_Quantity) over (partition by region) as Total_Order_Quantity,
	str(round(Net_Sales/sum(Net_Sales) over (partition by region),2)*100) + '%' as Percent_Sales,
	str(round(Sum_Order_Quantity/sum(Sum_Order_Quantity) over (partition by region),2)*100) + '%' as Percent_Order_Quantity
from sales


