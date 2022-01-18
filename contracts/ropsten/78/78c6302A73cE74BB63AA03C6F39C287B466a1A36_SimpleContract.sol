//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract SimpleContract {
    function getValue(uint item) public pure returns(uint) {
       return item;
    }
}