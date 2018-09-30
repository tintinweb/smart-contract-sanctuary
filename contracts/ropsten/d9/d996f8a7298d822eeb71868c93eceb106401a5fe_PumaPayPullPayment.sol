pragma solidity 0.4.25;

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: contracts/PumaPayToken.sol

/// PumaPayToken inherits from MintableToken, which in turn inherits from StandardToken.
/// Super is used to bypass the original function signature and include the whenNotMinting modifier.
contract PumaPayToken is MintableToken {

    string public name = "PumaPay"; 
    string public symbol = "PMA";
    uint8 public decimals = 18;

    constructor() public {
    }

    /// This modifier will be used to disable all ERC20 functionalities during the minting process.
    modifier whenNotMinting() {
        require(mintingFinished);
        _;
    }

    /// @dev transfer token for a specified address
    /// @param _to address The address to transfer to.
    /// @param _value uint256 The amount to be transferred.
    /// @return success bool Calling super.transfer and returns true if successful.
    function transfer(address _to, uint256 _value) public whenNotMinting returns (bool) {
        return super.transfer(_to, _value);
    }

    /// @dev Transfer tokens from one address to another.
    /// @param _from address The address which you want to send tokens from.
    /// @param _to address The address which you want to transfer to.
    /// @param _value uint256 the amount of tokens to be transferred.
    /// @return success bool Calling super.transferFrom and returns true if successful.
    function transferFrom(address _from, address _to, uint256 _value) public whenNotMinting returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

// File: contracts/MasterPullPayment.sol

/// @title PumaPay Pull Payment - Contract that facilitates our pull payment protocol
/// @author PumaPay Dev Team - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="53373625363f3c233621201323263e3223322a7d3a3c">[email&#160;protected]</a>>
contract PumaPayPullPayment is Ownable {
    using SafeMath for uint256;
    /// =================================================================================================================
    ///                                      Events
    /// =================================================================================================================
    
    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogPaymentRegistered(address clientAddress, address beneficiaryAddress, string paymentID);
    event LogPaymentCancelled(address clientAddress, address beneficiaryAddress, string paymentID);
    event LogPullPaymentExecuted(address clientAddress, address beneficiaryAddress, string paymentID);
    event LogSetExchangeRate(string currency, uint256 exchangeRate);

    /// =================================================================================================================
    ///                                      Constants
    /// =================================================================================================================

    uint256 constant private DECIMAL_FIXER = 10000000000; // 1^10 - This transforms the Rate from decimals to uint256
    uint256 constant private FIAT_TO_CENT_FIXER = 100;    // Fiat currencies have 100 cents in 1 basic monetary unit.
    uint256 constant private ONE_ETHER = 1 ether;         // PumaPay token has 18 decimals - same as one ETHER
    uint256 constant private MINIMUM_AMOUN_OF_ETH_FOR_OPARATORS = 0.01 ether; // minimum amount of ETHER the owner/executor should have 
    /// =================================================================================================================
    ///                                      Members
    /// =================================================================================================================

    PumaPayToken public token;

    mapping (string => uint256) private exchangeRates;
    mapping (address => bool) public executors;
    mapping (address => mapping (address => PullPayment)) public pullPayments;

    struct PullPayment {
        string merchantID;                      /// ID of the merchant
        string paymentID;                       /// ID of the payment
        string currency;                        /// 3-letter abbr i.e. &#39;EUR&#39; / &#39;USD&#39; etc.
        uint256 initialPaymentAmountInCents;    /// initial payment amount in fiat in cents
        uint256 fiatAmountInCents;              /// payment amount in fiat in cents
        uint256 frequency;                      /// how often merchant can pull - in seconds
        uint256 numberOfPayments;               /// amount of pull payments merchant can make
        uint256 startTimestamp;                 /// when subscription starts - in seconds
        uint256 nextPaymentTimestamp;           /// timestamp of next payment
        uint256 lastPaymentTimestamp;           /// timestamp of last payment
        uint256 cancelTimestamp;                /// timestamp the payment was cancelled
    }

    /// =================================================================================================================
    ///                                      Modifiers
    /// =================================================================================================================

    modifier isExecutor() {
         require(executors[msg.sender]);
         _;
     }

     modifier executorExists(address _executor) {
         require(executors[_executor]);
         _;
     }

     modifier executorDoesNotExists(address _executor) {
         require(!executors[_executor]);
         _;
     } 

    modifier paymentExists(address _client, address _beneficiary) {
        require(doesPaymentExist(_client, _beneficiary));
        _;
    }

    modifier paymentNotCancelled(address _client, address _beneficiary) {
        require(pullPayments[_client][_beneficiary].cancelTimestamp == 0);
        _;
    }

    modifier isValidPullPaymentRequest(address _client, address _beneficiary, string _paymentID) {
        require(
            (pullPayments[_client][_beneficiary].initialPaymentAmountInCents > 0 ||
            (now >= pullPayments[_client][_beneficiary].startTimestamp &&
            now >= pullPayments[_client][_beneficiary].nextPaymentTimestamp)
            ) 
            &&
            pullPayments[_client][_beneficiary].numberOfPayments > 0 &&
            (pullPayments[_client][_beneficiary].cancelTimestamp == 0 ||
            pullPayments[_client][_beneficiary].cancelTimestamp > pullPayments[_client][_beneficiary].nextPaymentTimestamp) &&
            keccak256(
                abi.encodePacked(pullPayments[_client][_beneficiary].paymentID)
                ) == keccak256(abi.encodePacked(_paymentID))
        );
        _;
    }

    modifier isValidDeletionRequest(string paymentID, address client, address beneficiary) {
        require(
            beneficiary != address(0) &&
            client != address(0) &&
            bytes(paymentID).length != 0
        );
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0));
        _;
    }

    /// =================================================================================================================
    ///                                      Constructor
    /// =================================================================================================================

    /// @dev Contract constructor - sets the token address that the contract facilitates.
    /// @param _token Token Address.
    constructor (PumaPayToken _token)
    public
    {
        require(_token != address(0));
        token = _token;
    }

    // @notice Will receive any eth sent to the contract
    function () external payable {
    }

    /// =================================================================================================================
    ///                                      Public Functions - Owner Only
    /// =================================================================================================================
    
    /// @dev Adds a new executor. - can be executed only by the onwer. 
    /// When adding a new executor 1 ETH is tranferred to allow the executor to pay for gas.
    /// The balance of the owner is also checked and if funding is needed 1 ETH is transferred.
    /// @param _executor - address of the executor which cannot be zero address.
    function addExecutor(address _executor)
    public 
    onlyOwner
    isValidAddress(_executor)
    executorDoesNotExists(_executor)
    {
        if (isFundingNeeded(owner)) {
            owner.transfer(1 ether);
        }
        _executor.transfer(1 ether);
        executors[_executor] = true;
        
        emit LogExecutorAdded(_executor);
    }

    /// @dev Removes a new executor. - can be executed only by the onwer.
    /// The balance of the owner is checked and if funding is needed 1 ETH is transferred.
    /// @param _executor - address of the executor which cannot be zero address.
    function removeExecutor(address _executor)
    public 
    onlyOwner
    isValidAddress(_executor)
    executorExists(_executor)
    {
        executors[_executor] = false;
        if (isFundingNeeded(owner)) {
            owner.transfer(1 ether);
        }
        emit LogExecutorRemoved(_executor);
    }

    /// @dev Sets the exchange rate for a currency. - can be executed only by the onwer.
    /// Emits &#39;LogSetExchangeRate&#39; with the currency and the updated rate.
    /// The balance of the owner is checked and if funding is needed 1 ETH is transferred.
    /// @param _currency - address of the executor which cannot be zero address
    /// @param _rate - address of the executor which cannot be zero address
    function setRate(string _currency, uint256 _rate)
    public
    onlyOwner
    returns (bool) {
        exchangeRates[_currency] = _rate;
        emit LogSetExchangeRate(_currency, _rate);
        
        if (isFundingNeeded(owner)) {
            owner.transfer(1 ether);
        }

        return true;
    }

    /// =================================================================================================================
    ///                                      Public Functions - Executors Only
    /// =================================================================================================================

    /// @dev Registers a new pull payment to the Master Pull Payment Contract - The registration can be executed only by one of the executors of the Master Pull Payment Contract
    /// and the Master Pull Payment Contract checks that the pull payment has been singed by the signatory of the account.
    /// The balance of the executor (msg.sender) is checked and if funding is needed 1 ETH is transferred.
    /// Emits &#39;LogPaymentRegistered&#39; with client address, beneficiary address and paymentID.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _merchantID - ID of the merchant.
    /// @param _paymentID - ID of the payment.
    /// @param _client - client address that is linked to this pull payment.
    /// @param _beneficiary - address that is allowed to execute this pull payment.
    /// @param _currency - currency of the payment / 3-letter abbr i.e. &#39;EUR&#39;.
    /// @param _fiatAmountInCents - payment amount in fiat in cents.
    /// @param _frequency - how often merchant can pull - in seconds.
    /// @param _numberOfPayments - amount of pull payments merchant can make
    /// @param _startTimestamp - when subscription starts - in seconds.
    function registerPullPayment (
        uint8 v,
        bytes32 r,
        bytes32 s,
        string _merchantID,
        string _paymentID,
        address _client,
        address _beneficiary,
        string _currency,
        uint256 _initialPaymentAmountInCents,
        uint256 _fiatAmountInCents,
        uint256 _frequency,
        uint256 _numberOfPayments,
        uint256 _startTimestamp
    )
    public
    isExecutor()
    {
        require(
            bytes(_paymentID).length > 0 &&
            bytes(_currency).length > 0 &&
            _client != address(0) &&
            _beneficiary != address(0) &&
            _initialPaymentAmountInCents >= 0 &&
            _fiatAmountInCents > 0 &&
            _frequency > 0 &&
            _numberOfPayments > 0 &&
            _startTimestamp > 0
        );

        pullPayments[_client][_beneficiary].currency = _currency;
        pullPayments[_client][_beneficiary].initialPaymentAmountInCents = _initialPaymentAmountInCents;
        pullPayments[_client][_beneficiary].fiatAmountInCents = _fiatAmountInCents;
        pullPayments[_client][_beneficiary].frequency = _frequency;
        pullPayments[_client][_beneficiary].startTimestamp = _startTimestamp;
        pullPayments[_client][_beneficiary].numberOfPayments = _numberOfPayments;

        if (!isValidRegistration(v, r, s, _client, _beneficiary, pullPayments[_client][_beneficiary])) revert();

        pullPayments[_client][_beneficiary].merchantID = _merchantID;
        pullPayments[_client][_beneficiary].paymentID = _paymentID;
        pullPayments[_client][_beneficiary].nextPaymentTimestamp = _startTimestamp;
        pullPayments[_client][_beneficiary].lastPaymentTimestamp = 0;
        pullPayments[_client][_beneficiary].cancelTimestamp = 0;
        
        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(1 ether);
        }

        emit LogPaymentRegistered(_client, _beneficiary, _paymentID);
    }

    /// @dev Deletes a pull payment for a beneficiary - The deletion needs can be executed only by one of the executors of the Master Pull Payment Contract
    /// and the Master Pull Payment Contract checks that the beneficiary and the paymentID have been singed by the signatory of the account.
    /// This method deletes the pull payment from the pull payments array for this beneficiary specified and
    /// also deletes the beneficiary from the beneficiaries array.
    /// The balance of the executor (msg.sender) is checked and if funding is needed 1 ETH is transferred.
    /// Emits &#39;LogPaymentCancelled&#39; with beneficiary address and paymentID.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _paymentID - ID of the payment.
    /// @param _client - client address that is linked to this pull payment.
    /// @param _beneficiary - address that is allowed to execute this pull payment.
    function deletePullPayment (
        uint8 v,
        bytes32 r,
        bytes32 s,
        string _paymentID,
        address _client,
        address _beneficiary
    )
    public
    isExecutor()
    paymentExists(_client, _beneficiary)
    paymentNotCancelled(_client, _beneficiary)
    isValidDeletionRequest(_paymentID, _client, _beneficiary)
    {   
        if (!isValidDeletion(v, r, s, _paymentID, _client, _beneficiary)) revert();
        pullPayments[_client][_beneficiary].cancelTimestamp = now;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(1 ether);
        }

        emit LogPaymentCancelled(_client, _beneficiary, _paymentID);
    }

    /// =================================================================================================================
    ///                                      Public Functions
    /// =================================================================================================================

    /// @dev Executes a pull payment for the msg.sender - The pull payment should exist and the payment request
    /// should be valid in terms of when it can be executed.
    /// Emits &#39;LogPullPaymentExecuted&#39; with client address, msg.sender as the beneficiary address and the paymentID.
    /// Use Case 1: Single/Recurring Fixed Pull Payment (initialPaymentAmountInCents == 0 )
    /// ------------------------------------------------
    /// We calculate the amount in PMA using the rate for the currency specified in the pull payment
    /// and the &#39;fiatAmountInCents&#39; and we transfer from the client account the amount in PMA.
    /// After execution we set the last payment timestamp to NOW, the next payment timestamp is incremented by
    /// the frequency and the number of payments is decresed by 1.
    /// Use Case 2: Recurring Fixed Pull Payment with initial fee (initialPaymentAmountInCents > 0)
    /// ------------------------------------------------------------------------------------------------
    /// We calculate the amount in PMA using the rate for the currency specified in the pull payment
    /// and the &#39;initialPaymentAmountInCents&#39; and we transfer from the client account the amount in PMA.
    /// After execution we set the last payment timestamp to NOW and the &#39;initialPaymentAmountInCents to ZERO.
    /// @param _client - address of the client from which the msg.sender requires to pull funds.
    function executePullPayment(address _client, string _paymentID)
    public
    paymentExists(_client, msg.sender)
    isValidPullPaymentRequest(_client, msg.sender, _paymentID)
    {
        uint256 amountInPMA;
        if (pullPayments[_client][msg.sender].initialPaymentAmountInCents > 0) {
            amountInPMA = calculatePMAFromFiat(pullPayments[_client][msg.sender].initialPaymentAmountInCents, pullPayments[_client][msg.sender].currency);
            pullPayments[_client][msg.sender].initialPaymentAmountInCents = 0;
        } else {
            amountInPMA = calculatePMAFromFiat(pullPayments[_client][msg.sender].fiatAmountInCents, pullPayments[_client][msg.sender].currency);   
            
            pullPayments[_client][msg.sender].nextPaymentTimestamp = pullPayments[_client][msg.sender].nextPaymentTimestamp + pullPayments[_client][msg.sender].frequency;
            pullPayments[_client][msg.sender].numberOfPayments = pullPayments[_client][msg.sender].numberOfPayments - 1;
        }
        token.transferFrom(_client, msg.sender, amountInPMA);

        pullPayments[_client][msg.sender].lastPaymentTimestamp = now;

        emit LogPullPaymentExecuted(_client, msg.sender, pullPayments[_client][msg.sender].paymentID);
    }

    function getRate(string _currency) public view returns(uint256) {
        return exchangeRates[_currency];
    }

    /// =================================================================================================================
    ///                                      Internal Functions
    /// =================================================================================================================

    /// @dev Calculates the PMA Rate for the fiat currency specified - The rate is being retrieved by the PumaPayOracle
    /// for the currency specified. The Oracle is being updated every minute for each different currency the our system supports.
    /// @param _fiatAmountInCents - payment amount in fiat CENTS so that is always integer
    /// @param _currency - currency in which the payment needs to take place
    /// RATE CALCULATION EXAMPLE
    /// ------------------------
    /// RATE ==> 1 PMA = 0.01 USD$
    /// 1 USD$ = 1/0.01 PMA = 100 PMA
    /// Start the calculation from one ether - PMA Token has 18 decimals
    /// Multiply by the DECIMAL_FIXER (1e+10) to fix the multiplication of the rate
    /// Multiply with the fiat amount in cents
    /// Divide by the Rate of PMA to Fiat in cents
    /// Divide by the FIAT_TO_CENT_FIXER to fix the _fiatAmountInCents
    function calculatePMAFromFiat(uint256 _fiatAmountInCents, string _currency)
    internal
    view
    returns (uint256) {
        return ONE_ETHER.mul(DECIMAL_FIXER).mul(_fiatAmountInCents).div(exchangeRates[_currency]).div(FIAT_TO_CENT_FIXER);
    }

    /// @dev Checks if a deletion request is valid by comparing the v, r, s params
    /// and the hashed params with the signatory address.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _client - client address that is linked to this pull payment.
    /// @param _beneficiary - address that is allowed to execute this pull payment.
    /// @param _pullPayment - pull payment to be validated.
    /// @return bool - if the v, r, s params with the hashed params match the signatory address
    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _client,
        address _beneficiary,
        PullPayment _pullPayment
    )
    internal
    pure
    returns(bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _beneficiary,
                    _pullPayment.currency,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.fiatAmountInCents,
                    _pullPayment.frequency,
                    _pullPayment.numberOfPayments,
                    _pullPayment.startTimestamp
                )
        ),
        v, r, s) == _client;
    }

    /// @dev Checks if a deletion request is valid by comparing the v, r, s params
    /// and the hashed params with the signatory address.
    /// @param v - recovery ID of the ETH signature. - https://github.com/ethereum/EIPs/issues/155
    /// @param r - R output of ECDSA signature.
    /// @param s - S output of ECDSA signature.
    /// @param _paymentID - ID of the payment.
    /// @param _client - client address that is linked to this pull payment.
    /// @param _beneficiary - address that is allowed to execute this pull payment.
    /// @return bool - if the v, r, s params with the hashed params match the signatory address
    function isValidDeletion(
        uint8 v,
        bytes32 r,
        bytes32 s,
        string _paymentID,
        address _client,
        address _beneficiary
    )
    internal
    view
    returns(bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _paymentID,
                    _beneficiary
                )
            ), v, r, s) == _client
            && keccak256(
                abi.encodePacked(pullPayments[_client][_beneficiary].paymentID)
                ) == keccak256(abi.encodePacked(_paymentID));
    }

    /// @dev Checks if a payment for a beneficiary of a client exists.
    /// @param _client - client address that is linked to this pull payment.
    /// @param _beneficiary - address to execute a pull payment.
    /// @return bool - whether the beneficiary for this client has a pull payment to execute.
    function doesPaymentExist(address _client, address _beneficiary)
    internal
    view
    returns(bool) {
        return (
            bytes(pullPayments[_client][_beneficiary].currency).length > 0 &&
            pullPayments[_client][_beneficiary].fiatAmountInCents > 0 &&
            pullPayments[_client][_beneficiary].frequency > 0 &&
            pullPayments[_client][_beneficiary].startTimestamp > 0 &&
            pullPayments[_client][_beneficiary].numberOfPayments > 0 &&
            pullPayments[_client][_beneficiary].nextPaymentTimestamp > 0
        );
    }
    
    /// @dev Checks if the address of an owner/executor needs to be funded. 
    /// The minimum amount the owner/executors should always have is 0.001 ETH 
    /// @param _address - address of owner/executors that the balance is checked against. 
    /// @return bool - whether the address needs more ETH.
    function isFundingNeeded(address _address) 
    private
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUN_OF_ETH_FOR_OPARATORS;
    }
}