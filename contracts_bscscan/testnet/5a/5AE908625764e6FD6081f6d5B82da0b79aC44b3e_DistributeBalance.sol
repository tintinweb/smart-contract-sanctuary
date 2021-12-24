/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract DistributeBalance {
    function distribute(address payable[] memory accounts) public payable{
        uint value = msg.value;
        uint equalValue = value / (accounts.length + 1);

        for (uint i = 0; i < accounts.length; i++) {
            (bool sent, bytes memory data) = accounts[i].call{value: equalValue}("");
            require(sent, "Failed to send Ether");
        }
    }
}