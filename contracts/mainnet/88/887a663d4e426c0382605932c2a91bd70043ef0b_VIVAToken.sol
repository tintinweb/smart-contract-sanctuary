pragma solidity ^0.4.18;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}




contract Administrated is Ownable {

  mapping(address => bool) internal admins;

  function Administrated() public {
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender));
    _;
  }

  function setAdmin(address _admin, bool _isAdmin) public {
    require(_admin != address(0));
    require(msg.sender == owner || admins[msg.sender] == true);
    admins[_admin] = _isAdmin;
  }

  function isAdmin(address _address) public view returns (bool) {
    return admins[_address];
  }

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
    totalSupply_ = totalSupply_.add(_amount);
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



/**
 * @title Capped token
 * @dev Mintable token with a token cap.
 */
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}



/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}



contract VIVAToken is CappedToken, PausableToken {

  using SafeERC20 for ERC20;

  string public name = "VIVA Token";
  string public symbol = "VIVA";
  uint8 public decimals = 18;

  function VIVAToken(uint256 _cap) public
    CappedToken(_cap * 10**18)
    PausableToken() { }

}







library CrowdsaleTokenUtils {

  // Events
  event MintTokens(address beneficiary, uint256 tokens);

  using SafeMath for uint256;

  function mintTokens(VIVAToken token, address beneficiary, uint256 tokens) public returns (bool) {
    require(beneficiary != address(0));
    require(tokens > 0);
    MintTokens(beneficiary, tokens);
    return token.mint(beneficiary, tokens);
  }

}



contract Testable is Ownable {

  bool internal testing;
  uint256 public _now;

  function Testable(bool _testing) public {
    testing = _testing;
    _now = now;
  }

  modifier whenTesting() {
    require(testing);
    _;
  }

  function getNow() public view returns (uint256) {
    if(testing) {
      return _now;
    } else {
      return now;
    }
  }

  function setNow(uint256 __now) public onlyOwner whenTesting {
    _now = __now;
  }

}




// Not a generalized vesting contract - just our compensation protocol
contract VIVAVestingVault is Administrated, Testable {

  using SafeMath for uint256;

  event Released(address beneficiary, uint256 amount);

  VIVAToken public token;

  uint256 public d1;
  uint256 public d2;

  mapping(address => uint256) internal totalDue;
  mapping(address => uint256) internal released;

  function VIVAVestingVault(
    VIVAToken _token,
    uint256 _d1,
    uint256 _d2,
    bool _testing
  ) public
    Testable(_testing) {
    token = _token;
    d1 = _d1;
    d2 = _d2;
  }

  function register(address beneficiary, uint256 due) public onlyAdmin {
    require(beneficiary != address(0));
    require(due >= released[beneficiary]);
    totalDue[beneficiary] = due;
  }

  function release(address beneficiary, uint256 tokens) public {
    require(beneficiary != address(0));
    require(tokens > 0);
    uint256 releasable = releasableAmount(beneficiary);
    require(releasable > 0);
    uint256 toRelease = releasable;
    require(releasable >= tokens);
    if(tokens < releasable) {
      toRelease = tokens;
    }
    require(token.balanceOf(this) >= toRelease);
    assert(released[beneficiary].add(toRelease) <= totalDue[beneficiary]);
    released[beneficiary] = released[beneficiary].add(toRelease);
    assert(token.transfer(beneficiary, toRelease));
    Released(beneficiary, toRelease);
  }

  function releasableAmount(address beneficiary) public view returns (uint256) {
    uint256 vestedAmount;
    if (getNow() < d1) {
      vestedAmount = 0;
    } else if (getNow() < d2) {
      vestedAmount = totalDue[beneficiary].div(2);
    } else {
      if(isAdmin(msg.sender)) {
        vestedAmount = totalDue[beneficiary];
      } else {
        vestedAmount = totalDue[beneficiary].div(2);
      }
    }
    return vestedAmount.sub(released[beneficiary]);
  }

  function setSchedule(uint256 _d1, uint256 _d2) public onlyAdmin {
    require(_d1 <= _d2);
    d1 = _d1;
    d2 = _d2;
  }

}












