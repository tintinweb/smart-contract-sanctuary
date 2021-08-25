//SourceUnit: BTDToken.sol

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

contract BTDToken is Context, IERC20, Ownable {
    using SafeMath for uint;
    
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    
    address public teamAddress = 0xd670bAae4268737196Fb926cC35f39F9f1c07A60;
    address public burnAddress = 0x0000000000000000000000000000000000000000;
    
    address public uniswapV2Router;
    address public uniswapV2Pair;
    
    uint256 public _burnFee = 3;
    uint256 public _teamFee = 5;
    uint256 public stopFee = 5000 * 10 ** uint256(decimals());
    
    mapping(address => bool) public isAdminAddress;

    constructor() public {
        _name = "BTD";
        _symbol = "BTD";
        
        isAdminAddress[_msgSender()] = true;
        isAdminAddress[teamAddress] = true;
        
        _mint(_msgSender(), 21000 * 10 ** uint256(decimals()));
    }

    function name() public view returns (string memory) {
        return _name;
    }
    
    function getAddress(address tmp) public pure returns(address){
        return tmp;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 6;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
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
    
    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
         _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        if(isAdminAddress[sender] || isAdminAddress[recipient]){
            standerTransfer(sender, recipient, amount);
            return;
        }
        
        require(uniswapV2Pair != address(0), "please set the uniswapV2Pair address");
        
        //transfer between two account
        if(sender != address(this) && sender != uniswapV2Pair && sender != uniswapV2Router && recipient != address(this) && recipient != uniswapV2Pair && recipient != uniswapV2Router){
            standerTransfer(sender, recipient, amount);
            return;
        }
        
        //buy token without fee
        if(recipient != address(this) && recipient != uniswapV2Pair && recipient != uniswapV2Router){
            standerTransfer(sender, recipient, amount);
            return;
        }
        
        if(stopFee >= _totalSupply){
            standerTransfer(sender, recipient, amount);
            return;
        }
        
        //seller token with fee
        //team fee
        uint256 _teamToken = amount.mul(_teamFee).div(100);
        _balances[teamAddress] = _balances[teamAddress].add(_teamToken);
        
        //burn token
        uint256 _burnToken = amount.mul(_burnFee).div(100);
        _burn(sender, _burnToken);
        
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] =  _balances[recipient].add(amount.sub(_teamToken).sub(_burnToken));
        emit Transfer(sender, recipient, amount);
    }
    
    function standerTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] =  _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function setUniswapV2Pair(address pair) public onlyOwner{
        uniswapV2Pair = pair;
    }
    
    function setFee(uint256 burnFee, uint256 teamFee) public onlyOwner{
        _burnFee = burnFee;
        _teamFee = teamFee;
    }
    
    function setStopFee(uint256 token) public onlyOwner{
        stopFee = token * 10 ** uint256(decimals());
    }
    
    function setAdminAddress(address account, bool ok) public onlyOwner{
        isAdminAddress[account] = ok;
    }
    
    function setTeamAddress(address acc) public onlyOwner(){
        teamAddress = acc;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        _balances[burnAddress] = _balances[burnAddress].add(amount);
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, burnAddress, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}