pragma solidity ^0.4.24;

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
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
  function totalSupply() public view returns (uint256);
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

  uint256 internal totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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

contract ERC20Implementation is ERC20, BurnableToken, Ownable {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

contract MintableToken is ERC20Implementation {
  
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

contract ICEToken is MintableToken {

  string public constant name = "Online.io ICE";
  string public constant symbol = "ICE";
  uint8 public constant decimals = 18;

  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  
  address[] private founders;
  uint256[] private foundersTokensAmountPercents;
  
  uint256 private weeklyTokensForHolders;
  uint256 private weeklyTokensForWebsites;
  uint256 private weeklyTokensForFounders;
  
  uint256 private weeklyTokensSupply;
  uint256 private emissionCoefficient;

  uint256 private start;
  uint256 private lastMintingDate;
  uint256 private yearsAmount;

  function mintOneWeek() onlyOwner canMint public returns (bool) {
    require(now >= lastMintingDate + 7 * 1 days);
    lastMintingDate = now;
    calculateWeeklyTokensSupply();
    totalSupply_ = totalSupply_.add(weeklyTokensSupply);
    weeklyTokensForFounders = weeklyTokensForFounders.add(weeklyTokensSupply.div(5));
    weeklyTokensForHolders = weeklyTokensForHolders.add(weeklyTokensSupply.mul(40).div(100));
    weeklyTokensForWebsites = weeklyTokensForWebsites.add(weeklyTokensSupply.mul(40).div(100));
    return true;
  }

  constructor(address[] _founders, uint256[] _equities) public{
    require(_founders.length == _equities.length);

    uint256 percents;
    
    for (uint i=0; i<_equities.length; i++) {
       percents += _equities[i];
    }
    if(percents!=0){
      require (percents == 100);
    }
    
    founders = _founders;
    foundersTokensAmountPercents = _equities;

    start = now;
    lastMintingDate = now;
    weeklyTokensSupply = 77000000;
  }

  function mintForFounders() onlyOwner canMint public {
     uint256 tokensForFounders = weeklyTokensForFounders;
     for (uint i=0; i<founders.length; i++) {
       balances[founders[i]] = balances[founders[i]].add(tokensForFounders*foundersTokensAmountPercents[i]/100);
       weeklyTokensForFounders = weeklyTokensForFounders.sub(tokensForFounders*foundersTokensAmountPercents[i]/100);
     }  
  }

  function getWeeklyTokensForHoldersAmount() public view returns(uint256){
    return weeklyTokensForHolders;
  }
  
  function mintForHolders(address[] _to, uint256[] _amount) onlyOwner canMint public returns (bool) {
    require(_to.length == _amount.length);
    for (uint i=0; i<_to.length; i++) {
      assert(weeklyTokensForHolders > 0 && weeklyTokensForHolders >= _amount[i]);
      balances[_to[i]] = balances[_to[i]].add(_amount[i]);
      weeklyTokensForHolders = weeklyTokensForHolders.sub(_amount[i]);
      emit Mint(_to[i], _amount[i]);
      emit Transfer(address(0), _to[i], _amount[i]);
    }
    return true;
  }
  
  function getWeeklyTokensForWebsitesAmount() public view returns(uint256){
    return weeklyTokensForWebsites;
  }

  function mintForWebsites(address[] _to, uint256[] _amount) onlyOwner canMint public returns (bool) {
    require(_to.length == _amount.length);
    for (uint i=0; i<_to.length; i++) {
      assert(weeklyTokensForWebsites > 0 && weeklyTokensForWebsites >= _amount[i]);
      balances[_to[i]] = balances[_to[i]].add(_amount[i]);
      weeklyTokensForWebsites = weeklyTokensForWebsites.sub(_amount[i]);
      emit Mint(_to[i], _amount[i]);
      emit Transfer(address(0), _to[i], _amount[i]);
    }
    return true;
  }

  function calculateWeeklyTokensSupply() private {
    if (now >= start + 365 days && yearsAmount < 10) {
        weeklyTokensSupply = weeklyTokensSupply.mul(70).div(100);
        start = now;
        yearsAmount++;
    }
  }
  
}