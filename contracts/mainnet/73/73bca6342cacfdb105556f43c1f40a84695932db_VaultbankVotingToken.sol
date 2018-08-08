pragma solidity ^0.4.19;

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

contract Nonpayable {

  // ------------------------------------------------------------------------
  // Don&#39;t accept ETH
  // ------------------------------------------------------------------------
  function () public payable {
    revert();
  }
}

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function destroy() public onlyOwner {
    selfdestruct(owner);
  }
}

contract Regulated is Ownable {
  event Whitelisted(address indexed customer);
  event Blacklisted(address indexed customer);
  
  mapping(address => bool) regulationStatus;

  function whitelist(address customer) public onlyOwner {
    regulationStatus[customer] = true;
    Whitelisted(customer);
  }

  function blacklist(address customer) public onlyOwner {
    regulationStatus[customer] = false;
    Blacklisted(customer);
  }
  
  function ensureRegulated(address customer) public constant {
    require(regulationStatus[customer] == true);
  }

  function isRegulated(address customer) public constant returns (bool approved) { 
    return regulationStatus[customer];
  }
}

contract ERC20 {
  function totalSupply() public constant returns (uint);
  function balanceOf(address tokenOwner) public constant returns (uint balance);
  function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
  function transfer(address to, uint tokens) public returns (bool success);
  function approve(address spender, uint tokens) public returns (bool success);
  function transferFrom(address from, address to, uint tokens) public returns (bool success);

  event Transfer(address indexed from, address indexed to, uint tokens);
  event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract VaultbankVotingToken is ERC20, Regulated, Nonpayable {
  using SafeMath for uint;

  string public symbol;
  string public  name;
  uint8 public decimals;
  uint public _totalSupply;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;

  function VaultbankVotingToken() public {
    symbol = "VBV";
    name = "Vaultbank Voting Token";
    decimals = 0;
    _totalSupply = 1000;

    regulationStatus[address(0)] = true;
    Whitelisted(address(0));
    regulationStatus[owner] = true;
    Whitelisted(owner);

    balances[owner] = _totalSupply;
    Transfer(address(0), owner, _totalSupply);
  }

  function issue(address recipient, uint tokens) public onlyOwner returns (bool success) {
    require(recipient != address(0));
    require(recipient != owner);
    
    whitelist(recipient);
    transfer(recipient, tokens);
    return true;
  }

  function issueAndLock(address recipient, uint tokens) public onlyOwner returns (bool success) {
    issue(recipient, tokens);
    blacklist(recipient);
    return true;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    require(newOwner != owner);
   
    whitelist(newOwner);
    transfer(newOwner, balances[owner]);
    owner = newOwner;
  }

  function totalSupply() public constant returns (uint supply) {
    return _totalSupply - balances[address(0)];
  }

  function balanceOf(address tokenOwner) public constant returns (uint balance) {
    return balances[tokenOwner];
  }

  function transfer(address to, uint tokens) public returns (bool success) {
    ensureRegulated(msg.sender);
    ensureRegulated(to);
    
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint tokens) public returns (bool success) {
    // Put a check for race condition issue with approval workflow of ERC20
    require((tokens == 0) || (allowed[msg.sender][spender] == 0));
    
    allowed[msg.sender][spender] = tokens;
    Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
    ensureRegulated(from);
    ensureRegulated(to);

    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
    return allowed[tokenOwner][spender];
  }
}