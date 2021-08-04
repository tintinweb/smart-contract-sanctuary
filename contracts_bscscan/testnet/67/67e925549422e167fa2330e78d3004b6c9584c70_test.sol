/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

pragma solidity >=0.6.12;
contract test{
    
    function gettest(uint256[] calldata arrs) public view returns(uint256[] memory) {
        uint256[] memory returnData;
       returnData=arrs;
       return returnData;
    }
     function gettest2(uint256[] calldata arrs) public view returns(uint256[] memory) {
        uint256[] memory returnData;
       for(uint256 i=0;i<arrs.length;i++){
            returnData[i]=arrs[i];
       }
       return returnData;
    }
    
}