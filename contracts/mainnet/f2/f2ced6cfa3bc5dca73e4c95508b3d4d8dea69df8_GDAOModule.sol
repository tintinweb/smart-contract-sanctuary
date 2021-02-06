/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma experimental ABIEncoderV2;

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol


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

// File: contracts/GVoting.sol

pragma solidity ^0.6.0;

/**
 * @dev An interface to extend gTokens with voting delegation capabilities.
 *      See GTokenType3.sol for further documentation.
 */
interface GVoting
{
	// view functions
	function votes(address _candidate) external view returns (uint256 _votes);
	function candidate(address _voter) external view returns (address _candidate);

	// open functions
	function setCandidate(address _newCandidate) external;

	// emitted events
	event ChangeCandidate(address indexed _voter, address indexed _oldCandidate, address indexed _newCandidate);
	event ChangeVotes(address indexed _candidate, uint256 _oldVotes, uint256 _newVotes);
}

// File: contracts/modules/Math.sol

pragma solidity ^0.6.0;

/**
 * @dev This library implements auxiliary math definitions.
 */
library Math
{
	function _min(uint256 _amount1, uint256 _amount2) internal pure returns (uint256 _minAmount)
	{
		return _amount1 < _amount2 ? _amount1 : _amount2;
	}
}

// File: contracts/interop/Gnosis.sol

pragma solidity ^0.6.0;

interface Enum
{
	enum Operation { Call, DelegateCall }
}

interface OwnerManager
{
	function getOwners() external view returns (address[] memory _owners);
	function isOwner(address _owner) external view returns (bool _isOwner);
}

interface ModuleManager
{
	function execTransactionFromModule(address _to, uint256 _value, bytes calldata _data, Enum.Operation _operation) external returns (bool _success);
}

interface Safe is OwnerManager, ModuleManager
{
}

// File: contracts/modules/Multisig.sol

pragma solidity ^0.6.0;


/**
 * @dev This library abstracts the Gnosis Safe multisig operations.
 */
library Multisig
{
	/**
	 * @dev Lists the current owners/signers of a Gnosis Safe multisig.
	 * @param _safe The Gnosis Safe contract address.
	 * @return _owners The list of current owners/signers of the multisig.
	 */
	function _getOwners(address _safe) internal view returns (address[] memory _owners)
	{
		return Safe(_safe).getOwners();
	}

	/**
	 * @dev Checks if an address is a signer of the Gnosis Safe multisig.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _owner The address to check if it is a owner/signer of the multisig.
	 * @return _isOnwer A boolean indicating if the provided address is
	 *                  indeed a signer.
	 */
	function _isOwner(address _safe, address _owner) internal view returns (bool _isOnwer)
	{
		return Safe(_safe).isOwner(_owner);
	}

	/**
	 * @dev Adds a signer to the multisig by calling the Gnosis Safe function
	 *      addOwnerWithThreshold() via the execTransactionFromModule()
	 *      primitive.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _owner The owner/signer to be added to the multisig.
	 * @param _threshold The new threshold (minimum number of signers) to be set.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _addOwnerWithThreshold(address _safe, address _owner, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("addOwnerWithThreshold(address,uint256)", _owner, _threshold);
		return _execTransactionFromModule(_safe, _data);
	}

	/**
	 * @dev Removes a signer to the multisig by calling the Gnosis Safe function
	 *      removeOwner() via the execTransactionFromModule()
	 *      primitive.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _prevOwner The previous owner/signer in the multisig linked list.
	 * @param _owner The owner/signer to be added to the multisig.
	 * @param _threshold The new threshold (minimum number of signers) to be set.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _removeOwner(address _safe, address _prevOwner, address _owner, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("removeOwner(address,address,uint256)", _prevOwner, _owner, _threshold);
		return _execTransactionFromModule(_safe, _data);
	}

	/**
	 * @dev Changes minimum number of signers of the multisig by calling the
	 *      Gnosis Safe function changeThreshold() via the
	 *      execTransactionFromModule() primitive.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _threshold The new threshold (minimum number of signers) to be set.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _changeThreshold(address _safe, uint256 _threshold) internal returns (bool _success)
	{
		bytes memory _data = abi.encodeWithSignature("changeThreshold(uint256)", _threshold);
		return _execTransactionFromModule(_safe, _data);
	}

	/**
	 * @dev Calls the execTransactionFrom() module primitive handling
	 *      possible errors.
	 * @param _safe The Gnosis Safe contract address.
	 * @param _data The encoded data describing the function signature and
	 *              argument values.
	 * @return _success A boolean indicating if the operation succeded.
	 */
	function _execTransactionFromModule(address _safe, bytes memory _data) internal returns (bool _success)
	{
		try Safe(_safe).execTransactionFromModule(_safe, 0, _data, Enum.Operation.Call) returns (bool _result) {
			return _result;
		} catch (bytes memory /* _data */) {
			return false;
		}
	}
}

// File: contracts/GDAOModule.sol

pragma solidity ^0.6.0;






