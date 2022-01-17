//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract checkContract {
    function isContract(address addr) public view returns (bool) {
        uint32 size;
        // address a = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }
}