/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Bank {
    mapping(address => uint) public clientsBalance;
    
    event NewDeposit(address indexed client, uint money);

    function depositMoney(address client) external payable {
        clientsBalance[client] += msg.value;
        emit NewDeposit(client, msg.value);
    }

    function subtractMoney(uint money) external {
        require(clientsBalance[msg.sender] >= money, "You have not enough money");
        clientsBalance[msg.sender] -= money;
        payable(msg.sender).transfer(money);
    }
}