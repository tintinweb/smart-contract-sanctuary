/**
 *Submitted for verification at Etherscan.io on 2021-03-21
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

    address public immutable receiver;
    address public immutable wethAddress;

    constructor(address receiver_, address wethAddress_) public {
        // Initialize immutable storage.
        receiver = receiver_;
        wethAddress = wethAddress_;
    }

    // When it receives ETH, it wraps it and transfers it.
    receive() external payable {
        IWETH(wethAddress).deposit{value: msg.value}();
        IWETH(wethAddress).transfer(receiver, msg.value);
        Recipient(receiver).unwrapWETH(msg.value);
    }
}