// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../helpers/FixedPoint.sol";
import "../helpers/BytesHelpers.sol";

import "../interfaces/IAgreement.sol";
import "../interfaces/IVault.sol";

contract Agreement is IAgreement, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;
    using BytesHelpers for bytes;
    using BytesHelpers for bytes4;
    using BytesHelpers for bytes32[];

    enum AllowedStrategies {
        Any,
        None,
        Whitelisted
    }

    uint256 internal constant MAX_DEPOSIT_FEE = 1e18; // 100%
    uint256 internal constant MAX_PERFORMANCE_FEE = 1e18; // 100%

    string public override name;
    address public immutable override vault;
    address public immutable override feeCollector;
    uint256 public immutable override depositFee;
    uint256 public immutable override performanceFee;

    address public immutable manager0;
    address public immutable manager1;
    address public immutable withdrawer0;
    address public immutable withdrawer1;

    uint256 public immutable customStrategies;
    address public immutable customStrategy0;
    address public immutable customStrategy1;
    address public immutable customStrategy2;
    address public immutable customStrategy3;
    address public immutable customStrategy4;
    address public immutable customStrategy5;
    address public immutable customStrategy6;
    address public immutable customStrategy7;
    AllowedStrategies public immutable allowedStrategies;

    event Withdrawn(address indexed caller, address indexed withdrawer, address[] tokens, uint256[] amounts);

    constructor(
        string memory _name,
        address _vault,
        uint256 _depositFee,
        uint256 _performanceFee,
        address _feeCollector,
        address[] memory _managers,
        address[] memory _withdrawers,
        AllowedStrategies _allowedStrategies,
        address[] memory _customStrategies
    ) {
        require(bytes(_name).length > 0, "AGREEMENT_EMPTY_NAME");
        name = _name;

        require(_vault.isContract(), "VAULT_NOT_CONTRACT");
        vault = _vault;

        require(_depositFee <= MAX_DEPOSIT_FEE, "DEPOSIT_FEE_TOO_HIGH");
        depositFee = _depositFee;

        require(_performanceFee <= MAX_PERFORMANCE_FEE, "PERFORMANCE_FEE_TOO_HIGH");
        performanceFee = _performanceFee;

        require(_feeCollector != address(0), "FEE_COLLECTOR_ZERO_ADDRESS");
        feeCollector = _feeCollector;
        emit FeesConfigSet(_depositFee, _performanceFee, _feeCollector);

        require(_managers.length == 2, "MUST_SPECIFY_2_MANAGERS");
        require(_managers[0] != address(0) && _managers[1] != address(0), "MANAGER_ZERO_ADDRESS");
        manager0 = _managers[0];
        manager1 = _managers[1];
        emit ManagersSet(_managers);

        require(_withdrawers.length == 2, "MUST_SPECIFY_2_WITHDRAWERS");
        require(_withdrawers[0] != address(0) && _withdrawers[1] != address(0), "WITHDRAWER_ZERO_ADDRESS");
        withdrawer0 = _withdrawers[0];
        withdrawer1 = _withdrawers[1];
        emit WithdrawersSet(_withdrawers);

        uint256 length = _customStrategies.length;
        require(length <= 8, "TOO_MANY_CUSTOM_STRATEGIES");

        allowedStrategies = _allowedStrategies;
        bool isAny = _allowedStrategies == AllowedStrategies.Any;
        require(!isAny || length == 0, "ANY_WITH_CUSTOM_STRATEGIES");

        for (uint256 i = 0; i < length; i++) {
            require(_customStrategies[i].isContract(), "CUSTOM_STRATEGY_NOT_CONTRACT");
        }

        customStrategies = length;
        customStrategy0 = isAny ? address(0) : (length > 0 ? _customStrategies[0] : address(0));
        customStrategy1 = isAny ? address(0) : (length > 1 ? _customStrategies[1] : address(0));
        customStrategy2 = isAny ? address(0) : (length > 2 ? _customStrategies[2] : address(0));
        customStrategy3 = isAny ? address(0) : (length > 3 ? _customStrategies[3] : address(0));
        customStrategy4 = isAny ? address(0) : (length > 4 ? _customStrategies[4] : address(0));
        customStrategy5 = isAny ? address(0) : (length > 5 ? _customStrategies[5] : address(0));
        customStrategy6 = isAny ? address(0) : (length > 6 ? _customStrategies[6] : address(0));
        customStrategy7 = isAny ? address(0) : (length > 7 ? _customStrategies[7] : address(0));
        emit StrategiesSet(uint256(_allowedStrategies), _customStrategies);
    }

    function getDepositFee() external override view returns (uint256, address) {
        return (depositFee, feeCollector);
    }

    function getPerformanceFee() external override view returns (uint256, address) {
        return (performanceFee, feeCollector);
    }

    function getBalance(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function isManager(address account) public override view returns (bool) {
        return manager0 == account || manager1 == account;
    }

    function isWithdrawer(address account) public override view returns (bool) {
        return withdrawer0 == account || withdrawer1 == account;
    }

    function isSenderAllowed(address sender) public view returns (bool) {
        return isWithdrawer(sender) || isManager(sender);
    }

    function isStrategyAllowed(address strategy) public override view returns (bool) {
        if (allowedStrategies == AllowedStrategies.Any) {
            return true;
        }

        if (isCustomStrategy(strategy)) {
            return true;
        }

        return allowedStrategies == AllowedStrategies.Whitelisted && IVault(vault).isStrategyWhitelisted(strategy);
    }

    function isCustomStrategy(address strategy) public view returns (bool) {
        if (customStrategies > 0 && strategy == customStrategy0) return true;
        if (customStrategies > 1 && strategy == customStrategy1) return true;
        if (customStrategies > 2 && strategy == customStrategy2) return true;
        if (customStrategies > 3 && strategy == customStrategy3) return true;
        if (customStrategies > 4 && strategy == customStrategy4) return true;
        if (customStrategies > 5 && strategy == customStrategy5) return true;
        if (customStrategies > 6 && strategy == customStrategy6) return true;
        if (customStrategies > 7 && strategy == customStrategy7) return true;
        return false;
    }

    function canPerform(address who, address where, bytes32 what, bytes32[] memory how) external override view returns (bool) {
        // If the sender is not allowed, then it cannot perform any actions
        if (!isSenderAllowed(who)) {
            return false;
        }

        // This agreement only trusts the vault
        if (where != address(vault)) {
            return false;
        }

        // Eval different actions and parameters
        if (what == IVault.joinSwap.selector.toBytes32() || what == IVault.join.selector.toBytes32() || what == IVault.exit.selector.toBytes32()) {
            return isStrategyAllowed(how.decodeAddress(0));
        } else if (what == IVault.withdraw.selector.toBytes32()) {
            return isWithdrawer(how.decodeAddress(0));
        } else {
            return what == IVault.deposit.selector.toBytes32();
        }
    }

    function approveTokens(address[] memory tokens) external override nonReentrant {
        require(msg.sender == vault, "SENDER_NOT_ALLOWED");
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            uint256 allowance = token.allowance(address(this), vault);
            if (allowance < FixedPoint.MAX_UINT256) {
                if (token.allowance(address(this), vault) > 0) {
                    // Some tokens revert when changing non-zero approvals
                    token.safeApprove(vault, 0);
                }
                token.safeApprove(vault, FixedPoint.MAX_UINT256);
            }
        }
    }

    function withdraw(address withdrawer, address[] memory tokens, uint256[] memory amounts) external nonReentrant {
        require(isSenderAllowed(msg.sender), "SENDER_NOT_ALLOWED");
        require(isWithdrawer(withdrawer), "WITHDRAWER_NOT_ALLOWED");

        require(tokens.length > 0, "INVALID_TOKENS_LENGTH");
        require(tokens.length == amounts.length, "INVALID_AMOUNTS_LENGTH");

        uint256[] memory missingAmounts = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            uint256 currentBalance = getBalance(token);

            bool requiresVaultBalance = amount > currentBalance;
            missingAmounts[i] = requiresVaultBalance ? amount - currentBalance : 0;
            uint256 vaultBalance = requiresVaultBalance ? IVault(vault).getAccountBalance(address(this), token) : 0;
            require(vaultBalance.add(currentBalance) >= amount, "ACCOUNT_INSUFFICIENT_BALANCE");

            require(currentBalance >= amount - missingAmounts[i], "ACCOUNT_INSUFFICIENT_BALANCE");
            IERC20(token).safeTransfer(withdrawer, amount - missingAmounts[i]);
        }

        IVault(vault).withdraw(address(this), tokens, missingAmounts, withdrawer);
        emit Withdrawn(msg.sender, withdrawer, tokens, amounts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library FixedPoint {
    uint256 internal constant ONE = 1e18; // 18 decimal places
    uint256 internal constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        uint256 c = a + b;
        require(c >= a, "ADD_OVERFLOW");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        // Fixed Point addition is the same as regular checked addition

        require(b <= a, "SUB_OVERFLOW");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c0 = a * b;
        require(a == 0 || c0 / a == b, "MUL_OVERFLOW");
        uint256 c1 = c0 + (ONE / 2);
        require(c1 >= c0, "MUL_OVERFLOW");
        uint256 c2 = c1 / ONE;
        return c2;
    }

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        require(a == 0 || product / a == b, "MUL_OVERFLOW");

        return product / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;
        require(a == 0 || product / a == b, "MUL_OVERFLOW");

        if (product == 0) {
            return 0;
        } else {
            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((product - 1) / ONE) + 1;
        }
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");
        uint256 c0 = a * ONE;
        require(a == 0 || c0 / a == ONE, "DIV_INTERNAL"); // mul overflow
        uint256 c1 = c0 + (b / 2);
        require(c1 >= c0, "DIV_INTERNAL"); // add require
        uint256 c2 = c1 / b;
        return c2;
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");

        uint256 aInflated = a * ONE;
        require(aInflated / a == ONE, "DIV_INTERNAL"); // mul overflow

        return aInflated / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "ZERO_DIVISION");

        if (a == 0) {
            return 0;
        } else {
            uint256 aInflated = a * ONE;
            require(aInflated / a == ONE, "DIV_INTERNAL"); // mul overflow

            // The traditional divUp formula is:
            // divUp(x, y) := (x + y - 1) / y
            // To avoid intermediate overflow in the addition, we distribute the division and get:
            // divUp(x, y) := (x - 1) / y + 1
            // Note that this requires x != 0, which we already tested for.

            return ((aInflated - 1) / b) + 1;
        }
    }

    /**
     * @dev Returns the largest of two numbers of 256 bits.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers of 256 bits.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

library BytesHelpers {
    function toBytes32(bytes4 self) internal pure returns (bytes32 result) {
        assembly { result := self }
    }

    function decodeAddress(bytes32[] memory self, uint256 index) internal pure returns (address) {
        require(self.length > index, "INVALID_BYTES_ARRAY_INDEX");
        return address(bytes20(self[index]));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "./IPortfolio.sol";

interface IAgreement is IPortfolio {
    event WithdrawersSet(address[] withdrawers);
    event ManagersSet(address[] managers);
    event StrategiesSet(uint256 allowedStrategies, address[] customStrategies);

    function name() external view returns (string memory);

    function vault() external view returns (address);

    function feeCollector() external view returns (address);

    function depositFee() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function isManager(address account) external view returns (bool);

    function isWithdrawer(address account) external view returns (bool);

    function isStrategyAllowed(address strategy) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IVault {
    event Deposit(address indexed account, address[] tokens, uint256[] amounts, uint256[] depositFees, address caller);
    event Withdraw(address indexed account, address[] tokens, uint256[] amounts, address recipient, address caller);
    event Join(address indexed account, address indexed strategy, uint256 amount, uint256 shares, address caller);
    event Exit(address indexed account, address indexed strategy, uint256 amountInvested, uint256 amountReceived, uint256 shares, uint256 protocolFee, uint256 performanceFee, address caller);
    event Swap(address indexed account, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, bytes data);
    event ProtocolFeeSet(uint256 protocolFee);
    event SwapConnectorSet(address swapConnector);
    event WhitelistedStrategySet(address indexed strategy, bool whitelisted);

    function protocolFee() external view returns (uint256);

    function swapConnector() external view returns (address);

    function isStrategyWhitelisted(address strategy) external view returns (bool);

    function getAccountBalance(address account, address token) external view returns (uint256);

    function getAccountInvestment(address account, address strategy) external view returns (uint256 invested, uint256 shares);

    function batch(bytes[] memory data) external returns (bytes[] memory results);

    function deposit(address account, address[] memory tokens, uint256[] memory amounts) external;

    function withdraw(address account, address[] memory tokens, uint256[] memory amounts, address recipient) external;

    function joinSwap(address account, address strategy, address token, uint256 amountIn, uint256 minAmountOut, bytes memory data) external;

    function join(address account, address strategy, uint256 amount, bytes memory data) external;

    function exit(address account, address strategy, uint256 ratio, bytes memory data) external;

    function setProtocolFee(uint256 newProtocolFee) external;

    function setSwapConnector(address newSwapConnector) external;

    function setWhitelistedStrategies(address[] memory strategies, bool[] memory whitelisted) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IPortfolio {
    event FeesConfigSet(uint256 depositFee, uint256 performanceFee, address feeCollector);

    function getPerformanceFee() external view returns (uint256 fee, address collector);

    function getDepositFee() external view returns (uint256 fee, address collector);

    function canPerform(address who, address where, bytes32 what, bytes32[] memory how) external view returns (bool);

    function approveTokens(address[] memory tokens) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "./Agreement.sol";

contract AgreementFactory  {
    address public immutable vault;
    mapping (address => bytes32) public agreementsByAddress;
    mapping (bytes32 => address) public agreementsByNameHash;

    event AgreementCreated(address indexed agreement);

    constructor(address _vault) {
        vault = _vault;
    }

    function isAgreement(address agreement) external view returns (bool) {
        return agreementsByAddress[agreement] != bytes32(0);
    }

    function isAgreement(string memory name) external view returns (bool) {
        bytes32 nameHash = keccak256(bytes(name));
        return agreementsByNameHash[nameHash] == address(0);
    }

    function create(
        string memory _name,
        uint256 _depositFee,
        uint256 _performanceFee,
        address _feeCollector,
        address[] memory _managers,
        address[] memory _withdrawers,
        Agreement.AllowedStrategies _allowedStrategies,
        address[] memory _customStrategies
    ) external {
        bytes32 nameHash = keccak256(bytes(_name));
        require(agreementsByNameHash[nameHash] == address(0), "AGREEMENT_ALREADY_REGISTERED");

        Agreement agreement = new Agreement(_name, vault, _depositFee, _performanceFee, _feeCollector, _managers, _withdrawers, _allowedStrategies, _customStrategies);
        agreementsByAddress[address(agreement)] = nameHash;
        agreementsByNameHash[nameHash] = address(agreement);
        emit AgreementCreated(address(agreement));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "../helpers/Utils.sol";
import "../helpers/FixedPoint.sol";
import "../helpers/BytesHelpers.sol";

import "../interfaces/IPortfolio.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/ISwapConnector.sol";
import "../interfaces/IVault.sol";

contract Vault is IVault, Ownable, ReentrancyGuard {
    using Address for address;
    using SafeERC20 for IERC20;
    using FixedPoint for uint256;
    using BytesHelpers for bytes4;

    uint256 private constant _MAX_PROTOCOL_FEE = 0.05e16; // 5%

    struct Account {
        mapping (address => uint256) balance;
        mapping (address => uint256) shares;
        mapping (address => uint256) invested;
    }

    uint256 public override protocolFee;
    address public override swapConnector;
    mapping (address => bool) public override isStrategyWhitelisted;

    mapping (address => Account) internal accounts;

    modifier authenticate(address account, bytes32[] memory params) {
        _authenticate(account, params);
        _;
    }

    constructor (uint256 _protocolFee, address _swapConnector, address[] memory _whitelistedStrategies) {
        setProtocolFee(_protocolFee);
        setSwapConnector(_swapConnector);
        setWhitelistedStrategies(_whitelistedStrategies, trues(_whitelistedStrategies.length));
    }

    function getAccountBalance(address accountAddress, address token) external override view returns (uint256) {
        Account storage account = accounts[accountAddress];
        return account.balance[token];
    }

    function getAccountInvestment(address accountAddress, address strategy) external override view returns (uint256 invested, uint256 shares) {
        Account storage account = accounts[accountAddress];
        invested = account.invested[strategy];
        shares = account.shares[strategy];
    }

    function batch(bytes[] memory data) external override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
    }

    function deposit(address accountAddress, address[] memory tokens, uint256[] memory amounts)
        external
        override
        nonReentrant
        authenticate(accountAddress, arr())
    {
        require(tokens.length > 0, "INVALID_TOKENS_LENGTH");
        require(tokens.length == amounts.length, "INVALID_AMOUNTS_LENGTH");

        uint256 depositFee;
        address feeCollector;
        if (accountAddress.isContract()) {
            IPortfolio(accountAddress).approveTokens(tokens);
            (depositFee, feeCollector) = IPortfolio(accountAddress).getDepositFee();
        }

        Account storage account = accounts[accountAddress];
        uint256[] memory depositFees = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];
            _safeTransferFrom(token, accountAddress, amount);

            uint256 depositFeeAmount;
            if (depositFee > 0) {
                depositFeeAmount = amount.mulDown(depositFee);
                _safeTransfer(token, feeCollector, depositFeeAmount);
            }

            depositFees[i] = depositFeeAmount;
            uint256 amountAfterFees = amount.sub(depositFeeAmount);
            account.balance[token] = account.balance[token].add(amountAfterFees);
        }

        emit Deposit(accountAddress, tokens, amounts, depositFees, msg.sender);
    }

    function withdraw(address accountAddress, address[] memory tokens, uint256[] memory amounts, address recipient)
        external
        override
        nonReentrant
        authenticate(accountAddress, arr(recipient))
    {
        require(tokens.length > 0, "INVALID_TOKENS_LENGTH");
        require(tokens.length == amounts.length, "INVALID_AMOUNTS_LENGTH");

        Account storage account = accounts[accountAddress];
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 amount = amounts[i];

            uint256 currentBalance = account.balance[token];
            require(currentBalance >= amount, "ACCOUNT_INSUFFICIENT_BALANCE");

            account.balance[token] = currentBalance.sub(amount);
            _safeTransfer(token, recipient, amount);
        }

        emit Withdraw(accountAddress, tokens, amounts, recipient, msg.sender);
    }

    function joinSwap(address accountAddress, address strategy, address token, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        override
        nonReentrant
        authenticate(accountAddress, arr(strategy, token, amountIn))
    {
        address strategyToken = IStrategy(strategy).getToken();
        require(strategyToken != token, "JOIN_SWAP_INVALID_TOKEN");

        Account storage account = accounts[accountAddress];
        uint256 currentBalance = account.balance[token];
        require(currentBalance >= amountIn, "ACCOUNT_INSUFFICIENT_BALANCE");
        account.balance[token] = currentBalance.sub(amountIn);

        uint256 amountOut = _swap(accountAddress, token, strategyToken, amountIn, minAmountOut, data);
        _join(accountAddress, strategy, strategyToken, amountOut, data);
    }

    function join(address accountAddress, address strategy, uint256 amount, bytes memory data)
        external
        override
        nonReentrant
        authenticate(accountAddress, arr(strategy, amount))
    {
        address token = IStrategy(strategy).getToken();
        Account storage account = accounts[accountAddress];
        uint256 currentBalance = account.balance[token];
        require(currentBalance >= amount, "ACCOUNT_INSUFFICIENT_BALANCE");
        account.balance[token] = currentBalance.sub(amount);

        _join(accountAddress, strategy, token, amount, data);
    }

    function _join(address accountAddress, address strategy, address token, uint256 amount, bytes memory data) private {
        _safeTransfer(token, strategy, amount);
        Account storage account = accounts[accountAddress];
        uint256 shares = IStrategy(strategy).onJoin(amount, data);
        account.shares[strategy] = account.shares[strategy].add(shares);
        account.invested[strategy] = account.invested[strategy].add(amount);
        emit Join(accountAddress, strategy, amount, shares, msg.sender);
    }

    function exit(address accountAddress, address strategy, uint256 ratio, bytes memory data)
        external
        override
        nonReentrant
        authenticate(accountAddress, arr(strategy, ratio))
    {
        Account storage account = accounts[accountAddress];
        uint256 exitingShares = _updateExitingShares(account, strategy, ratio);
        (address token, uint256 amountReceived) = IStrategy(strategy).onExit(exitingShares, data);
        _safeTransferFrom(token, strategy, amountReceived);

        uint256 invested = account.invested[strategy];
        uint256 deposited = invested.mulUp(ratio);
        (uint256 protocolFeeAmount, uint256 performanceFeeAmount) = _payExitFees(accountAddress, token, deposited, amountReceived);

        account.invested[strategy] = invested.sub(deposited);
        uint256 amountAfterFees = amountReceived.sub(protocolFeeAmount).sub(performanceFeeAmount);
        account.balance[token] = account.balance[token].add(amountAfterFees);
        emit Exit(accountAddress, strategy, deposited, amountAfterFees, exitingShares, protocolFeeAmount, performanceFeeAmount, msg.sender);
    }

    function setProtocolFee(uint256 newProtocolFee) public override nonReentrant onlyOwner {
        require(newProtocolFee <= _MAX_PROTOCOL_FEE, "PROTOCOL_FEE_TOO_HIGH");
        protocolFee = newProtocolFee;
        emit ProtocolFeeSet(newProtocolFee);
    }

    function setSwapConnector(address newSwapConnector) public override nonReentrant onlyOwner {
        require(newSwapConnector != address(0), "SWAP_CONNECTOR_ZERO_ADDRESS");
        swapConnector = newSwapConnector;
        emit SwapConnectorSet(newSwapConnector);
    }

    function setWhitelistedStrategies(address[] memory strategies, bool[] memory whitelisted)
        public
        override
        nonReentrant
        onlyOwner
    {
        require(strategies.length == whitelisted.length, "INVALID_WHITELISTED_LENGTH");

        for (uint256 i = 0; i < strategies.length; i++) {
            address strategy = strategies[i];
            require(strategy != address(0), "STRATEGY_ZERO_ADDRESS");
            isStrategyWhitelisted[strategy] = whitelisted[i];
            emit WhitelistedStrategySet(strategy, whitelisted[i]);
        }
    }

    function _updateExitingShares(Account storage account, address strategy, uint256 ratio) private returns (uint256) {
        require(ratio <= FixedPoint.ONE, "INVALID_EXIT_RATIO");

        uint256 currentShares = account.shares[strategy];
        uint256 exitingShares = currentShares.mulDown(ratio);
        require(exitingShares > 0, "EXIT_SHARES_ZERO");
        require(currentShares >= exitingShares, "ACCOUNT_INSUFFICIENT_SHARES");

        account.shares[strategy] = currentShares - exitingShares;
        return exitingShares;
    }

    function _payExitFees(address accountAddress, address token, uint256 deposited, uint256 received)
        private
        returns (uint256 protocolFeeAmount, uint256 performanceFeeAmount)
    {
        if (deposited >= received) {
            return (0, 0);
        }

        uint256 gains = received - deposited;

        if (protocolFee > 0) {
            protocolFeeAmount = gains.mulUp(protocolFee);
            _safeTransfer(token, owner(), protocolFeeAmount);
        }

        if (accountAddress.isContract()) {
            (uint256 performanceFee, address feeCollector) = IPortfolio(accountAddress).getPerformanceFee();
            if (performanceFee > 0) {
                uint256 gainsAfterProtocolFees = gains.sub(protocolFeeAmount);
                performanceFeeAmount = gainsAfterProtocolFees.mulDown(performanceFee);
                _safeTransfer(token, feeCollector, performanceFeeAmount);
            }
        }
    }

    function _swap(address accountAddress, address tokenIn, address tokenOut, uint256 amountIn, uint256 minAmountOut, bytes memory data) internal returns (uint256 amountOut) {
        amountOut = ISwapConnector(swapConnector).getAmountOut(tokenIn, tokenOut, amountIn);
        require(amountOut >= minAmountOut, "SWAP_MIN_AMOUNT");
        _safeTransfer(tokenIn, swapConnector, amountIn);

        ISwapConnector(swapConnector).swap(tokenIn, tokenOut, amountIn, minAmountOut, block.timestamp, data);
        _safeTransferFrom(tokenOut, swapConnector, amountOut);
        emit Swap(accountAddress, tokenIn, tokenOut, amountIn, amountOut, data);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        if (amount > 0) {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    function _safeTransferFrom(address token, address from, uint256 amount) internal {
        if (amount > 0) {
            IERC20(token).safeTransferFrom(from, address(this), amount);
        }
    }

    function _authenticate(address account, bytes32[] memory params) internal view {
        require(_canPerform(account, params), "SENDER_NOT_ALLOWED");
    }

    function _canPerform(address account, bytes32[] memory params) internal view returns (bool) {
        // Allow users operating on their behalf
        if (msg.sender == account) {
            return true;
        }

        // Disallow users operating on behalf of foreign EOAs
        if (!account.isContract()) {
            return false;
        }

        // Finally, ask the account if the sender can operate on their behalf
        return IPortfolio(account).canPerform(msg.sender, address(this), msg.sig.toBytes32(), params);
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

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

// solhint-disable func-visibility

function trues(uint256 size) pure returns (bool[] memory array) {
    array = new bool[](size);
    for (uint256 i = 0; i < size; i++) {
        array[i] = true;
    }
}

function arr() pure returns (bytes32[] memory result) {
    result = new bytes32[](0);
}

function arr(address p1) pure returns (bytes32[] memory result) {
    result = new bytes32[](1);
    result[0] = bytes32(bytes20(p1));
}

function arr(address p1, uint256 p2) pure returns (bytes32[] memory result) {
    result = new bytes32[](2);
    result[0] = bytes32(bytes20(p1));
    result[1] = bytes32(p2);
}

function arr(address p1, address p2, uint256 p3) pure returns (bytes32[] memory result) {
    result = new bytes32[](3);
    result[0] = bytes32(bytes20(p1));
    result[1] = bytes32(bytes20(p2));
    result[2] = bytes32(p3);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
    function getToken() external view returns (address);

    function getTokenBalance() external view returns (uint256);

    function getTotalShares() external view returns (uint256);

    function getMetadataURI() external view returns (string memory);

    function onJoin(uint256 amount, bytes memory data) external returns (uint256 shares);

    function onExit(uint256 shares, bytes memory data) external returns (address token, uint256 amount);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface ISwapConnector {
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut);

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bytes memory data
    ) external returns (uint256 amountOut);
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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/ISwapConnector.sol";

import "../helpers/FixedPoint.sol";

contract SwapConnectorMock is ISwapConnector {
    using FixedPoint for uint256;

    uint256 public mockedRate;

    constructor() {
        // always used as OUT priced based on IN: 2 means 1 IN is equal to 2 OUT
        mockedRate = FixedPoint.ONE;
    }

    function getAmountOut(address, address, uint256 amountIn) public view override returns (uint256) {
        return amountIn.mul(mockedRate);
    }

    function swap(address /* tokenIn */, address tokenOut, uint256 amountIn, uint256, uint256, bytes memory)
        external
        override
        returns (uint256 amountOut)
    {
        amountOut = amountIn.mul(mockedRate);
        IERC20(tokenOut).approve(msg.sender, amountOut);
    }

    function mockRate(uint256 newRate) external {
        mockedRate = newRate;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IStrategy.sol";

import "../helpers/FixedPoint.sol";

contract StrategyMock is IStrategy {
    using FixedPoint for uint256;

    uint256 public mockedRate;

    address public override getToken;
    uint256 public override getTotalShares;

    constructor(address _token) {
        getToken = _token;
        mockedRate = FixedPoint.ONE;
    }

    function getTokenBalance() external override view returns (uint256) {
        return mockedRate.mul(getTotalShares);
    }

    function getMetadataURI() external override pure returns (string memory) {
        return "./strategies/metadata.json";
    }

    function onJoin(uint256 amount, bytes memory) external override returns (uint256 shares) {
        shares = amount.mul(mockedRate);
        getTotalShares += shares;
    }

    function onExit(uint256 shares, bytes memory) external override returns (address, uint256) {
        getTotalShares -= shares;
        uint256 amount = shares.div(mockedRate);
        IERC20(getToken).approve(msg.sender, amount);
        return (getToken, amount);
    }

    function mockRate(uint256 newMockedRate) external {
        mockedRate = newMockedRate;
    }
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenMock is ERC20 {
    constructor (string memory symbol) ERC20(symbol, symbol) {
        // do nothing
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IPortfolio.sol";

import "../helpers/FixedPoint.sol";

contract PortfolioMock is IPortfolio {
    bool public mockedCanPerform;

    address public vault;
    uint256 public depositFee;
    uint256 public performanceFee;
    address public feeCollector;

    constructor(address _vault, uint256 _depositFee, uint256 _performanceFee, address _feeCollector) {
        vault = _vault;
        depositFee = _depositFee;
        performanceFee = _performanceFee;
        feeCollector = _feeCollector;
    }

    function mockCanPerform(bool newMockedCanPerform) external {
        mockedCanPerform = newMockedCanPerform;
    }

    function getPerformanceFee() external override view returns (uint256 fee, address collector) {
        return (performanceFee, feeCollector);
    }

    function getDepositFee() external override view returns (uint256 fee, address collector) {
        return (depositFee, feeCollector);
    }

    function canPerform(address, address, bytes32, bytes32[] memory) external override view returns (bool) {
        return mockedCanPerform;
    }

    function approveTokens(address[] memory tokens) external override {
        for(uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).approve(vault, FixedPoint.MAX_UINT256);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../vault/Vault.sol";

contract VaultMock is Vault {
    constructor (uint256 _protocolFee, address _swapConnector, address[] memory _whitelistedStrategies)
        Vault(_protocolFee, _swapConnector, _whitelistedStrategies)
    {}

    function mockApproveTokens(address portfolio, address[] memory tokens) external {
        IPortfolio(portfolio).approveTokens(tokens);
    }
}

