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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./utils/AccessControl.sol";
import "./interfaces/IBridgeHandler.sol";

/**
    @title Facilitates deposits, creation and voting of deposit proposals, and deposit executions.
    @author Ryuhei Matsuda
 */
contract Bridge is Pausable, AccessControl {
    // Limit relayers number because proposal can fit only so much votes
    uint256 public constant MAX_RELAYERS = 128;

    address public handler;
    uint128 public relayerThreshold;
    uint40 public expiry;
    uint256 public fee;

    enum ProposalStatus {
        Inactive,
        Active,
        Passed,
        Executed,
        Cancelled
    }

    struct Proposal {
        ProposalStatus status;
        uint128 yesVotes; // bitmap, 128 maximum votes
        uint8 yesVotesTotal;
        uint40 proposedBlock; // 1099511627775 maximum block
    }

    // destinationChainID => number of deposits
    mapping(uint256 => uint64) public depositCounts;
    // sourceChainID => depositNonce => dataHash => Proposal
    mapping(uint256 => mapping(uint64 => mapping(bytes32 => Proposal)))
        private _proposals;

    event RelayerThresholdChanged(uint128 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event Deposit(
        uint256 indexed destinationChainID,
        address indexed recipient,
        uint64 depositNonce,
        uint256 amount
    );
    event ProposalEvent(
        uint256 originChainID,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint256 originChainID,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 dataHash
    );
    event HandlerSet(address indexed handler);
    event FeeChanged(uint256 fee);

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "sender doesn't have admin role"
        );
        _;
    }

    modifier onlyAdminOrRelayer() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(RELAYER_ROLE, msg.sender),
            "sender is not relayer or admin"
        );
        _;
    }

    modifier onlyRelayers() {
        require(
            hasRole(RELAYER_ROLE, msg.sender),
            "sender doesn't have relayer role"
        );
        _;
    }

    function _relayerBit(address _relayer) private view returns (uint128) {
        return
            uint128(
                1 <<
                    (AccessControl.getRoleMemberIndex(RELAYER_ROLE, _relayer) -
                        1)
            );
    }

    function _hasVoted(Proposal memory _proposal, address _relayer)
        private
        view
        returns (bool)
    {
        return (_relayerBit(_relayer) & uint256(_proposal.yesVotes)) > 0;
    }

    /**
        @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
        creates and grants {initialRelayers} the relayer role.
        @param _initialRelayers Addresses that should be initially granted the relayer role.
        @param _initialRelayerThreshold Number of votes needed for a deposit proposal to be considered passed.
        @param _fee Fee to bridge token.
        @param _expiry bridge expire block amount 
     */
    constructor(
        address[] memory _initialRelayers,
        uint128 _initialRelayerThreshold,
        uint256 _fee,
        uint40 _expiry
    ) {
        relayerThreshold = _initialRelayerThreshold;
        fee = _fee;
        expiry = _expiry;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i; i < _initialRelayers.length; i++) {
            grantRole(RELAYER_ROLE, _initialRelayers[i]);
        }
    }

    /**
        @notice Returns true if {relayer} has voted on {destNonce} {dataHash} proposal.
        @notice Naming left unchanged for backward compatibility.
        @param _chainId sourceChainID of the proposal.
        @param _depositNonce depositNonce of the proposal.
        @param _dataHash Hash of data to be provided when deposit proposal is executed.
        @param _relayer Address to check.
     */
    function hasVotedOnProposal(
        uint256 _chainId,
        uint64 _depositNonce,
        bytes32 _dataHash,
        address _relayer
    ) external view returns (bool) {
        return
            _hasVoted(_proposals[_chainId][_depositNonce][_dataHash], _relayer);
    }

    /**
        @notice Returns true if {relayer} has the relayer role.
        @param _relayer Address to check.
     */
    function isRelayer(address _relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, _relayer);
    }

    /**
        @notice Removes admin role from {msg.sender} and grants it to {newAdmin}.
        @notice Only callable by an address that currently has the admin role.
        @param _newAdmin Address that admin role will be granted to.
     */
    function renounceAdmin(address _newAdmin) external onlyAdmin {
        require(msg.sender != _newAdmin, "Cannot renounce oneself");
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
        @notice Pauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminPauseTransfers() external onlyAdmin {
        _pause();
    }

    /**
        @notice Unpauses deposits, proposal creation and voting, and deposit executions.
        @notice Only callable by an address that currently has the admin role.
     */
    function adminUnpauseTransfers() external onlyAdmin {
        _unpause();
    }

    /**
        @notice Modifies the number of votes required for a proposal to be considered passed.
        @notice Only callable by an address that currently has the admin role.
        @param _newThreshold Value {_relayerThreshold} will be changed to.
        @notice Emits {RelayerThresholdChanged} event.
     */
    function adminChangeRelayerThreshold(uint128 _newThreshold)
        external
        onlyAdmin
    {
        relayerThreshold = _newThreshold;
        emit RelayerThresholdChanged(_newThreshold);
    }

    /**
        @notice Grants {relayerAddress} the relayer role.
        @notice Only callable by an address that currently has the admin role, which is
                checked in grantRole().
        @param _relayerAddress Address of relayer to be added.
        @notice Emits {RelayerAdded} event.
     */
    function adminAddRelayer(address _relayerAddress) external {
        require(
            !hasRole(RELAYER_ROLE, _relayerAddress),
            "addr already has relayer role!"
        );
        require(totalRelayers() < MAX_RELAYERS, "relayers limit reached");
        grantRole(RELAYER_ROLE, _relayerAddress);
        emit RelayerAdded(_relayerAddress);
    }

    /**
        @notice Removes relayer role for {relayerAddress}.
        @notice Only callable by an address that currently has the admin role, which is
                checked in revokeRole().
        @param _relayerAddress Address of relayer to be removed.
        @notice Emits {RelayerRemoved} event.
     */
    function adminRemoveRelayer(address _relayerAddress) external {
        require(
            hasRole(RELAYER_ROLE, _relayerAddress),
            "addr doesn't have relayer role!"
        );
        revokeRole(RELAYER_ROLE, _relayerAddress);
        emit RelayerRemoved(_relayerAddress);
    }

    /**
        @notice Set handler address.
        @param _handler Address of handler resource will be set for.
     */
    function adminSetHandler(address _handler) external onlyAdmin {
        require(_handler != address(0), "handler cannot be zero!");
        handler = _handler;
        emit HandlerSet(_handler);
    }

    /**
        @notice Returns a proposal.
        @param _originChainID Chain ID deposit originated from.
        @param _depositNonce ID of proposal generated by proposal's origin Bridge contract.
        @param _dataHash Hash of data to be provided when deposit proposal is executed.
     */
    function getProposal(
        uint256 _originChainID,
        uint64 _depositNonce,
        bytes32 _dataHash
    ) external view returns (Proposal memory) {
        return _proposals[_originChainID][_depositNonce][_dataHash];
    }

    /**
        @notice Returns total relayers number.
        @notice Added for backwards compatibility.
     */
    function totalRelayers() public view returns (uint256) {
        return AccessControl.getRoleMemberCount(RELAYER_ROLE);
    }

    /**
        @notice Changes deposit fee.
        @notice Only callable by admin.
        @param _newFee Value {_fee} will be updated to.
     */
    function adminChangeFee(uint256 _newFee) external onlyAdmin {
        require(fee != _newFee, "Current fee is equal to new fee");
        fee = _newFee;
        emit FeeChanged(_newFee);
    }

    /**
        @notice Initiates a transfer using a specified handler contract.
        @notice Only callable when Bridge is not paused.
        @param _destinationChainID ID of chain deposit will be bridged to.
        @param _recipient Address to receive.
        @param _amount Token amount to deposit.
        @notice Emits {Deposit} event.
     */
    function deposit(
        uint256 _destinationChainID,
        address _recipient,
        uint256 _amount
    ) external payable whenNotPaused {
        require(msg.value == fee, "Incorrect fee supplied");
        require(_amount > 0, "Invalid amount");
        require(_destinationChainID != block.chainid, "Invalid chainid");
        require(_recipient != address(0), "Invalid recipient");

        uint64 depositNonce = ++depositCounts[_destinationChainID];

        IBridgeHandler(handler).deposit(
            _destinationChainID,
            depositNonce,
            msg.sender,
            _amount,
            _recipient
        );

        emit Deposit(_destinationChainID, _recipient, depositNonce, _amount);
    }

    /**
        @notice When called, {msg.sender} will be marked as voting in favor of proposal.
        @notice Only callable by relayers when Bridge is not paused.
        @param _chainID ID of chain deposit originated from.
        @param _depositNonce ID of deposited generated by origin Bridge contract.
        @param _dataHash Hash of data provided when deposit was made.
        @notice Proposal must not have already been passed or executed.
        @notice {msg.sender} must not have already voted on proposal.
        @notice Emits {ProposalEvent} event with status indicating the proposal status.
        @notice Emits {ProposalVote} event.
     */
    function voteProposal(
        uint256 _chainID,
        uint64 _depositNonce,
        bytes32 _dataHash
    ) external onlyRelayers whenNotPaused {
        Proposal storage proposal = _proposals[_chainID][_depositNonce][
            _dataHash
        ];
        require(
            uint8(proposal.status) <= 1,
            "proposal already passed/executed/cancelled"
        );
        require(!_hasVoted(proposal, msg.sender), "relayer already voted");

        if (proposal.status == ProposalStatus.Inactive) {
            proposal.status = ProposalStatus.Active;
            proposal.proposedBlock = uint40(block.number); // Overflow is desired.

            emit ProposalEvent(
                _chainID,
                _depositNonce,
                ProposalStatus.Active,
                _dataHash
            );
        } else if (uint40(block.number - proposal.proposedBlock) > expiry) {
            // if the number of blocks that has passed since this proposal was
            // submitted exceeds the expiry threshold set, cancel the proposal
            proposal.status = ProposalStatus.Cancelled;

            emit ProposalEvent(
                _chainID,
                _depositNonce,
                ProposalStatus.Cancelled,
                _dataHash
            );
        }

        if (proposal.status != ProposalStatus.Cancelled) {
            proposal.yesVotes = proposal.yesVotes | _relayerBit(msg.sender);
            proposal.yesVotesTotal += 1;

            emit ProposalVote(
                _chainID,
                _depositNonce,
                proposal.status,
                _dataHash
            );

            // Finalize if _relayerThreshold has been reached
            if (proposal.yesVotesTotal >= relayerThreshold) {
                proposal.status = ProposalStatus.Passed;

                emit ProposalEvent(
                    _chainID,
                    _depositNonce,
                    ProposalStatus.Passed,
                    _dataHash
                );
            }
        }
    }

    /**
        @notice Cancels a deposit proposal that has not been executed yet.
        @notice Only callable by relayers when Bridge is not paused.
        @param _chainID ID of chain deposit originated from.
        @param _depositNonce ID of deposited generated by origin Bridge contract.
        @param _dataHash Hash of data originally provided when deposit was made.
        @notice Proposal must be past expiry threshold.
        @notice Emits {ProposalEvent} event with status {Cancelled}.
     */
    function cancelProposal(
        uint256 _chainID,
        uint64 _depositNonce,
        bytes32 _dataHash
    ) public onlyAdminOrRelayer {
        Proposal storage proposal = _proposals[_chainID][_depositNonce][
            _dataHash
        ];
        ProposalStatus currentStatus = proposal.status;

        require(
            currentStatus == ProposalStatus.Active ||
                currentStatus == ProposalStatus.Passed,
            "Proposal cannot be cancelled"
        );
        require(
            uint40(block.number - proposal.proposedBlock) > expiry,
            "Proposal not at expiry threshold"
        );

        proposal.status = ProposalStatus.Cancelled;

        emit ProposalEvent(
            _chainID,
            _depositNonce,
            ProposalStatus.Cancelled,
            _dataHash
        );
    }

    /**
        @notice Executes a deposit proposal that is considered passed using a specified handler contract.
        @notice Only callable by relayers when Bridge is not paused.
        @param _chainID ID of chain deposit originated from.
        @param _depositNonce ID of deposited generated by origin Bridge contract.
        @param _amount Token amount to deposit.
        @param _recipient Address to receive.
        @notice Proposal must have Passed status.
        @notice Hash of {data} must equal proposal's {dataHash}.
        @notice Emits {ProposalEvent} event with status {Executed}.
     */
    function executeProposal(
        uint256 _chainID,
        uint64 _depositNonce,
        uint256 _amount,
        address _recipient
    ) external onlyRelayers whenNotPaused {
        bytes32 dataHash = keccak256(abi.encodePacked(_amount, _recipient));
        Proposal storage proposal = _proposals[_chainID][_depositNonce][
            dataHash
        ];

        require(
            proposal.status == ProposalStatus.Passed,
            "Proposal must have Passed status"
        );

        proposal.status = ProposalStatus.Executed;

        IBridgeHandler(handler).executeProposal(_amount, _recipient);

        emit ProposalEvent(
            _chainID,
            _depositNonce,
            ProposalStatus.Executed,
            dataHash
        );
    }

    /**
        @param _addrs Array of addresses to transfer {amounts} to.
        @param _amounts Array of amonuts to transfer to {addrs}.
     */
    function transferFunds(
        address[] calldata _addrs,
        uint256[] calldata _amounts
    ) external onlyAdmin {
        for (uint256 i = 0; i < _addrs.length; i++) {
            (bool success, ) = _addrs[i].call{value: _amounts[i]}("");
            require(success, "transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
    @title Interface for BridgeHandler contracts .
    @author Ryuhei Matsuda
 */
interface IBridgeHandler {
    /**
        @param _destinationChainID Chain ID deposit is expected to be bridged to.
        @param _depositNonce This value is generated as an ID by the Bridge contract.
        @param _depositer Address of account making the deposit in the Bridge contract.
        @param _amount Token amount to deposit.
        @param _recipient Address to receive.
     */
    function deposit(
        uint256 _destinationChainID,
        uint64 _depositNonce,
        address _depositer,
        uint256 _amount,
        address _recipient
    ) external;

    /**
        @param _amount Token amount to deposit.
        @param _recipient Address to receive.
     */
    function executeProposal(uint256 _amount, address _recipient) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// This is adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/access/AccessControl.sol
// The only difference is added getRoleMemberIndex(bytes32 role, address account) function.

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the index of the account that have `role`.
     */
    function getRoleMemberIndex(bytes32 role, address account)
        public
        view
        returns (uint256)
    {
        return
            _roles[role].members._inner._indexes[
                bytes32(uint256(uint160(account)))
            ];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}