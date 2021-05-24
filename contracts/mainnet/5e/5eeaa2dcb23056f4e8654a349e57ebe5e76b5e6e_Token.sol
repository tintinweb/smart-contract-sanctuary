/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2018-04-20
*/

pragma solidity 0.4.19;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: @tokenfoundry/sale-contracts/contracts/DisbursementHandler.sol

/// @title Disbursement handler - Manages time locked disbursements of ERC20 tokens
contract DisbursementHandler is Ownable {
    using SafeMath for uint256;

    struct Disbursement {
        // Tokens cannot be withdrawn before this timestamp
        uint256 timestamp;

        // Amount of tokens to be disbursed
        uint256 tokens;
    }

    event LogSetup(address indexed vestor, uint256 timestamp, uint256 tokens);
    event LogWithdraw(address indexed to, uint256 value);

    ERC20 public token;
    uint256 public totalAmount;
    mapping(address => Disbursement[]) public disbursements;
    mapping(address => uint256) public withdrawnTokens;

    function DisbursementHandler(address _token) public {
        token = ERC20(_token);
    }

    /// @dev Called by the sale contract to create a disbursement.
    /// @param vestor The address of the beneficiary.
    /// @param tokens Amount of tokens to be locked.
    /// @param timestamp Funds will be locked until this timestamp.
    function setupDisbursement(
        address vestor,
        uint256 tokens,
        uint256 timestamp
    )
        external
        onlyOwner
    {
        require(block.timestamp < timestamp);
        disbursements[vestor].push(Disbursement(timestamp, tokens));
        totalAmount = totalAmount.add(tokens);
        LogSetup(vestor, timestamp, tokens);
    }

    /// @dev Transfers tokens to the withdrawer
    function withdraw()
        external
    {
        uint256 withdrawAmount = calcMaxWithdraw(msg.sender);
        require(withdrawAmount != 0);
        withdrawnTokens[msg.sender] = withdrawnTokens[msg.sender].add(withdrawAmount);
        require(token.transfer(msg.sender, withdrawAmount));
        LogWithdraw(msg.sender, withdrawAmount);
    }

    /// @dev Calculates the maximum amount of vested tokens
    /// @return Number of vested tokens that can be withdrawn
    function calcMaxWithdraw(address beneficiary)
        public
        view
        returns (uint256)
    {
        uint256 maxTokens = 0;

        // Go over all the disbursements and calculate how many tokens can be withdrawn
        Disbursement[] storage temp = disbursements[beneficiary];
        uint256 tempLength = temp.length;
        for (uint256 i = 0; i < tempLength; i++) {
            if (block.timestamp > temp[i].timestamp) {
                maxTokens = maxTokens.add(temp[i].tokens);
            }
        }

        // Return the computed amount minus the tokens already withdrawn
        return maxTokens.sub(withdrawnTokens[beneficiary]);
    }
}

// File: zeppelin-solidity/contracts/math/Math.sol

/**
 * @title Math
 * @dev Assorted math operations
 */
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

// File: @tokenfoundry/sale-contracts/contracts/Vault.sol

// Adapted from Open Zeppelin's RefundVault

