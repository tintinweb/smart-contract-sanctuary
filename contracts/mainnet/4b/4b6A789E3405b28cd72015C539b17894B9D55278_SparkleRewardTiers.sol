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

// File: contracts/SparkleRewardTiers.sol

/// SWC-103:  Floating Pragma
pragma solidity 0.6.12;






/**
  * @title A contract for managing reward tiers
  * @author SparkleLoyalty Inc. (c) 2019-2020
  */
contract SparkleRewardTiers is ISparkleRewardTiers, Ownable, Pausable, ReentrancyGuard {

  /**
    * @dev Ensure math safety through SafeMath
    */
  using SafeMath for uint256;

  /**
    * @dev Data structure declaring a loyalty tier
    * @param _rate apr for reward tier
    * @param _price to select reward tier
    * @param _enabled availability for reward tier
    */
  struct Tier {
    uint256 _rate;
    uint256 _price;
    bool _enabled;
  }

  // tiers mapping of available reward tiers
  mapping(uint256 => Tier) private g_tiers;

  /**
    * @dev Sparkle loyalty tier rewards contract
    * @notice Timestamp support for SparklePOL contract
    */
  constructor()
  public
  Ownable()
  Pausable()
  ReentrancyGuard()
  {
    Tier memory tier0;
    tier0._rate = uint256(1.00000000 * 10e7);
    tier0._price = 0 ether;
    tier0._enabled = true;
    /// Initialize default reward tier
    g_tiers[0] = tier0;

    Tier memory tier1;
    tier1._rate = uint256(1.10000000 * 10e7);
    tier1._price = 0.10 ether;
    tier1._enabled = true;
    /// Initialize reward tier 1
    g_tiers[1] = tier1;

    Tier memory tier2;
    tier2._rate = uint256(1.20000000 * 10e7);
    tier2._price = 0.20 ether;
    tier2._enabled = true;
    /// Initialize reward tier 2
    g_tiers[2] = tier2;

    Tier memory tier3;
    tier3._rate = uint256(1.30000000 * 10e7);
    tier3._price = 0.30 ether;
    tier3._enabled = true;
    /// Initialize reward tier 3
    g_tiers[3] = tier3;
  }

  /**
    * @dev Add a new reward tier to the contract for future proofing
    * @param _index of the new reward tier to add
    * @param _rate of the added reward tier
    * @param _price of the added reward tier
    * @param _enabled status of the added reward tier
    * @notice Test(s) Need rewrite
    */
  function addTier(uint256 _index, uint256 _rate, uint256 _price, bool _enabled)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    /// Validate that tier does not already exist
    require(g_tiers[_index]._enabled == false, 'Tier exists');
    Tier memory newTier;
    /// Initialize structure to specified data
    newTier._rate = _rate;
    newTier._price = _price;
    newTier._enabled = _enabled;
    /// Insert tier into collection
    g_tiers[_index] = newTier;
    /// Emit event log to the block chain for future web3 use
    emit TierAdded(_index, _rate, _price, _enabled);
    /// Return success
    return true;
  }

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
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    require(g_tiers[_index]._rate > 0, 'Invalid tier');
    /// Validate that reward and ether values
    require(_rate > 0, 'Invalid rate');
    require(_price > 0, 'Invalid Price');
    /// Update the specified tier with specified data
    g_tiers[_index]._rate = _rate;
    g_tiers[_index]._price = _price;
    g_tiers[_index]._enabled = _enabled;
    /// Emit event log to the block chain for future web3 use
    emit TierUpdated(_index, _rate, _price, _enabled);
    /// Return success
    return true;
  }

  /**
    * @dev Remove an existing reward tier from list of tiers
    * @param _index of reward tier to remove
    * @notice Test(s) Need rewrite
    */
  function deleteTier(uint256 _index)
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    /// Validate tier delete does not delete system tiers 0-2
    require(_index >= 4, 'Invalid request');
    /// Zero out the spcified tier's data
    delete g_tiers[_index];
    /// Emit event log to the block chain for future web3 use
    emit TierDeleted(_index);
    /// Return success
    return true;
  }

  /**
    * @dev Get the rate value of specified tier
    * @param _index of tier to query
    * @return specified reward tier rate
    * @notice Test(s) Need rewrite
    */
  function getRate(uint256 _index)
  public
  whenNotPaused
  override
  returns(uint256)
  {
    /// Return reward rate for specified tier
    return g_tiers[_index]._rate;
  }

  /**
    * @dev Get price of tier
    * @param _index of tier to query
    * @return uint256 indicating tier price
    * @notice Test(s) Need rewrite
    */
  function getPrice(uint256 _index)
  public
  whenNotPaused
  override
  returns(uint256)
  {
    /// Return reward purchase price in ether for tier
    return g_tiers[_index]._price;
  }

  /**
    * @dev Get the enabled status of tier
    * @param _index of tier to query
    * @return bool indicating status of tier
    * @notice Test(s) Need rewrite
    */
  function getEnabled(uint256 _index)
  public
  whenNotPaused
  override
  returns(bool)
  {
    /// Return reward tier enabled status for specified tier
    return g_tiers[_index]._enabled;
  }

  /**
    * @dev Withdraw ether that has been sent directly to the contract
    * @return bool indicating withdraw success
    * @notice Test(s) Need rewrite
    */
  function withdrawEth()
  public
  onlyOwner
  whenNotPaused
  nonReentrant
  override
  returns(bool)
  {
    /// Validate calling address (msg.sender)
    require(msg.sender != address(0x0), 'Invalid {From}');
    /// Validate that this contract is storing ether
    require(address(this).balance >= 0, 'No ether');
    /// Transfer the ether to owner address
    msg.sender.transfer(address(this).balance);
    return true;
  }

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