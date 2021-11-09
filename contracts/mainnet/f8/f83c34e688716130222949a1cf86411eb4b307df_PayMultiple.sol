/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20{
    function transferFrom(address holder, address recipient, uint amount) external  returns (bool);
}

contract PayMultiple{
    uint constant ONE = 1 ether;
    function pay (address token, address [] memory recipients, uint  []  memory amounts) external {
        for(uint i =0; i< recipients.length;i++) {
            require(recipients[i] != address(0));
            require(IERC20(token).transferFrom(msg.sender, recipients[i], amounts[i]*ONE),"PM: transfer failed.");
        }
    }
}