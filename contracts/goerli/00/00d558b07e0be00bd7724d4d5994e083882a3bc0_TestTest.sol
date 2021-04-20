/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract TestTest {
    
    event StringChanged(string oldString, string newString);
    event NewElementAddedToArray(uint256 newArrayLength, uint256 newElement);
    
    uint256[] public myArr;
    string public myStr;
    
    function changeString(string memory str) public {
        emit StringChanged(myStr, str);
        myStr = str;
    }
    
    function addElement(uint256 el) public {
        myArr.push(el);
        emit NewElementAddedToArray(myArr.length, el);
    }
}