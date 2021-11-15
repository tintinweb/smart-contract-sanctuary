// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IReign.sol";
import "../interfaces/IBasketBalancer.sol";
import "./ReignDiamond.sol";
import "./Bridge.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract ReignDAO is Bridge {
    using SafeMath for uint256;

    enum ProposalState {
        WarmUp,
        Active,
        Canceled,
        Failed,
        Accepted,
        Queued,
        Grace,
        Expired,
        Executed,
        Abrogated
    }

    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint256 votes;
        // support
        bool support;
    }

    struct AbrogationProposal {
        address creator;
        uint256 createTime;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        mapping(address => Receipt) receipts;
    }

    struct ProposalParameters {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
    }

    struct Proposal {
        // proposal identifiers
        // unique id
        uint256 id;
        // Creator of the proposal
        address proposer;
        // proposal description
        string description;
        string title;
        // proposal technical details
        // ordered list of target addresses to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;
        // proposal creation time - 1
        uint256 createTime;
        // votes status
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;
        bool canceled;
        bool executed;
        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;
        ProposalParameters parameters;
    }

    uint256 public lastProposalId;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => AbrogationProposal) public abrogationProposals;
    mapping(address => uint256) public latestProposalIds;
    IReign reign;
    IBasketBalancer basketBalancer;
    bool isInitialized;
    bool public isActive;

    event ProposalCreated(uint256 indexed proposalId);
    event Vote(
        uint256 indexed proposalId,
        address indexed user,
        bool support,
        uint256 power
    );
    event VoteCanceled(uint256 indexed proposalId, address indexed user);
    event ProposalQueued(
        uint256 indexed proposalId,
        address caller,
        uint256 eta
    );
    event ProposalExecuted(uint256 indexed proposalId, address caller);
    event ProposalCanceled(uint256 indexed proposalId, address caller);
    event AbrogationProposalStarted(uint256 indexed proposalId, address caller);
    event AbrogationProposalExecuted(
        uint256 indexed proposalId,
        address caller
    );
    event AbrogationProposalVote(
        uint256 indexed proposalId,
        address indexed user,
        bool support,
        uint256 power
    );
    event AbrogationProposalVoteCancelled(
        uint256 indexed proposalId,
        address indexed user
    );

    receive() external payable {}

    // executed only once
    function initialize(
        address _reignAddr,
        address _basketBalancer,
        address _smartPool
    ) public {
        require(isInitialized == false, "Contract already initialized.");
        require(_reignAddr != address(0), "reign must not be 0x0");

        reign = IReign(_reignAddr);
        basketBalancer = IBasketBalancer(_basketBalancer);
        setSmartPoolInitial(_smartPool);
        isInitialized = true;
    }

    function activate() public {
        require(!isActive, "DAO already active");
        require(
            reign.reignStaked() >= ACTIVATION_THRESHOLD,
            "Threshold not met yet"
        );

        isActive = true;
    }

    function triggerWeightUpdate() public {
        // this will revert if epoch is not over
        basketBalancer.updateBasketBalance();

        // get etsablished weights
        address[] memory token = basketBalancer.getTokens();
        uint256[] memory weights = new uint256[](token.length);
        for (uint256 i = 0; i < token.length; i++) {
            weights[i] = basketBalancer.getTargetAllocation(token[i]);
        }

        //update weights gradually in smartPool
        updateWeights(weights);
    }

    function triggerApplyAddToken() public {
        // apply addition of new token, reverts if token add lock is not elapsed
        applyAddToken();
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory description,
        string memory title
    ) public returns (uint256) {
        if (!isActive) {
            require(
                reign.reignStaked() >= ACTIVATION_THRESHOLD,
                "DAO not yet active"
            );
            isActive = true;
        }

        require(
            reign.votingPowerAtTs(msg.sender, block.timestamp - 1) >=
                _getCreationThreshold(),
            "Creation threshold not met"
        );
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "Proposal function information arity mismatch"
        );
        require(targets.length != 0, "Must provide actions");
        require(
            targets.length <= PROPOSAL_MAX_ACTIONS,
            "Too many actions on a vote"
        );
        require(bytes(title).length > 0, "title can't be empty");
        require(bytes(description).length > 0, "description can't be empty");

        // check if user has another running vote
        uint256 previousProposalId = latestProposalIds[msg.sender];
        if (previousProposalId != 0) {
            require(
                _isLiveState(previousProposalId) == false,
                "One live proposal per proposer"
            );
        }

        uint256 newProposalId = lastProposalId + 1;
        Proposal storage newProposal = proposals[newProposalId];
        newProposal.id = newProposalId;
        newProposal.proposer = msg.sender;
        newProposal.description = description;
        newProposal.title = title;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.createTime = block.timestamp - 1;
        newProposal.parameters.warmUpDuration = warmUpDuration;
        newProposal.parameters.activeDuration = activeDuration;
        newProposal.parameters.queueDuration = queueDuration;
        newProposal.parameters.gracePeriodDuration = gracePeriodDuration;
        newProposal.parameters.acceptanceThreshold = acceptanceThreshold;
        newProposal.parameters.minQuorum = minQuorum;

        lastProposalId = newProposalId;
        latestProposalIds[msg.sender] = newProposalId;

        emit ProposalCreated(newProposalId);

        return newProposalId;
    }

    function queue(uint256 proposalId) public {
        require(
            state(proposalId) == ProposalState.Accepted,
            "Proposal can only be queued if it is succeeded"
        );

        Proposal storage proposal = proposals[proposalId];
        uint256 eta =
            proposal.createTime +
                proposal.parameters.warmUpDuration +
                proposal.parameters.activeDuration +
                proposal.parameters.queueDuration;
        proposal.eta = eta;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            require(
                !queuedTransactions[
                    _getTxHash(
                        proposal.targets[i],
                        proposal.values[i],
                        proposal.signatures[i],
                        proposal.calldatas[i],
                        eta
                    )
                ],
                "proposal action already queued at eta"
            );

            queueTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                eta
            );
        }

        emit ProposalQueued(proposalId, msg.sender, eta);
    }

    function execute(uint256 proposalId) public payable {
        require(_canBeExecuted(proposalId), "Cannot be executed");

        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            executeTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalExecuted(proposalId, msg.sender);
    }

    function cancelProposal(uint256 proposalId) public {
        require(
            _isCancellableState(proposalId),
            "Proposal in state that does not allow cancellation"
        );
        require(
            _canCancelProposal(proposalId),
            "Cancellation requirements not met"
        );

        Proposal storage proposal = proposals[proposalId];
        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit ProposalCanceled(proposalId, msg.sender);
    }

    function castVote(uint256 proposalId, bool support) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];

        // exit if user already voted
        require(
            receipt.hasVoted == false ||
                (receipt.hasVoted && receipt.support != support),
            "Already voted this option"
        );

        uint256 votes =
            reign.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));
        require(votes > 0, "no voting power");

        // means it changed its vote
        if (receipt.hasVoted) {
            if (receipt.support) {
                proposal.forVotes = proposal.forVotes.sub(receipt.votes);
            } else {
                proposal.againstVotes = proposal.againstVotes.sub(
                    receipt.votes
                );
            }
        }

        if (support) {
            proposal.forVotes = proposal.forVotes.add(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.add(votes);
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.support = support;

        emit Vote(proposalId, msg.sender, support, votes);
    }

    function cancelVote(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Active, "Voting is closed");

        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[msg.sender];

        uint256 votes =
            reign.votingPowerAtTs(msg.sender, _getSnapshotTimestamp(proposal));

        require(receipt.hasVoted, "Cannot cancel if not voted yet");

        if (receipt.support) {
            proposal.forVotes = proposal.forVotes.sub(votes);
        } else {
            proposal.againstVotes = proposal.againstVotes.sub(votes);
        }

        receipt.hasVoted = false;
        receipt.votes = 0;
        receipt.support = false;

        emit VoteCanceled(proposalId, msg.sender);
    }

    // ======================================================================================================
    // Abrogation proposal methods
    // ======================================================================================================

    // the Abrogation Proposal is a mechanism for the DAO participants to veto the execution of a proposal that was already
    // accepted and it is currently queued. For the Abrogation Proposal to pass, 50% + 1 of the vBOND holders
    // must vote FOR the Abrogation Proposal
    function startAbrogationProposal(
        uint256 proposalId,
        string memory description
    ) public {
        require(
            state(proposalId) == ProposalState.Queued,
            "Proposal must be in queue"
        );
        require(
            reign.votingPowerAtTs(msg.sender, block.timestamp - 1) >=
                _getCreationThreshold(),
            "Creation threshold not met"
        );

        AbrogationProposal storage ap = abrogationProposals[proposalId];

        require(ap.createTime == 0, "Abrogation proposal already exists");
        require(bytes(description).length > 0, "description can't be empty");

        ap.createTime = block.timestamp;
        ap.creator = msg.sender;
        ap.description = description;

        emit AbrogationProposalStarted(proposalId, msg.sender);
    }

    // abrogateProposal cancels a proposal if there's an Abrogation Proposal that passed
    function abrogateProposal(uint256 proposalId) public {
        require(
            state(proposalId) == ProposalState.Abrogated,
            "Cannot be abrogated"
        );

        Proposal storage proposal = proposals[proposalId];

        require(proposal.canceled == false, "Cannot be abrogated");

        proposal.canceled = true;

        for (uint256 i = 0; i < proposal.targets.length; i++) {
            cancelTransaction(
                proposal.targets[i],
                proposal.values[i],
                proposal.signatures[i],
                proposal.calldatas[i],
                proposal.eta
            );
        }

        emit AbrogationProposalExecuted(proposalId, msg.sender);
    }

    function abrogationProposal_castVote(uint256 proposalId, bool support)
        public
    {
        require(
            0 < proposalId && proposalId <= lastProposalId,
            "invalid proposal id"
        );

        AbrogationProposal storage abrogationProposal =
            abrogationProposals[proposalId];
        require(
            state(proposalId) == ProposalState.Queued &&
                abrogationProposal.createTime != 0,
            "Abrogation Proposal not active"
        );

        Receipt storage receipt = abrogationProposal.receipts[msg.sender];
        require(
            receipt.hasVoted == false ||
                (receipt.hasVoted && receipt.support != support),
            "Already voted this option"
        );

        uint256 votes =
            reign.votingPowerAtTs(
                msg.sender,
                abrogationProposal.createTime - 1
            );
        require(votes > 0, "no voting power");

        // means it changed its vote
        if (receipt.hasVoted) {
            if (receipt.support) {
                abrogationProposal.forVotes = abrogationProposal.forVotes.sub(
                    receipt.votes
                );
            } else {
                abrogationProposal.againstVotes = abrogationProposal
                    .againstVotes
                    .sub(receipt.votes);
            }
        }

        if (support) {
            abrogationProposal.forVotes = abrogationProposal.forVotes.add(
                votes
            );
        } else {
            abrogationProposal.againstVotes = abrogationProposal
                .againstVotes
                .add(votes);
        }

        receipt.hasVoted = true;
        receipt.votes = votes;
        receipt.support = support;

        emit AbrogationProposalVote(proposalId, msg.sender, support, votes);
    }

    function abrogationProposal_cancelVote(uint256 proposalId) public {
        require(
            0 < proposalId && proposalId <= lastProposalId,
            "invalid proposal id"
        );

        AbrogationProposal storage abrogationProposal =
            abrogationProposals[proposalId];
        Receipt storage receipt = abrogationProposal.receipts[msg.sender];

        require(
            state(proposalId) == ProposalState.Queued &&
                abrogationProposal.createTime != 0,
            "Abrogation Proposal not active"
        );

        uint256 votes =
            reign.votingPowerAtTs(
                msg.sender,
                abrogationProposal.createTime - 1
            );

        require(receipt.hasVoted, "Cannot cancel if not voted yet");

        if (receipt.support) {
            abrogationProposal.forVotes = abrogationProposal.forVotes.sub(
                votes
            );
        } else {
            abrogationProposal.againstVotes = abrogationProposal
                .againstVotes
                .sub(votes);
        }

        receipt.hasVoted = false;
        receipt.votes = 0;
        receipt.support = false;

        emit AbrogationProposalVoteCancelled(proposalId, msg.sender);
    }

    // ======================================================================================================
    // views
    // ======================================================================================================

    function state(uint256 proposalId) public view returns (ProposalState) {
        require(
            0 < proposalId && proposalId <= lastProposalId,
            "invalid proposal id"
        );

        Proposal storage proposal = proposals[proposalId];

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (
            block.timestamp <=
            proposal.createTime + proposal.parameters.warmUpDuration
        ) {
            return ProposalState.WarmUp;
        }

        if (
            block.timestamp <=
            proposal.createTime +
                proposal.parameters.warmUpDuration +
                proposal.parameters.activeDuration
        ) {
            return ProposalState.Active;
        }

        if (
            (proposal.forVotes + proposal.againstVotes) <
            _getQuorum(proposal) ||
            (proposal.forVotes < _getMinForVotes(proposal))
        ) {
            return ProposalState.Failed;
        }

        // what it checks here is if the proposal is not queued
        if (proposal.eta == 0) {
            return ProposalState.Accepted;
        }

        if (block.timestamp < proposal.eta) {
            return ProposalState.Queued;
        }

        if (_proposalAbrogated(proposalId)) {
            return ProposalState.Abrogated;
        }

        if (
            block.timestamp <=
            proposal.eta + proposal.parameters.gracePeriodDuration
        ) {
            return ProposalState.Grace;
        }

        return ProposalState.Expired;
    }

    function getReceipt(uint256 proposalId, address voter)
        public
        view
        returns (Receipt memory)
    {
        return proposals[proposalId].receipts[voter];
    }

    function getProposalParameters(uint256 proposalId)
        public
        view
        returns (ProposalParameters memory)
    {
        return proposals[proposalId].parameters;
    }

    function getAbrogationProposalReceipt(uint256 proposalId, address voter)
        public
        view
        returns (Receipt memory)
    {
        return abrogationProposals[proposalId].receipts[voter];
    }

    function getActions(uint256 proposalId)
        public
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

    function getProposalQuorum(uint256 proposalId)
        public
        view
        returns (uint256)
    {
        require(
            0 < proposalId && proposalId <= lastProposalId,
            "invalid proposal id"
        );

        return _getQuorum(proposals[proposalId]);
    }

    // ======================================================================================================
    // internal methods
    // ======================================================================================================

    function _canCancelProposal(uint256 proposalId)
        internal
        view
        returns (bool)
    {
        Proposal storage proposal = proposals[proposalId];

        if (
            msg.sender == proposal.proposer ||
            reign.votingPower(proposal.proposer) < _getCreationThreshold()
        ) {
            return true;
        }

        return false;
    }

    function _isCancellableState(uint256 proposalId)
        internal
        view
        returns (bool)
    {
        ProposalState s = state(proposalId);

        return s == ProposalState.WarmUp || s == ProposalState.Active;
    }

    function _isLiveState(uint256 proposalId) internal view returns (bool) {
        ProposalState s = state(proposalId);

        return
            s == ProposalState.WarmUp ||
            s == ProposalState.Active ||
            s == ProposalState.Accepted ||
            s == ProposalState.Queued ||
            s == ProposalState.Grace;
    }

    function _canBeExecuted(uint256 proposalId) internal view returns (bool) {
        return state(proposalId) == ProposalState.Grace;
    }

    function _getMinForVotes(Proposal storage proposal)
        internal
        view
        returns (uint256)
    {
        return
            (proposal.forVotes + proposal.againstVotes)
                .mul(proposal.parameters.acceptanceThreshold)
                .div(100);
    }

    function _getCreationThreshold() internal view returns (uint256) {
        return reign.reignStaked().div(100);
    }

    // Returns the timestamp of the snapshot for a given proposal
    // If the current block's timestamp is equal to `proposal.createTime + warmUpDuration` then the state function
    // will return WarmUp as state which will prevent any vote to be cast which will gracefully avoid any flashloan attack
    function _getSnapshotTimestamp(Proposal storage proposal)
        internal
        view
        returns (uint256)
    {
        return proposal.createTime + proposal.parameters.warmUpDuration;
    }

    function _getQuorum(Proposal storage proposal)
        internal
        view
        returns (uint256)
    {
        return
            reign
                .reignStakedAtTs(_getSnapshotTimestamp(proposal))
                .mul(proposal.parameters.minQuorum)
                .div(100);
    }

    function _proposalAbrogated(uint256 proposalId)
        internal
        view
        returns (bool)
    {
        Proposal storage p = proposals[proposalId];
        AbrogationProposal storage cp = abrogationProposals[proposalId];

        if (cp.createTime == 0 || block.timestamp < p.eta) {
            return false;
        }

        return cp.forVotes >= reign.reignStakedAtTs(cp.createTime - 1).div(2);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibReignStorage.sol";

interface IReign {
    function BASE_MULTIPLIER() external view returns (uint256);

    // deposit allows a user to add more bond to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current BOND balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of BOND that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp)
        external
        view
        returns (LibReignStorage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // bondStaked returns the total raw amount of BOND staked at the current block
    function reignStaked() external view returns (uint256);

    // reignStakedAtTs returns the total raw amount of BOND users have deposited into the contract
    // it does not include any bonus
    function reignStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakingBoost calculates the multiplier on the user's stake at the current timestamp
    function stakingBoost(address user) external view returns (uint256);

    // stackingBoostAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    function stackingBoostAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);

    // returns the last timestamp in which the user intercated with the staking contarct
    function userLastAction(address user) external view returns (uint256);

    // reignCirculatingSupply returns the current circulating supply of BOND
    function reignCirculatingSupply() external view returns (uint256);

    function getEpochDuration() external view returns (uint256);

    function getEpoch1Start() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint128);

    function stakingBoostAtEpoch(address, uint128)
        external
        view
        returns (uint256);

    function getEpochUserBalance(address, uint128)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

interface IBasketBalancer {
    function addToken(address, uint256) external returns (uint256);

    function hasVotedInEpoch(address, uint128) external view returns (bool);

    function getTargetAllocation(address) external view returns (uint256);

    function full_allocation() external view returns (uint256);

    function updateBasketBalance() external;

    function reignDiamond() external view returns (address);

    function getTokens() external view returns (address[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "diamond-libraries/contracts/libraries/LibDiamond.sol";
import "diamond-libraries/contracts/libraries/LibOwnership.sol";
import "diamond-libraries/contracts/interfaces/IDiamondLoupe.sol";
import "diamond-libraries/contracts/interfaces/IERC165.sol";
import "diamond-libraries/contracts/interfaces/IERC173.sol";

contract ReignDiamond {
    constructor(IDiamondCut.FacetCut[] memory _diamondCut, address _owner)
        payable
    {
        require(_owner != address(0), "owner must not be 0x0");

        LibDiamond.diamondCut(_diamondCut, address(0), new bytes(0));
        LibOwnership.setContractOwner(_owner);

        LibDiamondStorage.DiamondStorage storage ds =
            LibDiamondStorage.diamondStorage();

        // adding ERC165 data
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibDiamondStorage.DiamondStorage storage ds =
            LibDiamondStorage.diamondStorage();

        address facet = address(bytes20(ds.facets[msg.sig].facetAddress));
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
                case 0 {
                    revert(0, returndatasize())
                }
                default {
                    return(0, returndatasize())
                }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./Parameters.sol";
import "../interfaces/ISmartPool.sol";

abstract contract Bridge is Parameters {
    mapping(bytes32 => bool) public queuedTransactions;

    function queueTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes32) {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = true;

        return txHash;
    }

    function cancelTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal {
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);
        queuedTransactions[txHash] = false;
    }

    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal returns (bytes memory) {
        // reignDAO.execute already checks that the proposal is in grace period
        bytes32 txHash = _getTxHash(target, value, signature, data, eta);

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

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) =
            target.call{value: value}(callData);
        require(success, string(returnData));

        return returnData;
    }

    function updateWeights(uint256[] memory weights) internal {
        ISmartPool(smartPool).updateWeightsGradually(
            weights,
            block.number,
            block.number + gradualWeightUpdate // plus 2 days
        );
    }

    function applyAddToken() internal {
        ISmartPool(smartPool).applyAddToken();
    }

    function _getTxHash(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data,
        uint256 eta
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(target, value, signature, data, eta));
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibReignStorage {

    bytes32 constant STORAGE_POSITION = keccak256("org.sovreign.reign.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct EpochBalance {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
        uint256 stakingBoost;
    }

    struct Storage {
        bool initialized;
        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;
        mapping(address => EpochBalance[]) userBalanceHistory;
        mapping(address => uint128) lastWithdrawEpochId;
        // array of reign staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] reignStakedHistory;
        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 reign; // the reign Token
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function reignStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IDiamondCut.sol";
import "./LibDiamondStorage.sol";

library LibDiamond {
    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        uint256 selectorCount = LibDiamondStorage.diamondStorage().selectors.length;

        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            selectorCount = executeDiamondCut(selectorCount, _diamondCut[facetIndex]);
        }

        emit DiamondCut(_diamondCut, _init, _calldata);

        initializeDiamondCut(_init, _calldata);
    }

    // executeDiamondCut takes one single FacetCut action and executes it
    // if FacetCutAction can't be identified, it reverts
    function executeDiamondCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        require(cut.functionSelectors.length > 0, "LibDiamond: No selectors in facet to cut");

        if (cut.action == IDiamondCut.FacetCutAction.Add) {
            require(cut.facetAddress != address(0), "LibDiamond: add facet address can't be address(0)");
            enforceHasContractCode(cut.facetAddress, "LibDiamond: add facet must have code");

            return _handleAddCut(selectorCount, cut);
        }

        if (cut.action == IDiamondCut.FacetCutAction.Replace) {
            require(cut.facetAddress != address(0), "LibDiamond: remove facet address can't be address(0)");
            enforceHasContractCode(cut.facetAddress, "LibDiamond: remove facet must have code");

            return _handleReplaceCut(selectorCount, cut);
        }

        if (cut.action == IDiamondCut.FacetCutAction.Remove) {
            require(cut.facetAddress == address(0), "LibDiamond: remove facet address must be address(0)");

            return _handleRemoveCut(selectorCount, cut);
        }

        revert("LibDiamondCut: Incorrect FacetCutAction");
    }

    // _handleAddCut executes a cut with the type Add
    // it reverts if the selector already exists
    function _handleAddCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];

            address oldFacetAddress = ds.facets[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");

            ds.facets[selector] = LibDiamondStorage.Facet(
                cut.facetAddress,
                uint16(selectorCount)
            );
            ds.selectors.push(selector);

            selectorCount++;
        }

        return selectorCount;
    }

    // _handleReplaceCut executes a cut with the type Replace
    // it does not allow replacing immutable functions
    // it does not allow replacing with the same function
    // it does not allow replacing a function that does not exist
    function _handleReplaceCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];

            address oldFacetAddress = ds.facets[selector].facetAddress;

            // only useful if immutable functions exist
            require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
            require(oldFacetAddress != cut.facetAddress, "LibDiamondCut: Can't replace function with same function");
            require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");

            // replace old facet address
            ds.facets[selector].facetAddress = cut.facetAddress;
        }

        return selectorCount;
    }

    // _handleRemoveCut executes a cut with the type Remove
    // for efficiency, the selector to be deleted is replaced with the last one and then the last one is popped
    // it reverts if the function doesn't exist or it's immutable
    function _handleRemoveCut(uint256 selectorCount, IDiamondCut.FacetCut memory cut) internal returns (uint256) {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        for (uint256 selectorIndex; selectorIndex < cut.functionSelectors.length; selectorIndex++) {
            bytes4 selector = cut.functionSelectors[selectorIndex];

            LibDiamondStorage.Facet memory oldFacet = ds.facets[selector];

            require(oldFacet.facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
            require(oldFacet.facetAddress != address(this), "LibDiamondCut: Can't remove immutable function.");

            // replace selector with last selector
            if (oldFacet.selectorPosition != selectorCount - 1) {
                bytes4 lastSelector = ds.selectors[selectorCount - 1];
                ds.selectors[oldFacet.selectorPosition] = lastSelector;
                ds.facets[lastSelector].selectorPosition = oldFacet.selectorPosition;
            }

            // delete last selector
            ds.selectors.pop();
            delete ds.facets[selector];

            selectorCount--;
        }

        return selectorCount;
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but _calldata is not empty");
            return;
        }

        require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
        if (_init != address(this)) {
            enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        }

        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up the error
                revert(string(error));
            } else {
                revert("LibDiamondCut: _init function reverted");
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./LibDiamondStorage.sol";

library LibOwnership {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        address previousOwner = ds.contractOwner;
        require(previousOwner != _newOwner, "Previous owner and new owner must be different");

        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage.diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner, "Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner, "Must be contract owner");
        _;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;

        // ERC165
        mapping(bytes4 => bool) supportedInterfaces;

        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract Parameters {
    // These values are set very low in the beginnign to allow the DAO to quickly interveen in case of
    // maliscious attacks or other problems.
    // Once the DAO has reched a more mature stage these will be voted to be 3-4 days each
    uint256 public warmUpDuration = 1 hours;
    uint256 public activeDuration = 1 hours;
    uint256 public queueDuration = 1 hours;
    uint256 public gracePeriodDuration = 1 hours;

    uint256 public gradualWeightUpdate = 13300; // 2 days in blocks

    uint256 public acceptanceThreshold = 60;
    uint256 public minQuorum = 40;

    address public smartPool;

    uint256 constant ACTIVATION_THRESHOLD = 4_000_000 * 10**18;
    uint256 constant PROPOSAL_MAX_ACTIONS = 10;

    modifier onlyDAO() {
        require(msg.sender == address(this), "Only DAO can call");
        _;
    }

    function setWarmUpDuration(uint256 period) public onlyDAO {
        warmUpDuration = period;
    }

    function setSmartPoolAddress(address _smartPool) public onlyDAO {
        smartPool = _smartPool;
    }

    function setSmartPoolInitial(address _smartPool) public {
        require(
            smartPool == address(0),
            "Can only initialize smartPool address once"
        );
        smartPool = _smartPool;
    }

    function setGradualWeightUpdate(uint256 period) public onlyDAO {
        gradualWeightUpdate = period;
    }

    function setActiveDuration(uint256 period) public onlyDAO {
        require(period >= 1 days, "period must be > 0");
        activeDuration = period;
    }

    function setQueueDuration(uint256 period) public onlyDAO {
        queueDuration = period;
    }

    function setGracePeriodDuration(uint256 period) public onlyDAO {
        require(period >= 1 days, "period must be > 0");
        gracePeriodDuration = period;
    }

    function setAcceptanceThreshold(uint256 threshold) public onlyDAO {
        require(threshold <= 100, "Maximum is 100.");
        require(threshold > 50, "Minimum is 50.");

        acceptanceThreshold = threshold;
    }

    function setMinQuorum(uint256 quorum) public onlyDAO {
        require(quorum > 5, "quorum must be greater than 5");
        require(quorum <= 100, "Maximum is 100.");

        minQuorum = quorum;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

abstract contract BalancerOwnable {
    function setController(address controller) external virtual;
}

abstract contract AbstractPool is BalancerOwnable {
    function setSwapFee(uint256 swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;

    function totalSupply() external virtual returns (uint256);
}

abstract contract ConfigurableRightsPool is AbstractPool {
    struct PoolParams {
        string poolTokenSymbol;
        string poolTokenName;
        address[] constituentTokens;
        uint256[] tokenBalances;
        uint256[] tokenWeights;
        uint256 swapFee;
    }

    struct CrpParams {
        uint256 initialSupply;
        uint256 minimumWeightChangeBlockPeriod;
        uint256 addTokenTimeLockInBlocks;
    }

    function createPool(
        uint256 initialSupply,
        uint256 minimumWeightChangeBlockPeriod,
        uint256 addTokenTimeLockInBlocks
    ) external virtual;

    function createPool(uint256 initialSupply) external virtual;

    function setCap(uint256 newCap) external virtual;

    function updateWeight(address token, uint256 newWeight) external virtual;

    function updateWeightsGradually(
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external virtual;

    function commitAddToken(
        address token,
        uint256 balance,
        uint256 denormalizedWeight
    ) external virtual;

    function applyAddToken() external virtual;

    function removeToken(address token) external virtual;

    function whitelistLiquidityProvider(address provider) external virtual;

    function removeWhitelistedLiquidityProvider(address provider)
        external
        virtual;

    function bPool() external view virtual returns (BPool);
}

abstract contract BPool is AbstractPool {
    function finalize() external virtual;

    function bind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function rebind(
        address token,
        uint256 balance,
        uint256 denorm
    ) external virtual;

    function unbind(address token) external virtual;

    function isBound(address t) external view virtual returns (bool);

    function getCurrentTokens()
        external
        view
        virtual
        returns (address[] memory);

    function getFinalTokens() external view virtual returns (address[] memory);

    function getBalance(address token) external view virtual returns (uint256);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure virtual returns (uint256 poolAmountOut);

    function calcPoolInGivenSingleOut(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external pure virtual returns (uint256 poolAmountIn);

    function getDenormalizedWeight(address token)
        external
        view
        virtual
        returns (uint256);

    function getTotalDenormalizedWeight()
        external
        view
        virtual
        returns (uint256);

    function getSwapFee() external view virtual returns (uint256);
}

abstract contract ISmartPool is BalancerOwnable {
    function updateWeightsGradually(
        uint256[] memory,
        uint256,
        uint256
    ) external virtual;

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external virtual returns (uint256);

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external virtual returns (uint256);

    function approve(address spender, uint256 value)
        external
        virtual
        returns (bool);

    function balanceOf(address owner) external view virtual returns (uint256);

    function totalSupply() external view virtual returns (uint256);

    function setSwapFee(uint256 swapFee) external virtual;

    function setPublicSwap(bool public_) external virtual;

    function getDenormalizedWeight(address token)
        external
        view
        virtual
        returns (uint256);

    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn)
        external
        virtual;

    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut)
        external
        virtual;

    function bPool() external view virtual returns (BPool);

    function applyAddToken() external virtual;

    function getSmartPoolManagerVersion()
        external
        view
        virtual
        returns (address);
}

abstract contract SmartPoolManager {
    function joinPool(
        ConfigurableRightsPool,
        BPool,
        uint256 poolAmountOut,
        uint256[] calldata maxAmountsIn
    ) external view virtual returns (uint256[] memory actualAmountsIn);

    function exitPool(
        ConfigurableRightsPool self,
        BPool bPool,
        uint256 poolAmountIn,
        uint256[] calldata minAmountsOut
    )
        external
        view
        virtual
        returns (
            uint256 exitFee,
            uint256 pAiAfterExitFee,
            uint256[] memory actualAmountsOut
        );

    function joinswapExternAmountIn(
        ConfigurableRightsPool self,
        BPool bPool,
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external view virtual returns (uint256 poolAmountOut);
}

