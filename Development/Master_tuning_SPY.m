%% Setting
clc;clear;

loaddata='N';
TradeOptionType_range={'1stM','2ndM'};%1stM
OptionMoneyness_range={'95OTM','97OTM','ATM','103ITM','105ITM'};%Trade 90OTM 95OTM ATM 105ITM 110ITM
dynamic_weight='Y'; %'Decsend_only'; 'Y'
dynamic_weight_type_range={'FixedLeverage1',...
    'FixedLeverage1.5','FixedLeverage1.8','FixedLeverage2.5',...
    'YueDieYueSell210','YueDieYueSell1.510','YueDieYueSell21.50','YueDieYueSell2.51.80','YueDieYueSell320'};

%Output setting
Todaystamp=datestr(today,'YYYY_mm_DD');
OutputExcel=['Tuning_output\Master_tuning_output_SPY' Todaystamp '.xlsx'];
%% Get data & Setting
if strcmp(loaddata,'Y')
    addpath('C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\42. Sigmaa003_Enhanced\Sigmaa003_Enhanced\Data');
    loadopitondata();
end

load('C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\42. Sigmaa003_Enhanced\Sigmaa003_Enhanced\Data\SPYOptionData.mat');


%% Load BMK
OutputCollection_BMK = BMK(spy_price,Datestamp_spy,'SPY');
OutputCollection_TY = BMK(ty_price,Datestamp_spy,'TY10');

Master_tuning_output=struct;
CollectionTable=OutputCollection_BMK.PerformanceStats;
CollectionCumpnl=OutputCollection_BMK.PerformanceTS.Cumpnl;

CollectionTable=vertcat(CollectionTable,OutputCollection_TY.PerformanceStats);
CollectionCumpnl=horzcat(CollectionCumpnl,OutputCollection_TY.PerformanceTS.Cumpnl);
CollectionTable.Properties.RowNames={'BMK','TY10'};

%% Loops start here
for i=1:size(TradeOptionType_range,2)
    TradeOptionType=TradeOptionType_range{i};

    %% Trade 1st or 2nd Month Expiring options
    if strcmp(TradeOptionType,'1stM')
        Ivolcurve=Ivolcurve_1stM_spy;
    elseif strcmp(TradeOptionType,'2ndM')
        Ivolcurve=Ivolcurve_2ndM_spy;
    end

    for j=1:size(OptionMoneyness_range,2)
        OptionMoneyness=OptionMoneyness_range{j};

        for k=1:size(dynamic_weight_type_range,2)
            dynamic_weight_type=dynamic_weight_type_range{k};

            %% Setting for trade simulation can be found in sigmaa003_2023.m
            %Below is the default numbers
            % Initial_AUM=200000;
            Trading_cost_per_contract=0.3; %trading cost per contract
            Leverage_lever=1; %Overall leverage control

            %% Dyanmics weighting options
            switch dynamic_weight_type
                case 'YueDieYueBuy112' %(YDYBuy越跌越买
                    Vix_Thld=[13 20 50]; Leverge_step=[1 1 2];
                case 'YueDieYueBuy111.5' %
                    Vix_Thld=[13 20 50]; Leverge_step=[1 1.5 2];
                case 'FixedLeverage1' %
                    Vix_Thld=[13 20 50]; Leverge_step=[1 1 0];
                case 'FixedLeverage1.5' %
                    Vix_Thld=[13 20 50]; Leverge_step=[1.5 1.5 0];
                case 'FixedLeverage1.8' %
                    Vix_Thld=[13 20 50]; Leverge_step=[1.8 1.8 0];
                case 'FixedLeverage2.5' %
                    Vix_Thld=[13 20 50]; Leverge_step=[2.5 2.5 0];
                case 'YueDieYueSell210' %
                    Vix_Thld=[13 20 50]; Leverge_step=[2 1 0];
                case 'YueDieYueSell1.510' %
                    Vix_Thld=[13 20 50]; Leverge_step=[1.5 1 0];
                case 'YueDieYueSell21.50' %
                    Vix_Thld=[13 20 50]; Leverge_step=[2 1.5 0];
                case 'YueDieYueSell2.51.80' %
                    Vix_Thld=[13 20 50]; Leverge_step=[2.5 1.8 0];
                case 'YueDieYueSell320' %
                    Vix_Thld=[13 20 50]; Leverge_step=[3 2 0];
                otherwise
                    error('choose dynamic_weight_type');
            end


            %% Main line
            [OutputCollection] = sigmaa003_2023(spy_price,Ivolcurve_1stM_spy,Ivolcurve_2ndM_spy,Vix_dat_spy,ExpiryDate_spy,Datestamp_spy,TradeOptionType,OptionMoneyness,dynamic_weight,Vix_Thld,Leverge_step);
            loop_name=[ 'L_' TradeOptionType '_' OptionMoneyness '_' dynamic_weight_type];
            loop_name=strrep(loop_name,'.','_');
            Master_tuning_output.(loop_name)=OutputCollection;

            save(['Tuning_output\Master_tuning_output_' Todaystamp '.mat'],"Master_tuning_output","-mat");

            CollectionRowName=vertcat(CollectionTable.Properties.RowNames,loop_name);
            CollectionTable=vertcat(CollectionTable,OutputCollection.PerformanceStats);
            CollectionCumpnl=horzcat(CollectionCumpnl,OutputCollection.PerformanceTS.Cumpnl);
            CollectionTable.Properties.RowNames=CollectionRowName;
        end
    end
end
CollectionCumpnl=array2timetable(CollectionCumpnl,"RowTimes",Datestamp_spy,'VariableNames',CollectionRowName);
writetable(CollectionTable,OutputExcel,'WriteRowNames',true,'Sheet','StatsTable','UseExcel',1);
writetimetable(CollectionCumpnl,OutputExcel,'Sheet','CumPNLTS','UseExcel',1);