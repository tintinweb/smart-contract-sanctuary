/**
 *Submitted for verification at Etherscan.io on 2021-03-07
*/

pragma solidity ^0.4.25;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}
contract ERC20Details is ERC20 {

  uint8 public _decimal;
  string public _name;
  string public _symbol;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _decimal = decimals;
    _name = name;
    _symbol = symbol; 
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint8) {
    return _decimal;
  }
}

contract CyberWings is ERC20Details {
  using SafeMath for uint256;

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowed;
  
  string private constant _NAME  = "Cyber Wings Token";
  string private constant _SYMBOL = "CWT";
  uint8 private constant _DECIMALS = 10;
  uint256 private constant supply = 100000;
  address owner = msg.sender;
  uint256 _totalSupply = supply * 10 ** uint256(_DECIMALS);

  constructor() public payable ERC20Details(_NAME, _SYMBOL, _DECIMALS){
    mint(msg.sender, _totalSupply);
  }
  
  function mint(address account, uint256 amount) internal {
    require(amount != 0);
    balances[account] = balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address player) public view returns (uint256) {
    return balances[player];
  }

  function allowance(address player, address spender) public view returns (uint256) {
    return allowed[player][spender];
  }
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= balances[msg.sender]);
    require(to != address(0));
    uint256 _transfer = value.sub(0);
    balances[msg.sender] = balances[msg.sender].sub(value);
    balances[to] = balances[to].add(_transfer);
    _totalSupply = _totalSupply.sub(0);
    emit Transfer(msg.sender, to, _transfer);
    return true;
  }
    
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function approveAndCall(address spender, uint256 tokens, bytes data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= balances[from]);
    require(value <= allowed[from][msg.sender]);
    require(to != address(0));
    uint256 _transfer = value.sub(0);
    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(_transfer);
    _totalSupply = _totalSupply.sub(0);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, _transfer);
    return true;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}