contract VIVACrowdsaleRound is Ownable, Testable {

  using SafeMath for uint256;

  struct Bonus {
    uint256 tier;
    uint256 rate;
  }

  bool public refundable;
  uint256 public capAtWei;
  uint256 public capAtDuration;

  Bonus[] bonuses;

  function VIVACrowdsaleRound(
    bool _refundable,
    uint256 _capAtWei,
    uint256 _capAtDuration,
    bool _testing
  ) Testable(_testing) public {
    refundable = _refundable;
    capAtWei = _capAtWei;
    capAtDuration = _capAtDuration;
  }

  function addBonus(uint256 tier, uint256 rate) public onlyOwner {
    Bonus memory bonus;
    bonus.tier = tier;
    bonus.rate = rate;
    bonuses.push(bonus);
  }

  function setCapAtDuration(uint256 _capAtDuration) onlyOwner public returns (uint256) {
    capAtDuration = _capAtDuration;
  }

  function setCapAtWei(uint256 _capAtWei) onlyOwner whenTesting public {
    capAtWei = _capAtWei;
  }

  function getBonusRate(uint256 baseRate, uint256 weiAmount) public view returns (uint256) {
    uint256 r = baseRate;
    for(uint i = 0; i < bonuses.length; i++) {
      if(weiAmount >= bonuses[i].tier) {
        r = bonuses[i].rate;
      } else {
        break;
      }
    }
    return r;
  }

}










/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


contract VIVARefundVault is RefundVault {

  function VIVARefundVault(
    address _wallet
  ) RefundVault(_wallet) public { }

  function setWallet(address _wallet) onlyOwner public {
    require(state == State.Active);
    require(_wallet != address(0));
    wallet = _wallet;
  }

  function getWallet() public view returns (address) {
    return wallet;
  }

}



contract VIVACrowdsaleData is Administrated {

  using SafeMath for uint256;

  // Events
  event MintTokens(address beneficiary, uint256 tokens);

  event CloseRefundVault(bool refund);
  event Finalize(address tokenOwner, bool refundable);
  event RegisterPrivateContribution(address beneficiary, uint256 tokens);
  event RegisterPurchase(VIVACrowdsaleRound round, address beneficiary, uint256 tokens, uint256 weiAmount);
  event UnregisterPurchase(address beneficiary, uint256 tokens, uint256 weiAmount);

  VIVAToken public token;

  uint256 public startTime;

  bool public isFinalized = false;

  VIVACrowdsaleRound[] public rounds;

  // Main fund collection (refundable)
  address public wallet;
  VIVARefundVault public refundVault;
  bool public refundVaultClosed = false;

  // Distribution vaults
  address public bountyVault;
  address public reserveVault;
  address public teamVault;
  address public advisorVault;

  // Track general sale progress
  uint256 public privateContributionTokens;
  mapping(address => uint256) internal weiContributed;
  uint256 public mintedForSaleTokens; // Total general sale tokens minted
  uint256 public weiRaisedForSale;

  // Verified investors only for > 7ETH (must be pre-approved)
  uint256 public largeInvestorWei = 7000000000000000000; // 7 ETH
  mapping(address => uint256) internal approvedLargeInvestors; // And their authorized limits

  function VIVACrowdsaleData(
    VIVAToken _token,
    address _wallet,
    uint256 _startTime
  )  public {
      require(_token != address(0));
      require(_wallet != address(0));
      token = _token;
      wallet = _wallet;
      startTime = _startTime;
      refundVault = new VIVARefundVault(_wallet);
  }

  function getNumRounds() public view returns (uint256) {
    return rounds.length;
  }

  function addRound(VIVACrowdsaleRound round) public onlyAdmin {
    require(address(round) != address(0));
    rounds.push(round);
  }

  function removeRound(uint256 i) public onlyAdmin {
    while (i < rounds.length - 1) {
      rounds[i] = rounds[i+1];
      i++;
    }
    rounds.length--;
  }

  function setStartTime(uint256 _startTime) public onlyAdmin {
    startTime = _startTime;
  }

  function mintTokens(address beneficiary, uint256 tokens) public onlyAdmin returns (bool) {
    return CrowdsaleTokenUtils.mintTokens(token, beneficiary, tokens);
  }

  function registerPrivateContribution(address beneficiary, uint256 tokens) public onlyAdmin returns (bool) {
    require(beneficiary != address(0));
    privateContributionTokens = privateContributionTokens.add(tokens);
    RegisterPrivateContribution(beneficiary, tokens);
    return true;
  }

  function registerPurchase(VIVACrowdsaleRound round, address beneficiary, uint256 tokens) public payable onlyAdmin returns (bool) {
    require(address(round) != address(0));
    require(beneficiary != address(0));
    if(round.refundable()) {
      refundVault.deposit.value(msg.value)(beneficiary);
    } else {
      wallet.transfer(msg.value);
    }
    weiContributed[beneficiary] = msg.value.add(weiContributed[beneficiary]);
    weiRaisedForSale = weiRaisedForSale.add(msg.value);
    mintedForSaleTokens = mintedForSaleTokens.add(tokens);
    RegisterPurchase(round, beneficiary, tokens, msg.value);
    return true;
  }

  function getWeiContributed(address from) public view returns (uint256) { return weiContributed[from];  }

  function closeRefundVault(bool refund) public onlyAdmin {
    require(!refundVaultClosed);
    refundVaultClosed = true;
    if(refund) {
      refundVault.enableRefunds();
    } else {
      refundVault.close();
    }
    CloseRefundVault(refund);
  }

  function finalize(address tokenOwner, bool refundable) public onlyAdmin {
    require(tokenOwner != address(0));
    require(!isFinalized);
    isFinalized = true;
    if(!refundVaultClosed) {
      closeRefundVault(refundable);
    }
    token.finishMinting();
    token.transferOwnership(tokenOwner);
    Finalize(tokenOwner, refundable);
  }

  function setWallet(address _wallet) public onlyAdmin {
    require(_wallet != address(0));
    wallet = _wallet;
    refundVault.setWallet(_wallet);
  }

  function setLargeInvestorWei(uint256 _largeInvestorWei) public onlyAdmin {
    require(_largeInvestorWei >= 0);
    largeInvestorWei = _largeInvestorWei;
  }

  function getLargeInvestorApproval(address beneficiary) public view returns (uint256) {
    require(beneficiary != address(0));
    return approvedLargeInvestors[beneficiary];
  }

  function setLargeInvestorApproval(address beneficiary, uint256 weiLimit) public onlyAdmin {
    require(beneficiary != address(0));
    require(weiLimit >= largeInvestorWei);
    approvedLargeInvestors[beneficiary] = weiLimit;
  }

  function setBountyVault(address vault) public onlyAdmin  { bountyVault = vault;  }
  function setReserveVault(address vault) public onlyAdmin { reserveVault = vault; }
  function setTeamVault(address vault) public onlyAdmin    { teamVault = vault;    }
  function setAdvisorVault(address vault) public onlyAdmin { advisorVault = vault; }

}







