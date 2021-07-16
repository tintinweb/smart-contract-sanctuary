//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

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


//SourceUnit: EnumerableSet.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

//SourceUnit: ITRC20.sol

pragma solidity 0.6.0;

interface ITRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

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
    function decimals() external view returns (uint8);

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

//SourceUnit: MultistageSwap.sol

pragma solidity 0.6.0;

import "./Ownable.sol";
import "./StructuredLinkedList.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./ITRC20.sol";
import "./TokenInfo.sol";

pragma experimental ABIEncoderV2;

contract MultistageSwap is Ownable, TokenInfo {

  using StructuredLinkedList for StructuredLinkedList.List;
  using EnumerableSet for EnumerableSet.AddressSet;
  using SafeMath for uint;

  struct Package {
    uint16 id;
    uint8 count;
    uint8 left;
    uint64 tokenPrice;
    uint64 trxPrice;
    uint64 payout;
    uint8 payoutInTokens;
    uint8 last;
  }

  struct Payout {
    uint216 amount;
    uint32 frozenUntil;
    uint8 inTokens;
  }

  struct PayoutStats {
    uint128 completed;
    uint128 total;
  }

  StructuredLinkedList.List private _packageIdList;

  uint private _lastPackageId;
  // uint private _lastPayoutId;

  bool private _isStarted;

  mapping(uint => Package) _packages;
  // mapping(address => StructuredLinkedList.List) _userPayoutIds;
  // mapping(uint => Payout) _payouts;
  mapping(address => mapping(uint => Payout)) _payouts;
  mapping(address => PayoutStats) _stats;
  // EnumerableSet.AddressSet private _users;

  address private _tokenAddress;

  uint private _trxFreezeTime;
  uint private _tokenFreezeTime;

  int private _trxBalance;
  int private _tokenBalance;

  constructor(address token, uint trxFreezeTime, uint tokenFreezeTime) public {
    _tokenAddress = token;
    _isStarted = false;

    // _trxFreezeTime = trxFreezeTime;
    // _tokenFreezeTime = tokenFreezeTime;

    setFreezeTime(trxFreezeTime, tokenFreezeTime);

    // addPackage( 64,  400*10**6, 120*10**6,  520*10**6, false );
    // addPackage( 32,  500*10**6, 150*10**6,  650*10**6, true  );
    // addPackage( 16,  600*10**6, 180*10**6,  780*10**6, false );
    // addPackage(  8,  700*10**6, 210*10**6,  910*10**6, true  );
    addPackage(  4,  800*10**6, 240*10**6, 1040*10**6, false );
    addPackage(  2,  900*10**6, 270*10**6, 1170*10**6, true  );
    addPackage(  1, 1000*10**6, 300*10**6, 1300*10**6, false );

  }

  modifier onlyBetweenRounds() {
    require(!_isStarted, "You can modify packages only between rounds");
    _;
  }

  event NewRound(bool started);

  function start() public onlyOwner {
    (, uint id) = _packageIdList.getNextNode(0);
    while(id != 0) {
      _packages[id].left = _packages[id].count;
      (, uint next_id) = _packageIdList.getNextNode(id);
      _packages[id].last = (next_id == 0) ? 1 : 0;
      id = next_id;
    }
    _isStarted = true;
    emit NewRound(true);
  }

  event PackageAdded(uint id, uint count, uint trxPrice, uint tokenPrice, uint payout, bool payoutInTokens);

  function addPackage(uint count, uint trxPrice, uint tokenPrice, uint payout, bool payoutInTokens) public onlyOwner onlyBetweenRounds {
    require(tokenPrice > 0, "tokenPrice should be positive");
    require(trxPrice > 0, "trxPrice should be positive");
    require(payout > 0, "trxPrice should be positive");
    _lastPackageId++;
    _packages[_lastPackageId] = Package(
      uint16(_lastPackageId),
      uint8(count),
      0,
      uint64(tokenPrice),
      uint64(trxPrice),
      uint64(payout),
      payoutInTokens ? 1 : 0,
      0
    );
    _packageIdList.pushBack(_lastPackageId);
    emit PackageAdded(_lastPackageId, count, trxPrice, tokenPrice, payout, payoutInTokens);
  }

  event PackageRemoved(uint id);

  function removePackage(uint id) public onlyOwner onlyBetweenRounds {
    _packageIdList.remove(id);
    delete _packages[id];
    emit PackageRemoved(id);
  }

  event PackageChanged(uint id, uint count, uint trxPrice, uint tokenPrice, uint payout, bool payoutInTokens);

  function changePackage(uint id, uint8 count, uint64 trxPrice, uint64 tokenPrice, uint64 payout, bool payoutInTokens) public onlyOwner onlyBetweenRounds {
    require(_packages[id].id == id, "Package with specified id is not found");
    _packages[id].count = count;
    _packages[id].tokenPrice = tokenPrice;
    _packages[id].trxPrice = trxPrice;
    _packages[id].payout = payout;
    _packages[id].payoutInTokens = payoutInTokens ? 1 : 0;
    emit PackageChanged(id, count, trxPrice, tokenPrice, payout, payoutInTokens);
  }

  event FreezeTimeSet(uint trxFreezeTime, uint tokenFreezeTime);

  function setFreezeTime(uint trxFreezeTime, uint tokenFreezeTime) public onlyOwner onlyBetweenRounds {
    _trxFreezeTime = trxFreezeTime;
    _tokenFreezeTime = tokenFreezeTime;
    emit FreezeTimeSet(trxFreezeTime, tokenFreezeTime);
  }

  function freezeTime() public view returns (uint trxFreezeTime, uint tokenFreezeTime) {
    trxFreezeTime = _trxFreezeTime;
    tokenFreezeTime = _tokenFreezeTime;
  }

  function packageIds() public view returns (uint[] memory ids) {
    uint n = 0;
    (, uint id) = _packageIdList.getNextNode(0);
    while(id != 0) {
      n++;
      (, id) = _packageIdList.getNextNode(id);
    }
    ids = new uint[](n);
    n = 0;
    (, id) = _packageIdList.getNextNode(0);
    while(id != 0) {
      ids[n++] = id;
      (, id) = _packageIdList.getNextNode(id);
    }
  }

  function packages() public view returns (uint[8][] memory) {
    uint[] memory ids = packageIds();
    uint[8][] memory list = new uint[8][](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      list[i] = [
        uint256( _packages[ids[i]].id ),
        uint256( _packages[ids[i]].count ),
        uint256( _packages[ids[i]].left ),
        uint256( _packages[ids[i]].tokenPrice ),
        uint256( _packages[ids[i]].trxPrice ),
        uint256( _packages[ids[i]].payout ),
        uint256( _packages[ids[i]].payoutInTokens ),
        uint256( _packages[ids[i]].last )
      ];
    }
    return list;
  }

  function isStarted() public view returns (bool) { return _isStarted; }

  function currentPackageId() public view returns (uint) {
    (, uint id) = _packageIdList.getNextNode(0);
    while(id != 0) {
      if(_packages[id].left > 0) return _packages[id].id;
      (, id) = _packageIdList.getNextNode(id);
    }
    return 0; // Not found
  }

  function _countPayoutsFor(address user) private view returns(uint availableTrx, uint availableTokens, uint frozenTrx, uint frozenTokens) {
    availableTrx = 0; availableTokens = 0;
    frozenTrx = 0; frozenTokens = 0;
    uint t = block.timestamp;

    PayoutStats storage stats = _stats[user];
    for (uint256 i = stats.completed + 1; i <= stats.total; i++) {
      Payout storage p = _payouts[user][i];
      if(p.frozenUntil > t) {
        if(p.inTokens == 1)
          frozenTokens = frozenTokens.add(p.amount);
        else
          frozenTrx = frozenTrx.add(p.amount);
      } else {
        if(p.inTokens == 1)
          availableTokens = availableTokens.add(p.amount);
        else
          availableTrx = availableTrx.add(p.amount);
      }
    }
  }

  function _countAndDeleteAvailableTrxPayoutsFor(address user) private returns(uint availableTrx) {
    availableTrx = 0;
    uint t = block.timestamp;

    PayoutStats storage stats = _stats[user];
    for (uint256 i = stats.completed + 1; i <= stats.total; i++) {
      Payout storage p = _payouts[user][i];
      if(p.frozenUntil <= t) {
        if(p.inTokens == 0) {
          availableTrx = availableTrx.add(p.amount);
          p.amount = 0;
        }
      }
      if(p.amount == 0 && i == stats.completed + 1) {
        stats.completed++;
        delete _payouts[user][i];
      }
    }
  }

  function _countAndDeleteAvailableTokenPayoutsFor(address user) private returns(uint availableTokens) {
    availableTokens = 0;
    uint t = block.timestamp;

    PayoutStats storage stats = _stats[user];
    for (uint256 i = stats.completed + 1; i <= stats.total; i++) {
      Payout storage p = _payouts[user][i];
      if(p.frozenUntil <= t) {
        if(p.inTokens == 1) {
          availableTokens = availableTokens.add(p.amount);
          p.amount = 0;
        }
      }
      if(p.amount == 0 && i == stats.completed + 1) {
        stats.completed++;
        delete _payouts[user][i];
      }
    }
  }

  function availableFor(address user) public view returns (uint availableTrx, uint availableTokens) {
    uint frozenTrx; uint frozenTokens;
    (availableTrx, availableTokens, frozenTrx, frozenTokens) = _countPayoutsFor(user);
    (uint trxDebt, uint tokenDebt) = debts();
    if(trxDebt > 0) availableTrx = 0;
    if(tokenDebt > 0) availableTokens = 0;
  }

  function frozenFor(address user) public view returns (uint frozenTrx, uint frozenTokens) {
    uint availableTrx; uint availableTokens;
    (availableTrx, availableTokens, frozenTrx, frozenTokens) = _countPayoutsFor(user);
    (uint trxDebt, uint tokenDebt) = debts();
    if(trxDebt > 0) frozenTrx += availableTrx;
    if(tokenDebt > 0) frozenTokens += availableTokens;
  }

  function tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(ITRC20(_tokenAddress));}

  function availableToCollect() public view returns (uint availableTrx, uint availableTokens) {
    return _availableToCollect();
  }

  function debts() public view returns (uint trxDebt, uint tokenDebt) {
    return (
      (_trxBalance < 0 ? uint(-_trxBalance) : 0),
      (_tokenBalance < 0 ? uint(-_tokenBalance) : 0)
    );
  }

  event DebtPayed(uint trxAmount, uint tokenAmount);

  function payDebts() external payable {
    (uint trxDebt, uint tokenDebt) = debts();
    require(trxDebt > 0 || tokenDebt > 0, "No debts");
    require(msg.value == trxDebt, "Not enough trx to pay the debt");
    if(tokenDebt > 0) {
      ITRC20(_tokenAddress).transferFrom(msg.sender, address(this), tokenDebt);
      _tokenBalance = 0;
    }
    if(trxDebt > 0) {
      _trxBalance = 0;
    }
    emit DebtPayed(trxDebt, tokenDebt);

  }

  event Replenished(uint trxAmount, uint tokenAmount);

  function replenish(uint tokenAmount) external payable {
    uint trxAmount = msg.value;
    if(tokenAmount > 0) {
      ITRC20(_tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);
      _tokenBalance += int(tokenAmount);
    }
    if(trxAmount > 0) _trxBalance += int(trxAmount);
    emit Replenished(trxAmount, tokenAmount);
  }

  function _availableToCollect() private view returns (uint availableTrx, uint availableTokens) {
    return (
      _trxBalance > 0 ? uint(_trxBalance) : 0,
      _tokenBalance > 0 ? uint(_tokenBalance) : 0
    );
  }

  event TokensCollected(uint amount);
  event TrxCollected(uint amount);

  function collect() external onlyOwner {
    (uint trons, uint tokens) = _availableToCollect();
    require(trons > 0 || tokens > 0, "Nothing to collect");
    if(trons > 0) {
      payable(msg.sender).transfer(trons);
      _trxBalance -= int(trons);
      emit TrxCollected(trons);
    }
    if(tokens > 0) {
      ITRC20(_tokenAddress).transfer(msg.sender, tokens);
      _tokenBalance -= int(tokens);
      emit TokensCollected(tokens);
    }
  }

  event PackagePurchased(uint id, address user);
  event PayoutScheduled(uint amount, uint frozenUntil, bool inTokens, address user, uint trxPrice, uint tokenPrice);

  function buy() external payable {
    require(_isStarted, "New round is not started");
    Package storage p = _packages[currentPackageId()];
    require(p.id > 0, "Package not found");
    require(p.left > 0, "Contract is broken");
    ITRC20 token = ITRC20(_tokenAddress);
    require(msg.value == p.trxPrice, "Not enought trx");
    // require(token.allowance(msg.sender, address(this)) >= p.tokenPrice, "Not enough allowance for token");
    token.transferFrom(msg.sender, address(this), p.tokenPrice);

    uint frozenUntil = block.timestamp;
    int trxBalanceChange = int(p.trxPrice); // контракт получает TRX
    int tokenBalanceChange = int(p.tokenPrice); // контракт получает токены

    if (p.payoutInTokens == 1) {
      frozenUntil = frozenUntil.add(_tokenFreezeTime);
      tokenBalanceChange -= int(p.payout); // контракт обещает вернуть токены
    } else {
      frozenUntil = frozenUntil.add(_trxFreezeTime);
      trxBalanceChange -= int(p.payout); // контракт обещает вернуть TRX
    }

    if(trxBalanceChange != 0) _trxBalance += trxBalanceChange;
    if(tokenBalanceChange != 0) _tokenBalance += tokenBalanceChange;

    PayoutStats storage stats = _stats[msg.sender];

    _payouts[msg.sender][++stats.total] = Payout(p.payout, uint32(frozenUntil), p.payoutInTokens);


    emit PayoutScheduled(p.payout, frozenUntil, p.payoutInTokens == 1, msg.sender, p.trxPrice, p.tokenPrice);

    if(p.last == 1 && p.left == 1) {
      _isStarted = false;
    }

    _packages[p.id].left--;

    emit PackagePurchased(p.id, msg.sender);
  }

  event TrxWithdrawn(uint amount, address user);

  function getTrx() external {
    uint trons = _countAndDeleteAvailableTrxPayoutsFor(msg.sender);
    require(trons > 0, "No available trx");
    payable(msg.sender).transfer(trons);
    // _trxBalance -= int(trons);
    emit TrxWithdrawn(trons, msg.sender);
  }

  event TokensWithdrawn(uint amount, address user);

  function getTokens() external {
    uint tokens = _countAndDeleteAvailableTokenPayoutsFor(msg.sender);
    require(tokens > 0, "No available tokens");
    ITRC20(_tokenAddress).transfer(msg.sender, tokens);
    // _tokenBalance -= int(tokens);
    emit TokensWithdrawn(tokens, msg.sender);
  }

}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
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
    uint96 private _;

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


//SourceUnit: SafeMath.sol

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


//SourceUnit: StructuredLinkedList.sol

pragma solidity ^0.6.0;

interface  IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {

    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}

//SourceUnit: TokenInfo.sol

pragma solidity 0.6.0;

import "./ITRC20.sol";

contract TokenInfo {
  function _tokenInfo(ITRC20 token) internal view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) {
    name = token.name();
    symbol = token.symbol();
    decimals = token.decimals();
    tokenAddress = address(token);
  }
}