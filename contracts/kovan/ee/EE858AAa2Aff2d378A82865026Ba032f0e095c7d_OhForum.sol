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

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IForum} from "../interfaces/IForum.sol";
import {IGovernor} from "../interfaces/IGovernor.sol";
import {IManager} from "../interfaces/IManager.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {IToken} from "../interfaces/IToken.sol";
import {OhSubscriber} from "../registry/OhSubscriber.sol";
import {OhForumTypes} from "./OhForumTypes.sol";

/// @title Oh! Finance Forum
/// @notice Manages Protocol proposals and voting receipts to send to the Governor
/// @dev Proposer-Executor Relationship to execute protocol changes
contract OhForum is OhSubscriber, OhForumTypes, IForum {
    using SafeMath for uint256;

    /// @notice Contract Name
    string public constant name = "Oh! Forum";

    /// @notice The maximum number of actions that can be included in a proposal
    uint256 public constant MAX_OPERATIONS = 10;

    /// @notice The minimum setable proposal threshold
    uint256 public constant MIN_PROPOSAL_THRESHOLD = 500000e18; // 500,000 = 0.5%

    /// @notice The maximum setable proposal threshold
    uint256 public constant MAX_PROPOSAL_THRESHOLD = 5000000e18; // 5,000,000 = 5%

    /// @notice The minimum setable voting period
    uint256 public constant MIN_VOTING_PERIOD = 5760; // About 24 hours

    /// @notice The max setable voting period
    uint256 public constant MAX_VOTING_PERIOD = 80640; // About 2 weeks

    /// @notice The min setable voting delay
    uint256 public constant MIN_VOTING_DELAY = 1;

    /// @notice The max setable voting delay
    uint256 public constant MAX_VOTING_DELAY = 40320; // About 1 week

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    uint256 public constant QUORUM_VOTES = 4000000e18; // 4,000,000 = 4%

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 public immutable DOMAIN_SEPARATOR;

    /// @notice The address of Oh! Finance Protocol Guardian
    address public guardian;

    /// @notice The address of the Oh! Finance Token
    address public token;

    /// @notice The delay before voting on a proposal may take place, once proposed, in blocks
    uint256 public votingDelay;

    /// @notice The duration of voting on a proposal, in blocks
    uint256 public votingPeriod;

    /// @notice The number of votes required in order for a voter to become a proposer
    uint256 public proposalThreshold;

    /// @notice The total number of proposals
    uint256 public proposalCount;

    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    /// @notice Mapping of proposal to receipts of ballots for the entire set of voters
    mapping(uint256 => mapping(address => Receipt)) public receipts;

    /// @notice The latest proposal for each proposer
    mapping(address => uint256) public latestProposalIds;

    /// @notice An event emitted when a new proposal is created
    event ProposalAdded(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCancelled(uint256 id);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint256 proposalId, bool support, uint256 votes);

    /// @notice Only allow guardian to execute function
    modifier onlyGuardian {
        require(msg.sender == guardian, "Forum: Only Guardian");
        _;
    }

    constructor(
        address registry_,
        address _token,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _proposalThreshold
    ) OhSubscriber(registry_) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes("1")), getChainId(), address(this))
        );

        guardian = msg.sender;
        token = _token;
        votingDelay = _votingDelay;
        votingPeriod = _votingPeriod;
        proposalThreshold = _proposalThreshold;
    }

    /// @notice Cast a vote for a given Proposal
    /// @param proposalId The id of the Proposal to vote on
    /// @param support The boolean representing whether the user supports or rejects the Proposal
    function castVote(uint256 proposalId, bool support) external {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(
        uint256 proposalId,
        bool support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest =
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))));

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "Forum: Invalid Signature");
        return _castVote(signatory, proposalId, support);
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) external returns (uint256) {
        require(IToken(token).getPriorVotes(msg.sender, block.number.sub(1)) > proposalThreshold, "Forum: Votes Below Threshold");
        require(
            targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length,
            "Forum: Arity Mismatch"
        );
        require(targets.length != 0, "Forum: No Actions");
        require(targets.length <= MAX_OPERATIONS, "Forum: Too Many Actions");

        uint256 latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
            ProposalState latestProposalState = state(latestProposalId);
            require(latestProposalState != ProposalState.Active, "Forum: Proposal Already Active");
            require(latestProposalState != ProposalState.Pending, "Forum: Proposal Already Pending");
        }

        uint256 startBlock = block.number.add(votingDelay);
        uint256 endBlock = startBlock.add(votingPeriod);

        proposalCount++;
        Proposal memory newProposal =
            Proposal({
                id: proposalCount,
                proposer: msg.sender,
                eta: 0,
                targets: targets,
                values: values,
                signatures: signatures,
                calldatas: calldatas,
                startBlock: startBlock,
                endBlock: endBlock,
                forVotes: 0,
                againstVotes: 0,
                cancelled: false,
                executed: false
            });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        emit ProposalAdded(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function queue(uint256 proposalId) external {
        require(state(proposalId) == ProposalState.Succeeded, "Forum: Only Successful Proposals");
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp.add(IGovernor(governance()).delay());
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function execute(uint256 proposalId) external payable {
        require(state(proposalId) == ProposalState.Queued, "Forum: Must Be Queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            IGovernor(governance()).executeTransaction{value: proposal.values[i]}(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId) external {
        require(state(proposalId) != ProposalState.Executed, "Forum: Proposal Already Executed");

        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == guardian ||
                msg.sender == proposal.proposer ||
                IToken(token).getPriorVotes(proposal.proposer, block.number.sub(1)) < proposalThreshold,
            "Forum: Valid Proposer"
        );

        proposal.cancelled = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            IGovernor(governance()).cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCancelled(proposalId);
    }

    function setProposalThreshold(uint256 _proposalThreshold) external onlyGovernance {
        require(_proposalThreshold >= MIN_PROPOSAL_THRESHOLD, "Forum: Threshold Too Low");
        require(_proposalThreshold <= MAX_PROPOSAL_THRESHOLD, "Forum: Threshold Too High");
        proposalThreshold = _proposalThreshold;
    }

    function setVotingDelay(uint256 _votingDelay) external onlyGovernance {
        require(_votingDelay >= MIN_VOTING_DELAY, "Forum: Delay Too Low");
        require(_votingDelay <= MAX_VOTING_DELAY, "Forum: Delay Too High");
        votingDelay = _votingDelay;
    }

    function setVotingPeriod(uint256 _votingPeriod) external onlyGovernance {
        require(_votingPeriod >= MIN_VOTING_PERIOD, "Forum: Period Too Low");
        require(_votingPeriod <= MAX_VOTING_PERIOD, "Forum: Period Too High");
        votingPeriod = _votingPeriod;
    }

    function emergencyPause(address bank) external onlyGuardian {
        IGovernor(governance()).executeEmergencyPause(bank);
    }

    function emergencyPauseAll() external onlyGuardian {
        address manager = manager();
        address governance = governance();

        uint256 length = IManager(manager).totalBanks();
        for (uint256 i = 0; i < length; i++) {
            address bank = IManager(manager).banks(i);
            IGovernor(governance).executeEmergencyPause(bank);
        }
    }

    function pause(address bank) external onlyGuardian {
        IGovernor(governance()).executePause(bank);
    }

    function unpause(address bank) external onlyGuardian {
        IGovernor(governance()).executeUnpause(bank);
    }

    /// @notice Allow Guardian to accept admin rights after setting pending admin
    function acceptAdmin() external onlyGuardian {
        IGovernor(governance()).acceptAdmin();
    }

    /// @notice Abdicate Guardian rights when protocol has suffiently matured
    function abdicate() external onlyGuardian {
        guardian = address(0);
    }

    /// @notice Allow Guardian to queue transaction to accept admin rights with delay
    function queueSetGovernorPendingAdmin(address newPendingAdmin, uint256 eta) external onlyGuardian {
        IGovernor(governance()).queueTransaction(governance(), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    /// @notice Allow Guardian to set the pending admin once delay has expired
    function executeSetGovernorPendingAdmin(address newPendingAdmin, uint256 eta) external onlyGuardian {
        IGovernor(governance()).executeTransaction(governance(), 0, "setPendingAdmin(address)", abi.encode(newPendingAdmin), eta);
    }

    /// @notice Get the actions for a given Proposal
    /// @param proposalId The id of the Proposal to get actions from
    function getActions(uint256 proposalId)
        external
        view
        returns (
            address[] memory targets,
            uint256[] memory values,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    /// @notice Get the voting receipt for a given Voter for a given Proposal
    /// @param proposalId The id of the Proposal to get the Receipt from
    /// @param voter The address of the Voter to check
    function getReceipt(uint256 proposalId, address voter) external view returns (Receipt memory) {
        return receipts[proposalId][voter];
    }

    /// @notice Get the current state of a given Proposal
    /// @param proposalId The id of the Proposal to check
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "Forum: Invalid Proposal ID");

        Proposal storage proposal = proposals[proposalId];
        if (proposal.cancelled) {
            return ProposalState.Cancelled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < QUORUM_VOTES) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta.add(IGovernor(governance()).GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function _castVote(
        address voter,
        uint256 proposalId,
        bool support
    ) internal {
        require(state(proposalId) == ProposalState.Active, "Forum: Proposal Inactive");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[proposalId][voter];
        require(receipt.hasVoted == false, "Forum: Already Voted");

        uint256 votes = IToken(token).getPriorVotes(voter, proposal.startBlock);
        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function _queueOrRevert(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !IGovernor(governance()).queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))),
            "Forum: Proposal Already Queued"
        );
        IGovernor(governance()).queueTransaction(target, value, signature, data, eta);
    }

    function getChainId() internal pure returns (uint256 chainId) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

abstract contract OhForumTypes {
    /// @notice Possible states that a proposal may be in
    enum ProposalState {Pending, Active, Cancelled, Defeated, Succeeded, Queued, Expired, Executed}

    /// @notice Proposal object used to execute a series of instructions
    struct Proposal {
        // Unique id for looking up a proposal
        uint256 id;
        // Creator of the proposal
        address proposer;
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // the ordered list of target addresses for calls to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        // The block at which voting begins: holders must delegate their votes prior to this block
        uint256 startBlock;
        // The block at which voting ends: votes must be cast prior to this block
        uint256 endBlock;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;
        // Flag marking whether the proposal has been canceled
        bool cancelled;
        // Flag marking whether the proposal has been executed
        bool executed;
    }

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // Whether or not the voter supports the proposal
        bool support;
        // The number of votes the voter had, which were cast
        uint256 votes;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IForum {
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGovernor {
    function delay() external view returns (uint256);

    function GRACE_PERIOD() external view returns (uint256);

    function acceptAdmin() external;

    function queuedTransactions(bytes32 hash) external view returns (bool);

    function queueTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes32);

    function cancelTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external;

    function executeTransaction(
        address target,
        uint256 value,
        string calldata signature,
        bytes calldata data,
        uint256 eta
    ) external payable returns (bytes memory);

    function executeEmergencyPause(address bank) external;

    function executePause(address bank) external;

    function executeUnpause(address bank) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IManager {
    function token() external view returns (address);

    function buybackFee() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function liquidators(address from, address to) external view returns (address);

    function whitelisted(address _contract) external view returns (bool);

    function banks(uint256 i) external view returns (address);

    function totalBanks() external view returns (uint256);

    function strategies(address bank, uint256 i) external view returns (address);

    function totalStrategies(address bank) external view returns (uint256);

    function withdrawIndex(address bank) external view returns (uint256);

    function setWithdrawIndex(uint256 i) external;

    function rebalance(address bank) external;

    function finance(address bank) external;

    function financeAll(address bank) external;

    function buyback(address from) external;

    function accrueRevenue(
        address bank,
        address underlying,
        uint256 amount
    ) external;

    function exitAll(address bank) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IRegistry {
    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface ISubscriber {
    function registry() external view returns (address);

    function governance() external view returns (address);

    function manager() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegator,
        address delegatee,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function burn(uint256 amount) external;

    function mint(address recipient, uint256 amount) external;

    function getCurrentVotes(address account) external view returns (uint256);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ISubscriber} from "../interfaces/ISubscriber.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";

/// @title Oh! Finance Subscriber
/// @notice Base Oh! Finance contract used to control access throughout the protocol
abstract contract OhSubscriber is ISubscriber {
    address internal _registry;

    /// @notice Only allow authorized addresses (governance or manager) to execute a function
    modifier onlyAuthorized {
        require(msg.sender == governance() || msg.sender == manager(), "Subscriber: Only Authorized");
        _;
    }

    /// @notice Only allow the governance address to execute a function
    modifier onlyGovernance {
        require(msg.sender == governance(), "Subscriber: Only Governance");
        _;
    }

    /// @notice Construct contract with the Registry
    /// @param registry_ The address of the Registry
    constructor(address registry_) {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");
        _registry = registry_;
    }

    /// @notice Get the Governance address
    /// @return The current Governance address
    function governance() public view override returns (address) {
        return IRegistry(registry()).governance();
    }

    /// @notice Get the Manager address
    /// @return The current Manager address
    function manager() public view override returns (address) {
        return IRegistry(registry()).manager();
    }

    /// @notice Get the Registry address
    /// @return The current Registry address
    function registry() public view override returns (address) {
        return _registry;
    }

    /// @notice Set the Registry for the contract. Only callable by Governance.
    /// @param registry_ The new registry
    /// @dev Requires sender to be Governance of the new Registry to avoid bricking.
    /// @dev Ideally should not be used
    function setRegistry(address registry_) external onlyGovernance {
        require(Address.isContract(registry_), "Subscriber: Invalid Registry");

        _registry = registry_;
        require(msg.sender == governance(), "Subscriber: Bad Governance");
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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