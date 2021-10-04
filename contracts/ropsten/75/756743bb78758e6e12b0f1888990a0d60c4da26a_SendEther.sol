/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SendEther {
    
    function sendViaTransfer(address payable _to, uint256 amount) public {
        _to.transfer(amount);
    }

    function sendViaSend(address payable _to, uint256 amount) public {
        bool sent = _to.send(amount);
        require(sent, "Failed to send Ether");
    }

    function sendViaCall(address payable _to, uint256 amount) public {
        (bool sent, bytes memory data) = _to.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }
}