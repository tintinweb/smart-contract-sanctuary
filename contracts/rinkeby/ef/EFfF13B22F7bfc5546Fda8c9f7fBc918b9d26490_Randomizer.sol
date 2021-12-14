// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./interfaces/IRandomizer.sol";

contract Randomizer is IRandomizer {
	function random() external view override returns (uint256) {
		return uint(keccak256(abi.encodePacked(block.number, block.timestamp))) % 2;
	}
}

pragma solidity ^0.8.0;

interface IRandomizer {
    function random() external returns (uint256);
}