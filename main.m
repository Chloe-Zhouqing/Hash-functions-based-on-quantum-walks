%% prepare connection to database
conn = database(datasourceName,username,password); %put your own datasource name (such as 'MySQL ODBC Data Source'), username, and password here
 
%Set query to execute on the database.
%Count the totol number of records, this will take a few minites. 
%One can also count the number of records using MySQL Workbench, delete the first query below, and insert
%the counted result, say, 1796911 (inplace of num2str(recordsCount)) into
%the second query.
% query = 'SELECT count(id) AS recordsCnt FROM db_test.tb_arxiv';
% data = fetch(conn,query);
% recordsCount = uint32(data.recordsCnt(1:1)); % get the value of 'recordsCnt', data type:uint32
% disp(['There are ',num2str(recordsCount),' records in the arXiv Dataset']);

%Randomly choose a record (the metadata for an article), extract the
%  abstract from the column 'doc' using MySQL X DevAPI.
% query = ['SELECT id, doc->''$.abstract'' AS abstract FROM db_test.tb_arxiv AS t ' ...
%     '     INNER JOIN ' ...
%     '       (SELECT ROUND(RAND() * ',num2str(recordsCount),') AS randomID) AS x ' ... 
%     '     WHERE t.id >= x.randomID LIMIT 1; ' ...
%     ''];

%Randomly choose a record with known record count, i.e., recordsCount=1796911
query = ['SELECT id, doc->''$.abstract'' AS abstract FROM db_test.tb_arxiv AS t ' ...
    '     INNER JOIN ' ...
    '       (SELECT ROUND(RAND() * 1796911) AS randomID) AS x ' ... %There are 1796911 records in table 'db_test'
    '     WHERE t.id >= x.randomID LIMIT 1; ' ...
    ''];

hashFuncCnt = 7;% ==※※※== the number of QHFM instances that will be tested and compared 
%% assign values to parameters of quantum walk based hash functions 
%qwalk hash instance list: 1. QHFM-296; 2. QHFM-264; 3. QHFM-221; 4. QHFM-200; 5. QHFM-195; 6. QHFM-136; 7. QHFM-120.
N = 10000; % the number of draws for each hash function. It is suggested to decrease the value of N to 10 for the first test. When N=10000, it will take more than half an hour.
coinParams = [pi/3,pi/5;pi/3,pi/5;pi/3,pi/5;pi/3,pi/5;pi/3,pi/5;pi/3,pi/5;pi/3,pi/5]; %==※※※==coinParams(h,:) is the parameters of the coin operators adopted by the hth hash function
% nodesCnt(h,1) is to store the size (the number of nodes) of the ring adopted by the hth hash function
nodesCnt = [37;33;17;25;15;17;15]; %==※※※== nodesCnt(*,1) is denoted by 'n' in the article  [33;17]
% hashBitsCntPerNode(h,1) is to store the number of hash bits contributed by each node in the hth hash function
hashBitsCntPerNode = [8;8;13;8;13;8;8]; %==※※※== hashBitsCntPerNode(*,1) is denoted by 'm' in the article [8;13]
% hashLen(h,1) is to store the bit length of the hash result of the hth hash function
hashLen = nodesCnt.*hashBitsCntPerNode;
% probDigitsCntInUse(h,1) is to store the number of decimal digits (within the probability value on each node) that will
%    be used for calculating a hash component in the hth hash function
probDigitsCntInUse = [8;8;8;8;8;8;8]; %==※※※==

% initiate outcome variables of the hash test
diffHashBitsCnts = zeros(hashFuncCnt,N);% diffHashBitsCnts(h,i) is to store the number of different bits at same positions in the new and the original hash values on the ith draw for the hth hash function (for the avalanche effect)
% fliptTrialCnt{h,1}(1,j) is to store the number of draws (for the hth hash function) wherein the new hash value differs from the original one at the jth binary digit (for the strict avalanche effect)
fliptTrialCnt = cell(hashFuncCnt,1);
for h = 1 : hashFuncCnt
    fliptTrialCnt{h,1} = zeros(1,hashLen(h,1));
end
hashGroupCnt = ceil(hashLen./8);% hashGroupCnt(h,1) is to store the number of hash segments (the number of groups within a hash value) in the hth hash function
collidCnts = zeros(hashFuncCnt,N);% collidCntsto(h,i) is to store the number of colliding groups on the ith draw for the hth hash function (for collision analysis)
absDiffsPerByte = zeros(hashFuncCnt,N);% absDiffs( h,i) is to store absolute differences on the ith draw for the hth hash function (for collision analysis)
max_absDiffPerByte = zeros(hashFuncCnt,1);
min_absDiffPerByte = zeros(hashFuncCnt,1);

