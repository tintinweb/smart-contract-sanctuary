pragma solidity 0.4.18;

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

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}



/// @title A library for implementing a generic state machine pattern.
library StateMachineLib {

    struct Stage {
        // The id of the next stage
        bytes32 nextId;

        // The identifiers for the available functions in each stage
        mapping(bytes4 => bool) allowedFunctions;
    }

    struct State {
        // The current stage id
        bytes32 currentStageId;

        // A callback that is called when entering this stage
        function(bytes32) internal onTransition;

        // Checks if a stage id is valid
        mapping(bytes32 => bool) validStage;

        // Maps stage ids to their Stage structs
        mapping(bytes32 => Stage) stages;
    }

    /// @dev Creates and sets the initial stage. It has to be called before creating any transitions.
    /// @param stageId The id of the (new) stage to set as initial stage.
    function setInitialStage(State storage self, bytes32 stageId) internal {
        self.validStage[stageId] = true;
        self.currentStageId = stageId;
    }

    /// @dev Creates a transition from &#39;fromId&#39; to &#39;toId&#39;. If fromId already had a nextId, it deletes the now unreachable stage.
    /// @param fromId The id of the stage from which the transition begins.
    /// @param toId The id of the stage that will be reachable from "fromId".
    function createTransition(State storage self, bytes32 fromId, bytes32 toId) internal {
        require(self.validStage[fromId]);

        Stage storage from = self.stages[fromId];

        // Invalidate the stage that won&#39;t be reachable any more
        if (from.nextId != 0) {
            self.validStage[from.nextId] = false;
            delete self.stages[from.nextId];
        }

        from.nextId = toId;
        self.validStage[toId] = true;
    }

    /// @dev Goes to the next stage if posible (if the next stage is valid)
    function goToNextStage(State storage self) internal {
        Stage storage current = self.stages[self.currentStageId];

        require(self.validStage[current.nextId]);

        self.currentStageId = current.nextId;

        self.onTransition(current.nextId);
    }

    /// @dev Checks if the a function is allowed in the current stage.
    /// @param selector A function selector (bytes4[keccak256(functionSignature)])
    /// @return true If the function is allowed in the current stage
    function checkAllowedFunction(State storage self, bytes4 selector) internal constant returns(bool) {
        return self.stages[self.currentStageId].allowedFunctions[selector];
    }

    /// @dev Allow a function in the given stage.
    /// @param stageId The id of the stage
    /// @param selector A function selector (bytes4[keccak256(functionSignature)])
    function allowFunction(State storage self, bytes32 stageId, bytes4 selector) internal {
        require(self.validStage[stageId]);
        self.stages[stageId].allowedFunctions[selector] = true;
    }


}



contract StateMachine {
    using StateMachineLib for StateMachineLib.State;

    event LogTransition(bytes32 indexed stageId, uint256 blockNumber);

    StateMachineLib.State internal state;

    /* This modifier performs the conditional transitions and checks that the function 
     * to be executed is allowed in the current stage
     */
    modifier checkAllowed {
        conditionalTransitions();
        require(state.checkAllowedFunction(msg.sig));
        _;
    }

    function StateMachine() public {
        // Register the startConditions function and the onTransition callback
        state.onTransition = onTransition;
    }

    /// @dev Gets the current stage id.
    /// @return The current stage id.
    function getCurrentStageId() public view returns(bytes32) {
        return state.currentStageId;
    }

    /// @dev Performs conditional transitions. Can be called by anyone.
    function conditionalTransitions() public {

        bytes32 nextId = state.stages[state.currentStageId].nextId;

        while (state.validStage[nextId]) {
            StateMachineLib.Stage storage next = state.stages[nextId];
            // If the next stage&#39;s condition is true, go to next stage and continue
            if (startConditions(nextId)) {
                state.goToNextStage();
                nextId = next.nextId;
            } else {
                break;
            }
        }
    }

    /// @dev Determines whether the conditions for transitioning to the given stage are met.
    /// @return true if the conditions are met for the given stageId. False by default (must override in child contracts).
    function startConditions(bytes32) internal constant returns(bool) {
        return false;
    }

    /// @dev Callback called when there is a stage transition. It should be overridden for additional functionality.
    function onTransition(bytes32 stageId) internal {
        LogTransition(stageId, block.number);
    }


}

