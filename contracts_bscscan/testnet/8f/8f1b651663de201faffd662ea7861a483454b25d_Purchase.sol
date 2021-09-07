/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

pragma solidity ^0.4.22;

contract Purchase {
    
    
    

    uint256 _allTotalStorage; //all total storage 
    
    
    function addAllTotalStorage(uint256 amount)  public {
        _allTotalStorage +=amount;
    }
    
    
    function getAllTotalStorage() view public returns(uint256){
        return _allTotalStorage;
    }

}