for i = 1 : N % to make the ith draw / to perform the ith trial
    %% Execute query, fetch a record id and the corresponding abstract of a random record
    disp(['===== draw: ',num2str(i),' =====']);
    data = fetch(conn,query);
    randId = uint32(data.id(1:1)); % extract the id value; data type:uint32
    randAbstract = cell2mat(data.abstract(1:1));% extract the abstract value; data type: char array
    truncAbstract = randAbstract(4:end-3);%remove the double quotes before and after the abstract content, delete the blanks before the abstract, remove '\n' after the abstract content.
    %
    %%%------ 1 intermediate checks (begin) ------%%%
    %disp('input message:');
    %disp(truncAbstract);
    %%%------ 1 intermediate checks (end) ------%%%
    %
    %% Convert the abstract into the binary input message
    msgCodes = double(truncAbstract);%code values (ASCII or Unicode values) of the input message (the abstract); data type: double array
    binMsg = '';%to store the binary representation of the input message; data type: char array
    msgCharCnt = length(msgCodes);% the number of chars of the input message
    for j = 1:msgCharCnt
        binMsg = strcat(binMsg,dec2bin(msgCodes(j)));
    end

    %% Perform each quantum walk based hash function
    %randomly flip a bit within binMsg and then generate a new binary message binMsgNew
    binMsgNew = binMsg;%binMsgNew is to store the new message after a random bit-flip
    binMsgLen = length(binMsg);%the length of the binary message
    flipIdx = randi(binMsgLen);
    if strcmp(binMsgNew(flipIdx),'0')
        binMsgNew(flipIdx) = '1';
    else
        binMsgNew(flipIdx) = '0';
    end
    
    %run each qwalk based hash function on binMsg and binMsgNew, respectively
    origHash = cell(hashFuncCnt,1);% origHash{h,1} is to store the hash result of the hth hash function on the original message; origHash{h,1} is a numeric array of nodesCnt(h,1) elements
    newHash = cell(hashFuncCnt,1);% newHash{h,1} is to store the new result of the hth hash function on the new message; a numeric array of nodesCnt(h,1) elements
    for h = 1 : hashFuncCnt
        disp(['    To run the ', num2str(h), 'th hash fucntion on the original message...']);
        origHash{h,1} = QHFM12(coinParams(h,1), coinParams(h,2), nodesCnt(h,1), hashBitsCntPerNode(h,1),probDigitsCntInUse(h,1),binMsg);
        disp(['    To run the ', num2str(h), 'th hash fucntion on the modified message...']);
        newHash{h,1} = QHFM12(coinParams(h,1), coinParams(h,2), nodesCnt(h,1), hashBitsCntPerNode(h,1),probDigitsCntInUse(h,1),binMsgNew); 
    end 
    
    %% ====== collect the one-draw data for each hash function (for the avalanche effect) ======
    binHash = cell(hashFuncCnt,1);
    binHashNew = cell(hashFuncCnt,1);
    % binHashXor{h,1} is to store the XOR result of the binary representations of origHash{h,1} and newHash{h,1}; 
    binHashXor = cell(hashFuncCnt,1);%Note that binHashXor is a numerical array (rather than a char array) of length hashLen(h,1), each element equals 0 or 1.
    for h = 1 : hashFuncCnt% to get the binary results (binHash{h,1},binHashnew{h,1}) of the hth hash function on the original and the new message, as well as binHash{h,1} XOR binHashnew{h,1}
        binHash{h,1} = '';% binHash{h,1} is to store the binary representation of origHash{h,1}; a char array of length hashLen(h,1), each char equals '0' or '1'
        binHashNew{h,1} = '';% binHashNew{h,1} is to store the binary representation of newHash{h,1}
        for j = 1 : nodesCnt(h,1)
            binHash{h,1} = strcat(binHash{h,1},dec2bin(origHash{h,1}(1,j),hashBitsCntPerNode(h,1)));
            binHashNew{h,1} = strcat(binHashNew{h,1},dec2bin(newHash{h,1}(1,j),hashBitsCntPerNode(h,1)));
        end
        % note that '1'-'0'=1 and '0'-'0'=0
        binHashXor{h,1} = abs(binHash{h,1} - binHashNew{h,1});
        diffHashBitsCnts(h,i) = sum(binHashXor{h,1}); %count the number of different bits at same positions in the binary representations of origHash{1,1} and newHash{1,1}
    end
    
    %% === collect the one-draw data for each hash function (for the strict avalanche effect) ===
    for h = 1 : hashFuncCnt
        fliptTrialCnt{h,1} = binHashXor{h,1} + fliptTrialCnt{h,1};
    end
    
    %% === collect the one-draw data for each hash function (for collision analysis) ===
    %%%%%%sameGroupRecogStr = dec2bin(0,8);%the pattern '00000000' is used to recognize identical groups at same positions in binary representations of origHash and newHash
    %collidCnts(h,i) is the number of colliding groups within binHash{h,1} and
    %  binHashNew{h,1} on the ith draw for the hth hash function.
    for h = 1 : hashFuncCnt
        disp(['    Collect the one-draw collision data of the ', num2str(h), 'th hash function...']);
        [collidCnts(h,i),absDiffsPerByte(h,i)] = collisionPerTrial(8, binHash{h,1}, binHashNew{h,1});
    end
    
