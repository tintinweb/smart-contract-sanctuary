/**
 *Submitted for verification at Etherscan.io on 2021-12-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.7;

contract SendToFallback {
    //  send Ether directly but receive() does not exist
    function transferToFallback(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    // call an NULL function to triggers fallback function
    function callFallback(address payable _to) public payable {
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}