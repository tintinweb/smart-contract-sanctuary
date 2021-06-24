// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";

interface IStaking {
    function getEpochId(uint timestamp) external view returns (uint); // get epoch id
    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns(uint);
    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint);
    function epoch1Start() external view returns (uint);
    function epochDuration() external view returns (uint);
    function hasReferrer(address addr) external view returns(bool);
    function referrals(address addr) external view returns(address);
    function firstReferrerRewardPercentage() external view returns(uint256);
    function secondReferrerRewardPercentage() external view returns(uint256);
}

interface TokenInterface is IERC20 {
    function mintSupply(address _investorAddress, uint256 _amount) external;
}

contract YieldFarmLP {
    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // constants
    uint public constant NR_OF_EPOCHS = 24;

    // addreses
    address public _uniLP;
    address public _owner;
    // contracts
    TokenInterface private _swapp;
    IStaking private _staking;

    uint[] private epochs = new uint[](NR_OF_EPOCHS + 1);
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract

    mapping(uint128 => uint256) public epochAmounts;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);
    event ReferrerRewardCollected(address indexed staker, address indexed referrer, uint256 rewardAmount);
    event Referrer2RewardCollected(address indexed staker, address indexed referrer, address indexed referrer2, uint256 rewardAmount);

    // constructor
    constructor() {
        _swapp = TokenInterface(0x8CB924583681cbFE487A62140a994A49F833c244);
        _staking = IStaking(0x245a551ee0F55005e510B239c917fA34b41B3461);

        epochDuration = _staking.epochDuration();
        epochStart = _staking.epoch1Start();

        _owner = msg.sender;
    }

    function setEpochAmount(uint128 epochId, uint256 amount) external {
        require(msg.sender == _owner, "Only owner can update epoch amount");
        require(epochId > 0 && epochId <= NR_OF_EPOCHS, "Minimum epoch number is 1 and Maximum number of epochs is 24");
        require(epochId > _getEpochId(), "Only future epoch can be updated");
        epochAmounts[epochId] = amount;
    }

    function getTotalAmountPerEpoch() public view returns (uint) {
        uint128 currentEpoch = _getEpochId();
        if (currentEpoch > NR_OF_EPOCHS) {
            currentEpoch = 25;
        }

        return epochAmounts[currentEpoch-1].mul(10**18);
    }
    
    function getCurrentEpochAmount() public view returns (uint) {
        uint128 currentEpoch = _getEpochId();
        if (currentEpoch <= 0 || currentEpoch > NR_OF_EPOCHS) {
            return 0;
        }

        return epochAmounts[currentEpoch];
    }

    function getTotalDistributedAmount() external view returns(uint256) {
        uint256 totalDistributed;
        for (uint128 i = 1; i <= NR_OF_EPOCHS; i++) {
            totalDistributed += epochAmounts[i];
        }
        return totalDistributed;
    } 

    function setLPAddress(address lp) external {
        if (_uniLP == address(0)) {
            _uniLP = lp;
        }
    }

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external returns (uint){
        uint totalDistributedValue;
        uint epochId = _getEpochId().sub(1); // fails in epoch 0
        // force max number of epochs
        if (epochId > NR_OF_EPOCHS) {
            epochId = NR_OF_EPOCHS;
        }

        for (uint128 i = lastEpochIdHarvested[msg.sender] + 1; i <= epochId; i++) {
            // i = epochId
            // compute distributed Value and do one single transfer at the end
            totalDistributedValue += _harvest(i);
        }

        emit MassHarvest(msg.sender, epochId - lastEpochIdHarvested[msg.sender], totalDistributedValue);

        if (totalDistributedValue > 0) {
            _swapp.mintSupply(msg.sender, totalDistributedValue);
            //Referrer reward
            distributeReferrerReward(totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (uint128 epochId) external returns (uint){
        // checks for requested epoch
        require (_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 24");
        require (lastEpochIdHarvested[msg.sender].add(1) == epochId, "Harvest in order");
        uint userReward = _harvest(epochId);
        if (userReward > 0) {
            _swapp.mintSupply(msg.sender, userReward);
            //Referrer reward
            distributeReferrerReward(userReward);
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
    }
    
    function distributeReferrerReward(uint256 stakerReward) internal {
        if (_staking.hasReferrer(msg.sender)) {
            address referrer = _staking.referrals(msg.sender);
            uint256 ref1Reward = stakerReward.mul(_staking.firstReferrerRewardPercentage()).div(10000);
            _swapp.mintSupply(referrer, ref1Reward);
            emit ReferrerRewardCollected(msg.sender, referrer, ref1Reward);
            
            // second step referrer
            if (_staking.hasReferrer(referrer)) {
                address referrer2 = _staking.referrals(referrer);
                uint256 ref2Reward = stakerReward.mul(_staking.secondReferrerRewardPercentage()).div(10000);
                _swapp.mintSupply(referrer2, ref2Reward);
                emit Referrer2RewardCollected(msg.sender, referrer, referrer2, ref2Reward);
            }
        }
    }

    // views
    // calls to the staking smart contract to retrieve the epoch total pool size
    function getPoolSize(uint128 epochId) external view returns (uint) {
        return _getPoolSize(epochId);
    }

    function getCurrentEpoch() external view returns (uint) {
        return _getEpochId();
    }

    // calls to the staking smart contract to retrieve user balance for an epoch
    function getEpochStake(address userAddress, uint128 epochId) external view returns (uint) {
        return _getUserBalancePerEpoch(userAddress, epochId);
    }

    function userLastEpochIdHarvested() external view returns (uint){
        return lastEpochIdHarvested[msg.sender];
    }

    // internal methods

    function _initEpoch(uint128 epochId) internal {
        require(lastInitializedEpoch.add(1) == epochId, "Epoch can be init only in order");
        lastInitializedEpoch = epochId;
        // call the staking smart contract to init the epoch
        epochs[epochId] = _getPoolSize(epochId);
    }

    function _harvest (uint128 epochId) internal returns (uint) {
        // try to initialize an epoch. if it can't it fails
        // if it fails either user either a Swapp account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user state for last harvested
        lastEpochIdHarvested[msg.sender] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        return getTotalAmountPerEpoch()
        .mul(_getUserBalancePerEpoch(msg.sender, epochId))
        .div(epochs[epochId]);
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        // retrieve unilp token balance
        return _staking.getEpochPoolSize(_uniLP, epochId);
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        // retrieve unilp token balance per user per epoch
        return _staking.getEpochUserBalance(userAddress, _uniLP, epochId);
    }

    // compute epoch id from blocktimestamp and epochstart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }
}