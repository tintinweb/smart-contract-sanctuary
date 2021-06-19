/**
 *Submitted for verification at Etherscan.io on 2021-06-18
*/

pragma solidity ^0.8.4;

interface IERC20{
    
     function name() external view returns (string memory);

    function symbol() external view returns(string memory);

    function decimals() external view returns(uint256);

    function totalSupply() external view returns(uint256);
    
    function balanceOf(address account) external view returns(uint256);
    
    function transfer(address recipient, uint256 amount) external returns(bool);

    function allowance(address owner, address spender) external view returns(uint256);

    function approve(address spender, uint256 amount) external returns(bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns(bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns(bool);
    
    function mint(address user, uint256 amount) external;
    
    function burn(uint256 amount) external;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    event Mint(address indexed to, uint256 amount);
    
    event Burn(address indexed from, uint256 amount);
    
}
contract MCFToken is IERC20{
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply;

    address private _owner;
    
    constructor (uint256 totalsupply) {
        _totalSupply = totalsupply * (10 ** uint256(10));
        _balances[msg.sender] = totalsupply * (10 ** uint256(10));
        _owner = msg.sender;
    }

    function name() external view override returns (string memory) {
        return "MCF Token";
    }

    function symbol() external view override returns (string memory) {
        return "MCF";
    }

    function decimals() external view override returns (uint256) {
        return 10;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _allowances[sender][msg.sender] -= amount;
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external  override returns (bool) {
        _allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external override returns (bool) {
        if(subtractedValue > _allowances[msg.sender][spender]){_allowances[msg.sender][spender] = 0;}
        else{_allowances[msg.sender][spender] -= subtractedValue;}
        emit Approval(msg.sender, spender, _allowances[msg.sender][spender]);
        return true;
    }
    
    function mint(address user, uint256 amount) external override {
        require(msg.sender == _owner);
        _balances[user] += amount;
        _totalSupply += amount;
        emit Mint(user, amount);
    }
    
    function burn(uint256 amount) external override {
        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Burn(msg.sender, amount);
    }

}