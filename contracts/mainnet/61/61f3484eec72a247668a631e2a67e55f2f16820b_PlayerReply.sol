pragma solidity ^0.4.24;


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