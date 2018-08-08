pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract PreICO {
  function balanceOf(address _owner) constant returns (uint256);
  function burnTokens(address _owner);
}

contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /*
   * Fix for the ERC20 short address attack  
   */
  modifier onlyPayloadSize(uint size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
}

contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract ATL is StandardToken {

  string public name = "ATLANT Token";
  string public symbol = "ATL";
  uint public decimals = 18;
  uint constant TOKEN_LIMIT = 150 * 1e6 * 1e18;

  address public ico;

  bool public tokensAreFrozen = true;

  function ATL(address _ico) {
    ico = _ico;
  }

  function mint(address _holder, uint _value) external {
    require(msg.sender == ico);
    require(_value != 0);
    require(totalSupply + _value <= TOKEN_LIMIT);

    balances[_holder] += _value;
    totalSupply += _value;
    Transfer(0x0, _holder, _value);
  }

  function unfreeze() external {
    require(msg.sender == ico);
    tokensAreFrozen = false;
  }

  function transfer(address _to, uint _value) public {
    require(!tokensAreFrozen);
    super.transfer(_to, _value);
  }


  function transferFrom(address _from, address _to, uint _value) public {
    require(!tokensAreFrozen);
    super.transferFrom(_from, _to, _value);
  }


  function approve(address _spender, uint _value) public {
    require(!tokensAreFrozen);
    super.approve(_spender, _value);
  }
}

contract ICO {

  uint public constant MIN_TOKEN_PRICE = 425; // min atl per ETH
  uint public constant TOKENS_FOR_SALE = 103548812 * 1e18;
  uint public constant ATL_PER_ATP = 2; // Migration rate

  event Buy(address holder, uint atlValue);
  event ForeignBuy(address holder, uint atlValue, string txHash);
  event Migrate(address holder, uint atlValue);
  event RunIco();
  event PauseIco();
  event FinishIco(address teamFund, address bountyFund);

  PreICO preICO;
  ATL public atl;

  address public team;
  address public tradeRobot;
  modifier teamOnly { require(msg.sender == team); _; }
  modifier robotOnly { require(msg.sender == tradeRobot); _; }

  uint public tokensSold = 0;

  enum IcoState { Created, Running, Paused, Finished }
  IcoState icoState = IcoState.Created;


  function ICO(address _team, address _preICO, address _tradeRobot) {
    atl = new ATL(this);
    preICO = PreICO(_preICO);
    team = _team;
    tradeRobot = _tradeRobot;
  }


  function() external payable {
    buyFor(msg.sender);
  }


  function buyFor(address _investor) public payable {
    require(icoState == IcoState.Running);
    require(msg.value > 0);
    uint _total = buy(_investor, msg.value * MIN_TOKEN_PRICE);
    Buy(_investor, _total);
  }


  function getBonus(uint _value, uint _sold)
    public constant returns (uint)
  {
    uint[8] memory _bonusPricePattern = [ 505, 495, 485, 475, 465, 455, 445, uint(435) ];
    uint _step = TOKENS_FOR_SALE / 10;
    uint _bonus = 0;

    for (uint8 i = 0; _value > 0 && i < _bonusPricePattern.length; ++i) {
      uint _min = _step * i;
      uint _max = _step * (i+1);

      if (_sold >= _min && _sold < _max) {
        uint bonusedPart = min(_value, _max - _sold);
        _bonus += bonusedPart * _bonusPricePattern[i] / MIN_TOKEN_PRICE - bonusedPart;
        _value -= bonusedPart;
        _sold += bonusedPart;
      }
    }

    return _bonus;
  }

  function foreignBuy(address _investor, uint _atlValue, string _txHash)
    external robotOnly
  {
    require(icoState == IcoState.Running);
    require(_atlValue > 0);
    uint _total = buy(_investor, _atlValue);
    ForeignBuy(_investor, _total, _txHash);
  }


  function setRobot(address _robot) external teamOnly {
    tradeRobot = _robot;
  }


  function migrateSome(address[] _investors) external robotOnly {
    for (uint i = 0; i < _investors.length; i++)
      doMigration(_investors[i]);
  }


  function startIco() external teamOnly {
    require(icoState == IcoState.Created || icoState == IcoState.Paused);
    icoState = IcoState.Running;
    RunIco();
  }


  function pauseIco() external teamOnly {
    require(icoState == IcoState.Running);
    icoState = IcoState.Paused;
    PauseIco();
  }


  function finishIco(
    address _teamFund,
    address _bountyFund
  )
    external teamOnly
  {
    require(icoState == IcoState.Running || icoState == IcoState.Paused);

    atl.mint(_teamFund, 22500000 * 1e18);
    atl.mint(_bountyFund, 18750000 * 1e18);
    atl.unfreeze();

    icoState = IcoState.Finished;
    FinishIco(_teamFund, _bountyFund);
  }


  function withdrawEther(uint _value) external teamOnly {
    team.transfer(_value);
  }


  function withdrawToken(address _tokenContract, uint _val) external teamOnly
  {
    ERC20 _tok = ERC20(_tokenContract);
    _tok.transfer(team, _val);
  }


  function min(uint a, uint b) internal constant returns (uint) {
    return a < b ? a : b;
  }


  function buy(address _investor, uint _atlValue) internal returns (uint) {
    uint _bonus = getBonus(_atlValue, tokensSold);
    uint _total = _atlValue + _bonus;

    require(tokensSold + _total <= TOKENS_FOR_SALE);

    atl.mint(_investor, _total);
    tokensSold += _total;
    return _total;
  }


  function doMigration(address _investor) internal {
    uint _atpBalance = preICO.balanceOf(_investor);
    require(_atpBalance > 0);

    preICO.burnTokens(_investor);

    uint _atlValue = _atpBalance * ATL_PER_ATP;
    atl.mint(_investor, _atlValue);

    Migrate(_investor, _atlValue);
  }
}