/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity 0.5.14;

contract fall{
    
    uint256 public add;
    
    function() external{
       addFun();
    }
    
    function addFun() public {
        add++;
    }
}