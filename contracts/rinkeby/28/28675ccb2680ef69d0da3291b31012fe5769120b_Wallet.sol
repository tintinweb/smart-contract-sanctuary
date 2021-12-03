/**
 *Submitted for verification at Etherscan.io on 2021-12-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.2;

contract Wallet {
    address public owner;
    mapping(address => uint) public balances;
    event AproveSendMoney(address _from, address _to, uint _amount);

    constructor() {
        owner = msg.sender;
        balances[owner] = 50000;
    }

    function getBalance(address _address) public view returns (uint) {
        return balances[_address];
    }

    function approveSendMoney(address _to, uint _amount) public {
        emit AproveSendMoney(msg.sender, _to, _amount);
    }

    function sendMoney(address _from, address _to, uint _amount) public {
        balances[_from] -= _amount;
        balances[_to] += _amount;
    }
}