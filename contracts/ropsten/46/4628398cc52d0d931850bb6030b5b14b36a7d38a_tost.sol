/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// SPDX-License-Identifier: UNLISENCED

pragma solidity 0.7.6;

//math/SafeMath.sol

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

//token/ERC20/IERC20.sol

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

//utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract tost is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;
    mapping (address => uint256) private _sbalances;
    mapping (address => uint) private _stime;

    mapping (address => mapping (address => uint256)) private _allowances;
    event Stake(address indexed account, uint256 amount, uint256 stakedSupply);
    event Unstake(address indexed account, uint256 amount, uint256 stakedSupply);
    event Mint(address indexed account, uint256 amount, uint256 totalSupply);
    event Burn(address indexed account, uint256 amount, uint256 totalSupply);

    uint256 private _totalSupply;
    uint256 private _stotalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor () {
        _name = "tost";
        _symbol = "t";
        _decimals = 18;
        _mint(msg.sender, 1000000000000000000000);
    }
    
    function name() public virtual view returns (string memory) {
        return _name;
    }
    
    function symbol() public virtual view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public virtual view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function stotalSupply() public view returns (uint256) {
        return _stotalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function sbalanceOf(address account) public view returns (uint256) {
        return _sbalances[account];
    }
    
    function stime(address account) public view returns (uint) {
        return _stime[account];
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue));
        return true;
    }
    
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
    
    function stake(uint256 amount) public virtual {
        _stake(_msgSender(), amount);
    }
    
    function unstake() public virtual {
        _unstake(_msgSender());
    }
    
    function mint() public virtual {
        _smint(_msgSender());
    }
    
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount);

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    
    function _stake(address account, uint256 amount) internal virtual {
        require(account != address(0), "WW: stake from the zero address");
        require(amount >= 10000, "WW: amount has to be over 10000");
        require(amount <= _balances[account], "WW: amount exceeds balance");
        
        _balances[account] = _balances[account].sub(amount);
        _sbalances[account] = _sbalances[account].add(amount);
        _stotalSupply = _stotalSupply.add(amount);
        _stime[account] = block.timestamp;
        emit Transfer(account, address(this), amount);
        emit Stake(account, amount, _stotalSupply);
    }
    
    function _unstake(address account) internal virtual {
        require(account != address(0), "WW: stake from the zero address");
        require(0 < _sbalances[account], "WW: amount exceeds balance");
        
        _balances[account] = _balances[account].add(_sbalances[account]);
        _stotalSupply = _stotalSupply.sub(_sbalances[account]);
        uint256 amount = _sbalances[account];
        _sbalances[account] = 0;
        _stime[account] = block.timestamp;
        emit Transfer(address(this), account, amount);
        emit Unstake(account, amount, _stotalSupply);
    }
    
    function _smint(address account) internal virtual {
        require(0 < _sbalances[account], "WW: amount exceeds balance");
        uint256 timePassed = block.timestamp;
        timePassed = timePassed.sub(_stime[account]);
        require(1728 < timePassed, "WW: no enough time has passed since stake");
        
        uint256 amount = _sbalances[account].div(10000);
        amount = amount.mul(timePassed.div(1728));
        _balances[account] = _balances[account].add(amount);
        _totalSupply = _totalSupply.add(amount);
        _stime[account] = block.timestamp;
        emit Transfer(address(this), account, amount);
        emit Mint(account, amount, _totalSupply);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "WW: transfer from the zero address");
        require(recipient != address(0), "WW: transfer to the zero address");
        require(amount <= _balances[sender], "WW: amount exceeds balance");
        
        _burn(sender, amount.div(500));
        amount = amount.sub(amount.div(500));
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "WW: mint to the zero address");
        
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        emit Mint(account, amount, _totalSupply);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "WW: burn from the zero address");
        require(balanceOf(account) >= amount, "WW: Not enough LMT balance");

        _balances[account] = _balances[account].sub(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "WW: approve from the zero address");
        require(spender != address(0), "WW: approve to the zero address");
        require(amount <= _balances[owner], "WW: amount exceeds balance");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
}
/*
* Coded by TheLegend27
*/