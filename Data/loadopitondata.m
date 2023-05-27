function loadopitondata()

 datafolder='C:\Spectrion\PriceData\Option_Generic\';

    MetaDat_spy=readtable(strcat(datafolder,'SPYOptionData.xlsx'),'Sheet','CleanData');
    ExpiryDate_spy=readtable(strcat(datafolder,'SPYOptionData.xlsx'),'Sheet','ExpiryDate'); ExpiryDate_spy=table2array(ExpiryDate_spy);
    Ivolcurve_2ndM_spy=table2array(MetaDat_spy(:,2:8));
    Ivolcurve_1stM_spy=table2array(MetaDat_spy(:,13:19));
    spy_price=table2array(MetaDat_spy(:,9:11));
    ty_price=table2array(MetaDat_spy(:,[20,10,11]));
    Datestamp_spy=table2array(MetaDat_spy(:,1));
    Vix_dat_spy=table2array(MetaDat_spy(:,12));
    save('C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\42. Sigmaa003_Enhanced\Data\SPYOptionData.mat',"ExpiryDate_spy","Ivolcurve_1stM_spy","Vix_dat_spy","Datestamp_spy","Ivolcurve_2ndM_spy",...
        "spy_price","ty_price");

    MetaDat_TLT=readtable(strcat(datafolder,'TLTOptionData.xlsx'),'Sheet','CleanData');
    ExpiryDate_tlt=readtable(strcat(datafolder,'TLTOptionData.xlsx'),'Sheet','ExpiryDate'); ExpiryDate_tlt=table2array(ExpiryDate_tlt);
    Ivolcurve_2ndM_tlt=table2array(MetaDat_TLT(:,2:8));
    Ivolcurve_1stM_tlt=table2array(MetaDat_TLT(:,13:19));
    tlt_price=table2array(MetaDat_TLT(:,9:11));
    ty_prices=table2array(MetaDat_TLT(:,[20,10,11]));
    Datestamp_tlt=table2array(MetaDat_TLT(:,1));
    Vix_dat_tlt=table2array(MetaDat_TLT(:,12));
    save('C:\Users\gly19\Dropbox\GU\1.Investment\4. Alphas (new)\42. Sigmaa003_Enhanced\Data\TLTOptionData.mat',"ExpiryDate_tlt","Ivolcurve_1stM_tlt","Vix_dat_tlt","Datestamp_tlt","Ivolcurve_2ndM_tlt",...
        "tlt_price","ty_prices");

   