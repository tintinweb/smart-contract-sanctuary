pragma solidity 0.4.24;

// File: contracts/EventRegistry.sol

contract EventRegistry {
    address[] verityEvents;
    mapping(address => bool) verityEventsMap;

    mapping(address => address[]) userEvents;

    event NewVerityEvent(address eventAddress);

    function registerEvent() public {
        verityEvents.push(msg.sender);
        verityEventsMap[msg.sender] = true;
        emit NewVerityEvent(msg.sender);
    }

    function getUserEvents() public view returns(address[]) {
        return userEvents[msg.sender];
    }

    function addEventToUser(address _user) external {
        require(verityEventsMap[msg.sender]);

        userEvents[_user].push(msg.sender);
    }

    function getEventsLength() public view returns(uint) {
        return verityEvents.length;
    }

    function getEventsByIds(uint[] _ids) public view returns(uint[], address[]) {
        address[] memory _events = new address[](_ids.length);

        for(uint i = 0; i < _ids.length; ++i) {
            _events[i] = verityEvents[_ids[i]];
        }

        return (_ids, _events);
    }

    function getUserEventsLength(address _user)
        public
        view
        returns(uint)
    {
        return userEvents[_user].length;
    }

    function getUserEventsByIds(address _user, uint[] _ids)
        public
        view
        returns(uint[], address[])
    {
        address[] memory _events = new address[](_ids.length);

        for(uint i = 0; i < _ids.length; ++i) {
            _events[i] = userEvents[_user][_ids[i]];
        }

        return (_ids, _events);
    }
}

// File: contracts/VerityToken.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract VerityToken is StandardToken {
  string public name = "VerityToken";
  string public symbol = "VTY";
  uint8 public decimals = 18;
  uint public INITIAL_SUPPLY = 500000000 * 10 ** uint(decimals);

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}

// File: contracts/VerityEvent.sol

