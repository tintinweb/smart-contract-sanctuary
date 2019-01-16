pragma solidity ^0.4.24;
  
contract StateMachine {

    struct State {
        bytes32 nextStateId;
        mapping(bytes4 => bool) allowedFunctions;
        function() internal[] transitionCallbacks;
        function(bytes32) internal returns(bool)[] startConditions;
    }

    mapping(bytes32 => State) states;

    // The current state id
    bytes32 private currentStateId;

    event Transition(bytes32 stateId, uint256 blockNumber);

    /* This modifier performs the conditional transitions and checks that the function
     * to be executed is allowed in the current State
     */
    modifier checkAllowed {
        conditionalTransitions();
        require(states[currentStateId].allowedFunctions[msg.sig]);
        _;
    }

    ///@dev transitions the state machine into the state it should currently be in
    ///@dev by taking into account the current conditions and how many further transitions can occur
    function conditionalTransitions() public {
        bool checkNextState;
        do {
            checkNextState = false;

            bytes32 next = states[currentStateId].nextStateId;
            // If one of the next state&#39;s conditions is met, go to this state and continue

            for (uint256 i = 0; i < states[next].startConditions.length; i++) {
                if (states[next].startConditions[i](next)) {
                    goToNextState();
                    checkNextState = true;
                    break;
                }
            }
        } while (checkNextState);
    }

    function getCurrentStateId() view public returns(bytes32) {
        return currentStateId;
    }

    /// @dev Setup the state machine with the given states.
    /// @param _stateIds Array of state ids.
    function setStates(bytes32[] _stateIds) internal {
        require(_stateIds.length > 0);
        require(currentStateId == 0);

        require(_stateIds[0] != 0);

        currentStateId = _stateIds[0];

        for (uint256 i = 1; i < _stateIds.length; i++) {
            require(_stateIds[i] != 0);

            states[_stateIds[i - 1]].nextStateId = _stateIds[i];

            // Check that the state appears only once in the array
            require(states[_stateIds[i]].nextStateId == 0);
        }
    }

    /// @dev Allow a function in the given state.
    /// @param _stateId The id of the state
    /// @param _functionSelector A function selector (bytes4[keccak256(functionSignature)])
    function allowFunction(bytes32 _stateId, bytes4 _functionSelector)
        internal
    {
        states[_stateId].allowedFunctions[_functionSelector] = true;
    }

    /// @dev Goes to the next state if possible (if the next state is valid)
    function goToNextState() internal {
        bytes32 next = states[currentStateId].nextStateId;
        require(next != 0);

        currentStateId = next;
        for (uint256 i = 0; i < states[next].transitionCallbacks.length; i++) {
            states[next].transitionCallbacks[i]();
        }

        emit Transition(next, block.number);
    }

    ///@dev Add a function returning a boolean as a start condition for a state.
    /// If any condition returns true, the StateMachine will transition to the next state.
    /// If s.startConditions is empty, the StateMachine will need to enter state s through invoking
    /// the goToNextState() function.
    /// A start condition should never throw. (Otherwise, the StateMachine may fail to enter into the
    /// correct state, and succeeding start conditions may return true.)
    /// A start condition should be gas-inexpensive since every one of them is invoked in the same call to
    /// transition the state.
    ///@param _stateId The ID of the state to add the condition for
    ///@param _condition Start condition function - returns true if a start condition (for a given state ID) is met
    function addStartCondition(
        bytes32 _stateId,
        function(bytes32) internal returns(bool) _condition
    )
        internal
    {
        states[_stateId].startConditions.push(_condition);
    }

    ///@dev Add a callback function for a state. All callbacks are invoked immediately after entering the state.
    /// Callback functions should never throw. (Otherwise, the StateMachine may fail to enter a state.)
    /// Callback functions should also be gas-inexpensive as all callbacks are invoked in the same call to enter the state.
    ///@param _stateId The ID of the state to add a callback function for
    ///@param _callback The callback function to add
    function addCallback(bytes32 _stateId, function() internal _callback)
        internal
    {
        states[_stateId].transitionCallbacks.push(_callback);
    }
}
  


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}
 interface IToken {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function mint(address to, uint256 value) external returns (bool);
}
contract Pool is StateMachine, Pausable {
    bytes32 constant FUNDING = "funding";
    bytes32 constant INVESTING = "investing";
    bytes32 constant WAITING = "waiting";
    bytes32 constant DISTRIBUTION = "distribution";
    bytes32[] states = [FUNDING, INVESTING, WAITING, DISTRIBUTION];

    address public token;
    address public tokensale;
    uint256 public fundingStart;
    uint256 public fundingEnd;
    uint256 public minFunding;
    uint256 public maxFunding;
    uint256 public minTokens;

    mapping (address => uint256) public balances;

    uint256 public totalFundsCollected = 0;

    address[] public investors;

    uint256 totalTokensReceived;

    function getInvestorsCount()
        public view returns (uint256)
    {
        return investors.length;
    }

    event Deposit(address who, uint256 amount);
    event Withdraw(address who, uint256 amount);
    event Refund(address who, uint256 amount);

    constructor(
        address _token,
        address _tokensale,
        uint256 _fundingStart,
        uint256 _fundingEnd,
        uint256 _minFunding,
        uint256 _maxFunding,
        uint256 _minTokens
    )
        public
    {
        token = _token;
        tokensale = _tokensale;
        fundingStart = _fundingStart;
        fundingEnd = _fundingEnd;
        minFunding = _minFunding;
        maxFunding = _maxFunding;
        minTokens = _minTokens;

        setupStates();
    }

    function() payable {
        depositFunds();
    }

    function depositFunds()
        public payable checkAllowed whenNotPaused
    {
        if (balances[msg.sender] == 0) {
            investors.push(msg.sender);
        }

        balances[msg.sender] += msg.value;
        totalFundsCollected += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdrawTokens()
        public checkAllowed whenNotPaused
    {
        uint256 fundsBalance = balances[msg.sender];
        balances[msg.sender] = 0;

        uint256 tokensBalance = ((fundsBalance*10**18 / totalFundsCollected) * totalTokensReceived) / 10**18;

        IToken(token).transfer(msg.sender, tokensBalance);

        emit Withdraw(msg.sender, tokensBalance);
    }

    function refundFunds()
        public checkAllowed whenPaused
    {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;

        msg.sender.transfer(balance);

        emit Refund(msg.sender, balance);
    }

    function rememberTotalTokensReceived()
        internal
    {
        totalTokensReceived = IToken(token).balanceOf(address(this));
    }

    function softcapReachedAfterEnd(bytes32)
        internal returns (bool)
    {
        return totalFundsCollected >= minFunding && now >= fundingEnd;
    }

    function hardcapReachedBeforeEnd(bytes32)
        internal returns (bool)
    {
        return totalFundsCollected >= maxFunding && now <= fundingEnd;
    }

    function fundsTransferredToTokensale(bytes32)
        internal returns (bool)
    {
        return totalFundsCollected > 0 && address(this).balance == 0;
    }

    function tokensReceived(bytes32)
        internal returns (bool)
    {
        return IToken(token).balanceOf(address(this)) >= minTokens;
    }

    function transferFundsToTokensale()
        internal
    {
        require(tokensale.call.value(totalFundsCollected)());
    }

    function setupStates() internal {
        setStates(states);

        allowFunction(FUNDING, 0);
        allowFunction(FUNDING, this.depositFunds.selector);
        allowFunction(DISTRIBUTION, this.withdrawTokens.selector);

        addCallback(INVESTING, transferFundsToTokensale);
        addCallback(DISTRIBUTION, rememberTotalTokensReceived);

        addStartCondition(INVESTING, softcapReachedAfterEnd);
        addStartCondition(INVESTING, hardcapReachedBeforeEnd);

        addStartCondition(WAITING, fundsTransferredToTokensale);

        addStartCondition(DISTRIBUTION, tokensReceived);
    }
}