/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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

contract YieldFarm {
    // lib
    using SafeMath for uint;
    using SafeMath for uint128;
    using SafeMath for uint256;
    
    // constants
    // uint public constant TOTAL_DISTRIBUTED_AMOUNT = 72000000;//????
    uint public constant NR_OF_EPOCHS = 24;//????

    // addreses
    address public _usdc;
    address public _usdt;
    address public _dai;
    // contracts
    TokenInterface private _swapp;
    IStaking private _staking;
    
    address public _owner;

    // fixed size array holdings total number of epochs + 1 (epoch 0 doesn't count)
    uint[] private epochs = new uint[](NR_OF_EPOCHS + 1);
    // pre-computed variable for optimization. total amount of swapp tokens to be distributed on each epoch
    // uint private _totalAmountPerEpoch;

    // id of last init epoch, for optimization purposes moved from struct to a single id.
    uint128 public lastInitializedEpoch;

    // state of user harvest epoch
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
        _swapp = TokenInterface(0xc52FD807131e8cb3bc5FD278db6a18768aebf233);//????
        _staking = IStaking(0xF95AdB16d6C337dBF609c52C7AaF8120282699Be);//????

        _usdc = 0x07865c6E87B9F70255377e024ace6630C1Eaa37F;//????
        _usdt = 0x110a13FC3efE6A245B50102D2d79B3E76125Ae83;//????
        _dai = 0x31F42841c2db5173425b5223809CF3A38FEde360;//????

        epochStart = _staking.epoch1Start();
        epochDuration = _staking.epochDuration();
        // _totalAmountPerEpoch = TOTAL_DISTRIBUTED_AMOUNT.mul(10**18).div(NR_OF_EPOCHS);
        
        _owner = msg.sender;
        
        for (uint128 i = 1; i <= 24; i++) {
            // i = epochId
            epochAmounts[i] = 5000000;
        }
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
        // Set user last harvested epoch
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
        // retrieve stable coins total staked in epoch
        uint valueUsdc = _staking.getEpochPoolSize(_usdc, epochId).mul(10 ** 12); // for usdc which has 6 decimals add a 10**12 to get to a common ground
        uint valueUsdt = _staking.getEpochPoolSize(_usdt, epochId).mul(10 ** 12); // for usdt which has 6 decimals add a 10**12 to get to a common ground
        uint valueDai = _staking.getEpochPoolSize(_dai, epochId);
        return valueUsdc.add(valueUsdt).add(valueDai);
    }

    function _getUserBalancePerEpoch(address userAddress, uint128 epochId) internal view returns (uint){
        // retrieve stable coins total staked per user in epoch
        uint valueUsdc = _staking.getEpochUserBalance(userAddress, _usdc, epochId).mul(10 ** 12); // for usdc which has 6 decimals add a 10**12 to get to a common ground
        uint valueUsdt = _staking.getEpochUserBalance(userAddress, _usdt, epochId).mul(10 ** 12); // for usdt which has 6 decimals add a 10**12 to get to a common ground
        uint valueDai = _staking.getEpochUserBalance(userAddress, _dai, epochId);
        return valueUsdc.add(valueUsdt).add(valueDai);
    }

    // compute epoch id from blocktimestamp and epochstart date
    function _getEpochId() internal view returns (uint128 epochId) {
        if (block.timestamp < epochStart) {
            return 0;
        }
        epochId = uint128(block.timestamp.sub(epochStart).div(epochDuration).add(1));
    }
}