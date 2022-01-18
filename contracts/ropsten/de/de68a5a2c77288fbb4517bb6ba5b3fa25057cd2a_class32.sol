/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }
    function whossender() public view returns(address){
        return owner;
    } 
    function querybalance1() public view returns(uint){
        return owner.balance;
    }
    function querybalance2() public view returns(uint){
        return address(this).balance;
    }
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
    function bye() public {
        selfdestruct(owner);
    }
}