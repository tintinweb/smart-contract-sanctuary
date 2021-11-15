// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract RandomGenUtils {
    function randomGen(uint256 seed, uint256 max) external view returns (uint256 randomNumber) {
        return (uint256(
            keccak256(
                abi.encodePacked(blockhash(block.number - 1), block.timestamp, msg.sender, block.difficulty, seed)
            )
        ) % max);
    }
}