end
for h = 1 : hashFuncCnt
    max_absDiffPerByte(h,1) = max(absDiffsPerByte(h,:));
    min_absDiffPerByte(h,1) = min(absDiffsPerByte(h,:));
end

%% === calculate the statistical properties for the avalanche effect ===
avgCnt_diffHashBits = zeros(hashFuncCnt,1);%avgCnt_diffHashBits(h,1) is to store the mean number of changed hash bits on a draw on the hth hash function, denoted by '\bar{B}' in the article
avgPerc_diffHashBits = zeros(hashFuncCnt,1);% avgPerc_diffHashBits(h,1) is to store the mean percentage of changed hash bits in a draw on the hth hash function, i.e. 'P' in the article
varinCnt_diffHashBits = zeros(hashFuncCnt,1);% varinCnt_diffHashBits(h,1) is to store the standard variation of the changed hash bit number of the hth hash function,i.e. '\Delta B' in the article
varinPerc_diffHashBits = zeros(hashFuncCnt,1);% varinPerc_diffHashBits(h,1) is to store the standard variation of the changed percentage of the hth hash function,i.e. '\Delta P' in the article
for h = 1 : hashFuncCnt
    avgCnt_diffHashBits(h,1) = sum(diffHashBitsCnts(h,:))/N;
    avgPerc_diffHashBits(h,1) = avgCnt_diffHashBits(h,1)/hashLen(h,1);
    varinCnt_diffHashBits(h,1) = sqrt(sum((diffHashBitsCnts(h,:) - avgCnt_diffHashBits(h,1)).^2)/(N-1));
    varinPerc_diffHashBits(h,1) = sqrt(sum((diffHashBitsCnts(h,:)./hashLen(h,1) - avgPerc_diffHashBits(h,1)).^2)/(N-1));
end

%% === calculate the statistical properties for the strict avalanche effect ===
avgCnt_fliptTrial = zeros(hashFuncCnt,1);% avgCnt_fliptTrial(h,1) is to store the mean number of draws (for the hth hash function) on which the hash bit changed at a fixed position, i.e. '\bar{T}' in the article
avgPerc_fliptTrial = zeros(hashFuncCnt,1); % avgPerc_fliptTrial(h,1) is to store the mean percentage of draws (for the hth hash function) on which the new hash bit differs from the original one at a given position, i.e. "Q"
varinCnt_fliptTrial = zeros(hashFuncCnt,1);% varinCnt_fliptTrial(h,1) is to store the standard variation of the number of draws (for the hth hash function) on which the hash bit changed at a fixed position, i.e. '\Delta T'
varinPerc_fliptTrial = zeros(hashFuncCnt,1);% varinPerc_fliptTrial(h,1) is to store the standard variation of the percentage of draws (for the hth hash function) on which the hash bit changed at a fixed position, i.e. "\Delta Q"
for h = 1 : hashFuncCnt
    avgCnt_fliptTrial(h,1) = sum(fliptTrialCnt{h,1}(1,:))/hashLen(h,1);%mean number of draws with changed bits
    avgPerc_fliptTrial(h,1) = avgCnt_fliptTrial(h,1)/N;% mean percentage of draws with changed bits
    varinCnt_fliptTrial(h,1) = sqrt(sum((fliptTrialCnt{h,1}(1,:)-avgCnt_fliptTrial(h,1)).^2)/(hashLen(h,1)-1));% standard deviation of the number of draws with changed bits
    varinPerc_fliptTrial(h,1) = sqrt(sum((fliptTrialCnt{h,1}(1,:)./N-avgPerc_fliptTrial(h,1)).^2)/(hashLen(h,1)-1));%standard deviation of the percentage of draws with changed bits
