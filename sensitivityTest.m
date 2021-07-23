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

%Set query to execute on the database.
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
msgArr = cell(4,1); %to store the four messages
%% assign values to parameters of QHFM
nodesCnt = 15; %denoted by 'n' in the article
hashBitsCntPerNode = 13; %denoted by 'm' in the article
hashLen = nodesCnt*hashBitsCntPerNode;
probDigitsCntInUse = 8; %denoted by 'l' in the article
coinParams = [pi/4,pi/3]; %corresponds to theta_0 and theta_1

%% Execute query, fetch a record id and the corresponding abstract of a random record
data = fetch(conn,query);
randId = uint32(data.id(1:1)); % extract the id value; data type:uint32
randAbstract = cell2mat(data.abstract(1:1));% extract the abstract value; data type: char array
truncAbstract = randAbstract(4:end-3);%remove the double quotes before and after the abstract content, delete the blanks before the abstract, remove '\n' after the abstract content.

%% Convert the abstract into the binary input message
msgCodes = double(truncAbstract);%code values (ASCII or Unicode values) of the input message (the abstract); data type: double array
binMsg0 = '';%to store the binary representation of the original message; data type: char array
msgCharCnt = length(msgCodes);% the number of chars of the input message
for j = 1:msgCharCnt
    binMsg0 = strcat(binMsg0,dec2bin(msgCodes(j)));
end
msgArr{1,1} = binMsg0;

%% to generate slightly modified messages
binMsgLen = length(binMsg0);%the length of the original message
%randomly flip a bit within binMsg and then obtain binMsg1
binMsg1 = binMsg0;
flipIdx = randi(binMsgLen);%generate a random index of the message bit that will be flipped
if strcmp(binMsg1(flipIdx),'0')
    binMsg1(flipIdx) = '1';
else
    binMsg1(flipIdx) = '0';
end
msgArr{2,1} = binMsg1;

%randomly generate a bit, insert this bit into binMsg0 at a random position and then obtain binMsg2
randBit = randi([0,1]);
insertIdx = randi(binMsgLen); %to insert randBit before the insertIndx^th bit of the orginal message
if insertIdx == 1
    binMsg2 = strcat(num2str(randBit),binMsg0);
else
    binMsg2 = strcat(binMsg0(1 : insertIdx-1),num2str(randBit),binMsg0(insertIdx : binMsgLen));
end
%disp(['待插入的随机比特为：',num2str(randBit)]);
%disp(['待插入的随机位置为：',num2str(insertIdx)]);
msgArr{3,1} = binMsg2;

%delete a random bit from binMsg0 and then obtain binMsg3
deleteIdx = randi(binMsgLen); %to delete the deleteIdx^th bit from the original message
if deleteIdx == 1
    binMsg3 = binMsg0(2 : binMsgLen);
elseif deleteIdx == binMsgLen
    binMsg3 = binMsg0(1 : binMsgLen-1);
else
    binMsg3 = strcat(binMsg0(1 : deleteIdx-1),binMsg0(deleteIdx+1 : binMsgLen));
end
msgArr{4,1} = binMsg3;

%% to calculate the hash values of the original and modified messages
hashArr = zeros(4,nodesCnt);
emptyHashStr = dec2bin(0,hashLen);
binHashArr = char(emptyHashStr,emptyHashStr,emptyHashStr,emptyHashStr); %to store the hash values in binary format, the jth hash value will occupy the jth row.
binHashVecs = zeros(4,hashLen);%hash values for plotting
for j = 1 : 4
    hashArr(j,:) = QHFM12(coinParams(1), coinParams(2), nodesCnt, hashBitsCntPerNode, probDigitsCntInUse,msgArr{j,1});
    currentHash = '';
    for k = 1 : nodesCnt
       currentHash = strcat(currentHash,dec2bin(hashArr(j,k),hashBitsCntPerNode));
    end
    binHashArr(j,:) = currentHash;
    binHashVecs(j,:) = currentHash - '0';
end

%% plot the hash values
set(gca, 'LooseInset', [0,0,0,0]);%expand axes to fill figure, elimilate the empty margin around the axes
%to plot a stair graph for H(msg0)
%subplot(4,1,1);%There are 4 subgraphs, arranged in 4 rows and 1 columns
tiledlayout(4,1,'TileSpacing','Compact','Padding','Compact');%Create a 4-by-1 tiled chart layout
nexttile;
stairs(binHashVecs(1,:),'b','Color','#0072BD');%draws a stairstep graph for the first hash value
ylim([-0.5,1.5]);%the range of the y axis
yticks([0 1]);%display tick marks along the y-axis at the values 0 and 1
xlim([-3,hashLen+4]);%the range of the x axis
max_xtick = floor(nodesCnt * hashBitsCntPerNode / 20)*20;
xticks(0:20:max_xtick);%display tick marks along the x-axis at increments of 20, starting from 0 and ending at max_xtick.
title('C1','position',[-8,0.3],'FontSize',9);%set the title for each subplot
%plot H(msg1), H(msg2), and H(msg3)
for j = 2 : 4
    %subplot(4,1,j);
    nexttile;
    stairs(binHashVecs(j,:),'b','Color','#0072BD');%RGB:0,114,189,#0072BD
    ylim([-0.5,1.5]);
    yticks([0 1]);
    xlim([-3,hashLen+4]);
    xticks(0:20:max_xtick);
    % mark the hash bits that are different from H(msg0)
    for k = 1 : hashLen
        if binHashVecs(j,k) ~= binHashVecs(1,k)
            text(k,binHashVecs(j,k),'*','Color','#0072BD');
        end
    end
    title(strcat('C',num2str(j)),'position',[-8,0.3],'FontSize',9);
end


%% display the hash values
hexGroupCnt = ceil(hashLen/4); %the hash value can be divided into hexGroupCnt groups, each group is represented by a hexadecimal number
% if hashLen is a multiple of 4, then every group is of 4 bits; otherwise,
% the bitlength of the first group is mod(hashLen,4), and the subsequent groups
% are of 4 bits.

disp('The hash values of the original and modified messages are ');
for j = 1 : 4
    binStrToDisp = strcat('Condition',num2str(j),': H(msg',num2str(j-1),') = ');
    hexStrToDisp = binStrToDisp;
    for k = 1 : hexGroupCnt
        if mod(hashLen,4) == 0
            startIdx = (k-1)*4+1;% the start index for kth group
            endIdx = 4*k;% the end index for jth group
            currentGroup = binHashArr(j,startIdx:endIdx);
        else
            if k == 1
                firstGroupLen = mod(hashLen,4);
                zeroCharsToPad = dec2bin(0,4 - firstGroupLen);
                currentGroup = strcat(zeroCharsToPad,binHashArr(j,1:firstGroupLen));
            else
                startIdx = firstGroupLen+1+4*(k-2);
                endIdx = firstGroupLen+4*(k-1);
                currentGroup = binHashArr(j,startIdx:endIdx);
            end
        end
        binStrToDisp = strcat(binStrToDisp,currentGroup);%to ouput the binary hash value without blanck between two group
        hexStrToDisp = strcat(hexStrToDisp,dec2hex(bin2dec(currentGroup)));
    end
    disp(binStrToDisp); % display the hash results in binary format
    disp(hexStrToDisp); % display the hash results in hexademical format
end

if mod(hashLen,4) > 0
    disp(['The first ',num2str(4-mod(hashLen,4)),' zero(s) of the binary hash values is (are) redundant bit(s).']);
else
    
end

    
