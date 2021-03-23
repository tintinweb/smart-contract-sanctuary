/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity <0.8.0;

contract audyCoin  {
    

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) public _allowances;

    uint256 public _totalSupply;
    string public _name;
    string public _symbol;
    uint8 public _decimals;
    
    constructor () public {
        _name = "AudyCoin";
        _symbol = "ADY";
        _decimals = 18;
    }
    function totalSupply() public view  returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view  returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public   returns (bool) {
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        return true;
    }
    function allowance(address owner, address spender) public view   returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public   returns (bool) {
        _allowances[msg.sender][spender] = amount;
        
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public   returns (bool) {
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        _allowances[sender][recipient] = amount;
    
        return true;
    
    }
    function _mint(address account, uint256 amount) public  {
        require(account != address(0), "ERC20: mint to the zero address");

        

        _totalSupply += amount;
        _balances[account] += amount;
    }
    
    
}