contract VIVAVault is Administrated {

  using SafeMath for uint256;

  event Released(address beneficiary, uint256 amount);

  VIVAToken public token;

  function VIVAVault(
    VIVAToken _token
  ) public {
    token = _token;
  }

  function release(address beneficiary, uint256 amount) public onlyAdmin {
    require(beneficiary != address(0));
    require(amount > 0);

    uint256 releasable = releasableAmount(beneficiary);
    require(releasable > 0);
    require(token.balanceOf(this) >= releasable);
    require(amount <= releasable);

    assert(token.transfer(beneficiary, amount));

    Released(beneficiary, amount);
  }

  function releasableAmount(address beneficiary) public view returns (uint256) {
    require(beneficiary != address(0));
    // Any other restrictions we want
    return token.balanceOf(this);
  }

}








library VaultUtils {

  using SafeMath for uint256;

  function createVestingVault(VIVACrowdsaleData data, address admin, uint256 tokens, uint256 d1, uint256 d2, bool testing) public returns (VIVAVestingVault) {
    require(admin != address(0));
    VIVAVestingVault vault = new VIVAVestingVault(data.token(), d1, d2, testing);
    vault.setAdmin(admin, true);
    assert(data.mintTokens(address(vault), tokens));
    return vault;
  }

  function createVault(VIVACrowdsaleData data, address admin, uint256 tokens) public returns (VIVAVault) {
    require(admin != address(0));
    VIVAVault vault = new VIVAVault(data.token());
    vault.setAdmin(admin, true);
    assert(data.mintTokens(address(vault), tokens));
    return vault;
  }

}








library CrowdsaleUtils {

  using SafeMath for uint256;

  function getCurrentRound(VIVACrowdsaleData data, uint256 valuationDate, uint256 weiRaisedForSale) public view returns (VIVACrowdsaleRound) {
    uint256 time = data.startTime();
    bool hadTimeRange = false;
    for(uint i = 0; i < data.getNumRounds(); i++) {
      bool inTimeRange = valuationDate >= time && valuationDate < time.add(data.rounds(i).capAtDuration());
      bool inCapRange = weiRaisedForSale < data.rounds(i).capAtWei();
      if(inTimeRange) {
        if(inCapRange) {
          return data.rounds(i);
        }
        hadTimeRange = true;
      } else {
        if(hadTimeRange) {
          if(inCapRange) {
            return data.rounds(i);
          }
        }
      }
      time = time.add(data.rounds(i).capAtDuration());
    }
  }

  function validPurchase(VIVACrowdsaleData data, VIVACrowdsaleRound round, address beneficiary, uint256 weiAmount, uint256 tokens, uint256 minContributionWeiAmount, uint256 tokensForSale) public view returns (bool) {
    // Crowdsale must be active
    if(address(round) == address(0)) {
      return false;
    }
    if(data.isFinalized()) {
      return false;
    }

    // Ensure exceeds min contribution size
    if(weiAmount < minContributionWeiAmount) {
      return false;
    }
    if(tokens <= 0) {
      return false;
    }

    // Ensure we have enough tokens left for sale
    if(tokens.add(data.mintedForSaleTokens()) > tokensForSale) {
      return false;
    }

    // Ensure cap not exceeded
    if(weiAmount.add(data.weiRaisedForSale()) > round.capAtWei()) {
      return false;
    }

    uint256 contributed = weiAmount.add(data.getWeiContributed(beneficiary));
    // Ensure large investors are approved
    if(contributed > data.largeInvestorWei()) {
      if(data.getLargeInvestorApproval(beneficiary) < contributed) {
        return false;
      }
    }

    // It&#39;s valid!
    return true;
  }

}
















