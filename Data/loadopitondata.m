function loadopitondata()

datafolder='C:\Spectrion\PriceData\Option_Generic\';

%ExpiryDate data
ExpiryDate_spy=readtable(strcat(datafolder,'SPYOptionData.xlsx'),'Sheet','ExpiryDate'); ExpiryDate_spy=table2array(ExpiryDate_spy);
ExpiryDate_tlt=ExpiryDate_spy;

%BBG data start date and end date
fromdate='01/10/2005';
todate=datestr(today()-1,'mm/dd/yyyy');

%SPY Option Data
spy_price=bbggethistdata({'SPY US Equity'},{'PX_LAST','DIVIDEND_INDICATED_YIELD'},fromdate,todate,'daily',[]);
Time=datetime(spy_price.timestamp,'InputFormat','dd/MM/yyyy');
spy_price=timetable(Time,spy_price.PX_LAST.SPY_US_Equity,spy_price.DIVIDEND_INDICATED_YIELD.SPY_US_Equity);
spy_price.Properties.VariableNames={'SPX_LAST','SPX_DIVIDEND_INDICATED_YIELD'};

%TLT US Equity
tlt_price=bbggethistdata({'TLT US Equity'},{'PX_LAST','DIVIDEND_INDICATED_YIELD'},fromdate,todate,'daily',[]);
Time=datetime(tlt_price.timestamp,'InputFormat','dd/MM/yyyy');
tlt_price=timetable(Time,tlt_price.PX_LAST.TLT_US_Equity,tlt_price.DIVIDEND_INDICATED_YIELD.TLT_US_Equity);
tlt_price.Properties.VariableNames={'TLT_LAST','TLT_DIVIDEND_INDICATED_YIELD'};

%risk free rate
rf_rate=bbggethistdata({'US0003M Index'},{'PX_LAST'},fromdate,todate,'daily',[]);
Time=datetime(rf_rate.timestamp,'InputFormat','dd/MM/yyyy');
rf_rate=table2timetable(rf_rate.PX_LAST,"RowTimes",Time);

%TY rate (10Y treasury)
TY_rate=bbggethistdata({'TY1 Comdty'},{'PX_LAST'},fromdate,todate,'daily',[]);
Time=datetime(TY_rate.timestamp,'InputFormat','dd/MM/yyyy');
TY_rate=table2timetable(TY_rate.PX_LAST,"RowTimes",Time);

%VIX price
vix=bbggethistdata({'VIX Index'},{'PX_LAST'},fromdate,todate,'daily',[]);
Time=datetime(vix.timestamp,'InputFormat','dd/MM/yyyy');
vix=table2timetable(vix.PX_LAST,"RowTimes",Time);

Clean_Data=synchronize(spy_price,tlt_price,rf_rate,TY_rate,vix,'union','previous');

%option IVOL curves
SPY_Clean_Data=Clean_Data;
Maturity_type={'MATURITY_2NDM','MATURITY_1STM'};
   Moneyness_lvl_type={'MONEY_LVL_80_0','MONEY_LVL_90_0','MONEY_LVL_95_0','MONEY_LVL_100_0','MONEY_LVL_105_0','MONEY_LVL_110_0','MONEY_LVL_120_0'};

   for i=1:length(Maturity_type)
       for j=1:length(Moneyness_lvl_type)
           overridefld={'overrideFields',{'IVOL_MONEYNESS_LEVEL',Moneyness_lvl_type{j}},'overrideFields',{'IVOL_MATURITY',Maturity_type{i}}};
           fldname=strcat(Moneyness_lvl_type{j},'_',Maturity_type{i});
           fulldat = bbggetoptcurve({'SPY US Equity'},{'IVOL_MONEYNESS'},fromdate,todate,'daily',overridefld);
           fulldat.Properties.VariableNames={fldname};
           SPY_Clean_Data=synchronize(SPY_Clean_Data,fulldat);

       end
   end

%% TLT Option data
TLT_Clean_Data=Clean_Data;
   for i=1:length(Maturity_type)
       for j=1:length(Moneyness_lvl_type)
           overridefld={'overrideFields',{'IVOL_MONEYNESS_LEVEL',Moneyness_lvl_type{j}},'overrideFields',{'IVOL_MATURITY',Maturity_type{i}}};
           fldname=strcat(Moneyness_lvl_type{j},'_',Maturity_type{i});
           fulldat_tlt = bbggetoptcurve({'TLT US Equity'},{'IVOL_MONEYNESS'},fromdate,todate,'daily',overridefld);
           fulldat_tlt.Properties.VariableNames={fldname};
           TLT_Clean_Data=synchronize(TLT_Clean_Data,fulldat_tlt);
       end
   end


%% save data
Todaystamp=datestr(today(),'yyyy_mm_dd');  
save([datafolder 'backupdata\OptionRawData_' Todaystamp '.mat'],"SPY_Clean_Data","TLT_Clean_Data","-mat");
save([datafolder 'OptionRawData.mat'],"SPY_Clean_Data","TLT_Clean_Data","-mat");

Ivolcurve_2ndM_spy=table2array(SPY_Clean_Data(:,8:14));
Ivolcurve_1stM_spy=table2array(SPY_Clean_Data(:,15:21));
spy_price=table2array(SPY_Clean_Data(:,[1,2,5]));
ty_price=table2array(SPY_Clean_Data(:,[6,2,5]));
Datestamp_spy=SPY_Clean_Data.Time;
Vix_dat_spy=table2array(SPY_Clean_Data(:,7));
save('C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\42. Sigmaa003_Enhanced\Sigmaa003_Enhanced\Data\SPYOptionData.mat',"ExpiryDate_spy","Ivolcurve_1stM_spy","Vix_dat_spy","Datestamp_spy","Ivolcurve_2ndM_spy",...
   "spy_price","ty_price");

Ivolcurve_2ndM_tlt=table2array(TLT_Clean_Data(:,8:14));
Ivolcurve_1stM_tlt=table2array(TLT_Clean_Data(:,15:21));
tlt_price=table2array(TLT_Clean_Data(:,[3,4,5]));
Datestamp_tlt=TLT_Clean_Data.Time;
Vix_dat_tlt=table2array(TLT_Clean_Data(:,7));
save('C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\42. Sigmaa003_Enhanced\Sigmaa003_Enhanced\Data\TLTOptionData.mat',"ExpiryDate_tlt","Ivolcurve_1stM_tlt","Vix_dat_tlt","Datestamp_tlt","Ivolcurve_2ndM_tlt",...
    "tlt_price","ty_price");
