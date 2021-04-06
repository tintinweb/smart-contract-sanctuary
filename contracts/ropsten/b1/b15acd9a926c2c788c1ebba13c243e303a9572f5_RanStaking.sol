// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Context.sol";


/*
    Deploy:
        - _im -> address of IM intelligent mining address
        - _fundsWallet -> The wallet that will funds the staking rewards
    After Deploy
        - Need to send to _fundsWallet amount of IM needed for now for staking
        - open allowance for new contract from _fundsWallet on IM intelligent mining address
*/


contract RanStaking is Context{
    mapping (address => uint256) private _balances;

    using SafeMath for uint256;
    IERC20 public im;
    address public fundsWallet;
    mapping(address => uint256) public startLockTime;
    mapping(address => uint256) public lastRewardTime;
    mapping(address => uint256) public rewards;
    uint256 public lockTime = 3 days;
    uint256 public staking_apy = 12;

    // Define the im token contract
    constructor(IERC20 _im, address _fundsWallet) {
        im = _im;
        fundsWallet = _fundsWallet;
    }

    function stake(uint256 _amount) public {
        calcReward();

        im.transferFrom(_msgSender(), address(this), _amount);
        // Lock the IM in the contract
        startLockTime[_msgSender()] = block.timestamp;
        _balances[_msgSender()] += _amount;
    }

    function withdrawn(uint256 _share) public {
        uint256 accountBalance = _balances[_msgSender()];
        require(accountBalance >= _share, "Stake withdrawn exceeds balance");

        uint256 duration = block.timestamp.sub(startLockTime[_msgSender()]);
        require(duration >= lockTime, "IM Lock not expired yet");

        calcReward();
        _balances[_msgSender()] -= _share;

        im.transfer(_msgSender(), _share);
    }

    function withdrawnReward() public {
        calcReward();
        uint256 amount = rewards[_msgSender()];
        rewards[_msgSender()] = 0;

        im.transferFrom(fundsWallet, _msgSender(), amount);
    }
    
    function calcReward() internal {
        uint256 lastReward = lastRewardTime[_msgSender()];
        lastRewardTime[_msgSender()] = block.timestamp;

        // We eligible for rewards
        if (lastReward != 0) {
            uint256 duration = block.timestamp.sub(lastReward);
            uint256 amount = _balances[_msgSender()].mul(staking_apy).div(100).mul(duration).div(365 days);
            rewards[_msgSender()] += amount;
        }
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
}