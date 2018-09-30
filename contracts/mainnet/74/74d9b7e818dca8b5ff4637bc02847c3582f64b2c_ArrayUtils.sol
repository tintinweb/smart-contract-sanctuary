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