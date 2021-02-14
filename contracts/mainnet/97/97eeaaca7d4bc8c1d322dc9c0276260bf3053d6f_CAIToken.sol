/**
 *Submitted for verification at Etherscan.io on 2021-02-13
*/

pragma solidity ^0.6.0;

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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event LockAddress(address indexed from, address indexed to, uint256 releaseTime);

}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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
}

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    
    constructor (string memory name, string memory symbol,uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        
        _afterTokenTransfer(recipient);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
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

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    function _afterTokenTransfer(address to) internal virtual { }
    
}

abstract contract ERC20Burnable is ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, msg.sender).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account,msg.sender, decreasedAllowance);
        _burn(account, amount);
    }
}

abstract contract LockedToken is ERC20,ERC20Burnable,Ownable{
    mapping (address => bool) private _Admin;
    struct _LockInfo {
        uint256 releaseTime;
        bool isUsed;
    }
    mapping (address => _LockInfo) private _LockList; 
    uint private _defaultLockDays;
    
    bool private _pause;
    
    constructor() Ownable() public{
        unlock(msg.sender);
        setAdmin(msg.sender,true);
        _defaultLockDays = 0;
    }
 
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        require(!_pause,"ERC20: transfer paused");
        require(!isLocked(from),"ERC20: address locked");
    }
    

    function _afterTokenTransfer(address to) internal virtual override {
        super._afterTokenTransfer(to);

        if (_Admin[to] == true) {
            _LockList[to].isUsed = true;
            _LockList[to].releaseTime = block.timestamp;
        } else if(_LockList[to].releaseTime == 0){
            _LockList[to].isUsed = true;
            _LockList[to].releaseTime = block.timestamp + (_defaultLockDays*24*3600);//(_defaultLockDays*600); 
        }
    }
    

    event lockSomeOne(address account, uint256 releaseTime);
    event unlockSomeOne(address account);
    function lock(address account, uint256 releaseTime) public onlyOwner {
        _LockList[account].isUsed = true;
        _LockList[account].releaseTime = releaseTime;
        emit lockSomeOne(account, releaseTime);
    }

    function unlock(address account) public onlyOwner{
        _LockList[account].isUsed = true;
        _LockList[account].releaseTime = block.timestamp;
        emit unlockSomeOne(account);
    }

    function isLocked(address account) internal returns (bool){
        if (_LockList[account].isUsed) {
            return _LockList[account].releaseTime > block.timestamp;
        } else {
            return false;
        }
    }
    
    function setTransferPause(bool pause) public onlyOwner{
        _pause = pause;
    }

    function setAdmin(address account,bool stats) public onlyOwner {
        _Admin[account]== stats;
        if (stats == false){
            _LockList[account].releaseTime = 1592881395022;
        }else{
            _LockList[account].releaseTime = block.timestamp;
        }
    }

    function setDefaultLockdays(uint dayNum) public onlyOwner {
        require(dayNum >= 0,"DVC:must gather than or equal 0!");
        _defaultLockDays = dayNum;
    }



    function lockDate(address user) public view returns (uint) {
        return _LockList[user].releaseTime;
    }
    
    function defaultLockDays() public view returns (uint) {
        return _defaultLockDays;
    }
    

    function mint(address account, uint256 amount )public onlyOwner{
        _mint(account,amount);
    }
}

contract CAIToken is LockedToken {
    string private _name = "CAI Protocol";
    string private _symbol = "CAI";
    uint8 private _decimals = 18;
    
    constructor () 
        ERC20(_name, _symbol, _decimals) 
        public{
            _mint(msg.sender,3000000000000000000000000000);
        }
        
}