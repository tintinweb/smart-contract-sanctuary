/**
 *Submitted for verification at Etherscan.io on 2021-11-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity^0.8.7;

contract Chainsgiving {
    event Message(string indexed message);
    
    function iAmGratefulFor(string memory message) public {
        emit Message(message);
    }
}