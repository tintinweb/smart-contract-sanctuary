// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 */
abstract contract Approvable is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    EnumerableSet.AddressSet _approvers;
    mapping(address => uint256) private _weights;
    uint256 private _totalWeight;
    uint256 private _threshold;


    struct GrantApprover {
        uint256 id;
        bool executed;
        address account;
        uint256 weight;
        uint256 approvalsWeight;
    }
    GrantApprover[] private _grantApprovers;
    mapping(address => mapping(uint256 => bool)) private _approvalsGrantApprover;


    struct ChangeApproverWeight {
        uint256 id;
        bool executed;
        address account;
        uint256 weight;
        uint256 approvalsWeight;
    }
    ChangeApproverWeight[] private _changeApproverWeights;
    mapping(address => mapping(uint256 => bool)) private _approvalsChangeApproverWeight;


    struct RevokeApprover {
        uint256 id;
        bool executed;
        address account;
        uint256 approvalsWeight;
    }
    RevokeApprover[] private _revokeApprovers;
    mapping(address => mapping(uint256 => bool)) private _approvalsRevokeApprover;


    struct ChangeThreshold {
        uint256 id;
        bool executed;
        uint256 threshold;
        uint256 approvalsWeight;
    }
    ChangeThreshold[] private _changeThresholds;
    mapping(address => mapping(uint256 => bool)) private _approvalsChangeThreshold;


    event NewGrantApprover(uint256 indexed id, address indexed account, uint256 weight);
    event VoteForGrantApprover(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverGranted(address indexed account);

    event NewChangeApproverWeight(uint256 indexed id, address indexed account, uint256 weight);
    event VoteForChangeApproverWeight(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverWeightChanged(address indexed account, uint256 oldWeight, uint256 newWeight);

    event NewRevokeApprover(uint256 indexed id, address indexed account);
    event VoteForRevokeApprover(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ApproverRevoked(address indexed account);

    event NewChangeThreshold(uint256 indexed id, uint256 threshold);
    event VoteForChangeThreshold(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ThresholdChanged(uint256 oldThreshold, uint256 newThreshold);

    event TotalWeightChanged(uint256 oldTotalWeight, uint256 newTotalWeight);


    function getThreshold() public view returns (uint256) {
        return _threshold;
    }

    function getTotalWeight() public view returns (uint256) {
        return _totalWeight;
    }

    function getApproversCount() public view returns (uint256) {
        return _approvers.length();
    }

    function isApprover(address account) public view returns (bool) {
        return _approvers.contains(account);
    }

    function getApprover(uint256 index) public view returns (address) {
        return _approvers.at(index);
    }

    function getApproverWeight(address account) public view returns (uint256) {
        return _weights[account];
    }


    // GrantApprovers
    function getGrantApproversCount() public view returns (uint256) {
        return _grantApprovers.length;
    }

    function getGrantApprover(uint256 id) public view returns (GrantApprover memory) {
        return _grantApprovers[id];
    }

    // ChangeApproverWeights
    function getChangeApproverWeightsCount() public view returns (uint256) {
        return _changeApproverWeights.length;
    }

    function getChangeApproverWeight(uint256 id) public view returns (ChangeApproverWeight memory) {
        return _changeApproverWeights[id];
    }

    // RevokeApprovers
    function getRevokeApproversCount() public view returns (uint256) {
        return _revokeApprovers.length;
    }

    function getRevokeApprover(uint256 id) public view returns (RevokeApprover memory) {
        return _revokeApprovers[id];
    }

    // ChangeThresholds
    function getChangeThresholdsCount() public view returns (uint256) {
        return _changeThresholds.length;
    }

    function getChangeThreshold(uint256 id) public view returns (ChangeThreshold memory) {
        return _changeThresholds[id];
    }


    // Grant Approver
    function grantApprover(address account, uint256 weight) public onlyApprover returns (uint256) {
        uint256 id = _addNewGrantApprover(account, weight);
        _voteForGrantApprover(id);
        return id;
    }

    function _addNewGrantApprover(address account, uint256 weight) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _grantApprovers.length;
        _grantApprovers.push(GrantApprover(id, false, account, weight, 0));
        emit NewGrantApprover(id, account, weight);
        return id;
    }

    function _voteForGrantApprover(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsGrantApprover[msgSender][id] = true;
        _grantApprovers[id].approvalsWeight = _grantApprovers[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForGrantApprover(id, msgSender, _weights[msgSender], _grantApprovers[id].approvalsWeight);
        return true;
    }

    function _grantApprover(address account, uint256 weight) private returns (bool) {
        if (_approvers.add(account)) {
            _changeApproverWeight(account, weight);
            emit ApproverGranted(account);
            return true;
        }
        return false;
    }

    function _setupApprover(address account, uint256 weight) internal returns (bool) {
        return _grantApprover(account, weight);
    }

    function approveGrantApprover(uint256 id) public onlyApprover returns (bool) {
        require(_grantApprovers[id].executed == false, "Approvable: action has already executed");
        require(_approvalsGrantApprover[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForGrantApprover(id);
    }

    function confirmGrantApprover(uint256 id) public returns (bool) {
        require(_grantApprovers[id].account == _msgSender(), "Approvable: only pending approver");
        require(_grantApprovers[id].executed == false, "Approvable: action has already executed");
        if (_grantApprovers[id].approvalsWeight >= _threshold) {
            _grantApprover(_grantApprovers[id].account, _grantApprovers[id].weight);
            _grantApprovers[id].executed = true;
            return true;
        }
        return false;
    }


    // Change Approver Weight
    function changeApproverWeight(address account, uint256 weight) public onlyApprover returns (uint256) {
        require(_totalWeight.sub(_weights[account]).add(weight) >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        uint256 id = _addNewChangeApproverWeight(account, weight);
        _voteForChangeApproverWeight(id);
        return id;
    }

    function _addNewChangeApproverWeight(address account, uint256 weight) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _changeApproverWeights.length;
        _changeApproverWeights.push(ChangeApproverWeight(id, false, account, weight, 0));
        emit NewChangeApproverWeight(id, account, weight);
        return id;
    }

    function _voteForChangeApproverWeight(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsChangeApproverWeight[msgSender][id] = true;
        _changeApproverWeights[id].approvalsWeight = _changeApproverWeights[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForChangeApproverWeight(id, msgSender, _weights[msgSender], _changeApproverWeights[id].approvalsWeight);
        if (_changeApproverWeights[id].approvalsWeight >= _threshold) {
            _changeApproverWeight(_changeApproverWeights[id].account, _changeApproverWeights[id].weight);
            _changeApproverWeights[id].executed = true;
        }
        return true;
    }

    function _changeApproverWeight(address account, uint256 weight) private returns (bool) {
        uint256 newTotalWeight = _totalWeight.sub(_weights[account]).add(weight);
        require(newTotalWeight >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        _setTotalWeight(newTotalWeight);
        emit ApproverWeightChanged(account, _weights[account], weight);
        _weights[account] = weight;
        return true;
    }

    function approveChangeApproverWeight(uint256 id) public onlyApprover returns (bool) {
        require(_changeApproverWeights[id].executed == false, "Approvable: action has already executed");
        require(_approvalsChangeApproverWeight[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForChangeApproverWeight(id);
    }


    // Revoke Approver
    function revokeApprover(address account) public onlyApprover returns (uint256) {
        require(_totalWeight.sub(_weights[account]) >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        uint256 id = _addNewRevokeApprover(account);
        _voteForRevokeApprover(id);
        return id;
    }

    function _addNewRevokeApprover(address account) private returns (uint256) {
        require(account != address(0), "Approvable: account is the zero address");
        uint256 id = _revokeApprovers.length;
        _revokeApprovers.push(RevokeApprover(id, false, account, 0));
        emit NewRevokeApprover(id, account);
        return id;
    }

    function _voteForRevokeApprover(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsRevokeApprover[msgSender][id] = true;
        _revokeApprovers[id].approvalsWeight = _revokeApprovers[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForRevokeApprover(id, msgSender, _weights[msgSender], _revokeApprovers[id].approvalsWeight);
        if (_revokeApprovers[id].approvalsWeight >= _threshold) {
            _revokeApprover(_revokeApprovers[id].account);
            _revokeApprovers[id].executed = true;
        }
        return true;
    }

    function _revokeApprover(address account) private returns (bool) {
        uint256 newTotalWeight = _totalWeight.sub(_weights[account]);
        require(newTotalWeight >= _threshold, "Approvable: The threshold is greater than new totalWeight");
        if (_approvers.remove(account)) {
            _changeApproverWeight(account, 0);
            emit ApproverRevoked(account);
            return true;
        }
        return false;
    }

    function approveRevokeApprover(uint256 id) public onlyApprover returns (bool) {
        require(_revokeApprovers[id].executed == false, "Approvable: action has already executed");
        require(_approvalsRevokeApprover[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForRevokeApprover(id);
    }

    function renounceApprover(address account) public returns (bool) {
        require(account == _msgSender(), "Approvable: can only renounce roles for self");
        return _revokeApprover(account);
    }


    // Change Threshold
    function changeThreshold(uint256 threshold) public onlyApprover returns (uint256) {
        require(getTotalWeight() >= threshold, "Approvable: The new threshold is greater than totalWeight");
        uint256 id = _addNewChangeThreshold(threshold);
        _voteForChangeThreshold(id);
        return id;
    }

    function _addNewChangeThreshold(uint256 threshold) private returns (uint256) {
        uint256 id = _changeThresholds.length;
        _changeThresholds.push(ChangeThreshold(id, false, threshold, 0));
        emit NewChangeThreshold(id, threshold);
        return id;
    }

    function _voteForChangeThreshold(uint256 id) private returns (bool) {
        address msgSender = _msgSender();
        _approvalsChangeThreshold[msgSender][id] = true;
        _changeThresholds[id].approvalsWeight = _changeThresholds[id].approvalsWeight.add(_weights[msgSender]);
        emit VoteForChangeThreshold(id, msgSender, _weights[msgSender], _changeThresholds[id].approvalsWeight);
        if (_changeThresholds[id].approvalsWeight >= _threshold) {
            _setThreshold(_changeThresholds[id].threshold);
            _changeThresholds[id].executed = true;
        }
        return true;
    }

    function approveChangeThreshold(uint256 id) public onlyApprover returns (bool) {
        require(_changeThresholds[id].executed == false, "Approvable: action has already executed");
        require(_approvalsChangeThreshold[_msgSender()][id] == false, "Approvable: Cannot approve action twice");
        return _voteForChangeThreshold(id);
    }

    function _setThreshold(uint256 threshold) private returns (bool) {
        require(getTotalWeight() >= threshold, "Approvable: The new threshold is greater than totalWeight");
        emit ThresholdChanged(_threshold, threshold);
        _threshold = threshold;
        return true;
    }

    function _setupThreshold(uint256 threshold) internal returns (bool) {
        return _setThreshold(threshold);
    }


    // Total Weight
    function _setTotalWeight(uint256 totalWeight) private returns (bool) {
        emit TotalWeightChanged(_totalWeight, totalWeight);
        _totalWeight = totalWeight;
        return true;
    }

    modifier onlyApprover() {
        require(isApprover(_msgSender()), "Approvable: caller is not the approver");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Approvable.sol";



interface IERC20Short {
    function burnFrom(address account, uint256 amount) external;
    function mint(address to, uint256 amount) external;
}


contract CUPMinter is Approvable {
    using SafeMath for uint256;

    address private _cup;
    mapping(address => bool) private _tokens;

    struct Proposal {
        uint256 id;
        bool applied;
        address token;
        uint256 approvalsWeight;
    }
    Proposal[] private _proposals;
    mapping(address => mapping(uint256 => bool)) private _approvalsProposal;

    event NewProposal(uint256 indexed id, address indexed token);
    event VoteForProposal(uint256 indexed id, address indexed voter, uint256 voterWeight, uint256 approvalsWeight);
    event ProposalApplied(uint256 indexed id, address indexed token);


    constructor(uint256 weight, uint256 threshold) public {
        _setupApprover(_msgSender(), weight);
        _setupThreshold(threshold);
    }

    function convert(address token, uint256 amount) public {
        require(_tokens[token], "This token is not allowed to convert");
        address msgSender = _msgSender();
        IERC20Short(token).burnFrom(msgSender, amount);
        IERC20Short(cup()).mint(msgSender, amount);
    }

    function cup() public view returns (address) {
        return _cup;
    }

    function setCup(address token) public onlyApprover {
        require(token != address(0), "New CUP address is the zero address");
        require(cup() == address(0), "The CUP address is already setted");
        _cup = token;
    }

    function proposalsCount() public view returns (uint256) {
        return _proposals.length;
    }

    function getProposal(uint256 id) public view returns (Proposal memory) {
        return _proposals[id];
    }

    function addProposal(address token) public onlyApprover returns (uint256) {
        uint256 id = _addNewProposal(token);
        _voteForProposal(id);
        return id;
    }

    function approveProposal(uint256 id) public onlyApprover {
        require(_proposals[id].applied == false, "Proposal has already applied");
        require(_approvalsProposal[_msgSender()][id] == false, "Cannot approve transfer twice");
        _voteForProposal(id);
    }


    function _addNewProposal(address token) private returns (uint256) {
        require(token != address(0), "Token is the zero address");
        uint256 id = _proposals.length;
        _proposals.push(Proposal(id, false, token, 0));
        emit NewProposal(id, token);
        return id;
    }

    function _voteForProposal(uint256 id) private {
        address msgSender = _msgSender();
        _approvalsProposal[msgSender][id] = true;
        uint256 approverWeight = getApproverWeight(msgSender);
        _proposals[id].approvalsWeight = _proposals[id].approvalsWeight.add(approverWeight);
        emit VoteForProposal(id, msgSender, approverWeight, _proposals[id].approvalsWeight);
        if (_proposals[id].approvalsWeight >= getThreshold())
            _applyProposal(id);
    }

    function _applyProposal(uint256 id) private {
        _tokens[_proposals[id].token] = true;
        _proposals[id].applied = true;
        emit ProposalApplied(id, _proposals[id].token);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}