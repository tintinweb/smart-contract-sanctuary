pragma solidity ^0.4.24;



library NameFilter {
    /**
     * @dev filters name strings
     * -converts uppercase to lower case.  
     * -makes sure it does not start/end with a space
     * -makes sure it does not contain multiple spaces in a row
     * -cannot be only numbers
     * -cannot start with 0x 
     * -restricts characters to A-Z, a-z, 0-9, and space.
     * @return reprocessed string in bytes32 format
     */
    function nameFilter(string _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        // make sure first two characters are not 0x
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }
        
        // create a bool to track if we have a non number character
        bool _hasNonNumber;
        
        // convert & check
        for (uint256 i = 0; i < _length; i++)
        {
            // if its uppercase A-Z
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                // convert to lower case a-z
                _temp[i] = byte(uint(_temp[i]) + 32);
                
                // we have a non number
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                    // or 0-9
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                
                // see if we have a character other than a number
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;    
            }
        }
        
        require(_hasNonNumber == true, "string cannot be only numbers");
        
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}


library Player{

    using NameFilter for string;

    address public constant AUTHOR =  0x001C9b3392f473f8f13e9Eaf0619c405AF22FC26a7;
    
    struct Map{
        mapping(address=>uint256) map;
        mapping(address=>address) referrerMap;
        mapping(address=>bytes32) addrNameMap;
        mapping(bytes32=>address) nameAddrMap;
    }
    
    function deposit(Map storage  ps,address adr,uint256 v) internal returns(uint256) {
       ps.map[adr]+=v;
        return v;
    }
    
    function depositAuthor(Map storage  ps,uint256 v) public returns(uint256) {
        return deposit(ps,AUTHOR,v);
    }

    function withdrawal(Map storage  ps,address adr,uint256 num) public returns(uint256) {
        uint256 sum = ps.map[adr];
        if(sum==num){
            withdrawalAll(ps,adr);
        }
        require(sum > num);
        ps.map[adr] = (sum-num);
        return sum;
    }
    
    function withdrawalAll(Map storage  ps,address adr) public returns(uint256) {
        uint256 sum = ps.map[adr];
        require(sum >= 0);
        delete ps.map[adr];
        return sum;
    }
    
    function getAmmount(Map storage ps,address adr) public view returns(uint256) {
        return ps.map[adr];
    }
    
    function registerName(Map storage ps,bytes32 _name)internal  {
        require(ps.nameAddrMap[_name] == address(0) );
        ps.nameAddrMap[_name] = msg.sender;
        ps.addrNameMap[msg.sender] = _name;
    }
    
    function isEmptyName(Map storage ps,bytes32 _name) public view returns(bool) {
        return ps.nameAddrMap[_name] == address(0);
    }
    
    function getByName(Map storage ps,bytes32 _name)public view returns(address) {
        return ps.nameAddrMap[_name] ;
    }
    
    function getName(Map storage ps) public view returns(bytes32){
        return ps.addrNameMap[msg.sender];
    }
    
    function getNameByAddr(Map storage ps,address adr) public view returns(bytes32){
        return ps.addrNameMap[adr];
    }    
    
    function getReferrer(Map storage ps,address adr)public view returns(address){
        return ps.referrerMap[adr];
    }
    
    function getReferrerName(Map storage ps,address adr)public view returns(bytes32){
        return getNameByAddr(ps,getReferrer(ps,adr));
    }
    
    function setReferrer(Map storage ps,address self,address referrer)internal {
         ps.referrerMap[self] = referrer;
    }
    
    function applyReferrer(Map storage ps,string referrer)internal {
        require(getReferrer(ps,msg.sender) == address(0));
        bytes32 rbs = referrer.nameFilter();
        address referrerAdr = getByName(ps,rbs);
        if(referrerAdr != msg.sender){
            setReferrer(ps,msg.sender,referrerAdr);
        }
    }    
    
    function withdrawalFee(Map storage ps,uint256 fee) public returns (uint256){
        if(msg.value > 0){
            require(msg.value >= fee,"msg.value < fee");
            return fee;
        }
        require(getAmmount(ps,msg.sender)>=fee ,"players.getAmmount(msg.sender)<fee");
        withdrawal(ps,msg.sender,fee);
        return fee;
    }   
    
}

