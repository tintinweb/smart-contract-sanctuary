/**
 *Submitted for verification at hecoinfo.com on 2022-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Time {

    function getOneHourLaterTime() public view returns(uint256) {
        return (block.timestamp + 1 hours);
    }

    function getSalt() public returns(bytes32) {
        return keccak256(abi.encode(block.timestamp));
    }

    function getHash() public returns(bytes32) {
        bytes32 hash = keccak256(abi.encode("1"));
        return hash;
    }

}