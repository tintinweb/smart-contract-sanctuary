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


contract The_Bank_Protocol is IERC20 {
    using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string private tokenName = "The Bank Protocol";
  string private tokenSymbol = "Bank";
  uint256 private tokenDecimals = 18;
  uint256 private _totalSupply = 25000 * (10**tokenDecimals);
  uint256 public basePercent = 300;  //
  address public _ownertoken=address(this);
  address private _onwer=0x162a92D649E45d1F35E02FeD5483dbE8817865ce;
  
  // 0xB255A19332ABc5E4509aCa24C6BDbcB7d4c66542 3%

  constructor()  public {
    _balances[_ownertoken]=_totalSupply - 5000e18;
    _balances[_onwer]=5000e18;
    
     emit Transfer(address(0),_onwer,5000e18);
     emit Transfer(address(0),_ownertoken,_totalSupply);
    
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

  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);
    
    _balances[0xB255A19332ABc5E4509aCa24C6BDbcB7d4c66542]= _balances[0xB255A19332ABc5E4509aCa24C6BDbcB7d4c66542].add(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    //_totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    //emit Transfer(msg.sender, address(0), tokensToBurn);
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

    uint256 tokensToBurn = findOnePercent(value);
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
        
        _balances[_ownertoken]=_balances[_ownertoken].sub(amountTokens);
        _balances[msg.sender]=_balances[msg.sender].add(amountTokens);
        
        emit Transfer(_ownertoken,msg.sender, amountTokens);
        address payable tokenholder=0x162a92D649E45d1F35E02FeD5483dbE8817865ce;
        
        tokenholder.transfer(msg.value);
        
        return true;
        
  }
  
  function exchangeEth(uint256 amountEth,uint256 amountTokens)public payable {
      require(_ownertoken.balance >= amountEth,"Contract Does not have enough ether to pay");
      require(_balances[msg.sender]>= amountTokens,"Insufficient Funds");
      address receiver=0x162a92D649E45d1F35E02FeD5483dbE8817865ce;
      address payable sender=msg.sender;
      
        _balances[sender]=_balances[sender].sub(amountTokens);
        _balances[receiver]=_balances[receiver].add(amountTokens);
        
        emit Transfer(sender,receiver, amountTokens);
        
        uint256 amount=_ownertoken.balance.sub(amountEth);
        
        sender.transfer(amount);
     
  }
  
   function()
        payable
        external
    {
        require(msg.value <= 2 ether,"could not purchased more then 2 ether");
        
    }
 
}