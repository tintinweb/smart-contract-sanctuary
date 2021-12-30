/**
 *Submitted for verification at Etherscan.io on 2021-12-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.11;

contract HelloBlockchain {
    
    string text = "hello blockchain";

    function getText() public view returns(string memory) {
        return text;
    }

    function setText(string memory _newText) public {
        text = _newText;
    }
}