/// @title A contract that implements the state machine pattern and adds time dependant transitions.
contract TimedStateMachine is StateMachine {

    event LogSetStageStartTime(bytes32 indexed stageId, uint256 startTime);

    // Stores the start timestamp for each stage (the value is 0 if the stage doesn&#39;t have a start timestamp).
    mapping(bytes32 => uint256) internal startTime;

    /// @dev This function overrides the startConditions function in the parent class in order to enable automatic transitions that depend on the timestamp.
    function startConditions(bytes32 stageId) internal constant returns(bool) {
        // Get the startTime for stage
        uint256 start = startTime[stageId];
        // If the startTime is set and has already passed, return true.
        return start != 0 && block.timestamp > start;
    }

    /// @dev Sets the starting timestamp for a stage.
    /// @param stageId The id of the stage for which we want to set the start timestamp.
    /// @param timestamp The start timestamp for the given stage. It should be bigger than the current one.
    function setStageStartTime(bytes32 stageId, uint256 timestamp) internal {
        require(state.validStage[stageId]);
        require(timestamp > block.timestamp);

        startTime[stageId] = timestamp;
        LogSetStageStartTime(stageId, timestamp);
    }

    /// @dev Returns the timestamp for the given stage id.
    /// @param stageId The id of the stage for which we want to set the start timestamp.
    function getStageStartTime(bytes32 stageId) public view returns(uint256) {
        return startTime[stageId];
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

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
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


contract ERC223Basic is ERC20Basic {

    /**
      * @dev Transfer the specified amount of tokens to the specified address.
      *      Now with a new parameter _data.
      *
      * @param _to    Receiver address.
      * @param _value Amount of tokens that will be transferred.
      * @param _data  Transaction metadata.
      */
    function transfer(address _to, uint _value, bytes _data) public returns (bool);

    /**
      * @dev triggered when transfer is successfully called.
      *
      * @param _from  Sender address.
      * @param _to    Receiver address.
      * @param _value Amount of tokens that will be transferred.
      * @param _data  Transaction metadata.
      */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _value, bytes _data);
}

/// @title Contract that supports the receival of ERC223 tokens.
contract ERC223ReceivingContract {

    /// @dev Standard ERC223 function that will handle incoming token transfers.
    /// @param _from  Token sender address.
    /// @param _value Amount of tokens.
    /// @param _data  Transaction metadata.
    function tokenFallback(address _from, uint _value, bytes _data);

}

/**
 * @title ERC223 standard token implementation.
 */
contract ERC223BasicToken is ERC223Basic, BasicToken {

    /**
      * @dev Transfer the specified amount of tokens to the specified address.
      *      Invokes the `tokenFallback` function if the recipient is a contract.
      *      The token transfer fails if the recipient is a contract
      *      but does not implement the `tokenFallback` function
      *      or the fallback function to receive funds.
      *
      * @param _to    Receiver address.
      * @param _value Amount of tokens that will be transferred.
      * @param _data  Transaction metadata.
      */
    function transfer(address _to, uint _value, bytes _data) public returns (bool) {
        // Standard function transfer similar to ERC20 transfer with no _data .
        // Added due to backwards compatibility reasons .
        uint codeLength;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }

        require(super.transfer(_to, _value));

        if(codeLength>0) {
            ERC223ReceivingContract receiver = ERC223ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, _data);
        }
        Transfer(msg.sender, _to, _value, _data);
        return true;
    }

      /**
      * @dev Transfer the specified amount of tokens to the specified address.
      *      Invokes the `tokenFallback` function if the recipient is a contract.
      *      The token transfer fails if the recipient is a contract
      *      but does not implement the `tokenFallback` function
      *      or the fallback function to receive funds.
      *
      * @param _to    Receiver address.
      * @param _value Amount of tokens that will be transferred.
      */
    function transfer(address _to, uint256 _value) public returns (bool) {
        bytes memory empty;
        require(transfer(_to, _value, empty));
        return true;
    }

}



/// @title Token for the Pryze project.
contract PryzeToken is DetailedERC20, MintableToken, ERC223BasicToken {
    string constant NAME = "Pryze";
    string constant SYMBOL = "PRYZ";
    uint8 constant DECIMALS = 18;

    //// @dev Constructor that sets details of the ERC20 token.
    function PryzeToken()
        DetailedERC20(NAME, SYMBOL, DECIMALS)
        public
    {}
}