contract VIVACrowdsale is Administrated, Testable {

  using SafeMath for uint256;

  // Events (more bubble up from VIVACrowdsaleData)
  event Cancelled();
  event Debug(uint256 value);

  // ms time constants
  uint256 public constant SECOND = 1000;
  uint256 public constant MINUTE = SECOND * 60;
  uint256 public constant HOUR = MINUTE * 60;
  uint256 public constant DAY = HOUR * 24;
  uint256 public constant WEEK = DAY * 7;

  // Crowdsale data store separated from logic
  VIVACrowdsaleData public data;

  // ===== Main TGE Parameters (Constant) =================================================
  uint256 public constant baseRate                 = 35714;
  uint256 public constant minContributionWeiAmount = 1000000000000000;
  uint256 public constant tokensPrivateInvesting   = 50000000 * 10**18;
  uint256 public constant tokensMarketing          = 500000000 * 10**18;
  uint256 public constant tokensTeam               = 300000000 * 10**18;
  uint256 public constant tokensAdvisor            = 150000000 * 10**18;
  uint256 public constant tokensBounty             = 50000000 * 10**18;
  uint256 public constant tokensReserved           = 400000000 * 10**18;
  uint256 public constant tokensForSale            = 3000000000 * 10**18;
  // ======================================================================================

  function VIVACrowdsale(
    VIVACrowdsaleData _data,
    bool _testing
  ) Testable(_testing) public {
      require(_data != address(0));
      data = _data;
  }

  function privateContribution(address beneficiary, uint256 tokens) public onlyAdmin {
    require(beneficiary != address(0));
    require(tokens > 0);
    require(!data.isFinalized());
    require(tokens.add(data.privateContributionTokens()) <= tokensPrivateInvesting.add(tokensMarketing));
    assert(data.registerPrivateContribution(beneficiary, tokens));
    assert(data.mintTokens(beneficiary, tokens));
  }

  function getTokenAmount(VIVACrowdsaleRound round, uint256 weiAmount) public view returns(uint256) {
    require(address(round) != address(0));
    if(weiAmount == 0) return 0;
    return weiAmount.mul(round.getBonusRate(baseRate, weiAmount));
  }

  function () external payable {
    buyTokens();
  }

  function buyTokens() public payable {
    require(!data.isFinalized());
    VIVACrowdsaleRound round = getCurrentRound(getNow(), data.weiRaisedForSale());
    require(address(round) != address(0));
    uint256 tokens = getTokenAmount(round, msg.value);
    require(CrowdsaleUtils.validPurchase(data, round, msg.sender, msg.value, tokens, minContributionWeiAmount, tokensForSale));
    assert(data.registerPurchase.value(msg.value)(round, msg.sender, tokens));
    assert(data.mintTokens(msg.sender, tokens));
  }

  function getCurrentRound(uint256 valuationDate, uint256 weiRaisedForSale) public view returns (VIVACrowdsaleRound) {
    return CrowdsaleUtils.getCurrentRound(data, valuationDate, weiRaisedForSale);
  }

  function cancel() onlyAdmin public {
    require(!data.isFinalized());
    data.finalize(msg.sender, true);
    Cancelled();
  }

  function finalize() onlyAdmin public {
    require(!data.isFinalized());
    data.setBountyVault(VaultUtils.createVault(data, msg.sender, tokensBounty));
    data.setReserveVault(VaultUtils.createVault(data, msg.sender, tokensReserved));
    data.setTeamVault(VaultUtils.createVestingVault(data, msg.sender, tokensTeam, getNow() + (365 * DAY), getNow() + (365 * DAY), testing));
    data.setAdvisorVault(VaultUtils.createVestingVault(data, msg.sender, tokensAdvisor, getNow() + (30 * DAY), getNow() + (90 * DAY), testing));
    data.finalize(msg.sender, false);
    // Unsold tokens are burnt (i.e. never minted)
  }

}