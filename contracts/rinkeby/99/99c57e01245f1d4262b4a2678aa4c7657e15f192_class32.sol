/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

pragma solidity ^0.4.24;
contract class32{
    address public owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance_owner() public view returns(uint){
        return owner.balance;
    }
    
    function querybalance_contract() public view returns(uint){
        return address(this).balance;
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
    
    function owner() public view returns(address){
        return owner;
    }
}