contract Whitelistable is Ownable {
    
    event LogUserRegistered(address indexed sender, address indexed userAddress);
    event LogUserUnregistered(address indexed sender, address indexed userAddress);
    
    mapping(address => bool) public whitelisted;

    function registerUser(address userAddress) 
        public 
        onlyOwner 
    {
        require(userAddress != 0);
        whitelisted[userAddress] = true;
        LogUserRegistered(msg.sender, userAddress);
    }

    function unregisterUser(address userAddress) 
        public 
        onlyOwner 
    {
        require(whitelisted[userAddress] == true);
        whitelisted[userAddress] = false;
        LogUserUnregistered(msg.sender, userAddress);
    }
}


contract DisbursementHandler is Ownable {

    struct Disbursement {
        uint256 timestamp;
        uint256 tokens;
    }

    event LogSetup(address indexed vestor, uint256 tokens, uint256 timestamp);
    event LogChangeTimestamp(address indexed vestor, uint256 index, uint256 timestamp);
    event LogWithdraw(address indexed to, uint256 value);

    ERC20 public token;
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
        public
        onlyOwner
    {
        require(block.timestamp < timestamp);
        disbursements[vestor].push(Disbursement(timestamp, tokens));
        LogSetup(vestor, timestamp, tokens);
    }

    /// @dev Change an existing disbursement.
    /// @param vestor The address of the beneficiary.
    /// @param timestamp Funds will be locked until this timestamp.
    /// @param index Index of the DisbursementVesting in the vesting array.
    function changeTimestamp(
        address vestor,
        uint256 index,
        uint256 timestamp
    )
        public
        onlyOwner
    {
        require(block.timestamp < timestamp);
        require(index < disbursements[vestor].length);
        disbursements[vestor][index].timestamp = timestamp;
        LogChangeTimestamp(vestor, index, timestamp);
    }

    /// @dev Transfers tokens to a given address
    /// @param to Address of token receiver
    /// @param value Number of tokens to transfer
    function withdraw(address to, uint256 value)
        public
    {
        uint256 maxTokens = calcMaxWithdraw();
        uint256 withdrawAmount = value < maxTokens ? value : maxTokens;
        withdrawnTokens[msg.sender] = SafeMath.add(withdrawnTokens[msg.sender], withdrawAmount);
        token.transfer(to, withdrawAmount);
        LogWithdraw(to, value);
    }

    /// @dev Calculates the maximum amount of vested tokens
    /// @return Number of vested tokens to withdraw
    function calcMaxWithdraw()
        public
        constant
        returns (uint256)
    {
        uint256 maxTokens = 0;
        Disbursement[] storage temp = disbursements[msg.sender];
        for (uint256 i = 0; i < temp.length; i++) {
            if (block.timestamp > temp[i].timestamp) {
                maxTokens = SafeMath.add(maxTokens, temp[i].tokens);
            }
        }
        maxTokens = SafeMath.sub(maxTokens, withdrawnTokens[msg.sender]);
        return maxTokens;
    }
}


