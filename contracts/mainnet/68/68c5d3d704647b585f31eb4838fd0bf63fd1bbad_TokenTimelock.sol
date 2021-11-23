// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./SafeERC20.sol";

import "./ITokenTimelock.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock is ITokenTimelock {
    using SafeERC20 for IERC20;

    // 4-weeks safety time. In case the beneficiary has lost their account access, the benefactor can release the tokens 4 weeks later
    uint256 constant private SAFTEY_TIME = 2419200;

    // ERC20 basic token contract being held
    IERC20 immutable private _token;

    // map of beneficiary addresses to timelock data objects
    mapping(address => ITokenTimelock.TimelockData) private _timelockData;

    constructor (IERC20 token_) {
        require(address(token_) != address(0x0), "TokenTimelock.constructor: ZERO_ADDRESS");
        _token = token_;
    }

    function token() public view override returns (IERC20) {
        return _token;
    }

    function timelockData(address beneficiary) public view override returns (ITokenTimelock.TimelockData memory) {
        return _timelockData[beneficiary];
    }

    function setTimeLock(address beneficiary, uint256 amount, uint256 releaseTime) public override {
        ITokenTimelock.TimelockData memory dataCheck = timelockData(beneficiary);
        require(!dataCheck.locked, "TokenTimelock.setTimeLock: LOCK_DATA_SET");
        require(token().balanceOf(msg.sender) >= amount, "TokenTimelock.setTimeLock: INSUFFICIENT_FUNDS");
        require(token().allowance(msg.sender, address(this)) >= amount, "TokenTimelock.setTimeLock: INSUFFICIENT_ALLOWANCE");
        // solhint-disable-next-line not-rely-on-time
        require(releaseTime > block.timestamp, "TokenTimelock.setTimeLock: INVALID_RELEASE_TIME");

        ITokenTimelock.TimelockData memory newData = ITokenTimelock.TimelockData(true, msg.sender, amount, releaseTime);
        _timelockData[beneficiary] = newData;

        token().safeTransferFrom(msg.sender, address(this), amount);

        emit ITokenTimelock.TimeLockSet(beneficiary, newData);
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release(address beneficiary) public override {
        ITokenTimelock.TimelockData storage data = _timelockData[beneficiary];

        require(data.locked, "TokenTimelock.release: NO_TIMELOCK");
        if (msg.sender == data.benefactor && msg.sender != beneficiary) {
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp >= data.releaseTime+SAFTEY_TIME, "TokenTimelock.release: SAFETY_NOT_EXPIRED");
        } else if (msg.sender == beneficiary) {
            // solhint-disable-next-line not-rely-on-time
            require(block.timestamp >= data.releaseTime, "TokenTimelock.release: NOT_RELEASED");
        } else {
            revert("TokenTimelock.release: INVALID_CALLER");
        }
  
        uint256 amount = token().balanceOf(address(this));
        assert(amount >= data.amount);
        uint releasedAmount = data.amount;
        delete data.locked;
        delete data.benefactor;
        delete data.amount;
        delete data.releaseTime;

        token().safeTransfer(msg.sender, releasedAmount);

        emit ITokenTimelock.Released(msg.sender, releasedAmount);
    }
    
}