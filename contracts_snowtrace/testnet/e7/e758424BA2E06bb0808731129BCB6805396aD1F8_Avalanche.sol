/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-20
*/

// File: print.sol
// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.7.0;
contract Avalanche {
string word;

function convert(string memory _word) public {
    word = _word;
}

function print() public view returns (string memory){
    return word;
    }
}