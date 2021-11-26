/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity ^0.4.26;
contract token1{
    address owner;
    uint public amount=0;
    function token1()payable{}
    function()payable{}
    mapping (address => uint256) balance;
    function deposit1() payable{balance[msg.sender]+=msg.value;}
    function deposit2() payable{balance[this]+=msg.value;}
    function transfer(address _to,uint256 _value) returns(bool){
        if(_value<=balance[msg.sender]&& _value>0)
        {
            balance[msg.sender]-=_value;
            balance[_to]+=_value;
            return true;
        }
        else
            return false;
    }
}