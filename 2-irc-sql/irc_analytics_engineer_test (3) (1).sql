/*
IRC Analytics Engineering SQL Test

This test consists of two parts:

1. A SQL skill-based component consisting of a series of questions on provided
datasets, whereby there are - more or less - right and wrong answers.

2. A qualitative evaluation step whereby there are no wrong answers. Rather,
from your response, we hope to obtain an understanding of your thought processes
and general approach to refactoring a bad ELT SQL query.

Please spend no more than three hours on the test. Part One should only
require about 45-60 minutes, while you should expect to spend about 1-2 hours
on Part Two.
*/

/*
-- Part One: --
Using the provided datasets (accounts.csv and donations.csv), answer the
following questions with a SQL statement that will produce the correct results.
Please write your SQL in this document below. You may also include screenshots
of results if you wish. However, you will be graded on your SQL code, not your
results. The IRC uses T-SQL. However, you may use any SQL dialect that you are
comfortable with.

*Please note here which SQL dialect you are using:*

Notes on the datasets:
- The primary key of accounts is account_id.
- The primary key of donations is donation_id.
*/

/*
1. What are the top five organizations by revenue in 2021?
*/


/*
2. Create an account-level table with aggregate measures of revenue in
past week, past month, past year, and all time.
*/


/*
3. What is the average first donation of new donors for each billing country?
*/


/*
-- Part Two: --
The following query is an actual example of code that we have refactored, or
plan to refactor.

When we look to refactor code we evaluate it with regards to a few areas:
- Performance: Generally, we want to keep our queries running in under 20
  minutes. So we attempt to avoid SQL practices that risk causing performance
  issues as our data grows. Sometimes this means there are too many complicated
  joins or window functions. Other times it just means the object is trying to
  amass and transform too much data in one go.

- Readability: We want other analyts/engineers to be able to easily skim a
  SQL script and understand what it is trying to accomplish. Often this means
  the author takes care to provide good notes/comments and to structure the code
  in a consistent and understandable way. For example, explicit column names,
  meaningful aliases, and neatly indented code.

- Modularity: We want individual pipeline objects to be scoped to a general
  transformation goal such as: data enrichment, data pivots, rollups,
  data source knitting, aggregate calculations, etc. Our aim in doing so is to
  reduce redudancy and repeition and keep the number of places in our pipelines
  where certain joins, calculated fields, and other business logic are applied
  to a minimum.

For the following query, please provide your thoughts regarding how well, or
poorly, the author(s) performed in the above areas. Additionally, please
describe how you might have approached things differently. For instance, you may
not know whether the query below will be slow, but depending on the data size
you may suspect X join or Y window function might cause problems at some point
as the dataset grows. If you find particular sections difficult to read, how
would you restructure the work within the query or break it out into another
query/pipeline step?

Reminder: There are no wrong or right answers here.

There is a lot of missing context here for you. So we don't expect you to give
us solutions. (In fact, assume the query accurately creates the intended
database object.) Mostly, we are looking to understand your thought processes
and general approach to rethinking the query below. Letting us know what
questions you might have about the pipeline or data also helps us reach that
understanding.

At the bottom of the script, there is a section to include a summary of your
thoughts. However, if you also wish to include in-line comments on the query
below, you can use the following "searchable comment" format:*/

/* TEST COMMENT: ... */


--------------------------------------------------------------------------------
----------------------------- Start SQL statement ------------------------------
--------------------------------------------------------------------------------

