/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

contract StringTest {
    string public name;
    function setName(string memory _string) public{
        name = _string;        
    }
}