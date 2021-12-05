/**
 *Submitted for verification at BscScan.com on 2021-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract WRText {

    string text;
    
    function toWrite(string calldata _text) public {
        text = _text;
    }

    function toRead() public view returns(string memory) {
        return text;
    }    
}