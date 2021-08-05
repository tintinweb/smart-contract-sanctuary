// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/EnumerableSet.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../interfaces/ICollectableDust.sol';

abstract
contract CollectableDust is ICollectableDust {
  using EnumerableSet for EnumerableSet.AddressSet;

  address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  EnumerableSet.AddressSet internal protocolTokens;

  constructor() public {}

  function _addProtocolToken(address _token) internal {
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    protocolTokens.add(_token);
  }

  function _removeProtocolToken(address _token) internal {
    require(protocolTokens.contains(_token), 'collectable-dust/token-not-part-of-the-protocol');
    protocolTokens.remove(_token);
  }

  function _sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) internal {
    require(_to != address(0), 'collectable-dust/cant-send-dust-to-zero-address');
    require(!protocolTokens.contains(_token), 'collectable-dust/token-is-part-of-the-protocol');
    if (_token == ETH_ADDRESS) {
      payable(_to).transfer(_amount);
    } else {
      IERC20(_token).transfer(_to, _amount);
    }
    emit DustSent(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
        (bool success, ) = recipient.call{ value: amount }("");
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
 * As of v3.0.0, only sets of type `address` (`AddressSet`) and `uint256`
 * (`UintSet`) are supported.
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
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface ICollectableDust {
  event DustSent(address _to, address token, uint256 amount);

  function sendDust(address _to, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../../interfaces/zTreasury/V2/IZTreasuryV2.sol';

import '../../Governable.sol';
import '../../Manageable.sol';
import '../../CollectableDust.sol';

import './zTreasuryV2Metadata.sol';
import './zTreasuryV2ProtocolParameters.sol';

contract zTreasuryV2 is 
  Governable, 
  Manageable,
  CollectableDust,
  zTreasuryV2Metadata,
  zTreasuryV2ProtocolParameters, 
  IZTreasuryV2 {

  using SafeERC20 for IERC20;

  uint256 public override lastEarningsDistribution = 0;
  uint256 public override totalEarningsDistributed = 0;
  
  constructor(
    address _governor,
    address _manager,
    address _zGov,
    address _lotManager,
    address _maintainer,
    address _zToken,
    uint256 _maintainerShare,
    uint256 _governanceShare,
    uint256[] memory _initialDistributionValues
  ) public 
    zTreasuryV2ProtocolParameters(
      _zGov,
      _lotManager,
      _maintainer, 
      _zToken,
      _maintainerShare,
      _governanceShare
    )
    Governable(_governor)
    Manageable(_manager)
    CollectableDust() {
      lastEarningsDistribution = _initialDistributionValues[0];
      totalEarningsDistributed = _initialDistributionValues[1];
      _addProtocolToken(_zToken);
  }

  // Modifiers
  modifier onlyManagerOrLotManager {
    require(msg.sender == manager || msg.sender == lotManager, 'zTreasuryV2::only-manager-or-lot-manager');
    _;
  }
  
  function distributeEarnings() external override onlyManagerOrLotManager {
    uint256 _balance = zToken.balanceOf(address(this));
    
    // Send zToken to maintainer
    uint256 _maintainerEarnings = _balance.mul(maintainerShare).div(SHARES_PRECISION).div(100);
    zToken.safeTransfer(maintainer, _maintainerEarnings);

    // Send zToken to zGov
    uint256 _governanceEarnings = _balance.sub(_maintainerEarnings);
    zToken.safeApprove(address(zGov), 0);
    zToken.safeApprove(address(zGov), _governanceEarnings);

    // Notify governance reward amount to distribute
    zGov.notifyRewardAmount(_governanceEarnings);

    // Set last time distributed
    lastEarningsDistribution = block.timestamp;
    totalEarningsDistributed = totalEarningsDistributed.add(_balance);

    // Emit event
    emit EarningsDistributed(_maintainerEarnings, _governanceEarnings, totalEarningsDistributed);
  }

  // zTreasuryProtocolParameters
  function setZGov(address _zGov) external override onlyGovernor {
    _setZGov(_zGov);
  }

  function setLotManager(address _lotManager) external override onlyGovernor {
    _setLotManager(_lotManager);
  }

  function setMaintainer(address _maintainer) external override onlyGovernor {
    _setMaintainer(_maintainer);
  }

  function setZToken(address _zToken) external override onlyGovernor {
    require(address(zToken) != _zToken, 'zTreasuryV2::setZToken::same-ztoken');
    _removeProtocolToken(address(zToken));
    _addProtocolToken(address(_zToken));
    _setZToken(_zToken);
  }

  function setShares(uint256 _maintainerShare, uint256 _governanceShare) external override onlyGovernor {
    _setShares(_maintainerShare, _governanceShare);
  }

  // Governable
  function setPendingGovernor(address _pendingGovernor) external override onlyGovernor {
    _setPendingGovernor(_pendingGovernor);
  }

  function acceptGovernor() external override onlyPendingGovernor {
    _acceptGovernor();
  }

  // Manageable
  function setPendingManager(address _pendingManager) external override onlyManager {
    _setPendingManager(_pendingManager);
  }

  function acceptManager() external override onlyPendingManager {
    _acceptManager();
  }

  // Collectable Dust
  function sendDust(
    address _to,
    address _token,
    uint256 _amount
  ) external override onlyGovernor {
    _sendDust(_to, _token, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import './IZTreasuryV2Metadata.sol';
import './IZTreasuryV2ProtocolParameters.sol';

interface IZTreasuryV2 is IZTreasuryV2ProtocolParameters, IZTreasuryV2Metadata {
  event EarningsDistributed(
    uint256 maintainerRewards, 
    uint256 governanceRewards, 
    uint256 totalEarningsDistributed
  );

  function lastEarningsDistribution() external returns (uint256);
  function totalEarningsDistributed() external returns (uint256);
  function distributeEarnings() external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../interfaces/IGovernable.sol';

abstract
contract Governable is IGovernable {
  address public governor;
  address public pendingGovernor;

  constructor(address _governor) public {
    require(_governor != address(0), 'governable/governor-should-not-be-zero-address');
    governor = _governor;
  }

  function _setPendingGovernor(address _pendingGovernor) internal {
    require(_pendingGovernor != address(0), 'governable/pending-governor-should-not-be-zero-addres');
    pendingGovernor = _pendingGovernor;
    emit PendingGovernorSet(_pendingGovernor);
  }

  function _acceptGovernor() internal {
    governor = pendingGovernor;
    pendingGovernor = address(0);
    emit GovernorAccepted();
  }

  modifier onlyGovernor {
    require(msg.sender == governor, 'governable/only-governor');
    _;
  }

  modifier onlyPendingGovernor {
    require(msg.sender == pendingGovernor, 'governable/only-pending-governor');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../interfaces/IManageable.sol';

abstract
contract Manageable is IManageable {
  address public manager;
  address public pendingManager;

  constructor(address _manager) public {
    require(_manager != address(0), 'manageable/manager-should-not-be-zero-address');
    manager = _manager;
  }

  function _setPendingManager(address _pendingManager) internal {
    require(_pendingManager != address(0), 'manageable/pending-manager-should-not-be-zero-addres');
    pendingManager = _pendingManager;
    emit PendingManagerSet(_pendingManager);
  }

  function _acceptManager() internal {
    manager = pendingManager;
    pendingManager = address(0);
    emit ManagerAccepted();
  }

  modifier onlyManager {
    require(msg.sender == manager, 'manageable/only-manager');
    _;
  }

  modifier onlyPendingManager {
    require(msg.sender == pendingManager, 'manageable/only-pending-manager');
    _;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../../interfaces/zTreasury/V2/IZTreasuryV2Metadata.sol';

contract zTreasuryV2Metadata is IZTreasuryV2Metadata {
  function isZTreasury() external override pure returns (bool) {
    return true;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../../../interfaces/LotManager/ILotManagerMetadata.sol';
import '../../../interfaces/zTreasury/V2/IZTreasuryV2ProtocolParameters.sol';

abstract
contract zTreasuryV2ProtocolParameters is IZTreasuryV2ProtocolParameters {
  using SafeMath for uint256;
  
  uint256 public constant override SHARES_PRECISION = 10000;
  uint256 public constant override MAX_MAINTAINER_SHARE = 25 * SHARES_PRECISION;

  IERC20 public override zToken; // zhegic
  zGovernance public override zGov; // zgov

  address public override lotManager;
  address public override maintainer;

  uint256 public override maintainerShare;
  uint256 public override governanceShare;
  
  constructor(
    address _zGov,
    address _lotManager,
    address _maintainer,
    address _zToken,
    uint256 _maintainerShare,
    uint256 _governanceShare
  ) public {
    _setZGov(_zGov);
    _setLotManager(_lotManager);
    _setMaintainer(_maintainer);
    _setZToken(_zToken);
    _setShares(_maintainerShare, _governanceShare);
  }
  
  function _setZGov(address _zGov) internal {
    require(_zGov != address(0), 'zTreasuryV2ProtocolParameters::_setZGov::no-zero-address');
    zGov = zGovernance(_zGov);
    emit ZGovSet(_zGov);
  }

  function _setLotManager(address _lotManager) internal {
    require(_lotManager != address(0), 'zTreasuryV2ProtocolParameters::_setLotManager::no-zero-address');
    require(ILotManagerMetadata(_lotManager).isLotManager(), 'zTreasuryV2ProtocolParameters::_setLotManager::not-lot-manager');
    lotManager = _lotManager;
    emit LotManagerSet(_lotManager);
  }

  function _setMaintainer(address _maintainer) internal {
    require(_maintainer != address(0), 'zTreasuryV2ProtocolParameters::_setMaintainer::no-zero-address');
    maintainer = _maintainer;
    emit MaintainerSet(_maintainer);
  }

  function _setZToken(address _zToken) internal {
    require(_zToken != address(0), 'zTreasuryV2ProtocolParameters::_setZToken::no-zero-address');
    zToken = IERC20(_zToken);
    emit ZTokenSet(_zToken);
  }

  function _setShares(uint256 _maintainerShare, uint256 _governanceShare) internal {
    require(_maintainerShare.add(_governanceShare) == SHARES_PRECISION.mul(100), 'zTreasuryV2ProtocolParameters::_setShares::not-100-percent');
    require(_maintainerShare <= MAX_MAINTAINER_SHARE, 'zTreasuryV2ProtocolParameters::_setShares::exceeds-max-mantainer-share');
    maintainerShare = _maintainerShare;
    governanceShare = _governanceShare;
    emit SharesSet(_maintainerShare, _governanceShare);
  }
}

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IZTreasuryV2Metadata {
  function isZTreasury() external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface zGovernance {
  function notifyRewardAmount(uint) external;
}

interface IZTreasuryV2ProtocolParameters {
  event ZGovSet(address zGov);
  event LotManagerSet(address lotManager);
  event MaintainerSet(address maintainer);
  event ZTokenSet(address zToken);
  event SharesSet(uint256 maintainerShare, uint256 governanceShare);

  function zToken() external returns (IERC20);

  function zGov() external returns (zGovernance);
  function lotManager() external returns (address);
  function maintainer() external returns (address);

  function SHARES_PRECISION() external returns (uint256);
  function MAX_MAINTAINER_SHARE() external returns (uint256);
  function maintainerShare() external returns (uint256);
  function governanceShare() external returns (uint256);

  function setZGov(address _zGov) external;
  function setLotManager(address _lotManager) external;
  function setMaintainer(address _maintainer) external;
  function setZToken(address _zToken) external;
  function setShares(uint256 _maintainerShare, uint256 _governanceShare) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event GovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;
  function acceptGovernor() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IManageable {
  event PendingManagerSet(address pendingManager);
  event ManagerAccepted();

  function setPendingManager(address _pendingManager) external;
  function acceptManager() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface ILotManagerMetadata {
  function isLotManager() external pure returns (bool);
  function getName() external pure returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

contract zLOTTokenWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public zLOT;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  constructor(address _zLOT) public {
    zLOT = IERC20(_zLOT);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function stake(uint256 amount) public virtual {
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    zLOT.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public virtual {
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    zLOT.safeTransfer(msg.sender, amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/math/Math.sol';
import './IRewardDistributionRecipient.sol';
import './zLOTTokenWrapper.sol';

contract zGovernance is zLOTTokenWrapper, IRewardDistributionRecipient {
  uint256 public constant DURATION = 7 days;

  IERC20 public zToken;
  uint256 public periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public lastUpdateTime = 0;
  uint256 public rewardPerTokenStored = 0;
  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  mapping(address => uint256) public totalEarnedRewards;

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward, uint256 totalEarnedRewards);

  constructor (address _zLOT, address _zToken) public zLOTTokenWrapper(_zLOT) {
    zToken = IERC20(_zToken);
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    return Math.min(block.timestamp, periodFinish);
  }

  function rewardPerToken() public view returns (uint256) {
    if (totalSupply() == 0) {
      return rewardPerTokenStored;
    }
    return
      rewardPerTokenStored.add(
        lastTimeRewardApplicable()
          .sub(lastUpdateTime)
          .mul(rewardRate)
          .mul(1e18)
          .div(totalSupply())
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      balanceOf(account)
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function stake(uint256 amount) override public updateReward(msg.sender) {
    require(amount > 0, 'zGovernance::stake::cant-stake-0');
    super.stake(amount);
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) override public updateReward(msg.sender) {
    require(amount > 0, 'zGovernance::withdraw::cant-withdraw-0');
    super.withdraw(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
    getReward();
  }

  function getReward() public updateReward(msg.sender) {
    uint256 reward = earned(msg.sender);
    if (reward > 0) {
      rewards[msg.sender] = 0;
      totalEarnedRewards[msg.sender] = totalEarnedRewards[msg.sender].add(reward);
      zToken.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward, totalEarnedRewards[msg.sender]);
    }
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyRewardDistribution
    updateReward(address(0))
  {
    IERC20(zToken).safeTransferFrom(msg.sender, address(this), reward);
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(DURATION);
    } else {
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(DURATION);
    }
    lastUpdateTime = block.timestamp;
    periodFinish = block.timestamp.add(DURATION);
    emit RewardAdded(reward);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/access/Ownable.sol';

abstract contract IRewardDistributionRecipient is Ownable {
  address public rewardDistribution;

  function notifyRewardAmount(uint256 reward) external virtual;

  modifier onlyRewardDistribution() {
    require(_msgSender() == rewardDistribution, 'Caller is not reward distribution');
    _;
  }

  function setRewardDistribution(address _rewardDistribution)
    external
    onlyOwner
  {
    rewardDistribution = _rewardDistribution;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '../../interfaces/LotManager/ILotManagerMetadata.sol';

contract LotManagerMetadata is ILotManagerMetadata {
  function isLotManager() external override pure returns (bool) {
    return true;
  }
  function getName() external override pure returns (string memory) {
    return 'LotManager';
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
  "libraries": {}
}