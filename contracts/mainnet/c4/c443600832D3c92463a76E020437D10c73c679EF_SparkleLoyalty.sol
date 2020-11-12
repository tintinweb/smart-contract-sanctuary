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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.6.0;

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

// File: contracts/ISparkleRewardTiers.sol


/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;

// import '../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
// import '../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol';
// import '../node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol';
// import '../node_modules/openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol';

/**
  * @title A contract for managing reward tiers
  * @author SparkleLoyalty Inc. (c) 2019-2020
  */
// interface ISparkleRewardTiers is Ownable, Pausable, ReentrancyGuard {
interface ISparkleRewardTiers {

  /**
    * @dev Add a new reward tier to the contract for future proofing
    * @param _index of the new reward tier to add
    * @param _rate of the added reward tier
    * @param _price of the added reward tier
    * @param _enabled status of the added reward tier
    * @notice Test(s) Need rewrite
    */
  function addTier(uint256 _index, uint256 _rate, uint256 _price, bool _enabled)
  external
  // view
  // onlyOwner
  // whenNotPaused
  // nonReentrant
  returns(bool);

  /**
    * @dev Update an existing reward tier with new values
    * @param _index of reward tier to update
    * @param _rate of the reward tier
    * @param _price of the reward tier
    * @param _enabled status of the reward tier
    * @return (bool) indicating success/failure
    * @notice Test(s) Need rewrite
    */
  function updateTier(uint256 _index, uint256 _rate, uint256 _price, bool _enabled)
  external
  // view
  // onlyOwner
  // whenNotPaused
  // nonReentrant
  returns(bool);

  /**
    * @dev Remove an existing reward tier from list of tiers
    * @param _index of reward tier to remove
    * @notice Test(s) Need rewrite
    */
  function deleteTier(uint256 _index)
  external
  // view
  // onlyOwner
  // whenNotPaused
  // nonReentrant
  returns(bool);

  /**
    * @dev Get the rate value of specified tier
    * @param _index of tier to query
    * @return specified reward tier rate
    * @notice Test(s) Need rewrite
    */
  function getRate(uint256 _index)
  external
  // view
  // whenNotPaused
  returns(uint256);

  /**
    * @dev Get price of tier
    * @param _index of tier to query
    * @return uint256 indicating tier price
    * @notice Test(s) Need rewrite
    */
  function getPrice(uint256 _index)
  external
  // view
  // whenNotPaused
  returns(uint256);

  /**
    * @dev Get the enabled status of tier
    * @param _index of tier to query
    * @return bool indicating status of tier
    * @notice Test(s) Need rewrite
    */
  function getEnabled(uint256 _index)
  external
  // view
  // whenNotPaused
  returns(bool);

  /**
    * @dev Withdraw ether that has been sent directly to the contract
    * @return bool indicating withdraw success
    * @notice Test(s) Need rewrite
    */
  function withdrawEth()
  external
  // onlyOwner
  // whenNotPaused
  // nonReentrant
  returns(bool);

  /**
    * @dev Event triggered when a reward tier is deleted
    * @param _index of tier to deleted
    */
  event TierDeleted(uint256 _index);

  /**
    * @dev Event triggered when a reward tier is updated
    * @param _index of the updated tier
    * @param _rate of updated tier
    * @param _price of updated tier
    * @param _enabled status of updated tier
    */
  event TierUpdated(uint256 _index, uint256 _rate, uint256 _price, bool _enabled);

  /**
    * @dev Event triggered when a new reward tier is added
    * @param _index of the tier added
    * @param _rate of added tier
    * @param _price of added tier
    * @param _enabled status of added tier
    */
  event TierAdded(uint256 _index, uint256 _rate, uint256 _price, bool _enabled);

}

// File: contracts/SparkleLoyalty.sol


/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;








/**
  * @dev Sparkle Loyalty Rewards
  * @author SparkleMobile Inc.
  */
