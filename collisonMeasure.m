%To measure the divergence between experimental and theoretical
%distributions of hits
hashLens = [296,264,221,200,195,136,120,296,264,264,221,200,195,128];
collidDraws = zeros(14,5);% to store W_N^e(\omega) for 14 hash functions
%the former 7 are for the instances of QHFM 
collidDraws(1,:) = [8605,1312,81,2,0];
collidDraws(2,:) = [8762,1159,74,5,0];
collidDraws(3,:) = [8674,1230,93,3,0];
collidDraws(4,:) = [9071,895,34,0,0];
collidDraws(5,:) = [8066,1796,130,8,0];
collidDraws(6,:) = [9352,626,21,1,0];
collidDraws(7,:) = [9416,570,13,1,0];
%The latter 7 are for the existing schemes
collidDraws(8,:) = [8321,1547,110,22,0];
collidDraws(9,:) = [9019,923,52,2,4];
collidDraws(10,:) = [8904,1026,68,2,0];
collidDraws(11,:) = [9854,71,0,0,75];
collidDraws(12,:) = [8982,989,25,4,0];
collidDraws(13,:) = [16063,314,6,0,0];
collidDraws(14,:) = [9367,617,16,0,0];

D=zeros(1,14);%to store the Kullback-Leibler divergences
for h = 1 : 14
    disp(['--- To calculate the Kullback-Leibler divergence for the ',num2str(h),'th hash function ---']);
    if h == 13
        D(1,h) = hitsDistriDiverg(16383,ceil(hashLens(h)/8),collidDraws(h,:));
    else
        D(1,h) = hitsDistriDiverg(10000,ceil(hashLens(h)/8),collidDraws(h,:));
    end
end
format long;
disp(D);

%the values of W_N^e(\omega) for each hash function
% theoCollidDraws=zeros(14,5);
% for h=1:14
%     hashGroupCnt=ceil(hashLens(h)/8);
%     for j = 1 : hashGroupCnt+1
%         if h == 13
%             theoCollidDraws(h,j) = round(16383 * nchoosek(hashGroupCnt,j-1)*(1/2^8)^(j-1)*(1-1/2^8)^(hashGroupCnt-j+1));
%         else
%             theoCollidDraws(h,j) = round(10000 * nchoosek(hashGroupCnt,j-1)*(1/2^8)^(j-1)*(1-1/2^8)^(hashGroupCnt-j+1));
%         end
%     end
% end
% disp(theoCollidDraws(:,1:5))