end

%% === calculate the statistical properties for collision analysis ===  
cnts_collidTrials = cell(hashFuncCnt,1);
for h = 1 : hashFuncCnt
    tempArray = zeros(1,N);% j=0
    cnts_collidTrials{h,1} = zeros(1,hashGroupCnt(h,1)+1);%cnt_collidTrials{h,1}(1,j) counts the number of draws (for the hth hash function) on which origHash and newHash have j-1 identical groups
    cnts_collidTrials{h,1}(1,1) = sum(eq(collidCnts(h,:),tempArray));% the number of draws (for the hth hash function) where no collision occurs
    for j = 1 : hashGroupCnt(h,1) %to count the number of draws (on the hth hash function) where j collision(s) occur(s)
        tempArray(1:N) = j;
        cnts_collidTrials{h,1}(1,j+1) = sum(eq(collidCnts(h,:),tempArray));
    end
end
%
%%%------ 2 intermediate checks (begin) ------%%%
for h = 1 : hashFuncCnt
    if sum(cnts_collidTrials{h,1}(1,:)) ~= N
        disp(['the total number of draws (on the ', num2str(h),'th hash function) with or without collision is not equivalent to N, it equals',num2str(sum(cnts_collidTrials{h,1}(1,:))),'!']);
    end
end
%%%------ 2 intermediate checks (end) ------%%%
%
%calculate the theoretical number of draws where there are j-1 colliding
%    groups at same positions in binHash and binHashNew
theorCnts_collidTrials = cell(hashFuncCnt,1);
for h = 1 : hashFuncCnt
    theorCnts_collidTrials{h,1} = zeros(1,hashGroupCnt(h,1)+1);
    for j = 1 : hashGroupCnt(h,1) + 1
        theorCnts_collidTrials{h,1}(1,j) = round(N * nchoosek(hashGroupCnt(h,1),j-1)*(1/2^8)^(j-1)*(1-1/2^8)^(hashGroupCnt(h,1)-j+1));
    end
end


% % % % % disp(['experimental number of draws with 0 to',num2str(hashGroupCnt),' hits：']);
% % % % % disp(cnts_collidTrials);
% % % % % disp(['theoretical number of draws with 0 to',num2str(hashGroupCnt),' hits：'])
% % % % % disp(theorCnts_collidTrials);

%calculate the experimental and theoretical absolute differences of each hash function
avg_absDiffPerByte = zeros(hashFuncCnt,1);
theo_absDiffPerByte = 85.33;
%%%theo_absDiffPerByte = zeros(hashFuncCnt,1);
for h = 1 : hashFuncCnt
    avg_absDiffPerByte(h,1) = sum(absDiffsPerByte(h,:))/N;
    %%%theo_absDiffPerByte(h,1) = (1/3)*((2^8-1)*floor(hashLen(h,1)/8)+2^mod(hashLen(h,1),8)-1);
end
% % % % % disp(['the average absolute difference：',num2str(avg_absDiff),'；the theoretical value：',num2str(theo_absDiff)]);

