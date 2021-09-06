/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

contract SebastianTokenMultiSend {
    ISebastianToken private _token;

    constructor(address tokenAddress) {
        _token = ISebastianToken(address(tokenAddress));
    }

    function sendToMultiple(address[] memory contributors, uint256 amount) public {
        for(uint256 i = 0; i < contributors.length; i++) {
            _token.transferFrom(msg.sender,contributors[i], amount);
        }
    }
}

contract ISebastianToken {
    function transferFrom(address sender, address to, uint256 amount) public returns (bool) { }
}