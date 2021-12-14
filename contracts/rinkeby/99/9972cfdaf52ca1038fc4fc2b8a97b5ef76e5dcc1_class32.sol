/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance1() public view returns(uint){
        return owner.balance;  //目前owner錢包地址的餘額
    }
    
    function querybalance2() public view returns(uint){
        return address(this).balance;  //目前這個智能合約地址的餘額
                                       //初始是0，佈建合約時在value填5eth，表示送5eth到合約
    }

    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}