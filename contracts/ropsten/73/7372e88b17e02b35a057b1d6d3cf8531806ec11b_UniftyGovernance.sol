//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IUniftyGovernanceConsumer.sol";
import "./IERC20Simple.sol";
import "./IERC20Mintable.sol";

/* ################################
    #
    # UniftyGovernance
    #
    # Contract to propose and vote on community decisions.
    # Distributes proposed grants as UNT to accepted consumers.
    #
    ######################################## */

contract UniftyGovernance {

    /* ################################
    #
    # SETUP (partially proposable)
    #
    ######################################## */
    
    // nif address
    address public nifAddress = 0xE6D2e49AB758b9E0F18D8Cb4428928c833182C46;

    // unt address
    address public untAddress = 0x2C9f49E07C99C45e0fE8B766D8Ae538264dF3f00;
    
    // epoch duration as timestamp, consisting of epochDuration and epochDurationMult
    uint256 public epochDuration = 86400 * 30;

    // the initial reward at epoch 1
    uint256 public genesisReward = 50000000 * 10**18;
    
    // the maximum duration of a proposal
    uint256 public maxProposalDuration = 86400 * 7;

    // proposal duration
    // the duration a proposal will be kept open at minimum
    uint256 public minProposalDuration = 86400 * 2;
    
    // the max. amount of time a proposal may be executed after the proposal period has been accepted and ended
    uint256 public proposalExecutionLimit = 86400 * 7;
    
    // min amount of nif required for a proposal to conclude
    uint256 public quorum = 150000 * 10**18;
    
    // minimum nif staking for the governance per user.
    // if below, a staker cannot propose or vote but stake and allocate to peers
    uint256 public minNifStake = 10 * 10**18;

    // minimum nif staking for the governance
    uint256 public minNifOverallStake = 150000 * 10**18;

    // the min nif being staked in the governance required for consumers receiving UNT
    uint256 public minNifConsumptionStake = 150000 * 10**18;

    // the timelock that nif needs to stay locked at minimum
    uint256 public nifStakeTimelock = 86400 * 14;
    
    // for selected timestamp relevant lookups, we use a general gracetime
    uint public graceTime = 60 * 15;
    
    /* ################################
    #
    # RUNTIME MEMBERS
    #
    ######################################## */
    
    // all nif stakes of a user (user => stake)
    mapping(address => LUniftyGovernance.NifStake) public userNifStakes;
    
    // counts the amount of proposals
    uint256 public proposalCounter;

    // proposalID => proposal
    mapping(uint256 => LUniftyGovernance.Proposal) public proposals;

    // proposalID => proposal
    mapping(uint256 => LUniftyGovernance.Uint256Proposal) public uint256Proposal;

    // proposalID => address
    mapping(uint256 => LUniftyGovernance.AddressProposal) public addressProposal;

    // proposalID => votes
    mapping(uint256 => LUniftyGovernance.Vote[]) public votes;

    // counts the amount of votes
    // proposalID => vote count
    mapping(uint256 => uint256) public votesCounter;
    
    // all nif stakes within this governance
    uint256 public allNifStakes;

    // allocations for the different consumers and their peers
    mapping(IUniftyGovernanceConsumer => mapping( address => uint256 ) ) public consumerPeerNifAllocation;
    
    // the amount of allocators for the peer
    mapping(IUniftyGovernanceConsumer => mapping( address => uint256 ) ) public nifAllocationLength;
    
    // allocations for consumers
    mapping(IUniftyGovernanceConsumer => uint256) public consumerNifAllocation;
    uint256 public nifAllocation;

    // governance pause flag
    bool public pausing = false;

    // when the accrue started since contract creation
    uint256 public accrueStart;

    // consumers who may receive UNT for further processing
    mapping(uint256 => LUniftyGovernance.Consumer) public consumers;
    
    // flat list of peers, each peer is supposed to be unique to the governance
    mapping(address => bool) public peerExists;
    
    // counter to be used with consumers
    // unlike the proposalCounter, we start with 1 here as we need 0 to determine an empty consumer situation.
    uint256 public consumerCounter = 1;

    // returns the consumer id or 0 if not set
    mapping(IUniftyGovernanceConsumer => uint256) public consumerIdByType;
    
    // mapping consumer => peer for global use to check if those exist
    mapping(IUniftyGovernanceConsumer => mapping( address => bool )) public consumerPeerExists;
    
    // the currently granted unt across all consumers
    uint256 public grantedUnt;
    
    // the unt that has been minted so far across all consumers
    uint256 public mintedUnt;

    // how much UNT has a consumer minted so far
    mapping(IUniftyGovernanceConsumer => uint256) public mintedUntConsumer;
    
    // list of executives for the governance contracts.
    // execs may execute accepted proposals and pause the governance in case of emergencies.
    // they are obliged to obey to governance decision and supposed to execute accepted proposals.
    mapping(address => bool) public isExecutive;
    
    // the current credit after unlock requests per user
    mapping(address => uint256) public credit;

    /* ################################
    #
    # RE-ENTRANCY GUARD
    #
    ######################################## */

    // re-entrancy protection
    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'UniftyGovernance: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    /* ################################
    #
    # EVENTS
    #
    ######################################## */

    event Allocated(address indexed user, IUniftyGovernanceConsumer consumer, address peer, uint256 untEarned);
    event Dellocated(address indexed user, IUniftyGovernanceConsumer consumer, address peer, uint256 untEarned);
    event Staked(address indexed user, uint256 stake, bool peerAccepted, uint256 untEarned);
    event Unstaked(address indexed user, uint256 unstake, bool peerAccepted, uint256 untEarned);
    event Withdrawn(address indexed user, uint256 amount);
    event Proposed(address indexed initiator, uint256 indexed proposalId, uint256 expires, uint256 actionId);
    event Voted(address indexed voter, uint256 indexed proposalId, uint256 indexed voteId, bool supporting, uint256 power);
    event Executed(address indexed executor, uint256 indexed proposalId);

    /**
     * Sets the accrueStart value, marking the begin of the first epoch.
     * 
     * */
    constructor(){

        accrueStart = block.timestamp;
        isExecutive[msg.sender] = true;
    }
    
    /* ################################
    #
    # NIF STAKING
    #
    ######################################## */

    /**
     * Simple NIF staking.
     *
     * If not paused, frozen and the minNif is being sent or already available, staking is allowed.
     *
     * No further state changes to anyone's staked nif is performed other than individual unstaking.
     *
     * This is to make sure that nif funds can be unstaked at any time after the timelock expired, under any circumstance.
     *
     * Returns false if an allocation update to a peer silently failed and the earned unt.
     * */
    function stake(uint256 _stake) external lock returns(bool, uint256){

        // here we ask for the pausing flag, not isPausing() as the latter is also true if overall nif stakes are too low
        // so we couldn't stake in the first place.
        require(!pausing, "stake: pausing, sorry.");
        require(_stake > 0, "stake: invalid staking amount.");

        bool accepted = true;
        uint256 untEarned = 0;

        uint256 prevAmount = userNifStakes[msg.sender].amount;
        userNifStakes[msg.sender].amount += _stake;
        userNifStakes[msg.sender].unstakableFrom = block.timestamp + nifStakeTimelock;
        
        allNifStakes += _stake;
        
        // adding new stakes will reset the allocation time if an allocation exists already
        if(address(userNifStakes[msg.sender].peerConsumer) != address(0) && consumerIdByType[ userNifStakes[msg.sender].peerConsumer ] != 0){

            uint256 prevAllocation = consumerPeerNifAllocation[ userNifStakes[msg.sender].peerConsumer ][ userNifStakes[msg.sender].peer ];
            consumerPeerNifAllocation[ userNifStakes[msg.sender].peerConsumer ][ userNifStakes[msg.sender].peer ] += _stake;
            consumerNifAllocation[ userNifStakes[msg.sender].peerConsumer ] += _stake;
            nifAllocation += _stake;
            userNifStakes[msg.sender].peerAllocationTime = block.timestamp;
            
            try userNifStakes[msg.sender].peerConsumer.allocationUpdate(
                msg.sender, 
                prevAmount, 
                prevAllocation, 
                userNifStakes[msg.sender].peer
            ) 
                returns(bool _accepted, uint256 _untEarned)
            {
                
                accepted = _accepted;
                untEarned = _untEarned;
                
            } catch {}
            
            require(accepted, "stake: allocation update has been rejected.");
        }
        
        IERC20Simple(nifAddress).transferFrom(msg.sender, address(this), _stake);

        emit Staked(msg.sender, _stake, accepted, untEarned);
        
        return (accepted, untEarned);
    }
    
    /**
     * Returns credited NIF after the cooldown period.
     * 
     * */
    function withdraw() external lock {
        
        require(pausing || block.timestamp >= userNifStakes[msg.sender].unstakableFrom + graceTime, "withdraw: nif still locked.");
        
        uint256 tmp = credit[msg.sender];
        credit[msg.sender] = 0;
        IERC20Simple(nifAddress).transfer(msg.sender, tmp);
        emit Withdrawn(msg.sender, tmp);
    }

    /**
     * Unstaking is allowed at any given time (after min period and if peers allow it signalled through frozen()).
     *
     * Unstaking removes voting power.
     *
     * returns potential unt earned and sends it to the account.
     * "potentially" as it depends on the consumer's implementation.
     * 
     * returns true or false if the allocationUpdate has been accepted by the peer and the earned unt from allocated peer.
     * */
    function unstake(uint256 _unstaking) external lock returns(bool, uint256){
        
        require(userNifStakes[msg.sender].amount > 0 && userNifStakes[msg.sender].amount >= _unstaking, "unstakeInternal: insufficient funds.");
        
        bool accepted = true;
        uint256 untEarned = 0;
        
        userNifStakes[msg.sender].unstakableFrom = block.timestamp + nifStakeTimelock;
        credit[msg.sender] += _unstaking;
        
        if(userNifStakes[msg.sender].amount - _unstaking == 0){
            
            untEarned = dellocateInternal(msg.sender);
            
            // dellocate above needs the current staking amounts prior removing them.
            // since we use re-entrancy guarding, the below is not exploitable.
            userNifStakes[msg.sender].amount -= _unstaking;
            allNifStakes -= _unstaking;
            
        }
        else if(
            userNifStakes[msg.sender].amount - _unstaking != 0 && 
            address(userNifStakes[msg.sender].peerConsumer) != address(0) && 
            consumerIdByType[ userNifStakes[msg.sender].peerConsumer ] != 0
        ) {
            
            uint256 prevAmount = userNifStakes[msg.sender].amount;
            userNifStakes[msg.sender].amount -= _unstaking;
            allNifStakes -= _unstaking;
            
            uint256 prevAllocation = consumerPeerNifAllocation[ userNifStakes[msg.sender].peerConsumer ][ userNifStakes[msg.sender].peer ];
            consumerPeerNifAllocation[ userNifStakes[msg.sender].peerConsumer ][ userNifStakes[msg.sender].peer ] -= _unstaking;
            consumerNifAllocation[ userNifStakes[msg.sender].peerConsumer ] -= _unstaking;
            nifAllocation -= _unstaking;
            
            userNifStakes[msg.sender].peerAllocationTime = block.timestamp;
            
            try userNifStakes[msg.sender].peerConsumer.allocationUpdate(
                msg.sender, 
                prevAmount, 
                prevAllocation, 
                userNifStakes[msg.sender].peer
            ) 
                returns(bool _accepted, uint256 _untEarned)
            {
                accepted = _accepted;
                untEarned = _untEarned;
                
            } catch {}
        }
        else
        {
            
            userNifStakes[msg.sender].amount -= _unstaking;
            allNifStakes -= _unstaking;
        }
        
        emit Unstaked(msg.sender, _unstaking, accepted, untEarned);
        return (accepted, untEarned);
    }
    
    /**
     * Allocates stakes to a consumer's peer.
     * Fails if an allocated peer does not accept the allocation.
     * 
     * returns the earned unt from the previous peer if any.
     * */
    function allocate(IUniftyGovernanceConsumer _consumer, address _peer) external lock returns(uint256) {
        
        require(!isPausing(), "allocate: pausing, sorry.");
        require(userNifStakes[msg.sender].amount > 0, "allocate: you must stake first.");
        require(_peer != address(0) && address(_consumer) != address(0), "allocate: peer and consumer mustn't be null." );
        require(consumerIdByType[ _consumer ] != 0, "allocate: consumer doesn't exist.");
        require(consumerPeerExists[ _consumer ][ _peer ], "allocate: peer doesn't exist.");
        require(userNifStakes[msg.sender].peer != _peer, "allocate: you are allocating to this peer already.");
        require(!frozen(msg.sender), "allocate: cannot dellocate, allocation still frozen by current consumer.");
        
        uint256 untEarned = dellocateInternal(msg.sender); 
        
        userNifStakes[msg.sender].peerConsumer = _consumer;
        userNifStakes[msg.sender].peer = _peer;
        userNifStakes[msg.sender].peerAllocationTime = block.timestamp;
        
        uint256 prevAllocation = consumerPeerNifAllocation[ _consumer ][ _peer ];
        consumerPeerNifAllocation[ _consumer ][ _peer ] += userNifStakes[msg.sender].amount;
        consumerNifAllocation[ _consumer ] += userNifStakes[msg.sender].amount;
        nifAllocation += userNifStakes[msg.sender].amount;
        nifAllocationLength[ userNifStakes[msg.sender].peerConsumer ][ userNifStakes[msg.sender].peer ] += 1;
        
        bool accepted = false;
        try _consumer.allocate(msg.sender, prevAllocation, _peer) returns(bool _accepted) { 
            accepted = _accepted;
        }
        catch{ }
        
        // we do NOT use assert() here because there is no reason to panic.
        require(accepted, "allocate: allocation denied by consumer/peer or consumer is faulty.");
        
        emit Allocated(msg.sender, _consumer, _peer, untEarned);
        return untEarned;
    }
    
    /**
     * Dellocates a user's peer-allocation
     * 
     * */
    function dellocate() external lock returns(uint256) {
        
        require(address(userNifStakes[msg.sender].peerConsumer) != address(0), "dellocatePeer: nothing to dellocate.");
        
        return dellocateInternal(msg.sender);
        
    }
    
    /**
     * dellocates from an account's peer.
     * 
     * consumer.dellocate() in the end is 
     * a) a trusted contract
     * b) never called outside of re-entrancy guard-protected function
     * 
     * returns potential unt earnings being sent to the wallet alongside the dellocation.
     * */
    function dellocateInternal(address _sender) internal returns(uint256){
        
        if(address(userNifStakes[_sender].peerConsumer) == address(0)) { return 0; }
        
        // we allow dellocation upon pausing as it would indicate major trouble 
        // and unstaking NIF should be possible at all costs.
        require(!frozen(_sender) || pausing, "dellocateInternal: cannot dellocate, allocation still frozen by consumer.");
        
        IUniftyGovernanceConsumer tmpConsumer = userNifStakes[_sender].peerConsumer;
        address tmpPeer = userNifStakes[_sender].peer;
        uint256 untEarned = 0;
        
        uint256 prevAllocation = consumerPeerNifAllocation[ tmpConsumer ][ tmpPeer ];
        consumerPeerNifAllocation[ tmpConsumer ][ tmpPeer ] -= userNifStakes[_sender].amount;
        consumerNifAllocation[ tmpConsumer ] -= userNifStakes[_sender].amount;
        nifAllocation -= userNifStakes[_sender].amount;
        nifAllocationLength[ tmpConsumer ][ tmpPeer ] -= 1;
        
        userNifStakes[_sender].peerConsumer = IUniftyGovernanceConsumer(address(0));
        userNifStakes[_sender].peer = address(0);
        userNifStakes[_sender].peerAllocationTime = block.timestamp;
        
        if(consumerIdByType[ tmpConsumer ] != 0){
            try tmpConsumer.dellocate(_sender, prevAllocation, tmpPeer) returns(uint256 _untEarned){ 
                untEarned = _untEarned;
            }catch{ }
        }
        
        emit Dellocated(_sender, tmpConsumer, tmpPeer, untEarned);
        return untEarned;
    }
    
    /**
     * Checks if the consumer and peer an account allocated funds are frozen or not.
     * 
     * */
    function frozen(address _account) public view returns(bool){
        
        bool exists = consumerPeerExists[ userNifStakes[_account].peerConsumer ][ userNifStakes[_account].peer ];
        
        if(exists){
            
            // this won't stop malicious consumers from not releasing allocations
            // but it will at least help unfreezing allocations if consumers didn't implement peer handling properly
            // or if a peer has been removed while the user is still allocating.
            //
            // malicious/broken consumers should be spotted prior acceptance through contract reviews or being removed through proposals if slipping through.
            
            bool existsInConsumer = false;
            
            try userNifStakes[_account].peerConsumer.peerWhitelisted( userNifStakes[_account].peer ) returns(bool result){
                
                existsInConsumer = result;
                
            }catch{}
            
            if(!existsInConsumer){
                
                return false;
            }
            
            // in case of missing or faulty implementation of frozen() in the consumer, we want to catch that and signal nothing is being frozen
            
            try userNifStakes[_account].peerConsumer.frozen(_account) returns(bool result){
                
                return result;
                
            }catch{}
        }
        
        return false;
    }
    
    /**
     * The userNifStakes struct as accountInfo as convenience function for external callers.
     * 
     * Returns nulled peer allocations if the peer doesn't exist any longer, 
     * so this should be called externally to get proper information about the current peer state of an account.
     * 
     * */
    function accountInfo(address _account) external view returns(IUniftyGovernanceConsumer, address, uint256, uint256, uint256){
        
        bool exists = consumerPeerExists[ userNifStakes[_account].peerConsumer ][ userNifStakes[_account].peer ];
        
        IUniftyGovernanceConsumer consumer = userNifStakes[_account].peerConsumer;
        address peer = userNifStakes[_account].peer;
        uint256 allocationTime = userNifStakes[_account].peerAllocationTime;
        
        if(!exists){
            
            consumer = IUniftyGovernanceConsumer(address(0));
            peer = address(0);
            allocationTime = 0;
        }
        
        return ( 
            consumer,
            peer,  
            allocationTime,
            userNifStakes[_account].unstakableFrom,
            userNifStakes[_account].amount
        );
    }
    
    /**
     * The consumer struct info as convenience function for external callers.
     * 
     * */
    function consumerInfo(IUniftyGovernanceConsumer _consumer) external view returns(uint256, uint256, uint256, address[] memory){
        
        LUniftyGovernance.Consumer memory con = consumers[ consumerIdByType[ _consumer ] ];
        
        return ( 
            con.grantStartTime,
            con.grantRateSeconds,
            con.grantSizeUnt,
            con.peers
        );
    }

    /* ################################
    #
    # PROPOSALS & VOTES
    #
    ######################################## */

    /**
     *
     * Action ID = 1
     *
     * */
    function proposeMinNifOverallStake(uint256 _minNifOverallStake, uint256 _duration, string calldata _url) external lock{

        /**
         * newProposal() is an internal call, not externally, so this does NOT cause risks.
         * Also re-entrancy guards are consistently used.
         * 
         * */
        uint256 pid = newProposal(msg.sender, _duration, _url, 1);
        uint256Proposal[pid].value = _minNifOverallStake;
    }

    /**
     *
     * Action ID = 2
     *
     * */
    function proposeMinNifStake(uint256 _minNifStake, uint256 _duration, string calldata _url) external lock{

        uint256 pid = newProposal(msg.sender, _duration, _url, 2);
        uint256Proposal[pid].value = _minNifStake;
    }

    /**
     *
     * Action ID = 3
     *
     * _percentages must be current consumers length + 1.
     *
     * The last item in _percentages is the percentage for the currently proposed consumer.
     *
     * */
    function proposeAddConsumer(IUniftyGovernanceConsumer _consumer, uint256 _sizeUnt, uint256 _rateSeconds, uint256 _startTime, uint256 _duration, string calldata _url) external lock{

        require(address(_consumer) != address(0), "proposeAddConsumer: consumer may not be the null address.");
        require(consumerIdByType[ _consumer ] == 0, "proposeAddConsumer: consumer exists already.");
        require(_rateSeconds != 0, "proposeAddConsumer: invalid rate");
        require(_sizeUnt != 0, "proposeAddConsumer: invalid grant size.");
      
        uint256 pid = newProposal(msg.sender, _duration, _url, 3);
        addressProposal[pid].value = address(_consumer);
        uint256Proposal[pid].value = _sizeUnt;
        uint256Proposal[pid].value3 = _rateSeconds;
        uint256Proposal[pid].value4 = _startTime;
    }

    /**
     *
     * Action ID = 4
     *
     * */
    function proposeRemoveConsumer(IUniftyGovernanceConsumer _consumer, uint256 _duration, string calldata _url) external lock{

        require(address(_consumer) != address(0), "proposeRemoveConsumer: consumer may not be the null address.");
        require(consumers[ consumerIdByType[ _consumer ] ].consumer == _consumer , "proposeRemoveConsumer: consumer not found.");
        uint256 pid = newProposal(msg.sender, _duration, _url, 4);
        addressProposal[pid].value = address(_consumer);
    }

    /**
     *
     * Action ID = 5
     *
     * */
    function proposeConsumerWhitelistPeer(IUniftyGovernanceConsumer _consumer, address _peer, uint256 _duration, string calldata _url) external lock{

        require(_peer != address(0), "proposeConsumerWhitelistPeer: peer may not be the null address.");
        require(!consumerPeerExists[ _consumer ][ _peer ], "proposeConsumerWhitelistPeer: peer exists already.");
        require(!peerExists[_peer], "proposeConsumerWhitelistPeer: peer exists already.");
        
        uint256 pid = newProposal(msg.sender, _duration, _url, 5);
        addressProposal[pid].value = _peer;
        addressProposal[pid].value3 = address(_consumer);
    }

    /**
     *
     * Action ID = 6
     *
     * */
    function proposeConsumerRemovePeerFromWhitelist(IUniftyGovernanceConsumer _consumer, address _peer, uint256 _duration, string calldata _url) external lock{

        require(address(_consumer) != address(0), "proposeConsumerRemovePeerFromWhitelist: consumer may not be the null address.");
        require(consumers[ consumerIdByType[ _consumer ] ].consumer == _consumer , "proposeConsumerRemovePeerFromWhitelist: consumer not found.");
        require(consumerPeerExists[ _consumer ][ _peer ], "proposeConsumerRemovePeerFromWhitelist: peer not found.");
        
        uint256 pid = newProposal(msg.sender, _duration, _url, 6);
        addressProposal[pid].value = _peer;
        addressProposal[pid].value2.push(address(_consumer));
    }
    
    /**
     *
     * Action ID = 7
     *
     * */
    function proposeUpdateConsumerGrant(IUniftyGovernanceConsumer _consumer, uint256 _sizeUnt, uint256 _rateSeconds, uint256 _startTime, uint256 _duration, string calldata _url) external lock{

        require(consumerIdByType[ _consumer ] != 0, "updateConsumerGrant: consumer doesn't exist.");
        require(_rateSeconds != 0, "updateConsumerGrant: invalid rate");
        require(_sizeUnt != 0, "proposeUpdateConsumerGrant: invalid grant size.");
        
        uint256 pid = newProposal(msg.sender, _duration, _url, 7);
        addressProposal[pid].value = address(_consumer);
        uint256Proposal[pid].value = _sizeUnt;
        uint256Proposal[pid].value3 = _rateSeconds;
        uint256Proposal[pid].value4 = _startTime;
    }
    
    /**
     *
     * Action ID = 8
     *
     * */
    function proposeMinNifConsumptionStake(uint256 _minNifConsumptionStake, uint256 _duration, string calldata _url) external lock{

        uint256 pid = newProposal(msg.sender, _duration, _url, 8);
        uint256Proposal[pid].value = _minNifConsumptionStake;
    }
    
    /**
     *
     * Action ID = 9
     *
     * */
    function proposeGeneral( uint256 _duration, string calldata _url) external lock{

       newProposal(msg.sender, _duration, _url, 9);
    }
    
    /**
     *
     * Action ID = 10
     *
     * */
    function proposeMaxProposalDuration( uint256 _maxProposalDuration, uint256 _duration, string calldata _url) external lock{

       uint256 pid = newProposal(msg.sender, _duration, _url, 10);
       uint256Proposal[pid].value = _maxProposalDuration;
    }
    
    /**
     *
     * Action ID = 11
     *
     * */
    function proposeMinProposalDuration( uint256 _minProposalDuration, uint256 _duration, string calldata _url) external lock{

       uint256 pid = newProposal(msg.sender, _duration, _url, 11);
       uint256Proposal[pid].value = _minProposalDuration;
    }
    
    /**
     *
     * Action ID = 12
     *
     * */
    function proposeProposalExecutionLimit(uint256 _proposalExecutionLimit, uint256 _duration, string calldata _url) external lock{

       uint256 pid = newProposal(msg.sender, _duration, _url, 12);
       uint256Proposal[pid].value = _proposalExecutionLimit;
    }
    
    /**
     *
     * Action ID = 13
     *
     * */
    function proposeQuorum(uint256 _quorum, uint256 _duration, string calldata _url) external lock{

       uint256 pid = newProposal(msg.sender, _duration, _url, 13);
       uint256Proposal[pid].value = _quorum;
    }
    
    /**
     *
     * Action ID = 14
     *
     * */
    function proposeNifStakeTimelock(uint256 _nifStakeTimelock, uint256 _duration, string calldata _url) external lock{

       uint256 pid = newProposal(msg.sender, _duration, _url, 14);
       uint256Proposal[pid].value = _nifStakeTimelock;
    }
    

    /**
     * A new proposal implies the initiator is in support of proposal (counts as vote already).
     * He does not, nor can't, vote once he placed a proposal.
     *
     * */
    function newProposal(address _sender, uint256 _duration, string memory _url, uint256 _actionId) internal returns(uint256){

        require(!isPausing(), "newProposal: pausing, sorry.");
        require(_duration <= maxProposalDuration, "newProposal: duration too long.");
        require(_duration >= minProposalDuration, "newProposal: min. duration too short.");
        require(userNifStakes[_sender].amount >= minNifStake, "newProposal: invalid stake.");

        // we assume the initiator is supporting the proposal when opening it
        proposals[ proposalCounter ].initiator = _sender;
        proposals[ proposalCounter ].url = _url;
        proposals[ proposalCounter ].numVotes += 1;
        proposals[ proposalCounter ].numSupporting += userNifStakes[_sender].amount;
        proposals[ proposalCounter ].proposalId = proposalCounter;
        proposals[ proposalCounter ].voted[_sender] = true;
        proposals[ proposalCounter ].openUntil = block.timestamp + _duration;
        proposals[ proposalCounter ].actionId = _actionId;

        emit Proposed(_sender, proposalCounter, proposals[ proposalCounter ].openUntil, _actionId);

        votes[ proposalCounter ].push(LUniftyGovernance.Vote({
            voter: _sender,
            supporting: true,
            power: userNifStakes[_sender].amount,
            proposalId: proposalCounter,
            voteTime: block.timestamp
        }));
        
        emit Voted(_sender, proposalCounter, votesCounter[ proposalCounter ] + 1, true, userNifStakes[_sender].amount);

        uint256 ret = proposalCounter;

        // starts at 0, not 1 as we can loop "normally" from 0 to n-1 with clients

        votesCounter[ proposalCounter ] += 1;

        // ...same for the proposal counter

        proposalCounter += 1;

        return ret;

    }

    /**
     * A vote for a proposal uses the user nif earned points as voting power.
     *
     * */
    function vote(uint256 _proposalId, bool _supporting) external lock {

        require(!isPausing(), "vote: pausing, sorry.");
        require(userNifStakes[msg.sender].amount >= minNifStake, "vote: invalid stake.");
        require(proposals[ _proposalId ].initiator != address(0) && block.timestamp <= proposals[ _proposalId ].openUntil, "vote: invalid or expired proposal.");
        require(!proposals[ _proposalId ].voted[msg.sender], "vote: you voted already.");

        proposals[ _proposalId ].numVotes += 1;

        if(_supporting){

            proposals[ _proposalId ].numSupporting += userNifStakes[msg.sender].amount;

        }else{

            proposals[ _proposalId ].numNotSupporting += userNifStakes[msg.sender].amount;
        }

        proposals[ _proposalId ].voted[msg.sender] = true;

        votes[ _proposalId ].push(LUniftyGovernance.Vote({
            voter: msg.sender,
            supporting: _supporting,
            power: userNifStakes[msg.sender].amount,
            proposalId: _proposalId,
            voteTime: block.timestamp
        }));

        emit Voted(msg.sender, _proposalId, votesCounter[ _proposalId ], _supporting, userNifStakes[msg.sender].amount);

        votesCounter[ _proposalId ] += 1;
    }
    
    /**
     * For clients with ABI v1 support
     * 
     * */
    function voted(uint256 _proposalId, address _account) external view returns(bool){
        
        return proposals[_proposalId].voted[_account];
    }
    
    /**
     * service function
     * 
     * */
    function uint256ProposalInfo(uint256 _proposalId) external view returns(uint256, uint256, uint256, uint256[] memory){
      
        return (
            uint256Proposal[_proposalId].value,
            uint256Proposal[_proposalId].value3,
            uint256Proposal[_proposalId].value4,
            uint256Proposal[_proposalId].value2
        );
    }
    
    function addressProposalInfo(uint256 _proposalId) external view returns(address, address, address[] memory){
      
        return (
            addressProposal[_proposalId].value,
            addressProposal[_proposalId].value3,
            addressProposal[_proposalId].value2
        );
    }
    
    /**
     * Triggers the corresponding action if the vote is concluded in favor of support and expired.
     *
     * */
    function execute(uint256 _proposalId) external lock{

        require(!isPausing(), "execute: pausing, sorry.");
        require(isExecutive[msg.sender], "execute: not an executive.");
        require(proposals[ _proposalId ].initiator != address(0), "execute: invalid proposal.");
        require(!proposals[ _proposalId ].executed, "execute: proposal has been executed already.");
        require(proposals[ _proposalId ].numSupporting + proposals[ _proposalId ].numNotSupporting >= quorum, "execute: quorum not reached.");
        require(proposals[ _proposalId ].numSupporting > proposals[ _proposalId ].numNotSupporting, "execute: not enough support.");
        require(proposals[ _proposalId ].numVotes > 1, "execute: need at least 2 votes.");
        require(block.timestamp > proposals[ _proposalId ].openUntil + graceTime, "execute: voting and grace time not yet ended.");
        require(block.timestamp < proposals[ _proposalId ].openUntil + graceTime + proposalExecutionLimit, "execute: execution window expired.");
        
        proposals[ _proposalId ].executed = true;

        // Action ID = 1
        if(proposals[ _proposalId ].actionId == 1){

            minNifOverallStake = uint256Proposal[_proposalId].value;

            // Action ID = 2
        } else if(proposals[ _proposalId ].actionId == 2){

            minNifStake = uint256Proposal[_proposalId].value;

            // Action ID = 8
        } else if(proposals[ _proposalId ].actionId == 8){

            minNifConsumptionStake = uint256Proposal[_proposalId].value;

            // Action ID = 10
        } else if(proposals[ _proposalId ].actionId == 10){

            maxProposalDuration = uint256Proposal[_proposalId].value;

            // Action ID = 11
        } else if(proposals[ _proposalId ].actionId == 11){

            minProposalDuration = uint256Proposal[_proposalId].value;

            // Action ID = 12
        } else if(proposals[ _proposalId ].actionId == 12){

            proposalExecutionLimit = uint256Proposal[_proposalId].value;

            // Action ID = 13
        } else if(proposals[ _proposalId ].actionId == 13){

            quorum = uint256Proposal[_proposalId].value;

            // Action ID = 14
        } else if(proposals[ _proposalId ].actionId == 14){

            nifStakeTimelock = uint256Proposal[_proposalId].value;

            // Action ID = 3
        } else if(proposals[ _proposalId ].actionId == 3){

            require(consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value ) ] == 0, "execute: action id 3 => consumer exists already.");
            require(grantableUnt() >= uint256Proposal[_proposalId].value, "exeute: action id 3 => not enough available UNT." );
            require(uint256Proposal[_proposalId].value3 != 0, "execute: action id 3 => invalid rate");
            
            // setting the proposed startTime to now if it got in the past in the meanwhile 
            if(uint256Proposal[_proposalId].value4 < block.timestamp){
                
                uint256Proposal[_proposalId].value4 = block.timestamp;
            }

            grantedUnt += uint256Proposal[_proposalId].value;

            consumers[ consumerCounter ].consumer = IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value );
            consumers[ consumerCounter ].grantSizeUnt = uint256Proposal[_proposalId].value;
            consumers[ consumerCounter ].grantRateSeconds = uint256Proposal[_proposalId].value3;
            consumers[ consumerCounter ].grantStartTime = uint256Proposal[_proposalId].value4;
            
            consumerIdByType[ consumers[ consumerCounter ].consumer ] = consumerCounter;
            
            consumerCounter += 1;

            // Action ID = 4
        } else if(proposals[ _proposalId ].actionId == 4){
            
            LUniftyGovernance.Consumer memory tmp = consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value ) ] ];
            
            require( address( tmp.consumer ) != address(0), "execute: action id 4 => consumer not found." );
            
            for(uint256 i = 0; i < tmp.peers.length; i++){
                
                consumerPeerExists[ tmp.consumer ][ tmp.peers[i] ] = false;
                peerExists[ tmp.peers[i] ] = false;
            }
            
            // upon consumer removal, the consumer has to give back the rest of his grant
            grantedUnt -= tmp.grantSizeUnt;
            
            consumerIdByType[ consumers[ consumerCounter ].consumer ] = consumerIdByType[ tmp.consumer ];
            
            consumers[ consumerIdByType[ tmp.consumer ] ] = consumers[ consumerCounter ];
            
            consumerIdByType[ tmp.consumer ] = 0;
            
            consumers[ consumerCounter ].consumer = IUniftyGovernanceConsumer(address(0));
            consumers[ consumerCounter ].grantSizeUnt = 0;
            consumers[ consumerCounter ].grantRateSeconds = 0;
            consumers[ consumerCounter ].grantStartTime = 0;
            
            delete consumers[ consumerCounter ].peers;

            consumerCounter -= 1;
            
            for(uint256 i = 0; i < tmp.peers.length; i++){
                
                try tmp.consumer.removePeerFromWhitelist( tmp.peers[i] ){
                    
                }catch{}
            }
        
            // Action ID = 5
        } else if(proposals[ _proposalId ].actionId == 5){
            
            require( address( consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value3 ) ] ].consumer ) != address(0), "execute: action id 5 => consumer not found." );
            require(!consumerPeerExists[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value3 ) ][ addressProposal[ _proposalId ].value ], "execute: action id 5 => peer exists already.");
            require(!peerExists[addressProposal[ _proposalId ].value], "execute: action id 5 => peer exists already.");

            consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value3 ) ] ].peers.push( addressProposal[ _proposalId ].value );
            
            consumerPeerExists[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value3 ) ][ addressProposal[ _proposalId ].value ] = true;
            peerExists[addressProposal[ _proposalId ].value] = true;
            
            consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value3 ) ] ].consumer.whitelistPeer( addressProposal[ _proposalId ].value );
            
            // Action ID = 6
        } else if(proposals[ _proposalId ].actionId == 6){

            LUniftyGovernance.Consumer memory tmp = consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[_proposalId].value2[0] ) ] ];

            require( address( tmp.consumer ) != address(0), "execute: action id 6 => consumer not found." );
            require(consumerPeerExists[ tmp.consumer ][ addressProposal[ _proposalId ].value ], "execute: action id 6 => peer doesn't exist.");
            
            consumerPeerExists[ tmp.consumer ][ addressProposal[ _proposalId ].value ] = false;
            peerExists[addressProposal[ _proposalId ].value] = false;
           
            for(uint256 i = 0; i < tmp.peers.length; i++){
                
                if(addressProposal[ _proposalId ].value == tmp.peers[i]){
                    
                    consumers[ consumerIdByType[ tmp.consumer ] ].peers[i] = tmp.peers[ tmp.peers.length - 1 ];
                    
                    consumers[ consumerIdByType[ tmp.consumer ] ].peers.pop();
                   
                    try tmp.consumer.removePeerFromWhitelist( addressProposal[ _proposalId ].value ){
                        
                    }catch{}
                    
                    break;
                }
            }

            // Action ID = 7
        } else if(proposals[ _proposalId ].actionId == 7){
            
            require(consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value ) ] != 0, "execute: action id 7 => consumer doesn't exist.");
            
            // before we re-calculate the grantable, we give back the rest of what we have
            grantedUnt -= consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value ) ] ].grantSizeUnt;
            
            // ...if then there is enough to grant...
            require(grantableUnt() >= uint256Proposal[_proposalId].value, "exeute: action id 7 => not enough available UNT.");
            
            // ...we gonna allow to accept the new grant
            grantedUnt += uint256Proposal[_proposalId].value;
            
            require(uint256Proposal[_proposalId].value3 != 0, "execute: action id 7 => invalid rate");
            
            // setting the proposed startTime to now if it got in the past in the meanwhile 
            if(uint256Proposal[_proposalId].value4 < block.timestamp){
                
                uint256Proposal[_proposalId].value4 = block.timestamp;
            }
            
            consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value ) ] ].grantSizeUnt = uint256Proposal[_proposalId].value;
            consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value ) ] ].grantRateSeconds = uint256Proposal[_proposalId].value3;
            consumers[ consumerIdByType[ IUniftyGovernanceConsumer( addressProposal[ _proposalId ].value ) ] ].grantStartTime = uint256Proposal[_proposalId].value4;
            
        }
        // proposal action id = 9 does not need to be executed, since it has no parameters. its execution is optional.
        // instead the client should signal if the voting has ended and display the voting results.

        emit Executed(msg.sender, _proposalId);

    }

    /* ################################
    #
    # EPOCHS & GRANTS
    #
    ######################################## */
    
    /**
     * Calculating the current epoch
     * 
     * */
    function epoch() public view returns(uint256){
        
        // we actually want flooring here
        return 1 + ( ( block.timestamp - accrueStart ) / epochDuration );
    }
    
    /**
     * Calculating the available UNT overall
     * based on past and current epochs minus what has been reserved for grants.
     * 
     * Amount of loops is expected to be small, taking hundreds of years before running into gas issues.
     * */
    function grantableUnt() public view returns(uint256){
        
        uint256 all = 0;
        uint256 _epoch = epoch();
        uint256 _prev = genesisReward;
        
        for(uint256 i = 0; i < _epoch; i++){
            
            all += _prev;
            _prev -= ( ( ( _prev * 10**18 ) / 100 ) * 5 ) / 10**18;
            
        }
        
        return all - grantedUnt;
    }
    
    function earnedUnt(IUniftyGovernanceConsumer _consumer) public view returns(uint256){
        
        if(consumerIdByType[ _consumer ] == 0) return 0;
        
        LUniftyGovernance.Consumer memory con = consumers[ consumerIdByType[ _consumer ] ];
        
        if(con.grantRateSeconds == 0) return 0;
        
        uint256 earned = ( ( ( ( block.timestamp - con.grantStartTime ) * 10 ** 18 ) / con.grantRateSeconds ) * con.grantSizeUnt ) / 10**18;
        
        // since the grants are capped, we need to make sure not to display earnings above the cap.
        if(earned > con.grantSizeUnt){
            
            return con.grantSizeUnt;
        }
        
        return earned;
    }
    
    /**
    * Not locked as it must be callable by authorized consumers at any time.
    * This is ok as we do not call any untrusted contract's function 
    * and update all items prior the mint function in the end.
    * 
    */
    function mintUnt(uint256 _amount) external {
        
        require(!isPausing(), "mintUnt: pausing, sorry.");
        require(consumerIdByType[ IUniftyGovernanceConsumer(msg.sender) ] != 0, "mintUnt: access denied.");
        require(allNifStakes >= minNifConsumptionStake, "mintUnt: not enough NIF staked in the governance yet.");
        
        uint256 mint = earnedUnt( IUniftyGovernanceConsumer(msg.sender) );
        
        require(mint != 0 && mint >= _amount, "mintUnt: nothing to mint.");
        
        consumers[ consumerIdByType[ IUniftyGovernanceConsumer(msg.sender) ] ].grantSizeUnt -= _amount;
        
        mintedUnt += _amount;
        mintedUntConsumer[IUniftyGovernanceConsumer(msg.sender)] += _amount;
        
        IERC20Mintable(untAddress).mint(msg.sender, _amount);
    }
    
    /* ################################
    #
    # EXECUTIVES
    # 
    # Executives are responsible for executing accepted proposals.
    # Executives are responsible for pausing the governance (e.g. in case of emergencies).
    #
    ######################################## */

    /**
     * True if either manually paused or overall nif stakes below minNifOverallStake
     *
     * */
    function isPausing() public view returns(bool){

        return pausing || allNifStakes < minNifOverallStake;
    }

    /**
     * Pausing the governance is the responsibility of the governance executives, not votable.
     *
     * */
    function setPaused(bool _pausing) external{

        require(isExecutive[msg.sender], "setPaused: not an executive.");

        pausing = _pausing;
    }

    /**
     * The current executives may add new executives.
     *
     * */
    function setExecutive(address _executive, bool _add) external{

        require(isExecutive[msg.sender], "addExecutive: not an executive.");
        
        if(_add){
            require(!isExecutive[_executive], "addExecutive: already an executive.");
        }else{
            require(msg.sender != _executive, "removeExecutive: you cannot remove yourself.");
        }
        
        isExecutive[_executive] = _add;
    }
}

