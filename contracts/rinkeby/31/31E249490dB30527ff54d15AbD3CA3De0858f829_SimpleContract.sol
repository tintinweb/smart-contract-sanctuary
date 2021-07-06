/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

pragma solidity ^0.6.0;



contract SimpleContract {
    
    
    uint256 storeData;
    
    
    function setData(uint256 newData) external{
        storeData = newData;
    }
    function getData() external view returns(uint256){
        return storeData;
    }
    
}