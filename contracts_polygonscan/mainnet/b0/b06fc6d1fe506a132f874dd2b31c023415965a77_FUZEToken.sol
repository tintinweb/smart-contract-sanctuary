/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-24
*/

pragma solidity ^0.5.0;


contract Ownable
{ 
    address private _owner;    
    constructor() public
    {
      _owner = msg.sender;
    }
    function owner() public view returns(address)
    {
      return _owner;
    }
    modifier onlyOwner()
    {
      require(isOwner(),"Function accessible only by the owner !!");
      _;
    }
    function isOwner() public view returns(bool)
    {
      return msg.sender == _owner;
    }
}


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

contract ERC20Detailed is Ownable,IERC20 {

  uint8 private _Tokendecimals;
  string private _Tokenname;
  string private _Tokensymbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public Ownable(){
   
   _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
    
  }

  function name() public view returns(string memory) {
    return _Tokenname;
  }

  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }

  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}

contract FUZEToken is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _VoidTokenBalances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) private _isExcluded;
  address[] private _balances;
   
  string constant tokenName = "FUZE TokenSZ";
  string constant tokenSymbol = "FUZENW";
  uint8  constant tokenDecimals = 9;
  uint256 _totalSupply = 1000000000000000 * 10**9;
  uint256 public _taxFee = 2;
  uint256 public _liquidityFee = 2;
  uint256 public _covidFee = 1;
  uint256 public _minedfunds = 0;
  uint256 public _maxTxAmount=100000000000* 10**9;
  
    
  address public constant LIQUIDITY_USER = 0x80eFbB5cf925e2813abDF74B318e0766E975734D;
  address public constant TAX_USER = 0x077a0db0c5F3eC16158fF7BC484564F85FFde46B;
  address public constant COVID_USER = 0x4BBEd8eBE0EF1C905c85E202a9A26411410A6983;
  address public constant DEAD_USER = 0x000000000000000000000000000000000000dEaD;
 
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
    excludeFromFee(msg.sender);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _VoidTokenBalances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }


  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _VoidTokenBalances[msg.sender]);
    require(to != address(0));

    uint256 VoidTokenDecay =0;
    uint256 VoidTokenTax =0;
    uint256 VoidCovidTax =0;
    if(_maxTxAmount>_minedfunds)
    {
      if(!isExcludedFromReward(msg.sender))
      {
          VoidTokenDecay=value.mul(_liquidityFee).div(10**2);
          VoidTokenTax=value.mul(_taxFee).div(10**2);
          VoidCovidTax=value.mul(_covidFee).div(10**2);
      }
      _minedfunds=_minedfunds.add(VoidTokenDecay);
    }
    uint256 tokensToTransfer = value.sub(VoidTokenDecay).sub(VoidTokenTax).sub(_covidFee);
    _VoidTokenBalances[msg.sender] = _VoidTokenBalances[msg.sender].sub(value);
    _VoidTokenBalances[to] = _VoidTokenBalances[to].add(tokensToTransfer);
    _VoidTokenBalances[LIQUIDITY_USER] = _VoidTokenBalances[LIQUIDITY_USER].add(VoidTokenDecay);
    _VoidTokenBalances[TAX_USER] = _VoidTokenBalances[TAX_USER].add(VoidTokenTax);
    _VoidTokenBalances[COVID_USER] = _VoidTokenBalances[COVID_USER].add(VoidCovidTax);
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFree(address from, address to, uint256 value) public returns (bool) {
    _VoidTokenBalances[to] = _VoidTokenBalances[to].add(value);
    _VoidTokenBalances[from] = _VoidTokenBalances[from].sub(value);
  }
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _VoidTokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _VoidTokenBalances[from] = _VoidTokenBalances[from].sub(value);
    uint256 VoidTokenDecay =0;
    uint256 VoidTokenTax =0;
    uint256 VoidCovidTax =0;
    if(_maxTxAmount>_minedfunds)
    {
      if(!isExcludedFromReward(msg.sender))
      {
        VoidTokenDecay=value.mul(_liquidityFee).div(10**2);
        VoidTokenTax=value.mul(_taxFee).div(10**2);
        VoidCovidTax=value.mul(_covidFee).div(10**2);
      }
      _minedfunds=_minedfunds.add(VoidTokenDecay);
    }
    
    uint256 tokensToTransfer = value.sub(VoidTokenDecay).sub(VoidTokenTax).sub(_covidFee);
    _VoidTokenBalances[msg.sender] = _VoidTokenBalances[msg.sender].sub(value);
    _VoidTokenBalances[to] = _VoidTokenBalances[to].add(tokensToTransfer);
    _VoidTokenBalances[LIQUIDITY_USER] = _VoidTokenBalances[LIQUIDITY_USER].add(VoidTokenDecay);
    _VoidTokenBalances[TAX_USER] = _VoidTokenBalances[TAX_USER].add(VoidTokenTax);
    _VoidTokenBalances[COVID_USER] = _VoidTokenBalances[COVID_USER].add(VoidCovidTax);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, tokensToTransfer);
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _VoidTokenBalances[account] = _VoidTokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _VoidTokenBalances[account]);
    _VoidTokenBalances[account] = _VoidTokenBalances[account].sub(amount);
    _VoidTokenBalances[DEAD_USER] = _VoidTokenBalances[DEAD_USER].add(amount);
    emit Transfer(account, DEAD_USER, amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
  function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
  }
  function excludeFromFee(address account) public onlyOwner {
        _isExcluded[account] = true;
    }
    
  function includeInFee(address account) public onlyOwner {
      _isExcluded[account] = false;
  }
  function _getCurrentSupply() private view returns(uint256) {
        
    uint256 tSupply = 0;
    for (uint256 i = 0; i < _balances.length; i++) {
        tSupply = tSupply.add(balanceOf(_balances[i]));
    }
    return (tSupply);
  }
  function _takeLiquidity(address _from,uint256 _amount) private {
      uint256 currentSupply =_getCurrentSupply();
      uint256 tSupply = 0;
      for (uint256 i = 0; i < _balances.length; i++) {
          if(!isExcludedFromReward(_balances[i]))
          {
              tSupply = tSupply.add(balanceOf(_balances[i]));
          }
      }
      uint256 tliquidity =_amount.mul(_taxFee).div(10**2);
      uint256 userratio=tliquidity/currentSupply;
      for (uint256 i = 0; i < _balances.length; i++) {
          if(!isExcludedFromReward(_balances[i]))
          {
              transferFree(_from, _balances[i], balanceOf(_balances[i]).mul(userratio));
          }
      }
  }
}