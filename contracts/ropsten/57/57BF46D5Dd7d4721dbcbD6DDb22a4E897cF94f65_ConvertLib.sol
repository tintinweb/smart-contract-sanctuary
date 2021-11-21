/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.25 <0.7.0;

library ConvertLib{
	function convert(uint amount,uint conversionRate) public pure returns (uint convertedAmount)
	{
		return amount * conversionRate;
	}
}