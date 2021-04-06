/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity 0.6.12;
// SPDX-License-Identifier: GPLv3

library SafeMath { // arithmetic wrapper for under/overflow check
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }
}

interface IERC20 { // brief interface for moloch erc20 token txs
    function balanceOf(address who) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 amount) external returns (bool);
}

contract ReentrancyGuard { // call wrapper for reentrancy check - see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IAaveDepositWithdraw {
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address token, uint256 amount, address destination) external;
    function getReservesList() external view returns (address[] memory);
    function getAssetsPrices(address[] calldata _assets) external view returns(uint256[] memory);
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

contract AaveParty is ReentrancyGuard {
    using SafeMath for uint256;

    /****************
    GOVERNANCE PARAMS
    ****************/
    uint256 public periodDuration; // default = 17280 = 4.8 hours in seconds (5 periods per day)
    uint256 public votingPeriodLength; // default = 35 periods (7 days)
    uint256 public gracePeriodLength; // default = 35 periods (7 days)
    uint256 public proposalDepositReward; // default = 10 ETH (~$1,000 worth of ETH at contract deployment)
    uint256 public depositRate; // rate to convert into shares during summoning time (default = 10000000000000000000 wei amt. // 100 wETH => 10 shares)
    uint256 public summoningTime; // needed to determine the current period
    uint256 public partyGoal; // savings goal for DAO 
    uint256 public dilutionBound;

    
    address public aave; // aave lending pool contract reference  
    address public daoFees; // where fees go
    address public depositToken; // deposit token contract reference
    bool private initialized; // internally tracks deployment per eip-1167

    // HARD-CODED LIMITS
    // These numbers are quite arbitrary; they are small enough to avoid overflows when doing calculations
    // with periods or shares, yet big enough to not limit reasonable use cases.
    uint256 public constant MAX_INPUT = 10**36; // maximum bound for reasonable limits
    uint256 public constant MAX_TOKEN_WHITELIST_COUNT = 100; // maximum number of whitelisted tokens

    // ***************
    // EVENTS
    // ***************
    event SummonComplete(address[] indexed summoners, address[] tokens, uint256 summoningTime, uint256 periodDuration, uint256 votingPeriodLength, uint256 gracePeriodLength, uint256 proposalDepositReward, uint256 partyGoal, uint256 depositRate);
    event MakeDeposit(address indexed memberAddress, uint256 tribute, uint256 indexed shares, uint8 goalHit);
    event ProcessAmendGovernance(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass, address newToken, address newAave, uint256 newPartyGoal, uint256 newDepositRate);    
    event SubmitProposal(address indexed applicant, uint256 sharesRequested, uint256 lootRequested, uint256 tributeOffered, address tributeToken, uint256 paymentRequested, address paymentToken, bytes32 details, bool[8] flags, uint256 proposalId, address indexed delegateKey, address indexed memberAddress);
    event SponsorProposal(address indexed sponsor, address indexed memberAddress, uint256 proposalId, uint256 proposalIndex, uint256 startingPeriod);
    event SubmitVote(uint256 proposalId, uint256 indexed proposalIndex, address indexed delegateKey, address indexed memberAddress, uint8 uintVote);
    event ProcessProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event ProcessGuildKickProposal(uint256 indexed proposalIndex, uint256 indexed proposalId, bool didPass);
    event Ragequit(address indexed memberAddress, uint256 sharesToBurn, uint256 lootToBurn);
    event TokensCollected(address indexed token, uint256 amountToCollect);
    event CancelProposal(uint256 indexed proposalId, address applicantAddress);
    event UpdateDelegateKey(address indexed memberAddress, address newDelegateKey);
    event WithdrawEarnings(address indexed memberAddress, uint256 earningsToUser);
    event Withdraw(address indexed memberAddress, address token, uint256 amount);

    // *******************
    // INTERNAL ACCOUNTING
    // *******************
    uint8 public goalHit; // tracks whether goal has been hit
    uint256 public proposalCount; // total proposals submitted
    uint256 public totalShares; // total shares across all members
    uint256 public totalLoot; // total loot across all members
    uint256 public totalDeposits; // track deposits made for goal

    address public constant GUILD = address(0xdead);
    address public constant ESCROW = address(0xbeef);
    address public constant TOTAL = address(0xbabe);
    mapping(address => mapping(address => uint256)) public userTokenBalances; // userTokenBalances[userAddress][tokenAddress]
    mapping(address => int) public aTokenDeposits; // tracks DAO balance of aTokens to calc what's earnings

    enum Vote {
        Null, // default value, counted as abstention
        Yes,
        No
    }

    struct Member {
        uint256 shares; // the # of voting shares assigned to this member
        uint256 loot; // the loot amount available to this member (combined with shares on ragequit)
        mapping(address => uint256) aTokenRedemptions; // interest withdrawn from array of approvedTokens (reflecting burn of accumulated aTokens)
        mapping(address => uint256) aTokenDeposits; // interest withdrawn from array of approvedTokens (reflecting burn of accumulated aTokens)
        uint256 highestIndexYesVote; // highest proposal index # on which the member voted YES
        bool jailed; // set to proposalIndex of a passing guild kick proposal for this member, prevents voting on and sponsoring proposals
        bool exists; // always true once a member has been created
    }

    struct Proposal {
        address applicant; // the applicant who wishes to become a member - this key will be used for withdrawals (doubles as guild kick target for gkick proposals)
        address proposer; // the account that submitted the proposal (can be non-member)
        address sponsor; // the member that sponsored the proposal (moving it into the queue)
        uint256 sharesRequested; // the # of shares the applicant is requesting
        uint256 lootRequested; // the amount of loot the applicant is requesting
        uint256 tributeOffered; // amount of tokens offered as tribute
        address tributeToken; // tribute token contract reference
        uint256 paymentRequested; // amount of tokens requested as payment
        address paymentToken; // payment token contract reference
        uint256 startingPeriod; // the period in which voting can start for this proposal
        uint256 yesVotes; // the total number of YES votes for this proposal
        uint256 noVotes; // the total number of NO votes for this proposal
        bool[8] flags; // [sponsored, processed, didPass, cancelled, guildkick, spending, member, action]
        bytes32 details; // proposal details to add context for members 
        uint256 maxTotalSharesAndLootAtYesVote; // the maximum # of total shares encountered at a yes vote on this proposal
        mapping(address => Vote) votesByMember; // the votes on this proposal by each member
    }

    mapping(address => bool) public tokenWhitelist;
    address[] public approvedTokens;
    
    address[] public aTokens;
    mapping(address => address) public aTokenAssignments; // map whitelisted `underlying` tokens (tribute to join guild) to aTokens (guild savings strategy)
  
    
    mapping(address => bool) public proposedToKick;

    mapping(address => Member) public members;
    address[] public memberList;

    mapping(uint256 => Proposal) public proposals;
    uint256[] public proposalQueue;
   
    /******************
    SUMMONING FUNCTIONS
    ******************/
    function init(
        address[] memory _founders,
        address[] memory _aTokens,
        address _daoFees,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _proposalDepositReward,
        uint256 _depositRate,
        uint256 _dilutionBound,
        uint256 _partyGoal
    ) public {
        require(!initialized, "initialized");
        initialized = true;
        require(_periodDuration > 0, "_periodDuration zeroed");
        require(_votingPeriodLength > 0, "_votingPeriodLength zeroed");
        require(_votingPeriodLength <= MAX_INPUT, "_votingPeriodLength maxed");
        require(_gracePeriodLength <= MAX_INPUT, "_gracePeriodLength maxed");
        require(_aTokens.length > 0, "need token");
        require(_depositRate > 0, "deposit rate zeroed");
        
        depositToken = IAaveDepositWithdraw(_aTokens[0]).UNDERLYING_ASSET_ADDRESS(); // fetch underlying for base [0] aToken as deposit token
        // NOTE: move event up here, avoid stack too deep if too many approved tokens
        emit SummonComplete(_founders, _aTokens, block.timestamp, _periodDuration, _votingPeriodLength, _gracePeriodLength, _proposalDepositReward, _depositRate, _partyGoal);
        
        aave = 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe; //kovan 
        
        for (uint256 i = 0; i < _aTokens.length; i++) {
            address underlying = IAaveDepositWithdraw(_aTokens[i]).UNDERLYING_ASSET_ADDRESS();
            require(!tokenWhitelist[underlying], "duplicate approved token");
            tokenWhitelist[underlying] = true;
            approvedTokens.push(underlying);
            aTokens.push(_aTokens[i]);
            aTokenAssignments[underlying] = _aTokens[i]; // map underlying to aTokens
            IERC20(underlying).approve(aave, uint256(-1)); // max approve aave for deposit into aToken from underlying
        }
        
        for (uint256 i = 0; i < _founders.length; i++) {
            members[_founders[i]].exists = true;
            memberList.push(_founders[i]);
        }
        
        periodDuration = _periodDuration;
        votingPeriodLength = _votingPeriodLength;
        gracePeriodLength = _gracePeriodLength;
        proposalDepositReward = _proposalDepositReward;
        depositRate = _depositRate;
        partyGoal = _partyGoal;
        daoFees = _daoFees;
        dilutionBound = _dilutionBound;
        summoningTime = block.timestamp;
        goalHit = 0;
    }
    
    function _setAave(address _aave) internal {
        aave = _aave;
    }
    
    /*****************
    PROPOSAL FUNCTIONS
    *****************/
    function submitProposal(
        address applicant,
        uint256 tributeOffered,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 paymentRequested,
        uint256 flagNumber,
        address tributeToken,
        address paymentToken,
        bytes32 details
    ) public nonReentrant returns (uint256 proposalId) {
        require(sharesRequested.add(lootRequested) <= MAX_INPUT, "shares maxed");
        if(flagNumber != 7){
            require(tokenWhitelist[tributeToken] && tokenWhitelist[paymentToken], "tokens not whitelisted");  
        }
        require(applicant != address(0), "applicant cannot be 0");
        require(members[applicant].jailed == false, "applicant jailed");
        require(flagNumber != 0 || flagNumber != 1 || flagNumber != 2 || flagNumber != 3, "flag must be 4 - guildkick, 5 - spending, 6 - membership, 7 - governance");
        
        // collect deposit from proposer
        require(IERC20(depositToken).transferFrom(msg.sender, address(this), proposalDepositReward), "proposal deposit failed");
        unsafeAddToBalance(ESCROW, depositToken, proposalDepositReward);
        // collect tribute from proposer and store it in the Moloch until the proposal is processed
        require(IERC20(tributeToken).transferFrom(msg.sender, address(this), tributeOffered), "tribute token transfer failed");
        unsafeAddToBalance(ESCROW, tributeToken, tributeOffered);
   
        // check whether pool goal is met before allowing spending proposals
        if(flagNumber == 5) {
            require(goalHit == 1, "goal not met yet");
        }
        
        if(flagNumber == 6) {
            require(paymentRequested == 0 || goalHit == 1, "goal not met yet");
        }
        
        bool[8] memory flags; // [sponsored, processed, didPass, cancelled, guildkick, spending, member, governance]
        flags[flagNumber] = true;
        
        if(flagNumber == 4) {
            _submitProposal(applicant, 0, 0, 0, address(0), 0, address(0), details, flags);
        } 
        
        else if (flagNumber == 7) { // for amend governance use applicant for aToken (e.g., aDAI), tributeOffered for partyGoal, paymentRequested for depositRate, tributeToken for aToken underlying (e.g., DAI), paymentToken for new aave
            require(tributeToken == IAaveDepositWithdraw(applicant).UNDERLYING_ASSET_ADDRESS()); // sanity check 
            _submitProposal(applicant, 0, 0, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags);
        } 
        
        else {
            _submitProposal(applicant, sharesRequested, lootRequested, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags);
        }
        
        // NOTE: Should approve the 0x address as a blank token for guildKick proposals where there's no token. 
        return proposalCount - 1; // return proposalId - contracts calling submit might want it
    }
    
    function _submitProposal(
        address applicant,
        uint256 sharesRequested,
        uint256 lootRequested,
        uint256 tributeOffered,
        address tributeToken,
        uint256 paymentRequested,
        address paymentToken,
        bytes32 details,
        bool[8] memory flags
    ) internal {
        Proposal memory proposal = Proposal({
            applicant : applicant,
            proposer : msg.sender,
            sponsor : address(0),
            sharesRequested : sharesRequested,
            lootRequested : lootRequested,
            tributeOffered : tributeOffered,
            tributeToken : tributeToken,
            paymentRequested : paymentRequested,
            paymentToken : paymentToken,
            startingPeriod : 0,
            yesVotes : 0,
            noVotes : 0,
            flags : flags,
            details : details,
            maxTotalSharesAndLootAtYesVote : 0
        });
        
        proposals[proposalCount] = proposal;
        address memberAddress = msg.sender;
        // NOTE: argument order matters, avoid stack too deep
        emit SubmitProposal(applicant, sharesRequested, lootRequested, tributeOffered, tributeToken, paymentRequested, paymentToken, details, flags, proposalCount, msg.sender, memberAddress);
        proposalCount += 1;
    }

    function sponsorProposal(uint256 proposalId) public nonReentrant  {
        Proposal storage proposal = proposals[proposalId];

        require(proposal.proposer != address(0), 'proposal must have been proposed');
        require(!proposal.flags[0], "proposal has already been sponsored");
        require(!proposal.flags[3], "proposal has been cancelled");
        require(members[proposal.applicant].jailed == false, "proposal applicant must not be jailed");

        if (proposal.tributeOffered > 0 && userTokenBalances[GUILD][proposal.tributeToken] == 0) {
            require(approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, 'cannot sponsor more tribute proposals for new tokens - guildbank is full');
        }

         if (proposal.flags[4]) {
            require(!proposedToKick[proposal.applicant], 'already proposed to kick');
            proposedToKick[proposal.applicant] = true;
        }

        // compute startingPeriod for proposal
        uint256 startingPeriod = max(
            getCurrentPeriod(),
            proposalQueue.length == 0 ? 0 : proposals[proposalQueue[proposalQueue.length.sub(1)]].startingPeriod
        ).add(1);

        proposal.startingPeriod = startingPeriod;

        address memberAddress = msg.sender;
        proposal.sponsor = memberAddress;

        proposal.flags[0] = true; // sponsored

        // append proposal to the queue
        proposalQueue.push(proposalId);
        
        emit SponsorProposal(msg.sender, memberAddress, proposalId, proposalQueue.length.sub(1), startingPeriod);
    }

    function submitVote(uint256 proposalIndex, uint8 uintVote) public nonReentrant {
        require(members[msg.sender].exists == true);
        Member storage member = members[msg.sender];

        require(proposalIndex < proposalQueue.length, "proposal does not exist");
        Proposal storage proposal = proposals[proposalQueue[proposalIndex]];

        require(uintVote < 3, "must be less than 3, 1 = yes, 2 = no");
        Vote vote = Vote(uintVote);

        require(getCurrentPeriod() >= proposal.startingPeriod, "voting period has not started");
        require(!hasVotingPeriodExpired(proposal.startingPeriod), "proposal voting period has expired");
        require(proposal.votesByMember[msg.sender] == Vote.Null, "member has already voted");
        require(vote == Vote.Yes || vote == Vote.No, "vote must be either Yes or No");

        proposal.votesByMember[msg.sender] = vote;

        if (vote == Vote.Yes) {
            proposal.yesVotes = proposal.yesVotes.add(member.shares);

            // set highest index (latest) yes vote - must be processed for member to ragequit
            if (proposalIndex > member.highestIndexYesVote) {
                member.highestIndexYesVote = proposalIndex;
            }

            // set maximum of total shares encountered at a yes vote - used to bound dilution for yes voters
            if (totalShares.add(totalLoot) > proposal.maxTotalSharesAndLootAtYesVote) {
                proposal.maxTotalSharesAndLootAtYesVote = totalShares.add(totalLoot);
            }

        } else if (vote == Vote.No) {
            proposal.noVotes = proposal.noVotes.add(member.shares);
        }
     
        emit SubmitVote(proposalQueue[proposalIndex], proposalIndex, msg.sender, msg.sender, uintVote);
    }

    function processProposal(uint256 proposalIndex) public nonReentrant {
        _validateProposalForProcessing(proposalIndex);

        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];
        
        // [sponsored -0 , processed -1, didPass -2, cancelled -3, guildkick -4, spending -5, member -6, action -7]
        require(!proposal.flags[4], "not standard proposal"); 

        proposal.flags[1] = true; // processed

        bool didPass = _didPass(proposalIndex);

        // Make the proposal fail if the new total number of shares and loot exceeds the limit
        if (totalShares.add(totalLoot).add(proposal.sharesRequested).add(proposal.lootRequested) > MAX_INPUT) {
            didPass = false;
        }

        // Make the proposal fail if it is requesting more tokens as payment than the available guild bank balance (aToken check)
        if (proposal.paymentRequested > IERC20(aTokenAssignments[proposal.paymentToken]).balanceOf(address(this))) {
            didPass = false;
        }

        // PROPOSAL PASSED
        if (didPass) {
            proposal.flags[2] = true; // didPass

            // if the applicant is already a member, add to their existing shares & loot
            if (members[proposal.applicant].exists) {
                members[proposal.applicant].shares = members[proposal.applicant].shares.add(proposal.sharesRequested);
                members[proposal.applicant].loot = members[proposal.applicant].loot.add(proposal.lootRequested);

            // the applicant is a new member, create a new record for them
            } else {
                members[proposal.applicant].exists = true;
                members[proposal.applicant].shares = members[proposal.applicant].shares.add(proposal.sharesRequested);
                members[proposal.applicant].loot = members[proposal.applicant].loot.add(proposal.lootRequested);
                memberList.push(proposal.applicant);
            }

            // mint new shares & loot
            totalShares = totalShares.add(proposal.sharesRequested);
            totalLoot = totalLoot.add(proposal.lootRequested);

            if (proposal.tributeOffered > 0) {
                unsafeSubtractFromBalance(ESCROW, proposal.tributeToken, proposal.tributeOffered); // remove underlying from ESCROW accounting 
                IAaveDepositWithdraw(aave).deposit(proposal.tributeToken, proposal.tributeOffered, address(this), 0); // deposit underlying to aave to get equal aToken back into local guild balance
                members[proposal.applicant].aTokenDeposits[proposal.tributeToken] += proposal.tributeOffered;
                aTokenDeposits[proposal.tributeToken] += int(proposal.tributeOffered); // update internal accounting for that token
            } 
            
            if (proposal.paymentRequested > 0) {
                IAaveDepositWithdraw(aave).withdraw(proposal.paymentToken, proposal.paymentRequested, address(this)); // burn aToken from local guild balance
                aTokenDeposits[proposal.paymentToken] -= int(proposal.paymentRequested);
                unsafeAddToBalance(proposal.applicant, proposal.paymentToken, proposal.paymentRequested); // deposit underlying to applicant guild pull account
            }
 
        // PROPOSAL FAILED
        } else {
            // return all tokens to the proposer (not the applicant, because funds come from proposer)
            unsafeInternalTransfer(ESCROW, proposal.proposer, proposal.tributeToken, proposal.tributeOffered);
        }

        _returnDeposit();
        
        emit ProcessProposal(proposalIndex, proposalId, didPass);
    }

    function processGuildKickProposal(uint256 proposalIndex) public nonReentrant {
        _validateProposalForProcessing(proposalIndex);

        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];

        require(proposal.flags[4], "not guild kick");

        proposal.flags[1] = true; // [sponsored, processed, didPass, cancelled, guildkick, spending, member]

        bool didPass = _didPass(proposalIndex);

        if (didPass) {
            proposal.flags[2] = true; // didPass
            Member storage member = members[proposal.applicant];
            member.jailed == true;

            // transfer shares to loot
            member.loot = member.loot.add(member.shares);
            totalShares = totalShares.sub(member.shares);
            totalLoot = totalLoot.add(member.shares);
            member.shares = 0; // revoke all shares
        }

        proposedToKick[proposal.applicant] = false;

        _returnDeposit();

        emit ProcessGuildKickProposal(proposalIndex, proposalId, didPass);
    }
    
    function processAmendGovernance(uint256 proposalIndex) public nonReentrant {
        _validateProposalForProcessing(proposalIndex);

        uint256 proposalId = proposalQueue[proposalIndex];
        Proposal storage proposal = proposals[proposalId];

        require(proposal.flags[7], "not gov amendment");

        proposal.flags[1] = true; // [sponsored, processed, didPass, cancelled, guildkick, spending, member]

        bool didPass = _didPass(proposalIndex);

            if (didPass) {
                proposal.flags[2] = true; // didPass
            
            // Updates PartyGoal
            if(proposal.tributeOffered > 0){
                partyGoal = proposal.tributeOffered;
            }
            
            // Update depositRate
            if(proposal.paymentRequested > 0){
                depositRate = proposal.paymentRequested;
            }
            
            // Adds token to whitelist and approvedTokens / associates aToken / max approves aave deposit for underlying
            if(proposal.tributeToken != address(0)){
                require(approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, "too many tokens already");
                approvedTokens.push(proposal.tributeToken);
                tokenWhitelist[proposal.tributeToken] = true;
                aTokenAssignments[proposal.tributeToken] = proposal.applicant; // map underlying to aToken
                IERC20(proposal.tributeToken).approve(aave, uint256(-1)); // max approve underlying to aave for deposit into aToken
            }
            
            // Used to upgrade aave lending pool contract reference
            if(proposal.paymentToken != address(0)){
                _setAave(proposal.paymentToken);
            }
        }

        _returnDeposit();
        
        emit ProcessAmendGovernance(proposalIndex, proposalId, didPass, proposal.tributeToken, proposal.paymentToken, proposal.tributeOffered, proposal.paymentRequested);
    }

    function _didPass(uint256 proposalIndex) internal view returns (bool didPass) {
        Proposal memory proposal = proposals[proposalQueue[proposalIndex]];

        didPass = proposal.yesVotes > proposal.noVotes;

        // Make the proposal fail if the dilutionBound is exceeded
        if ((totalShares.add(totalLoot)).mul(dilutionBound) < proposal.maxTotalSharesAndLootAtYesVote) {
            didPass = false;
        }

        // Make the proposal fail if the applicant is jailed
        // - for standard proposals, we don't want the applicant to get any shares/loot/payment
        // - for guild kick proposals, we should never be able to propose to kick a jailed member (or have two kick proposals active), so it doesn't matter
        if (members[proposal.applicant].jailed == true) {
            didPass = false;
        }

        return didPass;
    }

    function _validateProposalForProcessing(uint256 proposalIndex) internal view {
        require(proposalIndex < proposalQueue.length, "no such proposal");
        Proposal memory proposal = proposals[proposalQueue[proposalIndex]];

        require(getCurrentPeriod() >= proposal.startingPeriod.add(votingPeriodLength).add(gracePeriodLength), "proposal not ready");
        require(proposal.flags[1] == false, "proposal has already been processed");
        require(proposalIndex == 0 || proposals[proposalQueue[proposalIndex.sub(1)]].flags[1], "previous proposal unprocessed");
    }

    function _returnDeposit() internal {
        unsafeInternalTransfer(ESCROW, msg.sender, depositToken, proposalDepositReward);
    }

    function ragequit() public nonReentrant {
        /* 
        @Dev - to simplify accounting had to set ragequit to an all or nothing proposition.
        Since members who ragequit can always redeposit after the ragequit, it should not 
        be to limiting until a better system can be implemented in ModMol v3. 
        */
        require(members[msg.sender].shares.add(members[msg.sender].loot) > 0, "only users with balances can ragequit");
        _ragequit(msg.sender);
    }

    function _ragequit(address memberAddress) internal {
        uint256 initialTotalSharesAndLoot = totalShares.add(totalLoot);

        Member storage member = members[memberAddress];

        require(canRagequit(member.highestIndexYesVote), "cannot ragequit until highest index proposal member voted YES on is processed");
        
        uint256 sharesToBurn = member.shares;
        uint256 lootToBurn = member.loot;
        uint256 sharesAndLootToBurn = sharesToBurn.add(lootToBurn);

        // burn shares and loot
        member.shares = 0;
        member.loot = 0;
        totalShares = totalShares.sub(sharesToBurn);
        totalLoot = totalLoot.sub(lootToBurn);
        
        for (uint256 i = 0; i < aTokens.length; i++) {
            uint256 amountToRagequit = fairShare(IERC20(aTokens[i]).balanceOf(address(this)), sharesAndLootToBurn, initialTotalSharesAndLoot).sub(member.aTokenRedemptions[aTokens[i]]);
            if (amountToRagequit > 0) { // gas optimization to allow a higher maximum token limit
                IAaveDepositWithdraw(aave).withdraw(approvedTokens[i], amountToRagequit, address(this));
                unsafeAddToBalance(memberAddress, approvedTokens[i], amountToRagequit);
                
                if(member.aTokenRedemptions[aTokens[i]] > 0){
                   uint256 aTokenAdj = amountToRagequit.sub(member.aTokenDeposits[aTokens[i]]);
                   if(aTokenAdj > 0){
                       unsafeInternalTransfer(memberAddress, GUILD, address(aTokens[i]), aTokenAdj);
                   }
                    aTokenDeposits[aTokens[i]] -= int(amountToRagequit);
                    aTokenDeposits[aTokens[i]] += int(aTokenAdj);
                } else {
                    aTokenDeposits[aTokens[i]] -= int(amountToRagequit);
                }
                member.aTokenRedemptions[aTokens[i]] = 0; // reset member claimed earnings 
                member.aTokenDeposits[aTokens[i]] = 0; // reset member claimed earnings 
            }
        }

        emit Ragequit(msg.sender, sharesToBurn, lootToBurn);
    }

    function ragekick(address memberToKick) public nonReentrant {
        Member storage member = members[memberToKick];

        require(member.jailed != true, "member not jailed");
        require(member.loot > 0, "member must have loot"); // note - should be impossible for jailed member to have shares
        require(canRagequit(member.highestIndexYesVote), "cannot ragequit until highest index proposal member voted YES on is processed");

        _ragequit(memberToKick);
    }
    
    function withdrawEarnings(uint256[] calldata amount) external nonReentrant {
        require(amount.length == approvedTokens.length, "amount/approvedTokens don't match");
        uint256 initialTotalSharesAndLoot = totalShares.add(totalLoot);
        
        Member storage member = members[msg.sender];
        require(member.exists == true, "not member");
        uint256 sharesAndLootM = member.shares.add(member.loot);
        
        // Calculates user's share of aave interest earned in the pool and grants underlying to pull account 
        for (uint256 i = 0; i < aTokens.length; i++) {
            uint256 claimable = fairShare(IERC20(aTokens[i]).balanceOf(address(this)), sharesAndLootM, initialTotalSharesAndLoot);
            uint256 base = abs(aTokenDeposits[aTokens[i]]).div(initialTotalSharesAndLoot).mul(sharesAndLootM).add(member.aTokenRedemptions[aTokens[i]]);
            require(claimable >= base, "insufficient earnings");
            
            IAaveDepositWithdraw(aave).withdraw(approvedTokens[i], amount[i], address(this));
            unsafeAddToBalance(msg.sender, approvedTokens[i], amount[i]);
            subFees(msg.sender, amount[i], approvedTokens[i]);
            member.aTokenRedemptions[aTokens[i]] += amount[i];

            emit WithdrawEarnings(msg.sender, claimable);
        }
    }

    function withdrawBalance(address token, uint256 amount) public nonReentrant {
        _withdrawBalance(token, amount);
    }
    
    function withdrawBalances(address[] memory tokens, uint256[] memory amounts, bool max) public nonReentrant {
        require(tokens.length == amounts.length, "tokens + amounts arrays must match");

        for (uint256 i=0; i < tokens.length; i++) {
            uint256 withdrawAmount = amounts[i];
            if (max) { // withdraw the maximum balance
                withdrawAmount = userTokenBalances[msg.sender][tokens[i]];
            }

            _withdrawBalance(tokens[i], withdrawAmount);
        }
    }
    
    function _withdrawBalance(address token, uint256 amount) internal {
        require(userTokenBalances[msg.sender][token] >= amount, "insufficient balance");
        unsafeSubtractFromBalance(msg.sender, token, amount);
        require(IERC20(token).transfer(msg.sender, amount), "transfer failed");
        emit Withdraw(msg.sender, token, amount);
    }
    
    function collectTokens(address token) public nonReentrant {
        require(members[msg.sender].exists, "not member");
        uint256 amountToCollect = IERC20(token).balanceOf(address(this)).sub(userTokenBalances[TOTAL][token]);
        // only collect if 1) there are tokens to collect 2) token is whitelisted 3) token has non-zero balance
        require(amountToCollect > 0, 'no tokens to collect');
        require(tokenWhitelist[token], 'token to collect must be whitelisted');
        require(userTokenBalances[GUILD][token] > 0 || approvedTokens.length < MAX_TOKEN_WHITELIST_COUNT, 'token to collect must have non-zero guild bank balance');
        
        unsafeAddToBalance(GUILD, token, amountToCollect);
        emit TokensCollected(token, amountToCollect);
    }
    
    function subFees(address holder, uint256 amount, address token) internal returns (uint256) {
        uint256 poolFees = amount.div(uint256(1000).div(100)); // 10% fee on earnings
        unsafeInternalTransfer(holder, daoFees, address(token), poolFees);
        return amount.sub(poolFees);
    }
    
    function cancelProposal(uint256 proposalId) public nonReentrant {
        Proposal storage proposal = proposals[proposalId];
        require(getCurrentPeriod() <= proposal.startingPeriod, "voting period has already started");
        require(!proposal.flags[3], "proposal already cancelled");
        require(msg.sender == proposal.proposer, "only proposer cancels");

        proposal.flags[3] = true; // cancelled
        
        unsafeInternalTransfer(ESCROW, proposal.proposer, proposal.tributeToken, proposal.tributeOffered);
        emit CancelProposal(proposalId, msg.sender);
    }

    // can only ragequit if the latest proposal you voted YES on has been processed
    function canRagequit(uint256 highestIndexYesVote) public view returns (bool) {
        if(proposalQueue.length == 0){
            return true;
        } else {
            require(highestIndexYesVote < proposalQueue.length, "no such proposal");
            return proposals[proposalQueue[highestIndexYesVote]].flags[0];
        }
    }

    function hasVotingPeriodExpired(uint256 startingPeriod) public view returns (bool) {
        return getCurrentPeriod() >= startingPeriod.add(votingPeriodLength);
    }
    
    /***************
    GETTER FUNCTIONS
    ***************/
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function getCurrentPeriod() public view returns (uint256) {
        return now.sub(summoningTime).div(periodDuration);
    }

    function getProposalQueueLength() public view returns (uint256) {
        return proposalQueue.length;
    }

    function getProposalFlags(uint256 proposalId) public view returns (bool[8] memory) {
        return proposals[proposalId].flags;
    }

    function getUserTokenBalance(address user, address token) public view returns (uint256) {
        return userTokenBalances[user][token];
    }

    function getMemberProposalVote(address memberAddress, uint256 proposalIndex) public view returns (Vote) {
        require(members[memberAddress].exists, "no such member");
        require(proposalIndex < proposalQueue.length, "unproposed");
        return proposals[proposalQueue[proposalIndex]].votesByMember[memberAddress];
    }

    function getTokenCount() public view returns (uint256) {
        return approvedTokens.length;
    }
    
    function getAaveReserves() external view returns (address[] memory) { // reference to check supported aToken types
        address[] memory reserves = IAaveDepositWithdraw(aave).getReservesList();
        return reserves;
    }

    /***************
    HELPER FUNCTIONS
    ***************/
    function makeDeposit(address token, uint256 amount) external nonReentrant {
        require(members[msg.sender].exists == true, 'must be member to deposit shares');
        
        uint256 shares = amount.div(depositRate);
        members[msg.sender].shares += shares;
        require(members[msg.sender].shares <= partyGoal.div(depositRate).div(2), "can't take over 50% of the shares w/o a proposal");
        totalShares += shares;
        
        require(IERC20(token).transferFrom(msg.sender, address(this), amount), "token transfer failed");
        IAaveDepositWithdraw(aave).deposit(token, amount, address(this), 0); // deposit to aave - return aToken to guild balance 
        members[msg.sender].aTokenDeposits[token] += amount;
        aTokenDeposits[token] += int(amount);
        
        if(token == depositToken){
            totalDeposits += amount;
        }

        // Checks to see if goal has been reached with this deposit
        // TODO: See if can use simple Aave oracle to collect prices for all aTokens
        goalHit = checkGoal();
        
        emit MakeDeposit(msg.sender, amount, shares, goalHit);
    }
    
    function checkGoal() public returns (uint8) {
        
        uint256 daoFunds = IERC20(aTokenAssignments[depositToken]).balanceOf(address(this));
        
        if(goalHit == 1){
            return goalHit = 1;
        } else if (daoFunds >= partyGoal){
            return goalHit = 1;
        } else {
            return goalHit = 0;
        }
        
    }
    
    function unsafeAddToBalance(address user, address token, uint256 amount) internal {
        userTokenBalances[user][token] += amount;
        userTokenBalances[TOTAL][token] += amount;
    }

    function unsafeSubtractFromBalance(address user, address token, uint256 amount) internal {
        userTokenBalances[user][token] -= amount;
        userTokenBalances[TOTAL][token] -= amount;
    }

    function unsafeInternalTransfer(address from, address to, address token, uint256 amount) internal {
        unsafeSubtractFromBalance(from, token, amount);
        unsafeAddToBalance(to, token, amount);
    }
    
    function abs(int x) internal pure returns (uint) {
        
        return uint(x) >= 0 ? uint(x) : uint(-x);
    }

    function fairShare(uint256 balance, uint256 shares, uint256 totalSharesAndLoot) internal pure returns (uint256) {
        require(totalSharesAndLoot != 0);

        if (balance == 0) { return 0; }

        uint256 prod = balance * shares;

        if (prod / balance == shares) { // no overflow in multiplication above?
            return prod / totalSharesAndLoot;
        }

        return (balance / totalSharesAndLoot) * shares;
    } 
} 

