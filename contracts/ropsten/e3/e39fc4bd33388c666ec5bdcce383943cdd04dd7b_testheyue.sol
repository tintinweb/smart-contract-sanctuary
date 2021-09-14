/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

pragma solidity ^0.6.6;

contract testheyue{
    address  owner;
    uint num = 10;
    
    constructor() public{
        owner = msg.sender;
    }
    
    modifier onlyower() {
        require(owner == msg.sender);
        _;
    }
    
    function kill() public onlyower {
        selfdestruct(msg.sender);
    }
    
    function getNuNum() public view returns(uint){
        return num;
    }
    
}