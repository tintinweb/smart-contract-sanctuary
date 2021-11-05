/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

pragma solidity 0.5.16;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
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
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
  // Empty internal constructor, to prevent people from mistakenly deploying
  // an instance of this contract, which should be used via inheritance.
  constructor () internal { }

  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

/**
 * Virgo's stacking contract
 * Permit users to lock their VGO, making them earn 0.5% interest each week
 * Tokens are locked for a month, after this period they can be withdrawn at any time
 */
contract VirgoFarm is Context {
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _lockTimes;
    address[] private _stackers;
    mapping (address => uint256) private _stackersIds;
    
    IBEP20 constant _token = IBEP20(0xbEE5E147e6e40433ff0310f5aE1a66278bc8D678);
    
    uint256 private _toDistribute = 0;
    uint256 private _distributed = 0;
    uint256 private _lastDistribution = 0;
    
    uint256 private _toDistributeThisRound = 0;
    uint256 private _currentIteration = 0;
    uint256 private _lockedAmount = 0;
    
    uint256 constant _perThousand = 1000;
    uint256 constant _baseWeeklyRate = 5; //per 1000
    uint256 constant _maxPerInterval = 4331500000000;
    uint256 constant _minLockAmount = 10000000000;
    uint256 constant _lockTime = 876000;
    uint256 constant _distributionInterval = 201600;
    
    constructor() public {}
    
    /**
     * Returns how much tokens the contract has at its disposal for distribution
     */
    function getToDistribute() external view returns (uint256) {
        return _toDistribute;
    }
    
    /**
     * Returns how much tokens the contract has to distribute this round
     */
    function getToDistributeThisRound() external view returns (uint256) {
        return _toDistributeThisRound;
    }
    
    /**
     * Returns how much tokens has been distributed since contract's start
     */
    function getDistributed() external view returns (uint256) {
        return _distributed;
    }

    /**
     * Returns last distribution's block height
     */
    function getLastDistribution() external view returns (uint256) {
        return _lastDistribution;
    }

    /**
     * Returns how much tokens are locked by users into the contract
     */
    function getLocked() external view returns (uint256) {
        return _token.balanceOf(address(this)).sub(_toDistribute);
    }

    /**
     * Returns given address's balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * Returns given address's block height of unlock
     */
    function lockTimeOf(address account) external view returns (uint256) {
        return _lockTimes[account];
    }
    
     /**
     * Add tokens to contract's distribution funds
     */
    function addFunds(uint256 amount) external returns (bool) {
        require(amount > 0, "you must send tokens");
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Please allow token before adding funds");
        
        _token.transferFrom(msg.sender, address(this), amount);
        _toDistribute = _toDistribute.add(amount);
        
        return true;
    }
    
    /**
     * Lock specified amount into the contract, transfering tokens from sender to contract and increasing sender's locked balance
     * If locked balance was 0 then add sender to stackers array, which we will iterate through during distribution
     * 
     * Require that:
     * No distribution is occuring (toDistributeThisRound == 0)
     * Amount to lock is superior or equal to minimal lock amount
     * Sender's allowance is sufficient
     * Sender's balance is sufficient (or will revert on _token.transferFrom)
     */
    function lock(uint256 amount) external returns (bool) {
        require(_toDistributeThisRound == 0, "A distribution is occuring! Please try again in a few minutes.");
        require(amount >= _minLockAmount, "Lock amount must be greater or equal to minimal lock amount");
        uint256 allowance = _token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Please allow token before locking");
        
        _token.transferFrom(msg.sender, address(this), amount);
        
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _lockTimes[msg.sender] = block.number.add(_lockTime);
        
        if(_stackersIds[msg.sender] == 0){
           _stackers.push(msg.sender);
           _stackersIds[msg.sender] = _stackers.length;
        }
            
        return true;
    }
    
    /**
     * Unlock specified amount, withdrawing tokens from contract to sender
     * If after this operation locked balance is zero, remove sender from stackers array 
     *
     * Require that:
     * No distribution is occuring (toDistributeThisRound == 0)
     * Amount to unlock is inferior or equal to sender's balance
     * Amount is superior to zero
     * Unlock block number is inferior or equal to current block number
     */
    function unlock(uint256 amount) external returns (bool) {
        require(_toDistributeThisRound == 0, "A distribution is occuring! Please try again in a few minutes.");
        require(amount > 0, "amount must be positive");
        require(_balances[msg.sender] > 0, "Balance must not be null");
        require(_lockTimes[msg.sender] <= block.number, "Lock not expired yet");
        require(amount <= _balances[msg.sender], "amount must be inferior or equal to balance");
        
        // make sure that users can't continue to stack with less than minLockAmount, by increasing withdraw amount if necessary
        if(_balances[msg.sender].sub(amount) < _minLockAmount){
            amount = _balances[msg.sender];
        }
        
        _token.transfer(msg.sender, amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        
        if(_balances[msg.sender] == 0){
            _stackers[_stackersIds[msg.sender]-1] = _stackers[_stackers.length-1];
            _stackersIds[_stackers[_stackers.length-1]] = _stackersIds[msg.sender];
            delete _stackersIds[msg.sender];
            _stackers.pop();
        }
        
        return true;
    }
    
    /**
     * Init a new distribution round, calculating how much to give this round, setting lastDistribution to current block height and
     * reseting currentIteration
     *
     * Require that:
     * enough blocks elasped since last distribution
     * No distribution is already ongoing
     */
    function initDistribution() external returns (bool) {
        require(_lastDistribution.add(_distributionInterval) <= block.number, "latest distribution is too recent");
        require(_toDistributeThisRound == 0, "current round not fully distributed");

        _lockedAmount = _token.balanceOf(address(this)).sub(_toDistribute);

        _toDistributeThisRound = _lockedAmount.div(_perThousand.div(_baseWeeklyRate));
        if(_toDistributeThisRound > _maxPerInterval)
            _toDistributeThisRound = _maxPerInterval;
        
        _currentIteration = 0;
        
        _lastDistribution = block.number;
        
        return true;
    }
    
    /**
     * distribute rewards for up to maxIterations stackers
     * If end of stackers is not reached, next call to this function will start at the index it previously stopped
     * If end of stackers is reached, end current distribution round
     * This permit us to distribute rewards over several contract calls, preventing gas outage
     *
     * Require that:
     * A distribution is ongoing
     */
    function distribute(uint256 maxIterations) external returns (bool) {
        require(_toDistributeThisRound > 0, "no active round");
        if(_currentIteration.add(maxIterations) > _stackers.length)
            maxIterations = _stackers.length.sub(_currentIteration);
            
        for(uint i = 0; i < maxIterations; i++){
            address holder = _stackers[_currentIteration+i];
            uint256 toDistrib = _balances[holder].mul(_toDistributeThisRound).div(_lockedAmount);
            _balances[holder] = _balances[holder].add(toDistrib);
        }
        
        if(_currentIteration.add(maxIterations) == _stackers.length){
            _toDistribute = _toDistribute.sub(_toDistributeThisRound);
            _distributed = _distributed.add(_toDistributeThisRound);
            _toDistributeThisRound = 0;
        }
        
        _currentIteration = _currentIteration.add(maxIterations);
        
        return true;
    }
}