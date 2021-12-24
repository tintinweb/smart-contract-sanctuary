/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract SendEther {
    function sendviaCall(address payable _to) public payable {
        (bool sent ,) = _to.call{value: msg.value}("");
        require(sent ,"Failed to send Ether");
    }
}