/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Test {
    
    /**
     * @dev getBalance
     * @param balance of address
     */
    function getBalance(address user) public view returns(uint256 balance) {
        return user.balance;
    }
    
    /**
     * @dev blockNumber
     * @param number of block
     */
     function getBlockNumber() public view returns(uint256 number) {
        return block.number;
    }
}