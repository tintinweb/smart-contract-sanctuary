/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

pragma solidity ^0.6.12;
 
 interface ERC20Interface {
   function totalSupply() external view returns (uint256);
   function balanceOf(address account) external view returns (uint256);
   function allowance(address owner, address spender) external view returns (uint256);
   function transfer(address recipient, uint256 amount) external returns (bool);
   function approve(address spender, uint256 amount) external returns (bool);
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

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
        require(b > 0, errorMessage);
        uint256 c = a / b;

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

contract NakulToken is ERC20Interface {
    using SafeMath for uint256;
    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;
    address public tokenOwner;
    
    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    constructor() public {
        tokenOwner = msg.sender;
        symbol="Nakul"; 
        name="x20204027"; 
        decimals=18;
        _totalSupply = 1000000 * 10**uint(decimals);
        _balances[tokenOwner] = _totalSupply;
        emit Transfer(address(0), tokenOwner, _totalSupply);
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply - _balances[address(0)];
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        
        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        
        _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
        return true;
    }
    

 function distributeToken(address[] memory recipient, uint256 amount) public   returns (bool) {
        address sender = msg.sender;
        
        for (uint i = 0; i < recipient.length; i++) {
         _balances[sender] = _balances[sender].sub(amount, "transfer amount exceeds balance");
          _balances[recipient[i]] = _balances[recipient[i]].add(amount);
         emit Transfer(sender, recipient[i], amount);
     }
         return true;
     
    }

}