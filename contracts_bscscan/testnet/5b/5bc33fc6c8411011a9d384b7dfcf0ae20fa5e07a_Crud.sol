/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Crud {
    uint[] private number;

    function readNumber() public view returns(uint[] memory) {
        return number;
    }

    function updateNumber(uint index, uint _number) public {
        number[index] = _number;
    }

    function createNumber(uint _number) public {
        number.push(_number);
    }

    function deleteNumber(uint index) public {
        delete number[index];
    }

}