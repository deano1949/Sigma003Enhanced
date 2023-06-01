function [OutputCollection] = sigmaa003_2023(spy_price,Ivolcurve1stm,Ivolcurve2ndm,Vix_dat,ExpiryDate,Datestamp,TradeOptionType,OptionMoneyness,dynamic_weight,Vix_Thld,Leverge_step)

%% Setting for trade simulation
Initial_AUM=200000;
Trading_cost_per_contract=0.3; %trading cost per contract
Leverage_lever=1; %Overall leverage control

%% Setup
StkPc=zeros(size(Datestamp,1),1);
Est_Ivol=zeros(size(Datestamp,1),1);
CallP=zeros(size(Datestamp,1),1);
PutP=zeros(size(Datestamp,1),1);
CallD=zeros(size(Datestamp,1),1);
PutD=zeros(size(Datestamp,1),1);
aum=zeros(size(Datestamp,1),1);
No_contract=zeros(size(Datestamp,1),1);
Daily_PNL=zeros(size(Datestamp,1),1);
PutOpt_pnl=zeros(size(Datestamp,1),1);
PNL_PI=zeros(size(Datestamp,1),1);
Tdiff=zeros(size(Datestamp,1),1);
leverage_ratio=zeros(size(Datestamp,1),1);
Trading_cost=zeros(size(Datestamp,1),1);
PutP_roll_TT=zeros(size(Datestamp,1),1);

%% Option Pricing
%risk free rate
Rf=spy_price(:,3)/100;

%Yield
Yld=spy_price(:,2)/100;


for i=1:size(Datestamp,1)
    T0=Datestamp(i);
    %find the expiry date of 2nd month option
    valid_date=ExpiryDate(ExpiryDate>T0); 
    if strcmp(TradeOptionType,'1stM')
        ExpDate(i)=valid_date(1);
    elseif strcmp(TradeOptionType,'2ndM')
        ExpDate(i)=valid_date(2);
    end
    
    Tdiff(i)=(datenum(ExpDate(i))-datenum(T0))/365; %Date to Expiry
    
    %Spot price
    SptPc=spy_price(i,1);

    %Strike Price
    if or(i==1,ismember(T0,ExpiryDate))
        if strcmp(OptionMoneyness,'90OTM') 
            StkPc(i)=floor(SptPc*0.9);
        elseif strcmp(OptionMoneyness,'95OTM') 
            StkPc(i)=floor(SptPc*0.95);
        elseif strcmp(OptionMoneyness,'97OTM') 
            StkPc(i)=floor(SptPc*0.97);
        elseif strcmp(OptionMoneyness,'ATM') 
            StkPc(i)=floor(SptPc);            
        elseif strcmp(OptionMoneyness,'103ITM') 
            StkPc(i)=floor(SptPc*1.03);
        elseif strcmp(OptionMoneyness,'105ITM') 
            StkPc(i)=floor(SptPc*1.05);
        elseif strcmp(OptionMoneyness,'110ITM') 
            StkPc(i)=floor(SptPc*1.1);
        end
    else
        StkPc(i)=StkPc(i-1);
    end

   

    %Implied Vol
    dis2spot=StkPc(i)/SptPc*100; %Moneyness
    if strcmp(TradeOptionType,'1stM')
        if ismember(T0,ExpiryDate)
            IvolCurve=Ivolcurve1stm(i+1,:); %Ivol curve of the date
        else
            IvolCurve=Ivolcurve1stm(i,:); %Ivol curve of the date
        end
    elseif strcmp(TradeOptionType,'2ndM')
        IvolCurve=Ivolcurve2ndm(i,:); %Ivol curve of the date
    end
    Money_level=[80 90 95 100 105 110 120];
    
    if dis2spot<=90
        Upendpt=IvolCurve(2);
        Lowendpt=IvolCurve(1);
        slope=(Upendpt-Lowendpt)/10;
        intercept=Upendpt-slope*90;
    elseif dis2spot<=95 && dis2spot>90
        Upendpt=IvolCurve(3);
        Lowendpt=IvolCurve(2);
        slope=(Upendpt-Lowendpt)/5;
        intercept=Upendpt-slope*95;        
    elseif dis2spot<=100 && dis2spot>95
        Upendpt=IvolCurve(4);
        Lowendpt=IvolCurve(3);
        slope=(Upendpt-Lowendpt)/5;
        intercept=Upendpt-slope*100;        
    elseif dis2spot<=105 && dis2spot>100
        Upendpt=IvolCurve(5);
        Lowendpt=IvolCurve(4);
        slope=(Upendpt-Lowendpt)/5;
        intercept=Upendpt-slope*105;             
    elseif dis2spot<=110 && dis2spot>105
        Upendpt=IvolCurve(6);
        Lowendpt=IvolCurve(5);
        slope=(Upendpt-Lowendpt)/5;
        intercept=Upendpt-slope*110;  
    elseif dis2spot>110
        Upendpt=IvolCurve(7);
        Lowendpt=IvolCurve(6);
        slope=(Upendpt-Lowendpt)/10;
        intercept=Upendpt-slope*120; 
    end

    Est_Ivol(i)=intercept+slope*dis2spot;

    %Option prices
    [CallP(i),PutP(i)]=blsprice(SptPc,StkPc(i),Rf(i),Tdiff(i),Est_Ivol(i)/100,Yld(i));
    %Option Delta
    [CallD(i),PutD(i)]=blsdelta(SptPc,StkPc(i),Rf(i),Tdiff(i),Est_Ivol(i)/100,Yld(i));


