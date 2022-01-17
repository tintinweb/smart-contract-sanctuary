// SPDX-License-Identifier: Ajabpur

// Scenario : A person nominate some amount to his nominies , hence he is adding nominies address and an amount
// The amount will be transfered to their address once the person turns 70 years old.

pragma solidity ^0.8.0;

contract Inheritance {
    address owner;
    uint256 age = 60;
    uint256 money;

    constructor(uint256 _age) payable {
        owner = msg.sender;
        money = msg.value;
        age = _age;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier isOldAge() {
        require(age == 70);
        _;
    }

    address[] wallets;
    mapping(address => uint256) inheritedAmt;

    function add_nomination(address _nominyAddress, uint256 _inheritedAmt)
        public
        onlyOwner
    {
        wallets.push(_nominyAddress);
        inheritedAmt[_nominyAddress] = _inheritedAmt;
    }

    function reachedOldAge() public onlyOwner {
        age = 70;
        // pay money
    }

    function sendAmount() private isOldAge {
        for (uint256 i = 0; i < wallets.length; i++) {
            payable(wallets[i]).transfer(inheritedAmt[wallets[i]]);
        }
    }
}