CREATE VIEW [PBI].[v_IncomeDataCube]
AS
/* Income Data Cube Query  For most External Relations pbi dashboards. */
-- all revenue
SELECT
	BankedStatus		= pa.bankedStatus
	, o.stagename

	/* Europe high-value currency conversion per rates set at time of budget:
		GBP	=1.3
		eur = 1.12
		SEK = 0.1
		CHF convert to GBP first

	US Vantive: in US CRM, Vantive does currency conversion as well.  SF later updates.
		Originally entered as Amount = $0.01.   Opportunity.Amount is always in USD
*/
	,amount				=		--Best case projected, CFY , allocated, USD
								(CASE WHEN BankedStatus in ('Pipeline')		THEN	pa.[AllocatedBestCaseCFYUSDAmt]    --Ignore Requested pa.AllocatedRequestedCFYUSDAmt
									WHEN Bankedstatus  IN ('Banked','Pledged') THEN  pa.AllocatedPaymentUsdAmt ELSE pa.IRCValuationAmt END)
	,RAV_InOriginalCurrency =  (CASE WHEN BankedStatus in ('Pipeline')		THEN pa.AllocatedProjectedCFYAmt
									WHEN Bankedstatus  IN ('Banked','Pledged') THEN pa.AllocatedPaymentAmt ELSE [IrcValuationAmt] END )
	,OriginalCurrencyIsoCode = pa.CurrencyIsoCode

	,[target]			= 0
	,Risk_Adjusted_Total_CFY = (CASE					-- use this field for most reporting
									WHEN Bankedstatus  IN ('Banked','Pledged') THEN  pa.AllocatedPaymentUsdAmt
									WHEN BankedStatus in ('Pipeline')	THEN pa.AllocatedProjectedCFYUSDAmt  ELSE pa.IRCValuationAmt  END)

	,Probability		= isnull(pa.Probabilitypct, CAST('100' as int) )
    ,GBP_amount			= 0
	,AccountId			= A.edwSourceid
	,Account_Name		= (CASE
			WHEN a.AccountName = 'IRC Admin / ICR Account'				THEN 'Admin/ICR Reallocation'
			WHEN Exists (SELECT 1 from GPP..uvMart_BiosPreference pref1  (nolock)
						where pref1.rC_Bios__Type__c = 'Anonymous'
						and pref1.rC_Bios__Account__c = a.EDWSourceId
						)												THEN 'Anonymous'
			WHEN gl.LoMidHiLevel = 'HighValue'							THEN a.AccountName     -- >= 25000 Annual; note that Hugh's cube uses Gift Size
																		ELSE 'Under 20K' END)

	,Fiscal_Year		= CASE WHEN BankedStatus in ('Pipeline')		THEN 'FY' + right(isnull(ad.FiscalYearName,cd.FiscalYearName) ,2)
							   WHEN BankedStatus IN ('Banked','Pledged') THEN 'FY' + right(ed.FiscalYearName,2)
																		ELSE 'FY' + right(cd.FiscalYearName,2) END
	,Fiscal_Period		= CASE WHEN BankedStatus in ('Pipeline')
									AND isnull(ad.FiscalPeriodNum,cd.FiscalPeriodNum) < 10 THEN 'P0'+ cast(isnull(ad.FiscalPeriodNum,cd.FiscalPeriodNum) as char(1))
							WHEN BankedStatus in ('Pipeline')								THEN 'P'+ cast(isnull(ad.FiscalPeriodNum,cd.FiscalPeriodNum) as char(2))
							WHEN BankedStatus IN ('Banked','Pledged')
									AND (ed.FiscalPeriodNum) < 10		THEN 'P0'+ cast(ed.FiscalPeriodNum as char(1))
							WHEN BankedStatus IN ('Banked','Pledged')	THEN 'P'+ cast(ed.FiscalPeriodNum as char(2))
							WHEN cd.FiscalPeriodNum < 10				THEN 'P0'+ cast(cd.FiscalPeriodNum as char(1))
																		ELSE 'P'+ cast(cd.FiscalPeriodNum as char(2)) END
	,Secured_In_Last_Week = (CASE
			WHEN pd.daydate >= dateadd(dd, -7, getdate())						-- Eu date established; US pledge close date
			 and pd.daydate  <= getdate()								THEN 'Y' ELSE 'N' END)

	,FYTD_Period_Filter = (CASE WHEN BankedStatus in ('Pipeline')
									and isnull(ad.IsGiftinFYTD,cd.IsGiftinFYTD)= 0 THEN 'YTG'
								WHEN BankedStatus IN ('Banked','Pledged')
									AND ed.IsGiftinFYTD = 0				THEN 'YTG'
								WHEN BankedStatus IN ('Received-GIK','Pledged-GIK')
									AND cd.IsGiftinFYTD = 0				THEN 'YTG'
																		ELSE 'YTD' END)
	,New_v_Retained_KPI = (CASE											-- Revenue new to IRC
			 WHEN (D12.DepartmentSummaryName = 'High-Value Fundraising'
					OR org.FundraisingcategorySummaryName = 'High-Value Fundraising')
				 AND (a.FirstGiftDate is null
					 OR a.FirstGiftDate >= cd.FiscalYearStartDate)				THEN 'New'
			 WHEN (D12.DepartmentSummaryName = 'High-Value Fundraising'
					OR org.FundraisingcategorySummaryName = 'High-Value Fundraising')
				 AND NOT EXISTS (SELECT 1 FROM fact.RevenueAllocation (nolock) pa1
								INNER JOIN dim.calendarDay (nolock) cd1 on cd1.DayID = pa1.CloseDateDayId
								WHERE pa1.SoftCreditAccountId = a.accountid
								AND cd1.fiscalYearNum >= cd.FiscalYearNum - 3
								)												THEN 'New'
			WHEN (D12.DepartmentSummaryName = 'Mass Marketing'
					OR org.FundraisingcategorySummaryName = 'Mass Marketing')
				 AND PA.IsSustainerPayment = 0
				 AND cd.daydate  = cast(a.FirstGiftDate as date)				THEN 'New'
			WHEN (D12.DepartmentSummaryName = 'Mass Marketing'
					OR org.FundraisingcategorySummaryName = 'Mass Marketing')
				 AND PA.IsSustainerPayment = 1
				 AND (a.FirstSustainerGiftDate is null
					 OR a.FirstSustainerGiftDate >= cd.FiscalYearStartDate)		THEN 'New'
																				ELSE 'Retained' END)
	,New_vs_Existing = (CASE
			 WHEN a.FirstGiftDate is null								THEN 'New'
			 WHEN a.FirstGiftDate = ''									THEN 'New'
			 WHEN BankedStatus = 'Pipeline'
				AND a.FirstGiftDate >= ad.FiscalYearStartDate			THEN 'New'
			WHEN BankedStatus <> 'Pipeline'
				AND a.FirstGiftDate >= ed.FiscalYearStartDate			THEN 'New'
																		ELSE 'Existing' END)
	,GivingLevel = GL.HighValueLevel
	,FundType = (CASE																	-- pipeline US often missing GAU, but pick it up if exists
			 when gau.T1Code like 'TR%'									then 'Restricted-Broadly Earmarked'
			 WHEN (GAU.GivingTypeName = 'Annuity')						THEN 'Annuity'
			 WHEN GAU.GivingTypeName Not in ('Error', 'Unknown')		THEN Gau.IncomeBreakdownName
			 WHEN BankedStatus in ('Received-GIK','Pledged-GIK')		THEN 'In Kind'
			 WHEN pa.Program in ('Unrestricted','Rescue Dinner')		then 'Unrestricted'    --Pipeline
																		ELSE 'TBD' END)
	,FinanceClassification = (case when gau.FinanceClassificationName = 'Pass Through (Not Recognized as IRC Revenue)' then 'Pass Through'
			when gau.T1Code like 'TR%'									then 'Restricted-Broadly Earmarked'
																		else gau.FinanceClassificationName	end)
	,FundingDesignation =
			(case when GAU.GAUName in ('Z-UNREST ADMIN-ICR'
									, 'Z-REST ADMIN-ICR')				then 'Admin Reallocation'
				WHEN gau.Reportingcategoryname in ('Undefined'
								,'Other Geographic Interest (non-IRC)') then 'Other'
																		else gau.reportingcategoryname end)
	,Funding_Need		=
			(CASE WHEN BankedStatus <> 'Pipeline'
					AND gau.FundingNeedName is not null					THEN gau.FundingNeedName
				WHEN pa.[edwSourceFundingNeedID] is not null			THEN (SELECT  FN.[name]
																			FROM
																					(Select id,[name] FROm GPP..uvMart_FundingNeed
																					UNION
																					Select id,[name] FROm GPP_UK..uvMart_FundingNeed
																					) FN
																			WHERE FN.id = PA.[edwSourceFundingNeedID])
																		ELSE null END)
	,T6_FundraisingMarket =
			Case
			when org.FundraisingMarketParentName in ('United States'
													, 'Rest of World')	then 'US/RoW'
				when org.FundraisingMarketName like 'United Kingdom'	Then 'UK'
				when org.DivisionName like 'Germany%'					THEN 'Germany'
				when org.DivisionName like 'Sweden%'					THEN 'Sweden'
				when D12.MarketName in ('US'
													, 'Remote Markets')	then 'US/RoW'
				when D12.MarketName IN ('UK', 'Germany','Sweden')		Then D12.MarketName
																		else 'Other' END
	,PaymentDate		= isnull(ad.daydate, cd.daydate )									-- award date for US pipeline
	,EffectiveDate		= (CASE WHEN BankedStatus in ('Pipeline')		THEN isnull(ad.daydate, cd.daydate )
							WHEN BankedStatus in ('Banked','Pledged')	THEN ed.daydate
																		ELSE cd.daydate END)
	,Fiscal_Year_of_Commitment        = 'FY' + right(coalesce(ad.fiscalYearName, pd.FiscalYearName, cd.FiscalYearName),2)
	,Fiscal_Period_of_Commitment      = CASE coalesce(ad.fiscalPeriodNum,pd.FiscalPeriodNum,cd.FiscalPeriodNum)
											WHEN 1 THEN 'P01' WHEN 2 THEN 'P02' WHEN 3 THEN 'P03' WHEN 4 THEN 'P04' WHEN 5 THEN 'P05' WHEN 6 THEN 'P06'
											WHEN 7 THEN 'P07' WHEN 8 THEN 'P08' WHEN 9 THEN 'P09' WHEN 10 THEN 'P10' WHEN 11 THEN 'P11' WHEN 12 THEN 'P12' ELSe 'P12' END
	,PledgedDate		= coalesce(ad.Daydate,pd.Daydate,cd.Daydate)
	,IncomeStream		= o.IncomeStreamName
	,Subtype = (CASE
			when o.RecordTypeName = 'Matching Gift'
				AND o.edwSourceName = 'Europe'											THEN 'Corporate Workplace and Match Giving'
			when o.RecordTypeName = 'Grant'
				AND o.edwSourceName = 'Europe'											THEN 'Grant'
			WHEN o.edwSourceName = 'Europe'												THEN 'Other'
			WHEN c.T3Code like 'FA%'
				and c.SubAffiliationName not in ('Marketing','Marketing New Markets')	THEN 'Rescue Dinner'
		   WHEN c.ChannelName in ('Web','Email','Text-To-Give')							THEN o.MarketSource
		   WHEN (c.SubAffiliationName = 'Marketing New Markets')						THEN 'Global Digital'
																						ELSE c.SolicitationTypename END)
	,Channel = CASE WHEN c.ChannelName in ('Web','Email','Text-To-Give')				THEN 'Digital'
																						ELSE 'Offline' END
	,SubChannel		= c.SubChannelName
	,Tier2	= Case WHEN (D12.DepartmentName = 'International Development'
						AND o.IncomeStreamName IN ('Corporate', 'Trusts & Foundations'
													,'New Funding Streams'))			THEN o.IncomeStreamName
				WHEN (D12.DepartmentName = 'International Development'
						AND o.IncomeStreamName is not null	)							THEN 'HNWI'
				WHEN (D12.DepartmentName = 'International Development'
						OR org.SubUnitName = 'Institutional Philanthropy')
					AND a.PortfolioName in ('New Funding Streams', 'Global Leads Business Development')	THEN 'New Funding Streams' --'Global Leads Business Development'
				WHEN (D12.DepartmentName = 'International Development'
						OR org.SubUnitName = 'Institutional Philanthropy')
					AND a.PortfolioName LIKE '%HNWI%'									THEN 'HNWI'
				/*WHEN (D12.DepartmentName = 'International Development'
						OR org.SubUnitName = 'Institutional Philanthropy')
					AND a.PortfolioName IN ('Other')									THEN 'HNWI'*/
				WHEN (D12.DepartmentName = 'International Development'
						OR org.SubUnitName = 'Institutional Philanthropy')
					AND a.PortfolioName like '%Foundations%'							THEN 'Trusts & Foundations'
					-- income stream not null goes in here
				WHEN (D12.DepartmentName = 'International Development'
					OR org.SubUnitName = 'Institutional Philanthropy')					THEN 'Corporate' --'Corporates'

				WHEN c.SubAffiliationName = 'Planned Gifts'								THEN 'Planned Giving'
				WHEN (D12.DepartmentName = 'USA Philanthropy'
						OR org.SubUnitName = 'USA Philanthropy')
				AND A.AccountOwnerTeam IN ('Principal Giving', 'Planned Giving'
											, 'Major Giving','Leadership Giving')		THEN A.AccountOwnerTeam
				WHEN (D12.DepartmentName = 'USA Philanthropy'
						OR org.SubUnitName = 'USA Philanthropy')						THEN 'USA-P Other'

				WHEN (D12.DepartmentName = 'Mass Marketing'
						OR org.FundraisingCategorySummaryName = 'Mass Marketing')
					AND PA.IsSustainerPayment = 1										THEN 'Sustainers'
				WHEN (D12.DepartmentName = 'Mass Marketing'
						OR org.FundraisingCategorySummaryName = 'Mass Marketing')		THEN 'Cash'
				WHEN D12.TeamName = 'RAI'												THEN 'RAI'
				WHEN org.T5Code like '6%'												THEN 'RAI'
				WHEN D12.TeamName not in ('Error', 'Unknown')							THEN D12.TeamName
																						ELSE org.SubUnitName END
	,IncomeStreamParent = CASE
								WHEN D12.UnitName = 'I-Dev'								THEN 'Int''l Partnerships & Philanthropy'
								WHEN D12.UnitName like 'RAI%'							THEN 'RAI'
								WHEN D12.UnitName not in ('Error','Other', 'Unknown')	THEN D12.UnitName

								WHEN org.SubUnitName = 'Institutional Philanthropy'		THEN 'Int''l Partnerships & Philanthropy'
								WHEN org.SubUnitName = 'USA Philanthropy'				THEN 'USA Philanthropy'
								WHEN org.SubUnitName = 'DM USA'							THEN 'US Mass Marketing'
								WHEN org.T5Code like '6%'								THEN 'RAI'
								WHEN org.t5code  = '8DI'								then 'UK Mass Marketing'
								WHEN org.T5Code = '8PP'									then 'UK High-Value Fundraising'
								WHEN org.SubUnitName = 'Germany High-Value'				THEN 'Germany High-Value Fundraising'
								WHEN org.SubUnitName = 'Germany Marketing'				THEN 'Germany Mass Marketing'
								WHEN org.SubUnitName = 'Sweden High-Value'				THEN 'Sweden High-Value Fundraising'
								WHEN org.SubUnitName = 'Sweden Marketing'				THEN 'Sweden Mass Marketing'
																						ELSE org.SubUnitName END

	,IncomeStreamGrandparent =
								(CASE WHEN d12.TeamName = 'RAI'							THEN 'US Programs'
																						ELSE 'ER Private Sector Fundraising' END)
	,FundraisingCategory	= Isnull(org.FundraisingCategorySummaryName, D12.DepartmentSummaryname)
	,T5_Code				= LEFT(gau.T5Code,30)
	,Finance_Codes			=							-- didn't map UK D codes yet as of 12Jun20
							(CASE WHEN gau.GAUname in ('UNCODED','UNCODED-CORONAVIRUS') THEN 'D Codes Pending'
																						ELSE concat(isnull(gau.D1Code,'')
																									,'; ', isnull(gau.D4Code,'')
																									, '; ',isnull(gau.D5Code,'')) end)
	,EmergencyRelated		= case when gau.IsEmergency = 1								then 'true' else 'false' end
	,ThematicArea			= (CASE WHEN bankedStatus <> 'Pipeline'						THEN isnull(gau.outcomeCategoryname,gau.ThematicArea)
									WHEN pa.program = 'Health Unit'						then 'Health'
									when pa.program = 'Non-Programmatic Focus'			then 'TBD'
									when pa.program is not null							then pa.program
																						else 'No Proposal Distribution' end)
	,ThematicAreaParent		= (CASE WHEN bankedStatus <> 'Pipeline'						THEN isnull(gau.ThematicArea, 'Multi-Sectoral/Other') -- includes UR
									WHEN pa.program = 'Emergencies'						THEN 'Emergency Preparedness & Response'
									WHEN pa.program = 'CRF'								THEN 'Emergency Preparedness & Response'
									WHEN pa.program = 'Health Unit'						THEN 'Health'
									WHEN pa.program = 'Education'						THEN 'Education'
									WHEN pa.program = 'Economic Recovery and Development'THEN 'Economic Recovery & Development'
									WHEN pa.program = 'RAI: Economic Empowerment'		THEN 'RAI'
									WHEN pa.program = 'RAI: General'					THEN 'RAI'
									WHEN pa.program = 'RAI: Immigration'				THEN 'RAI'
									WHEN pa.program = 'RAI: Mental Health'				THEN 'RAI'
									WHEN pa.program = 'RAI: Women Protection & Empowerment'THEN 'RAI'
									WHEN pa.program = 'RAI: New Roots'					THEN 'RAI'
									WHEN pa.program = 'R&I'								THEN 'R&D'
									WHEN pa.program = 'R&D'								THEN 'R&D'
									WHEN pa.program = 'Unrestricted'					Then 'Unrestricted'		--if pledged will become FundType = UR.
									WHEN pa.program IS null								THEN 'Unrestricted'
												--WHEN 'Non-Programmatic Focus'			Then 'Unrestricted'
																						ELSE 'Multi-Sectoral/Other' END)
	,OutcomeCategory		= gau.outcomeCategoryname
	,ProgramArea			= pa.program																		-- Not needed  - use ThematicArea
	,Donor_Type				= CASE WHEN (a.accountTypename = 'Company')					THEN 'Corporation'
									WHEN a.AccountTypeName NOT like 'Unknown%'			THEN a.AccountTypeName
									WHEN a.IsIndividual = 1								THEN 'Household'
																						ELSE '' END
	,Industry				= a.Industry
	,Capacity_Bucket		= a.CapacityRatingBand
	,CountryName			=
		(CASE
		 WHEN dc.CountryName in ('United States of America','United States Minor Outlying Islands') THEN 'United States'
		 WHEN dc.CountryName = 'United Kingdom of Great Britain and Northern Ireland'	THEN 'United Kingdom'
																						ELSE isnull(dc.CountryName,'United States')
	   END)
	,Market_Category		=
		(CASE WHEN dc.CountryName in ('United States of America','United States Minor Outlying Islands') THEN 'United States'
          WHEN dc.CountryName = 'United Kingdom of Great Britain and Northern Ireland'	THEN 'United Kingdom'
	      WHEN dc.CountryName = 'Sweden'												then 'Sweden'
		  WHEN dc.CountryName = 'Germany'												then 'Germany'
		  WHEN isnull(dc.CountryName,'United States') = 'United States'					then 'United States'
		  WHEN dc.IRCRegionName is not null												then dc.IRCRegionName
																						ELSE 'Rest of World' END)
	,IsMultiYear_Sustaining =																		-- KPI Sustainer page, % Sustainable Income
		(CASE
		WHEN org.FundraisingCategorySummaryName = 'Mass Marketing'
				AND pa.IsSustainerPayment = 1											THEN 'Y'
			WHEN D12.DepartmentName = 'Mass Marketing'
				AND pa.IsSustainerPayment = 1											THEN 'Y'
			WHEN isnull(D12.DepartmentName,'') <> 'Mass Marketing'
				AND org.FundraisingCategorySummaryName <> 'Mass Marketing'
				AND BankedStatus in ('Banked','Pledged')
				AND (pledge.GivingType = 'Multi-Year'											-- pre-alignment, temporarily remove to increase throughput
					OR o.SolicitationTypeName = 'Multi-Year')							THEN 'Y'
			WHEN isnull(D12.DepartmentName,'') <> 'Mass Marketing'
				AND org.FundraisingCategorySummaryName <> 'Mass Marketing'
				AND BankedStatus = 'Pipeline'
				AND o.EstimatedDurationInYrs > 1.0										THEN 'Y'
			WHEN D12.DepartmentName <> 'Mass Marketing'
				AND o.EDWSourceName = 'Europe'
				AND (  (sg.installmentperiod = 'Yearly' AND  sg.numberofInstallments > 1)
					OR (sg.installmentperiod= 'Quarterly' AND  sg.numberofInstallments > 4)
					OR (sg.installmentperiod= 'Monthly' AND sg.numberofInstallments  > 12)
					)																	THEN 'Y'

																						ELSE 'N' END)			-- KPi definition FY21

	,Committed_Giving		= --to enable flexibility in reporting against the “Sustainable Funding” KPI, for which there is some debate about
							-- whether to measure this KPI against just “solicited” high-value income vs. overall high value income
       (CASE WHEN BankedStatus in ('Pipeline')											THEN ''
			WHEN BankedStatus in ('Received-GIK', 'Pledged-GIK')						THEN 'One Time Gifts'
			WHEN Pledge.PledgeFrequencyName in ('Monthly','1st and 15th','Weekly')		THEN 'Monthly'
			WHEN SG.PaymentFrequency in ('Monthly','1st and 15th','Weekly')			THEN 'Monthly'
			WHEN o.EDWSourceName = 'US'
				and Pledge.EDWSourceParentId is not null
				AND Pledge.PledgeFrequencyName in ('One Payment','Single Payment','Single Instalment')
																						THEN 'One Time Gifts (with Proposal or Scheduled Gift)'
			WHEN o.EDWSourceName = 'Europe'
				AND SG.PaymentFrequency in ('One Payment','Single Payment','Single Instalment')
																						THEN 'One Time Gifts (with Proposal or Scheduled Gift)'
			WHEN o.EDWSourceName = 'US'
				and Pledge.PledgeFrequencyName in ('One Payment','Single Payment','Single Instalment')
																						THEN 'One Time Gifts (without Proposal or Scheduled Gift)'
			WHEN o.EDWSourceName = 'Europe'
				and isnull(SG.PaymentFrequency,'N/A') in ( 'N/A','Unknown')
																						THEN 'One Time Gifts (without Proposal or Scheduled Gift)'
			WHEN o.EDWSourceName = 'US'
				and Pledge.EDWSourceParentId is not null								THEN 'Other (with Proposal or Scheduled Gift)'
			WHEN o.EDWSourceName = 'Europe'												THEN 'Other (with Proposal or Scheduled Gift)'
			WHEN o.EDWSourceName = 'US'													THEN 'Other (without Proposal or Scheduled Gift)'
																						ELSE 'Error' END)
	 ,DataSource			= o.EDWSourceName
	,[PledgeID]				= pledge.edwSourceid
	,GivingID				= o.edwSourceid  --CASE WHEN o.edwSourceid <> '0' THEN o.edwSourceid else left(pa.SV_SourceId,18) END
	, GAUId					= GAU.edwSourceid
	, Campaignid			= c.EDWSourceId
	--, TransactionReference  = f.[Transaction Reference]            -- first one only
	,D12.D12code
	,MainAccountingCode		= gau.FinancialAccountCode
	,SustainerAcquired		=										-- flag initial payment on Sustainer pledge
						CASE WHEN o.IRCGiftCategory = 'Initial Payment'					THEN 'Y'
							WHEN pa.IsSustainerPayment = 1
								AND o.InstallmentNumber = 1								THEN 'Y'
																						ELSE null END
	,SubTeam				= a.AccountOwnerSubTeam
	,[edwSourceFundingNeedID]= pa.[edwSourceFundingNeedID]
	,RecordModifiedDate		= pa.[edwSourceSystemModstamp]
