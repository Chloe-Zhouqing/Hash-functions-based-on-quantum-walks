 function [nodeHashArr] = QHFM12(coinParam1, coinParam2, nodesCnt, hashBitsCntPerNode, probDigitsCntInUse, binMsg)
%Perform QHFM,the quantum hash function based on one-dimensional quantum walks with 1- and 2-step memory 
%   QHFM is perfomed on a ring of nodesCnt nodes and is controlled by the binary message binMsg (a char array like '0100110').
%   If the t^th message bit equals '1', then the t^th step of the walker (the particle) performs QW2M; otherwise, the t^th step performs QW1M.

%   @coinPara1: the parameter (an angle bewteen 0 to pi/2) used to define the first coin operator
%   @coinPara2: the parameter used to define the second coin operator
%   @hashBitsCntPerNode: the number of hash bits contributed by each node, denoted by 'm' in the article
%   @probDigitsCntInUse: the number of digits (within the probability value
%     on each node) that will be used for calculating a hash component
%     contributed by a node, denoted by 'l' in the article
binMsgLen = length(binMsg);%The length of the binary message

amplArr = zeros(8,nodesCnt);%The current amplitudes for the particle walking on the ring of nodesCnt nodes. The values in amplArr evolve as the particle walks.
%   amplArr(j,k) is the amplitude value of basis state |j-1> at location k (i.e. at node k).
%   Recall that there are 8 basis states for each location. Specifically,
    %   amplArr(1,k) is the amplitude of |k+2,k+1,k,0> (or |L,L,0> at location k); 
    %   amplArr(2,k) is the amplitude of |k+2,k+1,k,1> (or |L,L,1> at location k);
    %   amplArr(3,k) is the amplitude of |k,k+1,k,0> (or |R,L,0> at location k); 
    %   amplArr(4,k) is the amplitude of |k,k+1,k,1> (or |R,L,1> at location k);
    %   amplArr(5,k) is the amplitude of |k,k-1,k,0> (or |L,R,0> at location k);
    %   amplArr(6,k) is the amplitude of |k,k-1,k,1> (or |L,R,1> at location k);
    %   amplArr(7,k) is the amplitude of |k-2,k-1,k,1> (or |R,R,0> at location k);
    %   amplArr(8,k) is the amplitude of |k-2,k-1,k,1> (or |R,R,1> at location k).

theta0 = coinParam1; %the parameter of coin operater C0
theta1 = coinParam2; %the parameter of coin operater C1
a0 = cos(theta0); b0 = sin(theta0); c0 = sin(theta0); d0 = -cos(theta0); %C0=H=[a0,b0;c0,d0]
a1 = cos(theta1); b1 = sin(theta1); c1 = sin(theta1); d1 = -cos(theta1); %C1=[a1,b1;c1,d1];

