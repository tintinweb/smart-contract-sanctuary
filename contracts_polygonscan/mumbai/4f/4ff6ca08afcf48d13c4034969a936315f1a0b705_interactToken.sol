/**
 *Submitted for verification at polygonscan.com on 2021-08-27
*/

pragma solidity 0.8.7;

//SPDX-License-Identifier: MIT

contract interactToken {
    address owner;
    uint maxSupply = 64 * 10 ** 18;
    mapping(address => uint) private balances;
    mapping(address => bool) private isBanned;

    constructor() {
        owner = msg.sender;
        balances[owner] = maxSupply;
    }

    modifier ifOwner {
        require(msg.sender == owner);
        _;
    }

    modifier ifNotBanned {
        require(!isBanned[msg.sender]);
        _;
    }

    function hasEnoughBalanceToTransfer(uint _amount) public view returns (bool) {
        return balances[msg.sender] >= _amount;
    }

    function transfer(uint _amount, address _to) public ifNotBanned {
        if (hasEnoughBalanceToTransfer(_amount)) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
        } else {
            revert("InteractToken / Not enough balance for transfer");
        }
    }

    function getBalance(address _address) public view returns (uint) {
        return balances[_address];
    }

    function ban(address _address) public ifOwner {
        isBanned[_address] = true;
    }

    function unban(address _address) public ifOwner {
        isBanned[_address] = false;
    }
}