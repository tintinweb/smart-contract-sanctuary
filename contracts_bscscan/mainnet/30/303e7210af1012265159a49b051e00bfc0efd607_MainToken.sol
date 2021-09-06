/**
 *Submitted for verification at BscScan.com on 2021-09-06
*/

/**
Name		: Gazelle Token
Symbol		: GZLT

♻️ Contact Verified
📈 Audit is in progress

Social Media
Website	:  https://GazelleToken.com
Facebook	:  https://facebook.com/GazelleToken
Telegram	:  https://t.me/GazelleToken
Twitter		:  https://twitter.com/GazelleToken
Instagram	:  https://instagram.com/GazelleToken
*/

pragma solidity ^0.4.23;


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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


library SafeMath {


  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {

    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {

    return a / b;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Crowdsale {
  using SafeMath for uint256;

  ERC20 public token;

  address public wallet;

  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;


  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );


  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }


  function () external payable {
    buyTokens(msg.sender);
  }


  function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);
    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }


  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }


  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
  }


  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.transfer(_beneficiary, _tokenAmount);
  }


  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }


  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }


  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }


  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}


contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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


  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }


  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }


  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}



contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;


  modifier onlyWhileOpen {
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }


  constructor(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }


  function hasClosed() public view returns (bool) {
    return block.timestamp > closingTime;
  }


  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;


  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }


  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }


  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;



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


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

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


  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }


  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }



  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }



  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract FreezableToken is StandardToken {
    // freezing chains
    mapping (bytes32 => uint64) internal chains;
    // freezing amounts for each chain
    mapping (bytes32 => uint) internal freezings;
    // total freezing balance per address
    mapping (address => uint) internal freezingBalance;

    event Freezed(address indexed to, uint64 release, uint amount);
    event Released(address indexed owner, uint amount);



    function balanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner) + freezingBalance[_owner];
    }


    function actualBalanceOf(address _owner) public view returns (uint256 balance) {
        return super.balanceOf(_owner);
    }
    function freezingBalanceOf(address _owner) public view returns (uint256 balance) {
        return freezingBalance[_owner];
    }


    function freezingCount(address _addr) public view returns (uint count) {
        uint64 release = chains[toKey(_addr, 0)];
        while (release != 0) {
            count++;
            release = chains[toKey(_addr, release)];
        }
    }


    function getFreezing(address _addr, uint _index) public view returns (uint64 _release, uint _balance) {
        for (uint i = 0; i < _index + 1; i++) {
            _release = chains[toKey(_addr, _release)];
            if (_release == 0) {
                return;
            }
        }
        _balance = freezings[toKey(_addr, _release)];
    }


    function freezeTo(address _to, uint _amount, uint64 _until) public {
        require(_to != address(0));
        require(_amount <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);
        freeze(_to, _until);
        emit Transfer(msg.sender, _to, _amount);
        emit Freezed(_to, _until, _amount);
    }

    function releaseOnce() public {
        bytes32 headKey = toKey(msg.sender, 0);
        uint64 head = chains[headKey];
        require(head != 0);
        require(uint64(block.timestamp) > head);
        bytes32 currentKey = toKey(msg.sender, head);

        uint64 next = chains[currentKey];

        uint amount = freezings[currentKey];
        delete freezings[currentKey];

        balances[msg.sender] = balances[msg.sender].add(amount);
        freezingBalance[msg.sender] = freezingBalance[msg.sender].sub(amount);

        if (next == 0) {
            delete chains[headKey];
        } else {
            chains[headKey] = next;
            delete chains[currentKey];
        }
        emit Released(msg.sender, amount);
    }


    function releaseAll() public returns (uint tokens) {
        uint release;
        uint balance;
        (release, balance) = getFreezing(msg.sender, 0);
        while (release != 0 && block.timestamp > release) {
            releaseOnce();
            tokens += balance;
            (release, balance) = getFreezing(msg.sender, 0);
        }
    }

    function toKey(address _addr, uint _release) internal pure returns (bytes32 result) {
        result = 0x5749534800000000000000000000000000000000000000000000000000000000;
        assembly {
            result := or(result, mul(_addr, 0x10000000000000000))
            result := or(result, and(_release, 0xffffffffffffffff))
        }
    }




    function freeze(address _to, uint64 _until) internal {
        require(_until > block.timestamp);
        bytes32 key = toKey(_to, _until);
        bytes32 parentKey = toKey(_to, uint64(0));
        uint64 next = chains[parentKey];

        if (next == 0) {
            chains[parentKey] = _until;
            return;
        }

        bytes32 nextKey = toKey(_to, next);
        uint parent;

        while (next != 0 && _until > next) {
            parent = next;
            parentKey = nextKey;

            next = chains[nextKey];
            nextKey = toKey(_to, next);
        }

        if (_until == next) {
            return;
        }

        if (next != 0) {
            chains[key] = next;
        }

        chains[parentKey] = _until;
    }
}


contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);


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
}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }


  modifier whenPaused() {
    require(paused);
    _;
  }


  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }


  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}



contract FreezableMintableToken is FreezableToken, MintableToken {

 function mintAndFreeze(address _to, uint _amount, uint64 _until) public onlyOwner canMint returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);

        bytes32 currentKey = toKey(_to, _until);
        freezings[currentKey] = freezings[currentKey].add(_amount);
        freezingBalance[_to] = freezingBalance[_to].add(_amount);

        freeze(_to, _until);
        emit Mint(_to, _amount);
        emit Freezed(_to, _until, _amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
}

