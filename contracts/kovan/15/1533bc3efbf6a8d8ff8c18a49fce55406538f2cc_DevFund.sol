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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Fund contract - Implements reward distribution.
 * @author Stefan George - <[email protected]>
 * @author Milad Mostavi - <[email protected]>
 * @author Razvan Pop - <@popra>
 */
contract DevFund {
    /// --- External contracts

    // token to be awarded as reward to holders
    IERC20 public rewardToken;

    // token to claim rewards
    IERC20 public holderToken;

    /// --- Storage

    // total reward on contract
    uint256 public totalReward;

    // previously seen reward balance on contract
    uint256 public prevBalance;

    // User's address => Reward at time of withdraw
    mapping(address => uint256) public rewardAtTimeOfWithdraw;

    // User's address => Reward which can be withdrawn
    mapping(address => uint256) public owed;

    /**
     * @dev Contract constructor sets reward token address.
     */
    constructor(address _rewardToken) public {
        rewardToken = IERC20(_rewardToken);
    }

    /// --- Contract functions

    /**
     * @dev if we got some tokens update the totalReward, has to be called on every withdraw
     */
    function updateTotalReward() internal returns (uint256) {
        uint256 currentBalance = rewardToken.balanceOf(address(this));
        if (currentBalance > prevBalance) {
            totalReward += currentBalance - prevBalance;
        }
        return totalReward;
    }

    /**
     * @dev Compute reward for holder. Returns reward.
     * @param forAddress holder address.
     */
    function calcReward(address forAddress) internal view returns (uint256) {
        return
            (holderToken.balanceOf(forAddress) *
                (totalReward - rewardAtTimeOfWithdraw[forAddress])) /
            holderToken.totalSupply();
    }

    /**
     * @dev Withdraws reward for holder. Returns reward.
     */
    function withdrawReward() public returns (uint256) {
        updateTotalReward();
        uint256 value = calcReward(msg.sender) + owed[msg.sender];
        rewardAtTimeOfWithdraw[msg.sender] = totalReward;
        owed[msg.sender] = 0;

        require(value > 0, "DevFund: withdrawReward nothing to transfer");

        rewardToken.transfer(msg.sender, value);

        prevBalance = rewardToken.balanceOf(address(this));

        return value;
    }

    /**
     * @dev Credits reward to owed balance.
     * @param forAddress holder's address.
     */
    function softWithdrawRewardFor(address forAddress)
        external
        returns (uint256)
    {
        updateTotalReward();
        uint256 value = calcReward(forAddress);
        rewardAtTimeOfWithdraw[forAddress] = totalReward;
        owed[forAddress] += value;

        return value;
    }

    /**
     * @dev View remaining reward for an address.
     * @param forAddress holder's address.
     */
    function rewardFor(address forAddress) public view returns (uint256) {
        uint256 _currentBalance = rewardToken.balanceOf(address(this));
        uint256 _totalReward = totalReward +
            (_currentBalance > prevBalance ? _currentBalance - prevBalance : 0);
        return
            owed[forAddress] +
            (holderToken.balanceOf(forAddress) *
                (_totalReward - rewardAtTimeOfWithdraw[forAddress])) /
            holderToken.totalSupply();
    }

    /**
     * @dev Setup function sets dev holder token address and owner, callable only once.
     * @param _holderToken Dev holder Token address.
     */
    function setup(address _holderToken)
        external
        returns (bool)
    {
        require(address(holderToken) == address(0), "DevFund: already setup");

        holderToken = IERC20(_holderToken);

        return true;
    }

    // 0 ETH transfers to trigger withdrawReward
    fallback() external { withdrawReward(); }
}