/**
 * @title Vault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract Vault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Success, Refunding, Closed }

    uint256 public constant DISBURSEMENT_DURATION = 4 weeks;

    mapping (address => uint256) public deposited;
    uint256 public disbursementAmount; // The amount to be disbursed to the wallet every month
    address public trustedWallet; // Wallet from the project team

    uint256 public initialAmount; // The eth amount the team will get initially if the sale is successful

    uint256 public lastDisbursement; // Timestamp of the last disbursement made

    uint256 public totalDeposited; // Total amount that was deposited
    uint256 public refundable; // Amount that can be refunded

    uint256 public closingDuration;
    uint256 public closingDeadline; // Vault can't be closed before this deadline

    State public state;

    event LogClosed();
    event LogRefundsEnabled();
    event LogRefunded(address indexed contributor, uint256 amount);

    modifier atState(State _state) {
        require(state == _state);
        _;
    }

    function Vault(
        address wallet,
        uint256 _initialAmount,
        uint256 _disbursementAmount,
        uint256 _closingDuration
    ) 
        public 
    {
        require(wallet != address(0));
        require(_disbursementAmount != 0);
        require(_closingDuration != 0);
        trustedWallet = wallet;
        initialAmount = _initialAmount;
        disbursementAmount = _disbursementAmount;
        closingDuration = _closingDuration;
        state = State.Active;
    }

    /// @dev Called by the sale contract to deposit ether for a contributor.
    function deposit(address contributor) onlyOwner external payable {
        require(state == State.Active || state == State.Success);
        totalDeposited = totalDeposited.add(msg.value);
        refundable = refundable.add(msg.value);
        deposited[contributor] = deposited[contributor].add(msg.value);
    }

    /// @dev Sends initial funds to the wallet.
    function saleSuccessful() onlyOwner external atState(State.Active){
        state = State.Success;
        refundable = refundable.sub(initialAmount);
        if (initialAmount != 0) {
          trustedWallet.transfer(initialAmount);
        }
    }

    /// @dev Called by the owner if the project didn't deliver the testnet contracts or if we need to stop disbursements for any reasone.
    function enableRefunds() onlyOwner external {
        state = State.Refunding;
        LogRefundsEnabled();
    }

    /// @dev Refunds ether to the contributors if in the Refunding state.
    function refund(address contributor) external atState(State.Refunding) {
        uint256 refundAmount = deposited[contributor].mul(refundable).div(totalDeposited);
        deposited[contributor] = 0;
        contributor.transfer(refundAmount);
        LogRefunded(contributor, refundAmount);
    }

    /// @dev Sets the closingDeadline variable
    function beginClosingPeriod() external onlyOwner atState(State.Success) {
        require(closingDeadline == 0);
        closingDeadline = now.add(closingDuration);
    }

    /// @dev Called by anyone if the sale was successful and the project delivered.
    function close() external atState(State.Success) {
        require(closingDeadline != 0 && closingDeadline <= now);
        state = State.Closed;
        LogClosed();
    }

    /// @dev Sends the disbursement amount to the wallet after the disbursement period has passed. Can be called by anyone.
    function sendFundsToWallet() external atState(State.Closed) {
        require(lastDisbursement.add(DISBURSEMENT_DURATION) <= now);

        lastDisbursement = now;
        uint256 amountToSend = Math.min256(address(this).balance, disbursementAmount);
        refundable = amountToSend > refundable ? 0 : refundable.sub(amountToSend);
        trustedWallet.transfer(amountToSend);
    }
}

// File: @tokenfoundry/sale-contracts/contracts/Whitelistable.sol

/**
 * @title Whitelistable
 * @dev This contract is used to implement a signature based whitelisting mechanism
 */
