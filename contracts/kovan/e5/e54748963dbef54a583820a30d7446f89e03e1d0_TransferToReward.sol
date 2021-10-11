/**
 *Submitted for verification at Etherscan.io on 2021-10-10
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


interface ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) external;
}


contract TransferToReward {
    function transfer(uint amount) external {
        require(msg.sender == 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, "not admin");
        
        ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61).
                transferFrom(0xC507A27860C225aaD8CB4a5A32a44d8892288880, 0x9f4cFcDf4942dD1e6aF2e0b53E70524F31708CE7, amount);
        
    }
}