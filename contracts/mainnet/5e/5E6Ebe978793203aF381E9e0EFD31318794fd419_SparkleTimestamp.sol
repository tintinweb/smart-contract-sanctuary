// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/GSN/Context.sol


pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
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

// File: @openzeppelin/contracts/utils/Pausable.sol


pragma solidity ^0.6.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/ISparkleTimestamp.sol


/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;

// import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol";
// import "../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol";
// import "../node_modules/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";

/**
 * @dev Sparkle Timestamp Contract
 * @author SparkleMobile Inc. (c) 2019-2020
 */
interface ISparkleTimestamp {

  /**
   * @dev Add new reward timestamp for address
   * @param _rewardAddress being added to timestamp collection
   */
  function addTimestamp(address _rewardAddress)
  external
  returns(bool);

  /**
   * @dev Reset timestamp maturity for loyalty address
   * @param _rewardAddress to have reward period reset
   */
  function resetTimestamp(address _rewardAddress)
  external
  returns(bool);

  /**
   * @dev Zero/delete existing loyalty timestamp entry
   * @param _rewardAddress being requested for timestamp deletion
   * @notice Test(s) not passed
   */
  function deleteTimestamp(address _rewardAddress)
  external
  returns(bool);

  /**
   * @dev Get address confirmation for loyalty address
   * @param _rewardAddress being queried for address information
   */
  function getAddress(address _rewardAddress)
  external
  returns(address);

  /**
   * @dev Get timestamp of initial joined timestamp for loyalty address
   * @param _rewardAddress being queried for timestamp information
   */
  function getJoinedTimestamp(address _rewardAddress)
  external
  returns(uint256);

  /**
   * @dev Get timestamp of last deposit for loyalty address
   * @param _rewardAddress being queried for timestamp information
   */
  function getDepositTimestamp(address _rewardAddress)
  external
  returns(uint256);

  /**
   * @dev Get timestamp of reward maturity for loyalty address
   * @param _rewardAddress being queried for timestamp information
   */
  function getRewardTimestamp(address _rewardAddress)
  external
  returns(uint256);

  /**
   * @dev Determine if address specified has a timestamp record
   * @param _rewardAddress being queried for timestamp existance
   */
  function hasTimestamp(address _rewardAddress)
  external
  returns(bool);

  /**
   * @dev Calculate time remaining in seconds until this address' reward matures
   * @param _rewardAddress to query remaining time before reward matures
   */
  function getTimeRemaining(address _rewardAddress)
  external
  returns(uint256, bool, uint256);

  /**
   * @dev Determine if reward is mature for  address
   * @param _rewardAddress Address requesting addition in to loyalty timestamp collection
   */
  function isRewardReady(address _rewardAddress)
  external
  returns(bool);

  /**
   * @dev Change the stored loyalty controller contract address
   * @param _newAddress of new loyalty controller contract address
   */
  function setContractAddress(address _newAddress)
  external;

  /**
   * @dev Return the stored authorized controller address
   * @return Address of loyalty controller contract
   */
  function getContractAddress()
  external
  returns(address);

  /**
   * @dev Change the stored loyalty time period
   * @param _newTimePeriod of new reward period (in seconds)
   */
  function setTimePeriod(uint256 _newTimePeriod)
  external;

  /**
   * @dev Return the current loyalty timer period
   * @return Current stored value of loyalty time period
   */
  function getTimePeriod()
  external
  returns(uint256);

	/**
	 * @dev Event signal: Reset timestamp
	 */
  event ResetTimestamp(address _rewardAddress);

	/**
	 * @dev Event signal: Loyalty contract address waws changed
	 */
	event ContractAddressChanged(address indexed _previousAddress, address indexed _newAddress);

	/**
	 * @dev Event signal: Loyalty reward time period was changed
	 */
	event TimePeriodChanged( uint256 indexed _previousTimePeriod, uint256 indexed _newTimePeriod);

	/**
	 * @dev Event signal: Loyalty reward timestamp was added
	 */
	event TimestampAdded( address indexed _newTimestampAddress );

	/**
	 * @dev Event signal: Loyalty reward timestamp was removed
	 */
	event TimestampDeleted( address indexed _newTimestampAddress );

  /**
   * @dev Event signal: Timestamp for address was reset
   */
  event TimestampReset(address _rewardAddress);

}

// File: contracts/SparkleTimestamp.sol


/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;






/**
 * @dev Sparkle Timestamp Contract
 * @author SparkleMobile Inc. (c) 2019-2020
 */
