// SPDX-License-Identifier: BSD-3-Clause









pragma solidity =0.7.6;
pragma abicoder v2;


import '../governance/GovernorAlpha.sol';
import './interfaces/ITFDao.sol';

import '@openzeppelin/contracts/utils/Address.sol';


contract TFGovernorAlpha is GovernorAlpha {

    ITFDao public immutable tfDao;

    constructor(
        address timelock_,
        address votingToken_,
        address guardian_,
        uint48 votingPeriodBlocks_,
        ITFDao tfDao_
    ) GovernorAlpha(
        "TF Meta Governor Alpha",
        timelock_,
        votingToken_,
        guardian_,
        votingPeriodBlocks_
    ) {
        tfDao = tfDao_;
    }

    function _canAbdicate(address) internal pure override returns (bool) {
        return true;
    }

    function _requireValidAction(address dest, string memory) internal view override {
        require(Address.isContract(dest), 'Not a contract');
    }

    function _availableVotingTokens() internal view override returns (uint) {
        return tfDao.availableSupply();
    }
}

// SPDX-License-Identifier: BSD-3-Clause












pragma solidity =0.7.6;
pragma abicoder v2;


abstract contract GovernorAlpha {
    
    
    string public name;

    
    
    uint128 public constant QUORUM_VOTES_PERCENTAGE = 0.03e18; 

    
    
    uint128 public constant PROPOSAL_THRESHOLD_PERCENTAGE = 0.005e18; 

    
    
    function proposalThreshold(uint availableVotingTokens) public pure returns (uint) {
        return mul256(availableVotingTokens, PROPOSAL_THRESHOLD_PERCENTAGE) / 1e18;
    }

    
    function proposalMaxOperations() public pure returns (uint) { return 10; } 

    
    function votingDelay() public pure returns (uint) { return 1; } 

    
    function votingPeriod() public view returns (uint) { return votingPeriodBlocks; }

    
    TimelockInterface public timelock;

    
    uint48 public proposalCount;

    
    
    uint48 public immutable votingPeriodBlocks; 

    
    VotingTokenInterface public votingToken;

    
    address public guardian;

    
    struct Proposal {
        address[] targets;
        string[] signatures;
        bytes[] calldatas;
        string ipfsHash;
        address proposer;
        uint48 eta;
        uint48 id;
        uint128 forVotes;
        uint48 startBlock;
        uint48 endBlock;
        bool canceled;
        bool executed;
        uint128 againstVotes;
        uint128 availableVotingTokens;
    }

    
    
    struct Receipt {
        bool hasVoted;
        bool support;
        uint192 votes;
    }

    
    
    mapping(uint48 => mapping (address => Receipt)) internal receipts;

    
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    
    mapping (uint => Proposal) public proposals;

    
    mapping (address => uint) public latestProposalIds;

    
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    
    
    event ProposalCreated(uint indexed id, address indexed proposer);

    
    event VoteCast(address indexed voter, uint indexed proposalId, bool indexed support, uint votes);

    
    event ProposalCanceled(uint indexed id);

    
    event ProposalQueued(uint indexed id, uint eta);

    
    event ProposalExecuted(uint indexed id);

    constructor(string memory name_, address timelock_, address votingToken_, address guardian_, uint48 votingPeriodBlocks_) {
        
        name = name_;

        require(timelock_ != address(0) && votingToken_ != address(0) && guardian_ != address(0));
        timelock = TimelockInterface(timelock_);
        votingToken = VotingTokenInterface(votingToken_);
        guardian = guardian_;

        
        require(votingPeriodBlocks_ > 0);
        votingPeriodBlocks = votingPeriodBlocks_;
    }

    function propose(address[] memory targets, string[] memory signatures, bytes[] memory calldatas, string memory ipfsHash) public returns (uint) {
        
        uint availableVotingTokens = _availableVotingTokens();
        require(votingToken.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(availableVotingTokens), "GovernorAlpha::propose: proposer votes below proposal threshold");
        require(targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
        require(targets.length > 0, "GovernorAlpha::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId > 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }

        
        for (uint i = 0; i < signatures.length; i++) {
            _requireValidAction(targets[i], signatures[i]);
        }

        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());

        proposalCount++;
        require(proposalCount < 2**48);
        Proposal memory newProposal = Proposal({
            id: proposalCount,
            ipfsHash: ipfsHash, 
            proposer: msg.sender,
            eta: 0,
            targets: targets,
            signatures: signatures,
            calldatas: calldatas,
            startBlock: _to48(startBlock),
            endBlock: _to48(endBlock),
            forVotes: 0,
            againstVotes: 0,
            canceled: false,
            executed: false,
            availableVotingTokens: _to128(availableVotingTokens) 
        });

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;

        
        emit ProposalCreated(newProposal.id, msg.sender);
        return newProposal.id;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay());
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = _to48(eta);
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, signature, data, eta);
    }

    
    function execute(uint proposalId) public {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction(proposal.targets[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        
        
        
        require(state(proposalId) != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        
        require(msg.sender == guardian || votingToken.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(proposal.availableVotingTokens), "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.signatures, p.calldatas);
    }

    function getReceipt(uint48 proposalId, address voter) public view returns (Receipt memory) {
        
        return receipts[proposalId][voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < mul256(proposal.availableVotingTokens, QUORUM_VOTES_PERCENTAGE) / 1e18) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function castVote(uint proposalId, bool support) public {
        return _castVote(msg.sender, proposalId, support);
    }

    function castVoteBySig(uint proposalId, bool support, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "GovernorAlpha::castVoteBySig: invalid signature");
        return _castVote(signatory, proposalId, support);
    }

    function _castVote(address voter, uint proposalId, bool support) internal {
        require(state(proposalId) == ProposalState.Active, "GovernorAlpha::_castVote: voting is closed");
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = receipts[_to48(proposalId)][voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        uint votes = votingToken.getPriorVotes(voter, proposal.startBlock);

        if (support) {
            proposal.forVotes = _to128(add256(proposal.forVotes, votes));
        } else {
            proposal.againstVotes = _to128(add256(proposal.againstVotes, votes));
        }

        receipt.hasVoted = true;
        receipt.support = support;
        
        receipt.votes = _to192(votes);

        emit VoteCast(voter, proposalId, support, votes);
    }

    function __abdicate() public {
        require(_canAbdicate(msg.sender), 'Not Authorized');
        guardian = address(0);
    }

    
    function _canAbdicate(address) internal view virtual returns (bool);
    function _requireValidAction(address, string memory) internal view virtual;
    function _availableVotingTokens() internal view virtual returns (uint);

    

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }

    
    function mul256(uint256 a, uint256 b) internal pure returns (uint r) {
        if (a == 0) return 0;
        r = a * b;
        require(r / a == b, "multiplication overflow");
    }


    
    function _to192(uint256 val) internal pure returns (uint192) {
        require(val < 2**192, 'Exceeds 192 bits');
        return uint192(val);
    }

    function _to128(uint256 val) internal pure returns (uint128) {
        require(val < 2**128, 'Exceeds 128 bits');
        return uint128(val);
    }

    function _to48(uint256 val) internal pure returns (uint48) {
        require(val < 2**48, 'Exceeds 48 bits');
        return uint48(val);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    
    function getAllProposals(address voter) external view returns (
        Proposal[] memory _proposals,
        ProposalState[] memory _proposalStates,
        Receipt[] memory _receipts
    ) {
        uint _proposalCount = proposalCount;
        _proposals = new Proposal[](_proposalCount);
        _proposalStates = new ProposalState[](_proposalCount);
        _receipts = new Receipt[](_proposalCount);

        for(uint48 i = 1; i <= _proposalCount; i++) {
            _proposals[i - 1] = proposals[i];
            _proposalStates[i - 1] = state(i);
            _receipts[i - 1] = getReceipt(i, voter);
        }
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface VotingTokenInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint);
}

// Copyright (c) 2020. All Rights Reserved
// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.6;

import '../../governance/GovernorAlpha.sol';


interface ITFDao {
    
    function availableSupply() external view returns (uint);
    function incentiveContractMint(address dest, uint count) external;
    function voteInUnderlyingProtocol(GovernorAlpha, uint) external pure;

    
    struct TokenRewardsStatus {
        uint cumulativeVirtualCount;
        uint totalRewards;
    }

    struct TokenRewardsStatusStorage {
        uint128 cumulativeVirtualCount;
        uint128 totalRewards;
    }

    struct TokenPosition {
        uint count;
        uint startTotalRewards;
        uint startCumulativeVirtualCount;
        uint64 lastPeriodUpdated;
        uint64 endPeriod;
        uint64 durationMonths;
        uint16 tokenID;
    }

    struct TokenPositionStorage {
        uint128 count;
        uint128 startTotalRewards;
        uint184 startCumulativeVirtualCount;
        uint16 lastPeriodUpdated;
        uint16 endPeriod;
        uint16 tokenID;
        uint8 durationMonths;
    }

    
    
    event LiquidationIncentiveContractSet(address indexed _contract);
    event TokenAdded(address indexed token);
    event IncentiveMinted(address indexed token, uint count);
    event TFDaoStarted();
    event MetaGovernanceDecisionExecuted(address indexed governorAlpha, uint indexed proposalID, bool indexed decision);

    
    event TokensLocked(
        uint16 indexed tokenID,
        address indexed initialOwner,
        uint8 indexed lockDurationMonths,
        uint count);
    event RewardsClaimed(uint64 indexed positionNFTTokenID, address indexed owner);
    event TokensUnlocked(uint16 indexed tokenID, address indexed owner, uint count);

    
    event InflationAccrued(uint64 indexed currentPeriod, uint64 periods);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

