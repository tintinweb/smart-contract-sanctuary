pragma solidity ^0.4.24;

contract VerityToken {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract VerityEvent
{
  /// Contract&#39;s owner, used for permission management
  address public owner;
  /// Token contract address, used for tokend distribution
  address public tokenAddress;

  /// owner can recover tokens and ether after this time
  uint public leftoversRecoverableAfter;

  /**
  * A list of all the participating wallet addresses, implemented as a mapping
  * to provide constant lookup times.
  */
  mapping(address => bool) participants;
  /// A mapping of addresses to their assigned rewards
  mapping(address => mapping(string => uint)) rewards;

  /// Event application start time, users cannot apply to participate before it
  uint public applicationStartTime;
  /// Event application end time, users cannot apply after this time
  uint public applicationEndTime;

  /// Data feed hash, used for verification
  string public dataFeedHash;
  
  /// Event result
  string public eventResult;

  /**
  * Event&#39;s states
  * Events advance in the order defined here. Once the event reaches "Reward"
  * state, it cannot advance further.
  * Event states:
  *	 - Waiting     -- Contract has been created, nothing is happening yet
  *	 - Application -- After applicationStartTime, the event advances here
  *	   new wallets can be added to the participats list during this state.
  *	 - Running     -- Event is running, no new participants can be added
  *	 - Reward      -- Participants can claim their payouts here
  */
  enum EventStates
  {
    Waiting,
    Application,
    Running,
    Reward
  }

  /// Event&#39;s state, as described above. Defaults to Waiting.
  EventStates eventState = EventStates.Waiting;

  event StateTransition(EventStates newState);
  event JoinEvent(address wallet);
  event ClaimReward(address recipient);
  event Error(string description);

  constructor(
    uint _applicationStartTime,
    uint _applicationEndTime,
    address _tokenAddress,
    uint _leftoversRecoverableAfter
  )
    public
    payable
  {
    require(_applicationStartTime < _applicationEndTime);

    applicationStartTime = _applicationStartTime;
    applicationEndTime = _applicationEndTime;
    tokenAddress = _tokenAddress;

    owner = msg.sender;
    leftoversRecoverableAfter = _leftoversRecoverableAfter;
  }

  /**
  * A modifier signifiying that a certain method can only be used by the creator
  * of the contract.
  * Rollbacks the transaction on failure.
  */
  modifier onlyOwner()
  {
    require(msg.sender == owner);
    _;
  }

  /**
  * 	A modifier signifying that a certain method can only be used by a wallet
  * 	marked as a participant.
  * 	Rollbacks the transaction or failure.
  */
  modifier onlyParticipating()
  {
    require(isParticipating(msg.sender));
    _;
  }

  /**
  * A modifier signifying that a certain method can only be used when the event
  * is in a certain state.
  *
  * @param _state The event&#39;s required state
  *
  * Example:
  * 	function claimReward() onlyParticipanting onlyState(EventStates.Reward) {
  * 		// ... content
  * 	}
  */
  modifier onlyState(EventStates _state)
  {
    require(_state == eventState);
    _;
  }

  /**
  * A modifier taking care of all the timed state transitions.
  * Should always be used before all other modifiers, especially `onlyState`,
  * since it can change state.
  * Should probably be used in ALL non-constant (transaction) methods of
  * the contract.
  */
  modifier timedStateTransition()
  {
    if (eventState == EventStates.Waiting && now >= applicationStartTime) {
      advanceState();
    }

    if (eventState == EventStates.Application && now >= applicationEndTime) {
      advanceState();
    }

    _;
  }

  modifier onlyAfterLefroversCanBeRecovered()
  {
    require(now >= leftoversRecoverableAfter);
    _;
  }

  /**
  * Ensure we can receive money at any time.
  *
  * Not used, but we might want to extend the reward fund while event is running.
  */
  function() public payable {}

  /**
  * Apply for participation in this event.
  *
  * Available only during the Application state.
  * A transaction to this function has to be done by the users themselves,
  * registering their wallet address as a participent.
  * The transaction does not have to include any funds.
  */
  function joinEvent()
    public
    timedStateTransition
  {
    if (isParticipating(msg.sender))
    {
      emit Error("You are already participating.");
      return;
    }

    if (eventState != EventStates.Application)
    {
      emit Error("You can only join in the Application state.");
      return;
    }

    participants[msg.sender] = true;
    emit JoinEvent(msg.sender);
  }

  /**
  * Checks whether an address is participating in this event.
  *
  * @param _user The addres to check for participation
  * @return {bool} Whether the given address is a participant of this event
  */
  function isParticipating(address _user) public constant returns(bool)
  {
    return participants[_user];
  }

  /**
  * Assign the actual rewards.
  *
  * Receives a list of addresses and a list rewards. Mapping between the two
  * is done by the addresses&#39; and reward&#39;s numerical index in the list, so
  * order is important.
  *
  * @param _addresses A list of addresses
  * @param _etherRewards A list of ether rewards, must be the exact same length as addresses
  * @param _tokenRewards A list of token rewards, must be the exact same length as addresses
  */
  function setRewards(
    address[] _addresses,
    uint[] _etherRewards,
    uint[] _tokenRewards
  )
    public
    onlyOwner
    timedStateTransition
    onlyState(EventStates.Running)
  {
    require(
      _addresses.length == _etherRewards.length &&
        _addresses.length == _tokenRewards.length
    );

    for (uint i = 0; i < _addresses.length; ++i) {
      rewards[_addresses[i]]["ether"] = _etherRewards[i];
      rewards[_addresses[i]]["token"] = _tokenRewards[i];
    }
  }

  function markRewardsSet()
    public
    onlyOwner
    timedStateTransition
    onlyState(EventStates.Running)
  {
    advanceState();
  }

  /**
  * Returns the calling user&#39;s assigned rewards. Can be 0.
  *
  * Only available to participating users in the Reward state, since rewards
  * are not assigned before that.
  */
  function getReward()
    public
    constant
    returns(uint[2])
  {
    return [rewards[msg.sender]["ether"], rewards[msg.sender]["token"]];
  }

  /**
  * Claim a reward.
  * Needs to be called by the users themselves.
  *
  * Only available in the Reward state, after rewards have been received from
  * the validation nodes.
  */
  function claimReward()
    public
    onlyParticipating
    onlyState(EventStates.Reward)
  {
    if (rewards[msg.sender]["ether"] == 0 && rewards[msg.sender]["token"] == 0)
    {
      emit Error("You do not have any rewards to claim.");
      return;
    }

    if (address(this).balance < rewards[msg.sender]["ether"] ||
          VerityToken(tokenAddress).balanceOf(address(this)) < rewards[msg.sender]["token"])
    {
      emit Error("Critical error: not enough balance to pay out reward. Contact Eventum.");
      return;
    }

    uint etherReward = rewards[msg.sender]["ether"];
    uint tokenReward = rewards[msg.sender]["token"];
    rewards[msg.sender]["ether"] = 0;
    rewards[msg.sender]["token"] = 0;

    msg.sender.transfer(etherReward);
    VerityToken(tokenAddress).transfer(msg.sender, tokenReward);

    emit ClaimReward(msg.sender);
  }

  /**
  * Advances the event&#39;s state to the next one. Only for internal use.
  */
  function advanceState() private
  {
    require(eventState != EventStates.Reward);

    eventState = EventStates(uint(eventState) + 1);
    emit StateTransition(eventState);
  }

  function setDataFeedHash(string _hash) public onlyOwner
  {
    dataFeedHash = _hash;
  }

  function getState() public constant returns(uint)
  {
    return uint(eventState);
  }

  function getBalance() public constant returns(uint[2])
  {
    return [
      address(this).balance,
      VerityToken(tokenAddress).balanceOf(address(this))
    ];
  }
  
  function setEventResult(string _result)
    public
    onlyOwner
    onlyState(EventStates.Reward)
  {
      eventResult = _result;
  }
  
  function getResult() public constant returns(string)
  {
    return eventResult;
  }

  function recoverLeftovers() public onlyOwner onlyAfterLefroversCanBeRecovered
  {
    owner.transfer(address(this).balance);
    uint tokenBalance = VerityToken(tokenAddress).balanceOf(address(this));
    VerityToken(tokenAddress).transfer(owner, tokenBalance);
  }
}