contract Consts {
    uint public constant TOKEN_DECIMALS = 5;
    uint8 public constant TOKEN_DECIMALS_UINT8 = 5;
    uint public constant TOKEN_DECIMAL_MULTIPLIER = 10 ** TOKEN_DECIMALS;

    string public constant TOKEN_NAME = "GazelleToken";
    string public constant TOKEN_SYMBOL = "GZLT";
    bool public constant PAUSED = true;
    address public constant TARGET_USER = 0x0aB3871d431330456258D11dE1FaC409830BF17f;
    
    uint public constant START_TIME = 1625733000;
    
    bool public constant CONTINUE_MINTING = true;
}



contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;
  event Finalized();


  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }


  function finalization() internal {
  }
}



contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;


  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }


  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }


  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}



contract MintedCrowdsale is Crowdsale {


  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}







contract MainToken is Consts, FreezableMintableToken, BurnableToken, Pausable    
{
    function name() public pure returns (string _name) {
        return TOKEN_NAME;
    }
    function symbol() public pure returns (string _symbol) {
        return TOKEN_SYMBOL;
    }
    function decimals() public pure returns (uint8 _decimals) {
        return TOKEN_DECIMALS_UINT8;
    }
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transferFrom(_from, _to, _value);
    }
    function transfer(address _to, uint256 _value) public returns (bool _success) {
        require(!paused);
        return super.transfer(_to, _value);
    } 
}

contract MainCrowdsale is Consts, FinalizableCrowdsale, MintedCrowdsale, CappedCrowdsale {
    function hasStarted() public view returns (bool) {
        return now >= openingTime;
    }
    function startTime() public view returns (uint256) {
        return openingTime;
    }
    function endTime() public view returns (uint256) {
        return closingTime;
    }
    function hasClosed() public view returns (bool) {
        return super.hasClosed() || capReached();
    }
    function hasEnded() public view returns (bool) {
        return hasClosed();
    }

    function finalization() internal {
        super.finalization();

        if (PAUSED) {
            MainToken(token).unpause();
        }
        if (!CONTINUE_MINTING) {
            require(MintableToken(token).finishMinting());
        }

        Ownable(token).transferOwnership(TARGET_USER);
    }

    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        return _weiAmount.mul(rate).div(1 ether);
    }
}

contract BonusableCrowdsale is Consts, Crowdsale {

    function _getTokenAmount(uint256 _weiAmount)
        internal view returns (uint256)
    {
        uint256 bonusRate = getBonusRate(_weiAmount);
        return _weiAmount.mul(bonusRate).div(1 ether);
    }

    function getBonusRate(uint256 _weiAmount) internal view returns (uint256) {
        uint256 bonusRate = rate;

        
        uint[1] memory weiRaisedStartsBounds = [uint(0)];
        uint[1] memory weiRaisedEndsBounds = [uint(5000000000000000000000)];
        uint64[1] memory timeStartsBounds = [uint64(1625733000)];
        uint64[1] memory timeEndsBounds = [uint64(1625992195)];
        uint[1] memory weiRaisedAndTimeRates = [uint(500)];

        for (uint i = 0; i < 1; i++) {
            bool weiRaisedInBound = (weiRaisedStartsBounds[i] <= weiRaised) && (weiRaised < weiRaisedEndsBounds[i]);
            bool timeInBound = (timeStartsBounds[i] <= now) && (now < timeEndsBounds[i]);
            if (weiRaisedInBound && timeInBound) {
                bonusRate += bonusRate * weiRaisedAndTimeRates[i] / 1000;
            }
        }
        
        return bonusRate;
    }
}






contract TemplateCrowdsale is Consts, MainCrowdsale  , BonusableCrowdsale 
{
    event Initialized();
    event TimesChanged(uint startTime, uint endTime, uint oldStartTime, uint oldEndTime);
    bool public initialized = false;

    constructor(MintableToken _token) public
        Crowdsale(100000 * TOKEN_DECIMAL_MULTIPLIER, 0x0aB3871d431330456258D11dE1FaC409830BF17f, _token)
        TimedCrowdsale(START_TIME > now ? START_TIME : now, 1625992200)
        CappedCrowdsale(5000000000000000000000)
    { }

    function init() public onlyOwner {
        require(!initialized);
        initialized = true;

        if (PAUSED) {
            MainToken(token).pause();
        }

        address[5] memory addresses = [address(0x0aB3871d431330456258D11dE1FaC409830BF17f),address(0x42b8c40F67C0DBEDa0D2fb26F2a067ee91358AEd),address(0xf02B50f4856a61D19d2827C328b4530f91741feA),address(0x7b1A0a8Dc6E6A7A5Cdbc5971B148F331d91a0050),address(0x6071085624aE5b2c344c211AaB9A8f8a8EFdbD67)];
        uint[5] memory amounts = [uint(70000000000000),uint(17500000000000),uint(7500000000000),uint(2500000000000),uint(2500000000000)];
        uint64[5] memory freezes = [uint64(0),uint64(0),uint64(0),uint64(0),uint64(0)];

        for (uint i = 0; i < addresses.length; i++) {
            if (freezes[i] == 0) {
                MainToken(token).mint(addresses[i], amounts[i]);
            } else {
                MainToken(token).mintAndFreeze(addresses[i], amounts[i], freezes[i]);
            }
        }

        transferOwnership(TARGET_USER);
        emit Initialized();
    }
    function setEndTime(uint _endTime) public onlyOwner {
        // only if CS was not ended
        require(now < closingTime);
        // only if new end time in future
        require(now < _endTime);
        require(_endTime > openingTime);
        emit TimesChanged(openingTime, _endTime, openingTime, closingTime);
        closingTime = _endTime;
    }
}