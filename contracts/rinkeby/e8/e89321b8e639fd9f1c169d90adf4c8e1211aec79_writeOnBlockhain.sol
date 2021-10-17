/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract writeOnBlockhain {
    string text;
    function writeText(string calldata _text) public {
        text = _text;
    }
    function getText() public view returns(string memory) {
        return text;
    }
}