contract VerityEvent {
    /// Contract&#39;s owner, used for permission management
    address public owner;

    /// Token contract address, used for tokend distribution
    address public tokenAddress;

    /// Event registry contract address
    address public eventRegistryAddress;

    /// Designated validation nodes that will decide rewards.
    address[] eventResolvers;

    /// - WaitingForRewards: Waiting for current master to set rewards.
    /// - Validating: Master has set rewards. Vaiting for node validation.
    /// - Finished: Either successfully validated or failed.
    enum ValidationState {
        WaitingForRewards,
        Validating,
        Finished
    }
    ValidationState validationState = ValidationState.WaitingForRewards;

    struct RewardsValidation {
        address currentMasterNode;
        string rewardsHash;
        uint approvalCount;
        uint rejectionCount;
        string[] altHashes;
        mapping(address => uint) votersRound;
        mapping(string => address[]) altHashVotes;
        mapping(string => bool) rejectedHashes;
    }
    RewardsValidation rewardsValidation;

    /// Round of validation. Increases by each failed validation
    uint public rewardsValidationRound;

    /// A list of all the participating wallet addresses, implemented as a mapping
    /// to provide constant lookup times.
    mapping(address => bool) participants;
    address[] participantsIndex;

    enum RewardType {
        Ether,
        Token
    }
    RewardType rewardType;

    /// A mapping of addresses to their assigned rewards
    mapping(address => mapping(uint => uint)) rewards;
    address[] rewardsIndex;

    /// Event application start time, users cannot apply to participate before it
    uint applicationStartTime;

    /// Event application end time, users cannot apply after this time
    uint applicationEndTime;

    /// Event actual start time, votes before this should not be accepted
    uint eventStartTime;

    /// Event end time, it is calculated in the constructor
    uint eventEndTime;

    /// Ipfs event data hash
    string ipfsEventHash;

    /// Event name, here for informational use - not used otherwise
    /// owner can recover tokens and ether after this time
    uint leftoversRecoverableAfter;

    /// Amount of tokens that each user must stake before voting.
    uint public stakingAmount;

    struct Dispute {
        uint amount;
        uint timeout;
        uint round;
        uint expiresAt;
        uint multiplier;
        mapping(address => bool) disputers;
        address currentDisputer;
    }
    Dispute dispute;

    uint defaultDisputeTimeExtension = 1800; // 30 minutes

    string public eventName;

    /// Data feed hash, used for verification
    string public dataFeedHash;
    string result;

    enum RewardsDistribution {
        Linear, // 0
        Exponential // 1
    }

    struct ConsensusRules {
        uint minTotalVotes;
        uint minConsensusVotes;
        uint minConsensusRatio;
        uint minParticipantRatio;
        uint maxParticipants;
        RewardsDistribution rewardsDistribution;
    }
    ConsensusRules consensusRules;

    /// Event&#39;s states
    /// Events advance in the order defined here. Once the event reaches "Reward"
    /// state, it cannot advance further.
    /// Event states:
    ///   - Waiting         -- Contract has been created, nothing is happening yet
    ///   - Application     -- After applicationStartTime, the event advances here
    ///                        new wallets can be added to the participats list during this state.
    ///   - Running         -- Event is running, no new participants can be added
    ///   - DisputeTimeout  -- Dispute possible
    ///   - Reward          -- Participants can claim their payouts here - final state; can&#39;t be modified.
    ///   - Failed          -- Event failed (no consensus, not enough users, timeout, ...) - final state; can&#39;t be modified
    enum EventStates {
        Waiting,
        Application,
        Running,
        DisputeTimeout,
        Reward,
        Failed
    }
    EventStates eventState = EventStates.Waiting;

    event StateTransition(EventStates newState);
    event JoinEvent(address wallet);
    event ClaimReward(address recipient);
    event Error(string description);
    event EventFailed(string description);
    event ValidationStarted(uint validationRound);
    event ValidationRestart(uint validationRound);
    event DisputeTriggered(address byAddress);
    event ClaimStake(address recipient);

    constructor(
        string _eventName,
        uint _applicationStartTime,
        uint _applicationEndTime,
        uint _eventStartTime,
        uint _eventRunTime, // in seconds
        address _tokenAddress,
        address _registry,
        address[] _eventResolvers,
        uint _leftoversRecoverableAfter, // with timestamp (in seconds)
        uint[6] _consensusRules, // [minTotalVotes, minConsensusVotes, minConsensusRatio, minParticipantRatio, maxParticipants, distribution]
        uint _stakingAmount,
        uint[3] _disputeRules, // [dispute amount, dispute timeout, dispute multiplier]
        string _ipfsEventHash
    )
        public
        payable
    {
        require(_applicationStartTime < _applicationEndTime);
        require(_eventStartTime > _applicationEndTime, "Event can&#39;t start before applications close.");

        applicationStartTime = _applicationStartTime;
        applicationEndTime = _applicationEndTime;
        tokenAddress = _tokenAddress;

        eventName = _eventName;
        eventStartTime = _eventStartTime;
        eventEndTime = _eventStartTime + _eventRunTime;

        eventResolvers = _eventResolvers;

        owner = msg.sender;
        leftoversRecoverableAfter = _leftoversRecoverableAfter;

        rewardsValidationRound = 1;
        rewardsValidation.currentMasterNode = eventResolvers[0];

        stakingAmount = _stakingAmount;

        ipfsEventHash = _ipfsEventHash;

        setConsensusRules(_consensusRules);
        setDisputeData(_disputeRules);

        eventRegistryAddress = _registry;

        EventRegistry(eventRegistryAddress).registerEvent();
    }

    /// A modifier signifiying that a certain method can only be used by the creator
    /// of the contract.
    /// Rollbacks the transaction on failure.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /// A modifier signifiying that rewards can be set only by the designated master node.
    /// Rollbacks the transaction on failure.
    modifier onlyCurrentMaster() {
        require(
            msg.sender == rewardsValidation.currentMasterNode,
            "Not a designated master node."
        );
        _;
    }

    ///	A modifier signifying that a certain method can only be used by a wallet
    ///	marked as a participant.
    ///	Rollbacks the transaction or failure.
    modifier onlyParticipating() {
        require(
            isParticipating(msg.sender),
            "Not participating."
        );
        _;
    }

    /// A modifier signifying that a certain method can only be used when the event
    /// is in a certain state.
    /// @param _state The event&#39;s required state
    /// Example:
    /// 	function claimReward() onlyParticipanting onlyState(EventStates.Reward) {
    /// 		// ... content
    /// 	}
    modifier onlyState(EventStates _state) {
        require(
            _state == eventState,
            "Not possible in current event state."
        );
        _;
    }

    /// A modifier taking care of all the timed state transitions.
    /// Should always be used before all other modifiers, especially `onlyState`,
    /// since it can change state.
    /// Should probably be used in ALL non-constant (transaction) methods of
    /// the contract.
    modifier timedStateTransition() {
        if (eventState == EventStates.Waiting && now >= applicationStartTime) {
            advanceState();
        }

        if (eventState == EventStates.Application && now >= applicationEndTime) {
            if (participantsIndex.length < consensusRules.minTotalVotes) {
                markAsFailed("Not enough users joined for required minimum votes.");
            } else {
                advanceState();
            }
        }

        if (eventState == EventStates.DisputeTimeout && now >= dispute.expiresAt) {
            advanceState();
        }
        _;
    }

    modifier onlyChangeableState() {
        require(
            uint(eventState) < uint(EventStates.Reward),
            "Event state can&#39;t be modified anymore."
        );
        _;
    }

    modifier onlyAfterLefroversCanBeRecovered() {
        require(now >= leftoversRecoverableAfter);
        _;
    }

    modifier canValidateRewards(uint forRound) {
        require(
            isNode(msg.sender) && !isMasterNode(),
            "Not a valid sender address."
        );

        require(
            validationState == ValidationState.Validating,
            "Not validating rewards."
        );

        require(
            forRound == rewardsValidationRound,
            "Validation round mismatch."
        );

        require(
            rewardsValidation.votersRound[msg.sender] < rewardsValidationRound,
            "Already voted for this round."
        );
        _;
    }

    /// Ensure we can receive money at any time.
    /// Not used, but we might want to extend the reward fund while event is running.
    function() public payable {}

    /// Apply for participation in this event.
    /// Available only during the Application state.
    /// A transaction to this function has to be done by the users themselves,
    /// registering their wallet address as a participent.
    /// The transaction does not have to include any funds.
    function joinEvent()
        public
        timedStateTransition
    {
        if (isParticipating(msg.sender)) {
            emit Error("You are already participating.");
            return;
        }

        if (eventState != EventStates.Application) {
            emit Error("You can only join in the Application state.");
            return;
        }

        if (
            stakingAmount > 0 &&
            VerityToken(tokenAddress).allowance(msg.sender, address(this)) < stakingAmount
        ) {
            emit Error("Not enough tokens staked.");
            return;
        }

        if (stakingAmount > 0) {
            VerityToken(tokenAddress).transferFrom(msg.sender, address(this), stakingAmount);
        }
        participants[msg.sender] = true;
        participantsIndex.push(msg.sender);
        EventRegistry(eventRegistryAddress).addEventToUser(msg.sender);
        emit JoinEvent(msg.sender);
    }

    /// Checks whether an address is participating in this event.
    /// @param _user The addres to check for participation
    /// @return {bool} Whether the given address is a participant of this event
    function isParticipating(address _user) public view returns(bool) {
        return participants[_user];
    }

    function getParticipants() public view returns(address[]) {
        return participantsIndex;
    }

    function getEventTimes() public view returns(uint[5]) {
        return [
            applicationStartTime,
            applicationEndTime,
            eventStartTime,
            eventEndTime,
            leftoversRecoverableAfter
        ];
    }

    /// Assign the actual rewards.
    /// Receives a list of addresses and a list rewards. Mapping between the two
    /// is done by the addresses&#39; and reward&#39;s numerical index in the list, so
    /// order is important.
    /// @param _addresses A list of addresses
    /// @param _etherRewards A list of ether rewards, must be the exact same length as addresses
    /// @param _tokenRewards A list of token rewards, must be the exact same length as addresses
    function setRewards(
        address[] _addresses,
        uint[] _etherRewards,
        uint[] _tokenRewards
    )
        public
        onlyCurrentMaster
        timedStateTransition
        onlyState(EventStates.Running)
    {
        require(
            _addresses.length == _etherRewards.length &&
            _addresses.length == _tokenRewards.length
        );

        require(
            validationState == ValidationState.WaitingForRewards,
            "Not possible in this validation state."
        );

        for (uint i = 0; i < _addresses.length; ++i) {
            rewards[_addresses[i]][uint(RewardType.Ether)] = _etherRewards[i];
            rewards[_addresses[i]][uint(RewardType.Token)] = _tokenRewards[i];
            rewardsIndex.push(_addresses[i]);
        }
    }

    /// Triggered by the master node once rewards are set and ready to validate
    function markRewardsSet(string rewardsHash)
        public
        onlyCurrentMaster
        timedStateTransition
        onlyState(EventStates.Running)
    {
        require(
            validationState == ValidationState.WaitingForRewards,
            "Not possible in this validation state."
        );

        rewardsValidation.rewardsHash = rewardsHash;
        rewardsValidation.approvalCount = 1;
        validationState = ValidationState.Validating;
        emit ValidationStarted(rewardsValidationRound);
    }

    /// Called by event resolver nodes if they agree with rewards
    function approveRewards(uint validationRound)
        public
        onlyState(EventStates.Running)
        canValidateRewards(validationRound)
    {
        ++rewardsValidation.approvalCount;
        rewardsValidation.votersRound[msg.sender] = rewardsValidationRound;
        checkApprovalRatio();
    }

    /// Called by event resolvers if they don&#39;t agree with rewards
    function rejectRewards(uint validationRound, string altHash)
        public
        onlyState(EventStates.Running)
        canValidateRewards(validationRound)
    {
        ++rewardsValidation.rejectionCount;
        rewardsValidation.votersRound[msg.sender] = rewardsValidationRound;

        if (!rewardsValidation.rejectedHashes[altHash]) {
            rewardsValidation.altHashes.push(altHash);
            rewardsValidation.altHashVotes[altHash].push(msg.sender);
        }

        checkRejectionRatio();
    }

    /// Trigger a dispute.
    function triggerDispute()
        public
        timedStateTransition
        onlyParticipating
        onlyState(EventStates.DisputeTimeout)
    {
        require(
            VerityToken(tokenAddress).allowance(msg.sender, address(this)) >=
            dispute.amount * dispute.multiplier**dispute.round,
            "Not enough tokens staked for dispute."
        );

        require(
            dispute.disputers[msg.sender] == false,
            "Already triggered a dispute."
        );

        /// Increase dispute amount for next dispute and store disputer
        dispute.amount = dispute.amount * dispute.multiplier**dispute.round;
        ++dispute.round;
        dispute.disputers[msg.sender] = true;
        dispute.currentDisputer = msg.sender;

        /// Transfer staked amount
        VerityToken(tokenAddress).transferFrom(msg.sender, address(this), dispute.amount);

        /// Restart event
        deleteValidationData();
        deleteRewards();
        eventState = EventStates.Application;
        applicationEndTime = eventStartTime = now + defaultDisputeTimeExtension;
        eventEndTime = eventStartTime + defaultDisputeTimeExtension;

        /// Make consensus rules stricter
        /// Increases by ~10% of consensus diff
        consensusRules.minConsensusRatio += (100 - consensusRules.minConsensusRatio) * 100 / 1000;
        /// Increase total votes required my ~10% and consensus votes by consensus ratio
        uint votesIncrease = consensusRules.minTotalVotes * 100 / 1000;
        consensusRules.minTotalVotes += votesIncrease;
        consensusRules.minConsensusVotes += votesIncrease * consensusRules.minConsensusRatio / 100;

        emit DisputeTriggered(msg.sender);
    }

    /// Checks current approvals for threshold
    function checkApprovalRatio() private {
        if (approvalRatio() >= consensusRules.minConsensusRatio) {
            validationState = ValidationState.Finished;
            dispute.expiresAt = now + dispute.timeout;
            advanceState();
        }
    }

    /// Checks current rejections for threshold
    function checkRejectionRatio() private {
        if (rejectionRatio() >= (100 - consensusRules.minConsensusRatio)) {
            rejectCurrentValidation();
        }
    }

    /// Handle the rejection of current rewards
    function rejectCurrentValidation() private {
        rewardsValidation.rejectedHashes[rewardsValidation.rewardsHash] = true;

        // If approved votes are over the threshold all other hashes will also fail
        if (
            rewardsValidation.approvalCount + rewardsValidationRound - 1 >
            rewardsValidation.rejectionCount - rewardsValidation.altHashes.length + 1
        ) {
            markAsFailed("Consensus can&#39;t be reached");
        } else {
            restartValidation();
        }
    }

    function restartValidation() private {
        ++rewardsValidationRound;
        rewardsValidation.currentMasterNode = rewardsValidation.altHashVotes[rewardsValidation.altHashes[0]][0];

        deleteValidationData();
        deleteRewards();

        emit ValidationRestart(rewardsValidationRound);
    }

    /// Delete rewards.
    function deleteRewards() private {
        for (uint j = 0; j < rewardsIndex.length; ++j) {
            rewards[rewardsIndex[j]][uint(RewardType.Ether)] = 0;
            rewards[rewardsIndex[j]][uint(RewardType.Token)] = 0;
        }
        delete rewardsIndex;
    }

    /// Delete validation data
    function deleteValidationData() private {
        rewardsValidation.approvalCount = 0;
        rewardsValidation.rejectionCount = 0;
        for (uint i = 0; i < rewardsValidation.altHashes.length; ++i) {
            delete rewardsValidation.altHashVotes[rewardsValidation.altHashes[i]];
        }
        delete rewardsValidation.altHashes;
        validationState = ValidationState.WaitingForRewards;
    }

    /// Ratio of nodes that approved of current hash
    function approvalRatio() private view returns(uint) {
        return rewardsValidation.approvalCount * 100 / eventResolvers.length;
    }

    /// Ratio of nodes that rejected the current hash
    function rejectionRatio() private view returns(uint) {
        return rewardsValidation.rejectionCount * 100 / eventResolvers.length;
    }

    /// Returns the whole array of event resolvers.
    function getEventResolvers() public view returns(address[]) {
        return eventResolvers;
    }

    /// Checks if the address is current master node.
    function isMasterNode() public view returns(bool) {
        return rewardsValidation.currentMasterNode == msg.sender;
    }

    function isNode(address node) private view returns(bool) {
        for(uint i = 0; i < eventResolvers.length; ++i) {
            if(eventResolvers[i] == node) {
                return true;
            }
        }
        return false;
    }

    /// Returns the calling user&#39;s assigned rewards. Can be 0.
    /// Only available to participating users in the Reward state, since rewards
    /// are not assigned before that.
    function getReward()
        public
        view
        returns(uint[2])
    {
        return [
            rewards[msg.sender][uint(RewardType.Ether)],
            rewards[msg.sender][uint(RewardType.Token)]
        ];
    }

    /// Returns all the addresses that have rewards set.
    function getRewardsIndex() public view returns(address[]) {
        return rewardsIndex;
    }

    /// Returns rewards for specified addresses.
    /// [[ethRewards, tokenRewards], [ethRewards, tokenRewards], ...]
    function getRewards(address[] _addresses)
        public
        view
        returns(uint[], uint[])
    {
        uint[] memory ethRewards = new uint[](_addresses.length);
        uint[] memory tokenRewards = new uint[](_addresses.length);

        for(uint i = 0; i < _addresses.length; ++i) {
            ethRewards[i] = rewards[_addresses[i]][uint(RewardType.Ether)];
            tokenRewards[i] = rewards[_addresses[i]][uint(RewardType.Token)];
        }

        return (ethRewards, tokenRewards);
    }

    /// Claim a reward.
    /// Needs to be called by the users themselves.
    /// Only available in the Reward state, after rewards have been received from
    /// the validation nodes.
    function claimReward()
        public
        onlyParticipating
        timedStateTransition
        onlyState(EventStates.Reward)
    {
        uint etherReward = rewards[msg.sender][uint(RewardType.Ether)];
        uint tokenReward = rewards[msg.sender][uint(RewardType.Token)];

        if (etherReward == 0 && tokenReward == 0) {
            emit Error("You do not have any rewards to claim.");
            return;
        }

        if (
            address(this).balance < rewards[msg.sender][uint(RewardType.Ether)] ||
            VerityToken(tokenAddress).balanceOf(address(this)) < rewards[msg.sender][uint(RewardType.Token)]
        ) {
            emit Error("Critical error: not enough balance to pay out reward. Contact Verity.");
            return;
        }

        rewards[msg.sender][uint(RewardType.Ether)] = 0;
        rewards[msg.sender][uint(RewardType.Token)] = 0;

        msg.sender.transfer(etherReward);
        if (tokenReward > 0) {
            VerityToken(tokenAddress).transfer(msg.sender, tokenReward);
        }

        emit ClaimReward(msg.sender);
    }

    function claimFailed()
        public
        onlyParticipating
        timedStateTransition
        onlyState(EventStates.Failed)
    {
        require(
            stakingAmount > 0,
            "No stake to claim"
        );

        VerityToken(tokenAddress).transfer(msg.sender, stakingAmount);
        participants[msg.sender] = false;
        emit ClaimStake(msg.sender);
    }

    function setDataFeedHash(string _hash) public onlyOwner {
        dataFeedHash = _hash;
    }

    function setResult(string _result)
        public
        onlyCurrentMaster
        timedStateTransition
        onlyState(EventStates.Reward)
    {
        result = _result;
    }

    function getResult() public view returns(string) {
        return result;
    }

    function getState() public view returns(uint) {
        return uint(eventState);
    }

    function getBalance() public view returns(uint[2]) {
        return [
            address(this).balance,
            VerityToken(tokenAddress).balanceOf(address(this))
        ];
    }

    /// Returns an array of consensus rules.
    /// [minTotalVotes, minConsensusVotes, minConsensusRatio, minParticipantRatio, maxParticipants]
    function getConsensusRules() public view returns(uint[6]) {
        return [
            consensusRules.minTotalVotes,
            consensusRules.minConsensusVotes,
            consensusRules.minConsensusRatio,
            consensusRules.minParticipantRatio,
            consensusRules.maxParticipants,
            uint(consensusRules.rewardsDistribution)
        ];
    }

    /// Returns an array of dispute rules.
    /// [dispute amount, dispute timeout, dispute round]
    function getDisputeData() public view returns(uint[4], address) {
        return ([
            dispute.amount,
            dispute.timeout,
            dispute.multiplier,
            dispute.round
        ], dispute.currentDisputer);
    }

    function recoverLeftovers()
        public
        onlyOwner
        onlyAfterLefroversCanBeRecovered
    {
        owner.transfer(address(this).balance);
        uint tokenBalance = VerityToken(tokenAddress).balanceOf(address(this));
        VerityToken(tokenAddress).transfer(owner, tokenBalance);
    }

    /// Advances the event&#39;s state to the next one. Only for internal use.
    function advanceState() private onlyChangeableState {
        eventState = EventStates(uint(eventState) + 1);
        emit StateTransition(eventState);
    }

    /// Sets consensus rules. For internal use only.
    function setConsensusRules(uint[6] rules) private {
        consensusRules.minTotalVotes = rules[0];
        consensusRules.minConsensusVotes = rules[1];
        consensusRules.minConsensusRatio = rules[2];
        consensusRules.minParticipantRatio = rules[3];
        consensusRules.maxParticipants = rules[4];
        consensusRules.rewardsDistribution = RewardsDistribution(rules[5]);
    }

    function markAsFailed(string description) private onlyChangeableState {
        eventState = EventStates.Failed;
        emit EventFailed(description);
    }

    function setDisputeData(uint[3] rules) private {
        uint _multiplier = rules[2];
        if (_multiplier <= 1) {
            _multiplier = 1;
        }

        dispute.amount = rules[0];
        dispute.timeout = rules[1];
        dispute.multiplier = _multiplier;
        dispute.round = 0;
    }
}