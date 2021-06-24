/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/*
 * Origin Protocol
 * https://originprotocol.com
 *
 * Released under the MIT license
 * https://github.com/OriginProtocol/origin-dollar
 *
 * Copyright 2020 Origin Protocol, Inc
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/timelock/Timelock.sol

pragma solidity 0.5.11;

/**
 * @title OUSD Timelock Contract
 * @author Origin Protocol Inc
 */

interface CapitalPausable {
    function pauseCapital() external;

    function unpauseCapital() external;
}

contract Timelock {
    using SafeMath for uint256;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(
        bytes32 indexed txHash,
        address indexed target,
        string signature,
        bytes data,
        uint256 eta
    );
    event ExecuteTransaction(
        bytes32 indexed txHash,
        address indexed target,
        string signature,
        bytes data,
        uint256 eta
    );
    event QueueTransaction(
        bytes32 indexed txHash,
        address indexed target,
        string signature,
        bytes data,
        uint256 eta
    );

    uint256 public constant GRACE_PERIOD = 3 days;
    uint256 public constant MINIMUM_DELAY = 1 minutes;
    uint256 public constant MAXIMUM_DELAY = 2 days;

    address public admin;
    address public pendingAdmin;
    uint256 public delay;

    mapping(bytes32 => bool) public queuedTransactions;

    /**
     * @dev Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    constructor(address admin_, uint256 delay_) public {
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::constructor: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );

        admin = admin_;
        delay = delay_;
    }

    function setDelay(uint256 delay_) public {
        require(
            msg.sender == address(this),
            "Timelock::setDelay: Call must come from Timelock."
        );
        require(
            delay_ >= MINIMUM_DELAY,
            "Timelock::setDelay: Delay must exceed minimum delay."
        );
        require(
            delay_ <= MAXIMUM_DELAY,
            "Timelock::setDelay: Delay must not exceed maximum delay."
        );
        delay = delay_;

        emit NewDelay(delay);
    }

    function acceptAdmin() public {
        require(
            msg.sender == pendingAdmin,
            "Timelock::acceptAdmin: Call must come from pendingAdmin."
        );
        admin = msg.sender;
        pendingAdmin = address(0);

        emit NewAdmin(admin);
    }

    function setPendingAdmin(address pendingAdmin_) public onlyAdmin {
        pendingAdmin = pendingAdmin_;

        emit NewPendingAdmin(pendingAdmin);
    }

    function queueTransaction(
        address target,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes32) {
        require(
            msg.sender == admin,
            "Timelock::queueTransaction: Call must come from admin."
        );
        require(
            eta >= getBlockTimestamp().add(delay),
            "Timelock::queueTransaction: Estimated execution block must satisfy delay."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, signature, keccak256(data), eta)
        );
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(
        address target,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            msg.sender == admin,
            "Timelock::cancelTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, signature, keccak256(data), eta)
        );
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, signature, data, eta);
    }

    function executeTransaction(
        address target,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes memory) {
        require(
            msg.sender == admin,
            "Timelock::executeTransaction: Call must come from admin."
        );

        bytes32 txHash = keccak256(
            abi.encode(target, signature, keccak256(data), eta)
        );
        require(
            queuedTransactions[txHash],
            "Timelock::executeTransaction: Transaction hasn't been queued."
        );
        require(
            getBlockTimestamp() >= eta,
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock."
        );
        require(
            getBlockTimestamp() <= eta.add(GRACE_PERIOD),
            "Timelock::executeTransaction: Transaction is stale."
        );

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(
                bytes4(keccak256(bytes(signature))),
                data
            );
        }

        (bool success, bytes memory returnData) = target.call(callData);
        require(
            success,
            "Timelock::executeTransaction: Transaction execution reverted."
        );

        emit ExecuteTransaction(txHash, target, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint256) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }

    function pauseCapital(address target) external {
        require(
            msg.sender == admin,
            "Timelock::pauseCapital: Call must come from admin."
        );
        CapitalPausable(target).pauseCapital();
    }

    function unpauseCapital(address target) external {
        require(
            msg.sender == admin,
            "Timelock::unpauseCapital: Call must come from admin."
        );
        CapitalPausable(target).unpauseCapital();
    }
}

// File: contracts/governance/Governor.sol

pragma solidity 0.5.11;
pragma experimental ABIEncoderV2;

// Modeled off of Compound's Governor Alpha
//    https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
contract Governor is Timelock {
    // @notice The total number of proposals
    uint256 public proposalCount;

    struct Proposal {
        // @notice Unique id for looking up a proposal
        uint256 id;
        // @notice Creator of the proposal
        address proposer;
        // @notice The timestamp that the proposal will be available for
        // execution, set once the vote succeeds
        uint256 eta;
        // @notice the ordered list of target addresses for calls to be made
        address[] targets;
        // @notice The ordered list of function signatures to be called
        string[] signatures;
        // @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        // @notice Flag marking whether the proposal has been executed
        bool executed;
    }

    // @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;

    // @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        string[] signatures,
        bytes[] calldatas,
        string description
    );

    // @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id, uint256 eta);

    // @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    // @notice An event emitted when a proposal has been cancelled
    event ProposalCancelled(uint256 id);

    uint256 public constant MAX_OPERATIONS = 16;

    // @notice Possible states that a proposal may be in
    enum ProposalState { Pending, Queued, Expired, Executed }

    constructor(address admin_, uint256 delay_)
        public
        Timelock(admin_, delay_)
    {}

    /**
     * @notice Propose Governance call(s)
     * @param targets Ordered list of targeted addresses
     * @param signatures Orderd list of function signatures to be called
     * @param calldatas Orderded list of calldata to be passed with each call
     * @param description Description of the governance
     * @return uint256 id of the proposal
     */
    function propose(
        address[] memory targets,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description
    ) public returns (uint256) {
        // Allow anyone to propose for now, since only admin can queue the
        // transaction it should be harmless, you just need to pay the gas
        require(
            targets.length == signatures.length &&
                targets.length == calldatas.length,
            "Governor::propose: proposal function information arity mismatch"
        );
        require(targets.length != 0, "Governor::propose: must provide actions");
        require(
            targets.length <= MAX_OPERATIONS,
            "Governor::propose: too many actions"
        );

        proposalCount++;
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            signatures: signatures,
            calldatas: calldatas,
            executed: false
        });

        proposals[newProposal.id] = newProposal;

        emit ProposalCreated(
            newProposal.id,
            msg.sender,
            targets,
            signatures,
            calldatas,
            description
        );
        return newProposal.id;
    }

    /**
     * @notice Queue a proposal for execution
     * @param proposalId id of the proposal to queue
     */
    function queue(uint256 proposalId) public onlyAdmin {
        require(
            state(proposalId) == ProposalState.Pending,
            "Governor::queue: proposal can only be queued if it is pending"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.eta = block.timestamp.add(delay);

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(
                proposal.targets[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalQueued(proposal.id, proposal.eta);
    }

    /**
     * @notice Get the state of a proposal
     * @param proposalId id of the proposal
     * @return ProposalState
     */
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(
            proposalCount >= proposalId && proposalId > 0,
            "Governor::state: invalid proposal id"
        );
        Proposal storage proposal = proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        } else if (proposal.eta == 0) {
            return ProposalState.Pending;
        } else if (block.timestamp >= proposal.eta.add(GRACE_PERIOD)) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function _queueOrRevert(
        address target,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        require(
            !queuedTransactions[keccak256(
                abi.encode(target, signature, keccak256(data), eta)
            )],
            "Governor::_queueOrRevert: proposal action already queued at eta"
        );
        require(
            queuedTransactions[queueTransaction(target, signature, data, eta)],
            "Governor::_queueOrRevert: failed to queue transaction"
        );
    }

    /**
     * @notice Execute a proposal.
     * @param proposalId id of the proposal
     */
    function execute(uint256 proposalId) public {
        require(
            state(proposalId) == ProposalState.Queued,
            "Governor::execute: proposal can only be executed if it is queued"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executeTransaction(
                proposal.targets[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalExecuted(proposalId);
    }

    /**
     * @notice Cancel a proposal.
     * @param proposalId id of the proposal
     */
    function cancel(uint256 proposalId) public onlyAdmin {
        ProposalState proposalState = state(proposalId);

        require(
            proposalState == ProposalState.Queued ||
                proposalState == ProposalState.Pending,
            "Governor::execute: proposal can only be cancelled if it is queued or pending"
        );
        Proposal storage proposal = proposals[proposalId];
        proposal.eta = 1; // To mark the proposal as `Expired`
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(
                proposal.targets[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }
        emit ProposalCancelled(proposalId);
    }

    /**
     * @notice Get the actions that a proposal will take.
     * @param proposalId id of the proposal
     */
    function getActions(uint256 proposalId)
        public
        view
        returns (
            address[] memory targets,
            string[] memory signatures,
            bytes[] memory calldatas
        )
    {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.signatures, p.calldatas);
    }
}