contract SparkleLoyalty is Ownable, Pausable, ReentrancyGuard {

  /**
   * @dev Ensure math safety through SafeMath
   */
  using SafeMath for uint256;

  // Gas to send with certain transations that may cost more in the future due to chain growth
  uint256 private gasToSendWithTX = 25317;
  // Base rate APR (5%) factored to 365.2422 gregorian days
  uint256 private baseRate = 0.00041069 * 10e7; // A full year is 365.2422 gregorian days (5%)

  // Account data structure
  struct Account {
    address _address; // Loyalty reward address
    uint256 _balance; // Total tokens deposited
    uint256 _collected; // Total tokens collected
    uint256 _claimed; // Total succesfull reward claims
    uint256 _joined; // Total times address has joined
    uint256 _tier; // Tier index of reward tier
    bool _isLocked; // Is the account locked
  }

  // tokenAddress of erc20 token address
  address private tokenAddress;

  // timestampAddress of time stamp contract address
  address private timestampAddress;

  // treasuryAddress of token treeasury address
  address private treasuryAddress;

  // collectionAddress to receive eth payed for tier upgrades
  address private collectionAddress;

  // rewardTiersAddress to resolve reward tier specifications
  address private tiersAddress;

  // minProofRequired to deposit of rewards to be eligibile
  uint256 private minRequired;

  // maxProofAllowed for deposit to be eligibile
  uint256 private maxAllowed;

  // totalTokensClaimed of all rewards awarded
  uint256 private totalTokensClaimed;

  // totalTimesClaimed of all successfully claimed rewards
  uint256 private totalTimesClaimed;

  // totalActiveAccounts count of all currently active addresses
  uint256 private totalActiveAccounts;

  // Accounts mapping of user loyalty records
  mapping(address => Account) private accounts;

  /**
   * @dev Sparkle Loyalty Rewards Program contract .cTor
   * @param _tokenAddress of token used for proof of loyalty rewards
   * @param _treasuryAddress of proof of loyalty token reward distribution
   * @param _collectionAddress of ethereum account to collect tier upgrade eth
   * @param _tiersAddress of the proof of loyalty tier rewards support contract
   * @param _timestampAddress of the proof of loyalty timestamp support contract
  */
  constructor(address _tokenAddress, address _treasuryAddress, address _collectionAddress, address _tiersAddress, address _timestampAddress)
  public
  Ownable()
  Pausable()
  ReentrancyGuard()
  {
    // Initialize contract internal addresse(s) from params
    tokenAddress = _tokenAddress;
    treasuryAddress = _treasuryAddress;
    collectionAddress = _collectionAddress;
    tiersAddress = _tiersAddress;
    timestampAddress = _timestampAddress;

    // Initialize minimum/maximum allowed deposit limits
    minRequired = uint256(1000).mul(10e7);
    maxAllowed = uint256(250000).mul(10e7);
  }

  /**
   * @dev Deposit additional tokens to a reward address loyalty balance
   * @param _depositAmount of tokens to deposit into  a reward address balance
   * @return bool indicating the success of the deposit operation (true == success)
   */
  function depositLoyalty(uint _depositAmount)
  public
  whenNotPaused
  nonReentrant
  returns (bool)
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}1');
    // Validate specified value meets minimum requirements
    require(_depositAmount >= minRequired, 'Minimum required');

    // Determine if caller has approved enough allowance for this deposit
    if(IERC20(tokenAddress).allowance(msg.sender, address(this)) < _depositAmount) {
      // No, rever informing that deposit amount exceeded allownce amount
      revert('Exceeds allowance');
    }

    // Obtain a storage instsance of callers account record
    Account storage loyaltyAccount = accounts[msg.sender];

    // Determine if there is an upper deposit cap
    if(maxAllowed > 0) {
      // Yes, determine if the deposit amount + current balance exceed max deposit cap
      if(loyaltyAccount._balance.add(_depositAmount) > maxAllowed || _depositAmount > maxAllowed) {
        // Yes, revert informing that the maximum deposit cap has been exceeded
        revert('Exceeds cap');
      }

    }

    // Determine if the tier selected is enabled
    if(!ISparkleRewardTiers(tiersAddress).getEnabled(loyaltyAccount._tier)) {
      // No, then this tier cannot be selected
      revert('Invalid tier');
    }

    // Determine of transfer from caller has succeeded
    if(IERC20(tokenAddress).transferFrom(msg.sender, address(this), _depositAmount)) {
      // Yes, thend determine if the specified address has a timestamp record
      if(ISparkleTimestamp(timestampAddress).hasTimestamp(msg.sender)) {
        // Yes, update callers account balance by deposit amount
        loyaltyAccount._balance = loyaltyAccount._balance.add(_depositAmount);
        // Reset the callers reward timestamp
        _resetTimestamp(msg.sender);
        //
        emit DepositLoyaltyEvent(msg.sender, _depositAmount, true);
        // Return success
        return true;
      }

      // Determine if a timestamp has been added for caller
      if(!ISparkleTimestamp(timestampAddress).addTimestamp(msg.sender)) {
        // No, revert indicating there was some kind of error
        revert('No timestamp created');
      }

      // Prepare loyalty account record
      loyaltyAccount._address = address(msg.sender);
      loyaltyAccount._balance = _depositAmount;
      loyaltyAccount._joined = loyaltyAccount._joined.add(1);
      // Update global account counter
      totalActiveAccounts = totalActiveAccounts.add(1);
      //
      emit DepositLoyaltyEvent(msg.sender, _depositAmount, false);
      // Return success
      return true;
    }

    // Return failure
    return false;
  }

  /**
   * @dev Claim Sparkle Loyalty reward
   */
  function claimLoyaltyReward()
  public
  whenNotPaused
  nonReentrant
  returns(bool)
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // Validate caller has a timestamp and it has matured
    require(ISparkleTimestamp(timestampAddress).hasTimestamp(msg.sender), 'No record');
    require(ISparkleTimestamp(timestampAddress).isRewardReady(msg.sender), 'Not mature');

    // Obtain the current state of the callers timestamp
    (uint256 timeRemaining, bool isReady, uint256 rewardDate) = ISparkleTimestamp(timestampAddress).getTimeRemaining(msg.sender);
    // Determine if the callers reward has matured
    if(isReady) {
      // Value not used but throw unused var warning (cleanup)
      rewardDate = 0;
      // Yes, then obtain a storage instance of callers account record
      Account storage loyaltyAccount = accounts[msg.sender];
      // Obtain values required for caculations
      uint256 dayCount = (timeRemaining.div(ISparkleTimestamp(timestampAddress).getTimePeriod())).add(1);
      uint256 tokenBalance = loyaltyAccount._balance.add(loyaltyAccount._collected);
      uint256 rewardRate = ISparkleRewardTiers(tiersAddress).getRate(loyaltyAccount._tier);
      uint256 rewardTotal = baseRate.mul(tokenBalance).mul(rewardRate).mul(dayCount).div(10e7).div(10e7);
      // Increment collected by reward total
      loyaltyAccount._collected = loyaltyAccount._collected.add(rewardTotal);
      // Increment total number of times a reward has been claimed
      loyaltyAccount._claimed = loyaltyAccount._claimed.add(1);
      // Incrememtn total number of times rewards have been collected by all
      totalTimesClaimed = totalTimesClaimed.add(1);
      // Increment total number of tokens claimed
      totalTokensClaimed += rewardTotal;
      // Reset the callers timestamp record
      _resetTimestamp(msg.sender);
      // Emit event log to the block chain for future web3 use
      emit RewardClaimedEvent(msg.sender, rewardTotal);
      // Return success
      return true;
    }

    // Revert opposed to returning boolean (May or may not return a txreceipt)
    revert('Failed claim');
  }

  /**
   * @dev Withdraw the current deposit balance + any earned loyalty rewards
   */
  function withdrawLoyalty()
  public
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // validate that caller has a loyalty timestamp
    require(ISparkleTimestamp(timestampAddress).hasTimestamp(msg.sender), 'No timestamp2');

    // Determine if the account has been locked
    if(accounts[msg.sender]._isLocked) {
      // Yes, revert informing that this loyalty account has been locked
      revert('Locked');
    }

    // Obtain values needed from account record before zeroing
    uint256 joinCount = accounts[msg.sender]._joined;
    uint256 collected = accounts[msg.sender]._collected;
    uint256 deposit = accounts[msg.sender]._balance;
    bool isLocked = accounts[msg.sender]._isLocked;
    // Zero out the callers account record
    Account storage account = accounts[msg.sender];
    account._address = address(0x0);
    account._balance = 0x0;
    account._collected = 0x0;
    account._joined = joinCount;
    account._claimed = 0x0;
    account._tier = 0x0;
    // Preserve account lock even after withdraw (account always locked)
    account._isLocked = isLocked;
    // Decement the total number of active accounts
    totalActiveAccounts = totalActiveAccounts.sub(1);

    // Delete the callers timestamp record
    _deleteTimestamp(msg.sender);

    // Determine if transfer from treasury address is a success
    if(!IERC20(tokenAddress).transferFrom(treasuryAddress, msg.sender, collected)) {
      // No, revert indicating that the transfer and wisthdraw has failed
      revert('Withdraw failed');
    }

    // Determine if transfer from contract address is a sucess
    if(!IERC20(tokenAddress).transfer(msg.sender, deposit)) {
      // No, revert indicating that the treansfer and withdraw has failed
      revert('Withdraw failed');
    }

    // Emit event log to the block chain for future web3 use
    emit LoyaltyWithdrawnEvent(msg.sender, deposit.add(collected));
  }

  function returnLoyaltyDeposit(address _rewardAddress)
  public
  whenNotPaused
  onlyOwner
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // validate that caller has a loyalty timestamp
    require(ISparkleTimestamp(timestampAddress).hasTimestamp(_rewardAddress), 'No timestamp2');
    // Validate that reward address is locked
    require(accounts[_rewardAddress]._isLocked, 'Lock account first');
    uint256 deposit = accounts[_rewardAddress]._balance;
    Account storage account = accounts[_rewardAddress];
    account._balance = 0x0;
    // Determine if transfer from contract address is a sucess
    if(!IERC20(tokenAddress).transfer(_rewardAddress, deposit)) {
      // No, revert indicating that the treansfer and withdraw has failed
      revert('Withdraw failed');
    }

    // Emit event log to the block chain for future web3 use
    emit LoyaltyDepositWithdrawnEvent(_rewardAddress, deposit);
  }

  function returnLoyaltyCollected(address _rewardAddress)
  public
  whenNotPaused
  onlyOwner
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // validate that caller has a loyalty timestamp
    require(ISparkleTimestamp(timestampAddress).hasTimestamp(_rewardAddress), 'No timestamp2b');
    // Validate that reward address is locked
    require(accounts[_rewardAddress]._isLocked, 'Lock account first');
    uint256 collected = accounts[_rewardAddress]._collected;
    Account storage account = accounts[_rewardAddress];
    account._collected = 0x0;
    // Determine if transfer from treasury address is a success
    if(!IERC20(tokenAddress).transferFrom(treasuryAddress, _rewardAddress, collected)) {
      // No, revert indicating that the transfer and wisthdraw has failed
      revert('Withdraw failed');
    }

    // Emit event log to the block chain for future web3 use
    emit LoyaltyCollectedWithdrawnEvent(_rewardAddress, collected);
  }

  function removeLoyaltyAccount(address _rewardAddress)
  public
  whenNotPaused
  onlyOwner
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // validate that caller has a loyalty timestamp
    require(ISparkleTimestamp(timestampAddress).hasTimestamp(_rewardAddress), 'No timestamp2b');
    // Validate that reward address is locked
    require(accounts[_rewardAddress]._isLocked, 'Lock account first');
    uint256 joinCount = accounts[_rewardAddress]._joined;
    Account storage account = accounts[_rewardAddress];
    account._address = address(0x0);
    account._balance = 0x0;
    account._collected = 0x0;
    account._joined = joinCount;
    account._claimed = 0x0;
    account._tier = 0x0;
    account._isLocked = false;
    // Decement the total number of active accounts
    totalActiveAccounts = totalActiveAccounts.sub(1);

    // Delete the callers timestamp record
    _deleteTimestamp(_rewardAddress);

    emit LoyaltyAccountRemovedEvent(_rewardAddress);
  }

  /**
   * @dev Gets the locked status of the specified address
   * @param _loyaltyAddress of account
   * @return (bool) indicating locked status
   */
  function isLocked(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns (bool)
  {
    return accounts[_loyaltyAddress]._isLocked;
  }

  function lockAccount(address _rewardAddress, bool _value)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}');
    require(_rewardAddress != address(0x0), 'Invalid {reward}');
    // Validate specified address has timestamp
    require(ISparkleTimestamp(timestampAddress).hasTimestamp(_rewardAddress), 'No timstamp');
    // Set the specified address' locked status
    accounts[_rewardAddress]._isLocked = _value;
    // Emit event log to the block chain for future web3 use
    emit LockedAccountEvent(_rewardAddress, _value);
  }

  /**
   * @dev Gets the storage address value of the specified address
   * @param _loyaltyAddress of account
   * @return (address) indicating the address stored calls account record
   */
  function getLoyaltyAddress(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns(address)
  {
    return accounts[_loyaltyAddress]._address;
  }

  /**
   * @dev Get the deposit balance value of specified address
   * @param _loyaltyAddress of account
   * @return (uint256) indicating the balance value
   */
  function getDepositBalance(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return accounts[_loyaltyAddress]._balance;
  }

  /**
   * @dev Get the tokens collected by the specified address
   * @param _loyaltyAddress of account
   * @return (uint256) indicating the tokens collected
   */
  function getTokensCollected(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return accounts[_loyaltyAddress]._collected;
  }

  /**
   * @dev Get the total balance (deposit + collected) of tokens
   * @param _loyaltyAddress of account
   * @return (uint256) indicating total balance
   */
  function getTotalBalance(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return accounts[_loyaltyAddress]._balance.add(accounts[_loyaltyAddress]._collected);
  }

  /**
   * @dev Get the times loyalty has been claimed
   * @param _loyaltyAddress of account
   * @return (uint256) indicating total time claimed
   */
  function getTimesClaimed(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return accounts[_loyaltyAddress]._claimed;
  }

  /**
   * @dev Get total number of times joined
   * @param _loyaltyAddress of account
   * @return (uint256)
   */
  function getTimesJoined(address _loyaltyAddress)
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return accounts[_loyaltyAddress]._joined;
  }

  /**
   * @dev Get time remaining before reward maturity
   * @param _loyaltyAddress of account
   * @return (uint256, bool) Indicating time remaining/past and boolean indicating maturity
   */
  function getTimeRemaining(address _loyaltyAddress)
  public
  whenNotPaused
  returns (uint256, bool, uint256)
  {
    (uint256 remaining, bool status, uint256 deposit) = ISparkleTimestamp(timestampAddress).getTimeRemaining(_loyaltyAddress);
    return (remaining, status, deposit);
  }

  /**
   * @dev Withdraw any ether that has been sent directly to the contract
   * @param _loyaltyAddress of account
   * @return Total number of tokens that have been claimed by users
   * @notice Test(s) Not written
   */
  function getRewardTier(address _loyaltyAddress)
  public
  view whenNotPaused
  returns(uint256)
  {
    return accounts[_loyaltyAddress]._tier;
  }

  /**
   * @dev Select reward tier for msg.sender
   * @param _tierSelected id of the reward tier interested in purchasing
   * @return (bool) indicating failure/success
   */
  function selectRewardTier(uint256 _tierSelected)
  public
  payable
  whenNotPaused
  nonReentrant
  returns(bool)
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    // Validate specified address has a timestamp
    require(accounts[msg.sender]._address == address(msg.sender), 'No timestamp3');
    // Validate tier selection
    require(accounts[msg.sender]._tier != _tierSelected, 'Already selected');
    // Validate that ether was sent with the call
    require(msg.value > 0, 'No ether');

    // Determine if the specified rate is > than existing rate
    if(ISparkleRewardTiers(tiersAddress).getRate(accounts[msg.sender]._tier) >= ISparkleRewardTiers(tiersAddress).getRate(_tierSelected)) {
      // No, revert indicating failure
      revert('Invalid tier');
    }

    // Determine if ether transfer for tier upgrade has completed successfully
    (bool success, ) = address(collectionAddress).call{value: ISparkleRewardTiers(tiersAddress).getPrice(_tierSelected), gas: gasToSendWithTX}('');
    require(success, 'Rate unchanged');

    // Update callers rate with the new selected rate
    accounts[msg.sender]._tier = _tierSelected;
    emit TierSelectedEvent(msg.sender, _tierSelected);
    // Return success
    return true;
  }

  function getRewardTiersAddress()
  public
  view
  whenNotPaused
  returns(address)
  {
    return tiersAddress;
  }

  /**
   * @dev Set tier collectionm address
   * @param _newAddress of new collection address
   * @notice Test(s) not written
   */
  function setRewardTiersAddress(address _newAddress)
  public
  whenNotPaused
  onlyOwner
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    // Validate specified address is valid
    require(_newAddress != address(0), 'Invalid {reward}');
    // Set tier rewards contract address
    tiersAddress = _newAddress;
    emit TiersAddressChanged(_newAddress);
  }

  function getCollectionAddress()
  public
  view
  whenNotPaused
  returns(address)
  {
    return collectionAddress;
  }

  /** @notice Test(s) passed
   * @dev Set tier collectionm address
   * @param _newAddress of new collection address
   */
  function setCollectionAddress(address _newAddress)
  public
  whenNotPaused
  onlyOwner
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    // Validate specified address is valid
    require(_newAddress != address(0), 'Invalid {collection}');
    // Set tier collection address
    collectionAddress = _newAddress;
    emit CollectionAddressChanged(_newAddress);
  }

  function getTreasuryAddress()
  public
  view
  whenNotPaused
  returns(address)
  {
    return treasuryAddress;
  }

  /**
   * @dev Set treasury address
   * @param _newAddress of the treasury address
   * @notice Test(s) passed
   */
  function setTreasuryAddress(address _newAddress)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), "Invalid {from}");
    // Validate specified address
    require(_newAddress != address(0), "Invalid {treasury}");
    // Set current treasury contract address
    treasuryAddress = _newAddress;
    emit TreasuryAddressChanged(_newAddress);
  }

  function getTimestampAddress()
  public
  view
  whenNotPaused
  returns(address)
  {
    return timestampAddress;
  }

  /**
   * @dev Set the timestamp address
   * @param _newAddress of timestamp address
   * @notice Test(s) passed
   */
  function setTimestampAddress(address _newAddress)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), "Invalid {from}");
    // Set current timestamp contract address
    timestampAddress = _newAddress;
    emit TimestampAddressChanged(_newAddress);
  }

  function getTokenAddress()
  public
  view
  whenNotPaused
  returns(address)
  {
    return tokenAddress;
  }

  /**
   * @dev Set the loyalty token address
   * @param _newAddress of the new token address
   * @notice Test(s) passed
   */
  function setTokenAddress(address _newAddress)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), "Invalid {from}");
    // Set current token contract address
    tokenAddress = _newAddress;
    emit TokenAddressChangedEvent(_newAddress);
  }

  function getSentGasAmount()
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return gasToSendWithTX;
  }

  function setSentGasAmount(uint256 _amount)
  public
  onlyOwner
  whenNotPaused
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // Set the current minimum deposit allowed
    gasToSendWithTX = _amount;
    emit GasSentChanged(_amount);
  }

  function getBaseRate()
  public
  view
  whenNotPaused
  returns(uint256)
  {
    return baseRate;
  }

  function setBaseRate(uint256 _newRate)
  public
  onlyOwner
  whenNotPaused
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // Set the current minimum deposit allowed
    baseRate = _newRate;
    emit BaseRateChanged(_newRate);
  }

  /**
   * @dev Set the minimum Proof Of Loyalty amount allowed for deposit
   * @param _minProof amount for new minimum accepted loyalty reward deposit
   * @notice _minProof value is multiplied internally by 10e7. Do not multiply before calling!
   */
  function setMinProof(uint256 _minProof)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    // Validate specified minimum is not lower than 1000 tokens
    require(_minProof >= 1000, 'Invalid amount');
    // Set the current minimum deposit allowed
    minRequired = _minProof.mul(10e7);
    emit MinProofChanged(minRequired);
  }

  event MinProofChanged(uint256);
  /**
   * @dev Get the minimum Proof Of Loyalty amount allowed for deposit
   * @return Amount of tokens required for Proof Of Loyalty Rewards
   * @notice Test(s) passed
   */
  function getMinProof()
  public
  view
  whenNotPaused
  returns(uint256)
  {
    // Return indicating minimum deposit allowed
    return minRequired;
  }

  /**
   * @dev Set the maximum Proof Of Loyalty amount allowed for deposit
   * @param _maxProof amount for new maximum loyalty reward deposit
   * @notice _maxProof value is multiplied internally by 10e7. Do not multiply before calling!
   * @notice Smallest maximum value is 1000 + _minProof amount. (Ex: If _minProof == 1000 then smallest _maxProof possible is 2000)
   */
  function setMaxProof(uint256 _maxProof)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0), 'Invalid {from}');
    require(_maxProof >= 2000, 'Invalid amount');
    // Set allow maximum deposit
    maxAllowed = _maxProof.mul(10e7);
  }

  /**
   * @dev Get the maximum Proof Of Loyalty amount allowed for deposit
   * @return Maximum amount of tokens allowed for Proof Of Loyalty deposit
   * @notice Test(s) passed
   */
  function getMaxProof()
  public
  view
  whenNotPaused
  returns(uint256)
  {
    // Return indicating current allowed maximum deposit
    return maxAllowed;
  }

  /**
   * @dev Get the total number of tokens claimed by all users
   * @return Total number of tokens that have been claimed by users
   * @notice Test(s) Not written
   */
  function getTotalTokensClaimed()
  public
  view
  whenNotPaused
  returns(uint256)
  {
    // Return indicating total number of tokens that have been claimed by all
    return totalTokensClaimed;
  }

  /**
   * @dev Get total number of times rewards have been claimed for all users
   * @return Total number of times rewards have been claimed
   */
  function getTotalTimesClaimed()
  public
  view
  whenNotPaused
  returns(uint256)
  {
    // Return indicating total number of tokens that have been claimed by all
    return totalTimesClaimed;
  }

  /**
   * @dev Withdraw any ether that has been sent directly to the contract
   */
  function withdrawEth(address _toAddress)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}');
    // Validate specified address
    require(_toAddress != address(0x0), 'Invalid {to}');
    // Validate there is ether to withdraw
    require(address(this).balance > 0, 'No ether');
    // Determine if ether transfer of stored ether has completed successfully
    // require(address(_toAddress).call.value(address(this).balance).gas(gasToSendWithTX)(), 'Withdraw failed');
    (bool success, ) = address(_toAddress).call{value:address(this).balance, gas: gasToSendWithTX}('');
    require(success, 'Withdraw failed');
  }

  /**
   * @dev Withdraw any ether that has been sent directly to the contract
   * @param _toAddress to receive any stored token balance
   */
  function withdrawTokens(address _toAddress)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}');
    // Validate specified address
    require(_toAddress != address(0), "Invalid {to}");
    // Validate there are tokens to withdraw
    uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
    require(balance != 0, "No tokens");

    // Validate the transfer of tokens completed successfully
    if(IERC20(tokenAddress).transfer(_toAddress, balance)) {
      emit TokensWithdrawn(_toAddress, balance);
    }
  }

  /**
   * @dev Override loyalty account tier by contract owner
   * @param _loyaltyAccount loyalty account address to tier override
   * @param _tierSelected reward tier to override current tier value
   * @return (bool) indicating success status
   */
  function overrideRewardTier(address _loyaltyAccount, uint256 _tierSelected)
  public
  whenNotPaused
  onlyOwner
  nonReentrant
  returns(bool)
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}');
    require(_loyaltyAccount != address(0x0), 'Invalid {account}');
    // Validate specified address has a timestamp
    require(accounts[_loyaltyAccount]._address == address(_loyaltyAccount), 'No timestamp4');
    // Update the specified loyalty address tier reward index
    accounts[_loyaltyAccount]._tier = _tierSelected;
    emit RewardTierChanged(_loyaltyAccount, _tierSelected);
  }

  /**
   * @dev Reset the specified loyalty account timestamp
   * @param _rewardAddress of the loyalty account to perfornm a reset
   */
  function _resetTimestamp(address _rewardAddress)
  internal
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}');
    // Validate specified address
    require(_rewardAddress != address(0), "Invalid {reward}");
    // Reset callers timestamp for specified address
    require(ISparkleTimestamp(timestampAddress).resetTimestamp(_rewardAddress), 'Reset failed');
    emit ResetTimestampEvent(_rewardAddress);
  }

  /**
   * @dev Delete the specified loyalty account timestamp
   * @param _rewardAddress of the loyalty account to perfornm the delete
   */
  function _deleteTimestamp(address _rewardAddress)
  internal
  {
    // Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {from}16');
    // Validate specified address
    require(_rewardAddress != address(0), "Invalid {reward}");
    // Delete callers timestamp for specified address
    require(ISparkleTimestamp(timestampAddress).deleteTimestamp(_rewardAddress), 'Delete failed');
    emit DeleteTimestampEvent(_rewardAddress);
  }

  /**
   * @dev Event signal: Treasury address updated
   */
  event TreasuryAddressChanged(address);

  /**
   * @dev Event signal: Timestamp address updated
   */
  event TimestampAddressChanged(address);

  /**
   * @dev Event signal: Token address updated
   */
  event TokenAddressChangedEvent(address);

  /**
   * @dev Event signal: Timestamp reset
   */
  event ResetTimestampEvent(address _rewardAddress);

  /**
   * @dev Event signal: Timestamp deleted
   */
  event DeleteTimestampEvent(address _rewardAddress);

  /**
   * @dev Event signal: Loyalty deposited event
   */
  event DepositLoyaltyEvent(address, uint256, bool);

  /**
   * @dev Event signal: Reward claimed successfully for address
   */
  event RewardClaimedEvent(address, uint256);

  /**
   * @dev Event signal: Loyalty withdrawn
   */
  event LoyaltyWithdrawnEvent(address, uint256);

  /**
   * @dev Event signal: Account locked/unlocked
   */
  event LockedAccountEvent(address _rewardAddress, bool _locked);

  /**
   * @dev Event signal: Loyalty deposit balance withdrawn
   */
  event LoyaltyDepositWithdrawnEvent(address, uint256);

  /**
   * @dev Event signal: Loyalty collected balance withdrawn
   */
  event LoyaltyCollectedWithdrawnEvent(address, uint256);

  /**
   * @dev Event signal: Loyalty account removed
   */
  event LoyaltyAccountRemovedEvent(address);

  /**
   * @dev Event signal: Gas sent with call.value amount updated
   */
  event GasSentChanged(uint256);
  /**
   * @dev Event signal: Reward tiers address updated
   */
  event TierSelectedEvent(address, uint256);

  /**
   * @dev Event signal: Reward tiers address updated
   */
  event TiersAddressChanged(address);

   /**
   * @dev Event signal: Reward tier has been updated
   */
  event RewardTierChanged(address, uint256);

 /**
   * @dev Event signal: Collection address updated
   */
  event CollectionAddressChanged(address);

  /**
   * @dev Event signal: All stored tokens have been removed
   */
  event TokensWithdrawn(address, uint256);

  /**
   * @dev Event signal: Apr base rate has been changed
   */
  event BaseRateChanged(uint256);
}