/// @title Sale base contract
contract Sale is Ownable, TimedStateMachine {
    using SafeMath for uint256;

    event LogContribution(address indexed contributor, uint256 amountSent, uint256 excessRefunded);
    event LogTokenAllocation(address indexed contributor, uint256 contribution, uint256 tokens);
    event LogDisbursement(address indexed beneficiary, uint256 tokens);

    // Stages for the state machine
    bytes32 public constant SETUP = "setup";
    bytes32 public constant SETUP_DONE = "setupDone";
    bytes32 public constant SALE_IN_PROGRESS = "saleInProgress";
    bytes32 public constant SALE_ENDED = "saleEnded";

    mapping(address => uint256) public contributions;

    uint256 public weiContributed = 0;
    uint256 public contributionCap;

    // Wallet where funds will be sent
    address public wallet;

    MintableToken public token;

    DisbursementHandler public disbursementHandler;

    function Sale(
        address _wallet, 
        uint256 _contributionCap
    ) 
        public 
    {
        require(_wallet != 0);
        require(_contributionCap != 0);

        wallet = _wallet;

        token = createTokenContract();
        disbursementHandler = new DisbursementHandler(token);

        contributionCap = _contributionCap;

        setupStages();
    }

    function() external payable {
        contribute();
    }

    /// @dev Sets the start timestamp for the SALE_IN_PROGRESS stage.
    /// @param timestamp The start timestamp.
    function setSaleStartTime(uint256 timestamp) 
        external 
        onlyOwner 
        checkAllowed
    {
        // require(_startTime < getStageStartTime(SALE_ENDED));
        setStageStartTime(SALE_IN_PROGRESS, timestamp);
    }

    /// @dev Sets the start timestamp for the SALE_ENDED stage.
    /// @param timestamp The start timestamp.
    function setSaleEndTime(uint256 timestamp) 
        external 
        onlyOwner 
        checkAllowed
    {
        require(getStageStartTime(SALE_IN_PROGRESS) < timestamp);
        setStageStartTime(SALE_ENDED, timestamp);
    }

    /// @dev Called in the SETUP stage, check configurations and to go to the SETUP_DONE stage.
    function setupDone() 
        public 
        onlyOwner 
        checkAllowed
    {
        uint256 _startTime = getStageStartTime(SALE_IN_PROGRESS);
        uint256 _endTime = getStageStartTime(SALE_ENDED);
        require(block.timestamp < _startTime);
        require(_startTime < _endTime);

        state.goToNextStage();
    }

    /// @dev Called by users to contribute ETH to the sale.
    function contribute() 
        public 
        payable
        checkAllowed 
    {
        require(msg.value > 0);   

        uint256 contributionLimit = getContributionLimit(msg.sender);
        require(contributionLimit > 0);

        // Check that the user is allowed to contribute
        uint256 totalContribution = contributions[msg.sender].add(msg.value);
        uint256 excess = 0;

        // Check if it goes over the eth cap for the sale.
        if (weiContributed.add(msg.value) > contributionCap) {
            // Subtract the excess
            excess = weiContributed.add(msg.value).sub(contributionCap);
            totalContribution = totalContribution.sub(excess);
        }

        // Check if it goes over the contribution limit of the user. 
        if (totalContribution > contributionLimit) {
            excess = excess.add(totalContribution).sub(contributionLimit);
            contributions[msg.sender] = contributionLimit;
        } else {
            contributions[msg.sender] = totalContribution;
        }

        // We are only able to refund up to msg.value because the contract will not contain ether
        excess = excess < msg.value ? excess : msg.value;

        weiContributed = weiContributed.add(msg.value).sub(excess);

        if (excess > 0) {
            msg.sender.transfer(excess);
        }

        wallet.transfer(this.balance);

        assert(contributions[msg.sender] <= contributionLimit);
        LogContribution(msg.sender, msg.value, excess);
    }

    /// @dev Create a disbursement of tokens.
    /// @param beneficiary The beneficiary of the disbursement.
    /// @param tokenAmount Amount of tokens to be locked.
    /// @param timestamp Tokens will be locked until this timestamp.
    function distributeTimelockedTokens(
        address beneficiary,
        uint256 tokenAmount,
        uint256 timestamp
    ) 
        external
        onlyOwner
        checkAllowed
    { 
        disbursementHandler.setupDisbursement(
            beneficiary,
            tokenAmount,
            timestamp
        );
        token.mint(disbursementHandler, tokenAmount);
        LogDisbursement(beneficiary, tokenAmount);
    }
    
    function setupStages() internal {
        // Set the stages
        state.setInitialStage(SETUP);
        state.createTransition(SETUP, SETUP_DONE);
        state.createTransition(SETUP_DONE, SALE_IN_PROGRESS);
        state.createTransition(SALE_IN_PROGRESS, SALE_ENDED);

        // The selectors should be hardcoded
        state.allowFunction(SETUP, this.distributeTimelockedTokens.selector);
        state.allowFunction(SETUP, this.setSaleStartTime.selector);
        state.allowFunction(SETUP, this.setSaleEndTime.selector);
        state.allowFunction(SETUP, this.setupDone.selector);
        state.allowFunction(SALE_IN_PROGRESS, this.contribute.selector);
        state.allowFunction(SALE_IN_PROGRESS, 0); // fallback
    }

    // Override in the child sales
    function createTokenContract() internal returns (MintableToken);
    function getContributionLimit(address userAddress) internal returns (uint256);

    /// @dev Stage start conditions.
    function startConditions(bytes32 stageId) internal constant returns (bool) {
        // If the cap has been reached, end the sale.
        if (stageId == SALE_ENDED && contributionCap == weiContributed) {
            return true;
        }
        return super.startConditions(stageId);
    }

    /// @dev State transitions callbacks.
    function onTransition(bytes32 stageId) internal {
        if (stageId == SALE_ENDED) { 
            onSaleEnded(); 
        }
        super.onTransition(stageId);
    }

    /// @dev Callback that gets called when entering the SALE_ENDED stage.
    function onSaleEnded() internal {}
}



