// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";
import "./Ownable.sol";

contract ImStaking is Context, Ownable{
    mapping (address => uint256) private _stakeBalances;
    uint256 public totalStaking = 0;

    using SafeMath for uint256;
    IERC20 public im;
    address public fundsWallet;
    mapping(address => uint256) public startLockTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public rewards;
    uint256 constant public lockTime = 3 days;
    uint256 constant public staking_apy = 12;

    /**
     * @dev Emitted when `amount` tokens are staked in this contract
     *
     * Note that `amount` may be zero.
     */
    event Stake(address indexed from, uint256 amount);

    /**
     * @dev Emitted when `amount` tokens are withdrawn from this contract
     *
     * Note that `amount` may be zero.
     */
    event Withdrawn(address indexed to, uint256 amount);

    /**
     * @dev Emitted when `amount` reward tokens are taken from in this contract
     *
     * Note that `amount` may be zero.
     */
    event WithdrawnReward(address indexed from, address indexed to, uint256 amount);
    
    // Define the im token contract
    constructor(IERC20 _im, address _fundsWallet) {
        im = _im;
        fundsWallet = _fundsWallet;
    }

    function stake(uint256 _amount) external {
        calcReward();

        startLockTime[_msgSender()] = block.timestamp;
        _stakeBalances[_msgSender()] += _amount;
        totalStaking += _amount;

        // Lock the IM in the contract
        require(im.transferFrom(_msgSender(), address(this), _amount) == true, "Stake failed");
        emit Stake(_msgSender(), _amount);
    }

    function withdrawn(uint256 _amount) external {
        uint256 accountBalance = _stakeBalances[_msgSender()];
        require(accountBalance >= _amount, "Withdrawn exceeds balance");
        require(_amount != 0, "Withdrawn is zero");

        uint256 duration = block.timestamp.sub(startLockTime[_msgSender()]);
        require(duration >= lockTime, "IM Lock not expired yet");

        calcReward();
        _stakeBalances[_msgSender()] -= _amount;
        totalStaking -= _amount;
        bool withdrawnSucceeded = im.transfer(_msgSender(), _amount);
        if (withdrawnSucceeded) {
            emit Withdrawn(_msgSender(), _amount);
        }
    }

    function emergencyWithdrawn() external onlyOwner {
        uint256 contractTokenHold = im.balanceOf(address(this));
        uint256 lockFunds = contractTokenHold - totalStaking;
        require(lockFunds > 0, "No lock funds");

        im.transfer(owner(), lockFunds);
    }

    function withdrawnReward() external {
        calcReward();
        uint256 amount = rewards[_msgSender()];
        require(amount != 0, "Withdrawn reward is zero");

        rewards[_msgSender()] = 0;

        bool withdrawnRewardSucceeded = im.transferFrom(fundsWallet, _msgSender(), amount);
        if (withdrawnRewardSucceeded) {
            emit WithdrawnReward(fundsWallet, _msgSender(), amount);
        }
    }
    
    function calcReward() internal {
        uint256 lastReward = lastRewardTime[_msgSender()];
        lastRewardTime[_msgSender()] = block.timestamp;

        // We eligible for rewards
        if (lastReward != 0) {
            uint256 duration = block.timestamp.sub(lastReward);
            uint256 amount = _stakeBalances[_msgSender()].mul(staking_apy).mul(duration).div(100).div(365 days);
            rewards[_msgSender()] += amount;
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function stakeBalanceOf(address account) public view returns (uint256) {
        return _stakeBalances[account];
    }
}