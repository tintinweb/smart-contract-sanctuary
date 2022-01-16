/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
interface Tokenloom { function transfer(address to, uint256 value) external returns (bool success); }
contract Mine{

    address public creator;
    Tokenloom public mqttToken;

    constructor()payable{
        creator = msg.sender;
        mqttToken = Tokenloom(0xE19f15163F7691331d32eC379551Abe7857e8eE5);
    }

    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount <= 0.001 ether);
        payable(msg.sender).transfer(withdraw_amount);
        mqttToken.transfer(msg.sender,100000000); //调用token的transfer方法
    }


    fallback () payable external {}
    receive () payable external {}

}