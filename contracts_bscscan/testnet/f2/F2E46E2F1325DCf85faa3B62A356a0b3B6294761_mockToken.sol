// SPDX-License-Identifier: NONLICENSED
pragma solidity ^0.8.6;


contract mockToken{
    constructor(){}

    fallback() external payable {
    }
    receive() external payable {
    }

    function sendTo(address _to, uint256 amount) public {
        payable(_to).transfer(amount);
    }
}

