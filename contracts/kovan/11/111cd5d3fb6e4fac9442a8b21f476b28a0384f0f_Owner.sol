/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Owner
 * @dev Set & change owner
 */
contract Owner {
    uint public safeVolatilityPeriod;
    
    constructor () {
		safeVolatilityPeriod = 4 hours;
    }
    
	function check(uint _timestamp) external {
	    require(_timestamp + safeVolatilityPeriod <= block.timestamp);
	}
}