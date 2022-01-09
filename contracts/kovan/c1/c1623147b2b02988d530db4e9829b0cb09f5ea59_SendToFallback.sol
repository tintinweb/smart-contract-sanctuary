/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10 <0.9.0;

contract SendToFallback {
    // 用 transfer 調用 39. fallback
    function transferToFallback(address payable _to) public payable {
        _to.transfer(msg.value);
    }

    // 用 call 調用 39. fallback
    function callFallback(address payable _to) public payable {
        (bool sent, ) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}