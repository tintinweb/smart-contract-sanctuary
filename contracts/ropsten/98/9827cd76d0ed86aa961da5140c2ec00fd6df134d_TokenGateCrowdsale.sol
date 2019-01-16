pragma solidity 0.4.25;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: openzeppelin-solidity/contracts/lifecycle/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/PausableToken.sol

/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/CappedToken.sol

/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
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
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

// File: contracts/ico/TokenGateToken.sol

// here as example each project will create its own

contract TokenGateToken is CappedToken, PausableToken {

    event Unmint(address indexed from, uint256 amount);

    string public constant name = "TokenGateToken";
    string public constant symbol = "TGT";
    uint8 public constant decimals = 18;

    uint256 public constant ONE_TOKEN = (10 ** uint256(decimals));
    uint256 public constant MILLION_TOKENS = (10 ** 6) * ONE_TOKEN;
    
    // Per ico subject to change
    uint256 public constant TOTAL_CROWD_SALE_TOKENS = 65 * MILLION_TOKENS;

    // Note on return values of functions: it always returns true at the end of the function, so it is
    // possible to detect whether the function completed successfully when calling it over the web3. 
    // In case function fails, the return value will either be &#39;0x&#39; (for require routines without error message)
    // or in form &#39;0x<func signature><encoded error message as string>. In case the function succeeds,
    // it will return "0x00...001" to web3 (equivalent of true)
    
    constructor()
    public
    CappedToken(TOTAL_CROWD_SALE_TOKENS)
    {
        // token should not be transferable until after all tokens have been issued
        paused = true;
    }

    /**
     * @dev Function to take all tokens back from some investor
     * @param _from The address from which to withdraw all tokens
     * @return A boolean that indicates if the operation was successful.
     */
    function takeBackAllTokens(address _from) onlyOwner canMint public returns (bool)
    {
        return takeBackTokens(_from, balances[_from]);
    }

    /**
     * @dev Function to take a certain amount of tokens back from some investor
     * @param _from The address from which to withdraw all tokens
     * @param _amount How much tokens to take back
     * @return A boolean that indicates if the operation was successful.
     */
    function takeBackTokens(address _from, uint256 _amount) onlyOwner canMint public returns (bool)
    {
        require(_amount <= totalSupply_, "amount is greater than total supply");
        uint256 _balance = balances[_from];
        require(_amount <= _balance, "not enough tokens to take back");
        balances[_from] = balances[_from].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Unmint(_from, _amount);
        return true;
    }
}

// File: contracts/modifier/HasManager.sol

contract HasManager is Ownable {

    // allow managers to whitelist and confirm contributions by manager accounts
    // (managers can be set and altered by owner, multiple manager accounts are possible
    mapping (address => bool) public isManager;

    event ChangedManager(address indexed manager, bool active);

    /**
     * @dev Set / alter manager / whitelister "account". This can be done from owner only
     * @param manager address address of the manager to create/alter
     * @param active bool flag that shows if the manager account is active
     */
    function setManager(address manager, bool active) public onlyOwner {
        isManager[manager] = active;
        emit ChangedManager(manager, active);
    }

    modifier managerRole() {
        require(isManager[msg.sender], "sender is not a manager");
        _;
    }

}

// File: contracts/modifier/HasBank.sol

contract HasBank is Ownable {

    // banks can submit new payments
    mapping (address => bool) public isBank;

    event ChangedBank(address indexed bank, bool active);

    /**
     * @dev Set / alter bank / whitelister "account". This can be done from owner only
     * @param bank address address of the bank to create/alter
     * @param active bool flag that shows if the bank account is active
     */
    function setBank(address bank, bool active) public onlyOwner {
        isBank[bank] = active;
        emit ChangedBank(bank, active);
    }

    modifier bankRole() {
        require(isBank[msg.sender], "sender is not a bank");
        _;
    }
}

// File: contracts\ico\TokenGateCrowdsale.sol

