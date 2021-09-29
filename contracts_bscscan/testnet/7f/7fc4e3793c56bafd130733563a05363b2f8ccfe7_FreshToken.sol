/**
 *Submitted for verification at BscScan.com on 2021-09-28
*/

pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

interface DateAPI {
    function date() external view returns (string memory);
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}


interface IUniswapV2Router02 is IUniswapV2Router01 {
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FreshToken {
    string public _name = 'Fresh Token';
    string public _symbol = 'FTT';
    uint256 public _totalSupply = 25000;
    uint8 public _decimals = 8;
    address public _dateApi = 0xE2c47AEB7998eB7150D7A077e0e20870B7f08615;
    address public _uniswapRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => mapping (string => uint256)) private _dailyTransfers;
    mapping (address => bool) private _excludedDailyMaxTransfer;
    mapping (address => bool) private _excludedMaxWallet;
    mapping (address => bool) private _excludedMaxTransaction;
    mapping (address => bool) private _excludedFees;
    mapping (address => bool) private _blacklisted;
    uint256 public _dailyMaxTransfer;
    uint256 public _maxWallet;
    uint256 public _maxTransaction;
    uint8 public _burnPercent;
    uint8 public _devPercent;
    uint8 public _liquidityPercent;
    address public _owner;
    address public _uniswapPair;
    address public _devAddress;
    address public _burnAddress;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    receive () external payable {}
    
    modifier onlyOwner() {
        require(_owner == msg.sender, 'Only the owner can call this function!');
        _;
    }
    
    constructor () {
        emit OwnershipTransferred(_owner, msg.sender);
        _owner = msg.sender;
        _totalSupply = _totalSupply * 10**_decimals;
        _balances[_owner] = _totalSupply;
        
        setExcludedAll(address(this));
        setExcludedAll(_owner);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
        _uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
    }
    
    function setExcludedAll(address user) public virtual onlyOwner {
        setExcludedDailyMaxTransfer(user, true);
        setExcludedMaxTransaction(user, true);
        setExcludedMaxWallet(user, true);
    }
    
    function setExcludedDailyMaxTransfer(address user, bool status) public virtual onlyOwner {
        _excludedDailyMaxTransfer[user] = status;
    }
    
    function setAddresses(address burnAddress, address devAddress) public virtual onlyOwner {
        _burnAddress = burnAddress;
        _devAddress = devAddress;
    }
    
    function setLimits(uint256 dailyMaxTransferAmount, uint256 maxWalletAmount, uint256 maxTransactionAmount) public virtual onlyOwner {
        _dailyMaxTransfer = dailyMaxTransferAmount * 10**_decimals;
        _maxWallet = maxWalletAmount * 10**_decimals;
        _maxTransaction = maxTransactionAmount * 10**_decimals;
    }
    
    function setFees(uint8 burnPercent, uint8 devPercent, uint8 liquidityPercent) public virtual onlyOwner {
        _burnPercent = burnPercent;
        _devPercent = devPercent;
        _liquidityPercent = liquidityPercent;
    }
    
    function setExcludedMaxTransaction(address user, bool status) public virtual onlyOwner {
        _excludedMaxTransaction[user] = status;
    }
    
    function setExcludedMaxWallet(address user, bool status) public virtual onlyOwner {
        _excludedMaxWallet[user] = status;
    }
    
    function setExcludedFees(address user, bool status) public virtual onlyOwner {
        _excludedFees[user] = status;
    }
    
    function setBlacklistWallet(address user, bool status) public virtual onlyOwner {
        _blacklisted[user] = status;
    }
    
    function getDate() public view returns (string memory) {
        DateAPI a = DateAPI(_dateApi);
        return a.date();
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
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(!_blacklisted[sender] && !_blacklisted[recipient], 'Sender or recipient is blacklisted!');
        
        string memory today = getDate();
        
        if(!_excludedMaxTransaction[sender]) {
            require(amount <= _maxTransaction, 'Exceeds max transaction limit!');
        }
        
        if(!_excludedMaxWallet[recipient]) {
            require(_balances[recipient] + amount <= _maxWallet, 'Exceeds max wallet limit!');
        }
        
        if(!_excludedDailyMaxTransfer[sender]) {
            require(_dailyTransfers[sender][today] + amount <= _dailyMaxTransfer, 'Exceeds daily max transfer limit!');
        }
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, 'Amount exceeds sender\'s balance!');
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        
        _dailyTransfers[sender][today] += amount;
        
        emit Transfer(sender, recipient, amount);
        
        if(sender == _uniswapPair && !_excludedFees[recipient]) {
            uint256 burn_amount = amount / 100 * _burnPercent;
            
            _balances[recipient] -= burn_amount;
            _balances[_burnAddress] += burn_amount;
            
            emit Transfer(recipient, _burnAddress, burn_amount);
            
            uint256 dev_amount = amount / 100 * _devPercent;
            
            _balances[recipient] -= dev_amount;
            _balances[_devAddress] += dev_amount;
            
            emit Transfer(recipient, _devAddress, dev_amount);
        }
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), 'Wallet address can not be the zero address!');
        require(spender != address(0), 'Spender can not be the zero address!');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, 'Amount exceeds allowance!');
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, 'Decreased allowance below zero!');
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Owner can not be the zero address!');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function withdraw(uint256 amount) public payable onlyOwner returns (bool) {
        require(amount <= address(this).balance, 'Withdrawal amount exceeds balance!');
        payable(msg.sender).transfer(amount);
        return true;
    }
    
    function withdrawToken(address tokenContract, uint256 amount) public virtual onlyOwner {
        IERC20 _tokenContract = IERC20(tokenContract);
        _tokenContract.transfer(msg.sender, amount);
    }
}