// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Stake {
    IERC20 stakingToken;
    IERC20 rewardToken;

    event Staking(address staker, uint256 amount);
    event Withdrawing(address staker, uint256 amount);
    event Rewarding(address staker, uint256 amount);

    uint rate = 500;
    uint256 private _totalSupply;

    struct Stakes {
        uint256 amount;
        uint startedTime;
        uint releaseTime;
        uint numberOfDays;
        uint lastUpdateTime;
        uint256 rewards;
        bool isActive;
    }
    mapping(address => Stakes) public stakes;

    modifier updateReward(address account) {
        stakes[account].rewards = earned(account);
        stakes[account].lastUpdateTime = block.timestamp;
        _;
    }

    constructor() {
        address _stakingToken = 0xbbFc5D2A55E0EA0E0A9688DbFc63BCf788b1766a;
        address _rewardToken = 0xbbFc5D2A55E0EA0E0A9688DbFc63BCf788b1766a;
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
    }
    
    function stake(uint _amount, uint _numberOfDays) external updateReward(msg.sender) {
        require(_amount >= 1 * 1e18, "too small");
        require( _numberOfDays >= stakes[msg.sender].numberOfDays, "not a valid days");

        if(!stakes[msg.sender].isActive){
           stakes[msg.sender].startedTime = block.timestamp;
        }

        _totalSupply += _amount;
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].releaseTime = stakes[msg.sender].startedTime + (_numberOfDays * 1 days);
        stakes[msg.sender].numberOfDays = _numberOfDays;
        stakes[msg.sender].isActive = true;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staking(msg.sender,_amount);
    }

    function unstake() external updateReward(msg.sender) {
        require(block.timestamp > stakes[msg.sender].releaseTime, "not released");
        require(stakes[msg.sender].amount > 0, "no staking");

        _totalSupply -= stakes[msg.sender].amount;
        stakingToken.transfer(msg.sender, stakes[msg.sender].amount);
        emit Withdrawing(msg.sender,stakes[msg.sender].amount);
        delete stakes[msg.sender];
    }

    function getStake() public view returns(uint256) {
        return stakes[msg.sender].amount;
    }

    function rewardPerToken(address account) public view returns (uint) {
        return  (stakes[account].amount / 1e16) * rate / 10000;
    }

    function earned(address account) public view returns (uint256) {
        return
            ((block.timestamp - stakes[account].lastUpdateTime) * rewardPerToken(msg.sender))+
            stakes[account].rewards;
    }

    function getReward() external updateReward(msg.sender) {
        uint reward = stakes[msg.sender].rewards;
        stakes[msg.sender].rewards = 0;
        rewardToken.transfer(msg.sender, reward);

        emit Rewarding(msg.sender, reward);
    }
}

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