%% === output the test results for all hash functions in a table  ===
tbSize = [hashFuncCnt,30];
tbVarNames = {'hashFuncName','coinParams1','coinParams2','n','m','l','avgB','P(%)','|P-0.5|(%)','deltaB','deltaP','avgT','Q(%)','deltaT','deltaQ','W_N(0)','W_N(1)','W_N(2)','W_N(3)','W_N(4+)','W_N^0(0)','W_N^0(1)','W_N^0(2)','W_N^0(3)','W_N^0(4+)','avgd_byte','avgd_byte^t','|avgd_byte-avgd_byte^t|','max_d_byte','min_d_byte'};
tbVarTypes = {'string','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double','double'};
hashTestResults = table('Size',tbSize, 'VariableTypes',tbVarTypes,'VariableNames',tbVarNames);
hashTestResults(:,'hashFuncName') = {'QHFM-296';'QHFM-264';'QHFM-221';'QHFM-200';'QHFM-195';'QHFM-136';'QHFM-120'}; % ==※※※==
hashTestResults(:,'coinParams1') = num2cell(rad2deg(coinParams(:,1)));
hashTestResults(:,'coinParams2') = num2cell(rad2deg(coinParams(:,2)));
hashTestResults(:,'n') = num2cell(nodesCnt);
hashTestResults(:,'m') = num2cell(hashBitsCntPerNode);
hashTestResults(:,'l') = num2cell(probDigitsCntInUse);
hashTestResults(:,'avgB') = num2cell(avgCnt_diffHashBits);
hashTestResults(:,'P(%)') = num2cell(100*avgPerc_diffHashBits);
hashTestResults(:,'|P-50%|(%)') = num2cell(abs(100*avgPerc_diffHashBits-50));
hashTestResults(:,'deltaB') = num2cell(varinCnt_diffHashBits);
hashTestResults(:,'deltaP (%)') = num2cell(100*varinPerc_diffHashBits);
hashTestResults(:,'avgT') = num2cell(avgCnt_fliptTrial);
hashTestResults(:,'Q(%)') = num2cell(100*avgPerc_fliptTrial);%Q always equals P
hashTestResults(:,'deltaT') = num2cell(varinCnt_fliptTrial);
hashTestResults(:,'deltaQ (%)') = num2cell(100*varinPerc_fliptTrial);
for h = 1 : hashFuncCnt
    
    hashTestResults(h,'W_N(0)') = num2cell(cnts_collidTrials{h,1}(1,1));
    hashTestResults(h,'W_N(1)') = num2cell(cnts_collidTrials{h,1}(1,2));
    hashTestResults(h,'W_N(2)') = num2cell(cnts_collidTrials{h,1}(1,3));
    hashTestResults(h,'W_N(3)') = num2cell(cnts_collidTrials{h,1}(1,4));
    hashTestResults(h,'W_N(4+)') = num2cell(sum(cnts_collidTrials{h,1}(1,5:hashGroupCnt(h,1)+1)));
    hashTestResults(h,'W_N^0(0)') = num2cell(theorCnts_collidTrials{h,1}(1,1));
    hashTestResults(h,'W_N^0(1)') = num2cell(theorCnts_collidTrials{h,1}(1,2));
    hashTestResults(h,'W_N^0(2)') = num2cell(theorCnts_collidTrials{h,1}(1,3));
    hashTestResults(h,'W_N^0(3)') = num2cell(theorCnts_collidTrials{h,1}(1,4));
    hashTestResults(h,'W_N^0(4+)') = num2cell(sum(theorCnts_collidTrials{h,1}(1,5:hashGroupCnt(h,1)+1)));
    
end
hashTestResults(:,'avgd_byte') = num2cell(avg_absDiffPerByte(:,1));
hashTestResults(:,'avgd_byte^t') = num2cell(theo_absDiffPerByte(:,1));
hashTestResults(:,'|avgd_byte-avgd_byte^t|') = num2cell(abs(avg_absDiffPerByte(:,1) - theo_absDiffPerByte(:,1)));
hashTestResults(:,'max_d_byte') = num2cell(max_absDiffPerByte(:,1));
hashTestResults(:,'min_d_byte') = num2cell(min_absDiffPerByte(:,1));

disp(hashTestResults);%output the table content

%output W_N(j) for all j (0<=j<=N)
% disp('Experimental results of W_N(j) (0<=j<=N) for all compared hash functions are:');
% disp(cnts_collidTrials);
% disp('Theoretical values of W_N(j) (0<=j<=N) are:');
% disp(theorCnts_collidTrials);

%plot the histograms of fliptTrialCnt (i.e. T_i) for all hash functions
tiledlayout(hashFuncCnt,1);%Create a hashFuncCnt-by-1 tiled chart layout
for h = 1 : hashFuncCnt % to plot the h^th histogram
    nexttile;
    b=bar(linspace(1,hashLen(h,1),hashLen(h,1)),fliptTrialCnt{h,1}(1,:),1);
    b.FaceColor = '#0072BD';
    ylim([N/2-N/5,N/2+N/10]);
    yticks(N/2-N/5:N/20:N/2+N/10);
    xticks(0:20:floor(hashLen(h,1)/20)*20);
    title(strcat('QHFM-',num2str(hashLen(h,1))),'FontSize',10);
    ylabel('number of draws with flipped bits');
    xlabel(['Location index of ',num2str(hashLen(h,1)),'-bit hash space']);
end
%% Close connection to database
close(conn);

%% Clear variables
clear conn query;