/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance1() public view returns(uint){
        return owner.balance; //回傳發布合約的人的餘額
    }
    
    function querybalance2() public view returns(uint){
        return address(this).balance; //回傳這個智能合約裡面的餘額
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}