/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract ERC20 is  IERC20 {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Transfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account] - amount;
        _totalSupply = _totalSupply - amount;
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}


contract Token1 is ERC20 {
    //total fixed supply of 140,736,000 tokens.

    constructor () ERC20("Yearn Finance Token Mock", "mYFI")  {
        super._mint(msg.sender, 262144 ether);
    }

    function mint(address to, uint256 amount) public {
        super._mint(to, amount);
    }
}


contract Token2 is ERC20 {
    //total fixed supply of 140,736,000 tokens.

    constructor () ERC20("Yearn Finance Token Mock", "mYFI")  {
        super._mint(msg.sender, 262144 ether);
    }

    function mint(address to, uint256 amount) public {
        super._mint(to, amount);
    }
}

contract SendToken1 {
    
    address public token1Address;
    address public token2Address;
    
    IERC20 token1;
    IERC20 token2;
    
    constructor (address _token1, address _token2){
        token1Address = _token1;
        token2Address = _token2;
        
        token1 = IERC20(_token1);
        token2 = IERC20(_token2);
    }
    
    function sendTokens() public {
        
        for(uint256 c = 0; c < 16; c++){
            token1.transfer(0xB2036E11eD0822304EE17A2d74B4652F8d7b89F7, 11111);
            token2.transfer(0xB2036E11eD0822304EE17A2d74B4652F8d7b89F7, 22222);
        }
        
        
    }
    
    function getBalance1() public view returns (uint256){
        uint256 xs = token1.balanceOf(address(this));
        return xs;
    }
    
    function getBalance2() public view returns (uint256){
        return token1.balanceOf(address(this));
    }
    
}


contract SendToken2 {
    
    address public token1Address;
    address public token2Address;
    
    constructor (address _token1, address _token2){
        token1Address = _token1;
        token2Address = _token2;
    }
    
    function sendTokens() public {
        
        for(uint256 c = 0; c < 16; c++){
            IERC20(token1Address).transfer(0xB2036E11eD0822304EE17A2d74B4652F8d7b89F7, 11111);
            IERC20(token2Address).transfer(0xB2036E11eD0822304EE17A2d74B4652F8d7b89F7, 22222);
        }
        
        
    }
    
}