pragma solidity ^0.4.13;

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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _revocable whether the vesting is revocable or not
   */
  function TokenVesting(address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable) public {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (now < cliff) {
      return 0;
    } else if (now >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(now.sub(start)).div(duration);
    }
  }
}

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
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

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint internal returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
}

contract SafePayloadChecker {
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length == size + 4);
    _;
  }
}

contract PATH is MintableToken, BurnableToken, SafePayloadChecker {
  /**
   * @dev the original supply, for posterity, since totalSupply will decrement on burn
   */
  uint256 public initialSupply = 400000000 * (10 ** uint256(decimals));

  /**
   * ERC20 Identification Functions
   */
  string public constant name    = "PATH Token"; // solium-disable-line uppercase
  string public constant symbol  = "PATH"; // solium-disable-line uppercase
  uint8 public constant decimals = 18; // solium-disable-line uppercase

  /**
   * @dev the time at which token holders can begin transferring tokens
   */
  uint256 public transferableStartTime;

  address privatePresaleWallet;
  address publicPresaleContract;
  address publicCrowdsaleContract;
  address pathTeamMultisig;
  TokenVesting public founderTokenVesting;

  /**
   * @dev the token sale contract(s) and team can move tokens
   * @dev   before the lockup expires
   */
  modifier onlyWhenTransferEnabled()
  {
    if (now <= transferableStartTime) {
      require(
        msg.sender == privatePresaleWallet || // solium-disable-line operator-whitespace
        msg.sender == publicPresaleContract || // solium-disable-line operator-whitespace
        msg.sender == publicCrowdsaleContract || // solium-disable-line operator-whitespace
        msg.sender == pathTeamMultisig
      );
    }
    _;
  }

  /**
   * @dev require that this contract cannot affect itself
   */
  modifier validDestination(address _addr)
  {
    require(_addr != address(this));
    _;
  }

  /**
   * @dev Constructor
   */
  function PATH(uint256 _transferableStartTime)
    public
  {
    transferableStartTime = _transferableStartTime;
  }

  /**
   * @dev override transfer token for a specified address to add validDestination
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value)
    onlyPayloadSize(32 + 32) // address (32) + uint256 (32)
    validDestination(_to)
    onlyWhenTransferEnabled
    public
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  /**
   * @dev override transferFrom token for a specified address to add validDestination
   * @param _from The address to transfer from.
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transferFrom(address _from, address _to, uint256 _value)
    onlyPayloadSize(32 + 32 + 32) // address (32) + address (32) + uint256 (32)
    validDestination(_to)
    onlyWhenTransferEnabled
    public
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev burn tokens, but also include a Transfer(sender, 0x0, value) event
   * @param _value The amount to be burned.
   */
  function burn(uint256 _value)
    onlyWhenTransferEnabled
    public
  {
    super.burn(_value);
  }

  /**
   * @dev burn tokens on behalf of someone
   * @param _from The address of the owner of the token.
   * @param _value The amount to be burned.
   */
  function burnFrom(address _from, uint256 _value)
    onlyPayloadSize(32 + 32) // address (32) + uint256 (32)
    onlyWhenTransferEnabled
    public
  {
    require(_value <= allowed[_from][msg.sender]);
    require(_value <= balances[_from]);

    balances[_from] = balances[_from].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(_from, _value);
    Transfer(_from, address(0), _value);
  }

  /**
   * @dev override approval functions to include safe payload checking
   */
  function approve(address _spender, uint256 _value)
    onlyPayloadSize(32 + 32) // address (32) + uint256 (32)
    public
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint256 _addedValue)
    onlyPayloadSize(32 + 32) // address (32) + uint256 (32)
    public
    returns (bool)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue)
    onlyPayloadSize(32 + 32) // address (32) + uint256 (32)
    public
    returns (bool)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }


  /**
   * @dev distribute the tokens once the crowdsale addresses are known
   * @dev only callable once and disables minting at the end
   */
  function distributeTokens(
    address _privatePresaleWallet,
    address _publicPresaleContract,
    address _publicCrowdsaleContract,
    address _pathCompanyMultisig,
    address _pathAdvisorVault,
    address _pathFounderAddress
  )
    onlyOwner
    canMint
    external
  {
    // Set addresses
    privatePresaleWallet = _privatePresaleWallet;
    publicPresaleContract = _publicPresaleContract;
    publicCrowdsaleContract = _publicCrowdsaleContract;
    pathTeamMultisig = _pathCompanyMultisig;

    // Mint all tokens according to the established allocations
    mint(_privatePresaleWallet, 200000000 * (10 ** uint256(decimals)));
    // ^ 50%
    mint(_publicPresaleContract, 32000000 * (10 ** uint256(decimals)));
    // ^ 8%
    mint(_publicCrowdsaleContract, 8000000 * (10 ** uint256(decimals)));
    // ^ 2%
    mint(_pathCompanyMultisig, 80000000 * (10 ** uint256(decimals)));
    // ^ 20%
    mint(_pathAdvisorVault, 40000000 * (10 ** uint256(decimals)));
    // ^ 10%

    // deploy a token vesting contract for the founder tokens
    uint256 cliff = 6 * 4 weeks; // 4 months
    founderTokenVesting = new TokenVesting(
      _pathFounderAddress,
      now,   // start vesting now
      cliff, // cliff time
      cliff, // 100% unlocked at cliff
      false  // irrevocable
    );
    // and then mint tokens to the vesting contract
    mint(address(founderTokenVesting), 40000000 * (10 ** uint256(decimals)));
    // ^ 10%

    // immediately finish minting
    finishMinting();

    assert(totalSupply_ == initialSupply);
  }
}

