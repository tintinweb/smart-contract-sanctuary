pragma solidity >=0.7.0;
import "./SafeMathTyped.sol";
import "./AbqErc20.sol";
import "./SingleOwnerForward.sol";

enum GovernanceState 
{
    SubmissionsAccepted,
    SubmissionsOpen,
    SubmissionsSelection,
    VotingStarted,
    ProposalConclusion,
    AwaitingSelectionCall
}

struct Proposal 
{
    // CG: Word 0 start.
    address proposalAddress;    // CG: Word 0; 160 bits total.
    uint32 submissionBatchNumber;   // CG: Word0; 160 + 32 = 192 bits total.
    // CG: Word 0 end.

    // CG: Word 1 start.
    address proposer;
    // CG: Word 1 end.

    // CG: Word 2 start.
    uint256 votesInSupport; // CG: Word 2; 256 bits total.
    // CG: Word 2 full.

    // CG: Word 3 start.
    uint256 votesInOpposition;  // CG: Word 3; 256 bits total.
    // CG: Word 3 full.

    // CG: Word 4 start.
    uint256 proposalDeposit;  // CG: Word 4; 256 bits total.
    // CG: Word 4 full.

    bytes proposalData;

    mapping(address => VoteStatus) votesCasted;
}

enum VoteStatus 
{
    Abstain,
    Support,
    Oppose
}

struct Stake 
{
    uint256 amount;
    address delegate;
}

