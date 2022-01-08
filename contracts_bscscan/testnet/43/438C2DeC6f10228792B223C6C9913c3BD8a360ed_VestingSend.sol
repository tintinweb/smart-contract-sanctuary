/**
 *Submitted for verification at BscScan.com on 2022-01-07
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract VestingSend {
    IERC20 token;

    // set to true when the contract owns all the required token
    bool public initialized;

    uint256 public totalToRedeem;
    mapping(address => uint256) public toRedeem;
    uint64[] public tickCompoundedDurationInSec;

    mapping(address => uint256) public lastRedeemTimestamp;
    uint256 public deployTimestamp;
    uint64[] public tickCompoundedPercentageUnlocked;

    constructor(address _token,
        address[] memory addresses, uint256[] memory amounts,
        uint64[] memory _tickCompoundedPercentageUnlocked, uint64[] memory _tickCompoundedDurationInSec) {
        // input validation
        require(addresses.length == amounts.length, "backers addresses & amounts need to have the same size");
        require(_tickCompoundedPercentageUnlocked.length == _tickCompoundedDurationInSec.length, "tick duration & percentages need to have the same size");
        require(_tickCompoundedPercentageUnlocked.length > 0, "must have at least one tick");

        token = IERC20(_token);
        deployTimestamp = block.timestamp;
        tickCompoundedDurationInSec = _tickCompoundedDurationInSec;
        tickCompoundedPercentageUnlocked = _tickCompoundedPercentageUnlocked;

        // last % tick is 100
        require(_tickCompoundedPercentageUnlocked[_tickCompoundedPercentageUnlocked.length - 1] == 100, "need to give out exactly 100 percentages");

        // make sure all compounded entries are increasing
        for (uint256 i = 1; i < _tickCompoundedDurationInSec.length; i++) {
            require(_tickCompoundedDurationInSec[i] > _tickCompoundedDurationInSec[i - 1], "ticks compound duration needs to increase");
            require(_tickCompoundedPercentageUnlocked[i] > _tickCompoundedPercentageUnlocked[i - 1], "ticks compound percentage needs to increase");
        }

        for (uint256 i = 0; i < addresses.length; i++) {
            toRedeem[addresses[i]] = amounts[i];
            totalToRedeem += amounts[i];
        }
    }

    function initialize() external {
        require(initialized == false, "already initialized");
        // ensure the contract owns all the token that it needs to give out
        // token.transferFrom(msg.sender, address(this), totalToRedeem);
        initialized = true;
    }

    function _timestampToPercentage(uint256 timestamp) private view returns (uint256) {
        if (timestamp < deployTimestamp) {
            return 0;
        }
        uint256 diff = timestamp - deployTimestamp;
        if (tickCompoundedDurationInSec[0] > diff) {
            return 0;
        }
        for (int256 i = int256(tickCompoundedDurationInSec.length) - 1; i >= 0; i--) {
            if (diff >= tickCompoundedDurationInSec[uint256(i)]) {
                return tickCompoundedPercentageUnlocked[uint256(i)];
            }
        }

        require(false, "impossible scenario");
        return 0;
    }

    function received(address addr) external view returns (uint256) {
        uint256 total = toRedeem[addr];
        if (total == 0) {
            return 0;
        }

        uint256 redeemedPercentage = _timestampToPercentage(lastRedeemTimestamp[addr]);
        return total * redeemedPercentage / 100;
    }

    function canRedeem(address addr) external view returns (uint256) {
        uint256 total = toRedeem[addr];
        if (total == 0) {
            return 0;
        }

        uint256 unlockedPercentage = _timestampToPercentage(block.timestamp);
        return total * unlockedPercentage / 100 - this.received(addr);
    }

    function redeem() external returns (bool) {
        require(initialized == true, "contract needs to be initialized before redeeming can start");

        uint256 canRedeemAmount = this.canRedeem(msg.sender);
        if (canRedeemAmount == 0) {
            return false;
        }

        lastRedeemTimestamp[msg.sender] = block.timestamp;
        token.transfer(msg.sender, canRedeemAmount);
        return true;
    }
}