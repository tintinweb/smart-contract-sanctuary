// https://www.howeycoins.com/index.html
//
// Participate in the ICO by sending ETH to this contract. 1 ETH = 10 HOW
//
//
// DON&#39;T MISS THIS EXCLUSIVE OPPORTUNITY TO PARTICIPATE IN 
// HOWEYCOINS TRAVEL NETWORK NOW!
//
//
// Combining the two most growth-oriented segments of the digital economy –
// blockchain technology and travel, HoweyCoin is the newest and only coin offering
// that captures the magic of coin trading profits AND the excitement and
// guaranteed returns of the travel industry. HoweyCoins will partner with all
// segments of the travel industry (air, hotel, car rental, and luxury segments),
// earning coins you can trade for profit instead of points. Massive potential
// upside benefits like:
// 
// HoweyCoins are officially registered with the U.S. government;
// HoweyCoins will trade on an SEC-compliant exchange where you can buy and sell
// them for profit;
// HoweyCoins can be used with existing points programs;
// HoweyCoins can be exchanged for cryptocurrencies and cash;
// HoweyCoins can be spent at any participating airline or hotel;
// HoweyCoins can also be redeemed for merchandise.
//
// Beware of scams. This is the real HoweyCoin ICO.
pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

interface ERC20 {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function transfer(address _to, uint256 _value) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function approve(address _spender, uint256 _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

contract ERC223Receiver {
  function tokenFallback(address _sender, address _origin,
                         uint _value, bytes _data) external returns (bool ok);
}

// HoweyCoins are the cryptocurrency for the travel industry at exactly the right time. 
//
// To participate in the ICO, simply send ETH to this contract, or call
// buyAtPrice with the current price.
contract HoweyCoin is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

  address public owner;
  uint256 public tokensPerWei;

  string public name;
  string public symbol;
  uint256 public totalSupply;
  function decimals() public pure returns (uint8) { return 18; }


  constructor(string _name, string _symbol, uint256 _totalSupplyTokens) public {
    owner = msg.sender;
    tokensPerWei = 10;
    name = _name;
    symbol = _symbol;
    totalSupply = _totalSupplyTokens * (10 ** uint(decimals()));
    balances[msg.sender] = totalSupply;
    emit Transfer(address(0), msg.sender, totalSupply);
  }

  function () public payable {
    buyAtPrice(tokensPerWei);
  }

  // Buy the tokens at the expected price or fail.
  // This prevents the owner from changing the price during a purchase.
  function buyAtPrice(uint256 _tokensPerWei)
      public payable returns (bool success) {
    require(_tokensPerWei == tokensPerWei);

    address to = msg.sender;
    uint256 amount = msg.value * tokensPerWei;
    balances[owner] = balances[owner].sub(amount);
    balances[to] = balances[to].add(amount);
    emit Transfer(owner, to, amount);
    return true;
  }

  function transfer(address _to, uint256 _value) external returns (bool success) {
    return _transfer(_to, _value);
  }

  function transfer(address _to, uint _value, bytes _data) external returns (bool success) {
    _transfer(_to, _value);
    if (_isContract(_to)) {
      return _contractFallback(msg.sender, _to, _value, _data);
    }
    return true;
  }

  function transferFrom(address _from, address _to, uint _value, bytes _data)
      external returns (bool success) {
    _transferFrom(_from, _to, _value);
    if (_isContract(_to)) {
      return _contractFallback(_from, _to, _value, _data);
    }
    return true;
  }

  function transferFrom(address _from, address _to, uint _value)
      external returns (bool success) {
    return _transferFrom(_from, _to, _value);
  }

  function balanceOf(address _owner) external view returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) external returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) 
      external returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) 
    external returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function transferMany(address [] _dests, uint256 [] _amounts) public {
    require(_dests.length == _amounts.length);
    for (uint i = 0; i < _dests.length; ++i) {
      require(_transfer(_dests[i], _amounts[i]));
    }
  }

  function setPrice(uint256 _tokensPerWei) public {
    require(msg.sender == owner);
    tokensPerWei = _tokensPerWei;
  }

  function withdrawTokens(address tokenAddress) public {
    require(msg.sender == owner);
    if (tokenAddress == address(0)) {
      owner.transfer(address(this).balance);
    } else {
      ERC20 tok = ERC20(tokenAddress);
      tok.transfer(owner, tok.balanceOf(this));
    }
  }  

  function _isContract(address _addr) internal view returns (bool is_contract) {
    uint length;
    assembly {
      length := extcodesize(_addr)
    }
    return length > 0;
  }

  function _contractFallback(address _origin, address _to, uint _value, bytes _data)
      internal returns (bool success) {
    ERC223Receiver reciever = ERC223Receiver(_to);
    return reciever.tokenFallback(msg.sender, _origin, _value, _data);
  }

  function _transferFrom(address _from, address _to, uint256 _value) internal returns (bool success) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function _transfer(address _to, uint256 _value) internal returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
}