%% Trading simulation
%leverage ratio based on VIX (initial mapping)
leverage_ts=roundlookup(Vix_dat,Vix_Thld,Leverge_step);

if i==1
    aum(i)=Initial_AUM;
    Daily_PNL(i)=0;
    PutOpt_pnl(i)=0;
    PNL_PI(i)=100;
    leverage_ratio(i)=leverage_ts(i)*Leverage_lever; %leverage ratio
    No_contract(i)=floor(aum(i)/SptPc/100)*leverage_ratio(i);
else
    if ismember(T0,ExpiryDate)
        leverage_ratio(i)=leverage_ts(i)*Leverage_lever; %leverage ratio
        No_contract(i)=floor(aum(i-1)/SptPc/100)*leverage_ratio(i); %no of contracts
        [CallP_roll,PutP_roll]=blsprice(SptPc,StkPc(i-1),Rf(i-1),Tdiff(i-1),Est_Ivol(i-1)/100,Yld(i-1));%Price of a rolling option at rolling date
        PutP_roll_TT(i)=PutP_roll;%Exit put option price at the roll date
        PutOpt_pnl(i)=(-PutP_roll+PutP(i-1))*100; %single option's pnl

        if strcmp(TradeOptionType,'1stM')
            %no need to sell 1st month option
            Trading_cost(i)=-No_contract(i)*Trading_cost_per_contract;
        elseif strcmp(TradeOptionType,'2ndM')
            %sell the current options and open new options
            % so double trading cost
            Trading_cost(i)=-abs(No_contract(i-1)+No_contract(i))*Trading_cost_per_contract;
        end
    else
        if strcmp(dynamic_weight,'Decsend_only')
            leverage_ratio_temp=leverage_ts(i)*Leverage_lever;
            if leverage_ratio_temp<leverage_ratio(i-1)
                leverage_ratio(i)=leverage_ratio_temp;
            else
                leverage_ratio(i)=leverage_ratio(i-1);
            end   
            No_contract(i)=floor(No_contract(i-1)*leverage_ratio(i)/leverage_ratio(i-1));
        elseif strcmp(dynamic_weight,'Y')
            leverage_ratio(i)=leverage_ts(i)*Leverage_lever;
            No_contract(i)=floor(aum(i-1)/SptPc/100*leverage_ratio(i)); %no of contracts

        end

        if isnan(No_contract(i)) %avoid no_contract being zero
            No_contract(i)=0;
        end

        PutOpt_pnl(i)=(-PutP(i)+PutP(i-1))*100;
        Trading_cost(i)=-abs(No_contract(i-1)-No_contract(i))*Trading_cost_per_contract; %sell contracts due to de-risk
    end

    Daily_PNL(i)=No_contract(i-1)*PutOpt_pnl(i); % PNL of a portfolio
    aum(i)=aum(i-1)+Daily_PNL(i);
    PNL_PI(i)=aum(i)/Initial_AUM*100; %PNL price index
end

end
Exp=cellstr(ExpDate');%Expiry Date
OutputCollect=horzcat(StkPc,Est_Ivol,CallP,PutP,CallD,PutD,PutP_roll_TT);
OutputTableOptionPrice=array2table(OutputCollect,"VariableNames",{'StrikePrice','EstIVol','CallPrice','PutPrice','CallDelta','PutDelta','PutPrice_AtRoll'});
OutputTableOptionPrice=[OutputTableOptionPrice cell2table(Exp)];
OutputTableOptionPrice=table2timetable(OutputTableOptionPrice,'RowTimes',Datestamp);

TradeSimTable=horzcat(aum,No_contract,Daily_PNL,PutOpt_pnl,PNL_PI,Trading_cost,leverage_ratio);
TradeSimTable=array2timetable(TradeSimTable,'RowTimes',Datestamp,"VariableNames",{'AUM','No_contracts','Daily_PNL_$','Single_Opt_pnl','Price_Index','Trading_cost','Leverage_ratio'});


%% Performance measure
Dailyreturn=[0; tick2ret(TradeSimTable.Price_Index)];
Excessreturn=Dailyreturn-Rf/250;
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
OutputCollection.Setting={TradeOptionType,OptionMoneyness,Trading_cost_per_contract,Leverage_lever};
OutputCollection.LeverageSurface=array2table(transpose(vertcat(Vix_Thld,Leverge_step)),'VariableNames',{'Vix_Threshold','Leverage_steps'});
OutputCollection.OptionPrices=OutputTableOptionPrice;
OutputCollection.TradeSim=TradeSimTable;
OutputCollection.PerformanceStats=PerformanTbl;
OutputCollection.PerformanceTS=array2timetable([Dailyreturn Excessreturn Cumpnl],'RowTimes',Datestamp,'VariableNames',{'Dailyreturn','Excessreturn','Cumpnl'});

%save('OutputCollectionMat',"OutputCollection");