contract StandardCrowdsale {
  using SafeMath for uint256;

  // The token being sold
  PATH public token;  // Path Modification

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;

  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  function StandardCrowdsale(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    PATH _token
  )
    public
  {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // fallback function can be used to buy tokens
  function () external payable {
    buyTokens(msg.sender);
  }

  // low level token purchase function
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    require(token.transfer(beneficiary, tokens)); // PATH Modification

    TokenPurchase(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // Override this method to have a way to add business logic to your crowdsale when buying
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  // @return true if the transaction can buy tokens
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
}

contract FinalizableCrowdsale is StandardCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

contract BurnableCrowdsale is FinalizableCrowdsale {
  /**
   * @dev Burns any tokens held by this address.
   */
  function finalization() internal {
    token.burn(token.balanceOf(address(this)));
    super.finalization();
  }
}

contract RateConfigurable is StandardCrowdsale, Ownable {

  modifier onlyBeforeStart() {
    require(now < startTime);
    _;
  }

  /**
   * @dev allow the owner to update the rate before the crowdsale starts
   * @dev in order to account for ether valuation fluctuation
   */
  function updateRate(uint256 _rate)
    onlyOwner
    onlyBeforeStart
    external
  {
    rate = _rate;
  }
}

contract ReallocatableCrowdsale is StandardCrowdsale, Ownable {

  /**
   * @dev reallocate funds from this crowdsale to another
   */
  function reallocate(uint256 _value)
    external
    onlyOwner
  {
    require(!hasEnded());
    reallocation(_value);
  }

  /**
   * @dev perform the actual reallocation
   * @dev must be overridden to do anything
   */
  function reallocation(uint256 _value)
    internal
  {
  }
}

contract WhitelistedCrowdsale is StandardCrowdsale, Ownable {

  mapping(address=>bool) public registered;

  event RegistrationStatusChanged(address target, bool isRegistered);

  /**
    * @dev Changes registration status of an address for participation.
    * @param target Address that will be registered/deregistered.
    * @param isRegistered New registration status of address.
    */
  function changeRegistrationStatus(address target, bool isRegistered)
    public
    onlyOwner
  {
    registered[target] = isRegistered;
    RegistrationStatusChanged(target, isRegistered);
  }

  /**
    * @dev Changes registration statuses of addresses for participation.
    * @param targets Addresses that will be registered/deregistered.
    * @param isRegistered New registration status of addresses.
    */
  function changeRegistrationStatuses(address[] targets, bool isRegistered)
    public
    onlyOwner
  {
    for (uint i = 0; i < targets.length; i++) {
      changeRegistrationStatus(targets[i], isRegistered);
    }
  }

  /**
    * @dev overriding Crowdsale#validPurchase to add whilelist
    * @return true if investors can buy at the moment, false otherwise
    */
  function validPurchase() internal view returns (bool) {
    return super.validPurchase() && registered[msg.sender];
  }
}

contract PathPublicPresale is RateConfigurable, WhitelistedCrowdsale, BurnableCrowdsale, ReallocatableCrowdsale {

  address public privatePresaleWallet;

  function PathPublicPresale (
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    PATH _token,
    address _privatePresaleWallet
  )
    WhitelistedCrowdsale()
    BurnableCrowdsale()
    StandardCrowdsale(_startTime, _endTime, _rate, _wallet, _token)
    public
  {
    privatePresaleWallet = _privatePresaleWallet;
  }

  function reallocation(uint256 _value)
    internal
  {
    require(token.transfer(privatePresaleWallet, _value));
  }
}