pragma solidity ^0.4.13;

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  MintableToken public token;

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
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
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

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }

  // creates the token to be sold.
  // override this method to have crowdsale of a specific mintable token.
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
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

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
  }

}

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

contract FinalizableCappedCrowdsale is CappedCrowdsale, Ownable {

    bool public isFinalized = false;
    bool public reconciliationDateSet = false;
    uint public reconciliationDate = 0;

    event Finalized();

    /**
    * @dev Must be called after crowdsale ends, to do some extra finalization
    * work. Calls the contract&#39;s finalization function.
    */
    function finalize() onlyOwnerOrAfterReconciliation public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        Finalized();
        isFinalized = true;
    }

    function setReconciliationDate(uint _reconciliationDate) onlyOwner {
        reconciliationDate = _reconciliationDate;
        reconciliationDateSet = true;
    }

    /**
    * @dev Can be overridden to add finalization logic. The overriding function
    * should call super.finalization() to ensure the chain of finalization is
    * executed entirely.
    */
    function finalization() internal {
    }

    modifier onlyOwnerOrAfterReconciliation(){
        require(msg.sender == owner || (reconciliationDate <= now && reconciliationDateSet));
        _;
    }

}

contract PoolSegregationCrowdsale is Ownable {
    /**
    * we include the crowdsale eventhough this is not treated in this contract (zeppelin&#39;s CappedCrowdsale )
    */
    enum POOLS {POOL_STRATEGIC_INVESTORS, POOL_COMPANY_RESERVE, POOL_USER_ADOPTION, POOL_TEAM, POOL_ADVISORS, POOL_PROMO}

    using SafeMath for uint;

    mapping (uint => PoolInfo) poolMap;

    struct PoolInfo {
        uint contribution;
        uint poolCap;
    }

    function PoolSegregationCrowdsale(uint _cap) {
        poolMap[uint(POOLS.POOL_STRATEGIC_INVESTORS)] = PoolInfo(0, _cap.mul(285).div(1000));
        poolMap[uint(POOLS.POOL_COMPANY_RESERVE)] = PoolInfo(0, _cap.mul(10).div(100));
        poolMap[uint(POOLS.POOL_USER_ADOPTION)] = PoolInfo(0, _cap.mul(20).div(100));
        poolMap[uint(POOLS.POOL_TEAM)] = PoolInfo(0, _cap.mul(3).div(100));
        poolMap[uint(POOLS.POOL_ADVISORS)] = PoolInfo(0, _cap.mul(3).div(100));
        poolMap[uint(POOLS.POOL_PROMO)] = PoolInfo(0, _cap.mul(3).div(100));
    }

    modifier onlyIfInPool(uint amount, uint poolId) {
        PoolInfo poolInfo = poolMap[poolId];
        require(poolInfo.contribution.add(amount) <= poolInfo.poolCap); 
        _;
        poolInfo.contribution = poolInfo.contribution.add(amount);
    }

    function transferRemainingTokensToUserAdoptionPool(uint difference) internal {
        poolMap[uint(POOLS.POOL_USER_ADOPTION)].poolCap = poolMap[uint(POOLS.POOL_USER_ADOPTION)].poolCap.add(difference);
    }

    function getPoolCapSize(uint poolId) public view returns(uint) {
        return poolMap[poolId].poolCap;
    }

}

