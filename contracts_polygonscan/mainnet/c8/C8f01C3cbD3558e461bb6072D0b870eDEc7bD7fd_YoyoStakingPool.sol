// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SubpoolInteractive.sol";

contract YoyoStakingPool is Ownable {
    
    // Info of each Delegator
    struct Delegator {
        uint256 amount;            // staked yoyo
        uint256 rewardDebt;        // rewards debt 
        bool    hasStaked;         // set true when first staking
        uint256  yoyoAccount;      // related yoyo acount
    }

    mapping(uint256 => address) public yoyoBindAddr;
    mapping(address => Delegator) public delegators;
    address[] public delegatorList;

    IERC20 public immutable LARK;
    IERC20 public immutable StakingPoolToken;
    SubpoolInteractive public immutable LarkPool;

    address public minter;           
    uint256 public lastRewardBlock;
    uint256 public rewardsPerShare;  //*1e12
    uint256 public totalStaked; 

    event Update(uint256 yoyoAccount, address delegator, uint256 amount);
    event DelegatorHarvest(uint256 yoyoAccount, address delegator, uint256 rewardsOut);

    modifier onlyDelegator() {
        require(delegators[msg.sender].hasStaked, "Account is not a delegator");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not the minter");
        _;
    }

    constructor (IERC20 _lark, SubpoolInteractive _LarkPool, IERC20 _stakingPoolToken, uint256 _genesisBlock) {
        LARK = IERC20(_lark);
        totalStaked = 0;
        rewardsPerShare = 0;
        LarkPool = _LarkPool;
        StakingPoolToken = _stakingPoolToken;
        lastRewardBlock = _genesisBlock;
    }

    // update staking, onlyMinter can call this.
    function update(uint256 _yoyoAccount, address _delegator, uint256 _amount)
        external
        onlyMinter
    {
        require(_amount >= 0);

        address aDelegator = yoyoBindAddr[_yoyoAccount];
        
        // if yoyo account and addr hasn't staked before, initializing
        if(aDelegator == address(0) && !delegators[_delegator].hasStaked){
            aDelegator = _delegator;
            yoyoBindAddr[_yoyoAccount] = _delegator; //one to one binding
            delegators[_delegator].amount = 0;
            delegators[_delegator].rewardDebt = 0;
            delegators[_delegator].hasStaked = true;
            delegators[_delegator].yoyoAccount = _yoyoAccount;
            delegatorList.push(_delegator);
        }

        Delegator storage delegator = delegators[aDelegator];

        _updateRewardInfo();

        if (delegator.amount > 0) {
            uint256 pending = delegator.amount * rewardsPerShare / 1e12 - delegator.rewardDebt;
            if(pending > 0) {
                LARK.transfer(aDelegator, pending);
            }
        }

        totalStaked = totalStaked - delegator.amount + _amount;

        delegator.amount = _amount;
        delegator.rewardDebt = _amount * rewardsPerShare / 1e12;

        emit Update(_yoyoAccount, aDelegator, _amount);
    }


    function delegatorHarvest() 
        external
        onlyDelegator
    {
        // There are new blocks created after last updating, so append new rewards before withdraw
        if(block.number > lastRewardBlock) {
            _updateRewardInfo();
        }

        Delegator storage delegator = delegators[msg.sender];
        uint256 pending = delegator.amount * rewardsPerShare / 1e12 - delegator.rewardDebt;
        if(pending > 0) {
            LARK.transfer(msg.sender, pending);
            delegator.rewardDebt = delegator.amount * rewardsPerShare / 1e12;

            emit DelegatorHarvest(delegator.yoyoAccount, msg.sender, pending);
        }
    }


    function _updateRewardInfo() private {
        uint256 currentBlock = block.number;
        if (currentBlock <= lastRewardBlock) return;
        if(totalStaked == 0) return;

        uint256 poolRewards = LarkPool.harvest(5);
        rewardsPerShare = rewardsPerShare + poolRewards * 1e12 / totalStaked;
        lastRewardBlock = block.number;
    }


    function getPendinglark(address _delegator) external view returns (uint256) {
        uint256 currentBlock = block.number;
        uint256 _rewardsPerShare = rewardsPerShare;

        if (currentBlock > lastRewardBlock) {
            uint256 poolRewards = LarkPool.pendingLark(5, address(this));
            _rewardsPerShare = _rewardsPerShare + poolRewards * 1e12 / totalStaked;
        } 
        return delegators[_delegator].amount * _rewardsPerShare / 1e12 - delegators[_delegator].rewardDebt;
    }


    function getDelegatorListLength() external view returns(uint256){
        return delegatorList.length;
    }

    function getDelegators() external view returns(address[] memory delegatorLists){
        delegatorLists = delegatorList;
    }

    function getDelegatorsInfo() external view returns (Delegator[] memory returnData){
        returnData = new Delegator[](delegatorList.length);
        
        for(uint256 i = 0; i < delegatorList.length; i ++){
            returnData[i] = delegators[delegatorList[i]];
        }
        return returnData;
    }

    function poolDeposit() external onlyOwner {
        StakingPoolToken.approve(address(LarkPool), 1 * 1e18);
        LarkPool.deposit(5, 1 * 1e18);
    }

    function poolWithdraw() external onlyOwner {
        LarkPool.withdraw(5, 1 * 1e18);
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Invalid address");
        minter = _minter;
    }
}