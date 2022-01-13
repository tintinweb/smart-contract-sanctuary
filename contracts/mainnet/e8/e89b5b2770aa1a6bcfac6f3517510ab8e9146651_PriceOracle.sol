/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface Pair {
	function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


contract PriceOracle {
	function getPrice() external view returns (uint256) {
		Pair _ethUSDC = Pair(0xB4e16d0168e52d35CaCD2c6185b44281Ec28C9Dc);
		(uint256 _resUSDC, uint256 _resETH, ) = _ethUSDC.getReserves();
		return 1e30 * _resUSDC / _resETH;
	}
}