library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }
    
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
    
    function pwrFloat(uint256 tar,uint256 numerator,uint256 denominator,uint256 pwrN) public pure returns(uint256) {
        for(uint256 i=0;i<pwrN;i++){
            tar = tar * numerator / denominator;
        }
        return tar ;
        
    }

    
    function mulRate(uint256 tar,uint256 rate) public pure returns (uint256){
        return tar *rate / 100;
    }
 
    
    
}

library ArrayUtils {
    
    function removeByIdx(uint256[] array,uint256 idx) public pure returns(uint256[] memory){
         uint256[] memory ans = copy(array,array.length-1);
        while((idx+1) < array.length){
            ans[idx] = array[idx+1];
            idx++;
        }
        return ans;
    }
    
    function copy(uint256[] array,uint256 len) public pure returns(uint256[] memory){
        uint256[] memory ans = new uint256[](len);
        len = len > array.length? array.length : len;
        for(uint256 i =0;i<len;i++){
            ans[i] = array[i];
        }
        return ans;
    }
    
    function getHash(uint256[] array) public pure returns(uint256) {
        uint256 baseStep =100;
        uint256 pow = 1;
        uint256 ans = 0;
        for(uint256 i=0;i<array.length;i++){
            ans= ans+ uint256(array[i] *pow ) ;
            pow= pow* baseStep;
        }
        return ans;
    }
    
    function contains(address[] adrs,address adr)public pure returns(bool){
        for(uint256 i=0;i<adrs.length;i++){
            if(adrs[i] ==  adr) return true;
        }
        return false;
    }
    
}

library CommUtils{
    
    using ArrayUtils for uint256[];
    
    function random(uint256 max,uint256 mixed) public view returns(uint256){
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(blockhash(lastBlockNumber));
        hashVal += 31*uint256(block.coinbase);
        hashVal += 19*mixed;
        hashVal += 17*uint256(block.difficulty);
        hashVal += 13*uint256(block.gaslimit );
        hashVal += 11*uint256(now );
        hashVal += 7*uint256(block.timestamp );
        hashVal += 3*uint256(tx.origin);
        return uint256(hashVal % max);
    } 
    
    function getIdxArray(uint256 len) public pure returns(uint256[]){
        uint256[] memory ans = new uint256[](len);
        for(uint128 i=0;i<len;i++){
            ans[i] = i;
        }
        return ans;
    }
    
    function genRandomArray(uint256 digits,uint256 templateLen,uint256 base) public view returns(uint256[]) {
        uint256[] memory ans = new uint256[](digits);
        uint256[] memory idxs  = getIdxArray( templateLen);
       for(uint256 i=0;i<digits;i++){
            uint256  idx = random(idxs.length,i+base);
            uint256 wordIdx = idxs[idx];
            ans[i] = wordIdx;
            idxs = idxs.removeByIdx(idx);
           
       }
       return ans;
    }
}