/**
 * @notice This contract implements a Gnosis Safe extension module to allow
 *         replacing the multisig signers using the 1-level delegation voting
 *         provided by stkGRO. Every 24 hours, around 0 UTC, a new voting round
 *         starts and the candidates appointed in the previous round can become
 *         the signers of the multisig. This module allows up to 7 signers with
 *         a minimum of 4 signatures to take any action. There are 3 consecutive
 *         phases in the process, each occuring at a 24 hour voting round. In
 *         the first round, stkGRO holders can delegate their votes (stkGRO
 *         balance) to candidates; vote balance is frozen by the end of that
 *         round. In the second round, most voted candidates can appoint
 *         themselves to become signers, replacing a previous candidate from the
 *         current list. In the third and final round, the list of appointed
 *         candidates is set as the list of signers to the multisig. The 3
 *         phases overlap so that, when one list of signers is being set, the
 *         list for the next day is being build, and yet the votes for
 *         subsequent day are being counted. See GVoting and GTokenType3 for
 *         further documentation.
 */
contract GDAOModule is ReentrancyGuard
{
	using SafeMath for uint256;
	using EnumerableSet for EnumerableSet.AddressSet;

	string public constant NAME = "GrowthDeFi DAO Module";
	string public constant VERSION = "0.0.2";

	uint256 constant VOTING_ROUND_INTERVAL = 1 days;

	uint256 constant SIGNING_OWNERS = 7;
	uint256 constant SIGNING_THRESHOLD = 4;

	address public immutable safe;
	address public immutable votingToken;

	uint256 private votingRound;
	EnumerableSet.AddressSet private candidates;

	bool public pendingChanges;

	/**
	 * @dev Restricts execution to Externally Owned Accounts (EOA).
	 */
	modifier onlyEOA()
	{
		require(tx.origin == msg.sender, "not an externally owned account");
		_;
	}

	/**
	 * @dev Constructor for the Gnosis Safe extension module.
	 * @param _safe The Gnosis Safe multisig contract address.
	 * @param _votingToken The ERC-20 token used for voting (stkGRO).
	 */
	constructor (address _safe, address _votingToken) public
	{
		safe = _safe;
		votingToken = _votingToken;

		votingRound = _currentVotingRound();

		address[] memory _owners = Multisig._getOwners(_safe);
		uint256 _ownersCount = _owners.length;
		for (uint256 _index = 0; _index < _ownersCount; _index++) {
			address _owner = _owners[_index];
			bool _success = candidates.add(_owner);
			assert(_success);
		}

		pendingChanges = false;
	}

	/**
	 * @notice Returns the current voting round. This value gets incremented
	 *         every 24 hours.
	 * @return _votingRound The current voting round.
	 */
	function currentVotingRound() public view returns (uint256 _votingRound)
	{
		return _currentVotingRound();
	}

	/**
	 * @notice Returns the approximate number of seconds remaining until a
	 *         a new voting round starts.
	 * @return _timeToNextVotingRound The number of seconds to the next
	 *                                voting round.
	 */
	function timeToNextVotingRound() public view returns (uint256 _timeToNextVotingRound)
	{
		return now.div(VOTING_ROUND_INTERVAL).add(1).mul(VOTING_ROUND_INTERVAL).sub(now);
	}

	/**
	 * @notice Returns a boolean indicating whether or not turnOver()
	 *         can be called to apply pending changes.
	 * @return _available Returns true if a new round has started and there
	 *                    are pending changes.
	 */
	function turnOverAvailable() public view returns (bool _available)
	{
		return _turnOverAvailable();
	}

	/**
	 * @notice Returns the current number of appointed candidates in the list.
	 * @return _count The size of the appointed candidate list.
	 */
	function candidateCount() public view returns (uint256 _count)
	{
		return candidates.length();
	}

	/**
	 * @notice Returns the i-th appointed candidates on the list.
	 * @return _candidate The address of an stkGRO holder appointed to the
	 *                    candidate list.
	 */
	function candidateAt(uint256 _index) public view returns (address _candidate)
	{
		return candidates.at(_index);
	}

	/**
	 * @notice Appoints as candidate to be a signer for the multisig,
	 *         starting on the next voting round. Only the actual candidate
	 *         can appoint himself and he must have a vote count large
	 *         enough to kick someone else from the appointed candidate list.
	 *         No that the first candidate appointment on a round may update
	 *         the multisig signers with the list from the previous round, if
	 *         there are changes.
	 */
	function appointCandidate() public onlyEOA nonReentrant
	{
		address _candidate = msg.sender;
		if (_turnOverAvailable()) _turnOver();
		require(!candidates.contains(_candidate), "already eligible");
		require(_appointCandidate(_candidate), "not eligible");
	}

	/**
	 * @notice Updates the multisig signers with the appointed candidade
	 *         list from the previous round. Anyone can call this method
	 *         as soon as a new voting round starts. See hasPendingTurnOver()
	 *         to figure out whether or not there are pending changes to
	 *         be applied to the multisig.
	 */
	function turnOver() public onlyEOA nonReentrant
	{
		require(_turnOverAvailable(), "not available");
		_turnOver();
	}

	/**
	 * @dev Finds the appointed candidates with the least amount of votes
	 *      for the current list. This is used to find the candidate to be
	 *      removed when a new candidate with more votes is appointed.
	 * @return _leastVoted The address of the least voted appointed candidate.
	 * @return _leastVotes The actual number of votes for the least voted
	 *                     appointed candidate.
	 */
	function _findLeastVoted() internal view returns (address _leastVoted, uint256 _leastVotes)
	{
		_leastVoted = address(0);
		_leastVotes = uint256(-1);
		uint256 _candidateCount = candidates.length();
		for (uint256 _index = 0; _index < _candidateCount; _index++) {
			address _candidate = candidates.at(_index);
			uint256 _votes = _countVotes(_candidate);
			if (_votes < _leastVotes) {
				_leastVoted = _candidate;
				_leastVotes = _votes;
			}
		}
		return (_leastVoted, _leastVotes);
	}

	/**
	 * @dev Implements the logic for appointing a new candidate. It looks
	 *      for the appointed candidate with the least votes and if the
	 *      prospect given canditate has strictly more votes, it replaces
	 *      it on the list. Note that, if the list has less than 7 appointed
	 *      candidates, the operation always succeeds.
	 * @param _newCandidate The given prospect candidate, assumed not to be
	 *                      on the list.
	 * @return _success A boolean indicating if indeed the prospect appointed
	 *                  candidate has enough votes to beat someone on the
	 *                  list and the operation succeded.
	 */
	function _appointCandidate(address _newCandidate) internal returns(bool _success)
	{
		address _oldCandidate = address(0);
		uint256 _candidateCount = candidates.length();
		if (_candidateCount == SIGNING_OWNERS) {
			uint256 _oldVotes;
			(_oldCandidate, _oldVotes) = _findLeastVoted();
			uint256 _newVotes = _countVotes(_newCandidate);
			if (_newVotes <= _oldVotes) return false;

			_success = candidates.remove(_oldCandidate);
			assert(_success);
		}
		_success = candidates.add(_newCandidate);
		assert(_success);

		pendingChanges = true;

		emit CandidateChange(votingRound, _oldCandidate, _newCandidate);

		return true;
	}

	/**
	 * @dev Calculates the current voting round.
	 * @return _votingRound The current voting round as calculated.
	 */
	function _currentVotingRound() internal view returns (uint256 _votingRound)
	{
		return now.div(VOTING_ROUND_INTERVAL);
	}

	/**
	 * @dev Returns a boolean indicating whether or not the multisig
	 *      can be updated with new signers.
	 * @return _available Returns true if a new round has started and there
	 *                    are pending changes.
	 */
	function _turnOverAvailable() internal view returns (bool _available)
	{
		uint256 _votingRound = _currentVotingRound();
		return _votingRound > votingRound && pendingChanges;
	}

	/**
	 * @dev Implements the turn over by first adding all the missing
	 *      candidates from the appointed list to the multisig signers
	 *      list, and later removing the multisig signers not present
	 *      in the current appointed list. At last, it sets the minimum
	 *      number of signers to 4 (or the size of the list if smaller than
	 *      4). This function is optimized to skip the process if it is
	 *      in sync, i.e no candidates were appointed since the last update.
	 */
	function _turnOver() internal
	{
		votingRound = _currentVotingRound();

		// adds new candidates
		uint256 _candidateCount = candidates.length();
		for (uint256 _index = 0; _index < _candidateCount; _index++) {
			address _candidate = candidates.at(_index);
			if (Multisig._isOwner(safe, _candidate)) continue;
			bool _success = Multisig._addOwnerWithThreshold(safe, _candidate, 1);
			assert(_success);
		}

		// removes old candidates
		address[] memory _owners = Multisig._getOwners(safe);
		uint256 _ownersCount = _owners.length;
		address _prevOwner = address(0x1); // sentinel from Gnosis
		for (uint256 _index = 0; _index < _ownersCount; _index++) {
			address _owner = _owners[_index];
			if (candidates.contains(_owner)) {
				_prevOwner = _owner;
				continue;
			}
			bool _success = Multisig._removeOwner(safe, _prevOwner, _owner, 1);
			assert(_success);
		}

		// updates minimum number of signers
		uint256 _threshold = Math._min(_candidateCount, SIGNING_THRESHOLD);
		bool _success = Multisig._changeThreshold(safe, _threshold);
		assert(_success);

		pendingChanges = false;

		emit TurnOver(votingRound);
	}

	/**
	 * @dev Returns the vote count for a given candidate.
	 * @param _candidate The given candidate.
	 * @return _votes The number of votes delegated to the given candidate.
	 */
	function _countVotes(address _candidate) internal view virtual returns (uint256 _votes)
	{
		return GVoting(votingToken).votes(_candidate);
	}

	event TurnOver(uint256 indexed _votingRound);
	event CandidateChange(uint256 indexed _votingRound, address indexed _oldCandidate, address indexed _newCandidate);
}