function y=roundlookup_prod(Vix,VixThld,Leverage_step)

%VixThld has 3 values: 
% Min/Mid/Max where at each point, maximum, average, minimum leverage are set.
% Any VIX numbers in between are propotionally calculated for leverage
% ratio
%

%Vix_Thld=[13 25 50]; Leverge_step=[2 1 0];
n=length(Vix);
y=zeros(length(Vix),1);
Vix_Thld_min=VixThld(1); Vix_Thld_mid=VixThld(2); Vix_Thld_max=VixThld(3);
Leverage_max=Leverage_step(1); Leverage_mid=Leverage_step(2); Leverage_min=Leverage_step(3);

for i=1:n
    vix=Vix(i);

    if vix<Vix_Thld_min
        y(i)=Leverage_max;
    elseif vix<Vix_Thld_mid && vix>=Vix_Thld_min
        B=(Leverage_max-Leverage_mid)/(Vix_Thld_min-Vix_Thld_mid);
        C=Leverage_max-B*Vix_Thld_min;
        y(i)=B*Vix(i)+C;
    elseif vix<Vix_Thld_max && vix>=Vix_Thld_mid
        B=(Leverage_mid-Leverage_min)/(Vix_Thld_mid-Vix_Thld_max);
        C=Leverage_mid-B*Vix_Thld_mid;
        y(i)=B*Vix(i)+C;
    elseif vix>=Vix_Thld_max
        y(i)=Leverage_min;
    end
end

%% Option 2
% y=zeros(length(Vix),1);
% n=length(VixThld);
% m=length(Leverage_step);
% 
% if n~=m
%     error('Check threshold matrix');
% end
% Vix_Thld=[13 17 20 25 37 50]; Leverge_step=[2 1.5 1 0.5 0.25 0.1]; 
% 
% for i=n:-1:1
%     ix=Vix<VixThld(i);
%     y(ix)=Leverage_step(i);
% end

%% Option 3
% if n~=m
%     error('refTbl must be same size as lookupTbl');
% end
% 
% [LIA,LocAllB] = ismembertol(refTbl, x, 0.05, 'OutputAllIndices', true);
% 
% for i=1:n
%     y(LocAllB{i})=lookupTbl(i);
% end