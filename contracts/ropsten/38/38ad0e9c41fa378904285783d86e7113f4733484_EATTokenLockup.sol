/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity ^0.8.0;

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// File: @openzeppelin/contracts/token/ERC21/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time - the amount of coin allowed to be recovered
 * is proportional to the time taken. 
 *
 * This contract will be used to lock up 40% of minted ChowCoin (40 million coins)
 * over the course of 40 months specified in 30 day increments. Calling the release
 * method will recover the total number of available tokens after the given time period
 * and transfer the tokens back into the minting account.
 */
contract EATTokenLockup {

    // ERC20 basic token contract being held
    IERC20 immutable private _token;

    // beneficiary of tokens after they are released
    address immutable private _beneficiary;

    // time in seconds that the lockup should occur for
    uint256 immutable private _totalLockupDuration;

    // total number of increments of coin that should be released by
    uint256 immutable private _totalIncrements;

    // total number of tokens saved at this address
    uint256 immutable private _totalNumTokens;

    // start time of the lockup in epoch seconds
    uint256 immutable private _startTime;

    constructor (IERC20 token_, uint256 duration_, uint256 increments_, uint256 numTokens_) {
        _token = token_;
        _beneficiary = msg.sender;
        _totalLockupDuration = duration_;
        _totalIncrements = increments_;
        _totalNumTokens = numTokens_;
        _startTime = block.timestamp;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20) {
        return _token;
    }

    /**
     * @return the beneficiary of the tokens.
     */
    function beneficiary() public view virtual returns (address) {
        return _beneficiary;
    }

    /**
     * @return the total duration of the lockup in seconds
     */
    function duration() public view virtual returns (uint256) {
        return _totalLockupDuration;
    }

    /**
     * @return the total remaining time for the lockup
     */
    function remainingDuration() public view virtual returns (uint256) {
        require(block.timestamp <= _startTime + _totalLockupDuration, "EATTokenLockup: all tokens are avilable for release");
        return _startTime + _totalLockupDuration - block.timestamp;
    }

    /**
     * @return the total number of tokens available for release.
     */
    function numReleasableTokens() public view virtual returns (uint256) {
        uint256 timeIncrementSize = _totalLockupDuration / _totalIncrements;
        uint256 timeDuration = block.timestamp - _startTime;
        uint256 numTokensInIncrement = _totalNumTokens / _totalIncrements;
        uint256 incrementsAvailable = Math.min256(timeDuration / timeIncrementSize, _totalIncrements);
        uint256 maxNumTokensAvailable = incrementsAvailable * numTokensInIncrement;
        uint256 numTokensReleased = _totalNumTokens - remainingTokens();
        uint256 numTokensAvailable = maxNumTokensAvailable - numTokensReleased;
        return numTokensAvailable;
    }

    /**
     * @return the total number of increments in which coins are released
     */
    function increments() public view virtual returns (uint256) {
        return _totalIncrements;
    }

    /**
     * @return the total remaining coins held within the lockup
     */
    function remainingTokens() public view virtual returns (uint256) {
        return _token.balanceOf(address(this));
    }

    /**
     * @return the total remaining coins held within the lockup
     */
    function tokensReleased() public view virtual returns (uint256) {
        return _totalNumTokens - _token.balanceOf(address(this));
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public virtual {
        uint256 amount = token().balanceOf(address(this));
        require(amount > 0, "EATTokenLockup: no tokens remaining to release");
        // solhint-disable-next-line not-rely-on-time
        uint256 numTokensAvailable = numReleasableTokens();
        require(amount >= numTokensAvailable, "EATTokenLockup: not enough tokens available");
        token().transfer(beneficiary(), numTokensAvailable);
    }
}