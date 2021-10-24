// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";
import "./interfaces/IERC20.sol";

/**
 * @dev Contract for rektless liquidity migration
 */
contract RektlessMigrator {

    IStaking vulnContract;
    IERC20 vulnToken;
    IStaking fixedContract;

    constructor(address _vulnContract, address _fixedContract) {
        vulnContract = IStaking(_vulnContract);
        fixedContract = IStaking(_fixedContract);
        vulnToken = IERC20(_vulnContract);
    }

    /**
     * @dev Emergency withdraws user's tokens and stakes for it in fixed contract
     */
    function migrateToFixedContract() external {
        uint amount = vulnToken.balanceOf(msg.sender);
        vulnToken.transferFrom(msg.sender, address(this), amount);
        vulnContract.emergencyWithdraw(address(this));
        fixedContract.stakeFor{value:amount}(msg.sender);
    }

    /**
     * @dev Emergency withdraws tokens to user's account
     */
    function migrateToUserAddress() external {
        uint amount = vulnToken.balanceOf(msg.sender);
        vulnToken.transferFrom(msg.sender, address(this), amount);
        vulnContract.emergencyWithdraw(msg.sender);
    }
    
    fallback() external payable {

    }

    receive() external payable {

    }

}

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @dev Interface for the staking contract
 */
interface IStaking {

    /**
     * @dev Stake token
     */
    function stake() payable external;

    /**
     * @dev Stake token for other account
     */
    function stakeFor(address account) payable external;

    /**
     * @dev Withdraw user stake
     */
    function withdraw(uint amount) external;

    /**
     * @dev Emergency withdraw for user tokens losing rewards
     */
    function emergencyWithdraw(address to) external;

    /**
     * @dev Pauses/unpauses contract
     */
    function pause(bool _status) external;
}