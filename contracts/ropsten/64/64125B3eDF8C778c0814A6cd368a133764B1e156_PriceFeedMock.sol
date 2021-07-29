// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Balance.sol";

abstract contract Automate is Ownable, Pausable {
  /// @notice Balance contract address.
  Balance public balance;

  constructor(address _balance) {
    balance = Balance(_balance);
  }

  /**
   * @dev Claim fees from owner.
   * @param gasFee Claim gas fee.
   * @param protocolFee Claim protocol fee.
   * @param operation Claim description.
   */
  function _bill(
    uint256 gasFee,
    uint256 protocolFee,
    string memory operation
  ) internal whenNotPaused returns (uint256) {
    return balance.claim(owner(), gasFee, protocolFee, operation);
  }

  /**
   * @notice Pause bill maker.
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause bill maker.
   */
  function unpause() external onlyOwner {
    _unpause();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Balance is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice Maximum consumer count.
  uint256 public constant MAXIMUM_CONSUMER_COUNT = 10;

  /// @notice Maximum accept or reject claims by one call.
  uint256 public constant MAXIMUM_CLAIM_PACKAGE = 10;

  /// @notice Treasury contract
  address payable public treasury;

  /// @notice Oracle accepting and rejecting claims
  address public inspector;

  /// @dev Consumers list.
  EnumerableSet.AddressSet internal _consumers;

  /// @notice Account balance.
  mapping(address => uint256) public balanceOf;

  /// @notice Account claim.
  mapping(address => uint256) public claimOf;

  /// @notice Possible statuses that a bill may be in.
  enum BillStatus {
    Pending,
    Accepted,
    Rejected
  }

  struct Bill {
    // Identificator.
    uint256 id;
    // Claimant.
    address claimant;
    // Target account.
    address account;
    // Claim gas fee.
    uint256 gasFee;
    // Claim protocol fee.
    uint256 protocolFee;
    // Current bill status.
    BillStatus status;
  }

  /// @notice Bills.
  mapping(uint256 => Bill) public bills;

  /// @notice Bill count.
  uint256 public billCount;

  event TreasuryChanged(address indexed treasury);

  event InspectorChanged(address indexed inspector);

  event ConsumerAdded(address indexed consumer);

  event ConsumerRemoved(address indexed consumer);

  event Deposit(address indexed recipient, uint256 amount);

  event Refund(address indexed recipient, uint256 amount);

  event Claim(address indexed account, uint256 indexed bill, string description);

  event AcceptClaim(uint256 indexed bill);

  event RejectClaim(uint256 indexed bill);

  constructor(address payable _treasury, address _inspector) {
    treasury = _treasury;
    inspector = _inspector;
  }

  modifier onlyInspector() {
    require(inspector == _msgSender(), "Balance: caller is not the inspector");
    _;
  }

  /**
   * @notice Change treasury contract address.
   * @param _treasury New treasury contract address.
   */
  function changeTreasury(address payable _treasury) external onlyOwner {
    treasury = _treasury;
    emit TreasuryChanged(treasury);
  }

  /**
   * @notice Change inspector oracle address.
   * @param _inspector New inspector oracle address.
   */
  function changeInspector(address _inspector) external onlyOwner {
    inspector = _inspector;
    emit InspectorChanged(inspector);
  }

  /**
   * @notice Add consumer.
   * @param consumer Added consumer.
   */
  function addConsumer(address consumer) external onlyOwner {
    require(!_consumers.contains(consumer), "Balance::addConsumer: consumer already added");
    require(
      _consumers.length() < MAXIMUM_CONSUMER_COUNT,
      "Balance::addConsumer: consumer must not exceed maximum count"
    );

    _consumers.add(consumer);

    emit ConsumerAdded(consumer);
  }

  /**
   * @notice Remove consumer.
   * @param consumer Removed consumer.
   */
  function removeConsumer(address consumer) external onlyOwner {
    require(_consumers.contains(consumer), "Balance::addConsumer: consumer already removed");

    _consumers.remove(consumer);

    emit ConsumerRemoved(consumer);
  }

  /**
   * @notice Get all consumers.
   * @return All consumers addresses.
   */
  function consumers() external view returns (address[] memory) {
    address[] memory result = new address[](_consumers.length());

    for (uint256 i = 0; i < _consumers.length(); i++) {
      result[i] = _consumers.at(i);
    }

    return result;
  }

  /**
   * @notice Get net balance of account.
   * @param account Target account.
   * @return Net balance (balance minus claim).
   */
  function netBalanceOf(address account) public view returns (uint256) {
    return balanceOf[account] - claimOf[account];
  }

  /**
   * @notice Deposit ETH to balance.
   * @param recipient Target recipient.
   */
  function deposit(address recipient) external payable {
    require(recipient != address(0), "Balance::deposit: invalid recipient");
    require(msg.value > 0, "Balance::deposit: negative or zero deposit");

    balanceOf[recipient] += msg.value;

    emit Deposit(recipient, msg.value);
  }

  /**
   * @notice Refund ETH from balance.
   * @param amount Refunded amount.
   */
  function refund(uint256 amount) external {
    address payable recipient = payable(_msgSender());
    require(amount > 0, "Balance::refund: negative or zero refund");
    require(amount <= netBalanceOf(recipient), "Balance::refund: refund amount exceeds net balance");

    balanceOf[recipient] -= amount;
    recipient.transfer(amount);

    emit Refund(recipient, amount);
  }

  /**
   * @notice Send claim.
   * @param account Target account.
   * @param gasFee Claim gas fee.
   * @param protocolFee Claim protocol fee.
   * @param description Claim description.
   */
  function claim(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external returns (uint256) {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == account || _consumers.contains(tx.origin),
      "Balance: caller is not a consumer"
    );

    uint256 amount = gasFee + protocolFee;
    require(amount > 0, "Balance::claim: negative or zero claim");
    require(amount <= netBalanceOf(account), "Balance::claim: claim amount exceeds net balance");

    claimOf[account] += amount;
    billCount++;
    bills[billCount] = Bill(billCount, _msgSender(), account, gasFee, protocolFee, BillStatus.Pending);
    emit Claim(account, billCount, description);

    return billCount;
  }

  /**
   * @notice Accept bills package.
   * @param _bills Target bills.
   * @param gasFees Confirmed claims gas fees by bills.
   * @param protocolFees Confirmed claims protocol fees by bills.
   */
  function acceptClaims(
    uint256[] memory _bills,
    uint256[] memory gasFees,
    uint256[] memory protocolFees
  ) external onlyInspector {
    require(
      _bills.length == gasFees.length && _bills.length == protocolFees.length,
      "Balance::acceptClaims: arity mismatch"
    );
    require(_bills.length < MAXIMUM_CLAIM_PACKAGE, "Balance::acceptClaims: too many claims");

    uint256 transferredAmount;
    for (uint256 i = 0; i < _bills.length; i++) {
      uint256 billId = _bills[i];
      require(billId > 0 && billId <= billCount, "Balance::acceptClaims: bill not found");

      uint256 gasFee = gasFees[i];
      uint256 protocolFee = protocolFees[i];
      uint256 amount = gasFee + protocolFee;

      Bill storage bill = bills[billId];
      uint256 claimAmount = bill.gasFee + bill.protocolFee;
      require(bill.status == BillStatus.Pending, "Balance::acceptClaims: bill already processed");
      require(amount <= claimAmount, "Balance::acceptClaims: claim amount exceeds max fee");

      bill.status = BillStatus.Accepted;
      bill.gasFee = gasFee;
      bill.protocolFee = protocolFee;
      claimOf[bill.account] -= claimAmount;
      balanceOf[bill.account] -= amount;
      transferredAmount += amount;

      emit AcceptClaim(bill.id);
    }
    treasury.transfer(transferredAmount);
  }

  /**
   * @notice Reject bills package.
   * @param _bills Target bills.
   */
  function rejectClaims(uint256[] memory _bills) external onlyInspector {
    require(_bills.length < MAXIMUM_CLAIM_PACKAGE, "Balance::rejectClaims: too many claims");

    for (uint256 i = 0; i < _bills.length; i++) {
      uint256 billId = _bills[i];
      require(billId > 0 && billId <= billCount, "Balance::rejectClaims: bill not found");

      Bill storage bill = bills[billId];
      require(bill.status == BillStatus.Pending, "Balance::rejectClaims: bill already processed");
      uint256 amount = bill.gasFee + bill.protocolFee;

      bill.status = BillStatus.Rejected;
      claimOf[bill.account] -= amount;

      emit RejectClaim(bill.id);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../Automate.sol";

contract AutomateMock is Automate {
  uint256 public protocolFee;

  constructor(address _balance, uint256 _protocolFee) Automate(_balance) {
    protocolFee = _protocolFee;
  }

  function sum(
    uint256 gasFee,
    uint256 x,
    uint256 y
  ) external returns (uint256) {
    _bill(gasFee, protocolFee, "AutomateMock.sum");

    return x + y;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./Balance.sol";

contract Store is Ownable, Pausable {
  /// @notice Balance contract address.
  Balance public balance;

  /// @notice Price feed oracle.
  AggregatorV3Interface public priceFeed;

  /// @notice Products.
  mapping(uint8 => uint256) public products;

  event ProductChanged(uint8 indexed product, uint256 priceUSD);

  event PriceFeedChanged(address indexed priceFeed);

  event Buy(uint8 indexed product, address indexed recipient);

  constructor(address _balance, address _priceFeed) {
    balance = Balance(_balance);
    priceFeed = AggregatorV3Interface(_priceFeed);
  }

  /**
   * @notice Change price feed oracle address.
   * @param _priceFeed New price feed oracle address.
   */
  function changePriceFeed(address _priceFeed) external onlyOwner {
    priceFeed = AggregatorV3Interface(_priceFeed);
    emit PriceFeedChanged(_priceFeed);
  }

  /**
   * @notice Update product price.
   * @param id Product identificator.
   * @param priceUSD Product price in USD with price feed oracle decimals (zero if product is not for sale).
   */
  function changeProduct(uint8 id, uint256 priceUSD) external onlyOwner {
    products[id] = priceUSD;
    emit ProductChanged(id, priceUSD);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Get current product price.
   * @param product Target product.
   * @return Product price in ETH.
   */
  function price(uint8 product) public view returns (uint256) {
    (, int256 answer, , , ) = priceFeed.latestRoundData();
    require(answer > 0, "Store: invalid price");

    return (products[product] * 1e18) / uint256(answer);
  }

  /**
   * @notice Buy product.
   * @param product Target product.
   * @param recipient Product recipient.
   * @param priceMax Maximum price.
   * @param deadline Timestamp of deadline.
   */
  function buy(
    uint8 product,
    address recipient,
    uint256 priceMax,
    uint256 deadline
  ) external payable whenNotPaused {
    // solhint-disable-next-line not-rely-on-time
    require(deadline >= block.timestamp, "Store: expired");
    uint256 currentPrice = price(product);
    require(currentPrice > 0, "Store: negative or zero price");
    require(currentPrice <= priceMax, "Store: excessive price");

    balance.claim(_msgSender(), 0, currentPrice, "STORE_BUY");
    emit Buy(product, recipient);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceFeedMock is AggregatorV3Interface, Ownable {
  uint8 public override decimals;

  string public override description;

  uint256 public override version;

  struct Round {
    uint80 roundId;
    int256 answer;
    uint256 startedAt;
    uint256 updatedAt;
    uint80 answeredInRound;
  }

  mapping(uint80 => Round) internal _rounds;

  uint80 public latestRound;

  constructor(
    uint8 _decimals,
    string memory _description,
    uint256 _version
  ) {
    decimals = _decimals;
    description = _description;
    version = _version;
  }

  function addRoundData(int256 answer) external onlyOwner {
    latestRound++;
    // solhint-disable-next-line not-rely-on-time
    _rounds[latestRound] = Round(latestRound, answer, block.timestamp, block.timestamp, latestRound);
  }

  function getRoundData(uint80 _roundId)
    public
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    Round storage round = _rounds[_roundId];

    return (round.roundId, round.answer, round.startedAt, round.updatedAt, round.answeredInRound);
  }

  function latestRoundData()
    external
    view
    override
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return getRoundData(latestRound);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Treasury is Ownable {
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Transfer token to recipient.
   * @param token Target token.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transfer(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    require(amount > 0, "Treasury::transfer: negative or zero amount");
    require(recipient != address(0), "Treasury::transfer: invalid recipient");
    token.transfer(recipient, amount);
  }

  /**
   * @notice Transfer ETH to recipient.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transferETH(address payable recipient, uint256 amount) external onlyOwner {
    require(amount > 0, "Treasury::transferETH: negative or zero amount");
    require(recipient != address(0), "Treasury::transferETH: invalid recipient");
    recipient.transfer(amount);
  }

  /**
   * @notice Approve token to recipient.
   * @param token Target token.
   * @param recipient Recipient.
   * @param amount Approve amount.
   */
  function approve(
    IERC20 token,
    address recipient,
    uint256 amount
  ) external onlyOwner {
    uint256 allowance = token.allowance(address(this), recipient);
    if (allowance > 0) {
      token.approve(recipient, 0);
    }
    token.approve(recipient, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
  constructor(
    string memory name,
    string memory symbol,
    uint256 initialSupply
  ) ERC20(name, symbol) {
    _mint(_msgSender(), initialSupply);
  }

  function mint(address account, uint256 amount) external {
    _mint(account, amount);
  }

  function burn(address account, uint256 amount) external {
    _burn(account, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";

// solhint-disable const-name-snakecase
// solhint-disable private-vars-leading-underscore
contract GovernanceToken is Ownable {
  /// @notice EIP-20 token name for this token
  string public constant name = "DeFiHelper token";

  /// @notice EIP-20 token symbol for this token
  string public constant symbol = "DFH";

  /// @notice EIP-20 token decimals for this token
  uint8 public constant decimals = 18;

  /// @notice Total number of tokens in circulation
  uint256 public totalSupply = 1_000_000_000e18; // 1 billion GovernanceToken

  /// @notice Allowance amounts on behalf of others
  mapping(address => mapping(address => uint96)) internal allowances;

  /// @notice Official record of token balances for each account
  mapping(address => uint96) internal balances;

  /// @notice A record of each accounts delegate
  mapping(address => address) public delegates;

  /// @notice A checkpoint for marking number of votes from a given block
  struct Checkpoint {
    uint32 fromBlock;
    uint96 votes;
  }

  /// @notice A record of votes checkpoints for each account, by index
  mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

  /// @notice The number of checkpoints for each account
  mapping(address => uint32) public numCheckpoints;

  /// @notice The EIP-712 typehash for the contract's domain
  bytes32 public constant DOMAIN_TYPEHASH =
    keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

  /// @notice The EIP-712 typehash for the delegation struct used by the contract
  bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

  /// @notice A record of states for signing / validating signatures
  mapping(address => uint256) public nonces;

  /// @notice An event thats emitted when an account changes its delegate
  event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

  /// @notice An event thats emitted when a delegate account's vote balance changes
  event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

  /// @notice The standard EIP-20 transfer event
  event Transfer(address indexed from, address indexed to, uint256 amount);

  /// @notice The standard EIP-20 approval event
  event Approval(address indexed owner, address indexed spender, uint256 amount);

  /**
   * @notice Construct a new GovernanceToken token
   * @param account The initial account to grant all the tokens
   */
  constructor(address account) {
    balances[account] = uint96(totalSupply);
    emit Transfer(address(0), account, totalSupply);
  }

  /**
   * @notice Creates `amount` tokens and assigns them to `account`, increasing
   * the total supply.
   *
   * @param account Recipient of created token.
   * @param amount Amount of token to be created.
   */
  function mint(address account, uint256 amount) public onlyOwner {
    _mint(account, amount);
  }

  /**
   * @param account Owner of removed token.
   * @param amount Amount of token to be removed.
   */
  function burn(address account, uint256 amount) public onlyOwner {
    _burn(account, amount);
  }

  /**
   * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
   * @param account The address of the account holding the funds
   * @param spender The address of the account spending the funds
   * @return The number of tokens approved
   */
  function allowance(address account, address spender) external view returns (uint256) {
    return allowances[account][spender];
  }

  /**
   * @notice Approve `spender` to transfer up to `amount` from `src`
   * @dev This will overwrite the approval amount for `spender`
   *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
   * @param spender The address of the account which may transfer tokens
   * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
   * @return Whether or not the approval succeeded
   */
  function approve(address spender, uint256 rawAmount) external returns (bool) {
    uint96 amount;
    if (rawAmount == 2**256 - 1) {
      amount = 2**96 - 1;
    } else {
      amount = safe96(rawAmount, "GovernanceToken::approve: amount exceeds 96 bits");
    }

    allowances[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Get the number of tokens held by the `account`
   * @param account The address of the account to get the balance of
   * @return The number of tokens held
   */
  function balanceOf(address account) external view returns (uint256) {
    return balances[account];
  }

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transfer(address dst, uint256 rawAmount) external returns (bool) {
    uint96 amount = safe96(rawAmount, "GovernanceToken::transfer: amount exceeds 96 bits");
    _transferTokens(msg.sender, dst, amount);
    return true;
  }

  /**
   * @notice Transfer `amount` tokens from `src` to `dst`
   * @param src The address of the source account
   * @param dst The address of the destination account
   * @param rawAmount The number of tokens to transfer
   * @return Whether or not the transfer succeeded
   */
  function transferFrom(
    address src,
    address dst,
    uint256 rawAmount
  ) external returns (bool) {
    address spender = msg.sender;
    uint96 spenderAllowance = allowances[src][spender];
    uint96 amount = safe96(rawAmount, "GovernanceToken::approve: amount exceeds 96 bits");

    if (spender != src && spenderAllowance != 2**96 - 1) {
      uint96 newAllowance = sub96(
        spenderAllowance,
        amount,
        "GovernanceToken::transferFrom: transfer amount exceeds spender allowance"
      );
      allowances[src][spender] = newAllowance;

      emit Approval(src, spender, newAllowance);
    }

    _transferTokens(src, dst, amount);
    return true;
  }

  /**
   * @notice Delegate votes from `msg.sender` to `delegatee`
   * @param delegatee The address to delegate votes to
   */
  function delegate(address delegatee) public {
    return _delegate(msg.sender, delegatee);
  }

  /**
   * @notice Delegates votes from signatory to `delegatee`
   * @param delegatee The address to delegate votes to
   * @param nonce The contract state required to match the signature
   * @param expiry The time at which to expire the signature
   * @param v The recovery byte of the signature
   * @param r Half of the ECDSA signature pair
   * @param s Half of the ECDSA signature pair
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    bytes32 domainSeparator = keccak256(
      abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this))
    );
    bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    address signatory = ecrecover(digest, v, r, s);
    require(signatory != address(0), "GovernanceToken::delegateBySig: invalid signature");
    require(nonce == nonces[signatory]++, "GovernanceToken::delegateBySig: invalid nonce");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp <= expiry, "GovernanceToken::delegateBySig: signature expired");
    return _delegate(signatory, delegatee);
  }

  /**
   * @notice Gets the current votes balance for `account`
   * @param account The address to get votes balance
   * @return The number of current votes for `account`
   */
  function getCurrentVotes(address account) external view returns (uint96) {
    uint32 nCheckpoints = numCheckpoints[account];
    return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
  }

  /**
   * @notice Determine the prior number of votes for an account as of a block number
   * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
   * @param account The address of the account to check
   * @param blockNumber The block number to get the vote balance at
   * @return The number of votes the account had as of the given block
   */
  function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
    require(blockNumber < block.number, "GovernanceToken::getPriorVotes: not yet determined");

    uint32 nCheckpoints = numCheckpoints[account];
    if (nCheckpoints == 0) {
      return 0;
    }

    // First check most recent balance
    if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
      return checkpoints[account][nCheckpoints - 1].votes;
    }

    // Next check implicit zero balance
    if (checkpoints[account][0].fromBlock > blockNumber) {
      return 0;
    }

    uint32 lower = 0;
    uint32 upper = nCheckpoints - 1;
    while (upper > lower) {
      uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
      Checkpoint memory cp = checkpoints[account][center];
      if (cp.fromBlock == blockNumber) {
        return cp.votes;
      } else if (cp.fromBlock < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return checkpoints[account][lower].votes;
  }

  function _delegate(address delegator, address delegatee) internal {
    address currentDelegate = delegates[delegator];
    uint96 delegatorBalance = balances[delegator];
    delegates[delegator] = delegatee;

    emit DelegateChanged(delegator, currentDelegate, delegatee);

    _moveDelegates(currentDelegate, delegatee, delegatorBalance);
  }

  function _transferTokens(
    address src,
    address dst,
    uint96 amount
  ) internal {
    require(src != address(0), "GovernanceToken::_transferTokens: cannot transfer from the zero address");
    require(dst != address(0), "GovernanceToken::_transferTokens: cannot transfer to the zero address");

    balances[src] = sub96(balances[src], amount, "GovernanceToken::_transferTokens: transfer amount exceeds balance");
    balances[dst] = add96(balances[dst], amount, "GovernanceToken::_transferTokens: transfer amount overflows");
    emit Transfer(src, dst, amount);

    _moveDelegates(delegates[src], delegates[dst], amount);
  }

  function _moveDelegates(
    address srcRep,
    address dstRep,
    uint96 amount
  ) internal {
    if (srcRep != dstRep && amount > 0) {
      if (srcRep != address(0)) {
        uint32 srcRepNum = numCheckpoints[srcRep];
        uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
        uint96 srcRepNew = sub96(srcRepOld, amount, "GovernanceToken::_moveVotes: vote amount underflows");
        _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
      }

      if (dstRep != address(0)) {
        uint32 dstRepNum = numCheckpoints[dstRep];
        uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
        uint96 dstRepNew = add96(dstRepOld, amount, "GovernanceToken::_moveVotes: vote amount overflows");
        _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
      }
    }
  }

  function _writeCheckpoint(
    address delegatee,
    uint32 nCheckpoints,
    uint96 oldVotes,
    uint96 newVotes
  ) internal {
    uint32 blockNumber = safe32(block.number, "GovernanceToken::_writeCheckpoint: block number exceeds 32 bits");

    if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
      checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
    } else {
      checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
      numCheckpoints[delegatee] = nCheckpoints + 1;
    }

    emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
  }

  /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.

     * Requirements
     *
     * - `account` cannot be the zero address.
     */
  function _mint(address account, uint256 rawAmount) internal virtual {
    require(account != address(0), "GovernanceToken::_mint: mint to the zero address");
    uint96 amount = safe96(rawAmount, "GovernanceToken::_mint: amount exceeds 96 bits");

    totalSupply += amount;
    balances[account] = add96(balances[account], amount, "GovernanceToken::_mint: mint amount overflows");
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Destroys `amount` tokens from `account`, reducing the
   * total supply.
   *
   * Emits a {Transfer} event with `to` set to the zero address.
   *
   * Requirements
   *
   * - `account` cannot be the zero address.
   * - `account` must have at least `amount` tokens.
   */
  function _burn(address account, uint256 rawAmount) internal virtual {
    require(account != address(0), "GovernanceToken::_burn: burn from the zero address");
    uint96 amount = safe96(rawAmount, "GovernanceToken::_burn: amount exceeds 96 bits");

    balances[account] = sub96(balances[account], amount, "GovernanceToken::_burn: burn amount exceeds balance");
    totalSupply += amount;
    emit Transfer(account, address(0), amount);
  }

  function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
    require(n < 2**32, errorMessage);
    return uint32(n);
  }

  function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
    require(n < 2**96, errorMessage);
    return uint96(n);
  }

  function add96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    uint96 c = a + b;
    require(c >= a, errorMessage);
    return c;
  }

  function sub96(
    uint96 a,
    uint96 b,
    string memory errorMessage
  ) internal pure returns (uint96) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function getChainId() internal view returns (uint256) {
    uint256 chainId;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId := chainid()
    }
    return chainId;
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract Budget is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @notice Maximum recipient count.
  uint256 public constant MAXIMUM_RECIPIENT_COUNT = 10;

  struct Expenditure {
    // Recipient address.
    address recipient;
    // Minimum balance at which budget allocation is performed.
    uint256 min;
    // Target balance at budget allocation.
    uint256 target;
  }

  /// @notice Expenditure item to address.
  mapping(address => Expenditure) public expenditures;

  /// @dev Recipients addresses list.
  EnumerableSet.AddressSet internal _recipients;

  /// @dev Withdrawal balance of recipients.
  mapping(address => uint256) public balanceOf;

  /// @notice Total withdrawal balance.
  uint256 public totalSupply;

  event ExpenditureChanged(address indexed recipient, uint256 min, uint256 target);

  event Withdrawal(address indexed recipient, uint256 amount);

  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}

  /**
   * @notice Change expenditure item.
   * @param recipient Recipient address.
   * @param min Minimal balance for payment.
   * @param target Target balance.
   */
  function changeExpenditure(
    address recipient,
    uint256 min,
    uint256 target
  ) external onlyOwner {
    require(min <= target, "Budget::changeExpenditure: minimal balance should be less or equal target balance");
    require(recipient != address(0), "Budget::changeExpenditure: invalid recipient");

    expenditures[recipient] = Expenditure(recipient, min, target);
    if (target > 0) {
      _recipients.add(recipient);
      require(
        _recipients.length() <= MAXIMUM_RECIPIENT_COUNT,
        "Budget::changeExpenditure: recipient must not exceed maximum count"
      );
    } else {
      totalSupply -= balanceOf[recipient];
      balanceOf[recipient] = 0;
      _recipients.remove(recipient);
    }
    emit ExpenditureChanged(recipient, min, target);
  }

  /**
   * @notice Transfer ETH to recipient.
   * @param recipient Recipient.
   * @param amount Transfer amount.
   */
  function transferETH(address payable recipient, uint256 amount) external onlyOwner {
    require(amount > 0, "Budget::transferETH: negative or zero amount");
    require(recipient != address(0), "Budget::transferETH: invalid recipient");
    require(amount <= address(this).balance - totalSupply, "Budget::transferETH: transfer amount exceeds balance");

    recipient.transfer(amount);
  }

  /**
   * @notice Return all recipients addresses.
   * @return Recipients addresses.
   */
  function recipients() external view returns (address[] memory) {
    address[] memory result = new address[](_recipients.length());

    for (uint256 i = 0; i < _recipients.length(); i++) {
      result[i] = _recipients.at(i);
    }

    return result;
  }

  /**
   * @notice Return balance deficit of recipient.
   * @param recipient Target recipient.
   * @return Balance deficit of recipient.
   */
  function deficitTo(address recipient) public view returns (uint256) {
    require(_recipients.contains(recipient), "Budget::deficitTo: recipient not in expenditure item");

    uint256 availableBalance = recipient.balance + balanceOf[recipient];
    if (availableBalance >= expenditures[recipient].min) return 0;

    return expenditures[recipient].target - availableBalance;
  }

  /**
   * @notice Return summary balance deficit of all recipients.
   * @return Summary balance deficit of all recipients.
   */
  function deficit() public view returns (uint256) {
    uint256 result;

    for (uint256 i = 0; i < _recipients.length(); i++) {
      result += deficitTo(_recipients.at(i));
    }

    return result;
  }

  /**
   * @notice Pay ETH to all recipients with balance deficit.
   */
  function pay() external {
    for (uint256 i = 0; i < _recipients.length(); i++) {
      uint256 budgetBalance = address(this).balance - totalSupply;
      address recipient = _recipients.at(i);
      uint256 amount = deficitTo(recipient);
      if (amount == 0 || budgetBalance < amount) continue;

      balanceOf[recipient] += amount;
      totalSupply += amount;
    }
  }

  /**
   * @notice Withdraw ETH to recipient.
   */
  function withdraw() external {
    address payable recipient = payable(_msgSender());
    uint256 amount = balanceOf[recipient];
    require(amount > 0, "Budget::withdraw: transfer amount exceeds balance");

    balanceOf[recipient] = 0;
    totalSupply -= amount;
    recipient.transfer(amount);
    emit Withdrawal(recipient, amount);
  }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.6;

import "../Balance.sol";

contract BalanceConsumerMock {
  Balance public balance;

  constructor(address _balance) {
    balance = Balance(_balance);
  }

  function consume(
    address account,
    uint256 gasFee,
    uint256 protocolFee,
    string memory description
  ) external {
    balance.claim(account, gasFee, protocolFee, description);
  }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  }
}