contract TokenGateCrowdsale is Ownable, Pausable, HasManager, HasBank, Destructible {

    using SafeMath for uint256;

    event InvestorAdded(address indexed wallet);
    event InvestorRemoved(address indexed wallet);
    event PaymentEvent(bytes32 indexed paymentId, PaymentStatus status);
    event ExchangeRateEvent(uint _timestamp, uint256 _rateBTC, uint256 _rateETH);
    
    enum PaymentStatus { Verified, Cancelled, ErrorInvestorNotFound, ErrorNotTheSameInvestor,
        ErrorExceedsKycLimit, ErrorBelowMinInvest, ErrorNotStarted, ErrorHasEnded }

    uint8 constant public CURRENCY_TYPE_CHF = 0;
    uint8 constant public CURRENCY_TYPE_BTC = 1;
    uint8 constant public CURRENCY_TYPE_ETH = 2;
    
    uint256 constant ZERO = uint256(0);

    struct Payment {
        bytes32 refId;
        uint timestamp;
        uint256 amount;
        uint256 tokenAmount;
        uint8 currencyType;
        PaymentStatus status;
    }
    
    // refId => wallet mapping
    // refId: bitcoin addr, eth addr or bank ref id from which payment is expected
    // wallet is the address where generated tokens will be sent
    mapping(bytes32 => address) public investors;

    // wallet => kycLimit in tokens mapping
    mapping(address => uint256) public kycLimits;
    
    // paymentId => Payment mapping
    mapping(bytes32 => Payment) public payments;

    // how many tokens are received per unit currency (BTC and ETH)
    struct ExchangeRate {
        uint timestamp;
        uint256[2] rate;
    }
    
    ExchangeRate[] public exchangeRates;
    
    struct BonusStep {
        uint256 secondsSinceStart;
        uint256 bonusPercent;
    }
    
    BonusStep[] public bonuses;

    bool public finalized = false;

    uint public creationTime = now;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public pendingTime;
    
    ERC20 public token;
    
    uint256 public oneToken;
    
    // rate CHF is fixed at the beginning of ICO for its duration
    uint256 public rateCHF;
    
    // minimal allowed investment expressed in tokens
    uint256 public minInvestment;

    // keeping track of how much special tokens are allocated
    uint256 public teamTokensSum;
    uint256 public founderTokensSum;
    uint256 public privateSaleTokensSum;
    uint256 public referralTokensSum;
    
    /**
     * @param _startTime start time of the ICO
     * @param _endTime end time of the ICO
     * @param _pendingTime pending time after the ICO end
     * @param _managerAddress address of the manager account
     * @param _bankAddress address of the bank account
     * @param _token ERC20 token which is being controlled
     */
    constructor (
        uint256 _startTime,
        uint256 _endTime,
        uint256 _pendingTime,
        address _managerAddress,
        address _bankAddress,
        ERC20 _token)
    public
    Pausable()
    {
        require(_token != address(0), "token can not be 0x");
        require(_bankAddress != address(0), "bank address cannot be 0x");
        require(_managerAddress != address(0), "manager address cannot be 0x");
        require(_endTime > _startTime, "endTime must be bigger than startTme");
        require(_pendingTime > 0, "pendingTime must be > 0");
 
        setManager(_managerAddress, true);
        setBank(_bankAddress, true);

        token = _token;
        startTime = _startTime;
        endTime = _endTime;
        pendingTime = _pendingTime;
        
        oneToken = TokenGateToken(token).ONE_TOKEN();
        
        // *****************************
        // adjustable parameters per ICO
        // *****************************
        
        // rateCHF: how many tokens 1 CHF is worth
        uint256 rate = 1;
        rateCHF = rate.mul(oneToken);
        
        // minCHF - minimal investment in CHF
        uint256 minCHF = 5;
        // convert to tokens, because it&#39;s easier to work with it
        minInvestment = minCHF.mul(rateCHF);
        
        ///////////////////////////////////
        // BONUS IS STATICALLY DEFINED HERE
        ///////////////////////////////////
        BonusStep memory bonusStep1 = BonusStep(daysToSeconds(5), 25);
        BonusStep memory bonusStep2 = BonusStep(daysToSeconds(15), 15);
        BonusStep memory bonusStep3 = BonusStep(daysToSeconds(30), 10);
        
        bonuses.push(bonusStep1);
        bonuses.push(bonusStep2);
        bonuses.push(bonusStep3);
    }

    /**
     * @dev static distribution of team and founder tokens
     * supposed to be called only once after the token ownership is transferred
     * to the crowdsale
     */
    function allocateTeamFounderTokens() public managerRole {
        require(now < startTime, "ICO has started");
        require(teamTokensSum == 0, "team tokens are allocated already");
        require(founderTokensSum == 0, "founder tokens are allocated already");

        // no decimals - DON&#39;T MULTIPLY BY ONE TOKEN
        allocateTeamTokens(0x39683abdBA389Bad9d39Fadb82a45BC56244133f, 1000000);
        allocateTeamTokens(0x0C2b7A11e7Da363DaDD661228df6f1a4134e81be, 2000000);

        allocateFounderTokens(0x68Ca85DbF8EBA69Fb70ECDB78E0895F7Cd94Da83, 3000000);
        allocateFounderTokens(0x805A0eDC604C4b94265Bfa69266578F216a55add, 4000000);
    }

    /**
     * @dev allocates team tokens to an address (no kyc checks)
     * @param _addr address where to allocate tokens
     * @param _amount how much tokens to allocate
     */
    function allocateTeamTokens(address _addr, uint256 _amount) internal {
        uint256 tokenAmount = _amount.mul(oneToken);
        CappedToken(token).mint(_addr, tokenAmount);
        teamTokensSum = teamTokensSum.add(tokenAmount);
    }

    /**
     * @dev allocates founder tokens to an address (no kyc checks)
     * @param _addr address where to allocate tokens
     * @param _amount how much tokens to allocate
     */
    function allocateFounderTokens(address _addr, uint256 _amount) internal {
        uint256 tokenAmount = _amount.mul(oneToken);
        CappedToken(token).mint(_addr, tokenAmount);
        founderTokensSum = founderTokensSum.add(tokenAmount);
    }

    /**
     * @dev allocates private sale tokens to an address (no kyc checks)
     * @dev amount should be multiplied by oneToken
     * @param _addr address where to allocate tokens
     * @param _amount how much tokens to allocate
     */
    function allocatePrivateSaleTokens(address _addr, uint256 _amount) public managerRole {
        require(now < startTime, "ICO has started");
        CappedToken(token).mint(_addr, _amount);
        privateSaleTokensSum = privateSaleTokensSum.add(_amount);
    }
    
    /**
     * @dev calcs how many seconds are in days
     * @param _days days to converts to seconds
     */
    function daysToSeconds(uint _days) internal pure returns (uint) {
        return _days.mul(24 hours);
    }

    /**
     * @dev gets investor key in hash map based on refId and currency type
     * @param _refId one of investor accounts (btc, eth or bank)
     * @param _currencyType type of the account, 0 - chf, 1 - btc, 2 - eth
     */
    function getInvestorKey(bytes32 _refId, uint8 _currencyType) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_refId, _currencyType));
    }
    
    // Note on return values of functions: it always returns true at the end of the function, so it is
    // possible to detect whether the function completed successfully when calling it over the web3. 
    // In case function fails, the return value will either be &#39;0x&#39; (for require routines without error message)
    // or in form &#39;0x<func signature><encoded error message as string>. In case the function succeeds,
    // it will return "0x00...001" to web3 (equivalent of true)
    
    //
    // Investors
    //
    
    /**
     * @dev registers a new investor or updates existing one (e.g. kyc limit or new account)
     * @param _refIds an array of "mappings" where "mapping" array index == currency type and value is the refId
     * e.g. it expects at position 0 CHF account, 1 - BTC account and 2 - ETH account
     * pass the empty string if the user does not have the corresponding account
     * @param _wallet - wallet address of the investor which gets tokens
     * @param _kycLimit - max allowed investment amount in CHF*oneToken, 0 means unlimited
     */
    function addInvestor(bytes32[3][] _refIds, address _wallet, uint256 _kycLimit)
    public managerRole whenNotFinalized whenNotPaused returns (bool) {
        require(now < endTime, "crowdsale is already finished");
        require(_refIds.length > 0, "refs must be a non-empty array");
        require(_wallet != address(0), "wallet must have non-zero address");

        for (uint i = 0; i < _refIds.length; i++) {
            bytes32[3] memory ref = _refIds[i];
            for (uint j = 0; j < ref.length; j++) {
                // ignore unset values, they are treated as if the user does not have the corresponding account
                if (ref[j] == bytes32(0)) continue;

                bytes32 index = getInvestorKey(ref[j], uint8(j));

                address _curAddress = investors[index];
                require(_curAddress == address(0) || _curAddress == _wallet,
                    "refId already registered with a different wallet");

                // convert kycLimit in CHF to tokens
                (, uint256[3] memory _er) = getCurrentExchangeRate();
                // both kycLimit and exchange rate are multiplied by oneToken in order to keep the
                // precision. That&#39;s why it&#39;s necessary to divide by oneToken.
                uint256 kycLimitInTokens = _kycLimit.mul(_er[0]).div(oneToken);

                investors[index] = _wallet;
            }
        }
        
        kycLimits[_wallet] = kycLimitInTokens;

        emit InvestorAdded(_wallet);
        
        return true;
    }

    /**
     * @dev removes investor given his account numbers which should be position encoded
     * @param _refIds - same meaning as in addInvestor
     */
    function removeInvestor(bytes32[3][] _refIds) public onlyOwner whenNotFinalized whenNotPaused returns (bool) {
        address wallet = address(0);
        
        // this is to ensure that all refIds point to the same wallet
        for (uint i = 0; i < _refIds.length; i++) {
            bytes32[3] memory ref = _refIds[i];
            for (uint j = 0; j < ref.length; j++) {
                // ignore unset values, they are treated as if the user does not have the corresponding account
                if (ref[j] == bytes32(0)) continue;
                bytes32 index = getInvestorKey(ref[j], uint8(j));
                
                // the wallet var will be set only once
                if (wallet == address(0)) {
                    wallet = investors[index];
                }
                
                // the corresponding investor refId could have been already removed
                if (wallet == address(0)) continue;
                
                require(wallet == investors[index], "must be the same wallet for all refIds");

                investors[index] = address(0);
                kycLimits[wallet] = 0;
            }
        }

        // wallet can be 0 if all investors are removed, so the balance is also 0
        TokenGateToken(token).takeBackAllTokens(wallet);
        emit InvestorRemoved(wallet);
        return true;
    }
 
    /**
     * @dev returns investor wallet by account and account type
     * @param _refId - account
     * @param _currencyType - 0 - CHF account, 1 - BTC account and 2 - ETH account
     */
    function getInvestor(bytes32 _refId, uint8 _currencyType) public view returns (address) {
        return investors[getInvestorKey(_refId, _currencyType)];
    }

    /**
     * @dev returns kyc limit for an investor
     * @param _refId - account
     * @param _currencyType - 0 - CHF account, 1 - BTC account and 2 - ETH account
     */
    function getInvestorKycLimit(bytes32 _refId, uint8 _currencyType) public view returns (uint256) {
        address wallet = investors[getInvestorKey(_refId, _currencyType)];
        return kycLimits[wallet];
    }
    
    //
    // Exchange rate
    //
    
    /**
     * @dev provides a new exchange rate
     * @param _timestamp - time of the exchange rate
     * @param _rateBTC - how much token is worth in BTC multiplied by token decimals
     * @param _rateETH - how much token is worth in ETH multiplied by token decimals
     */
    function provideExchangeRate(
        uint256 _timestamp,
        uint256 _rateBTC,
        uint256 _rateETH) 
    public managerRole whenNotFinalized whenNotPaused returns (bool) {
        require(exchangeRates.length == 0 || exchangeRates[exchangeRates.length - 1].timestamp < _timestamp,
            "ts must be greater than the latest ts");
        require(_rateBTC > 0 && _rateETH > 0, "exchange rates must be positive");

        ExchangeRate memory rate = ExchangeRate(_timestamp, [_rateBTC, _rateETH]);
        exchangeRates.push(rate);
        
        emit ExchangeRateEvent(_timestamp, _rateBTC, _rateETH);
        
        return true;
    }

    /**
     * @return currently valid exchange rate 
     */
    function getCurrentExchangeRate() public view 
    returns (uint ts, uint256[3] rate) {
        if (exchangeRates.length == 0) return (now, [rateCHF, ZERO, ZERO]);
        ExchangeRate memory er = exchangeRates[exchangeRates.length - 1];
        return (now, [rateCHF, er.rate[CURRENCY_TYPE_BTC - 1], er.rate[CURRENCY_TYPE_ETH - 1]]);
    }

    /**
     * @return exchange rate valid at a certain time
     * @param _timestamp time to return exchange rate for
     */
    function getExchangeRateAtTime(uint _timestamp) public view
    returns (uint ts, uint256[3] rate) {
        if (exchangeRates.length == 0) return (_timestamp, [rateCHF, ZERO, ZERO]);
        for (uint j = 0; j <= exchangeRates.length - 1; j++) {
            uint i = exchangeRates.length - j - 1;
            if (_timestamp >= exchangeRates[i].timestamp) {
                ExchangeRate memory er = exchangeRates[i];
                return (_timestamp, [rateCHF, er.rate[CURRENCY_TYPE_BTC - 1], er.rate[CURRENCY_TYPE_ETH - 1]]);
            }
        }
        return (_timestamp, [rateCHF, ZERO, ZERO]);
    }
    
    /**
     * @return exchange rate array length
     */
    function getExchangeRatesLength() public view returns (uint) {
        return exchangeRates.length;
    }

    //
    // Bonus
    //

    /**
     * @param _timestamp desired time
     * @return bonus valid for a certain time
     */
    function getBonusAtTime(uint _timestamp) public view
    returns (uint256 curBonus, uint256 changeTime, uint256 nextBonus) {
        for (uint8 i = 0; i < bonuses.length; i++) {
            uint256 bonusChangeTime = bonuses[i].secondsSinceStart + startTime;
            if (_timestamp <= bonusChangeTime) {
                uint256 _nextBonus = 0;
                if (i + 1 < bonuses.length) {
                    _nextBonus = bonuses[i + 1].bonusPercent;
                }
                return (bonuses[i].bonusPercent, bonusChangeTime, _nextBonus);
            }
        }

        return (ZERO, ZERO, ZERO);
    }

    /**
     * @return currently active bonus
     */
    function getCurrentBonus() public view
    returns (uint256 curBonus, uint bonusChangeTime, uint256 nextBonus) {
        return getBonusAtTime(now);
    }

    /**
     * @return bonus array length
     */
    function getBonusLength() public view returns (uint) {
        return bonuses.length;
    }

    //
    // Payments
    //

    function allocateTokens(Payment storage _payment, address _investor) internal {
        (, uint256[3] memory er) = getExchangeRateAtTime(_payment.timestamp);
        require(er[_payment.currencyType] > 0, "exchange rate must be positive");
        // both amount and exchange rate are multiplied by oneToken in order to keep the
        // precision. That&#39;s why it&#39;s necessary to divide by oneToken.
        _payment.tokenAmount = _payment.amount.mul(er[_payment.currencyType]).div(oneToken);
        
        // now we know how many tokens is going to be allocated and can check the minInvest and KYC limit
        if (_payment.tokenAmount < minInvestment) {
            _payment.status = PaymentStatus.ErrorBelowMinInvest;
        } else if (kycLimits[_investor] > 0 &&
            kycLimits[_investor] < CappedToken(token).balanceOf(_investor).add(_payment.tokenAmount)) {
            _payment.status = PaymentStatus.ErrorExceedsKycLimit;
            _payment.tokenAmount = 0;
        } else {
            (uint256 bonus, ,) = getBonusAtTime(_payment.timestamp);
            _payment.tokenAmount = _payment.tokenAmount.add(bonus.mul(_payment.tokenAmount).div(100));

            CappedToken(token).mint(_investor, _payment.tokenAmount);
        }
    }

    /**
     * @dev submit a new payment
     * @param _paymentId unique id for this payment
     * @param _refIds - for Ethereum, this is one sender address. In Bitcoin, there can be several transaction
     * inputs associated with different addresses of the sender. Each address must be registered in smart contract,
     * only one refId will be saved as Payment.
     * @param _timestamp timestamp of the payment
     * @param _amount payment amount multimplied by decimals
     * @param _currencyType 0 - chf, 1 - btc, 2 - eth
     */
    function submitPayment(
        bytes32 _paymentId,
        bytes32[] _refIds,
        uint256 _timestamp,
        uint256 _amount,
        uint8 _currencyType
    ) public bankRole whenNotFinalized whenNotPaused returns (bool) {
        require(_timestamp <= now, "payment cannot be in the future");
        require(_amount > 0, "payment amount must be positive");
        require(payments[_paymentId].timestamp == 0, "payment already registered");
        require(_refIds.length > 0, "refIds must not be empty");

        PaymentStatus status = PaymentStatus.Verified;

        if (_timestamp < startTime) {
            status = PaymentStatus.ErrorNotStarted;
        } else if (_timestamp > endTime) {
            status = PaymentStatus.ErrorHasEnded;
        }

        payments[_paymentId] = Payment(
            _refIds[0],
            _timestamp,
            _amount,
            0,
            _currencyType,
            status);

        Payment storage payment = payments[_paymentId];

        bytes32 index = getInvestorKey(_refIds[0], _currencyType);
        address investor = investors[index];
        for (uint8 i = 1; i < _refIds.length; i++) {
            index = getInvestorKey(_refIds[i], _currencyType);
            
            if (investor != investors[index]) {
                // don&#39;t reset the existing error if set
                if (payment.status == PaymentStatus.Verified) {
                    payment.status = PaymentStatus.ErrorNotTheSameInvestor;
                }
            }
        }

        if (investor == address(0)) {
            // don&#39;t reset the existing error if set
            if (payment.status == PaymentStatus.Verified) {
                payment.status = PaymentStatus.ErrorInvestorNotFound;
            }
        } else if (payment.status == PaymentStatus.Verified) {
            allocateTokens(payment, investor);
        }
        
        emit PaymentEvent(_paymentId, payment.status);
        
        return true;
    }

    function setPaymentStatus(bytes32 _paymentId, PaymentStatus status)
    public managerRole whenNotFinalized whenNotPaused returns (bool) {
        Payment storage payment = payments[_paymentId];
        require(payment.timestamp > 0, "payment not found");
        require(payment.status != status, "status already set");

        PaymentStatus prevStatus = payment.status;
        payment.status = status;
        
        address investor = investors[getInvestorKey(payment.refId, payment.currencyType)];
        require(investor != address(0), "investor not found by payment refid");

        if (prevStatus == PaymentStatus.Verified) {
            TokenGateToken(token).takeBackTokens(investor, payment.tokenAmount);
        } else if (status == PaymentStatus.Verified) {
            allocateTokens(payment, investor);
        }

        emit PaymentEvent(_paymentId, payment.status);
        
        return true;
    }
    
    //
    // Finalize
    //

    /**
     * @dev finalize crowdsale and transfer ownership of token to owner
     */
    function finalize() public onlyOwner {
        require(now > endTime + pendingTime, "pending time is not elapsed yet");

        CappedToken(token).finishMinting();
        
        Pausable(token).unpause();
        
        finalized = true;

        // until now the owner of the token is this crowd sale contract
        // in order for a human owner to make use of the tokens onlyOwner functions
        // we need to transfer the ownership
        // in the end the owner of this crowd sale will also be the owner of the token
        Ownable(token).transferOwnership(owner);
    }

    modifier whenNotFinalized() {
        require(!finalized, "is already finalized");
        _;
    }
}