/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity 0.6.0;

contract fall{
    
    uint256 public add;
    
    receive() external payable{
       add++;
    }
}