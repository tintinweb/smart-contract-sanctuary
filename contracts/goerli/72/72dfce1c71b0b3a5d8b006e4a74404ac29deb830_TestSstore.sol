/**
 *Submitted for verification at Etherscan.io on 2021-06-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.2;
pragma experimental ABIEncoderV2;

contract TestSstore {
    function wasteGas() internal view {
        uint256 blockNumber = block.number;
        for (uint256 i = 1; i < 150; i+=1) {
            require(blockhash(blockNumber - i) != bytes32(0));
        }
    }
    uint256 private val;
    function set() external payable {
        wasteGas();
        val = tx.gasprice % 3;
    }
}