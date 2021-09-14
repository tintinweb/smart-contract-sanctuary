/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Coinflip {
    function XXX(uint256 i, address _to) external payable {
        bytes32 hash = keccak256(abi.encodePacked(i, block.number, block.difficulty, _to));
        bool e = uint256(hash) % 2 == 0;
        require(e, "tails...");
        block.coinbase.transfer(msg.value);
    }
}