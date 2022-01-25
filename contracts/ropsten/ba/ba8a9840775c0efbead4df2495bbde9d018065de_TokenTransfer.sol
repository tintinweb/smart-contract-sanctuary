/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity ^0.4.23;
 
contract token { function transfer(address receiver, uint amount){ receiver; amount; } } //transfer方法的接口说明
contract TokenTransfer{
    token public wowToken;
 
    function TokenTransfer(){
       wowToken = token(0x82bbb8326c02a172ba927dff525b60e10dbdcc3a); //实例化一个token
    }
 
    function tokenTransfer(address _to, uint _amt) public {
        wowToken.transfer(_to,_amt); //调用token的transfer方法
    }
}