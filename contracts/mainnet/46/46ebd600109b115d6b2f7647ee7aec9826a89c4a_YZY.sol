// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.25 <0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

abstract contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract YZY is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) public _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  address[] internal _tokenHolders;

  string constant tokenName = "YZY Art Fund";
  string constant tokenSymbol = "YZY";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 1100000000000000000000000;
  uint256 _minSupply = 111111111000000000000000;
  uint256 public burnPercent = 1000;
  uint256 public rewardPercent = 1000;
  uint256 private _basePercent = 1000;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() override public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) override public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) override public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) override public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    if (_totalSupply <= _minSupply) {
      _balances[msg.sender] = _balances[msg.sender].sub(value);
      _balances[to] = _balances[to].add(value);

      emit Transfer(msg.sender, to, value);
    } else {
      (uint256 tokensToBurn, uint256 tokensToReward) = burnAndReward(value);
      uint256 tokensToTransfer = value.sub(tokensToBurn);
      tokensToTransfer = tokensToTransfer.sub(tokensToReward);

      _balances[msg.sender] = _balances[msg.sender].sub(value);
      _balances[to] = _balances[to].add(tokensToTransfer);

      if (_balances[msg.sender] == 0) {
        _removeTokenHolder(msg.sender);
      }

      (bool isNewholder, ) = _isTokenHolder(to);
      if (!isNewholder) _tokenHolders.push(to);

      _totalSupply = _totalSupply.sub(tokensToBurn);
      _totalSupply = _totalSupply.sub(tokensToReward);

      emit Transfer(msg.sender, to, tokensToTransfer);
      emit Transfer(msg.sender, address(0), tokensToBurn);

      _distributeReward(msg.sender, to, tokensToReward);
    }
    return true;
  }

  function transferFrom(address from, address to, uint256 value) override public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    if (_totalSupply <= _minSupply) {
      _balances[from] = _balances[from].sub(value);
      _balances[to] = _balances[to].add(value);
      _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

      emit Transfer(from, to, value);
    } else {
      (uint256 tokensToBurn, uint256 tokensToReward) = burnAndReward(value);
      uint256 tokensToTransfer = value.sub(tokensToBurn);
      tokensToTransfer = tokensToTransfer.sub(tokensToReward);

      _balances[from] = _balances[from].sub(value);
      _balances[to] = _balances[to].add(tokensToTransfer);

      _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

      if (_balances[from] == 0) {
        _removeTokenHolder(from);
      }

      (bool isNewholder, ) = _isTokenHolder(to);
      if (!isNewholder) _tokenHolders.push(to);

      _totalSupply = _totalSupply.sub(tokensToBurn);
      _totalSupply = _totalSupply.sub(tokensToReward);

      emit Transfer(from, to, tokensToTransfer);
      emit Transfer(from, address(0), tokensToBurn);

      _distributeReward(from, to, tokensToReward);
    }

    return true;
  }

  function approve(address spender, uint256 value) override public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function burnAndReward(uint256 value) public view returns (uint256, uint256)  {
    uint256 roundValue = value.ceil(_basePercent);
    uint256 burnValue = roundValue.mul(burnPercent).div(100000);
    uint256 rewardValue = roundValue.mul(rewardPercent).div(100000);
    return (burnValue, rewardValue);
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    _tokenHolders.push(account);
    emit Transfer(address(0), account, amount);
  }

  function _removeTokenHolder(address _holder) internal {
    (bool isHolder, uint256 s) = _isTokenHolder(_holder);
    if (isHolder) {
      _tokenHolders[s] = _tokenHolders[_tokenHolders.length - 1];
      _tokenHolders.pop();
    }
  }

  function _isTokenHolder(address _address) internal view returns(bool, uint256)
  {
      for (uint256 s = 0; s < _tokenHolders.length; s += 1){
          if (_address == _tokenHolders[s]) return (true, s);
      }
      return (false, 0);
  }

  function _distributeReward(address from, address to, uint256 value) internal {
    uint256 _totalReward = 0;
    uint256 _sumBalance = _totalSupply.sub(_balances[from]);
    _sumBalance = _totalSupply.sub(_balances[to]);
    for (uint256 s = 0; s < _tokenHolders.length; s += 1) {
      address _holder = _tokenHolders[s];
      if (_holder != from && _holder != to) {
        uint256 _reward = _balances[_holder].mul(value);
        _reward = _reward.div(_sumBalance);
        _balances[_holder] = _balances[_holder].add(_reward);
        _totalReward = _totalReward.add(_reward);

        emit Transfer(address(0), _holder, _reward);
      }
    }
    _totalSupply = _totalSupply.add(_totalReward);
  }
}