contract Whitelistable is Ownable {
    bytes constant PREFIX = "\x19Ethereum Signed Message:\n32";

    address public whitelistAdmin;

    // addresses map to false by default
    mapping(address => bool) public blacklist;

    event LogAdminUpdated(address indexed newAdmin);

    modifier validAdmin(address _admin) {
        require(_admin != 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == whitelistAdmin);
        _;
    }

    /// @dev Constructor for Whitelistable contract
    /// @param _admin the address of the admin that will generate the signatures
    function Whitelistable(address _admin) public validAdmin(_admin) {
        whitelistAdmin = _admin;        
    }

    /// @dev Updates whitelistAdmin address 
    /// @dev Can only be called by the current owner
    /// @param _admin the new admin address
    function changeAdmin(address _admin)
        external
        onlyOwner
        validAdmin(_admin)
    {
        LogAdminUpdated(_admin);
        whitelistAdmin = _admin;
    }

    // @dev blacklists the given address to ban them from contributing
    // @param _contributor Address of the contributor to blacklist 
    function addToBlacklist(address _contributor)
        external
        onlyAdmin
    {
        blacklist[_contributor] = true;
    }

    // @dev removes a previously blacklisted contributor from the blacklist
    // @param _contributor Address of the contributor remove 
    function removeFromBlacklist(address _contributor)
        external
        onlyAdmin
    {
        blacklist[_contributor] = false;
    }

    /// @dev Checks if contributor is whitelisted (main Whitelistable function)
    /// @param contributor Address of who was whitelisted
    /// @param contributionLimit Limit for the user contribution
    /// @param currentSaleCap Cap of contributions to the sale at the current point in time
    /// @param v Recovery id
    /// @param r Component of the ECDSA signature
    /// @param s Component of the ECDSA signature
    /// @return Is the signature correct?
    function checkWhitelisted(
        address contributor,
        uint256 contributionLimit,
        uint256 currentSaleCap,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns(bool) {
        bytes32 prefixed = keccak256(PREFIX, keccak256(contributor, contributionLimit, currentSaleCap));
        return !(blacklist[contributor]) && (whitelistAdmin == ecrecover(prefixed, v, r, s));
    }
}

// File: @tokenfoundry/state-machine/contracts/StateMachine.sol

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

    event LogTransition(bytes32 stateId, uint256 blockNumber);

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

        bytes32 next = states[currentStateId].nextStateId;
        bool stateChanged;

        while (next != 0) {
            // If one of the next state's conditions is met, go to this state and continue
            stateChanged = false;
            for (uint256 i = 0; i < states[next].startConditions.length; i++) {
                if (states[next].startConditions[i](next)) {
                    goToNextState();
                    next = states[next].nextStateId;
                    stateChanged = true;
                    break;
                }
            }
            // If none of the next state's conditions are met, then we are in the right current state
            if (!stateChanged) break;
        }
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
    function allowFunction(bytes32 _stateId, bytes4 _functionSelector) internal {
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

        LogTransition(next, block.number);
    }

    ///@dev add a function returning a boolean as a start condition for a state
    ///@param _stateId The ID of the state to add the condition for
    ///@param _condition Start condition function - returns true if a start condition (for a given state ID) is met
    function addStartCondition(bytes32 _stateId, function(bytes32) internal returns(bool) _condition) internal {
        states[_stateId].startConditions.push(_condition);
    }

    ///@dev add a callback function for a state
    ///@param _stateId The ID of the state to add a callback function for
    ///@param _callback The callback function to add
    function addCallback(bytes32 _stateId, function() internal _callback) internal {
        states[_stateId].transitionCallbacks.push(_callback);
    }

}

// File: @tokenfoundry/state-machine/contracts/TimedStateMachine.sol

/// @title A contract that implements the state machine pattern and adds time dependant transitions.
contract TimedStateMachine is StateMachine {

    event LogSetStateStartTime(bytes32 indexed _stateId, uint256 _startTime);

    // Stores the start timestamp for each state (the value is 0 if the state doesn't have a start timestamp).
    mapping(bytes32 => uint256) private startTime;

    /// @dev Returns the timestamp for the given state id.
    /// @param _stateId The id of the state for which we want to set the start timestamp.
    function getStateStartTime(bytes32 _stateId) public view returns(uint256) {
        return startTime[_stateId];
    }

    /// @dev Sets the starting timestamp for a state.
    /// @param _stateId The id of the state for which we want to set the start timestamp.
    /// @param _timestamp The start timestamp for the given state. It should be bigger than the current one.
    function setStateStartTime(bytes32 _stateId, uint256 _timestamp) internal {
        require(block.timestamp < _timestamp);

        if (startTime[_stateId] == 0) {
            addStartCondition(_stateId, hasStartTimePassed);
        }

        startTime[_stateId] = _timestamp;

        LogSetStateStartTime(_stateId, _timestamp);
    }

    function hasStartTimePassed(bytes32 _stateId) internal returns(bool) {
        return startTime[_stateId] <= block.timestamp;
    }

}

