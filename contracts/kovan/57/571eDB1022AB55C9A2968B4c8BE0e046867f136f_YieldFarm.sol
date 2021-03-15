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
}

contract YieldFarm {
    // lib
    using SafeMath for uint;
    using SafeMath for uint128;
    using SafeMath for uint256;
    
    // constants
    uint public constant TOTAL_DISTRIBUTED_AMOUNT = 106083000;
    uint public constant NR_OF_EPOCHS = 24;

    // addreses
    address private _usdc;
    address private _usdt;
    address private _susd;
    address private _dai;
    // contracts
    IERC20 private _swapp;
    IStaking private _staking;


    // fixed size array holdings total number of epochs + 1 (epoch 0 doesn't count)
    uint[] private epochs = new uint[](NR_OF_EPOCHS + 1);
    // pre-computed variable for optimization. total amount of swapp tokens to be distributed on each epoch
    uint private _totalAmountPerEpoch;

    // id of last init epoch, for optimization purposes moved from struct to a single id.
    uint128 public lastInitializedEpoch;

    // state of user harvest epoch
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    constructor() {
        _swapp = IERC20(0x7639eA937a530749BEed9362fA1A50840bcAB935);
        _usdc = 0xC850F6b60fdc37C9F232b18F5A4e9FB733982832;
        _usdt = 0x2390D2ED12E73A4234bf6FeF1De947c69B240B7c;
        _susd = 0x31f55be7ccA405bf55fF56eF994d76D34bfE6762;
        _dai = 0x0637643CE48a65D97345Be974187Eb9edD84D78c;
        _staking = IStaking(0xe9f5A8928B773209Ea8DB4FBC3Cc45A85952dd64);
        epochStart = _staking.epoch1Start();
        epochDuration = _staking.epochDuration();
        _totalAmountPerEpoch = TOTAL_DISTRIBUTED_AMOUNT.mul(10**18).div(NR_OF_EPOCHS);
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

        emit MassHarvest(msg.sender, epochId.sub(lastEpochIdHarvested[msg.sender]), totalDistributedValue);

        if (totalDistributedValue > 0) {
            _safeSwappTransfer(msg.sender, totalDistributedValue);
        }

        return totalDistributedValue;
    }

    function harvest (uint128 epochId) external returns (uint){
        // checks for requested epoch
        require (_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 25");
        require (lastEpochIdHarvested[msg.sender].add(1) == epochId, "Harvest in order");
        uint userReward = _harvest(epochId);
        if (userReward > 0) {
            _safeSwappTransfer(msg.sender, userReward);
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward;
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
        // if it fails either user either a BarnBridge account will init not init epochs
        if (lastInitializedEpoch < epochId) {
            _initEpoch(epochId);
        }
        // Set user last harvested epoch
        lastEpochIdHarvested[msg.sender] = epochId;
        // compute and return user total reward. For optimization reasons the transfer have been moved to an upper layer (i.e. massHarvest needs to do a single transfer)

        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }

        return _totalAmountPerEpoch
        .mul(_getUserBalancePerEpoch(msg.sender, epochId))
        .div(epochs[epochId]);
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        // retrieve stable coins total staked in epoch
        uint valueUsdc = _staking.getEpochPoolSize(_usdc, epochId).mul(10 ** 12); // for usdc which has 6 decimals add a 10**12 to get to a common ground
        uint valueUsdt = _staking.getEpochPoolSize(_usdt, epochId).mul(10 ** 12); // for usdt which has 6 decimals add a 10**12 to get to a common ground
        uint valueSusd = _staking.getEpochPoolSize(_susd, epochId);
        uint valueDai = _staking.getEpochPoolSize(_dai, epochId);
        return valueUsdc.add(valueUsdt).add(valueSusd).add(valueDai);
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        // retrieve stable coins total staked per user in epoch
        uint valueUsdc = _staking.getEpochUserBalance(userAddress, _usdc, epochId).mul(10 ** 12); // for usdc which has 6 decimals add a 10**12 to get to a common ground
        uint valueUsdt = _staking.getEpochUserBalance(userAddress, _usdt, epochId).mul(10 ** 12); // for usdt which has 6 decimals add a 10**12 to get to a common ground
        uint valueSusd = _staking.getEpochUserBalance(userAddress, _susd, epochId);
        uint valueDai = _staking.getEpochUserBalance(userAddress, _dai, epochId);
        return valueUsdc.add(valueUsdt).add(valueSusd).add(valueDai);
    }

    // compute epoch id from blocktimestamp and epochstart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }

    function _safeSwappTransfer(address recipient, uint256 amount) internal {
        uint256 balance = _swapp.balanceOf(address(this));
        if (balance < amount) {
            _swapp.transfer(recipient, balance);
        } else {
            _swapp.transfer(recipient, amount);
        }
    }
}