/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;


interface ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) external;
}


contract TransferToGrowth {

    function transferSafe() external {
        require(msg.sender == 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, "not admin");
            
        address[3] memory dests = [
            0x803740916F4e6aB4F64E957a68eB7F62392dEE3e,
            0xa9d062B23650C9191673d9496d9e700d37DC55f5,
            0x92aE9Aca769778610d1485130e382Ca5A3e4f469
        ];

        for(uint i = 0 ; i < dests.length ; i++) {
            ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61).
                    transferFrom(0xC507A27860C225aaD8CB4a5A32a44d8892288880, dests[i], 1000e18);
        }
    }
}