library PlayerReply{
    
    using ArrayUtils for address[];
    using ArrayUtils for uint256[];
    
    uint256 constant VISABLE_NONE = 0;
    uint256 constant VISABLE_FINAL = 1;
    uint256 constant VISABLE_ALL = 2;
    uint256 constant VISABLE_OWNER = 3;
    uint256 constant VISABLE_BUYED = 4;
    
    uint256 constant HIDE_TIME = 5*60;
    
    uint256 constant GRAND_TOTAL_TIME = 10*60;
    
    
    struct Data{
        address[] ownerIds;
        uint256 aCount;
        uint256 bCount;
        uint256[] answer;
        uint replyAt;
    }
    
    struct List{
        uint256 size;
        mapping (uint256 => uint256) hashIds;
        mapping (uint256 => Data) map;
        mapping (uint256=>uint256) sellPriceMap;
        mapping (uint256=>address) seller;
        mapping (uint256=>address[]) buyer;
    }
    
    
    function init(Data storage d,uint256 ac,uint256 bc,address own) internal{
          d.ownerIds.push(own)  ;
          d.aCount = ac;
          d.bCount = bc;
          d.replyAt = now;
    }
    
    function clear(List storage ds) internal{
        for(uint256 i =0;i<ds.size;i++){
            uint256 key = ds.hashIds[i];
            delete ds.map[key];
            delete ds.sellPriceMap[key];
            delete ds.seller[key];
            delete ds.buyer[key];
            delete ds.hashIds[i];
        }
        ds.size = 0;
    }
    
    function setSellPrice(List storage ds,uint256 ansHash,uint256 price) internal {
        require(ds.map[ansHash].ownerIds.contains(msg.sender));
        require(ds.seller[ansHash] == address(0));
        ds.seller[ansHash] = msg.sender;
        ds.sellPriceMap[ansHash] = price;
    }
    
    function getSellPrice(List storage ds,uint256 idx) public view returns(uint256) {
        return ds.sellPriceMap[ds.hashIds[idx]] ;
    }
    
    function isOwner(Data storage d) internal view returns(bool){
        return d.replyAt>0 && d.answer.length>0 && d.ownerIds.contains(msg.sender);
    }
    
    function isWined(Data storage d) internal view returns(bool){
        return d.replyAt>0 && d.answer.length>0 && d.aCount == d.answer.length ;
    }
    
    function getWin(List storage ds) internal view returns(Data storage lastAns){
        for(uint256 i=0;i<ds.size;i++){
            Data storage d = get(ds,i);
           if(isWined(d)){
             return d;  
           } 
        }
        
        return lastAns;
    }
    
    function getVisibleType(List storage ds,uint256 ansHash) internal view returns(uint256) {
        Data storage d = ds.map[ansHash];
        if(d.ownerIds.contains(msg.sender)){
            return VISABLE_OWNER;
        }else if(d.answer.length == d.aCount){
            return VISABLE_FINAL;
        }else if(ds.buyer[ansHash].contains(msg.sender)){
            return VISABLE_BUYED;
        }else if((now - d.replyAt)> HIDE_TIME && ds.sellPriceMap[ansHash] == 0){
            return VISABLE_ALL;
        }
        return VISABLE_NONE;
    }
    
    function getReplay(List storage ds,uint256 idx) internal view returns(
        uint256 ,//aCount;
        uint256,// bCount;
        uint256[],// answer;
        uint,// Timeline;
        uint256, // VisibleType
        uint256, //sellPrice
        uint256 //ansHash
        ) {
            uint256 ansHash = ds.hashIds[idx];
            uint256 sellPrice = ds.sellPriceMap[ansHash];
            Data storage d= ds.map[ansHash];
            uint256 vt = getVisibleType(ds,ansHash);
        return (
            d.aCount,
            d.bCount,
            vt!=VISABLE_NONE ?  d.answer : new uint256[](0),
            now-d.replyAt,
            vt,
            sellPrice,
            vt!=VISABLE_NONE ? ansHash : 0
        );
    } 
    
    function listBestScore(List storage ds) internal view returns(
        uint256 aCount , //aCount    
        uint256 bCount , //bCount
        uint256 bestCount // Count
        ){
        uint256 sorce = 0;
        for(uint256 i=0;i<ds.size;i++){
            Data storage d = get(ds,i);
            uint256 curSore = (d.aCount *100) + d.bCount;
            if(curSore > sorce){
                aCount = d.aCount;
                bCount = d.bCount;
                sorce = curSore;
                bestCount = 1;
            }else if(curSore == sorce){
                bestCount++;
            }
        }
    }
    
    
    function getOrGenByAnwser(List storage ds,uint256[] ans) internal  returns(Data storage ){
        uint256 ansHash = ans.getHash();
        Data storage d = ds.map[ansHash];
        if(d.answer.length>0) return d;
        d.answer = ans;
        ds.hashIds[ds.size] = ansHash;
        ds.size ++;
        return d;
    }
    
    
    function get(List storage ds,uint256 idx) public view returns(Data storage){
        return ds.map[ ds.hashIds[idx]];
    }
    
    function getByHash(List storage ds ,uint256 ansHash)public view returns(Data storage){
        return ds.map[ansHash];
    }
    
    
    function getLastReplyAt(List storage list) internal view returns(uint256){
        return list.size>0 ? (now- get(list,list.size-1).replyAt) : 0;
    }
    
    function getLastReply(List storage ds) internal view returns(Data storage d){
        if( ds.size>0){
            return get(ds,ds.size-1);
        }
        return d;
    }    
    
    function countByGrand(List storage ds) internal view returns(uint256) {
        if(ds.size == 0 ) return 0;
        uint256 count = 0;
        uint256 _lastAt = now;
        uint256 lastIdx = ds.size-1;
        Data memory d = get(ds,lastIdx-count);
        while((_lastAt - d.replyAt)<= GRAND_TOTAL_TIME ){
            count++;
            _lastAt = d.replyAt;
            if(count>lastIdx) return count;
            d = get(ds,lastIdx-count);
        }
        return count;       
    }
    
}


