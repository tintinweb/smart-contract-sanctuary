/**
 *Submitted for verification at Etherscan.io on 2020-12-14
*/

pragma solidity ^0.6.0;

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


contract SaveMyAss is IERC20  {
    
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    mapping (address => uint256) private _amount;
    uint256 private balance1;
    uint256 private balance2;
    
  string private tokenName = "Save My Ass Coin";
  string private tokenSymbol = "SMA";
  uint256 private tokenDecimals = 18;
  uint256 private _totalSupply = 10000000 * (10**tokenDecimals);
  address private  _ownertoken=address(this);
  address private _onwer1=0x8A4748424bcaEfEa5859e6D517d4d1825b81b3FE;
  uint constant Rate=500;
  uint private startDate;
  
  constructor()  public {
    _balances[_onwer1]=_totalSupply;
    startDate=now;
    emit Transfer(address(0),_onwer1,_totalSupply);
  }
  
  function contractBalance() external view returns(uint256){
      return _ownertoken.balance;
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


  function totalSupply() public  view override returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view  override returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public  view override returns (uint256) {
    return _allowed[owner][spender];
  }

  function transfer(address to, uint256 value) public override  returns (bool) {
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

  function approve(address spender, uint256 value) public override returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public override  returns (bool) {
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
   
  function exchangeToken(uint256 amountTokens)public payable returns (bool)  {
      
        require(amountTokens <= _balances[_onwer1],"No more Tokens Supply");
        
        require(startDate >= startDate + 17 days,"pre-sale is not started yet");
        
        _balances[_onwer1]=_balances[_onwer1].sub(amountTokens);
        _balances[msg.sender]=_balances[msg.sender].add(amountTokens);
        
        emit Transfer(_onwer1,msg.sender, amountTokens);
        
        payable(_ownertoken).transfer(msg.value);
            
        return true; 
    }
  
  
   receive()
        payable
        external
    {
        
        require(startDate >= startDate + 17 days,"pre-sale is not started yet");
        
        _transfer(_onwer1,msg.sender,msg.value * Rate);
        payable(_onwer1).transfer(msg.value);
    }
  
}