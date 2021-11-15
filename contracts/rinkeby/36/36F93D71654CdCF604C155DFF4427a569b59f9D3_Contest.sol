// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ContestBase.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract Contest is ContestBase {
    address token;
    
    /**
     * @param token_address token address
     * @param stagesCount count of stages for first Contest
     * @param stagesMinAmount array of minimum amount that need to reach at each stage
     * @param contestPeriodInSeconds duration in seconds  for contest period(exclude before reach minimum amount)
     * @param votePeriodInSeconds duration in seconds  for voting period
     * @param revokePeriodInSeconds duration in seconds  for revoking period
     * @param percentForWinners array of values in percentages of overall amount that will gain winners 
     * @param judges array of judges' addresses. if empty than everyone can vote
     * 
     */
    function init(
        address token_address,
        uint256 stagesCount,
        uint256[] memory stagesMinAmount,
        uint256 contestPeriodInSeconds,
        uint256 votePeriodInSeconds,
        uint256 revokePeriodInSeconds,
        uint256[] memory percentForWinners,
        address[] memory judges
    ) 
        public 
        initializer 
    {
        __ContestBase__init(stagesCount, stagesMinAmount, contestPeriodInSeconds, votePeriodInSeconds, revokePeriodInSeconds, percentForWinners, judges);
        token = token_address;
    }
        
    
    receive() external payable {
        require(true == false, "Method does not support.");
    }
    
    
    /**
     * pledge(amount) can be used to send external token into the contract, and issue internal token balance
     * @param amount amount
     * @param stageID Stage number
     */
    function pledge(uint256 amount, uint256 stageID) public virtual override nonReentrant() {
        uint256 _allowedAmount = IERC20Upgradeable(token).allowance(_msgSender(), address(this));
        require(
            (
                (amount <= _allowedAmount) ||
                (_allowedAmount > 0)
            ), 
            "Amount exceeds allowed balance");

        // try to get
        bool success = IERC20Upgradeable(token).transferFrom(_msgSender(), address(this), _allowedAmount);
        require(success == true, "Transfer tokens were failed"); 
        
        _pledge(amount, stageID);
    }
    
    /**
     * @param amount amount
     */
    function revokeAfter(uint256 amount) internal virtual override nonReentrant() {
        // todo: 0 return back to user 
        bool success = IERC20Upgradeable(token).transfer(_msgSender(),amount);
        require(success == true, 'Transfer tokens were failed');    
    }
    
    /**
     * @param amount amount
     */
    function _claimAfter(uint256 amount) internal virtual override nonReentrant() {
        bool success = IERC20Upgradeable(token).transfer(_msgSender(),amount);
        require(success == true, 'Transfer tokens were failed');    
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IntercoinTrait.sol";

contract ContestBase is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable, IntercoinTrait {
    
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using SafeMathUpgradeable for uint256;

    // ** deprecated 
    // delegateFee (some constant in contract) which is percent of amount. They can delegate their entire amount of vote to the judge, or some.
    // uint256 delegateFee = 5e4; // 5% mul at 1e6
    
    // penalty for revoke tokens
    uint256 revokeFee; // 10% mul at 1e6
    
    EnumerableSetUpgradeable.AddressSet private _judgesWhitelist;
    EnumerableSetUpgradeable.AddressSet private _personsList;
    
    mapping (address => uint256) private _balances;
    
    Contest _contest;
    
    struct Contest {
        uint256 stage;
        uint256 stagesCount;
        mapping (uint256 => Stage) _stages;

    }
	
    struct Stage {
        uint256 winnerWeight;

        mapping (uint256 => address[]) winners;
        bool winnersLock;

        uint256 amount;     // acummulated all pledged 
        uint256 minAmount;
        
        bool active;    // stage will be active after riched minAmount
        bool completed; // true if stage already processed
        uint256 startTimestampUtc;
        uint256 contestPeriod; // in seconds
        uint256 votePeriod; // in seconds
        uint256 revokePeriod; // in seconds
        uint256 endTimestampUtc;
        EnumerableSetUpgradeable.AddressSet contestsList;
        EnumerableSetUpgradeable.AddressSet pledgesList;
        EnumerableSetUpgradeable.AddressSet judgesList;
        EnumerableSetUpgradeable.UintSet percentForWinners;
        mapping (address => Participant) participants;
    }
   
    // This declares a new complex type which will
    // be used for variables later.
    // It will represent a single participant at single stage
    struct Participant {
        uint256 weight; // user weight
        uint256 balance; // user balance
        uint256 balanceAfter; // balance after calculate
        bool voted;  // if true, that person already voted
        address voteTo; // person voted to
        bool delegated;  // if true, that person delegated to some1
        address delegateTo; // person delegated to
        EnumerableSetUpgradeable.AddressSet delegatedBy; // participant who delegated own weight
        EnumerableSetUpgradeable.AddressSet votedBy; // participant who delegated own weight
        bool won;  // if true, that person won round. setup after EndOfStage
        bool claimed; // if true, that person claimed them prise if won ofc
        bool revoked; // if true, that person revoked from current stage
        //bool left; // if true, that person left from current stage and contestant list
        bool active; // always true

    }

	event ContestStart();
    event ContestComplete();
    event ContestWinnerAnnounced(address[] indexed winners);
    event StageStartAnnounced(uint256 indexed stageID);
    event StageCompleted(uint256 indexed stageID);
    
    
	////
	// modifiers section
	////
	
    /**
     * @param account address
     * @param stageID Stage number
     */
    modifier onlyNotVotedNotDelegated(address account, uint256 stageID) {
         require(
             (_contest._stages[stageID].participants[account].voted == false) && 
             (_contest._stages[stageID].participants[account].delegated == false), 
            "Person must have not voted or delegated before"
        );
        _;
    }
    
    /**
     * @param account address
     * @param stageID Stage number
     */
    modifier judgeNotDelegatedBefore(address account, uint256 stageID) {
         require(
             (_contest._stages[stageID].participants[account].delegated == false), 
            "Judge has been already delegated"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier stageActive(uint256 stageID) {
        require(
            (_contest._stages[stageID].active == true), 
            "Stage have still in gathering mode"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier stageNotCompleted(uint256 stageID) {
        require(
            (_contest._stages[stageID].completed == false), 
            "Stage have not completed yet"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canPledge(uint256 stageID) {
        uint256 endContestTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod);
        require(
            (
                (
                    _contest._stages[stageID].active == false
                ) || 
                (
                    (_contest._stages[stageID].active == true) && (endContestTimestamp > block.timestamp)
                )
            ), 
            "Stage is out of contest period"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canDelegateAndVote(uint256 stageID) {
        uint256 endContestTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod);
        uint256 endVoteTimestamp = endContestTimestamp.add(_contest._stages[stageID].votePeriod);
        require(
            (
                (_contest._stages[stageID].active == true) && 
                (endVoteTimestamp > block.timestamp) && 
                (block.timestamp >= endContestTimestamp)
            ), 
            "Stage is out of voting period"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canRevoke(uint256 stageID) {
        uint256 endContestTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod);
        uint256 endVoteTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod).add(_contest._stages[stageID].votePeriod);
        uint256 endRevokeTimestamp = _contest._stages[stageID].endTimestampUtc;
        
        require(
            (
                (
                    (_contest._stages[stageID].active == true) && (endRevokeTimestamp > block.timestamp) && (block.timestamp >= endContestTimestamp)
                )
            ), 
            "Stage is out of revoke or vote period"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier canClaim(uint256 stageID) {
        uint256 endTimestampUtc = _contest._stages[stageID].endTimestampUtc;
        require(
            (
                (
                    (_contest._stages[stageID].participants[_msgSender()].revoked == false) && 
                    (_contest._stages[stageID].participants[_msgSender()].claimed == false) && 
                    (_contest._stages[stageID].completed == true) && 
                    (_contest._stages[stageID].active == true) && 
                    (block.timestamp > endTimestampUtc)
                )
            ), 
            "Stage have not completed or sender has already claimed or revoked"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier inContestsList(uint256 stageID) {
        require(
             (_contest._stages[stageID].contestsList.contains(_msgSender())), 
            "Sender must be in contestant list"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier notInContestsList(uint256 stageID) {
        require(
             (!_contest._stages[stageID].contestsList.contains(_msgSender())), 
            "Sender must not be in contestant list"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier inPledgesList(uint256 stageID) {
        require(
             (_contest._stages[stageID].pledgesList.contains(_msgSender())), 
            "Sender must be in pledge list"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier notInPledgesList(uint256 stageID) {
        require(
             (!_contest._stages[stageID].pledgesList.contains(_msgSender())), 
            "Sender must not be in pledge list"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier inJudgesList(uint256 stageID) {
        require(
             (_contest._stages[stageID].judgesList.contains(_msgSender())), 
            "Sender must be in judges list"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */
    modifier notInJudgesList(uint256 stageID) {
        require(
             (!_contest._stages[stageID].judgesList.contains(_msgSender())), 
            "Sender must not be in judges list"
        );
        _;
    }
    
    /**
     * @param stageID Stage number
     */        
    modifier inPledgesOrJudgesList(uint256 stageID) {
        require(
             (
                 _contest._stages[stageID].pledgesList.contains(_msgSender()) ||
                 _contest._stages[stageID].judgesList.contains(_msgSender())
             )
             , 
            "Sender must be in pledges or judges list"
        );
        _;
    }  
    
    /**
     * @param stageID Stage number
     */
    modifier canCompleted(uint256 stageID) {
         require(
            (
                (_contest._stages[stageID].completed == false) &&
                (_contest._stages[stageID].active == true) &&
                (_contest._stages[stageID].endTimestampUtc < block.timestamp)
            ), 
            string("Last stage have not ended yet")
        );
        _;
    }
    ////
	// END of modifiers section 
	////
        
    //constructor() public {}
    
	/**
     * @param stagesCount count of stages for first Contest
     * @param stagesMinAmount array of minimum amount that need to reach at each stage
     * @param contestPeriodInSeconds duration in seconds  for contest period(exclude before reach minimum amount)
     * @param votePeriodInSeconds duration in seconds  for voting period
     * @param revokePeriodInSeconds duration in seconds  for revoking period
     * @param percentForWinners array of values in percentages of overall amount that will gain winners 
     * @param judges array of judges' addresses. if empty than everyone can vote
     * 
     */
    function __ContestBase__init(
        uint256 stagesCount,
        uint256[] memory stagesMinAmount,
        uint256 contestPeriodInSeconds,
        uint256 votePeriodInSeconds,
        uint256 revokePeriodInSeconds,
        uint256[] memory percentForWinners,
        address[] memory judges
    ) 
        internal 
        initializer 
    {
        __Ownable_init();
        __ReentrancyGuard_init();
    
        revokeFee = 10e4;
        
        uint256 stage = 0;
        
        _contest.stage = 0;            
        for (stage = 0; stage < stagesCount; stage++) {
            _contest._stages[stage].minAmount = stagesMinAmount[stage];
            _contest._stages[stage].winnersLock = false;
            _contest._stages[stage].active = false;
            _contest._stages[stage].contestPeriod = contestPeriodInSeconds;
            _contest._stages[stage].votePeriod = votePeriodInSeconds;
            _contest._stages[stage].revokePeriod = revokePeriodInSeconds;
            
            for (uint256 i = 0; i < judges.length; i++) {
                _contest._stages[stage].judgesList.add(judges[i]);
            }
            
            for (uint256 i = 0; i < percentForWinners.length; i++) {
                _contest._stages[stage].percentForWinners.add(percentForWinners[i]);
            }
        }
        
        emit ContestStart();
        
        
    }

    ////
	// public section
	////
	/**
	 * @dev show contest state
	 * @param stageID Stage number
	 */
    function isContestOnline(uint256 stageID) public view returns (bool res){

        if (
            (_contest._stages[stageID].winnersLock == false) &&
            (
                (_contest._stages[stageID].active == false) ||
                ((_contest._stages[stageID].active == true) && (_contest._stages[stageID].endTimestampUtc > block.timestamp))
            ) && 
            (_contest._stages[stageID].completed == false)
        ) {
            res = true;
        } else {
            res = false;
        }
    }

    /**
     * @param amount amount to pledge
	 * @param stageID Stage number
     */
    function pledge(uint256 amount, uint256 stageID) public virtual {
        _pledge(amount, stageID);
    }
    
    /**
     * @param judge address of judge which user want to delegate own vote
	 * @param stageID Stage number
     */
    function delegate(
        address judge, 
        uint256 stageID
    ) 
        public
        notInContestsList(stageID)
        stageNotCompleted(stageID)
        onlyNotVotedNotDelegated(_msgSender(), stageID)
        judgeNotDelegatedBefore(judge, stageID)
    {
        _delegate(judge, stageID);
    }
    
    /** 
     * @param contestantAddress address of contestant which user want to vote
	 * @param stageID Stage number
     */     
    function vote(
        address contestantAddress,
        uint256 stageID
    ) 
        public 
        notInContestsList(stageID)
        onlyNotVotedNotDelegated(_msgSender(), stageID)  
        stageNotCompleted(stageID)
        canDelegateAndVote(stageID)
    {
        _vote(contestantAddress, stageID);
    }
    
    /**
     * @param stageID Stage number
     */
    function claim(
        uint256 stageID
    )
        public
        inContestsList(stageID)
        canClaim(stageID)
    {
        _contest._stages[stageID].participants[_msgSender()].claimed = true;
        uint prizeAmount = _contest._stages[stageID].participants[_msgSender()].balanceAfter;
        _claimAfter(prizeAmount);
    }
    
    /**
     * @param stageID Stage number
     */
    function enter(
        uint256 stageID
    ) 
        notInContestsList(stageID) 
        notInPledgesList(stageID) 
        notInJudgesList(stageID) 

        public 
    {
        _enter(stageID);
    }
    
    /**
     * @param stageID Stage number
     */   
    function leave(
        uint256 stageID
    ) 
        public 
    {
        _leave(stageID);
    }
    
    /**
     * @param stageID Stage number
     */
    function revoke(
        uint256 stageID
    ) 
        public
        notInContestsList(stageID)
        stageNotCompleted(stageID)
        canRevoke(stageID)
    {
        
        _revoke(stageID);
        
        _contest._stages[stageID].participants[_msgSender()].revoked == true;
            
        uint revokedBalance = _contest._stages[stageID].participants[_msgSender()].balance;
        _contest._stages[stageID].amount = _contest._stages[stageID].amount.sub(revokedBalance);
        revokeAfter(revokedBalance.sub(revokedBalance.mul(_calculateRevokeFee(stageID)).div(1e6)));
    } 

    ////
	// internal section
	////
	
	/**
	 * calculation revokeFee penalty.  it gradually increased if revoke happens in voting period
	 * @param stageID Stage number
	 */
	function _calculateRevokeFee(
	    uint256 stageID
    )
        internal 
        view
        returns(uint256)
    {
        uint256 endContestTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod);
        uint256 endVoteTimestamp = (_contest._stages[stageID].startTimestampUtc).add(_contest._stages[stageID].contestPeriod).add(_contest._stages[stageID].votePeriod);
        
        if ((endVoteTimestamp > block.timestamp) && (block.timestamp >= endContestTimestamp)) {
            uint256 revokeFeePerSecond = (revokeFee).div(endVoteTimestamp.sub(endContestTimestamp));
            return revokeFeePerSecond.mul(block.timestamp.sub(endContestTimestamp));
            
        } else {
            return revokeFee;
        }
        
    }
	
	/**
     * @param judge address of judge which user want to delegate own vote
     * @param stageID Stage number
     */
    function _delegate(
        address judge, 
        uint256 stageID
    ) 
        internal 
        canDelegateAndVote(stageID)
    {
        
        // code left for possibility re-delegate
        // if (_contests[contestID]._stages[stageID].participants[_msgSender()].delegated == true) {
        //     _revoke(stageID);
        // }
        _contest._stages[stageID].participants[_msgSender()].delegated = true;
        _contest._stages[stageID].participants[_msgSender()].delegateTo = judge;
        _contest._stages[stageID].participants[judge].delegatedBy.add(_msgSender());
    }
    
    /** 
     * @param contestantAddress address of contestant which user want to vote
	 * @param stageID Stage number
     */ 
    function _vote(
        address contestantAddress,
        uint256 stageID
    ) 
        internal
    {
           
        require(
            _contest._stages[stageID].contestsList.contains(contestantAddress), 
            "contestantAddress must be in contestant list"
        );
     
        // code left for possibility re-vote
        // if (_contests[contestID]._stages[stageID].participants[_msgSender()].voted == true) {
        //     _revoke(stageID);
        // }
        //----
        
        _contest._stages[stageID].participants[_msgSender()].voted = true;
        _contest._stages[stageID].participants[_msgSender()].voteTo = contestantAddress;
        _contest._stages[stageID].participants[contestantAddress].votedBy.add(_msgSender());
    }
    
    /**
     * @param amount amount 
     */
    function _claimAfter(uint256 amount) internal virtual { }
    
    /**
     * @param amount amount 
     */
    function revokeAfter(uint256 amount) internal virtual {}
    
    /** 
	 * @param stageID Stage number
     */ 
    function _revoke(
        uint256 stageID
    ) 
        private
    {
        address addr;
        if (_contest._stages[stageID].participants[_msgSender()].voted == true) {
            addr = _contest._stages[stageID].participants[_msgSender()].voteTo;
            _contest._stages[stageID].participants[addr].votedBy.remove(_msgSender());
        } else if (_contest._stages[stageID].participants[_msgSender()].delegated == true) {
            addr = _contest._stages[stageID].participants[_msgSender()].delegateTo;
            _contest._stages[stageID].participants[addr].delegatedBy.remove(_msgSender());
        } else {
            
        }
    }
    
    /**
     * @dev This method triggers the complete(stage), if it hasn't successfully been triggered yet in the contract. 
     * The complete(stage) method works like this: if stageBlockNumber[N] has not passed yet then reject. Otherwise it wraps up the stage as follows, and then increments 'stage':
     * @param stageID Stage number
     */
    function complete(uint256 stageID) public onlyOwner canCompleted(stageID) {
       _complete(stageID);
    }
  
	/**
	 * @dev need to be used after each pledge/enter
     * @param stageID Stage number
	 */
	function _turnStageToActive(uint256 stageID) internal {
	    
        if (
            (_contest._stages[stageID].active == false) && 
            (_contest._stages[stageID].amount >= _contest._stages[stageID].minAmount)
        ) {
            _contest._stages[stageID].active = true;
            // fill time
            _contest._stages[stageID].startTimestampUtc = block.timestamp;
            _contest._stages[stageID].endTimestampUtc = (block.timestamp)
                .add(_contest._stages[stageID].contestPeriod)
                .add(_contest._stages[stageID].votePeriod)
                .add(_contest._stages[stageID].revokePeriod);
            emit StageStartAnnounced(stageID);
        } else if (
            (_contest._stages[stageID].active == true) && 
            (_contest._stages[stageID].endTimestampUtc < block.timestamp)
        ) {
            // run complete
	        _complete(stageID);
	    } else {
            
        }
        
	}
	
	/**
	 * @dev logic for ending stage (calculate weights, pick winners, reward losers, turn to next stage)
     * @param stageID Stage number
	 */
	function _complete(uint256 stageID) internal  {
	    emit StageCompleted(stageID);

	    _calculateWeights(stageID);
	    uint256 percentWinnersLeft = _rewardWinners(stageID);
	    _rewardLosers(stageID, percentWinnersLeft);
	 
	    //mark stage completed
	    _contest._stages[stageID].completed = true;
	    
	    // switch to next stage
	    if (_contest.stagesCount == stageID.add(1)) {
            // just complete if last stage 
            
            emit ContestComplete();
        } else {
            // increment stage
            _contest.stage = (_contest.stage).add(1);
        }
	}
	
	/**
	 * @param amount amount
     * @param stageID Stage number
	 */
    function _pledge(
        uint256 amount, 
        uint256 stageID
    ) 
        internal 
        canPledge(stageID) 
        notInContestsList(stageID) 
    {
        _createParticipant(stageID);
        
        _contest._stages[stageID].pledgesList.add(_msgSender());
        
        // accumalate balance in current stage
        _contest._stages[stageID].participants[_msgSender()].balance = (
            _contest._stages[stageID].participants[_msgSender()].balance
            ).add(amount);
            
        // accumalate overall stage balance
        _contest._stages[stageID].amount = (
            _contest._stages[stageID].amount
            ).add(amount);
        
        _turnStageToActive(stageID);

    }
    
    /**
     * @param stageID Stage number
	 */
    function _enter(
        uint256 stageID
    ) 
        internal 
        notInContestsList(stageID) 
        notInPledgesList(stageID) 
        notInJudgesList(stageID) 
    {
        _turnStageToActive(stageID);
        _createParticipant(stageID);
        _contest._stages[stageID].contestsList.add(_msgSender());
    }
    
    /**
     * @param stageID Stage number
	 */
    function _leave(
        uint256 stageID
    ) 
        internal 
        inContestsList(stageID) 
    {
        _contest._stages[stageID].contestsList.remove(_msgSender());
        _contest._stages[stageID].participants[msg.sender].active = false;
    }
    
    /**
     * @param stageID Stage number
	 */     
    function _createParticipant(uint256 stageID) internal {
        if (_contest._stages[stageID].participants[_msgSender()].active) {
             // ---
        } else {
            //Participant memory p;
            //_contest._stages[stageID].participants[_msgSender()] = p;
            _contest._stages[stageID].participants[_msgSender()].active = true;
        }
    }
    
	////
	// private section
	////
	
	/**
     * @param stageID Stage number
	 */
	function _calculateWeights(uint256 stageID) private {
	       
        // loop via contestsList 
        // find it in participant 
        //     loop via votedBy
        //         in each calculate weight
        //             if delegatedBy empty  -- sum him balance only
        //             if delegatedBy not empty -- sum weight inside all who delegated
        // make array of winners
        // set balanceAfter
	    
	    address addrContestant;
	    address addrVotestant;
	    address addrWhoDelegated;
	    
	    for (uint256 i = 0; i < _contest._stages[stageID].contestsList.length(); i++) {
	        addrContestant = _contest._stages[stageID].contestsList.at(i);
	        for (uint256 j = 0; j < _contest._stages[stageID].participants[addrContestant].votedBy.length(); j++) {
	            addrVotestant = _contest._stages[stageID].participants[addrContestant].votedBy.at(j);
	            
                // sum votes
                _contest._stages[stageID].participants[addrContestant].weight = 
                _contest._stages[stageID].participants[addrContestant].weight.add(
                    _contest._stages[stageID].participants[addrVotestant].balance
                );
                
                // sum all delegated if exists
                for (uint256 k = 0; k < _contest._stages[stageID].participants[addrVotestant].delegatedBy.length(); k++) {
                    addrWhoDelegated = _contest._stages[stageID].participants[addrVotestant].delegatedBy.at(k);
                    _contest._stages[stageID].participants[addrContestant].weight = 
	                _contest._stages[stageID].participants[addrContestant].weight.add(
	                    _contest._stages[stageID].participants[addrWhoDelegated].balance
	                );
                }
	             
	        }
	        
	    }
	}
	
	/**
     * @param stageID Stage number
	 * @return percentLeft percents left if count of winners more that prizes. in that cases left percent distributed to losers
	 */
	function _rewardWinners(uint256 stageID) private returns(uint256 percentLeft)  {
	    
        uint256 indexPrize = 0;
	    address addrContestant;
	    
	    uint256 lenContestList = _contest._stages[stageID].contestsList.length();
	    if (lenContestList>0)  {
	    
    	    uint256[] memory weight = new uint256[](lenContestList);
    
    	    for (uint256 i = 0; i < lenContestList; i++) {
    	        addrContestant = _contest._stages[stageID].contestsList.at(i);
                weight[i] = _contest._stages[stageID].participants[addrContestant].weight;
    	    }
    	    weight = sortAsc(weight);
    
            // dev Note: 
            // the original implementation is an infinite loop. When. i is 0 the loop decrements it again, 
            // but since it's an unsigned integer it undeflows and loops back to the maximum uint 
            // so use  "for (uint i = a.length; i > 0; i--)" and in code "a[i-1]" 
    	    for (uint256 i = weight.length; i > 0; i--) {
    	       for (uint256 j = 0; j < lenContestList; j++) {
    	            addrContestant = _contest._stages[stageID].contestsList.at(j);
    	            if (
    	                (weight[i-1] > 0) &&
    	                (_contest._stages[stageID].participants[addrContestant].weight == weight[i-1]) &&
    	                (_contest._stages[stageID].participants[addrContestant].won == false) &&
    	                (_contest._stages[stageID].participants[addrContestant].active == true) &&
    	                (_contest._stages[stageID].participants[addrContestant].revoked == false)
    	            ) {
    	                 
    	                _contest._stages[stageID].participants[addrContestant].balanceAfter = (_contest._stages[stageID].amount)
    	                    .mul(_contest._stages[stageID].percentForWinners.at(indexPrize))
    	                    .div(100);
                    
                        _contest._stages[stageID].participants[addrContestant].won = true;
                        
                        indexPrize++;
                        break;
    	            }
    	        }
    	        if (indexPrize >= _contest._stages[stageID].percentForWinners.length()) {
    	            break;
    	        }
    	    }
	    }
	    
	    percentLeft = 0;
	    if (indexPrize < _contest._stages[stageID].percentForWinners.length()) {
	       for (uint256 i = indexPrize; i < _contest._stages[stageID].percentForWinners.length(); i++) {
	           percentLeft = percentLeft.add(_contest._stages[stageID].percentForWinners.at(i));
	       }
	    }
	    return percentLeft;
	}
	
    /**
     * @param stageID Stage number
	 * @param prizeWinLeftPercent percents left if count of winners more that prizes. in that cases left percent distributed to losers
	 */
	function _rewardLosers(uint256 stageID, uint256 prizeWinLeftPercent) private {
	    // calculate left percent
	    // calculate howmuch participant loose
	    // calculate and apply left weight
	    address addrContestant;
	    uint256 leftPercent = 100;
	    
	    uint256 prizecount = _contest._stages[stageID].percentForWinners.length();
	    for (uint256 i = 0; i < prizecount; i++) {
	        leftPercent = leftPercent.sub(_contest._stages[stageID].percentForWinners.at(i));
	    }

	    leftPercent = leftPercent.add(prizeWinLeftPercent); 
	    
	    uint256 loserParticipants = 0;
	    if (leftPercent > 0) {
	        for (uint256 j = 0; j < _contest._stages[stageID].contestsList.length(); j++) {
	            addrContestant = _contest._stages[stageID].contestsList.at(j);
	            
	            if (
	                (_contest._stages[stageID].participants[addrContestant].won == false) &&
	                (_contest._stages[stageID].participants[addrContestant].active == true) &&
	                (_contest._stages[stageID].participants[addrContestant].revoked == false)
	            ) {
	                loserParticipants++;
	            }
	        }

	        if (loserParticipants > 0) {
	            uint256 rewardLoser = (_contest._stages[stageID].amount).mul(leftPercent).div(100).div(loserParticipants);
	            
	            for (uint256 j = 0; j < _contest._stages[stageID].contestsList.length(); j++) {
    	            addrContestant = _contest._stages[stageID].contestsList.at(j);
    	            
    	            if (
    	                (_contest._stages[stageID].participants[addrContestant].won == false) &&
    	                (_contest._stages[stageID].participants[addrContestant].active == true) &&
    	                (_contest._stages[stageID].participants[addrContestant].revoked == false)
    	            ) {
    	                _contest._stages[stageID].participants[addrContestant].balanceAfter = rewardLoser;
    	            }
    	        }
	        }
	    }
	}
    
    // useful method to sort native memory array 
    function sortAsc(uint256[] memory data) private returns(uint[] memory) {
       quickSortAsc(data, int(0), int(data.length - 1));
       return data;
    }
    
    function quickSortAsc(uint[] memory arr, int left, int right) private {
        int i = left;
        int j = right;
        if(i==j) return;
        uint pivot = arr[uint(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint(i)] < pivot) i++;
            while (pivot < arr[uint(j)]) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            quickSortAsc(arr, left, j);
        if (i < right)
            quickSortAsc(arr, i, right);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IIntercoin.sol";
import "./interfaces/IIntercoinTrait.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract IntercoinTrait is Initializable, IIntercoinTrait {
    
    address private intercoinAddr;
    bool private isSetup;

    /**
     * setup intercoin contract's address. happens once while initialization through factory
     * @param addr address of intercoin contract
     */
    function setIntercoinAddress(address addr) public override returns(bool) {
        require (addr != address(0), 'Address can not be empty');
        require (isSetup == false, 'Already setup');
        intercoinAddr = addr;
        isSetup = true;
        
        return true;
    }
    
    /**
     * got stored intercoin address
     */
    function getIntercoinAddress() public override view returns (address) {
        return intercoinAddr;
    }
    
    /**
     * @param addr address of contract that need to be checked at intercoin contract
     */
    function checkInstance(address addr) internal view returns(bool) {
        require (intercoinAddr != address(0), 'Intercoin address need to be setup before');
        return IIntercoin(intercoinAddr).checkInstance(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IIntercoin {
    
    function registerInstance(address addr) external returns(bool);
    function checkInstance(address addr) external view returns(bool);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IIntercoinTrait {
    
    function setIntercoinAddress(address addr) external returns(bool);
    function getIntercoinAddress() external view returns (address);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
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
library SafeMathUpgradeable {
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
library EnumerableSetUpgradeable {
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

