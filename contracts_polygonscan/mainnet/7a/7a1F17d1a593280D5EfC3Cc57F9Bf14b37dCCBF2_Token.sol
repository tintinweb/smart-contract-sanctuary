/**
 *Submitted for verification at polygonscan.com on 2021-10-01
*/

pragma solidity ^0.8.7;

contract Token {
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    uint public totalSupply = 0;
    string public name = "The Basement";
    string public symbol = "BSD";
    uint public decimals = 6;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor() {
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address owner) public returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(value >= 1000, 'transfer too low');
        require(balanceOf(msg.sender) >= value, 'balance too low');
        balances[to] += value;
        balances[msg.sender] -= value;
        burn(msg.sender, div(value, 1000));
       emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'balance too low');
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function mint(address account, uint256 amount) public returns(bool) {
      require(account != address(0), "BEP20: mint to the zero address");
      totalSupply = add(totalSupply, amount);
      balances[account] = add(balances[account], amount);
      emit Transfer(address(0), account, amount);
      return true;
    }
    
    function burn(address account, uint256 amount) public returns(bool) {
      require(account != address(0), "BEP20: burn from the zero address");
      balances[account] = sub(balances[account], amount, "BEP20: burn amount exceeds balance");
      totalSupply = sub(totalSupply, amount);
      emit Transfer(account, address(0), amount);
      return true;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      require(c >= a, "SafeMath: addition overflow");
    
      return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b <= a, errorMessage);
      uint256 c = a - b;
    
      return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
      if (a == 0) {
        return 0;
      }
    
      uint256 c = a * b;
      require(c / a == b, "SafeMath: multiplication overflow");
    
      return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
      return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      // Solidity only automatically asserts when dividing by 0
      require(b > 0, errorMessage);
      uint256 c = a / b;
      // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    
      return c;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
      return mod(a, b, "SafeMath: modulo by zero");
    }
    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
      require(b != 0, errorMessage);
      return a % b;
    }
}