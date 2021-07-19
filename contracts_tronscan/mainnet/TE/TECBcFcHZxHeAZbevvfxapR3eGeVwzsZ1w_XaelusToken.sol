//SourceUnit: erc20.sol

pragma solidity ^0.5.0;

// SPDX-License-Identifier: MIT

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
*/

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


contract XaelusToken is IERC20  {
    
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => uint256) private _amount;
    
  string private tokenName = "Xaelus Token";
  string private tokenSymbol = "XNT";
  uint256 private tokenDecimals = 2;
  uint256 private _totalSupply = 10000000 * (10**tokenDecimals);
  address payable _onwer=0x591b5C8006Df72b0Ceb5727aDd57dBf1D062Bb98;
  
  constructor()  public {
    _balances[_onwer]=_totalSupply;
    emit Transfer(address(0),_onwer,_totalSupply);
  }
  
    function name() public view returns(string memory) {
    return tokenName;
  }

  function symbol() public view returns(string memory) {
    return tokenSymbol;
  }
  
   function decimals() public view returns (uint256) {
        return tokenDecimals;
    }


  function totalSupply() public  view  returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view   returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public  view  returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public   returns (bool) {
    _transfer(msg.sender,to,value);
    return true;
  }
  
  function _transfer(address from ,address to ,uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    
    emit Transfer(from, to, value);
  }

  function approve(address spender, uint256 value) public  returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public   returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, value);

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
  
}