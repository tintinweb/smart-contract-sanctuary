/**
 *Submitted for verification at BscScan.com on 2021-11-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract PRNG {
	function getPseudoRandomNumber() external view returns(uint256) {
		uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                    (block.timestamp)) + block.number
				)
            )
        );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            return 1;
        }

		return randNumber;
	}
}