contract CloneFactory { // Mystic implementation of eip-1167 - see https://eips.ethereum.org/EIPS/eip-1167
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}


contract AavePartyStarter is CloneFactory {
    
    address public template;
    
    constructor (address _template) public {
        template = _template;
    }

    
    event PartyStarted(address indexed pty, address[] _founders, address[] _approvedTokens, address _daoFees, uint256 _periodDuration, uint256 _votingPeriodLength, uint256 _gracePeriodLength, uint256 _proposalDepositReward, uint256 _depositRate, uint256 _partyGoal, uint256 summoningTime, uint256 _dilutionBound);

    function startParty(
        address[] memory _founders,
        address[] memory _approvedTokens, //deposit token in 0, idleToken in 1
        address _daoFees,
        uint256 _periodDuration,
        uint256 _votingPeriodLength,
        uint256 _gracePeriodLength,
        uint256 _proposalDepositReward,
        uint256 _depositRate,
        uint256 _partyGoal,
        uint256 _dilutionBound
    ) public returns (address) {
       AaveParty pty = AaveParty(createClone(template));
      
       pty.init(
            _founders,
            _approvedTokens,
            _daoFees,
            _periodDuration,
            _votingPeriodLength,
            _gracePeriodLength,
            _proposalDepositReward,
            _depositRate,
            _partyGoal,
            _dilutionBound);
        
        emit PartyStarted(address(pty), _founders, _approvedTokens, _daoFees, _periodDuration, _votingPeriodLength, _gracePeriodLength, _proposalDepositReward, _depositRate, _partyGoal, now, _dilutionBound);
        return address(pty);
    }
}