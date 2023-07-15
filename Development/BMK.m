function [OutputCollection] = BMK(data_ts,Datestamp,BMKname)
BMK_PI=data_ts(:,1);
Rf=data_ts(:,3);


Dailyreturn=[0; tick2ret(BMK_PI)];
Excessreturn=Dailyreturn-Rf/250/100;
Cumpnl=cumprod(1+Dailyreturn)*100;

%Since inception (2005)
cumpnl_SI=prod(1+Dailyreturn)-1; %Accumulative PNL
apr_SI=prod(1+Dailyreturn).^(252/length(Dailyreturn))-1; %annualised returns since inception
sharperatio_SI=mean(Excessreturn)*sqrt(252)/std(Excessreturn); %sharpe ratio since inception
Volatility=std(Dailyreturn)*sqrt(252);
maxdd_SI=maxdrawdown(Cumpnl);
% 1Y
cumpnl_1Y=prod(1+Dailyreturn(end-252:end))-1; 
apr_1Y=prod(1+Dailyreturn(end-252:end)).^(252/length(Dailyreturn(end-252:end)))-1; 
sharperatio_1Y=mean(Excessreturn(end-252:end))*sqrt(252)/std(Excessreturn(end-252:end));
% 3Y
cumpnl_3Y=prod(1+Dailyreturn(end-252*3:end))-1; 
apr_3Y=prod(1+Dailyreturn(end-252*3:end)).^(252/length(Dailyreturn(end-252*3:end)))-1; 
sharperatio_3Y=mean(Excessreturn(end-252*3:end))*sqrt(252)/std(Excessreturn(end-252*3:end)); 
% 5Y
cumpnl_5Y=prod(1+Dailyreturn(end-252*5:end))-1; 
apr_5Y=prod(1+Dailyreturn(end-252*5:end)).^(252/length(Dailyreturn(end-252*5:end)))-1; 
sharperatio_5Y=mean(Excessreturn(end-252*5:end))*sqrt(252)/std(Excessreturn(end-252*5:end)); 


PerformanTbl=array2table([cumpnl_SI apr_SI sharperatio_SI Volatility maxdd_SI cumpnl_1Y apr_1Y sharperatio_1Y ...
    cumpnl_3Y apr_3Y sharperatio_3Y cumpnl_5Y apr_5Y sharperatio_5Y],'VariableNames',{'Total_return_SI','APR_SI','SharpeRatio_SI','Volatility','MaxDrawdown_SI',...
    'Total_return_1Y','APR_1Y','SharpeRatio_1Y','Total_return_3Y','APR_3Y','SharpeRatio_3Y','Total_return_5Y','APR_5Y','SharpeRatio_5Y'});

OutputCollection=struct;
OutputCollection.Setting={'BMK',BMKname,'Long_only','No_Leverage'};
OutputCollection.PerformanceStats=PerformanTbl;
OutputCollection.PerformanceTS=array2timetable([Dailyreturn Excessreturn Cumpnl],'RowTimes',Datestamp,'VariableNames',{'Dailyreturn','Excessreturn','Cumpnl'});


