/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity  >=0.7.0 <0.8.0;

contract writee{
    string text;

    function write(string calldata _text) public {
        text = _text;
    }

    function red() public view returns(string memory){
        return text;
    }
}