//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract checkContract {
    function isContract() public view returns (bool) {
        uint32 size;
        address a = msg.sender;
        assembly {
            size := extcodesize(a)
        }
        return (size > 0);
    }
}