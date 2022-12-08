select 
	a.var
	,a.level
	,a.n_dist
	,a.pct_dist
    ,a,concentration
    ,a.hh_count
    ,a.hh_dist
from
(
	select 
	'00 topline' as var
	,'All Voters' as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
    left join voterfile_install.district d using(id,state) 
	group by 1,2

	union all

	select 
	'01 age bucket' as var
	,b.demo_age_bucket_full as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
	left join voterfile_install.district d using(id,state) 
	group by 1,2

	union all

	select 
	'02 gender' as var
	,b.gender_female::varchar as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
	left join voterfile_install.district d using(id,state) 
	group by 1,2

	union all

	select 
	'03 race/ethnicity' as var
	,b.demo_combined_ethnicity_4way as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
	left join voterfile_install.district d using(id,state) 
	group by 1,2

	union all

	select 
	'04 income' as var
	,b.demo_income_bucket_full as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
	left join voterfile_install.district d using(id,state) 
	group by 1,2

	union all

	select 
	'05 party' as var
	,b.demo_combined_party as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
	left join voterfile_install.district d using(id,state)
	where b.demo_combined_party in ('D','I')
	group by 1,2

	union all

	select 
	'06 urbanicity' as var
	,b.catalistsynthetic_urbanity as level
	,sum(univ_flag) as n_dist
	,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
    ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
    ,count(distinct householdid1) as hh_count
    ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist

	from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
    left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
	left join voterfile_install.district d using(id,state)
	group by 1,2) a


-- There are a lot of repeated queries in our SQL statement 
    -- 1. Joins 
        -- from (select * from model_scores.univ_base where target_geo2 in ('AZ','CA-47','CA-49','CO','CT-5','GA','IA-3','IL-14','KS-3','MI','NH','NJ-3','NV','OH-9','PA','VA-2','VA-7','WA-8','WI')) b
        -- left join (select *, '1' as univ_flag from model_scores.model_base_20220818_final left join model_scores.household using(id,state)) using(id,state)
        -- left join voterfile_install.district d using(id,state)
        -- group by 1,2)

        -- This statement is repeated seven times -- and it includes costly joins.  We can optimize our query significantly by performing this query only once instead of seven times.
        -- This statement itself could potentially be optimized by indexing the target_geo2, which will prevent a sequential scan of the data.

    -- 2. Optimizing the Join
        -- It's unclear if all of these tables need to joined together.
            -- Currently, we are joining the 
                -- model_scores.univ_base as b,
                -- model_scores.model_base_20220818_final
                -- model_scores.household
                -- voterfile_install.district d
            -- but we are only selecting four columns 
                -- b.catalistsynthetic_urbanity
                -- b.sporadic_dem_target, b.swing_target
                -- univ_flag
                -- householdid1
                -- as well as an additional column from b on each query
                -- So do we need each of those four tables in the query?

            -- We are also using left joins which are more costly than inner joins.  Are these necessary?

    -- 2. Repetition of Select
        -- We are repeating the same calculations in the select statement multiple times
            --     ,sum(univ_flag) as n_dist
            -- ,sum(univ_flag)/sum(sum(univ_flag)) over()::float as pct_dist
            -- ,sum(univ_flag)/sum(case when b.sporadic_dem_target =1 or b.swing_target =1 then 1 else 0 end)::float as concentration
            -- ,count(distinct householdid1) as hh_count
            -- ,count(distinct householdid1)/sum(count(distinct householdid1)) over()::float as hh_dist
    -- 3. Repetition Within Select Statement
        -- Even within this single select statement, we are performing the same calculations multiple times
        -- sum(univ_flag)
            -- can probably be done once
        -- count(distinct householdid1)
            -- distinct's are particularly costly, so we should avoid performing them multiple times.
            -- Here we are performing them of a householdid, and perhaps we already have a unique list of them in a table avoiding a distinct altogether.  
