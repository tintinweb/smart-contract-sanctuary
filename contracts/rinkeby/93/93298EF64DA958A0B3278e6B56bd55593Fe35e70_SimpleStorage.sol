/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    uint storedData;

    function set(uint x) public {
        require(msg.sender == 0x31C54a3B29c1617d796d74910A9C7D911Cc11B89);
        storedData = x;
    }

    function get() public view returns (uint) {
        return storedData;
    }
}