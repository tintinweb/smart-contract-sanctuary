/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-15
*/

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

contract GovernorAlpha {
    /// @notice The name of this contract
    string public constant name = "ASTR Governor Alpha";
    
    uint quorumVote = 40e18;
    
    uint minVoterCount = 1;
    
    uint minProposalTimeIntervalSec = 1 days;
    
    uint public lastProposalTimeIntervalSec;

    uint256 public proposalTokens = 500 * 10**18;

    uint256 public lastProposal;

    /// @notice To track the initialize time of Governance contract.
    uint256 public startTime;

    /// @notice The number of votes in support of a proposal required in order for a quorum to be reached and for a vote to succeed
    function quorumVotes() public view returns (uint) { return quorumVote; } // 4% of ASTR

    /// @notice The number of votes required in order for a voter to become a proposer
    function proposalThreshold() public pure returns (uint) { return 10e18; } // 1% of ASTR

    /// @notice The maximum number of actions that can be included in a proposal
    function proposalMaxOperations() public pure returns (uint) { return 10; } // 10 actions

    /// @notice The delay before voting on a proposal may take place, once proposed
    function votingDelay() public pure returns (uint) { return 1; } // 1 block

    /// @notice The duration of voting on a proposal, in blocks
    function votingPeriod() public pure returns (uint) { return 30; } // ~7 days in blocks (assuming 15s blocks)
    
    /// @notice Minimum number of voters
    function minVotersCount() public view returns (uint) { return minVoterCount; }

    /// @notice The address of the ASTR Protocol Timelock
    TimelockInterface public timelock;

    /// @notice The address of the ASTR governance token
    ASTRInterface public ASTR;

    /// @notice The address of the ASTRA Top 100 token holders
    IHolders public topTraders;

    /// @notice The total number of proposals
    uint public proposalCount;
    
    // @notice voter info 
    struct VoterInfo {
        /// @notice Map voter address for proposal
        mapping (address => bool) voterAddress;
        /// @notice Governors votes
        uint voterCount;
        /// @notice Governors votes
        uint256 governors;
    }

    struct Proposal {
        /// @notice ASTRque id for looking up a proposal
        uint id;

        /// @notice Creator of the proposal
        address proposer;

        /// @notice The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint eta;

        /// @notice the ordered list of target addresses for calls to be made
        address[] targets;

        /// @notice The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint[] values;

        /// @notice The ordered list of function signatures to be called
        string[] signatures;

        /// @notice The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        /// @notice The block at which voting begins: holders must delegate their votes prior to this block
        uint startBlock;

        /// @notice The block at which voting ends: votes must be cast prior to this block
        uint endBlock;

        /// @notice Current number of votes in favor of this proposal
        uint forVotes;

        /// @notice Current number of votes in opposition to this proposal
        uint againstVotes;

        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;

        /// @notice Flag marking whether the proposal has been executed
        bool executed;

        /// @notice Check is fundamenal changes
        bool fundamentalchanges;

        /// @notice Receipts of ballots for the entire set of voters
        mapping (address => Receipt) receipts;
    }

    /// @notice Track Time proposal is created
    mapping(uint256 => uint256)public proposalCreatedTime;

    /// @notice Ballot receipt record for a voter
    struct Receipt {
        /// @notice Whether or not a vote has been cast
        bool hasVoted;

        /// @notice Whether or not the voter supports the proposal
        bool support;

        /// @notice The number of votes the voter had, which were cast
        uint votes;
    }

    /// @notice Possible states that a proposal may be in
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
    
    /// @notice Chef Contract address for getting top stakers
    address public chefAddress;

    /// @notice The official record of all voters with id
    mapping (uint => VoterInfo) public votersInfo;

    /// @notice The official record of all proposals ever proposed
    mapping (uint => Proposal) public proposals;

    /// @notice The latest proposal for each proposer
    mapping (address => uint) public latestProposalIds;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the ballot struct used by the contract
    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,bool support)");

    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(uint id, address proposer, address[] targets, uint[] values, string[] signatures, bytes[] calldatas, uint startBlock, uint endBlock, string description);

    /// @notice An event emitted when a vote has been cast on a proposal
    event VoteCast(address voter, uint proposalId, bool support, uint votes);

    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint id, uint eta);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint id);

    constructor(address timelock_, address ASTR_,address _chef) public {
        timelock = TimelockInterface(timelock_);
        ASTR = ASTRInterface(ASTR_);
        // topTraders = IHolders(_holders);
        chefAddress = _chef;
        startTime = block.timestamp;
    }
    
    function updateQuorumValue(uint256 _quorumValue) public {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        quorumVote = _quorumValue; 
    }
    
    function updateMinVotersValue(uint256 _minVotersValue) public {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        minVoterCount = _minVotersValue; 
    }
    
    function updateMinProposalTimeIntervalSec(uint256 _minProposalTimeIntervalSec) public {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        minProposalTimeIntervalSec = _minProposalTimeIntervalSec; 
    }

    function updateProposalTokens(uint256 _proposalTokens) public {
        require(msg.sender == address(timelock), "Call must come from Timelock.");
        proposalTokens = _proposalTokens; 
    }
    
    function _acceptAdmin() public {
        timelock.acceptAdmin();
    }

    function checkFundamentalchanges(uint256 proposalId)internal view returns(bool){
        Proposal storage proposal = proposals[proposalId];
        return proposal.fundamentalchanges;
    }

    function checkUser(address _address) public returns(bool){
        //lastProposal

        bool returnValue;
        if(votersInfo[lastProposal].voterAddress[_address]){
            for(uint256 i; i<= proposalCount;i++){
        }
        }
        return returnValue;

    }

    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description, bool _fundametalChanges) public returns (uint) {
        // require(ASTR.getPriorVotes(msg.sender, sub256(block.number, 1)) > proposalThreshold(), "GovernorAlpha::propose: proposer votes below proposal threshold");
        require(targets.length == values.length && targets.length == signatures.length && targets.length == calldatas.length, "GovernorAlpha::propose: proposal function information arity mismatch");
        require(targets.length != 0, "GovernorAlpha::propose: must provide actions");
        require(targets.length <= proposalMaxOperations(), "GovernorAlpha::propose: too many actions");
        // require(checkTopTraderStatus(msg.sender), "GovernorAlpha::propose: Only top 100 token holder can create proposal");
        bool isTopStaker = ChefInterface(chefAddress).checkHighestStaker(0,msg.sender);
        if(block.timestamp<(startTime+7776000)){
        require(isTopStaker == true,"GovernorAlpha::propose: Only Top stakers can create proposal");
        }
        (bool transferStatus) = depositToken(msg.sender, address(this), proposalTokens);
        require(transferStatus == true, "GovernorAlpha::propose: need to transfer some tokens on contract to create proposal");
        
        require(add256(lastProposalTimeIntervalSec, sub256(minProposalTimeIntervalSec, mod256(lastProposalTimeIntervalSec, minProposalTimeIntervalSec))) < now, "GovernorAlpha::propose: Only one proposal can be create in one day");

        uint latestProposalId = latestProposalIds[msg.sender];
        if (latestProposalId != 0) {
          ProposalState proposersLatestProposalState = state(latestProposalId);
          require(proposersLatestProposalState != ProposalState.Active, "GovernorAlpha::propose: one live proposal per proposer, found an already active proposal");
          require(proposersLatestProposalState != ProposalState.Pending, "GovernorAlpha::propose: one live proposal per proposer, found an already pending proposal");
        }
        uint256 returnValue = setProposalDetail( targets, values, signatures, calldatas, description, _fundametalChanges);
        return returnValue;
    }

    function setProposalDetail(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description, bool _fundametalChanges)internal returns (uint){
        uint startBlock = add256(block.number, votingDelay());
        uint endBlock = add256(startBlock, votingPeriod());
        proposalCount++;
        Proposal memory newProposal = Proposal({
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
            canceled: false,
            executed: false,
            fundamentalchanges:_fundametalChanges
        });
        proposalCreatedTime[proposalCount] = block.number;

        proposals[newProposal.id] = newProposal;
        latestProposalIds[newProposal.proposer] = newProposal.id;
        lastProposalTimeIntervalSec = block.timestamp;
        
        emit ProposalCreated(newProposal.id, msg.sender, targets, values, signatures, calldatas, startBlock, endBlock, description);
        return newProposal.id;
    }

    function depositToken(address sender, address recipient, uint256 amount) internal returns(bool) {
        bool transferStatus = ASTR.transferFrom(sender, recipient, amount);
        return transferStatus;
    }
    
    function checkTopTraderStatus(address _trader) internal view returns(bool) {
        bool topHolderStatus = topTraders.checktoptrader(_trader);
        return topHolderStatus;
    }

    function queue(uint proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "GovernorAlpha::queue: proposal can only be queued if it is succeeded");
        require(votersInfo[proposalId].voterCount >= minVoterCount, "GovernorAlpha::queue: proposal require atleast min governers quorum");
        Proposal storage proposal = proposals[proposalId];
        uint eta = add256(block.timestamp, timelock.delay()); 
        for (uint i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        proposal.eta = eta;
        emit ProposalQueued(proposalId, eta);
    }

    function _queueOrRevert(address target, uint value, string memory signature, bytes memory data, uint eta) internal {
        require(!timelock.queuedTransactions(keccak256(abi.encode(target, value, signature, data, eta))), "GovernorAlpha::_queueOrRevert: proposal action already queued at eta");
        timelock.queueTransaction(target, value, signature, data, eta);
    }

    function execute(uint256 proposalId) public payable {
        require(state(proposalId) == ProposalState.Queued, "GovernorAlpha::execute: proposal can only be executed if it is queued");
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.executeTransaction.value(proposal.values[i])(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }
        lastProposal = proposalId;
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint proposalId) public {
        ProposalState state = state(proposalId);
        require(state != ProposalState.Executed, "GovernorAlpha::cancel: cannot cancel executed proposal");

        Proposal storage proposal = proposals[proposalId];
        // require(ASTR.getPriorVotes(proposal.proposer, sub256(block.number, 1)) < proposalThreshold(), "GovernorAlpha::cancel: proposer above threshold");

        proposal.canceled = true;
        for (uint i = 0; i < proposal.targets.length; i++) {
            timelock.cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], proposal.eta);
        }

        emit ProposalCanceled(proposalId);
    }

    function getActions(uint proposalId) public view returns (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }

    function getReceipt(uint proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }

    function state(uint proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        bool checkifMinGovenor;
        bool checkFastVote = checkfastvote(proposalId);
        uint256 percentage = 10;
        if(proposal.fundamentalchanges){
            percentage = 20;
            if(votersInfo[proposalId].governors>=2){
                checkifMinGovenor = true;
            }else{
                checkifMinGovenor = false;
            }
        }else{
            if(votersInfo[proposalId].governors>=1){
                checkifMinGovenor = true;
            }else{
                checkifMinGovenor = false;
            }
        }
        if(checkFastVote && checkifMinGovenor){
            return ProposalState.Succeeded;
        }
        else if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorumVotes()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {

            if(checkifMinGovenor){
                    if(proposal.againstVotes==0){
                        return ProposalState.Succeeded;
                    }else{
                    uint256 voteper=  div256(mul256(sub256(proposal.forVotes, proposal.againstVotes),100), proposal.againstVotes);
                     if(voteper>percentage){
                        return ProposalState.Succeeded;
                    }
                    }
            }
            return ProposalState.Defeated;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= add256(proposal.eta, timelock.GRACE_PERIOD())) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }

    function checkfastvote(uint proposalId) public view returns (bool){
        require(proposalCount >= proposalId && proposalId > 0, "GovernorAlpha::state: invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        uint256 oneday = proposalCreatedTime[proposalId]+5;
        uint256 percentage = 10;
        bool returnValue;
        if(proposal.fundamentalchanges==false && block.number <= oneday){
            if (block.number <= proposal.endBlock && proposal.againstVotes <= proposal.forVotes && proposal.forVotes >= quorumVotes()) {
                    // uint256 voteper= proposal.forVotes.sub(proposal.againstVotes).mul(100).div(proposal.againstVotes);
                    if(proposal.againstVotes==0){
                        returnValue = true;
                    }else{
                        uint256 voteper=  div256(mul256(sub256(proposal.forVotes, proposal.againstVotes),100), proposal.againstVotes);
                    if(voteper>percentage){
                        returnValue = true;
                    }
                    }
            }
        }

        return returnValue;
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
        bool isTopStaker = ChefInterface(chefAddress).checkHighestStaker(0,msg.sender);
        if(!votersInfo[proposalId].voterAddress[voter])
        {
          votersInfo[proposalId].voterAddress[voter] = true;
          votersInfo[proposalId].voterCount++;
          if(isTopStaker){
              votersInfo[proposalId].governors++;
          }
        }
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(receipt.hasVoted == false, "GovernorAlpha::_castVote: voter already voted");
        // uint256 votes = ASTR.getPriorVotes(voter, proposal.startBlock);
        uint256 votes = ChefInterface(chefAddress).stakingScore(0,voter);
        // votes = votes.mul(ChefInterface(chefAddress).getRewardMultiplier(0,voter)).div(10);
         votes = div256(mul256(votes,ChefInterface(chefAddress).getRewardMultiplier(0,voter)),10);
        if (support) {
            proposal.forVotes = add256(proposal.forVotes, votes);
        } else {
            proposal.againstVotes = add256(proposal.againstVotes, votes);
        }

        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;

        emit VoteCast(voter, proposalId, support, votes);
    }

    function add256(uint256 a, uint256 b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "addition overflow");
        return c;
    }

    function sub256(uint256 a, uint256 b) internal pure returns (uint) {
        require(b <= a, "subtraction underflow");
        return a - b;
    }
    
    function mod256(uint a, uint b) internal pure returns (uint) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function mul256(uint256 a, uint256 b) internal pure returns (uint256) {
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

    function div256(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    } 
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }


    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface TimelockInterface {
    function delay() external view returns (uint);
    function GRACE_PERIOD() external view returns (uint);
    function acceptAdmin() external;
    function queuedTransactions(bytes32 hash) external view returns (bool);
    function queueTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external returns (bytes32);
    function cancelTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external;
    function executeTransaction(address target, uint value, string calldata signature, bytes calldata data, uint eta) external payable returns (bytes memory);
}

interface ASTRInterface {
    function getPriorVotes(address account, uint blockNumber) external view returns (uint);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ChefInterface{
    function checkHighestStaker(uint256 _pid,address user) external view returns (bool);
   function getRewardMultiplier(uint256 _pid, address _user) external view returns (uint256);
   function stakingScore(uint256 _pid, address _userAddress) external view returns (uint256);
}

interface IHolders {
    function checktoptrader(address _addr) external view returns (bool);
}