FROM [fact].[RevenueAllocation]	(nolock)					pa
	INNER JOIN [dim].[PSEOrganization]						org		ON org.OrganizationId = pa.OrganizationId
	INNER JOIN [dim].[v_CalendarDay](nolock)				ed		ON ed.DayID = pa.EffectiveDateDayId
	INNER JOIN [dim].[v_CalendarDay]	(nolock)			cd		ON cd.DayID = pa.CloseDateDayId
	INNER JOIN [dim].[v_ConstituentAccount]	(nolock)		a		on pa.SoftCreditAccountId = a.AccountId
	INNER JOIN dim.FundraisingCampaign	(nolock)			c		ON c.CampaignId = pa.CampaignId
	INNER JOIN
		(SELECT Opportunityid, Closedate, edwSourceid, EDWSourceName,RecordTypeName	,Stagename,EstimatedDurationInYrs
		,MarketSource,IncomeStreamName,IRCGiftCategory,SolicitationTypeName,InstallmentNumber,createddate
		FROM dim.FundraisingOpportunity (nolock))
															o		ON o.OpportunityId = pa.PaymentOpportunityId
	LEFT JOIN (SELECT opportunityid, Closedate, GivingType, edwSourceid, edwSourcename
					,PledgeFrequencyName,EDWSourceParentId
				FROM dim.fundraisingOpportunity(nolock))	pledge	on pledge.EDWSourceName = 'US' AND  pledge.opportunityid = pa.PledgeId
	LEFT JOIN dim.ScheduledGift								sg		on sg.EDWSourcename = 'Europe' AND  sg.PledgeId = pa.PledgeId
	INNER JOIN [dim].[RevenueDesignationGau] (nolock)		gau		ON gau.RevenueDesignationGauId = pa.RevenueDesignationGauId
	LEFT JOIN [dim].[v_CalendarDay]	(nolock)				pd		ON pd.DayID = pa.EstablishedDateDayId--pledge close date
	LEFT JOIN util.[AccountsByGivingLevelFYE] (nolock)		agl		ON agl.AccountId = a.accountid
																	AND agl.FiscalYearNum = ed.FiscalYearNum
	LEFT JOIN util.FundraisingGivingLevel (nolock)			gl		on gl.GivingLevelID = agl.GivingLevelID
    LEFT JOIN GPP_PSE_Reports.[dim].[DonorCountry](nolock)		dc		on dc.ISO3CountryCode = a.BillingCountryCode
	LEFT JOIN dim.D12	(nolock)								D12		on D12.D12Id = pa.D12Id
	LEFT JOIN [dim].[v_CalendarDay]	(nolock)					ad		ON ad.DayID = pa.Actual_AnticipatedAward_DateId