contract LuckCashCrowdsale is FinalizableCappedCrowdsale, PoolSegregationCrowdsale {

    // whitelist registry contract
    WhiteListRegistry public whitelistRegistry;
    using SafeMath for uint;
    uint constant public CAP = 600000000*1e18;
    mapping (address => uint) contributions;

    /**
   * event for token vest fund launch
   * @param beneficiary who will get the tokens once they are vested
   * @param fund vest fund that will received the tokens
   * @param tokenAmount amount of tokens purchased
   */
    event VestedTokensFor(address indexed beneficiary, address fund, uint256 tokenAmount);
    /**
    * event for finalize function call at the end of the crowdsale
    */
    event Finalized();    

    /**
   * event for token minting for private investors
   * @param beneficiary who will get the tokens once they are vested
   * @param tokenAmount amount of tokens purchased
   */
    event MintedTokensFor(address indexed beneficiary, uint256 tokenAmount);

    /**
     * @dev Contract constructor function
     * @param _startTime The timestamp of the beginning of the crowdsale
     * @param _endTime Timestamp when the crowdsale will finish
     * @param _rate The token rate per ETH
     * Percent value is saved in crowdsalePercent.
     * @param _wallet Multisig wallet that will hold the crowdsale funds.
     * @param _whiteListRegistry Address of the whitelist registry contract
     */
    function LuckCashCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _whiteListRegistry) public
    CappedCrowdsale(CAP.mul(325).div(1000))
    PoolSegregationCrowdsale(CAP)
    FinalizableCappedCrowdsale()
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
        require(_whiteListRegistry != address(0));
        whitelistRegistry = WhiteListRegistry(_whiteListRegistry);
        LuckCashToken(token).pause();
    }

    /**
     * @dev Creates LuckCashToken contract. This is called on the Crowdsale contract constructor 
     */
    function createTokenContract() internal returns(MintableToken) {
        return new LuckCashToken(CAP); // 600 million cap
    }

    /**
     * @dev Mintes fresh token for a private investor.
     * @param beneficiary The beneficiary of the minting
     * @param amount The total token amount to be minted
     */
    function mintTokensFor(address beneficiary, uint256 amount, uint poolId) external onlyOwner onlyIfInPool(amount, poolId) {
        require(beneficiary != address(0) && amount != 0);
        // require(now <= endTime);

        token.mint(beneficiary, amount);

        MintedTokensFor(beneficiary, amount);
    }

    /**
     * @dev Creates a new contract for a vesting fund that will release funds for the beneficiary every quarter
     * @param beneficiary The beneficiary of the funds
     * @param amount The total token amount to be vested
     * @param quarters The number of quarters over which the funds will vest. Every quarter a sum equal to amount.quarters will be release
     */
    function createVestFundFor(address beneficiary, uint256 amount, uint256 quarters, uint poolId) external onlyOwner onlyIfInPool(amount, poolId) {
        require(beneficiary != address(0) && amount != 0);
        require(quarters > 0);
        // require(now <= endTime);

        VestingFund fund = new VestingFund(beneficiary, endTime, quarters, token); // the vesting period starts when the crowdsale has ended
        token.mint(fund, amount);

        VestedTokensFor(beneficiary, fund, amount);
    }

    /**
     * @dev overrides Crowdsale#validPurchase to add whitelist logic
     * @return true if buyers is able to buy at the moment
     */
    function validPurchase() internal view returns(bool) {
        return super.validPurchase() && canContributeAmount(msg.sender, msg.value);
    }

    function transferFromCrowdsaleToUserAdoptionPool() public onlyOwner {
        require(now > endTime);
        
        super.transferRemainingTokensToUserAdoptionPool(super.getTokenAmount(cap) - super.getTokenAmount(weiRaised));
    }
    
    /**
     * @dev finalizes crowdsale
     */ 
    function finalization() internal {
        token.finishMinting();
        LuckCashToken(token).unpause();

        wallet.transfer(this.balance);

        super.finalization();
    }

    /**
     * @dev overrides Crowdsale#forwardFunds to report of funds transfer and not transfer into the wallet untill the end
     */
    function forwardFunds() internal {
        reportContribution(msg.sender, msg.value);
    }

    function canContributeAmount(address _contributor, uint _amount) internal view returns (bool) {
        uint totalAmount = contributions[_contributor].add(_amount);
        return whitelistRegistry.isAmountAllowed(_contributor, totalAmount);  
    }

    function reportContribution(address _contributor, uint _amount) internal returns (bool) {
       contributions[_contributor] = contributions[_contributor].add(_amount);
    }

}

contract VestingFund is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);

  // beneficiary of tokens after they are released
  address public beneficiary;
  ERC20Basic public token;

  uint256 public quarters;
  uint256 public start;


  uint256 public released;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, tokens are release in an incremental fashion after a quater has passed until _start + _quarters * 3 * months. 
   * By then all of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _quarters number of quarters the vesting will last
   * @param _token ERC20 token which is being vested
   */
  function VestingFund(address _beneficiary, uint256 _start, uint256 _quarters, address _token) public {
    
    require(_beneficiary != address(0) && _token != address(0));
    require(_quarters > 0);

    beneficiary = _beneficiary;
    quarters = _quarters;
    start = _start;
    token = ERC20Basic(_token);
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   */
  function release() public {
    uint256 unreleased = releasableAmount();
    require(unreleased > 0);

    released = released.add(unreleased);
    token.safeTransfer(beneficiary, unreleased);

    Released(unreleased);
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   */
  function releasableAmount() public view returns(uint256) {
    return vestedAmount().sub(released);
  }

  /**
   * @dev Calculates the amount that has already vested.
   */
  function vestedAmount() public view returns(uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released);

    if (now < start) {
      return 0;
    }

    uint256 dT = now.sub(start); // time passed since start
    uint256 dQuarters = dT.div(90 days); // quarters passed

    if (dQuarters >= quarters) {
      return totalBalance; // return everything if vesting period ended
    } else {
      return totalBalance.mul(dQuarters).div(quarters); // ammount = total * (quarters passed / total quarters)
    }
  }
}

contract WhiteListRegistry is Ownable {

    mapping (address => WhiteListInfo) public whitelist;
    using SafeMath for uint;

    struct WhiteListInfo {
        bool whiteListed;
        uint minCap;
        uint maxCap;
    }

    event AddedToWhiteList(
        address contributor,
        uint minCap,
        uint maxCap
    );

    event RemovedFromWhiteList(
        address _contributor
    );

    function addToWhiteList(address _contributor, uint _minCap, uint _maxCap) public onlyOwner {
        require(_contributor != address(0));
        whitelist[_contributor] = WhiteListInfo(true, _minCap, _maxCap);
        AddedToWhiteList(_contributor, _minCap, _maxCap);
    }

    function removeFromWhiteList(address _contributor) public onlyOwner {
        require(_contributor != address(0));
        delete whitelist[_contributor];
        RemovedFromWhiteList(_contributor);
    }

    function isWhiteListed(address _contributor) public view returns(bool) {
        return whitelist[_contributor].whiteListed;
    }

    function isAmountAllowed(address _contributor, uint _amount) public view returns(bool) {
       return whitelist[_contributor].maxCap >= _amount && whitelist[_contributor].minCap <= _amount && isWhiteListed(_contributor);
    }

}

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
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

contract LuckCashToken is PausableToken, CappedToken {
    string public constant name = "LuckCash";
    string public constant symbol = "LCK";
    uint8 public constant decimals = 18;

    function LuckCashToken(uint _cap) public CappedToken(_cap) PausableToken() {

    }
}