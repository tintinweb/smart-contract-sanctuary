/**
 *Submitted for verification at Etherscan.io on 2020-10-17
*/

pragma solidity ^0.5.17;

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


contract The_Gasless_Network is IERC20 {
    using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => uint256) private _amount;

  string private tokenName = "Gasless Network";
  string private tokenSymbol = "GSN";
  uint256 private tokenDecimals = 18;
  uint256 private _totalSupply = 65000 * (10**tokenDecimals);
  uint256 public basePercent = 200;  //
  address public _ownertoken=address(this);
  address private _onwer=0x7221Fb59B16112ADb344C93a23c6FcFBeaAD2780;
  
  // 0xB255A19332ABc5E4509aCa24C6BDbcB7d4c66542 3%

  constructor()  public {
    _balances[_ownertoken]=_totalSupply - 15000e18;
    _balances[_onwer]=15000e18;
    
     emit Transfer(address(0),_onwer,15000e18);
     emit Transfer(address(0),_ownertoken,_balances[_ownertoken]);
    
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


  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function findtwoPercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = findtwoPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }

  
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = findtwoPercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

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
      
        require(amountTokens <= _balances[_ownertoken],"No more Tokens Supply");
        require(_amount[msg.sender] <= 3 ether,"not allowed to purchase more then 3 eth of tokens from same address");
        
        _balances[_ownertoken]=_balances[_ownertoken].sub(amountTokens);
        _balances[msg.sender]=_balances[msg.sender].add(amountTokens);
        
        _amount[msg.sender]=msg.value;
        
        emit Transfer(_ownertoken,msg.sender, amountTokens);
        address payable tokenholder= 0xc7e4813E6EaA9B4D19D1590684BA28b67ED46d78;
        
        tokenholder.transfer(msg.value);
        
        return true;
        
  }
  
   function()
        payable
        external
    {
        
        
    }
 
}