WHERE --o.createddate <= '2021-08-25 18:00' AND   for testing only
(Bankedstatus in ('Banked','Pledged') AND  cd.FiscalYearNum >=2014 )
OR	(Bankedstatus in ('Pipeline')  AND isnull(ad.FiscalYearNum,cd.FiscalYearNum) >= 2014)
OR (Bankedstatus in ('Received-GIK', 'Pledged-GIK')  AND cd.FiscalYearNum >=2014 )
-- filter out Declined, Awarded proposals etc


/*--Projected
	 ,GivingLevel			= (Case
		WHEN o.[ProjectedAmt]*(pa.[AllocationPct]/100)/[EstimatedDurationInYears]>= 25000 THEN '25K+'
		WHEN o.[ProjectedAmt]*(pa.[AllocationPct]/100)/[EstimatedDurationInYears] >= 1000 THEN '1K-24K'
																						ELSE 'Under 1K' END)
-- InKind
	,GivingLevel		=(CASE WHEN CAST(ia.IrcValuationAmt as int) >= 25000		THEN '25K+'
								WHEN CAST(ia.IrcValuationAmt as int) >= 1000		THEN '1K-24K'
																					ELSE 'Under 1K' END)
*/
;

GO

--------------------------------------------------------------------------------
------------------------------ End SQL statement -------------------------------
--------------------------------------------------------------------------------

/*
ENTER YOUR RESPONSE BELOW:





*/
