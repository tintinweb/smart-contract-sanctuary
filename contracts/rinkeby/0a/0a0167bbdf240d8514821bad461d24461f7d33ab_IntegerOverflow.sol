/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity ^0.6.12;


contract IntegerOverflow{
    
    uint256 public num1;
    uint256 public num2;
    
    constructor(uint256 _num1 , uint256 _num2) public{
        
        require(_num1+_num2>0,'number is greater');
        num1 = _num1;
        num2 = _num2;
    }
}