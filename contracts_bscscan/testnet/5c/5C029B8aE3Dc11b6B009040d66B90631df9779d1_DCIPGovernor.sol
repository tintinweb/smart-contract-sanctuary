// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import './governor.sol';
import './interfaces/dcip.sol';

contract DCIPGovernor is Governor {
    using Timers for Timers.BlockNumber;
    mapping(address => bool) public blockedAddresses;
    uint16 public proposalReward;

    constructor(IDCIP _token, uint16 _proposalReward) Governor(_token) {
        proposalReward = _proposalReward;
    }

    function blockAddress(address adr) public onlyOwner returns (bool) {
        blockedAddresses[adr] = true;
        return true;
    }

    function unblockAddress(address adr) public onlyOwner returns (bool) {
        blockedAddresses[adr] = false;
        return true;
    }

    function proposalThreshold() public pure returns (uint256) {
        return 80000000000e9;
    }

    function setProposalTreshhold(uint256 _threshold) public onlyOwner returns (bool) {
        proposalTreshhold = _threshold;
        return true;
    }

    function setVotingPeriod(uint64 period) public onlyOwner returns (bool) {
        require(period >= 14400, 'Voting period cannot be less than 12 hours');
        votingPeriodBlocks = period;
        return true;
    }

    function propose(
        string memory title,
        string memory description,
        uint256 fundAllocation
    ) public override returns (uint256) {
        require(blockedAddresses[_msgSender()] != true, 'Your address is blocked from making proposals');
        require(getVotingWeight(_msgSender()) >= proposalThreshold(), 'Proposer votes below proposal threshold');
        return super.propose(title, description, fundAllocation);
    }

    /**
     * @dev If amount of votes cast passes the threshold limit.
     */
    function quorumReached(uint256 proposalId) public view virtual returns (bool) {
        Proposal storage p = proposals[proposalId];
        return p.votesForQuorum < (p.votesFor + p.votesAgainst);
    }

    function setVotesForQuorum(uint256 nrOfTokens) public virtual onlyOwner returns (uint256) {
        require(nrOfTokens > 1000000e9, 'At least 1.000.000 DCIP is required');
        votesForQuorum = nrOfTokens;
        return votesForQuorum;
    }

    function getVotingWeight(address voter) public virtual override returns (uint256) {
        return token.balanceOf(voter);
    }

    function hasVoted(address account, uint256 proposalId) public view returns (bool) {
        return proposals[proposalId].hasVoted[account];
    }

    function getVote(address account, uint256 proposalId) public view returns (bool) {
        return proposals[proposalId].vote[account];
    }

    function voteSucceeded(uint256 proposalId) public view returns (bool) {
        Proposal storage p = proposals[proposalId];
        return p.votesFor > p.votesAgainst;
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            uint256 fundAllocation,
            Timers.BlockNumber memory voteStart,
            Timers.BlockNumber memory voteEnd,
            bool executed,
            uint256 votesAgainst,
            uint256 votesFor,
            uint256 votesForQuorum,
            ProposalState proposalState
        )
    {
        Proposal storage p = proposals[proposalId];
        ProposalState s = state(proposalId);
        return (
            p.id,
            p.proposer,
            p.title,
            p.description,
            p.fundAllocation,
            p.voteStart,
            p.voteEnd,
            p.executed,
            p.votesAgainst,
            p.votesFor,
            p.votesForQuorum,
            s
        );
    }

    function state(uint256 proposalId) internal view virtual override returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.invalidated) {
            return ProposalState.Invalidated;
        } else if (proposal.voteStart.isPending()) {
            return ProposalState.Pending;
        } else if (proposal.voteEnd.isPending()) {
            return ProposalState.Active;
        } else if (proposal.voteEnd.isExpired()) {
            return
                quorumReached(proposalId) && voteSucceeded(proposalId)
                    ? ProposalState.Succeeded
                    : ProposalState.Defeated;
        } else {
            revert('Governor: unknown proposal id');
        }
    }

    function _countVote(
        uint256 proposalId,
        address account,
        bool support,
        uint256 weight
    ) internal virtual override {
        Proposal storage p = proposals[proposalId];
        require(blockedAddresses[account] != true, 'Address blocked from voting');
        require(p.hasVoted[account] == false, 'Vote has already been cast!');
        require(weight >= 1, 'Invalid vote weight');
        if (support == true) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }
        p.hasVoted[account] = true;
        p.vote[account] = support;
        emit VoteCast(account, proposalId, support, weight);
    }

    function invalidateProposal(uint256 proposalId) public onlyOwner returns (bool) {
        Proposal storage p = proposals[proposalId];
        p.invalidated = true;
        return true;
    }

    function setProposalReward(uint16 _proposalReward) public onlyOwner returns (bool) {
        proposalReward = _proposalReward;
        return true;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './interfaces/governor.sol';
import './libraries/ownable.sol';
import './interfaces/dcip.sol';
import './libraries/timers.sol';
import '@openzeppelin/contracts/utils/math/SafeCast.sol';

abstract contract Governor is Ownable, IGovernor {
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    IDCIP public token;

    mapping(uint256 => Proposal) internal proposals;
    uint256 proposalTreshhold;
    uint256 public proposalCount;
    uint256 public votesForQuorum;
    uint64 public votingPeriodBlocks;

    constructor(IDCIP _tokenAddress) {
        token = _tokenAddress;
        proposalCount = 0;
        votesForQuorum = 25000000000000e9; /// Approxx 100 euros at current value
        votingPeriodBlocks = 201600;
    }

    function propose(
        string memory title,
        string memory description,
        uint256 fundAllocation
    ) public virtual override returns (uint256) {
        uint64 voteStart = block.number.toUint64();
        uint64 deadline = voteStart + votingPeriodBlocks;
        uint256 proposalId = proposalCount;

        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.title = title;
        p.description = description;
        p.fundAllocation = fundAllocation;
        p.voteStart = Timers.BlockNumber(voteStart);
        p.voteEnd = Timers.BlockNumber(deadline);
        p.invalidated = false;
        p.executed = false;
        p.votesFor = 0;
        p.votesAgainst = 0;
        p.votesForQuorum = votesForQuorum;

        emit ProposalCreated(proposalId, title, fundAllocation);

        _countVote(proposalId, _msgSender(), true, getVotingWeight(_msgSender()));
        proposalCount++;
        return proposalId;
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, bool support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        bool support
    ) internal virtual returns (uint256) {
        require(state(proposalId) == ProposalState.Active, 'Proposal is not currently active');

        uint256 weight = getVotingWeight(account);
        _countVote(proposalId, account, support, weight);
        return weight;
    }

    function state(uint256 proposalId) internal view virtual returns (ProposalState);

    function getVotingWeight(address voter) public virtual returns (uint256) {}

    /**
     * @dev Register a vote with a given support and voting weight.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        bool support,
        uint256 weight
    ) internal virtual;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDCIP {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import '../libraries/timers.sol';

enum ProposalState {
    Pending,
    Active,
    Invalidated,
    Defeated,
    Succeeded,
    Executed
}

struct Proposal {
    /// @notice Unique id for looking up a proposal
    uint256 id;
    /// @notice Creator of the proposal
    address proposer;
    /// @notice Title of the proposal
    string title;
    /// @notice Description of the proposal
    string description;
    /// @notice Funds to allocate
    uint256 fundAllocation;
    /// @notice The block at which voting begins: holders must delegate their votes prior to this block
    Timers.BlockNumber voteStart;
    /// @notice The block at which voting ends: votes must be cast prior to this block
    Timers.BlockNumber voteEnd;
    /// @notice Current number of votes in favor of this proposal
    bool executed;
    /// @notice Flag marking whether the proposal has been invalidated
    bool invalidated;
    uint256 votesAgainst;
    uint256 votesFor;
    uint256 votesForQuorum;
    mapping(address => bool) hasVoted;
    mapping(address => bool) vote;
}

// enum AssetType {
//     blockchain
// }

// struct Investment {
//     /// @notice Type of the proposed asset
//     AssetType assetType;
//     /// @notice Number of DCIP allocated for investment
//     uint256 fundAllocation;
//     /// @notice Chain such as BSC, ETH, etc
//     string chain;
//     /// @notice address of token to buy
//     address contractAddress;
// }

interface IDCIPGovernor {
    function propose(
        string memory title,
        string memory description,
        uint256 fundAllocation
    ) external returns (uint256);

    function getProposal(uint256 proposalId)
        external
        view
        returns (
            uint256 id,
            address proposer,
            string memory title,
            string memory description,
            uint256 fundAllocation,
            Timers.BlockNumber memory voteStart,
            Timers.BlockNumber memory voteEnd,
            bool executed,
            bool invalidated,
            uint256 votesAgainst,
            uint256 votesFor,
            uint256 votesForQuorum,
            ProposalState proposalState
        );

    function castVote(uint256 proposalId, bool support) external returns (uint256);

    function quorumReached(uint256 proposalId) external view returns (bool);

    function voteSucceeded(uint256 proposalId) external view returns (bool);

    function blockAddress(address adr) external returns (bool);

    function unblockAddress(address adr) external returns (bool);

    function proposalThreshold() external pure returns (uint256);

    function setProposalTreshhold(uint256 _threshold) external returns (bool);

    function setVotingPeriod(uint64 period) external returns (bool);

    function setVotesForQuorum(uint256 nrOfTokens) external returns (uint256);

    function getVotingWeight(address voter) external returns (uint256);

    function hasVoted(address account, uint256 proposalId) external view returns (bool);

    function getVote(address account, uint256 proposalId) external view returns (bool);
}

interface IGovernor {
    event ProposalCreated(uint256 id, string title, uint256 fundAllocation);
    event VoteCast(address account, uint256 proposalId, bool support, uint256 weight);

    function propose(
        string memory title,
        string memory description,
        uint256 fundAllocation
    ) external returns (uint256);

    function castVote(uint256 proposalId, bool support) external returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

