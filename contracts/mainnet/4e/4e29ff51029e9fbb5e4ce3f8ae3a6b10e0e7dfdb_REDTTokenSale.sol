pragma solidity ^0.4.23;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="573336213217363c383a35367934383a">[email&#160;protected]</a>
// released under Apache 2.0 licence
contract REDTTokenConfig {
    string public constant NAME = "Real Estate Doc Token";
    string public constant SYMBOL = "REDT";
    uint8 public constant DECIMALS = 18;
    uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
    uint public constant TOTALSUPPLY = 1000000000 * DECIMALSFACTOR;
}


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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract REDTTokenSaleConfig is REDTTokenConfig {
    uint public constant MIN_CONTRIBUTION      = 100 finney;

    

    

    uint public constant RESERVE_AMOUNT = 500000000 * DECIMALSFACTOR;

    uint public constant SALE_START = 1537189200;
    uint public constant SALE_END = 1540990800;
    
    uint public constant SALE0_END = 1537794000;
    uint public constant SALE0_RATE = 24000;
    uint public constant SALE0_CAP = 400000000 * DECIMALSFACTOR;
    
    uint public constant SALE1_END = 1538398800;
    uint public constant SALE1_RATE = 22000;
    uint public constant SALE1_CAP = 500000000 * DECIMALSFACTOR;
    
    uint public constant SALE2_END = 1540990800;
    uint public constant SALE2_RATE = 20000;
    uint public constant SALE2_CAP = 500000000 * DECIMALSFACTOR;
    
    uint public constant SALE_CAP = 500000000 * DECIMALSFACTOR;

    address public constant MULTISIG_ETH = 0x25C7A30F23a107ebF430FDFD582Afe1245B690Af;
    address public constant MULTISIG_TKN = 0x25C7A30F23a107ebF430FDFD582Afe1245B690Af;

}
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

contract Operatable is Claimable {
    address public minter;
    address public whiteLister;
    address public launcher;

    modifier canOperate() {
        require(msg.sender == minter || msg.sender == whiteLister || msg.sender == owner);
        _;
    }

    constructor() public {
        minter = owner;
        whiteLister = owner;
        launcher = owner;
    }

    function setMinter (address addr) public onlyOwner {
        minter = addr;
    }

    function setWhiteLister (address addr) public onlyOwner {
        whiteLister = addr;
    }

    modifier onlyMinter()  {
        require (msg.sender == minter);
        _;
    }

    modifier ownerOrMinter()  {
        require ((msg.sender == minter) || (msg.sender == owner));
        _;
    }


    modifier onlyLauncher()  {
        require (msg.sender == minter);
        _;
    }

    modifier onlyWhiteLister()  {
        require (msg.sender == whiteLister);
        _;
    }
}
contract Salvageable is Operatable {
    // Salvage other tokens that are accidentally sent into this token
    function emergencyERC20Drain(ERC20 oddToken, uint amount) public onlyLauncher {
        if (address(oddToken) == address(0)) {
            launcher.transfer(amount);
            return;
        }
        oddToken.transfer(launcher, amount);
    }
}
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

contract WhiteListed is Operatable {


    uint public count;
    mapping (address => bool) public whiteList;

    event Whitelisted(address indexed addr, uint whitelistedCount, bool isWhitelisted);

    function addWhiteListed(address[] addrs) external canOperate {
        uint c = count;
        for (uint i = 0; i < addrs.length; i++) {
            if (!whiteList[addrs[i]]) {
                whiteList[addrs[i]] = true;
                c++;
                emit Whitelisted(addrs[i], count, true);
            }
        }
        count = c;
    }

    function removeWhiteListed(address addr) external canOperate {
        require(whiteList[addr]);
        whiteList[addr] = false;
        count--;
        emit Whitelisted(addr, count, false);
    }

}
contract REDTToken is PausableToken, REDTTokenConfig, Salvageable {
    using SafeMath for uint;

    string public name = NAME;
    string public symbol = SYMBOL;
    uint8 public decimals = DECIMALS;
    bool public mintingFinished = false;

    event Mint(address indexed to, uint amount);
    event MintFinished();
    event Burn(address indexed burner, uint256 value);


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    constructor(address launcher_) public {
        launcher = launcher_;
        paused = true;
    }

    function mint(address _to, uint _amount) canMint onlyMinter public returns (bool) {
        require(totalSupply_.add(_amount) <= TOTALSUPPLY);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

    function finishMinting() canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }

    function sendBatchCS(address[] _recipients, uint[] _values) external canOperate returns (bool) {
        require(_recipients.length == _values.length);
        uint senderBalance = balances[msg.sender];
        for (uint i = 0; i < _values.length; i++) {
            uint value = _values[i];
            address to = _recipients[i];
            require(senderBalance >= value);        
            senderBalance = senderBalance - value;
            balances[to] += value;
            emit Transfer(msg.sender, to, value);
        }
        balances[msg.sender] = senderBalance;
        return true;
    }

}
contract REDTTokenSale is REDTTokenSaleConfig, Claimable, Pausable, Salvageable {
    using SafeMath for uint;
    bool public isFinalized = false;
    REDTToken public token;
    
    uint public tokensRaised;           
    uint public weiRaised;              // Amount of raised money in WEI
    WhiteListed public whiteListed;
    uint public numContributors;        // Discrete number of contributors

    mapping (address => uint) public contributions; // to allow them to have multiple spends

    event Finalized();
    event TokenPurchase(address indexed beneficiary, uint value, uint amount);
    event TokenPresale(address indexed purchaser, uint amount);

    struct capRec  {
        uint time;
        uint amount;
    }
    capRec[] public capz;
    uint public capDefault;


    constructor( WhiteListed _whiteListed ) public {
        
        require(now < SALE_START);
        
        require(_whiteListed != address(0));
        
        whiteListed = _whiteListed;

        token = new REDTToken(owner);
        token.mint(MULTISIG_TKN,RESERVE_AMOUNT);
        initCaps();
    }

    
    function initCaps() public {
        uint[4] memory caps = [uint(10),20,30,40];
        uint[4] memory times = [uint(1),4,12,24];
        for (uint i = 0; i < caps.length; i++) {
            capRec memory cr;
            cr.time = times[i];
            cr.amount = caps[i];
            capz.push(cr);
        }
        capDefault = 100;
    }
    
    function setCapRec(uint[] capsInEther, uint[] timesInHours, uint defaultCapInEther) public onlyOwner {
        //capRec[] memory cz = new capRec[](caps.length);
        require(capsInEther.length == timesInHours.length);
        capz.length = 0;
        for (uint i = 0; i < capsInEther.length; i++) {
            capRec memory cr;
            cr.time = timesInHours[i];
            cr.amount = capsInEther[i];
            capz.push(cr);
        }
        capDefault = defaultCapInEther;
        
    }
    
    function currentCap() public view returns (uint) {
        for (uint i = 0; i < capz.length; i++) {
            if (now < SALE_START + capz[i].time * 1 hours)
                return (capz[i].amount * 1 ether);
        }
        return capDefault;
    }


    function getRateAndCheckCap() public view returns (uint) {
        
        require(now>SALE_START);
        
        if ((now<SALE0_END) && (tokensRaised < SALE0_CAP))
            return SALE0_RATE;
        
        if ((now<SALE1_END) && (tokensRaised < SALE1_CAP))
            return SALE1_RATE;
        
        if ((now<SALE2_END) && (tokensRaised < SALE2_CAP))
            return SALE2_RATE;
        
        revert();
    }

    // Only fallback function can be used to buy tokens
    function () external payable {
        buyTokens(msg.sender, msg.value);
    }

    function buyTokens(address beneficiary, uint weiAmount) internal whenNotPaused {
        require(contributions[beneficiary].add(weiAmount) < currentCap());
        require(whiteListed.whiteList(beneficiary));
        require((weiAmount > MIN_CONTRIBUTION) || (weiAmount == SALE_CAP.sub(MIN_CONTRIBUTION)));

        weiRaised = weiRaised.add(weiAmount);
        uint tokens = weiAmount.mul(getRateAndCheckCap());

        if (contributions[beneficiary] == 0) {
            numContributors++;
        }

        tokensRaised = tokensRaised.add(tokens);

        contributions[beneficiary] = contributions[beneficiary].add(weiAmount);
        token.mint(beneficiary, tokens);
        emit TokenPurchase(beneficiary, weiAmount, tokens);
        forwardFunds();
    }

    function placeTokens(address beneficiary, uint256 numtokens) 
    public
	  ownerOrMinter
    {
        require(now < SALE_START);  
        tokensRaised = tokensRaised.add(numtokens);
        token.mint(beneficiary,numtokens);
    }


    function tokensUnsold() public view returns(uint) {
        return token.TOTALSUPPLY().sub(token.totalSupply());
    }

    // Return true if crowdsale event has ended
    function hasEnded() public view returns (bool) {
        return ((now > SALE_END) || (tokensRaised >= SALE_CAP));
    }

    // Send ether to the fund collection wallet
    function forwardFunds() internal {
        
        MULTISIG_ETH.transfer(address(this).balance);
    }

    // Must be called after crowdsale ends, to do some extra finalization
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

    // Stops the minting and transfer token ownership to sale owner. Mints unsold tokens to owner
    function finalization() internal {
        token.finishMinting();
        token.transferOwnership(owner);
    }
}