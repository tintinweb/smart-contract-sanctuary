/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
contract TokenTimelock {
    // ERC20 basic token contract being held
    IERC20 public _token;

    // beneficiary of tokens after they are released
    address public _beneficiary;

    // timestamp when token release is enabled
    uint256 public _cyclePeriod;
    uint256 public _amountPerCycle;
    uint256 public _lastUnstakeTime;

    constructor(
        IERC20 token,
        uint256 cyclePeriod,
        uint256 amountPerCycle,
        address beneficiary
    ) public {
        // solhint-disable-next-line not-rely-on-time
        require(amountPerCycle > 0, "TokenTimelock: amount per cycle > 0");
        require(cyclePeriod > 0, "TokenTimelock: cycle period > 0");

        _token = token;
        _beneficiary = beneficiary;
        _cyclePeriod = cyclePeriod;
        _amountPerCycle = amountPerCycle;
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

    function pending() public view returns (uint256) {
        uint256 diffTime = block.timestamp - _lastUnstakeTime;
        uint256 pendingAmount = (diffTime / _cyclePeriod) * _amountPerCycle;
        uint256 tokenAmount = _token.balanceOf(address(this));
        if (tokenAmount > pendingAmount) {
            return pendingAmount;
        }
        return tokenAmount;
    }

    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function release() public {
        // solhint-disable-next-line not-rely-on-time
        require(msg.sender == _beneficiary, "Only beneficiary can approve");

        uint256 pendingAmount = pending();
        require(pendingAmount > 0, "TokenTimelock: no tokens to release");

        _lastUnstakeTime = block.timestamp;
        _token.transfer(_beneficiary, pendingAmount);
    }
}