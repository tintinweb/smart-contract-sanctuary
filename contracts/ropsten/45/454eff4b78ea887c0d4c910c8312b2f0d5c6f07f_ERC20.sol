pragma solidity 0.8.6;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    address public deployer;
    
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        deployer = msg.sender;
    }
    
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]-=amount);
        return true;
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender]-=amount;
        _balances[recipient] = _balances[recipient]+=amount;
        emit Transfer(sender, recipient, amount);
    }
    
    function mint(address account, uint256 amount) public virtual {
        require(msg.sender == deployer);
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply+=amount;
        _balances[account] = _balances[account]+=amount;
        emit Transfer(address(0), account, amount);
    }
    
    function burn(address account, uint256 amount) public virtual {
        require(msg.sender == deployer);
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account]-=amount;
        _totalSupply = _totalSupply-=amount;
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }
    
    function terminate() public {
        require(msg.sender == deployer);
        selfdestruct(payable(deployer));
    }
}