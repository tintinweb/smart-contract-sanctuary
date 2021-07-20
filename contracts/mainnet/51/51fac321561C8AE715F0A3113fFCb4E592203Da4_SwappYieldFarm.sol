/**
 *Submitted for verification at Etherscan.io on 2021-07-20
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity 0.8.0;


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
    function isStakeFinished(address staker) external view returns (bool);
    function stakeData(address staker) external view returns (uint256 startEpoch, uint256 endEpoch, bool active);
    function stakeEndEpoch(address staker) external view returns (uint128);
    function calcDurationBonusMultiplier(uint128 epochId, address staker) external view returns (uint256);
}

interface Minter {
    function mint(address to, uint256 amount) external;
}

contract SwappYieldFarm {
    // lib
    using SafeMath for uint;
    using SafeMath for uint128;

    // constants
    uint public constant NR_OF_EPOCHS = 60;
    uint256 constant private CALC_MULTIPLIER = 1000000;

    // addreses
    address private _swappAddress = 0x8CB924583681cbFE487A62140a994A49F833c244;
    address private _owner;
    bool private _paused = false;
    // contracts
    IStaking private _staking;
	Minter private _minter;

    uint[] private epochs = new uint[](NR_OF_EPOCHS + 1);
    uint128 public lastInitializedEpoch;
    mapping(address => uint128) public lastEpochIdHarvested;
    uint public epochDuration; // init from staking contract
    uint public epochStart; // init from staking contract

    mapping(uint128 => uint256) public epochAmounts;
    mapping(uint128 => uint256) public epochDurationBonus;
    mapping(address => uint256) public collectedDurationBonus;
    
    modifier onlyStaking() {
        require(msg.sender == address(_staking), "Only staking contract can perfrom this action");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only owner can perfrom this action");
        _;
    }
    
    modifier whenNotPaused() {
        require(!paused(), "Contract is paused");
        _;
    }

    // events
    event MassHarvest(address indexed user, uint256 epochsHarvested, uint256 totalValue);
    event Harvest(address indexed user, uint128 indexed epochId, uint256 amount);
    event ReferrerRewardCollected(address indexed staker, address indexed referrer, uint256 rewardAmount);
    event Referrer2RewardCollected(address indexed staker, address indexed referrer, address indexed referrer2, uint256 rewardAmount);
    event DurationBonusCollected(address indexed staker, uint128 indexed epochId, uint256 bonusAmount);
    event DurationBonusDistributed(address indexed staker, uint128 indexed epochId, uint256 bonusAmount);
    event DurationBonusLost(address indexed staker, uint128 indexed epochId, uint256 bonusAmount);

    // constructor
    constructor() {
        _staking = IStaking(0x60F4D3e409Ad2Bb6BF5edFBCC85691eE1977cf35);
		_minter = Minter(0xBC1f9993ea5eE2C77909bf43d7a960bB8dA8C9B9);

        epochDuration = _staking.epochDuration();
        epochStart = _staking.epoch1Start();

        _owner = msg.sender;
        
        _initEpochReward();
        _initDurationBonus();
    }

    function setEpochAmount(uint128 epochId, uint256 amount) external onlyOwner {
        require(epochId > 0 && epochId <= NR_OF_EPOCHS, "Minimum epoch number is 1 and Maximum number of epochs is 60");
        require(epochId > _getEpochId(), "Only future epoch can be updated");
        epochAmounts[epochId] = amount;
    }
    
    function setEpochDurationBonus(uint128 epochId, uint256 amount) external onlyOwner {
        require(epochId > 0 && epochId <= NR_OF_EPOCHS, "Minimum epoch number is 1 and Maximum number of epochs is 60");
        require(epochId > _getEpochId(), "Only future epoch can be updated");
        epochDurationBonus[epochId] = amount;
    }

    function getTotalAmountPerEpoch(uint128 epoch) public view returns (uint) {
        return epochAmounts[epoch].mul(10**18);
    }
    
    function getDurationBonusPerEpoch(uint128 epoch) public view returns (uint) {
        return epochDurationBonus[epoch].mul(10**18);
    }
    
    function getCurrentEpochAmount() public view returns (uint) {
        uint128 currentEpoch = _getEpochId();
        if (currentEpoch <= 0 || currentEpoch > NR_OF_EPOCHS) {
            return 0;
        }

        return epochAmounts[currentEpoch];
    }
    
    function getCurrentEpochDurationBonus() public view returns (uint) {
        uint128 currentEpoch = _getEpochId();
        if (currentEpoch <= 0 || currentEpoch > NR_OF_EPOCHS) {
            return 0;
        }

        return epochDurationBonus[currentEpoch];
    }

    function getTotalDistributedAmount() external view returns(uint256) {
        uint256 totalDistributed;
        for (uint128 i = 1; i <= NR_OF_EPOCHS; i++) {
            totalDistributed += epochAmounts[i];
        }
        return totalDistributed;
    } 
    
    function getTotalDurationBonus() external view returns(uint256) {
        uint256 totalBonus;
        for (uint128 i = 1; i <= NR_OF_EPOCHS; i++) {
            totalBonus += epochDurationBonus[i];
        }
        return totalBonus;
    } 

    // public methods
    // public method to harvest all the unharvested epochs until current epoch - 1
    function massHarvest() external whenNotPaused returns (uint){
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
            
            uint256 durationBonus = _calcDurationBonus(i);
            if (durationBonus > 0) {
                collectedDurationBonus[msg.sender] = collectedDurationBonus[msg.sender].add(durationBonus);
                emit DurationBonusCollected(msg.sender, i, durationBonus);
            }
        }

        emit MassHarvest(msg.sender, epochId - lastEpochIdHarvested[msg.sender], totalDistributedValue);

        uint256 totalDurationBonus = 0;
        if (_staking.isStakeFinished(msg.sender) && collectedDurationBonus[msg.sender] > 0) {
            totalDurationBonus = collectedDurationBonus[msg.sender];
            collectedDurationBonus[msg.sender] = 0;
            _minter.mint(msg.sender, totalDurationBonus);
            emit DurationBonusDistributed(msg.sender, _getEpochId(), totalDurationBonus);
        }

        if (totalDistributedValue > 0) {
			_minter.mint(msg.sender, totalDistributedValue);
            //Referrer reward
            distributeReferrerReward(totalDistributedValue.add(totalDurationBonus));
        }

        return totalDistributedValue.add(totalDurationBonus);
    }

    function harvest (uint128 epochId) external whenNotPaused returns (uint){
        // checks for requested epoch
        require (_getEpochId() > epochId, "This epoch is in the future");
        require(epochId <= NR_OF_EPOCHS, "Maximum number of epochs is 60");
        require (lastEpochIdHarvested[msg.sender].add(1) == epochId, "Harvest in order");
        uint userReward = _harvest(epochId);
        
        uint256 durationBonus = _calcDurationBonus(epochId);
        collectedDurationBonus[msg.sender] = collectedDurationBonus[msg.sender].add(_calcDurationBonus(epochId));
        emit DurationBonusCollected(msg.sender, epochId, durationBonus);
        
        uint256 totalDurationBonus = 0;
        if (_staking.isStakeFinished(msg.sender) && collectedDurationBonus[msg.sender] > 0) {
            totalDurationBonus = collectedDurationBonus[msg.sender];
            collectedDurationBonus[msg.sender] = 0;
            _minter.mint(msg.sender, totalDurationBonus);
            emit DurationBonusDistributed(msg.sender, epochId, totalDurationBonus);
        }
        
        if (userReward > 0) {
			_minter.mint(msg.sender, userReward);
            //Referrer reward
            distributeReferrerReward(userReward.add(totalDurationBonus));
        }
        emit Harvest(msg.sender, epochId, userReward);
        return userReward.add(totalDurationBonus);
    }
    
    function distributeReferrerReward(uint256 stakerReward) internal {
        if (_staking.hasReferrer(msg.sender)) {
            address referrer = _staking.referrals(msg.sender);
            uint256 ref1Reward = stakerReward.mul(_staking.firstReferrerRewardPercentage()).div(10000);
            _minter.mint(referrer, ref1Reward);
            emit ReferrerRewardCollected(msg.sender, referrer, ref1Reward);
            
            // second step referrer
            if (_staking.hasReferrer(referrer)) {
                address referrer2 = _staking.referrals(referrer);
                uint256 ref2Reward = stakerReward.mul(_staking.secondReferrerRewardPercentage()).div(10000);
            	_minter.mint(referrer2, ref2Reward);
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
    
    function getUserLastEpochHarvested(address staker) external view returns (uint) {
        return lastEpochIdHarvested[staker];
    }
    
    function estimateDurationBonus (uint128 epochId) public view returns (uint) {
        uint256 poolSize = _getPoolSize(epochId);
        
        // exit if there is no stake on the epoch
        if (poolSize == 0) {
            return 0;
        }
        
        uint256 stakerMultiplier = stakerDurationMultiplier(msg.sender, epochId + 1);

        return getDurationBonusPerEpoch(epochId)
        .mul(_getUserBalancePerEpoch(msg.sender, epochId))
        .div(poolSize).mul(stakerMultiplier).div(CALC_MULTIPLIER);
    }
    
    function stakerDurationMultiplier(address staker, uint128 epochId) public view returns (uint256) {
        (uint256 startEpoch, uint256 endEpoch, bool active) = _staking.stakeData(staker);

        if (epochId > endEpoch || (epochId <= endEpoch && active == false) || epochId < startEpoch) {
            return 0;
        }
        
        uint256 stakerMultiplier = _staking.calcDurationBonusMultiplier(epochId, staker);
        
        return stakerMultiplier;
    }
    
    function reduceDurationBonus(address staker, uint256 reduceMultiplier) public onlyStaking {
        uint256 collected = collectedDurationBonus[staker];
        if (collected > 0) {
            collectedDurationBonus[staker] = collected.mul(reduceMultiplier).div(CALC_MULTIPLIER);
            uint256 bonusLost = collected.sub(collectedDurationBonus[staker]);
            DurationBonusLost(staker, _getEpochId(), bonusLost);
        }
    }
    
    function clearDurationBonus(address staker) public onlyStaking {
        uint256 collected = collectedDurationBonus[staker];
        if (collected > 0) {
            collectedDurationBonus[staker] = 0;
            DurationBonusLost(staker, _getEpochId(), collected);
        }
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
        
        uint128 endEpoch = _staking.stakeEndEpoch(msg.sender);
        if (epochId >= endEpoch) {
            return 0;
        }
        
        return getTotalAmountPerEpoch(epochId)
        .mul(_getUserBalancePerEpoch(msg.sender, epochId))
        .div(epochs[epochId]);
    }
    

    function _calcDurationBonus(uint128 epochId) internal view returns (uint) {
        // exit if there is no stake on the epoch
        if (epochs[epochId] == 0) {
            return 0;
        }
        
        uint256 stakerMultiplier = stakerDurationMultiplier(msg.sender, epochId + 1);

        return getDurationBonusPerEpoch(epochId)
        .mul(_getUserBalancePerEpoch(msg.sender, epochId))
        .div(epochs[epochId]).mul(stakerMultiplier).div(CALC_MULTIPLIER);
    }

    function _getPoolSize(uint128 epochId) internal view returns (uint) {
        // retrieve token balance
        return _staking.getEpochPoolSize(_swappAddress, epochId);
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        // retrieve token balance per user per epoch
        return _staking.getEpochUserBalance(userAddress, _swappAddress, epochId);
    }

    // compute epoch id from blocktimestamp and epochstart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }
    
    function paused() public view returns (bool) {
        return _paused;
    }
    
    function pause() external onlyOwner {
        _paused = true;
    }
    
    function unpause() external onlyOwner {
        _paused = false;
    }
    
    function _initEpochReward() internal {
        epochAmounts[1] = 5000000;
        epochAmounts[2] = 2000000;
        epochAmounts[3] = 2000000;
        epochAmounts[4] = 2000000;
        epochAmounts[5] = 2000000;
        epochAmounts[6] = 2000000;
        epochAmounts[7] = 1500000;
        epochAmounts[8] = 1500000;
        epochAmounts[9] = 1500000;
        epochAmounts[10] = 1500000;
        epochAmounts[11] = 1500000;
        epochAmounts[12] = 1500000;
        epochAmounts[13] = 500000;
        epochAmounts[14] = 500000;
        epochAmounts[15] = 500000;
        epochAmounts[16] = 500000;
        epochAmounts[17] = 500000;
        epochAmounts[18] = 500000;
        epochAmounts[19] = 500000;
        epochAmounts[20] = 500000;
        epochAmounts[21] = 500000;
        epochAmounts[22] = 500000;
        epochAmounts[23] = 500000;
        epochAmounts[24] = 500000;
        epochAmounts[25] = 400000;
        epochAmounts[26] = 400000;
        epochAmounts[27] = 400000;
        epochAmounts[28] = 400000;
        epochAmounts[29] = 400000;
        epochAmounts[30] = 400000;
        epochAmounts[31] = 400000;
        epochAmounts[32] = 400000;
        epochAmounts[33] = 400000;
        epochAmounts[34] = 400000;
        epochAmounts[35] = 400000;
        epochAmounts[36] = 400000;
        epochAmounts[37] = 250000;
        epochAmounts[38] = 250000;
        epochAmounts[39] = 250000;
        epochAmounts[40] = 250000;
        epochAmounts[41] = 250000;
        epochAmounts[42] = 250000;
        epochAmounts[43] = 250000;
        epochAmounts[44] = 250000;
        epochAmounts[45] = 250000;
        epochAmounts[46] = 250000;
        epochAmounts[47] = 250000;
        epochAmounts[48] = 250000;
        epochAmounts[49] = 250000;
        epochAmounts[50] = 250000;
        epochAmounts[51] = 250000;
        epochAmounts[52] = 250000;
        epochAmounts[53] = 250000;
        epochAmounts[54] = 250000;
        epochAmounts[55] = 250000;
        epochAmounts[56] = 250000;
        epochAmounts[57] = 250000;
        epochAmounts[58] = 250000;
        epochAmounts[59] = 250000;
        epochAmounts[60] = 250000;
    }
    
    function _initDurationBonus() internal {
        epochDurationBonus[1] = 21450;
        epochDurationBonus[2] = 23595;
        epochDurationBonus[3] = 25954;
        epochDurationBonus[4] = 28550;
        epochDurationBonus[5] = 31405;
        epochDurationBonus[6] = 34545;
        epochDurationBonus[7] = 38000;
        epochDurationBonus[8] = 41800;
        epochDurationBonus[9] = 45980;
        epochDurationBonus[10] = 50578;
        epochDurationBonus[11] = 55635;
        epochDurationBonus[12] = 61477;
        epochDurationBonus[13] = 67932;
        epochDurationBonus[14] = 75065;
        epochDurationBonus[15] = 82947;
        epochDurationBonus[16] = 91656;
        epochDurationBonus[17] = 101280;
        epochDurationBonus[18] = 111915;
        epochDurationBonus[19] = 123666;
        epochDurationBonus[20] = 136651;
        epochDurationBonus[21] = 150999;
        epochDurationBonus[22] = 166854;
        epochDurationBonus[23] = 184374;
        epochDurationBonus[24] = 204701;
        epochDurationBonus[25] = 227269;
        epochDurationBonus[26] = 252326;
        epochDurationBonus[27] = 280145;
        epochDurationBonus[28] = 311031;
        epochDurationBonus[29] = 345322;
        epochDurationBonus[30] = 383393;
        epochDurationBonus[31] = 425662;
        epochDurationBonus[32] = 472592;
        epochDurationBonus[33] = 524695;
        epochDurationBonus[34] = 582543;
        epochDurationBonus[35] = 646768;
        epochDurationBonus[36] = 721639;
        epochDurationBonus[37] = 805178;
        epochDurationBonus[38] = 898388;
        epochDurationBonus[39] = 1002387;
        epochDurationBonus[40] = 1118426;
        epochDurationBonus[41] = 1247898;
        epochDurationBonus[42] = 1392358;
        epochDurationBonus[43] = 1553541;
        epochDurationBonus[44] = 1733382;
        epochDurationBonus[45] = 1934043;
        epochDurationBonus[46] = 2157933;
        epochDurationBonus[47] = 2407740;
        epochDurationBonus[48] = 2700403;
        epochDurationBonus[49] = 3028638;
        epochDurationBonus[50] = 3396771;
        epochDurationBonus[51] = 3809651;
        epochDurationBonus[52] = 4272716;
        epochDurationBonus[53] = 4792068;
        epochDurationBonus[54] = 5374546;
        epochDurationBonus[55] = 6027826;
        epochDurationBonus[56] = 6760512;
        epochDurationBonus[57] = 7582256;
        epochDurationBonus[58] = 8503884;
        epochDurationBonus[59] = 9537537;
        epochDurationBonus[60] = 11000000;
    }
}