/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.8.7;

contract FiToken{
    mapping(address => uint256) public balanceOf;
    
    constructor (uint256 initialSupply){
        balanceOf[msg.sender] = initialSupply;
    }
    
    function transfer(address _to,uint256 _value)public{
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
    }
    
}