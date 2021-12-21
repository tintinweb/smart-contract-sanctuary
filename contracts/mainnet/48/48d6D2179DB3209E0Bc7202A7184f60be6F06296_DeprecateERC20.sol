// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// ============ External Imports ============
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
DeprecateERC20
by Anna Carroll
*/
contract DeprecateERC20 {
    // ============ Immutables ============

    IERC20 public immutable oldToken;
    uint256 public immutable exchangeRate;

    // ============  Public Storage ============

    IERC20 public newToken;
    // amount of oldToken migrated; target = 25k (all crowdfund tokens)
    uint256 public totalMigrated;

    // ============  Events ============

    event Migrated(address indexed owner, uint256 oldTokenAmount);

    // ======== Constructor =========

    constructor(address _oldToken, uint256 _exchangeRate) {
        // set oldToken and exchangeRate
        oldToken = IERC20(_oldToken);
        exchangeRate = _exchangeRate;
    }

    // ======== Initializer =========

    function initialize(address _newToken) external {
        require(address(newToken) == address(0), "already initialized");
        newToken = IERC20(_newToken);
    }

    // ======== External Functions =========

    /**
     * @notice Transfer token holder's entire balance of old token to burn address
     * in exchange for fixed rate of new token
     * @dev Token Holder must approve this contract to spend
     * their total balance of oldToken before calling migrate
     */
    function migrate(address _tokenHolder) external {
        // get function token holder's balance of old token
        uint256 _oldBalance = oldToken.balanceOf(_tokenHolder);
        // send total balance of old token to burn address
        oldToken.transferFrom(_tokenHolder, address(0), _oldBalance);
        // send balance of new token to caller
        newToken.transfer(_tokenHolder, _oldBalance * exchangeRate);
        // update total & emit event
        totalMigrated += _oldBalance;
        emit Migrated(_tokenHolder, _oldBalance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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