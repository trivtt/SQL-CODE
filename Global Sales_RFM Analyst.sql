use Global_Sales
go

-- Tạo bảng tạm chứa các thông tin cần

create view rfm_info as
select Order_ID, Customer_Name, Order_Date, Sales from market_fact
left join orders_dimen on market_fact.Ord_id = orders_dimen.Ord_id
left join cust_dimen on market_fact.Cust_id = cust_dimen.Cust_id

-- Tính R,F,M
create view rfm as
select
	rfm_info.Customer_Name,
	datediff(day,max(Order_Date),'2012-12-31') as R, -- Sẽ lấy ngày 31-12-2012 trừ đi ngày order gần nhất của khách hàng
	count(distinct Order_ID) as F,
	sum(Sales) as M
from rfm_info
group by Customer_Name

-- Percent_rank cho yếu tố F và M
with fm_rank as (
select
	*,
	round((PERCENT_RANK() over (order by F)),2) as f_percent_rank,
	round((PERCENT_RANK() over (order by M)),2) as m_percent_rank
from rfm
)


-- Xếp hạng các giá trị R, F, M
, rfm_rank as (
select 
	*,
	case
		when R between 1 and 476 then 3
		when R between 476 and 952 then 2
		when R between 952 and 1431 then 1
		else 0
	end as R_rank,

	case 
		when f_percent_rank between 0.8 and 1 then 3
		when f_percent_rank between 0.4 and 0.8 then 2
		when f_percent_rank between 0 and 0.4 then 1
	end as F_rank,

	case
		when m_percent_rank between 0.8 and 1 then 3
		when m_percent_rank between 0.4 and 0.8 then 2
		when m_percent_rank between 0 and 0.4 then 1
	end as M_rank
from fm_rank
)

-- Tính điểm tổng RFM
, rfm_score as (
select 
	*,
	concat(R_rank, F_rank, M_rank) as RFM_score
from rfm_rank
)

-- Phân lựa KH theo RFM score
select 
	*,
	case
		when (R_rank = 3) and (F_rank = 3) and (M_rank = 3) then N'Khach VIP' -- 333
        when (R_rank between 1 and 3) and (F_rank between 1 and 3) and (M_rank = 3) then N'Chi nhiều nhất' -- xx3
        when (R_rank between 1 and 3) and (F_rank = 3) and (M_rank between 1 and 3) then N'Mua thường xuyên nhất' -- x3x
        when (R_rank = 3) and (F_rank between 1 and 3) and (M_rank between 1 and 3) then N'Mua hàng gần đây' --3xx
        when (R_rank = 2) and (F_rank = 2) and (M_rank =2) then N'Bình Thường' --222
        when (R_rank between 1 and 2) and (F_rank between 1 and 2) and (M_rank between 1 and 2) then N'Không Quan Tâm' --X1X
        
    end as Customer_Ranking
from rfm_score
order by RFM_score DESC