iniPos = 1;%The the particle start at node 0.
amplArr(3,iniPos) = 1/sqrt(2); amplArr(4,iniPos) = 1/sqrt(2);%The initial amplitudes of the particle. 
for t = 1 : binMsgLen %Perform the t^th step of QHFM.
    if mod(t,2000)==0 
            disp(['    step ',num2str(t),' ...']);
    end
    tempAmpl = zeros(8,nodesCnt);%tempAmpl is the temporary array for the amplitudes in each step.
        if strcmp(binMsg(t),'1')%if the t^th message bit is '1', then perform QW2M with  on the ring of nodesCnt nodes
             %disp('Message bit 1, perform a step of QW2M');
             for k = 0 : nodesCnt - 1 %The possible location ranges from node 0 to node nodesCnt-1.
                %Note that the index of an array begins at 1, not 0; thus
                %the amplitudes of the walker at node k are stored in tempAmpl(:,k+1).
                
                %After each step, the amplitudes at node k are reallocated to amplitudes at nodes 
                %k+1 and k-1 (stored in amplArr(:,mod(k+1,nodesCnt)+1) and amplArr(:,mod(k-1,nodesCnt)+1), respectively).
                tempAmpl(1,mod(k-1,nodesCnt)+1)=a1*amplArr(3,k+1)+b1*amplArr(4,k+1);
                tempAmpl(2,mod(k-1,nodesCnt)+1)=c1*amplArr(1,k+1)+d1*amplArr(2,k+1);
                tempAmpl(3,mod(k-1,nodesCnt)+1)=a1*amplArr(7,k+1)+b1*amplArr(8,k+1);
                tempAmpl(4,mod(k-1,nodesCnt)+1)=c1*amplArr(5,k+1)+d1*amplArr(6,k+1);
                tempAmpl(5,mod(k+1,nodesCnt)+1)=a1*amplArr(1,k+1)+b1*amplArr(2,k+1);
                tempAmpl(6,mod(k+1,nodesCnt)+1)=c1*amplArr(3,k+1)+d1*amplArr(4,k+1);          
                tempAmpl(7,mod(k+1,nodesCnt)+1)=a1*amplArr(5,k+1)+b1*amplArr(6,k+1);
                tempAmpl(8,mod(k+1,nodesCnt)+1)=c1*amplArr(7,k+1)+d1*amplArr(8,k+1);
             end
        else %If the t^th message bit is '0', then perform QW1M with Hadamard coin on the ring of nodesCnt nodes.
             %disp('Message bit 0, perform a step of QW1M');
             for k = 0 : nodesCnt - 1
                tempAmpl(1,mod(k-1,nodesCnt)+1)=a0*amplArr(5,k+1)+b0*amplArr(6,k+1);
                tempAmpl(2,mod(k-1,nodesCnt)+1)=c0*amplArr(1,k+1)+d0*amplArr(2,k+1);
                tempAmpl(3,mod(k-1,nodesCnt)+1)=a0*amplArr(7,k+1)+b0*amplArr(8,k+1);
                tempAmpl(4,mod(k-1,nodesCnt)+1)=c0*amplArr(3,k+1)+d0*amplArr(4,k+1);
                tempAmpl(5,mod(k+1,nodesCnt)+1)=a0*amplArr(1,k+1)+b0*amplArr(2,k+1);
                tempAmpl(6,mod(k+1,nodesCnt)+1)=c0*amplArr(5,k+1)+d0*amplArr(6,k+1); 
                tempAmpl(7,mod(k+1,nodesCnt)+1)=a0*amplArr(3,k+1)+b0*amplArr(4,k+1);
                tempAmpl(8,mod(k+1,nodesCnt)+1)=c0*amplArr(7,k+1)+d0*amplArr(8,k+1);
            end
        end
        amplArr=tempAmpl;%Refresh the amplitude array.The amplitudes in step t+1 are calculated from the amplitudes in step t. 
end
distriArr = zeros(1,nodesCnt);%distriArr(1,k+1) is to store the final probability at node k.
%probsum = sym(0);%to verify that if the sum of probabilities equals 1. symbolic value can avoid a lost of the least significant digits
for k = 0 : nodesCnt - 1 %to calculate the probability at each node
    distriArr(1,k+1) = amplArr(:,k+1)'*amplArr(:,k+1);%*globCoeffi;
    %probsum=probsum+distriArr(1,k+1);
end
%disp('概率和为');
%disp(probsum);%show the result of the sum of probabilities 需要在命令行窗口重新输入一遍才知道是否为1

%% Compute the hash result from the probability distribution distriArr.

nodeHashArr = zeros(1,nodesCnt);%the output hash value of the input binary message, a numeric array of nodesCnt elements
nodeHashMax = 2^hashBitsCntPerNode; %Each node contributes hashBitsCntPerNode hash-bits
for k = 0 : nodesCnt - 1
    nodeHashArr(k+1)=mod(round(distriArr(k+1)*10^probDigitsCntInUse),nodeHashMax);%Calculate the hash component (an integer) contributed by node k.
end
end

