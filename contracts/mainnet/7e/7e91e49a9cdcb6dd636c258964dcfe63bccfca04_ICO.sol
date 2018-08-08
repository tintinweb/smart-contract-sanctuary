pragma solidity ^0.4.18;

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
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
    uint256 c = a / b;
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
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) internal allowed;
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
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
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

contract BurnableToken is StandardToken {
  event Burn(address indexed burner, uint256 value);
  function burn(uint256 _value) public {
    require(_value > 0);
    require(_value <= balances[msg.sender]);
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply = totalSupply.sub(_value);
    Burn(burner, _value);
  }
}
contract KimJCoin is BurnableToken {
  string public constant name = "KimJ Coin";
  string public constant symbol = "KJC";
  uint32 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 20000000 *(10 ** 18);  
  address public giveAddress = 0xacc31A27A5Ce81cB7b6269003226024963016F37;
  function KimJCoin() public {
    uint256 _keep = 90;
    uint256 _giveTokens = 10;

    totalSupply = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY.mul(_keep).div(100);
    balances[giveAddress] = INITIAL_SUPPLY.mul(_giveTokens).div(100);
  }
  
  function AddressDefault() public view returns (address){
    return giveAddress;
  }
  
}

contract ICO is Ownable {

  using SafeMath for uint256;

  KimJCoin public token;

  address multisig;
  address restricted;

  uint256 rate;
  uint256 minAmount;

  uint256 preIcoStartDate;
  uint256 preIcoEndDate;
  
  uint256 tier1StartDate;
  uint256 tier1EndDate;
  uint256 tier2StartDate;
  uint256 tier2EndDate;

  uint256 percentsTeamTokens;
  uint256 percentsBountySecondTokens;
  uint256 percentsBountyFirstTokens;
  uint256 percentsNuclearTokens;
  uint256 percentsBounty;
  uint256 percentsPreSaleTokens;
  uint256 percentsIco1;
  uint256 percentsIco2;
  uint256 totaldivineTokensIssued;
  uint256 totalEthereumRaised;
  modifier saleIsOn() {
    uint256 curState = getStatus();
    require(curState != 0);
    _;
  }

  modifier isUnderHardCap() {
    uint256 _availableTokens = token.balanceOf(this);
    uint256 _tokens = calculateTokens(msg.value);
    uint256 _minTokens = holdTokensOnStage();
    require(_availableTokens.sub(_tokens) >= _minTokens);
    _;
  }

  modifier checkMinAmount() {
    require(msg.value >= minAmount);
    _;
  }
  function ICO() public {
    
   token   =  new KimJCoin();
    multisig = msg.sender;
    restricted = msg.sender;
    minAmount = 0.01 * 1 ether;
    rate = 1000;

  preIcoStartDate = 1519257600  ;
    preIcoEndDate = 1521072000;  
  
  tier1StartDate = 1521072000;
  tier1EndDate = 1522540800;
  
  tier2StartDate = 1522540800;
  tier2EndDate = 1525132800;
  
    percentsTeamTokens = 15;
    percentsBountySecondTokens = 5;
  percentsBountyFirstTokens = 5;
  percentsNuclearTokens = 5;
  percentsBounty = 10;
  
    percentsPreSaleTokens = 30;
    percentsIco1 = 25;
  percentsIco2 = 15;
  totaldivineTokensIssued = 0;
  totalEthereumRaised = 0;
  }

  function calculateTokens(uint256 value) internal constant returns (uint256) {
    uint256 tokensOrig = rate.mul(value).div(1 ether).mul(10 ** 18);
    uint256 tokens = rate.mul(value).div(1 ether).mul(10 ** 18);
    uint256 curState = getStatus();
    if(curState== 1){
      tokens += tokens.div(2);
    }
  
    bytes20 divineHash = ripemd160(block.coinbase, block.number, block.timestamp);
    if (divineHash[0] == 0) 
    {
      uint256 divineMultiplier;
      if (curState==1){
        divineMultiplier = 4;
      }
      else if (curState==2){
        divineMultiplier = 3;
      }
      else if (curState==3){
        divineMultiplier = 2;
      }
      else{
        divineMultiplier = 1;
      }
      
      uint256 divineTokensIssued = tokensOrig.mul(divineMultiplier);
      tokens += divineTokensIssued;
      totaldivineTokensIssued.add(divineTokensIssued);
    }

  
  
    return tokens;
  }

  // 0 - stop
  // 1 - preSale
  // 2 - sale 1
  // 3 - sale 2
  function getStatus() internal constant returns (uint256) {
    if(now > tier2EndDate) {
      return 0;
    } else if(now > tier2StartDate && now < tier2EndDate) {
      return 3;
    } else if(now > tier1StartDate && now < tier1EndDate) {
      return 2;
    } else if(now > preIcoStartDate && now < preIcoEndDate){
      return 1;
    } else {
      return 0;
    }
  }

  function holdTokensOnStage() public view returns (uint256) {
    uint256 _totalSupply = token.totalSupply();
    uint256 _percents = 100;
    uint256 curState = getStatus();
    if(curState == 3) {
      _percents = percentsTeamTokens+percentsNuclearTokens;  //100 - (30+10+25+15) = 20
    } else if(curState == 2) {
      _percents = _percents.sub(percentsPreSaleTokens.add(percentsBounty).add(percentsIco1));  //100 - (30+10+25) = 35
    } else if(curState == 1) {
      _percents = _percents.sub(percentsPreSaleTokens.add(percentsBounty)); //100 - (30+10) = 60
    }

    return _totalSupply.mul(_percents).div(100);
  }

  function onBalance() public view returns (uint256) {
    return token.balanceOf(this);
  }

  function availableTokensOnCurrentStage() public view returns (uint256) {
    uint256 _currentHolder = token.balanceOf(this);
    uint256 _minTokens = holdTokensOnStage();
    return _currentHolder.sub(_minTokens);
  }

  function getStatusInfo() public view returns (string) {
    uint256 curState = getStatus();
    if(now > tier2EndDate) {
      return "ICO is over";
    } else if(curState == 3) {
      return "Now ICO #2 is active";
    } else if(curState == 2) {
      return "Now ICO #1 is active";
    } else if(curState == 1) {
      return "Now Pre-ICO is active";
    } else {
      return "The sale of tokens is stopped";
    }
  }

  // burn the rest
  // keep nuc and team tokens
  function burnTokens() public onlyOwner {
    require(now > tier2EndDate);
    uint256 circulating = token.totalSupply().sub(token.balanceOf(this));

    uint256 _teamTokens = circulating.mul(percentsTeamTokens).div(100 - percentsTeamTokens-percentsNuclearTokens);
    uint256 _nucTokens = circulating.mul(percentsNuclearTokens).div(100 - percentsTeamTokens-percentsNuclearTokens);

    // safety check. The math should work out, but this is here just in case
    if (_teamTokens.add(_nucTokens)>token.balanceOf(this)){
      _nucTokens = token.balanceOf(this).sub(_teamTokens);
    }

    token.transfer(restricted, _teamTokens);
    token.transfer(token.AddressDefault(), _nucTokens);
    uint256 _burnTokens = token.balanceOf(this);
    if (_burnTokens>0){
      token.burn(_burnTokens);
    }
  }

  function createTokens() public saleIsOn isUnderHardCap checkMinAmount payable {
    uint256 tokens = calculateTokens(msg.value);
    totalEthereumRaised.add(msg.value);
    multisig.transfer(msg.value);
    token.transfer(msg.sender, tokens);
  }


  function() external payable {
    createTokens();
  }
  
  function getStats() public constant returns (uint256, uint256, uint256) {
        return (totalEthereumRaised, token.totalSupply(), totaldivineTokensIssued);
    }
}