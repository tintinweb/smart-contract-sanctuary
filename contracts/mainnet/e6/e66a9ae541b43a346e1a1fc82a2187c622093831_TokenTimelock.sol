// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeERC20.sol";
import "./SafeMath.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20 private _token;

    // beneficiary of tokens after they are released
    address private _beneficiary;

    // timestamp when token release is enabled
    uint256 private _releaseTime;
    
    // percentage of the token relasing per time (withdrawTimeLimit)
    uint256 private _releaseLimit;
    
    // withdraw time limit as time interval
    uint256 private _withdrawTimeLimit;

    constructor (IERC20 token, address beneficiary, uint256 releaseTime, uint256 releaseLimit, uint256 withdrawTimeLimit) public {
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, "TokenTimelock: release time is before current time");
        _token = token;
        _beneficiary = beneficiary;
        _releaseTime = releaseTime;
        _releaseLimit = releaseLimit;
        _withdrawTimeLimit = withdrawTimeLimit;
    }

    /**
     * @return the token being held.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view returns (address) {
        return _beneficiary;
    }

    /**
     * @return the time when the tokens are released.
     */
    function releaseTime() public view returns (uint256) {
        return _releaseTime;
    }

    /**
     * @return the percentage of the token releasing per time (withdrawTimeLimit).
     */
    function releaseLimit() public view returns (uint256) {
        return _releaseLimit;
    }

    /**
     * @return the time interval of the token withdraw.
     */
    function withdrawTimeLimit() public view returns (uint256) {
        return _withdrawTimeLimit;
    }
    
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= _releaseTime, "TokenTimelock: current time is before release time");

        uint256 amount = _token.balanceOf(address(this));
        require(amount > 0, "TokenTimelock: no tokens to release");

        _token.safeTransfer(_beneficiary, amount.mul(_releaseLimit).div(100));
        
        _releaseTime = _releaseTime.add(_withdrawTimeLimit);
    }
}
