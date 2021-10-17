// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./SubpoolInteractive.sol";

contract DelegatedPool is Ownable {
    
    // Info of each Delegator
    struct Delegator {
        uint256 amount;            // reserved VEST
        uint256 rewardDebt;        // rewards debt 
        bool    hasDeposited;       // set true when first deposit
        string  hiveAccount;        // related hive acount
    }

    mapping(string => address) public hiveBindAddr;
    mapping(address => Delegator) public delegators;
    address[] public delegatorList;

    IERC20 public immutable LARK;
    IERC20 public immutable DelegatedPoolToken;
    SubpoolInteractive public immutable LarkPool;

    address public minter;           
    uint256 public lastRewardBlock;
    uint256 public rewardsPerShare;  //*1e12
    uint256 public totalDepositedHP; //VEST

    event Update(string hiveAccount, address delegator, uint256 amount);
    event DelegatorHarvest(string hiveAccount, address delegator, uint256 rewardsOut);

    modifier onlyDelegator() {
        require(delegators[msg.sender].hasDeposited, "Account is not a delegator");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == minter, "Caller is not the minter");
        _;
    }

    constructor (IERC20 _lark, SubpoolInteractive _LarkPool, IERC20 _delegatedPoolToken, uint256 _genesisBlock) {
        LARK = IERC20(_lark);
        totalDepositedHP = 0;
        rewardsPerShare = 0;
        LarkPool = _LarkPool;
        DelegatedPoolToken = _delegatedPoolToken;
        lastRewardBlock = _genesisBlock;
    }

    // update delegate, onlyMinter can call this.
    function update(string memory _hiveAccount, address _delegator, uint256 _amount)
        external
        onlyMinter
    {
        require(_amount >= 0);

        address aDelegator = hiveBindAddr[_hiveAccount];
        
        // if hive account and addr hasn't deposited before, initializing
        if(aDelegator == address(0) && !delegators[_delegator].hasDeposited){
            aDelegator = _delegator;
            hiveBindAddr[_hiveAccount] = _delegator; //one to one binding
            delegators[_delegator].amount = 0;
            delegators[_delegator].rewardDebt = 0;
            delegators[_delegator].hasDeposited = true;
            delegators[_delegator].hiveAccount = _hiveAccount;
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

        totalDepositedHP = totalDepositedHP - delegator.amount + _amount;

        delegator.amount = _amount;
        delegator.rewardDebt = _amount * rewardsPerShare / 1e12;

        emit Update(_hiveAccount, aDelegator, _amount);
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

            emit DelegatorHarvest(delegator.hiveAccount, msg.sender, pending);
        }
    }


    function _updateRewardInfo() private {
        uint256 currentBlock = block.number;
        if (currentBlock <= lastRewardBlock) return;
        if(totalDepositedHP == 0) return;

        uint256 poolRewards = LarkPool.harvest(1);
        rewardsPerShare = rewardsPerShare + poolRewards * 1e12 / totalDepositedHP;
        lastRewardBlock = block.number;
    }


    function getPendinglark(address _delegator) external view returns (uint256) {
        uint256 currentBlock = block.number;
        uint256 _rewardsPerShare = rewardsPerShare;

        if (currentBlock > lastRewardBlock) {
            uint256 poolRewards = LarkPool.pendingLark(1, address(this));
            _rewardsPerShare = _rewardsPerShare + poolRewards * 1e12 / totalDepositedHP;
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
        DelegatedPoolToken.approve(address(LarkPool), 1 * 1e18);
        LarkPool.deposit(1, 1 * 1e18);
    }

    function poolWithdraw() external onlyOwner {
        LarkPool.withdraw(1, 1 * 1e18);
    }

    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "Invalid address");
        minter = _minter;
    }
}