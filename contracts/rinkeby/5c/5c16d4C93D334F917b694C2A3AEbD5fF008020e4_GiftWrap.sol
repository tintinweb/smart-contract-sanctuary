/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);
}

interface Recipient {
    function unwrapWETH(uint256 amount) external;
}

contract GiftWrap {
    //==== Immutable storage. =====
    address public immutable wethAddress;

    constructor(address wethAddress_) public {
        wethAddress = wethAddress_;
    }

    function gift(address receiver) external payable {
        IWETH(wethAddress).deposit{value: msg.value}();
        IWETH(wethAddress).transfer(receiver, msg.value);
        Recipient(receiver).unwrapWETH(msg.value);
    }
}