// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "./Ownable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract FattTimelock is Ownable {

    //using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    //address private _beneficiary;
	
	uint256 private _released;
	uint256 private _startTime;


    constructor (IERC20 token, address beneficiary) public {
        // solhint-disable-next-line not-rely-on-time
        //require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
		transferOwnership(beneficiary);
		_startTime = block.timestamp;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

	function released() public view returns (uint256) {
		return _released;
	}
	
	function tokenBalance() public view returns (uint256) {
		return _token.balanceOf(address(this));
	}
	
	function releasable() public view returns (uint256) {
		uint16[37] memory locked = [0,1500,1792,2084,2376,2668,2960,3252,3544,3836,4128,4420,4712,6042,7084,8126,9168,10210,11252,12294,13336,14378,15420,16462,17504,18546,19588,20630,21672,22714,23756,24798,25840,26882,27924,28966,30000];
		uint256 month = (block.timestamp - _startTime) / 30 days;
		if (month > 36) month = 36;
		uint256 releasableAmount = uint256(locked[month]) * 10 ** 23;
		return (releasableAmount);
	}
	
    function release() public virtual onlyOwner {
	
		uint256 releasableAmount = releasable();

		if (releasableAmount > _released) {
		
			uint256 releaseAmount = releasableAmount - _released;
			require(releaseAmount <= _token.balanceOf(address(this)), "TokenTimelock: no tokens to release");
			_released = _released + releaseAmount;
			_token.transfer(owner(), releaseAmount);
		}
    }
}