contract SparkleTimestamp is ISparkleTimestamp, Ownable, Pausable, ReentrancyGuard {
  /**
   * @dev Ensure math safety through SafeMath
   */
  using SafeMath for uint256;

  /**
   * @dev Timestamp object for tacking block.timestamp ooc(out-of-contract)
   * @param _address Address of the owner address of this record
   * @param _joined block.timestamp of initial joining time
   * @param _deposit block.timestamp of reward address' deposit (uint256)
   * @param _reward block.timestamp + loyaltyTimePeriod precalculation (uint256)
   */
  struct Timestamp {
    address _address;
    uint256 _joined;
    uint256 _deposit;
    uint256 _reward;
  }

  /**
   * @dev Internal address for authorized loyalty contract
   */
  address private contractAddress;

  /**
   * @dev Internal time period of reward maturity for all address'
   */
  uint256 private timePeriod;

  /**
   * @dev Internal loyalty timestamp mapping to authorized calling loyalty contracts
   */
  mapping(address => mapping(address => Timestamp)) private g_timestamps;

  /**
   * @dev SparkleTimestamp contract .cTor
   */
  constructor()
  public
  Ownable()
  Pausable()
  ReentrancyGuard()
  {
    /// Initialize contract address to 0x0
    contractAddress = address(0x0);
    /// Initilize time period to 24 hours (86400 seconds)
    timePeriod = 60 * 60 * 24;
  }

  /**
   * @dev Add new reward timestamp for address
   * @param _rewardAddress being added to timestamp collection
   */
  function addTimestamp(address _rewardAddress)
  external
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}a');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0x0), 'Invalid reward address');
    /// Validate specified address does not have a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(0x0), 'Timestamp exists');
    /// Initialize timestamp structure with loyalty users data
    g_timestamps[msg.sender][_rewardAddress]._address = address(_rewardAddress);
    g_timestamps[msg.sender][_rewardAddress]._deposit = block.timestamp;
    g_timestamps[msg.sender][_rewardAddress]._joined = block.timestamp;
    /// Calculate the time in the future reward will mature
    g_timestamps[msg.sender][_rewardAddress]._reward = timePeriod.add(block.timestamp);
    /// Emit event log to the block chain for future web3 use
    emit TimestampAdded(_rewardAddress);
    /// Return success
    return true;
  }

  /**
   * @dev Reset timestamp maturity for loyalty address
   * @param _rewardAddress to have reward period reset
   */
  function resetTimestamp(address _rewardAddress)
  external
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}b');
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0x0), 'Invalid reward address');
    /// Validate specified address has a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress), 'Invalid timestamp');
    /// Re-initialize timestamp structure with updated time data
    g_timestamps[msg.sender][_rewardAddress]._deposit = block.timestamp;
    g_timestamps[msg.sender][_rewardAddress]._reward = uint256(block.timestamp).add(timePeriod);
    /// Return success
    return true;
  }

  /**
   * @dev Zero/delete existing loyalty timestamp entry
   * @param _rewardAddress being requested for timestamp deletion
   * @notice Test(s) not passed
   */
  function deleteTimestamp(address _rewardAddress)
  external
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}c');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), "Invalid reward address ");
    /// Validate specified address has a timestamp
    if(g_timestamps[msg.sender][_rewardAddress]._address != address(_rewardAddress)) {
      emit TimestampDeleted( false );
      return false;
    }

    // Zero out address as delete does nothing with structure elements
    Timestamp storage ts = g_timestamps[msg.sender][_rewardAddress];
    ts._address = address(0x0);
    ts._deposit = 0;
    ts._reward = 0;
    /// Return success
    emit TimestampDeleted( true );
    return true;
  }

  /**
   * @dev Get address confirmation for loyalty address
   * @param _rewardAddress being queried for address information
   */
  function getAddress(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(address)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}d');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Validate specified address has a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress), 'No timestamp b');
    /// Return address indicating success
    return address(g_timestamps[msg.sender][_rewardAddress]._address);
  }

  /**
   * @dev Get timestamp of initial joined timestamp for loyalty address
   * @param _rewardAddress being queried for timestamp information
   */
  function getJoinedTimestamp(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(uint256)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}e');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Validate specified address has a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress), 'No timestamp c');
    /// Return deposit timestamp indicating success
    return g_timestamps[msg.sender][_rewardAddress]._joined;
  }

  /**
   * @dev Get timestamp of last deposit for loyalty address
   * @param _rewardAddress being queried for timestamp information
   */
  function getDepositTimestamp(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(uint256)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}e');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Validate specified address has a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress), 'No timestamp d');
    /// Return deposit timestamp indicating success
    return g_timestamps[msg.sender][_rewardAddress]._deposit;
  }

  /**
   * @dev Get timestamp of reward maturity for loyalty address
   * @param _rewardAddress being queried for timestamp information
   */
  function getRewardTimestamp(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(uint256)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}f');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Return reward timestamp indicating success
    return g_timestamps[msg.sender][_rewardAddress]._reward;
  }


  /**
   * @dev Determine if address specified has a timestamp record
   * @param _rewardAddress being queried for timestamp existance
   */
  function hasTimestamp(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}g');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Determine if timestamp record matches reward address
    // if(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress)) {
    //   /// yes, then return success
    //   return true;
    // }
    if(g_timestamps[msg.sender][_rewardAddress]._address != address(_rewardAddress))
    {
      emit TimestampHasTimestamp(false);
      return false;
    }

    /// Return success
    emit TimestampHasTimestamp(true);
    return true;
  }

  /**
   * @dev Calculate time remaining in seconds until this address' reward matures
   * @param _rewardAddress to query remaining time before reward matures
   */
  function getTimeRemaining(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(uint256, bool, uint256)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}h');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Validate specified address has a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress), 'No timestamp f');
    /// Deterimine if reward address timestamp record has matured
    if(g_timestamps[msg.sender][_rewardAddress]._reward > block.timestamp) {
      /// No, then return indicating remaining time and false to indicate failure
      // return (g_timestamps[msg.sender][_rewardAddress]._reward - block.timestamp, false, g_timestamps[msg.sender][_rewardAddress]._deposit);
      return (g_timestamps[msg.sender][_rewardAddress]._reward - block.timestamp, false, g_timestamps[msg.sender][_rewardAddress]._joined);
    }

    /// Return indicating time since reward maturing and true to indicate success
    // return (block.timestamp - g_timestamps[msg.sender][_rewardAddress]._reward, true, g_timestamps[msg.sender][_rewardAddress]._deposit);
    return (block.timestamp - g_timestamps[msg.sender][_rewardAddress]._reward, true, g_timestamps[msg.sender][_rewardAddress]._joined);
  }

    /**
   * @dev Determine if reward is mature for  address
   * @param _rewardAddress Address requesting addition in to loyalty timestamp collection
   */
  function isRewardReady(address _rewardAddress)
  external
  whenNotPaused
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}i');
    /// Validate caller is valid controller contract
    require(msg.sender == address(contractAddress), 'Unauthorized {From}');
    /// Validate specified address (_rewardAddress)
    require(_rewardAddress != address(0), 'Invalid reward address');
    /// Validate specified address has a timestamp
    require(g_timestamps[msg.sender][_rewardAddress]._address == address(_rewardAddress), 'No timestamp g');
    /// Deterimine if reward address timestamp record has matured
    if(g_timestamps[msg.sender][_rewardAddress]._reward > block.timestamp) {
      /// No, then return false to indicate failure
      return false;
    }

    /// Return success
    return true;
  }

  /**
   * @dev Change the stored loyalty controller contract address
   * @param _newAddress of new loyalty controller contract address
   */
  function setContractAddress(address _newAddress)
  external
  onlyOwner
  nonReentrant
  override
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}j');
    /// Validate specified address (_newAddress)
    require(_newAddress != address(0), 'Invalid contract address');
    address currentAddress = contractAddress;
    /// Set current address to new controller contract address
    contractAddress = _newAddress;
    /// Emit event log to the block chain for future web3 use
    emit ContractAddressChanged(currentAddress, _newAddress);
  }

  /**
   * @dev Return the stored authorized controller address
   * @return Address of loyalty controller contract
   */
  function getContractAddress()
  external
  whenNotPaused
  override
  returns(address)
  {
    /// Return current controller contract address
    return address(contractAddress);
  }

  /**
   * @dev Change the stored loyalty time period
   * @param _newTimePeriod of new reward period (in seconds)
   */
  function setTimePeriod(uint256 _newTimePeriod)
  external
  onlyOwner
  nonReentrant
  override
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}k');
    /// Validate specified time period
    require(_newTimePeriod >= 60 seconds, 'Time period < 60s');
    uint256 currentTimePeriod = timePeriod;
    timePeriod = _newTimePeriod;
    /// Emit event log to the block chain for future web3 use
    emit TimePeriodChanged(currentTimePeriod, _newTimePeriod);
  }

  /**
   * @dev Return the current loyalty timer period
   * @return Current stored value of loyalty time period
   */
  function getTimePeriod()
  external
  whenNotPaused
  override
  returns(uint256)
  {
    /// Return current time period
    return timePeriod;
  }

	/**
	 * @dev Event signal: Reset timestamp
	 */
  event ResetTimestamp(address _rewardAddress);

	/**
	 * @dev Event signal: Loyalty contract address waws changed
	 */
	event ContractAddressChanged(address indexed _previousAddress, address indexed _newAddress);

	/**
	 * @dev Event signal: Loyalty reward time period was changed
	 */
	event TimePeriodChanged( uint256 indexed _previousTimePeriod, uint256 indexed _newTimePeriod);

	/**
	 * @dev Event signal: Loyalty reward timestamp was added
	 */
	event TimestampAdded( address indexed _newTimestampAddress );

	/**
	 * @dev Event signal: Loyalty reward timestamp was removed
	 */
	event TimestampDeleted( bool indexed _timestampDeleted );

  /**
   * @dev Event signal: Timestamp for address was reset
   */
  event TimestampReset(address _rewardAddress);

  /**
   * @dev Event signal: Current hasTimestamp value
   */
  event TimestampHasTimestamp(bool _hasTimestamp);

}