/* ################################
    #
    # STRUCTS
    #
    ######################################## */

library LUniftyGovernance{

    struct Proposal{
        address initiator;              // the initializing party
        bool executed;                  // yet executed or not?
        uint256 numVotes;               // overall votes
        uint256 numSupporting;          // overall votes in support
        uint256 numNotSupporting;       // overall votes not in support
        uint256 openUntil;              // when will the proposal be expired? timestamp in the future
        uint256 proposalId;             // the proposal ID, value taken from proposalCounter
        uint256 actionId;               // the action id to be executed (resolves to use the right function, e.g. 1 is MinNifOverallStakeProposal)
        string url;                     // the url that points to a json file (in opensea format), containing further information like description
        mapping(address => bool) voted; // voter => bool (voting party has voted?)
    }

    struct Vote{
        address voter;                 // the actual voting party
        bool supporting;               // support yes/no
        uint256 power;                 // the power of this vote
        uint256 proposalId;            // referring proposalId
        uint256 voteTime;              // time of the vote
    }

    // struct that holds uint256 and uint256[] parameters
    // per proposal id for later execution
    struct Uint256Proposal{
        uint256 value;
        uint256 value3;
        uint256 value4;
        uint256[] value2;
    }

    // struct that holds address and address[] parameters
    // per proposal id for later execution
    struct AddressProposal{
        address value;
        address value3;
        address[] value2;
    }

    struct NifStake{

        address user;                  // the user who is staking
        IUniftyGovernanceConsumer peerConsumer; // the consumer of the peer below (optional but if, then both must be set)
        address peer;                  // the peer that this stake allocated to (optional)
        uint256 peerAllocationTime;    // the time when the allocation happened, else 0
        uint256 unstakableFrom;        // timestamp from which the user is allowed to unstake
        uint256 amount;                // the amount of nif that is being staked
    }

    struct Consumer{
 
        IUniftyGovernanceConsumer consumer;   // the consumer object
        uint256 grantStartTime;
        uint256 grantRateSeconds;
        uint256 grantSizeUnt;
        address[] peers;               // array of allowed consumer's peers to receive emissions
    }
}