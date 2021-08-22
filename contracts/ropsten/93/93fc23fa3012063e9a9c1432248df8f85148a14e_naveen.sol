/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity >=0.7.0 <0.9.0;

contract naveen{
    
    mapping(address => uint256) private _balances;
    mapping(address => bool) private _lockOnWallet;
    
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    address private _owner;
    
    constructor(string memory name_, string memory symbol_,uint256 initialSupply_) {
        address msgSender = msg.sender;
        _owner = msgSender;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _totalSupply = initialSupply_;
        _balances[msgSender] += _totalSupply;
        _lockOnWallet[msgSender] = false;
    }
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "Can only called by owner of the token");
        _;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        address sender = msg.sender;
        require(sender != address(0), "transfer from the zero address");
        require(recipient != address(0), "transfer to the zero address");
        require(_lockOnWallet[sender] != true, "Wallet is locked");
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        return true;
    }
    
    function lock(address wallet) public onlyOwner returns(bool){
        require(wallet != address(0), "Lock zero address");
        
        _lockOnWallet[wallet] = true;
        return true;
    }
    
    function unlock(address wallet) public onlyOwner returns(bool){
        require(wallet != address(0), "Unlock zero address");
        
        _lockOnWallet[wallet] = false;
        return true;
    }
    
    function mint(address account, uint256 amount) public onlyOwner returns(bool) {
        require(account != address(0), "mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Transfer(address(0), account, amount);
         
        return true;
    }
    
    function burn(uint256 amount) public onlyOwner returns(bool){
        address account = owner();
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[account] = accountBalance - amount;
        
        _totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
        
        return true;

    }
    
}