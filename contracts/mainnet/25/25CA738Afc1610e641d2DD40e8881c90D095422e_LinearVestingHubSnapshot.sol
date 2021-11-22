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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Proxied} from "./vendor/hardhat-deploy/Proxied.sol";
import {ILinearVestingHub} from "./interfaces/ILinearVestingHub.sol";
import {Vesting} from "./structs/SVesting.sol";
import {
    _getVestedTkns,
    _getTknMaxWithdraw
} from "./functions/VestingFormulaFunctions.sol";

interface IToken {
    function getCurrentVotes(address account_) external view returns (uint96);
}

interface ITokenSale {
    function gelLockedByWhale(address whale_) external view returns (uint256);
}

contract LinearVestingHubSnapshot is Proxied {
    using EnumerableSet for EnumerableSet.AddressSet;

    // solhint-disable-next-line var-name-mixedcase
    ILinearVestingHub public immutable LINEAR_VESTING_HUB;

    // solhint-disable-next-line var-name-mixedcase
    ITokenSale public immutable TOKEN_SALE;

    // delegate => List of receivers who delegated their tokens to delegate
    mapping(address => EnumerableSet.AddressSet) internal _receiversByDelegate;
    // receivers => delegate
    mapping(address => address) public delegateByReceiver;

    modifier onlyProxyAdminOrReceiver(address _receiver) {
        require(
            msg.sender == _proxyAdmin() || msg.sender == _receiver,
            "LinearVestingHubSnapshot:: only owner or receiver"
        );
        _;
    }

    constructor(ILinearVestingHub linearVestingHub_, ITokenSale tokenSale_) {
        LINEAR_VESTING_HUB = linearVestingHub_;
        TOKEN_SALE = tokenSale_;
    }

    /// @notice Adds a vestedTokenOwners delegation to a delegate
    /// @param vestedTokenOwner_ Account to that has vested tokens which wants to add its delegation
    /// @param delegate_ Account which should receive the delegated TOKEN voting power
    function setDelegate(address vestedTokenOwner_, address delegate_)
        external
        onlyProxyAdminOrReceiver(vestedTokenOwner_)
    {
        require(
            delegate_ != address(0),
            "LinearVestingHubSnapshot:: cannot remove delegate_"
        );

        // Get tokens locked in LinearVestingHub
        uint256 nextVestingId = LINEAR_VESTING_HUB.nextVestingIdByReceiver(
            vestedTokenOwner_
        );

        uint256 amount;
        for (uint256 i = 0; i < nextVestingId; i++) {
            amount += getVestingBalance(vestedTokenOwner_, i);
        }

        require(
            amount > 0,
            "LinearVestingHubSnapshot:: no vested tokens avail for delegation"
        );

        // Check if receiver already delegated, if so, remove old delegation
        address oldDelegate = delegateByReceiver[vestedTokenOwner_];
        if (oldDelegate != address(0)) {
            // Remove old delegate
            _receiversByDelegate[oldDelegate].remove(vestedTokenOwner_);
            delete delegateByReceiver[vestedTokenOwner_];
        }

        // Add new delegation
        _receiversByDelegate[delegate_].add(vestedTokenOwner_);
        delegateByReceiver[vestedTokenOwner_] = delegate_;
    }

    /// @notice Removes a vestedTokenOwners delegation
    /// @param vestedTokenOwner_ Account to that has vested tokens which wants to remove its delegation
    function removeDelegate(address vestedTokenOwner_)
        external
        onlyProxyAdminOrReceiver(vestedTokenOwner_)
    {
        address delegate = delegateByReceiver[vestedTokenOwner_];
        require(
            delegate != address(0),
            "LinearVestingHubSnapshot:: No delegate set"
        );
        require(
            _receiversByDelegate[delegate].contains(vestedTokenOwner_),
            "LinearVestingHubSnapshot:: Can only have one receiver mapped to delegate"
        );

        // Remove delegation
        delete delegateByReceiver[vestedTokenOwner_];
        _receiversByDelegate[delegate].remove(vestedTokenOwner_);
    }

    /// @notice Helper func used in TOKEN Snapshot voting to derive the total voting power of an address
    /// @param account_ Account to check total TOKEN voting power for
    function balanceOf(address account_)
        external
        view
        returns (uint256 balance)
    {
        // 1. Add tokens delegated in Vesting Hub
        balance = getVestingHubDelegations(account_);

        // 2. Add tokens delegated in TOKEN token contract
        balance += IToken(address(LINEAR_VESTING_HUB.TOKEN())).getCurrentVotes(
            account_
        );

        // 3. Add whale pool balance
        balance += TOKEN_SALE.gelLockedByWhale(account_);
    }

    /// @notice Get total amount of TOKEN delegated to an account_ on Linear Vesting Hub
    /// @param account_ Account to check total delegated TOKEN voting power in LVH
    function getVestingHubDelegations(address account_)
        public
        view
        returns (uint256 balance)
    {
        address[] memory receivers = getReceiversByDelegate(account_);

        if (receivers.length > 0) {
            for (uint256 i; i < receivers.length; i++) {
                address receiver = receivers[i];
                uint256 nextVestingId = LINEAR_VESTING_HUB
                    .nextVestingIdByReceiver(receiver);

                for (uint256 j = 0; j < nextVestingId; j++) {
                    balance += getVestingBalance(receiver, j);
                }
            }
        }
    }

    /// @notice Helper func to get all receivers that delegated to a certain address
    /// @param delegate_ Delegate for locked receiver tokens
    function getReceiversByDelegate(address delegate_)
        public
        view
        returns (address[] memory)
    {
        uint256 length = _receiversByDelegate[delegate_].length();
        address[] memory receivers = new address[](length);

        for (uint256 i; i < length; i++) {
            receivers[i] = _receiversByDelegate[delegate_].at(i);
        }
        return receivers;
    }

    function getVestingBalance(address receiver_, uint256 vestingId_)
        public
        view
        returns (uint256)
    {
        try
            LINEAR_VESTING_HUB.vestingsByReceiver(receiver_, vestingId_)
        returns (Vesting memory vesting) {
            return vesting.receiver != address(0) ? vesting.tokenBalance : 0;
        } catch {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

function _getVestedTkns(
    uint256 tknBalance_,
    uint256 tknWithdrawn_,
    uint256 startDate_,
    uint256 duration_
) view returns (uint256) {
    if (block.timestamp < startDate_) return 0;
    if (block.timestamp >= startDate_ + duration_)
        return tknBalance_ + tknWithdrawn_;
    return
        ((tknBalance_ + tknWithdrawn_) * (block.timestamp - startDate_)) /
        duration_;
}

function _getTknMaxWithdraw(
    uint256 tknBalance_,
    uint256 tknWithdrawn_,
    uint256 startDate_,
    uint256 cliffDuration_,
    uint256 duration_
) view returns (uint256) {
    // Vesting has not started and/or cliff has not passed
    if (block.timestamp < startDate_ + cliffDuration_) return 0;

    uint256 vestedTkns = _getVestedTkns(
        tknBalance_,
        tknWithdrawn_,
        startDate_,
        duration_
    );

    return vestedTkns > tknWithdrawn_ ? vestedTkns - tknWithdrawn_ : 0;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Vesting} from "../structs/SVesting.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILinearVestingHub {
    // solhint-disable-next-line func-name-mixedcase
    function TOKEN() external view returns (IERC20);

    function nextVestingIdByReceiver(address receiver_)
        external
        view
        returns (uint256);

    function vestingsByReceiver(address receiver_, uint256 id_)
        external
        view
        returns (Vesting memory);

    function totalWithdrawn() external view returns (uint256);

    function isReceiver(address receiver_) external view returns (bool);

    function receiverAt(uint256 index_) external view returns (address);

    function receivers() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

struct Vesting {
    uint8 id;
    address receiver;
    uint256 tokenBalance; // remaining token balance
    uint256 withdrawnTokens; //
    uint256 startTime; // vesting start time.
    uint256 cliffDuration; // lockup time.
    uint256 duration;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(
                0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103
            )
        }
    }
}