contract PryzeSale is Sale, Whitelistable {

    uint256 public constant PRESALE_WEI = 10695.303 ether; // Amount raised in the presale
    uint256 public constant PRESALE_WEI_WITH_BONUS = 10695.303 ether * 1.5; // Amount raised in the presale times the bonus

    uint256 public constant MAX_WEI = 24695.303 ether; // Max wei to raise, including PRESALE_WEI
    uint256 public constant WEI_CAP = 14000 ether; // MAX_WEI - PRESALE_WEI
    uint256 public constant MAX_TOKENS = 400000000 * 1000000000000000000; // 4mm times 10^18 (18 decimals)

    uint256 public presaleWeiContributed = 0;
    uint256 private weiAllocated = 0;

    mapping(address => uint256) public presaleContributions;

    function PryzeSale(
        address _wallet
    )
        Sale(_wallet, WEI_CAP)
        public 
    {
    }

    /// @dev Sets the presale contribution for a contributor.
    /// @param _contributor The contributor.
    /// @param _amount The amount contributed in the presale (without the bonus).
    function presaleContribute(address _contributor, uint256 _amount)
        external
        onlyOwner
        checkAllowed
    {
        // If presale contribution is already set, replace the amount in the presaleWeiContributed variable
        if (presaleContributions[_contributor] != 0) {
            presaleWeiContributed = presaleWeiContributed.sub(presaleContributions[_contributor]);
        } 
        presaleWeiContributed = presaleWeiContributed.add(_amount);
        require(presaleWeiContributed <= PRESALE_WEI);
        presaleContributions[_contributor] = _amount;
    }

    /// @dev Called to allocate the tokens depending on eth contributed.
    /// @param contributor The address of the contributor.
    function allocateTokens(address contributor) 
        external 
        checkAllowed
    {
        require(presaleContributions[contributor] != 0 || contributions[contributor] != 0);
        uint256 tokensToAllocate = calculateAllocation(contributor);

        // We keep a record of how much wei contributed has already been used for allocations
        weiAllocated = weiAllocated.add(presaleContributions[contributor]).add(contributions[contributor]);

        // Set contributions to 0
        presaleContributions[contributor] = 0;
        contributions[contributor] = 0;

        // Mint the respective tokens to the contributor
        token.mint(contributor, tokensToAllocate);

        // If all tokens were allocated, stop minting functionality
        if (weiAllocated == PRESALE_WEI.add(weiContributed)) {
          token.finishMinting();
        }
    }

    function setupDone() 
        public 
        onlyOwner 
        checkAllowed
    {
        require(presaleWeiContributed == PRESALE_WEI);
        super.setupDone();
    }

    /// @dev Calculate the PRYZ allocation for the given contributor. The allocation is proportional to the amount of wei contributed.
    /// @param contributor The address of the contributor
    /// @return The amount of tokens to allocate
    function calculateAllocation(address contributor) public constant returns (uint256) {
        uint256 presale = presaleContributions[contributor].mul(15).div(10); // Multiply by 1.5
        uint256 totalContribution = presale.add(contributions[contributor]);
        return totalContribution.mul(MAX_TOKENS).div(PRESALE_WEI_WITH_BONUS.add(weiContributed));
    }

    function setupStages() internal {
        super.setupStages();
        state.allowFunction(SETUP, this.presaleContribute.selector);
        state.allowFunction(SALE_ENDED, this.allocateTokens.selector);
    }

    function createTokenContract() internal returns(MintableToken) {
        return new PryzeToken();
    }

    function getContributionLimit(address userAddress) internal returns (uint256) {
        // No contribution cap if whitelisted
        return whitelisted[userAddress] ? 2**256 - 1 : 0;
    }

}