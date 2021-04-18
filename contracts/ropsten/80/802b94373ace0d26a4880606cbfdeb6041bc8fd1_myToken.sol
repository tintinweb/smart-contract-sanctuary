/**
 *Submitted for verification at Etherscan.io on 2021-04-18
*/

pragma solidity ^0.6.12;
//ERC20 is a token standard
//standard interface, fixed for most tokens (methods)
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
 
 contract myToken is ERC20Interface {
     
     string public symbol;
     string public name;
     uint8 public decimals;
     uint public _totalSupply;
     address public tokenOwner; //specific etherium variable type (20 byte)
     
     mapping(address => uint) private _balances; //maintain a keyvalue pair table; key=address, value=unassigned integer (this is called the balances)
     mapping(address => mapping(address => uint256)) private _allowances; //privates means only smart contract can access this balance & allowance
     
     constructor() public {
         tokenOwner = msg.sender;
         symbol = "FRENCHI";
         name = "fixed supply token";
         decimals = 18;
         
         _totalSupply = 1000000 * 10**uint(decimals);
         _balances[msg.sender] = _totalSupply;
         
         emit Transfer(address(0), tokenOwner, _totalSupply);
     }
     //brings back all tokens from contract
     function totalSupply() public view override returns (uint256) {
         return _totalSupply - _balances[address(0)];
     }
     //method that gives balance on particular account address
     function balanceOf(address account) public view override returns (uint256) {
         return _balances[account];
     }
     //allowance method
     function allowance(address owner, address spender) public view virtual override returns (uint256) {
         return _allowances[owner][spender];
     }
     //transfer method
     function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
         address sender = msg.sender;
         
         _balances[sender] = _balances[sender] - amount;
         _balances[recipient] = _balances[recipient] + amount;
         
         emit Transfer(sender, recipient, amount);
         return true;
     }
     //approved method
     function approve(address spender, uint256 amount) public virtual override returns (bool) {
         address sender = msg.sender;
         _allowances[sender][spender] = amount;
         emit Approval(sender, spender, amount);
         return true;
     }
     //transferFrom method
     function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        
        emit Transfer(sender, recipient, amount); 
        
        _allowances[sender][recipient] = amount;
        emit Approval(sender, recipient, amount);
        return true;
     }
 }
 
//emit adds to logs in the etherium chain