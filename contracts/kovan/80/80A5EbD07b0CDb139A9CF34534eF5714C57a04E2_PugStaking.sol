/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/PugStaking.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


contract PugStaking {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => mapping(address => UserInfo)) userStakingInfo;
    mapping(address => uint256) totalStaked;
    mapping(address => uint256) accRewardPerShare;
    mapping(address => address) baseTokens;

    address pugToken;
    address pugFactory;

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event RewardWithdrawn(address indexed token, address indexed to, uint256 transferTo);

    modifier onlyPugFactory {
        require(msg.sender == pugFactory, "Not pug factory");
        _;
    }

    constructor(address _pugToken, address _pugFactory) {
        pugToken = _pugToken;
        pugFactory = _pugFactory;
    }

    function addPug(address _baseToken, address _pug) public onlyPugFactory {
        baseTokens[_pug] = _baseToken;
    }

    function addRewards(uint256 _amount) public {
        require(baseTokens[msg.sender] != address(0), "Not a pug");
        if(totalStaked[msg.sender] != 0) {
            accRewardPerShare[msg.sender] += _amount*1e12/totalStaked[msg.sender];
        }
    }

    function deposit(address _pug, uint256 _amount) external {
        UserInfo memory stakingInfo = userStakingInfo[msg.sender][_pug];
        uint256 pugAccRewardPerShare = accRewardPerShare[_pug];
        if(stakingInfo.amount != 0) {
            uint256 pendingReward = (pugAccRewardPerShare * stakingInfo.amount / 1e12) - stakingInfo.rewardDebt;
            transferRewards(baseTokens[_pug], msg.sender, pendingReward);
        }
        IERC20(pugToken).transferFrom(msg.sender, address(this), _amount);
        uint256 userDeposit = stakingInfo.amount + _amount;
        userStakingInfo[msg.sender][_pug] = UserInfo(userDeposit, userDeposit * pugAccRewardPerShare / 1e12);
        emit Deposit(msg.sender, _pug, _amount);
    }

    function withdraw(address _pug, uint256 _amount) external {
        UserInfo memory stakingInfo = userStakingInfo[msg.sender][_pug];
        uint256 pugAccRewardPerShare = accRewardPerShare[_pug];
        uint256 pendingReward = (pugAccRewardPerShare * stakingInfo.amount / 1e12) - stakingInfo.rewardDebt;
        transferRewards(baseTokens[_pug], msg.sender, pendingReward);
        uint256 userDeposit = stakingInfo.amount - _amount;
        userStakingInfo[msg.sender][_pug] = UserInfo(userDeposit, userDeposit * pugAccRewardPerShare / 1e12);
        IERC20(pugToken).transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _pug, _amount);
    }

    function withdrawRewards(address _user, address _pug) external {
        UserInfo memory stakingInfo = userStakingInfo[_user][_pug];
        uint256 pugAccRewardPerShare = accRewardPerShare[_pug];
        uint256 pendingReward = (pugAccRewardPerShare * stakingInfo.amount / 1e12) - stakingInfo.rewardDebt;
        userStakingInfo[_user][_pug].rewardDebt = stakingInfo.amount * pugAccRewardPerShare / 1e12;
        transferRewards(baseTokens[_pug], _user, pendingReward);
    }

    function transferRewards(address token, address to, uint256 amount) internal {
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 toTransfer;
        if(amount > balance) {
            toTransfer = balance;
        } else {
            toTransfer = amount;
        }
        IERC20(token).transfer(to, toTransfer);
        emit RewardWithdrawn(token, to, toTransfer);
    }
}