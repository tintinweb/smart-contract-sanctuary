/**
 *Submitted for verification at Etherscan.io on 2021-05-23
*/

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

struct Wallets {
    address team;
    address charity;
    address staking;
    address liquidity;
}

contract DistributionWallet {
    IERC20 token;
    Wallets public wallets;

    event Distributed(uint256 amount);

    constructor(address _token, Wallets memory _wallets) {
        token = IERC20(_token);
        wallets = _wallets;
    }

    function distribute() public {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "no tokens to transfer");
        emit Distributed(balance);
        uint256 distributionReward = balance / 1000;
        balance -= distributionReward;
        uint256 teamAmount = (balance * 15) / 100;
        uint256 charityAmount = (balance * 625) / 10000;
        uint256 liquidityAmount = (balance * 375) / 10000;
        uint256 stakingAmount =
            balance - teamAmount - charityAmount - liquidityAmount;
        token.transfer(wallets.team, teamAmount);
        token.transfer(wallets.charity, charityAmount);
        token.transfer(wallets.liquidity, liquidityAmount);
        token.transfer(wallets.staking, stakingAmount);
        token.transfer(msg.sender, distributionReward);
    }
}