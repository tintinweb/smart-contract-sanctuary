/**
 *Submitted for verification at polygonscan.com on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
  function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x + y) >= x, "ds-math-add-overflow");
  }

  function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require((z = x - y) <= x, "ds-math-sub-underflow");
  }

  function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
    require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b > 0, "ds-math-division-by-zero");
    c = a / b;
  }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, "TransferHelper: ETH_TRANSFER_FAILED");
  }
}

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

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1;
      // All indexes are 1-based

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
    return _add(set._inner, bytes32(uint256(value)));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(value)));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(value)));
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
    return address(uint256(_at(set._inner, index)));
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

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}

interface ICappedMintableBurnableERC20 {
  function cap() external view returns (uint256);

  function minterCap(address) external view returns (uint256);

  function mint(address, uint256) external;

  function burn(uint256) external;
}

interface IFireBirdPair {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external pure returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);

  function DOMAIN_SEPARATOR() external view returns (bytes32);

  function PERMIT_TYPEHASH() external pure returns (bytes32);

  function nonces(address owner) external view returns (uint256);

  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
  event Mint(address indexed sender, uint256 amount0, uint256 amount1);
  event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
  event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
  event Sync(uint112 reserve0, uint112 reserve1);

  function MINIMUM_LIQUIDITY() external pure returns (uint256);

  function factory() external view returns (address);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

  function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

  function getSwapFee() external view returns (uint32);

  function price0CumulativeLast() external view returns (uint256);

  function price1CumulativeLast() external view returns (uint256);

  function mint(address to) external returns (uint256 liquidity);

  function burn(address to) external returns (uint256 amount0, uint256 amount1);

  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(address to) external;

  function sync() external;

  function initialize(
    address,
    address,
    uint32,
    uint32
  ) external;
}

interface IFireBirdFactory {
  event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

  function feeTo() external view returns (address);

  function formula() external view returns (address);

  function protocolFee() external view returns (uint256);

  function feeToSetter() external view returns (address);

  function getPair(
    address tokenA,
    address tokenB,
    uint32 tokenWeightA,
    uint32 swapFee
  ) external view returns (address pair);

  function allPairs(uint256) external view returns (address pair);

  function isPair(address) external view returns (bool);

  function allPairsLength() external view returns (uint256);

  function createPair(
    address tokenA,
    address tokenB,
    uint32 tokenWeightA,
    uint32 swapFee
  ) external returns (address pair);

  function getWeightsAndSwapFee(address pair)
    external
    view
    returns (
      uint32 tokenWeight0,
      uint32 tokenWeight1,
      uint32 swapFee
    );

  function setFeeTo(address) external;

  function setFeeToSetter(address) external;

  function setProtocolFee(uint256) external;
}

interface IOracle {
  function epoch() external view returns (uint256);

  function nextEpochPoint() external view returns (uint256);

  function updateCumulative() external;

  function update() external;

  function consult(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

  function consultDollarPrice(address _sideToken, uint256 _amountIn) external view returns (uint256 _dollarPrice);

  function twap(uint256 _amountIn) external view returns (uint144 _amountOut);

  function twapDollarPrice(address _sideToken, uint256 _amountIn) external view returns (uint256 _amountOut);

  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    address pair
  ) external view returns (uint256 amountOut);
}

interface ISwapFeeReward {
  function swap(
    address account,
    address input,
    address output,
    uint256 amount,
    address pair
  ) external returns (bool);

  function pairsListLength() external view returns (uint256);

  function pairsList(uint256 index)
    external
    view
    returns (
      address,
      uint256,
      bool
    );
}

interface IReferral {
  function set(address _from, address _to) external;

  function onHopeCommission(
    address _from,
    address _to,
    uint256 _hopeAmount
  ) external;

  function refOf(address _to) external view returns (address);
}

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
  /**
   * @dev Returns true if `account` is a contract.
   *
   * [IMPORTANT]
   * ====
   * It is unsafe to assume that an address for which this function returns
   * false is an externally-owned account (EOA) and not a contract.
   *
   * Among others, `isContract` will return false for the following
   * types of addresses:
   *
   *  - an externally-owned account
   *  - a contract in construction
   *  - an address where a contract will be created
   *  - an address where a contract lived, but was destroyed
   * ====
   */
  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  /**
   * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
   * `recipient`, forwarding all available gas and reverting on errors.
   *
   * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
   * of certain opcodes, possibly making contracts go over the 2300 gas limit
   * imposed by `transfer`, making them unable to receive funds via
   * `transfer`. {sendValue} removes this limitation.
   *
   * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
   *
   * IMPORTANT: because control is transferred to `recipient`, care must be
   * taken to not create reentrancy vulnerabilities. Consider using
   * {ReentrancyGuard} or the
   * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
   */
  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
   * function instead.
   *
   * If `target` reverts with a revert reason, it is bubbled up by this
   * function (like regular Solidity function calls).
   *
   * Returns the raw returned data. To convert to the expected return value,
   * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
   *
   * Requirements:
   *
   * - `target` must be a contract.
   * - calling `target` with `data` must not revert.
   *
   * _Available since v3.1._
   */
  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
   * `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but also transferring `value` wei to `target`.
   *
   * Requirements:
   *
   * - the calling contract must have an ETH balance of at least `value`.
   * - the called Solidity function must be `payable`.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  /**
   * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
   * with `errorMessage` as a fallback revert reason when `target` reverts.
   *
   * _Available since v3.1._
   */
  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, "Address: low-level static call failed");
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }
}

// solhint-disable-next-line compiler-version
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private _initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private _initializing;

  /**
   * @dev Modifier to protect an initializer function from being invoked twice.
   */
  modifier initializer() {
    require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

    bool isTopLevelCall = !_initializing;
    if (isTopLevelCall) {
      _initializing = true;
      _initialized = true;
    }

    _;

    if (isTopLevelCall) {
      _initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function _isConstructor() private view returns (bool) {
    return !AddressUpgradeable.isContract(address(this));
  }
}

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
abstract contract ContextUpgradeable is Initializable {
  function __Context_init() internal initializer {
    __Context_init_unchained();
  }

  function __Context_init_unchained() internal initializer {}

  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }

  uint256[50] private __gap;
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  function __Ownable_init() internal initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
  }

  function __Ownable_init_unchained() internal initializer {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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

  uint256[49] private __gap;
}

contract SwapFeeReward is OwnableUpgradeable, ISwapFeeReward {
  using SafeMath for uint256;
  using EnumerableSet for EnumerableSet.AddressSet;
  EnumerableSet.AddressSet private _whitelist;

  address public factory;
  mapping(address => bool) public routers;
  uint256 public maxMiningAmount = 100000000 * 1e18;
  uint256 public maxMiningInPhase = 5000 * 1e18;
  uint256 public currentPhase = 1;
  uint256 public totalMined = 0;
  address public hope;
  IOracle public oracle;
  address public targetToken;

  address public rewardReferral;
  uint256 public commissionPercent = 500; //5%

  mapping(address => uint256) public nonces;
  mapping(address => uint256) private _balances;
  mapping(address => uint256) public pairOfPid;

  uint256 private FEE_PRECISION = 10000;
  mapping(address => uint256) pairsFee; //manual config for pair -> fee (base 10000)
  mapping(address => mapping(address => address)) tokensPair; //manual config for tokenA,tokenB -> pair

  struct PairsList {
    address pair;
    uint256 percentReward; //base 100
    bool enabled;
  }
  PairsList[] public override pairsList;

  event Withdraw(address userAddress, uint256 amount);
  event Rewarded(address account, address input, address output, uint256 amount, uint256 quantity);
  event Commission(address indexed user, address indexed referrer, uint256 amount);

  modifier onlyRouter() {
    require(routers[msg.sender], "SwapFeeReward: caller is not the router");
    _;
  }

  function initialize(
    address _factory,
    address[] memory _routers,
    address _hope,
    IOracle _Oracle,
    address _targetToken,
    address _rewardReferral
  ) external initializer {
    OwnableUpgradeable.__Ownable_init();

    maxMiningAmount = 100000000 * 1e18;
    maxMiningInPhase = 5000 * 1e18;
    currentPhase = 1;
    commissionPercent = 500; //5%
    FEE_PRECISION = 10000;

    factory = _factory;
    for (uint256 i = 0; i < _routers.length; i++) {
      routers[_routers[i]] = true;
    }
    hope = _hope;
    oracle = _Oracle;
    targetToken = _targetToken;
    rewardReferral = _rewardReferral;
  }

  function pairFor(address tokenA, address tokenB) public view returns (address pair) {
    if (tokensPair[tokenA][tokenB] != address(0)) {
      return tokensPair[tokenA][tokenB];
    } else if (tokensPair[tokenB][tokenA] != address(0)) {
      return tokensPair[tokenB][tokenA];
    } else {
      return IFireBirdFactory(factory).getPair(tokenA, tokenB, 50, 20);
    }
  }

  function getSwapFee(address pair) internal view returns (uint256 swapFee) {
    if (pairsFee[pair] > 0) {
      return pairsFee[pair];
    }
    if (IFireBirdFactory(factory).isPair(pair)) {
      return IFireBirdPair(pair).getSwapFee();
    } else {
      return 0;
    }
  }

  function setMaxMiningAmount(uint256 _maxMiningAmount) public onlyOwner {
    maxMiningAmount = _maxMiningAmount;
  }

  function setMaxMiningInPhase(uint256 _maxMiningInPhase) public onlyOwner {
    maxMiningInPhase = _maxMiningInPhase;
  }

  function setPhase(uint256 _newPhase) public onlyOwner returns (bool) {
    currentPhase = _newPhase;
    return true;
  }

  function checkPairExist(address tokenA, address tokenB) public view returns (bool) {
    address pair = pairFor(tokenA, tokenB);
    PairsList storage pool = pairsList[pairOfPid[pair]];
    if (pool.pair != pair) {
      return false;
    }
    return true;
  }

  function swap(
    address account,
    address input,
    address output,
    uint256 amount,
    address pair
  ) public override onlyRouter returns (bool) {
    uint256 quantity = getSwapReward(input, output, amount, pair);
    if (quantity == 0) {
      return false;
    }
    if (totalMined.add(quantity) > currentPhase.mul(maxMiningInPhase)) {
      return false;
    }
    _balances[account] = _balances[account].add(quantity);
    emit Rewarded(account, input, output, amount, quantity);
    return true;
  }

  function rewardBalance(address account) public view returns (uint256) {
    return _balances[account];
  }

  function permit(
    address spender,
    uint256 value,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) private {
    bytes32 message = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(spender, value, nonces[spender]++))));
    address recoveredAddress = ecrecover(message, v, r, s);
    require(recoveredAddress != address(0) && recoveredAddress == spender, "SwapFeeReward: INVALID_SIGNATURE");
  }

  function withdraw(
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public returns (bool) {
    require(maxMiningAmount > totalMined, "SwapFeeReward: Mined all tokens");
    uint256 balance = _balances[msg.sender];
    require(totalMined.add(balance) <= currentPhase.mul(maxMiningInPhase), "SwapFeeReward: Mined all tokens in this phase");
    permit(msg.sender, balance, v, r, s);
    if (balance > 0) {
      totalMined = totalMined.add(balance);
      _balances[msg.sender] = _balances[msg.sender].sub(balance);
      emit Withdraw(msg.sender, balance);

      //reference reward
      address _referrer = rewardReferral != address(0) ? IReferral(rewardReferral).refOf(msg.sender) : address(0);
      uint256 _commission = balance.mul(commissionPercent).div(10000);
      balance = balance.sub(_commission);
      if (_referrer != address(0)) {
        // send commission to referrer
        _safeHopeMint(_referrer, _commission);
        emit Commission(msg.sender, _referrer, _commission);
        IReferral(rewardReferral).onHopeCommission(_referrer, msg.sender, _commission);
      }

      _safeHopeMint(msg.sender, balance);
      return true;
    }
    return false;
  }

  function getSwapReward(
    address input,
    address output,
    uint256 amount,
    address pair
  ) public view returns (uint256 quantity) {
    if (!isWhitelist(input) || !isWhitelist(output)) {
      return 0;
    }
    if (maxMiningAmount <= totalMined) {
      return 0;
    }
    PairsList storage pool = pairsList[pairOfPid[pair]];
    if (pool.pair != pair || pool.enabled == false) {
      return 0;
    }
    uint256 pairFee = getSwapFee(pair);
    if (pairFee == 0) {
      return 0;
    }

    uint256 fee = amount.mul(pairFee).div(FEE_PRECISION.sub(pairFee));
    quantity = getQuantity(output, fee, targetToken);
    quantity = quantity.mul(pool.percentReward).div(100);
  }

  function getQuantity(
    address outputToken,
    uint256 outputAmount,
    address anchorToken
  ) public view returns (uint256) {
    uint256 quantity = 0;
    if (outputToken == anchorToken) {
      quantity = outputAmount;
    } else if (checkPairExist(outputToken, anchorToken)) {
      quantity = IOracle(oracle).consult(outputToken, outputAmount, anchorToken, pairFor(outputToken, anchorToken));
    } else {
      uint256 length = getWhitelistLength();
      for (uint256 index = 0; index < length; index++) {
        address intermediate = getWhitelist(index);
        address pair1 = pairFor(outputToken, intermediate);
        address pair2 = pairFor(intermediate, anchorToken);

        if (pair1 != address(0) && checkPairExist(intermediate, anchorToken)) {
          uint256 interQuantity = IOracle(oracle).consult(outputToken, outputAmount, intermediate, pair1);
          quantity = IOracle(oracle).consult(intermediate, interQuantity, anchorToken, pair2);
          break;
        }
      }
    }
    return quantity;
  }

  function _safeHopeMint(address _to, uint256 _amount) internal {
    address _hope = hope;
    if (ICappedMintableBurnableERC20(_hope).minterCap(address(this)) >= _amount && _to != address(0)) {
      uint256 _totalSupply = IERC20(_hope).totalSupply();
      uint256 _cap = ICappedMintableBurnableERC20(_hope).cap();
      uint256 _mintAmount = (_totalSupply.add(_amount) <= _cap) ? _amount : _cap.sub(_totalSupply);
      if (_mintAmount > 0) {
        ICappedMintableBurnableERC20(_hope).mint(_to, _mintAmount);
      }
    }
  }

  function addWhitelist(address _addToken) public onlyOwner returns (bool) {
    require(_addToken != address(0), "SwapMining: token is the zero address");
    return EnumerableSet.add(_whitelist, _addToken);
  }

  function delWhitelist(address _delToken) public onlyOwner returns (bool) {
    require(_delToken != address(0), "SwapMining: token is the zero address");
    return EnumerableSet.remove(_whitelist, _delToken);
  }

  function getWhitelistLength() public view returns (uint256) {
    return EnumerableSet.length(_whitelist);
  }

  function isWhitelist(address _token) public view returns (bool) {
    return EnumerableSet.contains(_whitelist, _token);
  }

  function getWhitelist(uint256 _index) public view returns (address) {
    require(_index <= getWhitelistLength() - 1, "SwapMining: index out of bounds");
    return EnumerableSet.at(_whitelist, _index);
  }

  function setRouter(address router, bool isRouter) public onlyOwner {
    require(router != address(0), "SwapMining: new router is the zero address");
    routers[router] = isRouter;
  }

  function setPairsFee(address pair, uint256 fee) public onlyOwner {
    require(fee < FEE_PRECISION, "SwapMining: max fee");
    pairsFee[pair] = fee;
  }

  function setTokensPair(
    address tokenA,
    address tokenB,
    address pair
  ) public onlyOwner {
    require(pair != address(0) && tokenA != address(0) && tokenB != address(0), "SwapMining: !address");
    tokensPair[tokenA][tokenB] = pair;
  }

  function setOracle(IOracle _oracle) public onlyOwner {
    require(address(_oracle) != address(0), "SwapMining: new oracle is the zero address");
    oracle = _oracle;
  }

  function setFactory(address _factory) public onlyOwner {
    require(_factory != address(0), "SwapMining: new factory is the zero address");
    factory = _factory;
  }

  function setCommissionPercent(uint256 _commissionPercent) public onlyOwner {
    require(_commissionPercent <= 5000, "exceed 50%");
    commissionPercent = _commissionPercent;
  }

  function setRewardReferral(address _rewardReferral) public onlyOwner {
    rewardReferral = _rewardReferral;
  }

  function pairsListLength() public view override returns (uint256) {
    return pairsList.length;
  }

  function addPair(uint256 _percentReward, address _pair) public onlyOwner {
    require(_pair != address(0), "_pair is the zero address");
    pairsList.push(PairsList({pair: _pair, percentReward: _percentReward, enabled: true}));
    pairOfPid[_pair] = pairsListLength() - 1;

    try IFireBirdPair(_pair).token0() {
      address token0 = IFireBirdPair(_pair).token0();
      address token1 = IFireBirdPair(_pair).token1();
      tokensPair[token0][token1] = _pair;

      EnumerableSet.add(_whitelist, token0);
      EnumerableSet.add(_whitelist, token1);
    } catch {}
  }

  function setPair(uint256 _pid, uint256 _percentReward) public onlyOwner {
    pairsList[_pid].percentReward = _percentReward;
  }

  function setPairEnabled(uint256 _pid, bool _enabled) public onlyOwner {
    pairsList[_pid].enabled = _enabled;
  }
}