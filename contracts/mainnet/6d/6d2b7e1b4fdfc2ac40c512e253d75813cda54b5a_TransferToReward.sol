/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;


interface ERC20Like {
    function transferFrom(address _from, address _to, uint256 _value) external;
}


contract TransferToReward {
    function transfer(uint amount) external {
        require(msg.sender == 0xf7D44D5a28d5AF27a7F9c8fc6eFe0129e554d7c4, "not admin");
        
        ERC20Like(0xbbBBBBB5AA847A2003fbC6b5C16DF0Bd1E725f61).
                transferFrom(0x225f27022a50aF2735287262a47bdacA2315a43E, 0xF29e1b04f6f00AeE4EaDe0d1C12640B5D872eD44, amount);
        
    }
}