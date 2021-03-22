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

interface TokenInterface is IERC20 {
    function mintSupply(address _investorAddress, uint256 _amount) external;
}

contract YieldFarmLP {
    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // constants
    uint public constant TOTAL_DISTRIBUTED_AMOUNT = 25000000;
    uint public constant NR_OF_EPOCHS = 24;

    // addreses
    address public _uniLP;
    // contracts
    TokenInterface private _swapp;
    IStaking private _staking;

    uint[] private epochs = new uint[](NR_OF_EPOCHS + 1);
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) private lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract

    uint public constant EPOCH_START_AMOUNT = 1999992;
    uint public constant EPOCH_DECREASE_AMOUNT = 83333;

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);

    // constructor
    constructor() {
        _swapp = TokenInterface(0xc87Cc32D75c13416CD853966Cb271615F35c9072);
        _staking = IStaking(0x036C83C47900b463B7685BdF9bE5785a74D5a3a3);

        epochDuration = _staking.epochDuration();
        epochStart = _staking.epoch1Start();
    }

    function getTotalAmountPerEpoch() public view returns (uint) {
        uint128 currentEpoch = _getEpochId();
        if (currentEpoch <= 0 || currentEpoch > NR_OF_EPOCHS) {
            return 0;
        }
        uint decreaseAmount = EPOCH_DECREASE_AMOUNT.mul(uint(currentEpoch - 1));
        return EPOCH_START_AMOUNT.sub(decreaseAmount).mul(10**18);
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
        }

        return totalDistributedValue;
    }

    function harvest (uint128 epochId) external returns (uint){
        // checks for requested epoch
        require (_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 100");
        require (lastEpochIdHarvested[msg.sender].add(1) == epochId, "Harvest in order");
        uint userReward = _harvest(epochId);
        if (userReward > 0) {
            _swapp.mintSupply(msg.sender, userReward);
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