// File: @tokenfoundry/token-contracts/contracts/TokenControllerI.sol

/// @title Interface for token controllers. The controller specifies whether a transfer can be done.
contract TokenControllerI {

    /// @dev Specifies whether a transfer is allowed or not.
    /// @return True if the transfer is allowed
    function transferAllowed(address _from, address _to) external view returns (bool);
}

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: @tokenfoundry/token-contracts/contracts/ControllableToken.sol

/**
 * @title Controllable ERC20 token
 *
 * @dev Token that queries a token controller contract to check if a transfer is allowed.
 * @dev controller state var is going to be set with the address of a TokenControllerI contract that has 
 * implemented transferAllowed() function.
 */
contract ControllableToken is Ownable, StandardToken {
    TokenControllerI public controller;

    /// @dev Executes transferAllowed() function from the Controller. 
    modifier isAllowed(address _from, address _to) {
        require(controller.transferAllowed(_from, _to));
        _;
    }

    /// @dev Sets the controller that is going to be used by isAllowed modifier
    function setController(TokenControllerI _controller) onlyOwner public {
        require(_controller != address(0));
        controller = _controller;
    }

    /// @dev It calls parent BasicToken.transfer() function. It will transfer an amount of tokens to an specific address
    /// @return True if the token is transfered with success
    function transfer(address _to, uint256 _value) isAllowed(msg.sender, _to) public returns (bool) {        
        return super.transfer(_to, _value);
    }

    /// @dev It calls parent StandardToken.transferFrom() function. It will transfer from an address a certain amount of tokens to another address 
    /// @return True if the token is transfered with success 
    function transferFrom(address _from, address _to, uint256 _value) isAllowed(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

// File: zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: @tokenfoundry/token-contracts/contracts/Token.sol

/**
 * @title Token base contract - Defines basic structure for a token
 *
 * @dev ControllableToken is a StandardToken, an OpenZeppelin ERC20 implementation library. DetailedERC20 is also an OpenZeppelin contract.
 * More info about them is available here: https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token/ERC20
 */
contract Token is ControllableToken, DetailedERC20 {

	/**
	* @dev Transfer is an event inherited from ERC20Basic.sol interface (OpenZeppelin).
	* @param _supply Total supply of tokens.
    * @param _name Is the long name by which the token contract should be known
    * @param _symbol The set of capital letters used to represent the token e.g. DTH.
    * @param _decimals The number of decimal places the tokens can be split up into. This should be between 0 and 18.
	*/
    function Token(
        uint256 _supply,
        string _name,
        string _symbol,
        uint8 _decimals
    ) DetailedERC20(_name, _symbol, _decimals) public {
        require(_supply != 0);
        totalSupply_ = _supply;
        balances[msg.sender] = _supply;
        Transfer(address(0), msg.sender, _supply);  //event
    }
}

// File: @tokenfoundry/sale-contracts/contracts/Sale.sol

/// @title Sale base contract
contract Sale is Ownable, Whitelistable, TimedStateMachine, TokenControllerI {
    using SafeMath for uint256;

    // State machine states
    bytes32 private constant SETUP = 'setup';
    bytes32 private constant FREEZE = 'freeze';
    bytes32 private constant SALE_IN_PROGRESS = 'saleInProgress';
    bytes32 private constant SALE_ENDED = 'saleEnded';
    bytes32[] public states = [SETUP, FREEZE, SALE_IN_PROGRESS, SALE_ENDED];

    // Stores the contribution for each user
    mapping(address => uint256) public contributions;
    // Records which users have contributed throughout the sale
    mapping(address => bool) public hasContributed;

    DisbursementHandler public disbursementHandler;

    uint256 public weiContributed = 0;
    uint256 public totalSaleCap;
    uint256 public minContribution;
    uint256 public minThreshold;

    // How many tokens a user will receive per each wei contributed
    uint256 public tokensPerWei;
    uint256 public tokensForSale;

    Token public trustedToken;
    Vault public trustedVault;

    event LogContribution(address indexed contributor, uint256 value, uint256 excess);
    event LogTokensAllocated(address indexed contributor, uint256 amount);

    function Sale(
        uint256 _totalSaleCap,
        uint256 _minContribution,
        uint256 _minThreshold,
        uint256 _maxTokens,
        address _whitelistAdmin,
        address _wallet,
        uint256 _closingDuration,
        uint256 _vaultInitialAmount,
        uint256 _vaultDisbursementAmount,
        uint256 _startTime,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals
    ) 
        Whitelistable(_whitelistAdmin)
        public 
    {
        require(_totalSaleCap != 0);
        require(_maxTokens != 0);
        require(_wallet != 0);
        require(_minThreshold <= _totalSaleCap);
        require(_vaultInitialAmount <= _minThreshold);
        require(now < _startTime);

        totalSaleCap = _totalSaleCap;
        minContribution = _minContribution;
        minThreshold = _minThreshold;

        // Setup the necessary contracts
        trustedToken = new Token(_maxTokens, _tokenName, _tokenSymbol, _tokenDecimals);
        disbursementHandler = new DisbursementHandler(trustedToken);

        trustedToken.setController(this);

        trustedVault = new Vault(
            _wallet,
            _vaultInitialAmount,
            _vaultDisbursementAmount, // disbursement amount
            _closingDuration
        );

        // Set the states
        setStates(states);

        allowFunction(SETUP, this.setup.selector);
        allowFunction(FREEZE, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.contribute.selector);
        allowFunction(SALE_IN_PROGRESS, this.endSale.selector);
        allowFunction(SALE_ENDED, this.allocateTokens.selector);

        // End the sale when the cap is reached
        addStartCondition(SALE_ENDED, wasCapReached);

        // Set the onSaleEnded callback (will be called when the sale ends)
        addCallback(SALE_ENDED, onSaleEnded);

        // Set the start and end times for the sale
        setStateStartTime(SALE_IN_PROGRESS, _startTime);
    }

    /// @dev Setup the disbursements and tokens for sale.
    /// @dev This needs to be outside the constructor because the token needs to query the sale for allowed transfers.
    function setup() public onlyOwner checkAllowed {
        require(trustedToken.transfer(disbursementHandler, disbursementHandler.totalAmount()));
        tokensForSale = trustedToken.balanceOf(this);       
        require(tokensForSale >= totalSaleCap);

        // Go to freeze state
        goToNextState();
    }

    /// @dev Called by users to contribute ETH to the sale.
    function contribute(uint256 contributionLimit, uint256 currentSaleCap, uint8 v, bytes32 r, bytes32 s) 
        external 
        payable
        checkAllowed 
    {
        // Check that the signature is valid
        require(currentSaleCap <= totalSaleCap);
        require(weiContributed < currentSaleCap);
        require(checkWhitelisted(msg.sender, contributionLimit, currentSaleCap, v, r, s));

        uint256 current = contributions[msg.sender];
        require(current < contributionLimit);

        // Get the max amount that the user can contribute
        uint256 remaining = Math.min256(contributionLimit.sub(current), currentSaleCap.sub(weiContributed));

        // Check if it goes over the contribution limit of the user or the eth cap. 
        uint256 contribution = Math.min256(msg.value, remaining);

        // Get the total contribution for the contributor after the previous checks
        uint256 totalContribution = current.add(contribution);
        require(totalContribution >= minContribution);

        contributions[msg.sender] = totalContribution;
        hasContributed[msg.sender] = true;

        weiContributed = weiContributed.add(contribution);

        trustedVault.deposit.value(contribution)(msg.sender);

        if (weiContributed >= minThreshold && trustedVault.state() != Vault.State.Success) trustedVault.saleSuccessful();

        // If there is an excess, return it to the user
        uint256 excess = msg.value.sub(contribution);
        if (excess > 0) msg.sender.transfer(excess);

        LogContribution(msg.sender, contribution, excess);

        assert(totalContribution <= contributionLimit);
    }

    /// @dev Sets the end time for the sale
    /// @param _endTime The timestamp at which the sale will end.
    function setEndTime(uint256 _endTime) external onlyOwner checkAllowed {
        require(now < _endTime);
        require(getStateStartTime(SALE_ENDED) == 0);
        setStateStartTime(SALE_ENDED, _endTime);
    }

    /// @dev Called to allocate the tokens depending on eth contributed by the end of the sale.
    /// @param _contributor The address of the contributor.
    function allocateTokens(address _contributor) external checkAllowed {
        require(contributions[_contributor] != 0);

        // Transfer the respective tokens to the contributor
        uint256 amount = contributions[_contributor].mul(tokensPerWei);

        // Set contributions to 0
        contributions[_contributor] = 0;

        require(trustedToken.transfer(_contributor, amount));

        LogTokensAllocated(_contributor, amount);
    }

    /// @dev Called to end the sale by the owner. Can only be called in SALE_IN_PROGRESS state
    function endSale() external onlyOwner checkAllowed {
        goToNextState();
    }

    /// @dev Since Sale is TokenControllerI, it has to implement transferAllowed() function
    /// @notice only the Sale and DisbursementHandler can disburse the initial tokens to their future owners
    function transferAllowed(address _from, address) external view returns (bool) {
        return _from == address(this) || _from == address(disbursementHandler);
    }

    /// @dev Called internally by the sale to setup a disbursement (it has to be called in the constructor of child sales)
    /// param _beneficiary Tokens will be disbursed to this address.
    /// param _amount Number of tokens to be disbursed.
    /// param _duration Tokens will be locked for this long.
    function setupDisbursement(address _beneficiary, uint256 _amount, uint256 _duration) internal {
        require(tokensForSale == 0);
        disbursementHandler.setupDisbursement(_beneficiary, _amount, now.add(_duration));
    }
   
    /// @dev Returns true if the cap was reached.
    function wasCapReached(bytes32) internal returns (bool) {
        return totalSaleCap <= weiContributed;
    }

    /// @dev Callback that gets called when entering the SALE_ENDED state.
    function onSaleEnded() internal {
        // If the minimum threshold wasn't reached, enable refunds
        if (weiContributed < minThreshold) {
            trustedVault.enableRefunds();
        } else {
            trustedVault.beginClosingPeriod();
            tokensPerWei = tokensForSale.div(weiContributed);
        }

        trustedToken.transferOwnership(owner); 
        trustedVault.transferOwnership(owner);
    }

}

// File: contracts/VirtuePokerSale.sol

contract VirtuePokerSale is Sale {

    function VirtuePokerSale() 
        Sale(
            25000 ether, // Total sale cap
            1 ether, // Min contribution
            12000 ether, // Min threshold
            500000000 * (10 ** 18), // Max tokens
            0x13ebf15f2e32d05ea944927ef5e6a3cad8187440, // Whitelist Admin
            0xaa0aE3459F9f3472d1237015CaFC1aAfc6F03C63, // Wallet
            28 days, // Closing duration
            12000 ether, // Vault initial amount
            25000 ether, // Vault disbursement amount
            1524218400, // Start time
            "Virtue Player Points", // Token name
            "VPP", // Token symbol
            18 // Token decimals
        )
        public 
    {
        // Team Wallet (50,000,000 VPP, 25% per year)
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 1 years);
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 2 years);
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 3 years);
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 4 years);

        // Company Wallet (250,000,000 VPP, no lock-up)
        setupDisbursement(0xaa0aE3459F9f3472d1237015CaFC1aAfc6F03C63, 250000000 * (10 ** 18), 1 days);

        // Founder Allocations (total 100,000,000, 12.5% per 6 months)
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 0.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 1 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 1.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 2 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 2.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 3 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 3.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 4 years);

        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 0.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 1 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 1.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 2 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 2.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 3 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 3.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 4 years);

        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 0.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 1 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 1.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 2 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 2.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 3 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 3.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 4 years);
    }
}