library RoomInfo{
    
    using PlayerReply for PlayerReply.Data;
    using PlayerReply for PlayerReply.List;
    using Player for Player.Map;
    using ArrayUtils for uint256[];
    uint256 constant DIVIDEND_AUTH = 5;
    uint256 constant DIVIDEND_INVITE = 2;
    uint256 constant DIVIDEND_INVITE_REFOUND = 3;
    uint256 constant DECIMAL_PLACE = 100;

    uint256 constant GRAND_RATE = 110;
    
    
    
    struct Data{
        address ownerId;
        uint256 charsLength;
        uint256[] answer;
        PlayerReply.List replys;
        bytes32 name;
        uint256 prize;
        uint256 minReplyFee;
        uint256 replayCount;
        uint256 firstReplayAt;
        uint256 rateCode;
        uint256 round;
        uint256 maxReplyFeeRate;
        uint256 toAnswerRate;
        uint256 toOwner;
        uint256 nextRoundRate;
        uint256 increaseRate_1000;
        uint256 initAwardTime ;
        uint256 plusAwardTime ;
    }
    
    struct List{
        mapping(uint256 => Data)  map;
        uint256  size ;
    }
    
    
    
    function genOrGetReplay(Data storage d,uint256[] ans) internal returns(PlayerReply.Data storage ) {
        (PlayerReply.Data storage replayData)  = d.replys.getOrGenByAnwser(ans);
        d.replayCount++;
        if(d.firstReplayAt == 0) d.firstReplayAt = now;
        return (replayData);
    }
    
    function tryAnswer(Data storage d ,uint256[] _t ) internal view returns(uint256,uint256){
        require(d.answer.length == _t.length);
        uint256 aCount;
        uint256 bCount;
        for(uint256 i=0;i<_t.length;i++){
            for(uint256 j=0;j<d.answer.length;j++){
                if(d.answer[j] == _t[i]){
                    if(i == j){
                        aCount++;
                    }else{
                        bCount ++;
                    }
                }
            }
        }
        return (aCount,bCount);
    }

    function init(
        Data storage d,
        uint256 digits,
        uint256 templateLen,
        bytes32 n,
        uint256 toAnswerRate,
        uint256 toOwner,
        uint256 nextRoundRate,
        uint256 minReplyFee,
        uint256 maxReplyFeeRate,
        uint256 increaseRate_1000,
        uint256 initAwardTime,
        uint256 plusAwardTime
        ) public {
        require(maxReplyFeeRate<1000 && maxReplyFeeRate > 5 );
        require(minReplyFee<= msg.value *maxReplyFeeRate /DECIMAL_PLACE && minReplyFee>= 0.000005 ether);
        require(digits>=2 && digits <= 9 );
        require((toAnswerRate+toOwner)<=90);
        require(msg.value >= 0.001 ether);
        require(nextRoundRate <= 70);
        require(templateLen >= 10);
        require(initAwardTime < 60*60*24*90);
        require(plusAwardTime < 60*60*24*20);
        require(SafeMath.mulRate(msg.value,100-nextRoundRate) >= minReplyFee);
        
        d.charsLength = templateLen;
        d.answer = CommUtils.genRandomArray(digits,templateLen,0);       
        d.ownerId = msg.sender;
        d.name = n;
        d.prize = msg.value;
        d.minReplyFee = minReplyFee;
        d.round = 1;
        d.maxReplyFeeRate = maxReplyFeeRate;
        d.toAnswerRate = toAnswerRate;
        d.toOwner = toOwner;
        d.nextRoundRate = nextRoundRate;
        d.increaseRate_1000 = increaseRate_1000;
        d.initAwardTime = initAwardTime;
        d.plusAwardTime = plusAwardTime;
        
    }
    
    function replayAnser(Data storage r,Player.Map storage ps,uint256 fee,uint256[] tryA) internal returns(
            uint256, // aCount
            uint256 // bCount
        )  {
        (uint256 a, uint256 b) = tryAnswer(r,tryA);
        saveReplyFee(r,ps,fee);
        (PlayerReply.Data storage pr) = genOrGetReplay(r,tryA);
        pr.init(a,b,msg.sender); 
        return (a,b);
    }
    
    function saveReplyFee(Data storage d,Player.Map storage ps,uint256 replayFee) internal  {
        uint256 lessFee = replayFee;
        //uint256 toAnswerRate= rates[IdxToAnswerRate];
        //uint256 toOwner = rates[IdxToOwnerRate];
        
        lessFee -=sendReplayDividend(d,ps,replayFee*d.toAnswerRate/DECIMAL_PLACE);
        address refer = ps.getReferrer(msg.sender);
        if(refer == address(0)){
            lessFee -=ps.depositAuthor(replayFee*(DIVIDEND_AUTH+DIVIDEND_INVITE+DIVIDEND_INVITE_REFOUND)/DECIMAL_PLACE);            
        }else{
            lessFee -=ps.deposit(msg.sender,replayFee*DIVIDEND_INVITE_REFOUND/DECIMAL_PLACE);
            lessFee -=ps.deposit(refer,replayFee*DIVIDEND_INVITE/DECIMAL_PLACE);
            lessFee -=ps.depositAuthor(replayFee*DIVIDEND_AUTH/DECIMAL_PLACE);
        }
        lessFee -=ps.deposit(d.ownerId,replayFee*d.toOwner/DECIMAL_PLACE);
        
        d.prize += lessFee;
    }
    
    function sendReplayDividend(Data storage d,Player.Map storage ps,uint256 ammount) private returns(uint256) {
        if(d.replayCount <=0) return 0;
        uint256 oneD = ammount /  d.replayCount;
        for(uint256 i=0;i<d.replys.size;i++){
            PlayerReply.Data storage rp = d.replys.get(i);
            for(uint256 j=0;j<rp.ownerIds.length;j++){
                ps.deposit(rp.ownerIds[j],oneD);          
            }
        }
        return ammount;
    }

    
    
    function getReplay(Data storage d,uint256 replayIdx) internal view returns(
        uint256 ,//aCount;
        uint256,// bCount;
        uint256[],// answer;
        uint,// replyAt;
        uint256, // VisibleType
        uint256, //sellPrice
        uint256 //ansHash
        ) {
        return d.replys.getReplay(replayIdx);
    }   
    
    function isAbleNextRound(Data storage d,uint256 nextRound) internal view returns(bool){
        return ( SafeMath.mulRate(nextRound,100-d.nextRoundRate)> d.minReplyFee  );
    }    
    
    function clearAndNextRound(Data storage d,uint256 prize) internal {
        d.prize = prize;
        d.replys.clear();
        d.replayCount  = 0;
        d.firstReplayAt = 0;
        d.round++;
        d.answer = CommUtils.genRandomArray(d.answer.length,d.charsLength,0); 
    }
    
    function getReplyFee(Data storage d) internal view returns(uint256){
        uint256 prizeMax = (d.prize *  d.maxReplyFeeRate ) /DECIMAL_PLACE;
        uint256 ans = SafeMath.pwrFloat(d.minReplyFee, d.increaseRate_1000 +1000,1000,d.replys.size);
        ans = ans > prizeMax ? prizeMax : ans;
        uint256 count = d.replys.countByGrand();
        if(count>0){
            ans = SafeMath.pwrFloat(ans,GRAND_RATE,DECIMAL_PLACE,count);       
        }
        ans = ans < d.minReplyFee ? d.minReplyFee : ans;
        return ans;
    }
    
    function sellReply(Data storage d,Player.Map storage ps,uint256 ansHash,uint256 price,uint256 fee) internal{
        d.replys.setSellPrice(ansHash,price);
        saveReplyFee(d,ps,fee);
    }
    
    function buyReply(Data storage d,Player.Map storage ps,uint256 replyIdx,uint256 buyFee) internal{
        uint256 ansHash = d.replys.hashIds[replyIdx];
        require(buyFee >= d.replys.getSellPrice(replyIdx) ,"buyFee to less");
        require(d.replys.seller[ansHash]!=address(0),"d.replys.seller[ansHash]!=address(0)");
        d.replys.buyer[ansHash].push(msg.sender);
        uint256 lessFee = buyFee;
        address refer = ps.referrerMap[msg.sender];
        if(refer == address(0)){
            lessFee -=ps.depositAuthor(buyFee*(DIVIDEND_AUTH+DIVIDEND_INVITE+DIVIDEND_INVITE_REFOUND)/100);            
        }else{
            lessFee -=ps.deposit(msg.sender,buyFee*DIVIDEND_INVITE_REFOUND/100);
            lessFee -=ps.deposit(refer,buyFee*DIVIDEND_INVITE/100);
            lessFee -=ps.depositAuthor(buyFee*DIVIDEND_AUTH/100);
        }        
        lessFee -=ps.deposit(d.ownerId,buyFee*    d.toOwner  /100);
        ps.deposit(d.replys.seller[ansHash],lessFee);
    }
    
    
    function getGameItem(Data storage d) public view returns(
        bytes32, //name
        uint256, //bestACount 
        uint256, //bestBCount
        uint256, //answer count
        uint256, //totalPrize
        uint256, // reply Fee
        uint256 //OverTimeLeft
        ){
             (uint256 aCount,uint256 bCount,uint256 bestCount) = d.replys.listBestScore();
             bestCount = bestCount;
             uint256 fee = getReplyFee(d);
             uint256 overTimeLeft = getOverTimeLeft(d);
             uint256 replySize = d.replys.size;
        return(
            d.name,
            d.prize,
            aCount,
            bCount,
            replySize,
            fee,
            overTimeLeft
        );  
        
    }    
    
    function getByPrizeLeast(List storage ds) internal view returns (Data storage){
        Data storage ans = ds.map[0];
        uint256 _cp = ans.prize;
        for(uint256 i=0;i<ds.size;i++){
            if(_cp > ds.map[i].prize){
                ans= ds.map[i];
                _cp = ans.prize;
            }
        }
        return ans;
    }
    
    function getByPrizeLargestIdx(List storage ds) internal view returns (uint256 ){
        uint256 ans = 0;
        uint256 _cp = 0;
        for(uint256 i=0;i<ds.size;i++){
            if(_cp < ds.map[i].prize){
                ans= i;
                _cp = ds.map[i].prize;
            }
        }
        return ans;
    }    
    
    function getByName(List storage ds,bytes32 name) internal view returns( Data ){
        for(uint256 i=0;i<ds.size;i++){
            if(ds.map[i].name == name){
                return ds.map[i];
            }
        }
    }
    
    function getIdxByNameElseLargest(List storage ds,bytes32 name) internal view returns( uint256 ){
        for(uint256 i=0;i<ds.size;i++){
            if(ds.map[i].name == name){
                return i;
            }
        }
        return getByPrizeLargestIdx(ds);
    } 
    
    function getEmpty(List storage ds) internal returns(Data storage){
        for(uint256 i=0;i<ds.size;i++){
            if(ds.map[i].ownerId == address(0)){
                return ds.map[i];
            }
        }
        uint256 lastIdx= ds.size++;
        return ds.map[lastIdx];
    }
    
    
    function award(RoomInfo.Data storage r,Player.Map storage players) internal  returns(
            address[] memory winners,
            uint256[] memory rewords,
            uint256 nextRound
        
        )  {
        (PlayerReply.Data storage pr) = getWinReply(r);
        require( pr.isOwner()," pr.isSelfWinnwer()");
        
        nextRound = r.nextRoundRate * r.prize / 100;
        require(nextRound<=r.prize, "nextRound<=r.prize");
        uint256 reward = r.prize - nextRound;
        address[] storage ownerIds = pr.ownerIds;
        winners = new address[](ownerIds.length);
        rewords = new uint256[](ownerIds.length);
        uint256 sum = 0;
        if(ownerIds.length==1){
            sum +=players.deposit(msg.sender , reward);
            winners[0] = msg.sender;
            rewords[0] = reward;
           // emit Wined(msg.sender , reward,roomIdx ,players.getNameByAddr(msg.sender) );
        }else{
            uint256 otherReward = reward * 30 /100;
            reward -= otherReward;
            otherReward = otherReward / (ownerIds.length-1);
            bool firstGived = false;
            for(uint256 i=0;i<ownerIds.length;i++){
                if(!firstGived && ownerIds[i] == msg.sender){
                    firstGived = true;
                    sum +=players.deposit(ownerIds[i] , reward);
                    winners[i] = ownerIds[i];
                    rewords[i] = reward;
                   // emit Wined(ownerIds[i] , reward,roomIdx,players.getNameByAddr(ownerIds[i] ));
                }else{
                    sum +=players.deposit(ownerIds[i] , otherReward);
                    //emit Wined(ownerIds[i] , otherReward,roomIdx,players.getNameByAddr(ownerIds[i] ));
                    winners[i] = ownerIds[i];
                    rewords[i] = otherReward;
                }
            }
        }     
        if(sum>(r.prize-nextRound)){
            revert("sum>(r.prize-nextRound)");
        }
    }    
    
    function getOverTimeLeft(Data storage d) internal view returns(uint256){
        if(d.replayCount == 0) return 0;
        //uint256 time = (d.replayCount * 5 * 60 )+ (3*24*60*60) ;
        uint256 time = (d.replayCount *d.plusAwardTime )+ d.initAwardTime ;
        uint256 spendT = (now-d.firstReplayAt);
        if(time<spendT) return 0;
        return time - spendT ;
    }
    
    
    function getWinReply(Data storage d) internal view returns (PlayerReply.Data storage){
        PlayerReply.Data storage pr = d.replys.getWin();
        if(pr.isWined()) return pr;
        if(d.replayCount > 0 && getOverTimeLeft(d)==0 ) return d.replys.getLastReply();
        return pr;
    }
    
    function getRoomExReplyInfo(Data storage r) internal view returns(uint256 time,uint256 count) {
        time = r.replys.getLastReplyAt();
        count = r.replys.countByGrand();
    }
    
    function get(List storage ds,uint256 idx) internal view returns(Data storage){
        return ds.map[idx];
    }
    
    
}