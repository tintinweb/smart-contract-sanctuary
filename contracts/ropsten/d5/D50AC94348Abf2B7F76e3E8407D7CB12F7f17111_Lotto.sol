/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.12;


/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// Bytes32Set
contract EnumerableBytes32SetMock {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    event OperationResult(bool result);

    EnumerableSet.Bytes32Set private _set;

    function contains(bytes32 value) public view returns (bool) {
        return _set.contains(value);
    }

    function add(bytes32 value) public {
        // bool result = _set.add(value);
        // emit OperationResult(result);
    }

    function remove(bytes32 value) public {
        // bool result = _set.remove(value);
        // emit OperationResult(result);
    }

    function length() public view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) public view returns (bytes32) {
        return _set.at(index);
    }
}

// AddressSet
contract EnumerableAddressSetMock {
    using EnumerableSet for EnumerableSet.AddressSet;

    event OperationResult(bool result);

    EnumerableSet.AddressSet private _set;

    function contains(address value) public view returns (bool) {
        return _set.contains(value);
    }

    function add(address value) public {
        // bool result = _set.add(value);
        // emit OperationResult(result);
    }

    function remove(address value) public {
        // bool result = _set.remove(value);
        // emit OperationResult(result);
    }

    function length() public view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) public view returns (address) {
        return _set.at(index);
    }
}

// UintSet
contract EnumerableUintSetMock {
    using EnumerableSet for EnumerableSet.UintSet;

    event OperationResult(bool result);

    EnumerableSet.UintSet private _set;

    function contains(uint256 value) public view returns (bool) {
        return _set.contains(value);
    }

    function add(uint256 value) public {
        // bool result = _set.add(value);
        // emit OperationResult(result);
    }

    function remove(uint256 value) public {
        // bool result = _set.remove(value);
        // emit OperationResult(result);
    }

    function length() public view returns (uint256) {
        return _set.length();
    }

    function at(uint256 index) public view returns (uint256) {
        return _set.at(index);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
        // emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        // emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        // emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/*
    This lottery uses a random number from the future to determine ticket placement for winnings.
    
    When the lotter is stopped, it means that the seed will come from the next block's hash which
    is a value that no one can predict.

    We then use that seed to generate a random lucky number for each ticket.

    By ording the tickets based on their lucky number, we are able to determine what position
    each ticket finished.

    This implementation is the most fair and efficient form of lottery smart contract.
*/

contract Lotto is Ownable {
    
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeMath for uint256;

  enum Status { NOT_INITIALIZED, PENDING, RUNNING, FINISHED }

//   event StatusChanged(Status status);
  event TicketSold(address playerAddress, uint256 ticketId);
//   event Payment(address to, uint256 value);
  
  mapping(uint256=>address) public ticketOwnerAddress;
  
  Status public status;
  
  uint256 public totalTicketsSold;
  uint256 public maxTickets;
  uint256 public ticketPrice;
  uint256 public rakePer100k;
  uint256 public seedBlockNumber;

  function setStatus(Status value) internal {
    if(value != status) {
      status = value;
    //   emit StatusChanged(status);
    }
  }

  function start() public onlyOwner {
    require(status == Status.PENDING);
    setStatus(Status.RUNNING);
  }

  function init(uint256 _maxTickets, uint256 _ticketPrice, uint256 _rakePer100k, bool autoStart) public onlyOwner {
    maxTickets = _maxTickets;
    ticketPrice = _ticketPrice;
    rakePer100k = _rakePer100k;
    totalTicketsSold = 0;
    setStatus(Status.PENDING);
    if(autoStart) start();
  }
    

  /*
  constructor(uint256 _maxTickets, uint256 _ticketPrice, uint256 _rakePer100k, bool autoStart) {
    init(_maxTickets, _ticketPrice, _rakePer100k, autoStart);
  }
  */
  
  constructor() public {
    init(200, 0.1 ether, 12000, true);
  }

  receive() external payable {
    require(status == Status.RUNNING, "not running");
    require(msg.value == ticketPrice, "invalid ticket price");
    require(totalTicketsSold < maxTickets, "all tickets sold");
    ticketOwnerAddress[totalTicketsSold] = msg.sender;
    ++totalTicketsSold;
    emit TicketSold(msg.sender, totalTicketsSold);
  }

  function stop() external onlyOwner {
    require(status == Status.RUNNING, "not running");
    setStatus(Status.FINISHED);
    seedBlockNumber = block.number + 1;
  }

  function pay(address payable to, uint256 value) external onlyOwner {
    require(status == Status.FINISHED);
    to.transfer(value);
    // emit Payment(to, value);
  }

  function getPot() public view returns (uint256) {
    return ticketPrice * totalTicketsSold;
  }

  function getRake() public view returns (uint256) {
    return getPot() * rakePer100k / 100000;
  }

  function getTotalPrizes() public view returns (uint256) {
    return getPot() - getRake();
  }
  
  function getLuckyNumbers(bytes32 seedBlockHash) public view returns(uint256[] memory luckyNumbers) {
    require(status == Status.FINISHED, "not finished");
    require(seedBlockNumber < block.number, "wait one more block");
    luckyNumbers = new uint256[](totalTicketsSold);
    for(uint256 i = 0; i < totalTicketsSold; ++i) {
      luckyNumbers[i] = uint256(seedBlockHash);
      seedBlockHash = keccak256(abi.encodePacked(seedBlockHash));
    }
  }
}