/// @notice This is a governance contract for the Aardbanq DAO. All ABQ token holders can stake
/// their tokens and delegate their voting rights to an address, including to themselves. 
/// Only one proposal can be voted on to be executed at a time.
/// Voters can stake or unstake their ABQ tokens at anytime using the `stake` and `unstake` method.
/// The protocol for selecting and voting on proposals works as follows:
/// * If there are no pending proposals, then anyone can submit a proposal candidate to be considered provided they pay an ABQ deposit of `proposalDeposit` (which also stores the 18 decimals).
/// * For `submissionWindow` seconds after the first proposal candidate was submitted can submit another proposal candidates by also paying an ABQ deposit of `proposalDeposit` (which also stores the 18 decimals).
/// * When the first proposal candidate is submitted, a proposal to "do nothing" is also automatically created.
/// * During the first `submissionSelectionWindow` seconds after the first proposal candidate was submitted the voters may place their votes with their preferred proposal candidate.
/// * After the first `submissionSelectionWindow` seconds after the first proposal candidate was submitted, the candidate that received the most votes can be made the proposal all voters should vote on, by calling the `selectMostSupportedProposal` function.
/// * In the event of a tie between the candidates for most votes the last candidate will receive presidence. However if the "do nothing" proposal is also tied for most votes, it will always take precedence.
/// * Once a proposal candidate has been established as the proposal, all voters may only vote on that proposal. Voting stays open for `votingWindow` seconds after this.
/// * When `votingWindow` seconds have passed since the proposal candidate has been promoted to the proposal or if the proposal has received more than 50% of all staked votes either for or against it, then the proposal may be executed calling the `resolveProposal` method.
/// * When a propsal is resolved it is considered successful only if more than 50% of all votes on it is in favor if it AND the proposal was resolved within `resolutionWindow` seconds after it was promoted from a proposal candidate to the proposal.
/// * Once the proposal has been resolved a new round of proposal candidates may be submitted again.
/// * All proposal candidates that were not promoted to the proposal and all failed proposals will have their deposits burnt. This is to avoid frivolous and malicious proposals that could cost the voters more gas than the person making the proposal.
/// * All successful proposals will have their deposits returned.
/// A proposal consist of an address and data, that the `daoOwnerContract` delegate calls to the address with the data.
contract StakedVotingGovernance 
{
    // CG: Word 0 start.
    SingleOwnerDelegateCall public daoOwnerContract;   // CG: Word 0; 160 bits total.
    uint32 public currentSubmissionBatchNumber = 1; // CG: Word 0; 160 + 32 = 192 bits total.
    uint64 public submissionStartedDate;    // CG: Word 0; 192 + 64 = 256 bits total.
    // CG: Word 0 full.

    // CG: Word 1 start.
    AbqErc20 public token;  // CG: Word 1; 160 bits total.
    uint64 public votingStartedDate;    // CG: Word 1; 160 + 64 = 224 bits total.
    uint32 public submissionWindow = 2 days;    // CG: Word 1; 224 + 32 = 256 bits.
    // CG: Word 1 full.

    // CG: Word 2 start.
    uint32 public submissionSelectionWindow = 4 days;   // CG: Word 2; 32 bits total.
    uint32 public votingWindow = 3 days;    // CG: Word 2; 32 + 32 = 64 bits total.
    uint32 public resolutionWindow = 10 days;   // CG: Word 2; 64 + 32 = 96 bits total.
    // CG: Word 2 end.

    // CG: Word 3 start.
    uint256 public burnAmount;
    // CG: Word 3 full.

    // CG: Word 4 start.
    bytes32 public currentProposalHash;
    // CG: Word 4 full.
    
    // CG: Word 5 start.
    uint256 public totalVotesStaked;
    // CG: Word 5 full.

    // CG: Word 6 start.
    uint256 public proposalDeposit = 100 ether;
    // CG: Word 6 full.

    bytes32[] public runningProposals;
    mapping(bytes32 => Proposal) public proposals;
    mapping(address => uint256) public refundAmount;

    mapping(address => uint256) public votingPower;
    mapping(address => Stake) public stakes;
    mapping(address => bytes32) public lastVotedOn;

    constructor (SingleOwnerDelegateCall _daoOwnerContract, AbqErc20 _token)
    {
        daoOwnerContract = _daoOwnerContract;
        token = _token;
    }

    modifier onlyDaoOwner()
    {
        require(msg.sender == address(daoOwnerContract), "ABQDAO/only-dao-owner");
        _;
    }

    modifier onlyAcceptingProposalsState()
    {
        GovernanceState governanceState = proposalsState();
        require(governanceState == GovernanceState.SubmissionsAccepted || governanceState == GovernanceState.SubmissionsOpen, "ABQDAO/submissions-not-allowed");
        _;
    }

    modifier onlyVotingState()
    {
        GovernanceState governanceState = proposalsState();
        require(governanceState == GovernanceState.VotingStarted, "ABQDAO/voting-not-allowed");
        _;
    }

    modifier onlyAwaitingSelectionCallState()
    {
        GovernanceState governanceState = proposalsState();
        require(governanceState == GovernanceState.AwaitingSelectionCall, "ABQDAO/selection-call-not-allowed");
        _;
    }

    function changeTimeWindows(uint32 _submissionWindow, uint32 _submissionSelectionWindow, uint32 _votingWindow, uint32 _resolutionWindow)
        onlyDaoOwner()
        external
    {
        // CG: ensure all parameters are between [1 days, 31 days] (in seconds).
        require(_submissionWindow >= 1 days && _submissionWindow <= 31 days, "ABQDAO/out-of-range");
        require(_submissionSelectionWindow >= 1 days && _submissionSelectionWindow <= 31 days, "ABQDAO/out-of-range");
        require(_votingWindow >= 1 days && _votingWindow <= 31 days, "ABQDAO/out-of-range");
        require(_resolutionWindow >= 1 days && _resolutionWindow <= 31 days, "ABQDAO/out-of-range");

        // CG: Ensure dependend windows occur after in the correct order.
        // CG: Given the above constraints that these values aren't greater than 31 days (in seconds), we can safely add 1 day (in seconds) without an overflow happening.
        require(_submissionSelectionWindow >= (_submissionSelectionWindow + 1 days), "ABQDAO/out-of-range");
        require(_resolutionWindow >= (_votingWindow + 1 days), "ABQDAO/out-of-range");

        // CG: Set the values.
        submissionWindow = submissionWindow;
        submissionSelectionWindow = _submissionSelectionWindow;
        votingWindow = _votingWindow;
        resolutionWindow = _resolutionWindow;
    }

    function proposalsState()
        public
        view
        returns (GovernanceState _proposalsState)
    {
        // CG: If no submission has been filed yet, then submissions are eligible.
        if (submissionStartedDate == 0)
        {
            return GovernanceState.SubmissionsAccepted;
        }
        // CG: Allow submissions for submissionWindow after first submission.
        else if (block.timestamp <= SafeMathTyped.add256(submissionStartedDate, submissionWindow))
        {
            return GovernanceState.SubmissionsOpen;
        }
        // CG: Allow selection of to close submissionSelectionWindow after the first submission.
        else if (block.timestamp <= SafeMathTyped.add256(submissionStartedDate, submissionSelectionWindow))
        {
            return GovernanceState.SubmissionsSelection;
        }
        // CG: If more than submissionSelectionWindow has passed since the submissionStartedDate the voting date should be checked.
        else 
        {
            // CG: If voting only happened for votingWindow or less so for, voting is still pending
            if (votingStartedDate == 0)
            {
                return GovernanceState.AwaitingSelectionCall;
            }
            else if (block.timestamp <= SafeMathTyped.add256(votingStartedDate, votingWindow))
            {
                return GovernanceState.VotingStarted;
            }
            // CG: If voting has started more than votingWindow ago, then voting is no longer possible
            else
            {
                return GovernanceState.ProposalConclusion;
            }
        }
    }

    function proposalsCount()
        public
        view
        returns (uint256 _proposalsCount)
    {
        return runningProposals.length;
    }

    function viewVote(bytes32 _proposalHash, address _voter)
        external
        view
        returns (VoteStatus)
    {
        return proposals[_proposalHash].votesCasted[_voter];
    }

    event StakeReceipt(address indexed staker, address indexed delegate, address indexed oldDelegate, bool wasStaked, uint256 amount);
    /// @notice Stake `_amount` of tokens from msg.sender and delegate the voting rights to `_delegate`.
    /// The tokens have to be approved by msg.sender before calling this method. All tokens staked by msg.sender
    /// will be have their voting rights assigned to `_delegate`.
    /// @param _delegate The address to delegate voting rights to.
    /// @param _amount The amount of tokens to stake.
    function stake(address _delegate, uint256 _amount)
        external
    {
        // CG: Transfer ABQ.
        bool couldTransfer = token.transferFrom(msg.sender, address(this), _amount);
        require(couldTransfer, "ABQDAO/could-not-transfer-stake");

        // CG: Get previous stake details.
        Stake storage stakerStake = stakes[msg.sender];
        uint256 previousStake = stakerStake.amount;
        address previousDelegate = stakerStake.delegate;

        // CG: Remove previous delegate stake
        votingPower[previousDelegate] = SafeMathTyped.sub256(votingPower[previousDelegate], previousStake);

        // CG: Increase stake counts.
        stakerStake.amount = SafeMathTyped.add256(stakerStake.amount, _amount);
        stakerStake.delegate = _delegate;
        votingPower[stakerStake.delegate] = SafeMathTyped.add256(votingPower[stakerStake.delegate], stakerStake.amount);

        // CG: Update previous vote
        bytes32 previousDelegateLastProposal = lastVotedOn[previousDelegate];
        bytes32 newDelegateLastProposal = lastVotedOn[stakerStake.delegate];
        updateVoteIfNeeded(previousDelegateLastProposal, previousDelegate, previousStake, newDelegateLastProposal, stakerStake.delegate, stakerStake.amount);

        // CG: Update running total.
        totalVotesStaked = SafeMathTyped.add256(totalVotesStaked, _amount);

        emit StakeReceipt(msg.sender, _delegate, previousDelegate, true, _amount);
    }
    
    /// @notice Unstake `_amount` tokens for msg.sender and send them to msg.sender.
    /// @param _amount The amount of tokens to unstake.
    function unstake(uint256 _amount)
        external
    {
        // CG: Decrease stake counts.
        Stake storage stakerStake = stakes[msg.sender];
        stakerStake.amount = SafeMathTyped.sub256(stakerStake.amount, _amount);
        address delegate = stakerStake.delegate;
        votingPower[delegate] = SafeMathTyped.sub256(votingPower[delegate], _amount);

        // CG: Update previous vote
        bytes32 lastProposal = lastVotedOn[delegate];
        updateVoteIfNeeded(lastProposal, delegate, _amount, lastProposal, delegate, 0);

        // CG: Transfer ABQ back.
        bool couldTransfer = token.transfer(msg.sender, _amount);
        require(couldTransfer, "ABQDAO/could-not-transfer-stake");

        // CG: Update running total.
        totalVotesStaked = SafeMathTyped.sub256(totalVotesStaked, _amount);

        emit StakeReceipt(msg.sender, delegate, delegate, false, _amount);
    }

    function updateVoteIfNeeded(bytes32 _proposalHashA, address _voterA, uint256 _voterADecrease, bytes32 _proposalHashB, address _voterB, uint256 _voterBIncrease)
        private
    {
        GovernanceState governanceState = proposalsState();
        // CG: Only update votes while voting is still open.
        if (governanceState == GovernanceState.SubmissionsOpen || governanceState == GovernanceState.SubmissionsSelection || governanceState == GovernanceState.VotingStarted)
        {
            // CG: Only update votes for current submission round on proposal A.
            Proposal storage proposalA = proposals[_proposalHashA];
            if (proposalA.submissionBatchNumber == currentSubmissionBatchNumber)
            {
                // CG: If voter A has a decrease, decrease it.
                if (_voterADecrease > 0)
                {
                    VoteStatus voterAVote = proposalA.votesCasted[_voterA];
                    if (voterAVote == VoteStatus.Support)
                    {
                        proposalA.votesInSupport = SafeMathTyped.sub256(proposalA.votesInSupport, _voterADecrease);
                        emit Ballot(_voterA, _proposalHashA, voterAVote, votingPower[_voterA]);
                    }
                    else if (voterAVote == VoteStatus.Oppose)
                    {
                        proposalA.votesInOpposition = SafeMathTyped.sub256(proposalA.votesInOpposition, _voterADecrease);
                        emit Ballot(_voterA, _proposalHashA, voterAVote, votingPower[_voterA]);
                    }
                }
            }

            // CG: Only update votes for current submission round on proposal B.
            Proposal storage proposalB = proposals[_proposalHashB];
            if (proposalB.submissionBatchNumber == currentSubmissionBatchNumber)
            {
                // CG: If voter B has an increase, increase it.
                if (_voterBIncrease > 0)
                {
                    VoteStatus voterBVote = proposalB.votesCasted[_voterB];
                    if (voterBVote == VoteStatus.Support)
                    {
                        proposalB.votesInSupport = SafeMathTyped.add256(proposalB.votesInSupport, _voterBIncrease);
                        emit Ballot(_voterB, _proposalHashB, voterBVote, votingPower[_voterB]);
                    }
                    else if (voterBVote == VoteStatus.Oppose)
                    {
                        proposalB.votesInOpposition = SafeMathTyped.add256(proposalB.votesInOpposition, _voterBIncrease);
                        emit Ballot(_voterB, _proposalHashB, voterBVote, votingPower[_voterB]);
                    }
                }
            }
        }
    }

    event ProposalReceipt(bytes32 proposalHash);
    /// @notice Make a poposal for a resolution.
    /// @param _executionAddress The address containing the smart contract to delegate call.
    /// @param _data The data to send when executing the proposal.
    function propose(address _executionAddress, bytes calldata _data)
        onlyAcceptingProposalsState()
        external
        returns (bytes32 _hash)
    {
        // CG: Get proposal hash and make sure it is not already submitted.
        bytes32 proposalHash = keccak256(abi.encodePacked(currentSubmissionBatchNumber, _executionAddress, _data));
        Proposal storage proposal = proposals[proposalHash];
        require(proposal.submissionBatchNumber == 0, "ABQDAO/proposal-already-submitted");

        // CG: Transfer deposit.
        bool couldTransferDeposit = token.transferFrom(msg.sender, address(this), proposalDeposit);
        require(couldTransferDeposit, "ABQDAO/could-not-transfer-deposit");

        // CG: If this is the first proposal, add a "do nothing" proposal as the first proposal
        if (runningProposals.length == 0)
        {
            address doNothingAddress = address(0);
            bytes memory doNothingData = new bytes(0);
            bytes32 doNothingHash = keccak256(abi.encodePacked(currentSubmissionBatchNumber, doNothingAddress, doNothingData));
            
            Proposal storage doNothingProposal = proposals[doNothingHash];
            doNothingProposal.proposalAddress = doNothingAddress;
            doNothingProposal.proposalDeposit = 0;
            doNothingProposal.submissionBatchNumber = currentSubmissionBatchNumber;
            doNothingProposal.proposer = address(0);
            doNothingProposal.votesInSupport = 0;
            doNothingProposal.votesInOpposition = 0;
            doNothingProposal.proposalData = doNothingData;

            runningProposals.push(doNothingHash);
            emit ProposalReceipt(doNothingHash);

            submissionStartedDate = uint64(block.timestamp);
        }

        // CG: Set the proposal data
        proposal.proposalAddress = _executionAddress;
        proposal.proposalDeposit = proposalDeposit;
        proposal.submissionBatchNumber = currentSubmissionBatchNumber;
        proposal.proposer = msg.sender;
        proposal.votesInSupport = 0;
        proposal.votesInOpposition = 0;
        proposal.proposalData = _data;

        runningProposals.push(proposalHash);
        emit ProposalReceipt(proposalHash);

        return proposalHash;
    }

    event VoteOpenedReceipt(bytes32 proposalHash);
    /// @notice Select the most supported proposal.
    /// @param maxIterations The max iteration to execute. This is used to throttle gas useage per call.
    function selectMostSupportedProposal(uint8 maxIterations)
        onlyAwaitingSelectionCallState()
        external
        returns (bool _isSelectionComplete)
    {
        if (votingStartedDate != 0)
        {
            return true;
        }

        while (runningProposals.length > 1 && maxIterations > 0)
        {
            Proposal storage firstProposal = proposals[runningProposals[0]];
            Proposal storage lastProposal = proposals[runningProposals[runningProposals.length - 1]];  // CG: runningProposals.length - 1 will always be >= 1 since we check runningProposals.length > 1 in the while's condition. Hence no overflow will occur.
            if (firstProposal.votesInSupport < lastProposal.votesInSupport)
            {
                burnAmount = SafeMathTyped.add256(burnAmount, firstProposal.proposalDeposit);
                runningProposals[0] = runningProposals[runningProposals.length - 1];  // CG: runningProposals.length - 1 will always be >= 1 since we check runningProposals.length > 1 in the while's condition. Hence no overflow will occur.
            }
            else
            {
                burnAmount = SafeMathTyped.add256(burnAmount, lastProposal.proposalDeposit);
            }
            runningProposals.pop();
            maxIterations = maxIterations - 1;  // CG: We can safely subtract 1 without overflow issues, since the while test for maxIterations > 0;
        }

        if (runningProposals.length == 1)
        {
            currentProposalHash = runningProposals[0];
            votingStartedDate = uint64(block.timestamp);
            runningProposals.pop();

            emit VoteOpenedReceipt(currentProposalHash);
            return true;
        }
        else
        {
            return false;
        }
    }

    event Ballot(address indexed voter, bytes32 proposalHash, VoteStatus vote, uint256 votes);
    /// @notice Cast a vote for a specific proposal for msg.sender.
    /// @param _proposalHash The hash for the proposal to vote on.
    /// @param _vote Indication of if msg.sender is voting in support, opposition, or abstaining.
    function vote(bytes32 _proposalHash, VoteStatus _vote)
        external
    {
        // CG: Must be in submission selection or voting state.
        GovernanceState state = proposalsState();
        require(state == GovernanceState.SubmissionsOpen || state == GovernanceState.SubmissionsSelection || state == GovernanceState.VotingStarted, "ABQDAO/voting-not-open");
        
        // CG: If in voting state, only votes on the current proposal allowed.
        if (state == GovernanceState.VotingStarted)
        {
            require(currentProposalHash == _proposalHash, "ABQDAO/only-votes-on-current-proposal");
        }

        uint256 voteCount = votingPower[msg.sender];

        // CG: Reverse previous vote on the current proposal round.
        Proposal storage previousProposal = proposals[lastVotedOn[msg.sender]];
        if (previousProposal.submissionBatchNumber == currentSubmissionBatchNumber)
        {
            VoteStatus previousVote = previousProposal.votesCasted[msg.sender];
            if (previousVote == VoteStatus.Support)
            {
                previousProposal.votesInSupport = SafeMathTyped.sub256(previousProposal.votesInSupport, voteCount);
                previousProposal.votesCasted[msg.sender] = VoteStatus.Abstain;
            }
            else if (previousVote == VoteStatus.Oppose)
            {
                previousProposal.votesInOpposition = SafeMathTyped.sub256(previousProposal.votesInOpposition, voteCount);
                previousProposal.votesCasted[msg.sender] = VoteStatus.Abstain;
            }
        }

        // CG: Only votes allowed on current proposal round.
        Proposal storage proposal = proposals[_proposalHash];
        require(proposal.submissionBatchNumber == currentSubmissionBatchNumber, "ABQDAO/only-votes-on-current-submissions");
        
        // CG: Cast the voter's vote
        if (_vote == VoteStatus.Support)
        {
            proposal.votesInSupport = SafeMathTyped.add256(proposal.votesInSupport, voteCount);
            proposal.votesCasted[msg.sender] = VoteStatus.Support;
        }
        else if (_vote == VoteStatus.Oppose)
        {
            proposal.votesInOpposition = SafeMathTyped.add256(proposal.votesInOpposition, voteCount);
            proposal.votesCasted[msg.sender] = VoteStatus.Oppose;
        }

        lastVotedOn[msg.sender] = _proposalHash;
        emit Ballot(msg.sender, _proposalHash, _vote, voteCount);
    }

    event ProposalResolution(bytes32 proposalHash, bool wasPassed);
    /// @notice Resolve the proposal that was voted on.
    function resolveProposal()
        external
    {
        require(currentProposalHash != 0, "ABQDAO/no-proposal");
        GovernanceState state = proposalsState();
        require(state == GovernanceState.VotingStarted || state == GovernanceState.ProposalConclusion, "ABQDAO/cannot-resolve-yet");

        bool hasPassed = false;
        Proposal storage proposal = proposals[currentProposalHash];
        
        if (state == GovernanceState.VotingStarted)
        {
            // CG: If a proposal already has more than 50% of all staked votes then it can be passed before voting concluded.
            if (proposal.votesInSupport >= SafeMathTyped.add256(SafeMathTyped.div256(totalVotesStaked,2), 1))
            {
                hasPassed = true;
            }
            // CG: If a proposal already has more than 50% of all staked votes against it then it can be defeated before voting concluded.
            else if (proposal.votesInOpposition >= SafeMathTyped.add256(SafeMathTyped.div256(totalVotesStaked,2), 1))
            {
                hasPassed = false;
            }
            else
            {
                revert("ABQDAO/voting-in-progress");
            }
        }
        else if (state == GovernanceState.ProposalConclusion)
        {
            // CG: If the proposal was started voting on less than resolutionWindow ago, then resolve based on amount of votes.
            if (SafeMathTyped.add256(votingStartedDate, resolutionWindow) > block.timestamp)
            {
                // CG: After voting time has concluded it is a pass if more votes are in support than in opposition.
                hasPassed = proposal.votesInSupport > proposal.votesInOpposition;
            }
            // CG: Since voting started resolutionWindow or more ago already and have not been executed yet, fail the proposal.
            else
            {
                hasPassed = false;
            }
        }

        // CG: Emit the event before we lose the hash stored in currentProposalHash.
        emit ProposalResolution(currentProposalHash, hasPassed);

        // CG: Close the proposal
        currentProposalHash = 0;
        currentSubmissionBatchNumber += 1;
        submissionStartedDate = 0;
        votingStartedDate = 0;

        if (hasPassed)
        {
            // CG: Refund deposit to proposer.
            refundAmount[proposal.proposer] = SafeMathTyped.add256(refundAmount[proposal.proposer], proposal.proposalDeposit);

            // CG: Call into owner to execute the proposal.
            daoOwnerContract.performDelegateCall(proposal.proposalAddress, proposal.proposalData);
        }
        else
        {
            // CG: If it isn't a passed proposal, then the deposit should be burned.
            burnAmount = SafeMathTyped.add256(burnAmount, proposal.proposalDeposit);
        }
    }

    /// @notice Burns the deposits of failed submissions.
    function burnDepositsOfFailedSubmissions()
        external
    {
        token.burn(burnAmount);
        burnAmount = 0;
    }

    /// @notice Refund the deposits for `_for` that was associated to succesful resolutions.
    /// @param _for The address to refund deposits for.
    function refundSuccessfulSubmissions(address _for)
        external
    {
        uint256 amount = refundAmount[_for];
        refundAmount[_for] = 0;

        bool couldRefund = token.transfer(_for, amount);
        require(couldRefund, "ABQDAO/could-not-refund");
    }
}