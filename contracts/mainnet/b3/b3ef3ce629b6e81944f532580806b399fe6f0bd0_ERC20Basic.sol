pragma solidity ^0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {
    string public constant name = "NoCovid";
    string public constant symbol = "NCVT";
    uint8 public constant decimals = 18;
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 _totalSupply;
    
    using SafeMath for uint256;
    
    constructor(uint256 total) public {
      _totalSupply = total;
      balances[msg.sender] = _totalSupply;
    }
    
    function totalSupply() public override view returns (uint256) {
      return _totalSupply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
      return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
      _transfer(msg.sender, receiver, numTokens);
      return true;
    }
    
    function approve(address delegate, uint256 numTokens) public override returns (bool) {
      allowed[msg.sender][delegate] = numTokens;
      emit Approval(msg.sender, delegate, numTokens);
      return true;
    }
    
    function allowance(address owner, address delegate) public override view returns (uint) {
      return allowed[owner][delegate];
    }
    
    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
      require(numTokens <= allowed[owner][msg.sender]);
      allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
      _transfer(owner, buyer, numTokens);
      return true;
    }
    
    function burn(uint256 numTokens) public override returns (bool) {
      _burn(msg.sender, numTokens);
      return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
      uint256 receiveAmount = amount.mul(99).div(100);
      balances[sender] = balances[sender].sub(receiveAmount);
      balances[recipient] = balances[recipient].add(receiveAmount);
      emit Transfer(sender, recipient, receiveAmount);
      
      _burn(sender, amount.sub(receiveAmount));
    }
    
    function _burn(address account, uint256 numTokens) internal {
      require(account != address(0), "ERC20: burn from the zero address");

      balances[account] = balances[account].sub(numTokens);
      _totalSupply = _totalSupply.sub(numTokens);
      emit Transfer(account, address(0), numTokens);
    }
}

library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
      uint256 c = a * b;
      require(c / a == b);
      return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      require(b > 0);
      uint256 c = a / b;
      return c;
    }
}