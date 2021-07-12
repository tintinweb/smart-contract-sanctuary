/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.7.0;

library DSMath {
    /// @dev github.com/makerdao/dss implementation
    /// of exponentiation by squaring
    //  nth power of x mod b
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


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

contract CompoundRateKeeper is Ownable {
    using SafeMath for uint256;

    struct CompoundRate {
        uint256 rate;
        uint256 lastUpdate;
    }

    CompoundRate public compoundRate;

    constructor () {
        compoundRate.rate = 1 * 10 ** 27;
        compoundRate.lastUpdate = block.timestamp;
    }

    function getCurrentRate() view external returns(uint256) {
        return compoundRate.rate;
    }

    function getLastUpdate() view external returns(uint256) {
        return compoundRate.lastUpdate;
    }

    function update(uint256 _interestRate) external onlyOwner returns(uint256) {
        uint256 _decimal = 10 ** 27;
        uint256 _period = (block.timestamp).sub(compoundRate.lastUpdate);
        uint256 _newRate = compoundRate.rate
        .mul(DSMath.rpow(_interestRate.add(_decimal), _period, _decimal)).div(_decimal);

        compoundRate.rate = _newRate;
        compoundRate.lastUpdate = block.timestamp;

        return _newRate;
    }
}

interface IBEPANStaking {
    /**
     * @notice Update compound rate
     */
    function updateCompoundRate() external;

    /**
     * @notice Update compound rate timeframe
     */
    function updateCompoundRateTimeframe() external;

    /**
     * @notice Update both compound rates
     */
    function updateCompoundRates() external;

    /**
     * @notice Update compound rate and stake tokens to user balance
     * @param _amount Amount to stake
     * @param _isTimeframe If true, stake to timeframe structure
     */
    function updateCompoundAndStake(uint256 _amount, bool _isTimeframe) external returns (bool);

    /**
     * @notice Update compound rate and withdraw tokens from contract
     * @param _amount Amount to stake
     * @param _isTimeframe If true, withdraw from timeframe structure
     */
    function updateCompoundAndWithdraw(uint256 _amount, bool _isTimeframe) external returns (bool);

    /**
     * @notice Stake tokens to user balance
     * @param _amount Amount to stake
     * @param _isTimeframe If true, stake to timeframe structure
     */
    function stake(uint256 _amount, bool _isTimeframe) external returns (bool);

    /**
     * @notice Withdraw tokens from user balance. Only for timeframe stake
     * @param _amount Amount to withdraw
     * @param _isTimeframe If true, withdraws from timeframe structure
     */
    function withdraw(uint256 _amount, bool _isTimeframe) external returns (bool);

    /**
     * @notice Returns the staking balance of the user
     * @param _isTimeframe If true, return balance from timeframe structure
     */
    function getBalance(bool _isTimeframe) external view returns (uint256);

    /**
    * @notice Set interest rate
    */
    function setInterestRate(uint256 _newInterestRate) external;

    /**
    * @notice Set interest rate timeframe
    * @param _newInterestRate New interest rate
    */
    function setInterestRateTimeframe(uint256 _newInterestRate) external;

    /**
     * @notice Set interest rates
     * @param _newInterestRateTimeframe New interest rate timeframe
     */
    function setInterestRates(uint256 _newInterestRate, uint256 _newInterestRateTimeframe) external;

    /**
     * @notice Add tokens to contract address to be spent as rewards
     * @param _amount Token amount that will be added to contract as reward
     */
    function supplyRewardPool(uint256 _amount) external returns (bool);

    /**
     * @notice Get reward amount for sender address
     * @param _isTimeframe If timeframe, calculate reward for user from timeframe structure
     */
    function getRewardAmount(bool _isTimeframe) external view returns (uint256);

    /**
     * @notice Get coefficient. Tokens on the contract / reward to be paid
     */
    function monitorSecurityMargin() external view returns (uint256);
}


contract BEPANStaking is IBEPANStaking, Ownable {
    using SafeMath for uint;
    
    uint256 constant INTEREST_500_THRESHOLD = 51034942716352291304;

    CompoundRateKeeper public compRateKeeper;
    CompoundRateKeeper public compRateKeeperTimeframe;
    IERC20 public token;

    struct Stake {
        uint256 amount;
        uint256 normalizedAmount;
    }

    struct StakeTimeframe {
        uint256 amount;
        uint256 normalizedAmount;
        uint256 lastStakeTime;
    }

    uint256 public interestRate;
    uint256 public interestRateTimeframe;

    mapping(address => Stake) public userStakes;
    mapping(address => StakeTimeframe) public userStakesTimeframe;

    uint256 public aggregatedNormalizedStake;
    uint256 public aggregatedNormalizedStakeTimeframe;

    constructor(address _token, address _compRateKeeper, address _compRateKeeperTimeframe) {
        compRateKeeper = CompoundRateKeeper(_compRateKeeper);
        compRateKeeperTimeframe = CompoundRateKeeper(_compRateKeeperTimeframe);
        token = IERC20(_token);
    }

    /**
     * @notice Update compound rate
     */
    function updateCompoundRate() public override {
        compRateKeeper.update(interestRate);
    }

    /**
     * @notice Update compound rate timeframe
     */
    function updateCompoundRateTimeframe() public override {
        compRateKeeperTimeframe.update(interestRateTimeframe);
    }

    /**
     * @notice Update both compound rates
     */
    function updateCompoundRates() public override {
        updateCompoundRate();
        updateCompoundRateTimeframe();
    }

    /**
     * @notice Update compound rate and stake tokens to user balance
     * @param _amount Amount to stake
     * @param _isTimeframe If true, stake to timeframe structure
     */
    function updateCompoundAndStake(uint256 _amount, bool _isTimeframe) external override returns (bool) {
        updateCompoundRates();
        return stake(_amount, _isTimeframe);
    }

    /**
     * @notice Update compound rate and withdraw tokens from contract
     * @param _amount Amount to stake
     * @param _isTimeframe If true, withdraw from timeframe structure
     */
    function updateCompoundAndWithdraw(uint256 _amount, bool _isTimeframe) external override returns (bool) {
        updateCompoundRates();
        return withdraw(_amount, _isTimeframe);
    }

    /**
     * @notice Stake tokens to user balance
     * @param _amount Amount to stake
     * @param _isTimeframe If true, stake to timeframe structure
     */
    function stake(uint256 _amount, bool _isTimeframe) public override returns (bool) {
        require(_amount > 0, "[E-11]-Invalid value for the stake amount, failed to stake a zero value.");

        if (_isTimeframe) {
            StakeTimeframe memory _stake = userStakesTimeframe[msg.sender];

            uint256 _newAmount = _getBalance(_stake.normalizedAmount, true).add(_amount);
            uint256 _newNormalizedAmount = _newAmount.mul(10 ** 27).div(compRateKeeperTimeframe.getCurrentRate());

            aggregatedNormalizedStakeTimeframe = aggregatedNormalizedStakeTimeframe.add(_newNormalizedAmount)
            .sub(_stake.normalizedAmount);

            userStakesTimeframe[msg.sender].amount = _stake.amount.add(_amount);
            userStakesTimeframe[msg.sender].normalizedAmount = _newNormalizedAmount;
            userStakesTimeframe[msg.sender].lastStakeTime = block.timestamp;

        } else {
            Stake memory _stake = userStakes[msg.sender];

            uint256 _newAmount = _getBalance(_stake.normalizedAmount, false).add(_amount);
            uint256 _newNormalizedAmount = _newAmount.mul(10 ** 27).div(compRateKeeper.getCurrentRate());

            aggregatedNormalizedStake = aggregatedNormalizedStake.add(_newNormalizedAmount)
            .sub(_stake.normalizedAmount);

            userStakes[msg.sender].amount = _stake.amount.add(_amount);
            userStakes[msg.sender].normalizedAmount = _newNormalizedAmount;
        }

        require(token.transferFrom(msg.sender, address(this), _amount), "[E-12]-Failed to transfer token.");

        return true;
    }

    /**
     * @notice Withdraw tokens from user balance. Only for timeframe stake
     * @param _amount Amount to withdraw
     * @param _isTimeframe If true, withdraws from timeframe structure
     */
    function withdraw(uint256 _amount, bool _isTimeframe) public override returns (bool) {
        uint256 _withdrawAmount = _amount;

        if (_isTimeframe) {
            StakeTimeframe memory _stake = userStakesTimeframe[msg.sender];

            uint256 _userAmount = _getBalance(_stake.normalizedAmount, true);

            require(_userAmount != 0, "[E-31]-The deposit does not exist, failed to withdraw.");
            require(block.timestamp - _stake.lastStakeTime > 180 days, "[E-32]-Funds are not available for withdraw.");

            if (_userAmount < _withdrawAmount) _withdrawAmount = _userAmount;

            uint256 _newAmount = _userAmount.sub(_withdrawAmount);
            uint256 _newNormalizedAmount = _newAmount.mul(10 ** 27).div(compRateKeeperTimeframe.getCurrentRate());

            aggregatedNormalizedStakeTimeframe = aggregatedNormalizedStakeTimeframe.add(_newNormalizedAmount)
            .sub(_stake.normalizedAmount);

            if (_withdrawAmount > _getRewardAmount(_stake.amount, _stake.normalizedAmount, _isTimeframe)) {
                userStakesTimeframe[msg.sender].amount = _newAmount;
            }
            userStakesTimeframe[msg.sender].normalizedAmount = _newNormalizedAmount;

        } else {
            Stake memory _stake = userStakes[msg.sender];

            uint256 _userAmount = _getBalance(_stake.normalizedAmount, false);

            require(_userAmount != 0, "[E-33]-The deposit does not exist, failed to withdraw.");

            if (_userAmount < _withdrawAmount) _withdrawAmount = _userAmount;

            uint256 _newAmount = _getBalance(_stake.normalizedAmount, false).sub(_withdrawAmount);
            uint256 _newNormalizedAmount = _newAmount.mul(10 ** 27).div(compRateKeeper.getCurrentRate());

            aggregatedNormalizedStake = aggregatedNormalizedStake.add(_newNormalizedAmount)
            .sub(_stake.normalizedAmount);

            if (_withdrawAmount > _getRewardAmount(_stake.amount, _stake.normalizedAmount, _isTimeframe)) {
                userStakes[msg.sender].amount = _newAmount;
            }
            userStakes[msg.sender].normalizedAmount = _newNormalizedAmount;
        }

        require(token.transfer(msg.sender, _withdrawAmount), "[E-34]-Failed to transfer token.");

        return true;
    }

    /**
     * @notice Returns the staking balance of the user
     * @param _isTimeframe If true, return balance from timeframe structure
     */
    function getBalance(bool _isTimeframe) public view override returns (uint256) {
        if (_isTimeframe) {
            return _getBalance(userStakesTimeframe[msg.sender].normalizedAmount, true);
        }
        return _getBalance(userStakes[msg.sender].normalizedAmount, false);
    }

    /**
     * @notice Returns the staking balance of the user
     * @param _normalizedAmount User normalized amount
     * @param _isTimeframe If true, return balance from timeframe structure
     */
    function _getBalance(uint256 _normalizedAmount, bool _isTimeframe) private view returns (uint256) {
        if (_isTimeframe) {
            return _normalizedAmount.mul(compRateKeeperTimeframe.getCurrentRate()).div(10 ** 27);
        }
        return _normalizedAmount.mul(compRateKeeper.getCurrentRate()).div(10 ** 27);
    }

    /**
     * @notice Set interest rate
     */
    function setInterestRate(uint256 _newInterestRate) external override onlyOwner {
        require(_newInterestRate <= INTEREST_500_THRESHOLD, "[E-202]-Can't be more than 500%.");
        
        updateCompoundRate();
        interestRate = _newInterestRate;
    }

    /**
    * @notice Set interest rate timeframe
    * @param _newInterestRate New interest rate
    */
    function setInterestRateTimeframe(uint256 _newInterestRate) external override onlyOwner {
        require(_newInterestRate <= INTEREST_500_THRESHOLD, "[E-211]-Can't be more than 500%.");

        updateCompoundRateTimeframe();
        interestRateTimeframe = _newInterestRate;
    }

    /**
     * @notice Set interest rates
     * @param _newInterestRateTimeframe New interest rate timeframe
     */
    function setInterestRates(uint256 _newInterestRate, uint256 _newInterestRateTimeframe) external override onlyOwner {
        require(_newInterestRate <= INTEREST_500_THRESHOLD && _newInterestRateTimeframe <= INTEREST_500_THRESHOLD,
            "[E-221]-Can't be more than 500%.");

        updateCompoundRate();
        updateCompoundRateTimeframe();
        interestRate = _newInterestRate;
        interestRateTimeframe = _newInterestRateTimeframe;
    }

    /**
     * @notice Add tokens to contract address to be spent as rewards
     * @param _amount Token amount that will be added to contract as reward
     */
    function supplyRewardPool(uint256 _amount) external override onlyOwner returns (bool) {
        require(token.transferFrom(msg.sender, address(this), _amount), "[E-231]-Failed to transfer token.");
        return true;
    }

    /**
     * @notice Get reward amount for sender address
     * @param _isTimeframe If timeframe, calculate reward for user from timeframe structure
     */
    function getRewardAmount(bool _isTimeframe) external view override returns (uint256) {
        if (_isTimeframe) {
            StakeTimeframe memory _stake = userStakesTimeframe[msg.sender];
            return _getRewardAmount(_stake.amount, _stake.normalizedAmount, true);
        }

        Stake memory _stake = userStakes[msg.sender];
        return _getRewardAmount(_stake.amount, _stake.normalizedAmount, false);
    }

    /**
     * @notice Get reward amount by params
     * @param _amount Token amount
     * @param _normalizedAmount Normalized token amount
     * @param _isTimeframe If timeframe, calculate reward for user from timeframe structure
     */
    function _getRewardAmount(uint256 _amount, uint256 _normalizedAmount, bool _isTimeframe) private view returns (uint256) {
        uint256 _balance = 0;

        if (_isTimeframe) {
            _balance = _getBalance(_normalizedAmount, _isTimeframe);
        } else {
            _balance = _getBalance(_normalizedAmount, _isTimeframe);
        }

        if (_balance <= _amount) return 0;
        return _balance.sub(_amount);
    }

    /**
     * @notice Get coefficient. Tokens on the contract / total stake + total reward to be paid
     */
    function monitorSecurityMargin() external view override onlyOwner returns (uint256) {
        uint256 _contractBalance = token.balanceOf(address(this));
        uint256 _toReward = aggregatedNormalizedStake.mul(compRateKeeper.getCurrentRate()).div(10 ** 27);
        uint256 _toRewardTimeframe = aggregatedNormalizedStakeTimeframe.mul(compRateKeeperTimeframe.getCurrentRate())
        .div(10 ** 27);

        return _contractBalance.mul(10 ** 27).div(_toReward.add(_toRewardTimeframe));
    }
}