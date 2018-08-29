contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract Ownable {
  
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused {
    paused = true;
    Pause();
  }

  function unpause() onlyOwner whenPaused {
    paused = false;
    Unpause();
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

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Crowdsale {
  using SafeMath for uint256;

  MintableToken public token;

  uint256 public startTime;
  uint256 public endTime;

  address wallet;

  uint256 public rate;

  uint256 public weiRaised;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= 0);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }

  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

    uint256 tokens = weiAmount.mul(rate);

    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
}

contract XulToken is MintableToken, Pausable {
  string public constant name = "XULToken";
  string public constant symbol = "XUL";
  uint8 public constant decimals = 18;

  uint256 public preIcoEndDate = 1510704000;  

  function XulToken() {
  }
  
  function mint(address _to, uint256 _amount) onlyOwner canMint whenNotPaused public returns (bool) {
    uint256 goal = 300000000 * (10**18);

    if (isPreIcoDate()) {
      uint256 sum = totalSupply.add(_amount);
      require(sum <= goal);
    }

    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    if (totalSupply == goal && isPreIcoDate()) {
      paused = true;
    }
    return true;    
  }
     
  function superMint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }     
  
  function changePreIcoEndDate(uint256 _preIcoEndDate) onlyOwner public {
    require(_preIcoEndDate > 0);
    preIcoEndDate = _preIcoEndDate;
  }  
 
  function isPreIcoDate() public returns(bool) {
    return now <= preIcoEndDate;
  }     
}

contract XulCrowdsale is Crowdsale, Ownable {
  XulToken public xultoken;
    
  function XulCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet)
    Crowdsale(_startTime, _endTime, _rate, _wallet)
  {
    
  }
  
  function createTokenContract() internal returns (MintableToken) {
     xultoken = new XulToken();
     return xultoken;
  }
  
  function changeRate(uint256 _rate) public onlyOwner returns (bool){
      require(_rate > 0);
      rate = _rate;
  }
    
  function pauseToken() public onlyOwner returns(bool){
      xultoken.pause();
  }
   
  function unpauseToken() public onlyOwner returns(bool){
      xultoken.unpause();
  }

  function mintToken(address _to, uint256 _amount) public onlyOwner returns(bool){
      xultoken.mint(_to, _amount * (10 ** 18));
  }

  function mintBulk(address[] _receivers, uint256[] _amounts) onlyOwner public {
    require(_receivers.length == _amounts.length);
    for (uint i = 0; i < _receivers.length; i++) {
        mintToken(_receivers[i], _amounts[i]);
    }
  } 
  
  function superMint(address _to, uint256 _amount) public onlyOwner returns(bool) {
      xultoken.superMint(_to, _amount * (10 ** 18));
  }
  
  function setStartTime(uint256 _startTime) public onlyOwner {
      require(_startTime > 0);
      startTime = _startTime;
  }  

  function setEndTime(uint256 _endTime) public onlyOwner {
      require(_endTime > 0);
      endTime = _endTime;
  }    

  function setPreIcoEndDate(uint256 _preIcoEndDate) public onlyOwner {
    xultoken.changePreIcoEndDate(_preIcoEndDate);
  }  
}