// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;


contract mockToken{
    constructor(){}

    fallback() external payable {
    }
    receive() external payable {
    }

    function sendTo(address _to, uint256 amount) public {
        _to.call{value: amount}("");
    }
}

