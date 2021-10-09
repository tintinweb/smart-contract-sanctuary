// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/ITroveLinkMultiSignatureWallet.sol";
import "./interfaces/ITroveLinkController.sol";
import "./AddressUtils.sol";

contract TroveLinkMultiSignatureWallet is ITroveLinkMultiSignatureWallet, Initializable {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    uint256 public constant MAX_COMMITTEE_MEMBER_COUNT = 11;
    uint256 public constant MIN_COMMITTEE_MEMBER_COUNT = 2;
    uint256 public constant PROPOSAL_DURATION = 24 hours;

    EnumerableSet.AddressSet private _committeeMembers;
    address private _controller;
    bool private _initialized;
    Proposal[] private _proposals;
    uint256 private _quorum;

    function getTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function controller() public view returns (address) {
        return _controller;
    }

    function initialized() public view returns (bool) {
        return _initialized;
    }

    function quorum() public view returns (uint256) {
        return _quorum;
    }

    function committeeMemberCount() external view override(ITroveLinkMultiSignatureWallet) returns (uint256) {
        return _committeeMembers.length();
    }

    function proposalCount() external view override(ITroveLinkMultiSignatureWallet) returns (uint256) {
        return _proposals.length;
    }

    function committeeMember(uint256 index_) external view override(ITroveLinkMultiSignatureWallet) returns (address) {
        return _committeeMembers.at(index_);
    }

    function proposal(
        uint256 index_
    ) external view override(ITroveLinkMultiSignatureWallet) returns (ProposalResponse memory) {
        Proposal storage proposal_ = _proposals[index_];
        EnumerableSet.AddressSet storage proposalConfirmations = proposal_.confirmations;
        uint256 confirmationsCount = proposalConfirmations.length();
        address[] memory confirmations_;
        for (uint256 i = 0; i < confirmationsCount; i++) confirmations_[i] = proposalConfirmations.at(i);
        return ProposalResponse({
            creator: proposal_.creator,
            destination: proposal_.destination,
            data: proposal_.data,
            value: proposal_.value,
            description: proposal_.description,
            createdAt: proposal_.createdAt,
            expiredAt: proposal_.expiredAt,
            confirmations: confirmations_,
            executed: proposal_.executed
        });
    }

    function addCommitteeMember(
        address committeeMember_,
        uint256 quorum_
    ) external override(ITroveLinkMultiSignatureWallet) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(_committeeMembers.length().add(1) <= MAX_COMMITTEE_MEMBER_COUNT, "Invalid committee members count");
        require(!_committeeMembers.contains(committeeMember_), "Already committee member");
        _addCommitteeMember(committeeMember_);
        _updateQuorum(quorum_);
        emit QuorumUpdated(quorum_);
        return true;
    }

    function confirmProposal(uint256 index_) external override(ITroveLinkMultiSignatureWallet) returns (bool) {
        address sender = msg.sender;
        require(_initialized, "Not initialized");
        require(_committeeMembers.contains(sender), "Invalid sender");
        require(_proposals.length > index_, "Invalid proposal index");
        Proposal storage proposal_ = _proposals[index_];
        require(!proposal_.executed, "Already executed");
        require(proposal_.expiredAt > getTimestamp(), "Expired");
        require(!proposal_.confirmations.contains(sender), "Already confirmed");
        proposal_.confirmations.add(sender);
        emit ProposalConfirmed(index_, sender);
        return true;
    }

    function createProposal(
        address destination_,
        bytes memory data_,
        string memory description_
    ) external payable override(ITroveLinkMultiSignatureWallet) returns (bool) {
        address sender = msg.sender;
        uint256 proposalValue = msg.value;
        uint256 proposalIndex = _proposals.length;
        uint256 createdAt = getTimestamp();
        uint256 expiredAt = createdAt.add(PROPOSAL_DURATION);
        require(_initialized, "Not initialized");
        require(
            _committeeMembers.contains(sender) || ITroveLinkController(_controller).isService(sender),
            "Invalid sender"
        );
        _proposals.push();
        Proposal storage proposal_ = _proposals[proposalIndex];
        proposal_.creator = sender;
        proposal_.destination = destination_;
        proposal_.data = data_;
        proposal_.description = description_;
        proposal_.value = proposalValue;
        proposal_.confirmations.add(sender);
        proposal_.createdAt = createdAt;
        proposal_.expiredAt = expiredAt;
        emit ProposalCreated(
            proposalIndex,
            sender,
            destination_,
            data_,
            proposalValue,
            description_,
            createdAt,
            expiredAt
        );
        emit ProposalConfirmed(proposalIndex, sender);
        return true;
    }

    function executeProposal(
        uint256 index_
    ) external override(ITroveLinkMultiSignatureWallet) returns (bytes memory result) {
        require(_initialized, "Not initialized");
        require(_proposals.length > index_, "Invalid proposal index");
        Proposal storage proposal_ = _proposals[index_];
        require(!proposal_.executed, "Already executed");
        require(proposal_.expiredAt > getTimestamp(), "Expired");
        require(proposal_.confirmations.length() >= _quorum, "Not enough confirmations");
        result = proposal_.destination.functionCallWithValue(
            proposal_.data,
            proposal_.value,
            "Proposal execution error"
        );
        proposal_.executed = true;
        emit ProposalExecuted(index_, msg.sender);
    }

    function removeCommitteeMember(
        address committeeMember_,
        uint256 quorum_
    ) external override(ITroveLinkMultiSignatureWallet) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(_committeeMembers.length().sub(1) >= MIN_COMMITTEE_MEMBER_COUNT, "Invalid committee members count");
        require(_committeeMembers.contains(committeeMember_), "Invalid committee member");
        _committeeMembers.remove(committeeMember_);
        _updateQuorum(quorum_);
        emit CommitteeMemberRemoved(committeeMember_);
        emit QuorumUpdated(quorum_);
        return true;
    }

    function transferCommitteeMember(
        address committeeMember_,
        address newCommitteeMember_
    ) external override(ITroveLinkMultiSignatureWallet) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        require(_committeeMembers.contains(committeeMember_), "Invalid committee member");
        require(!_committeeMembers.contains(newCommitteeMember_), "Invalid new committee member");
        _committeeMembers.remove(committeeMember_);
        _committeeMembers.add(newCommitteeMember_);
        emit CommitteeMemberTransfered(committeeMember_, newCommitteeMember_);
        return true;
    } 

    function updateQuorum(uint256 quorum_) external override(ITroveLinkMultiSignatureWallet) returns (bool) {
        require(_initialized, "Not initialized");
        require(msg.sender == _controller, "Invalid sender");
        _updateQuorum(quorum_);
        emit QuorumUpdated(quorum_);
        return true;
    }

    function initialize(
        address controller_,
        uint256 quorum_,
        address[] memory committeeMembers_
    ) public initializer() virtual returns (bool) {
        require(!_initialized, "Already initialized");
        require(controller_ != address(0), "Controller is zero address");
        _controller = controller_;
        for (uint256 i = 0; i < committeeMembers_.length; i++) {
            _addCommitteeMember(committeeMembers_[i]);
        }
        uint256 committeeMembersCount = _committeeMembers.length();
        require(
            committeeMembersCount <= MAX_COMMITTEE_MEMBER_COUNT &&
            committeeMembersCount >= MIN_COMMITTEE_MEMBER_COUNT,
            "Invalid committee members count"
        );
        _updateQuorum(quorum_);
        _initialized = true;
        emit Initialized(controller_, quorum_, committeeMembers_);
        return true;
    }

    function _addCommitteeMember(address committeeMember_) private {
        require(committeeMember_ != address(0), "Committee member is zero address");
        if (_committeeMembers.add(committeeMember_)) emit CommitteeMemberAdded(committeeMember_);
    }

    function _updateQuorum(uint256 quorum_) private {
        uint256 committeeCount = _committeeMembers.length();
        require(quorum_ >= MIN_COMMITTEE_MEMBER_COUNT && quorum_ <= committeeCount, "Invalid quorum");
        _quorum = quorum_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";

interface ITroveLinkMultiSignatureWallet {
    // Structs
    struct Proposal {
        address creator;
        address destination;
        bytes data;
        uint256 value;
        string description;
        uint256 createdAt;
        uint256 expiredAt;
        EnumerableSet.AddressSet confirmations;
        bool executed;
    }

    struct ProposalResponse {
        address creator;
        address destination;
        bytes data;
        uint256 value;
        string description;
        uint256 createdAt;
        uint256 expiredAt;
        address[] confirmations;
        bool executed;
    }

    // External view functions
    function committeeMemberCount() external view returns (uint256);
    function proposalCount() external view returns (uint256);
    function committeeMember(uint256 index_) external view returns (address);
    function proposal(uint256 index_) external view returns (ProposalResponse memory);

    // Events
    event Initialized(address controller_, uint256 quorum_, address[] committeeMembers_);
    event CommitteeMemberAdded(address committeeMember_);
    event CommitteeMemberRemoved(address committeeMember_);
    event CommitteeMemberTransfered(address committeeMember_, address newCommitteeMember_);
    event ProposalCreated(
        uint256 index_,
        address indexed creator_,
        address indexed destination_,
        bytes data_,
        uint256 value_,
        string description_,
        uint256 createdAt_,
        uint256 expiredAt_
    );
    event ProposalConfirmed(uint256 indexed index_, address indexed committeeMember_);
    event ProposalExecuted(uint256 index_, address indexed sender_);
    event QuorumUpdated(uint256 quorum_);

    // External functions
    function addCommitteeMember(address committeeMember_, uint256 quorum_) external returns (bool);
    function confirmProposal(uint256 index_) external returns (bool);
    function createProposal(
        address destination_,
        bytes memory data_,
        string memory description_
    ) external payable returns (bool);
    function executeProposal(uint256 index_) external returns (bytes memory result);
    function removeCommitteeMember(address committeeMember_, uint256 quorum_) external returns (bool);
    function transferCommitteeMember(address committeeMember_, address newCommitteeMember_) external returns (bool);
    function updateQuorum(uint256 quorum_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface ITroveLinkController {
    // External view functions
    function serviceCount() external view returns (uint256);
    function isService(address service_) external view returns (bool);
    function service(uint256 index_) external view returns (address);

    // Events
    event Executed(address destination_, bytes data_, string description_, uint256 value_);
    event ServiceAdded(address service_);
    event ServiceRemoved(address service_);
    event VotingUpdated(address voting_);

    // External functions
    function addService(address service_) external returns (bool);
    function execute(
        address destination_,
        bytes memory data_,
        string memory description_
    ) external payable returns (bytes memory result);
    function removeService(address service_) external returns (bool);
    function updateVoting(address voting_) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

library AddressUtils {
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "AddressUtils: insufficient value");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        require(b > 0, errorMessage);
        return a % b;
    }
}