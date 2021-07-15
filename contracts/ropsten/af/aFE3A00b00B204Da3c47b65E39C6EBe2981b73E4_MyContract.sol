/**
 *Submitted for verification at Etherscan.io on 2021-07-15
*/

// File: solidity/contracts/MyContract.sol

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.7.6;

contract MyContract {
    address private immutable addr;

    constructor(address _addr) {
        addr = _addr;
    }

    function getAddr() external view returns (address) {
        return addr;
    }
}