function [d] = hitsDistriDiverg(N, hashGroupCnt, experi_hitsDistri)
%to calculate the theoretical hit distribution, only compute the first m probabilities, where m is the length of experi_hitsDistri
m = length(experi_hitsDistri);
theor_hitsDistri = zeros(1,m);
    %to calculate P^t(\omega)
    for j = 1 : m  % to calculate the probability that there are j-1 hits
         theor_hitsDistri(j) = nchoosek(hashGroupCnt,j-1)*(1/2^8)^(j-1)*(1-1/2^8)^(hashGroupCnt-j+1);%each probability should not equal 0
    end
    %disp('the experimental hit distribution：');
    %disp(experi_hitsDistri/N);
    
    if sum(experi_hitsDistri)~=N 
        disp ('the sum of the experimental hit distribution does not equals 1!')
    end
    %disp('the theoretical hit distribution:');
    %disp(theor_hitsDistri);
    %to compute Kullback–Leibler divergence
    d = 0;
    for j = 1 : m
        if experi_hitsDistri(j) ~= 0
            experiProb = experi_hitsDistri(j)/N;
            d = d + (experiProb)*log2(experiProb / theor_hitsDistri(j));
        end
    end
end