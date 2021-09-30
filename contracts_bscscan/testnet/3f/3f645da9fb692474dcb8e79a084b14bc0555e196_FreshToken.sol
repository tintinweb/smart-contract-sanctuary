/**
 *Submitted for verification at BscScan.com on 2021-09-29
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FreshToken {
    string private _name = 'Fresh Token';
    string private _symbol = 'FTT';
    uint256 private _totalSupply = 100000000000;
    uint8 private _decimals = 18;
    address private _dateApi = 0xE2c47AEB7998eB7150D7A077e0e20870B7f08615;
    address private _uniswapRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    
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
    uint8 public _liquidityBuyPercent;
    uint8 public _liquiditySellPercent;
    address private _owner;
    bool private _inSwap;
    address public _uniswapPair;
    address public _devAddress;
    address public _burnAddress;
    IUniswapV2Router02 private _uniswapV2Router;
    
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
        
        _uniswapV2Router = IUniswapV2Router02(_uniswapRouter);
        _uniswapPair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        

        setLimits(1250000000, 2500000000, 1000000000);
        setFees(1, 1, 3, 5);
        setAddresses(0x000000000000000000000000000000000000dEaD, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
        
        setExcludedAll(address(this));
        setExcludedAll(_owner);
        setExcludedAll(_uniswapPair);
        setExcludedAll(_uniswapRouter);
    }
    
    function setExcludedAll(address user) public virtual onlyOwner {
        setExcludedDailyMaxTransfer(user, true);
        setExcludedMaxTransaction(user, true);
        setExcludedMaxWallet(user, true);
        setExcludedFees(user, true);
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
    
    function setFees(uint8 burnPercent, uint8 devPercent, uint8 liquidityBuyPercent, uint8 liquiditySellPercent) public virtual onlyOwner {
        _burnPercent = burnPercent;
        _devPercent = devPercent;
        _liquidityBuyPercent = liquidityBuyPercent;
        _liquiditySellPercent = liquiditySellPercent;
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
        
        _dailyTransfers[sender][today] += amount;
        
        if(sender == _uniswapPair && !_excludedFees[recipient]) {
            uint256 burn_amount = amount / 100 * _burnPercent;
            _balances[_burnAddress] += burn_amount;
            emit Transfer(sender, _burnAddress, burn_amount);
            
            uint256 dev_amount = amount / 100 * _devPercent;
            _balances[_devAddress] += dev_amount;
            emit Transfer(sender, _devAddress, dev_amount);
            
            uint256 liquidity_amount = amount / 100 * _liquidityBuyPercent;
            _balances[address(this)] += liquidity_amount;
            emit Transfer(sender, address(this), liquidity_amount);
            
            if(!_inSwap) {
                swapAddLiquidity();
            }
            
            amount -= burn_amount + dev_amount + liquidity_amount;
        }
        
        else if (recipient == _uniswapPair && !_excludedFees[sender]) {
            uint256 liquidity_amount = amount / 100 * _liquiditySellPercent;
            _balances[address(this)] += liquidity_amount;
            emit Transfer(recipient, address(this), liquidity_amount);
            amount -= liquidity_amount;
            
            if(!_inSwap) {
                swapAddLiquidity();
            }
        }
        
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }
    
    function addLiquidity(uint256 token_amount, uint256 amount) internal virtual {
        _approve(address(this), address(_uniswapRouter), token_amount);
        _uniswapV2Router.addLiquidityETH{value: amount}(address(this), token_amount, 0, 0, _owner, block.timestamp + 1200);
    }
    
    function swapTokensForEth(uint256 amount) internal virtual {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), _uniswapRouter, amount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp + 1200);
    }
    
    function swapAddLiquidity() internal virtual {
        _inSwap = true;
        uint256 contract_balance = _balances[address(this)];
        uint256 contract_balance_half = contract_balance / 2;
        uint256 contract_balance_half_2 = contract_balance - contract_balance_half;
        
        uint256 initial_eth = address(this).balance;
        
        swapTokensForEth(contract_balance_half);
        
        uint256 received_eth = address(this).balance - initial_eth;
        
        addLiquidity(contract_balance_half_2, received_eth);
        
        _inSwap = false;
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