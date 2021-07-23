function[collidCnt,absDiffPerByte] = collisionPerTrial(hashGroupLen,binHash1,binHash2)
%calculte the collision result for two binary hash values binHash1 and binHash2
%	collidCnt is the number of colliding groups (the number of identical groups at same positions) in binHash1 and binHash2
%   absDiff is the absolute difference between binHash1 and binHash2
%   @binHash1 the hash value (char array of '0's and '1's) of the original message
%   @binHash2 the hash value (char array of '0's and '1's) of the modified message
    collidCnt = 0;
    absDiff = 0;
    hashLen = length(binHash1);
    hashGroupCnt = ceil(hashLen/8);% hashGroupCnt is to store the number of hash segments (the number of groups) within a hash value
    binHashXor = char(abs(binHash1 - binHash2)+'0');%binHash1 XOR binHash2; a char array of '0's and '1's
    sameGroupRecogStr = dec2bin(0,hashGroupLen);%the pattern '00...0' is used to recognize identical groups at same positions in binary representations of binHash1 and binHash
    hashXorHex = '';%hashXorHex is the hexadecimal representation of binHashXor (possibly added with a prefix '00...0'). The char-length of hashXorHex is exactly 2*hashGroupCnt
    
    if mod(hashLen,8) == 0 %the length of the hash value can be exactely divided by 8
        %every group in the hash value consists of 8 bits 
        for j = 1 : hashGroupCnt
            startIdx = (j-1)*8+1;% the start index for jth group in binHash1 or binHash2
            endIdx = 8*j;% the end index for jth group in binHash1 or binHash2
            currentGroupXor = binHashXor(startIdx : endIdx); %currentGroupXor equals [(the jth group in binHash1) XOR (the jth group in binHash2)]
            collidFlag = strcmp(currentGroupXor,sameGroupRecogStr);% the flag indicating whether the jth groups in binHash1 and binHash2 are identical
            collidCnt = collidCnt + collidFlag;
            absDiff = absDiff + abs(bin2dec(binHash1(startIdx : endIdx))-bin2dec(binHash2(startIdx : endIdx)));
            %
            %%%------ 1 intermediate checks (begin) ------%%%
            hashXorHex = strcat(hashXorHex,dec2hex(bin2dec(currentGroupXor(1:4))));
            hashXorHex = strcat(hashXorHex,dec2hex(bin2dec(currentGroupXor(5:8))));
            if collidFlag
                disp(['    1 collision occurs at group ',num2str(j)]);
            end
            %%%------ 1 intermediate checks (end) ------%%%
            %
        end
    else %the lengh of the hash result is not divisible by 8
        firstGroupLen = mod(hashLen,8);
        sameGroupRecogStr = dec2bin(0,firstGroupLen);
        collidFlag = strcmp(binHashXor(1 : firstGroupLen) , sameGroupRecogStr);
        collidCnt = collidCnt + collidFlag;
        absDiff = absDiff + abs(bin2dec(binHash1(1 : firstGroupLen))-bin2dec(binHash2(1 : firstGroupLen)));
        %
        %%%------ 2 intermediate checks (begin) ------%%%
        firstGroupXor = strcat(dec2bin(0,8-firstGroupLen) , binHashXor(1 : firstGroupLen));%the first hash group, which is added a prefix of 8-firstGroupLen zeros
        hashXorHex = strcat(hashXorHex,dec2hex(bin2dec(firstGroupXor(1:4))));
        hashXorHex = strcat(hashXorHex,dec2hex(bin2dec(firstGroupXor(5:8))));
        if collidFlag
                disp('    1 collision occurs at group 1');
        end
        %%%------ 1 intermediate checks (end) ------%%%
        %
        sameGroupRecogStr = dec2bin(0,8);
        for j = 2 : hashGroupCnt
            startIdx = firstGroupLen+1+8*(j-2);
            endIdx = firstGroupLen+8*(j-1);
            currentGroupXor = binHashXor(startIdx : endIdx);
            collidFlag = strcmp(currentGroupXor,sameGroupRecogStr);
            collidCnt = collidCnt + collidFlag;
            absDiff = absDiff + abs(bin2dec(binHash1(startIdx:endIdx)) - bin2dec(binHash2(startIdx:endIdx)));
            %
            %%%------ 1 intermediate checks (begin) ------%%%
            hashXorHex = strcat(hashXorHex,dec2hex(bin2dec(currentGroupXor(1:4))));
            hashXorHex = strcat(hashXorHex,dec2hex(bin2dec(currentGroupXor(5:8))));
            if collidFlag
                disp(['    1 collision occurs at group ',num2str(j)]);    
            end
            %%%------ 1 intermediate checks (end) ------%%%
            %
        end
    end
    absDiffPerByte = absDiff/hashGroupCnt;
    %
    %%%------ 1 intermediate checks (begin) ------%%%
    if collidCnt > 0
        disp(['hashXorHex: ',hashXorHex]);
    end
    %%%------ 1 intermediate checks (end) ------%%%
    %    
end