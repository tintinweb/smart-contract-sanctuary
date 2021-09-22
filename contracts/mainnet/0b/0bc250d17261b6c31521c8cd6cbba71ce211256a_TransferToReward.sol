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
        
        ERC20Like(0xC7F0e3118B24f30A6Aa7d703E198996F04B64e32).
                transferFrom(0x3328D5b2CabDF25a9AaD31Ae52f660398c54b6cE, 0xAf50fe9282e1bE8C08b899a51628a085E81d0D57, amount);
        
    }
}