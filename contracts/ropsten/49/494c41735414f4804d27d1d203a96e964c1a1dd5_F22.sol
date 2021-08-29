/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT
interface IUniswapV2Factory {                                                                  
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface FTPAntiBot {  // Here we create the interface to interact with AntiBot
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender, address _origin) external;
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
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private v_Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        v_Owner = msgSender;   
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return v_Owner;
    }
    function transferOwnership(address _address) public virtual onlyOwner {
        v_Owner = _address;
        emit OwnershipTransferred(_msgSender(), _address);
    }
    modifier onlyOwner() {
        require(_msgSender() == v_Owner, "Ownable: caller is not the owner");
        _;
    }                                                                                          
}
contract ERC20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Banned;
    address private _UniswapV2Pair;
    address payable private _DevAddress;
    IUniswapV2Router02 private _UniswapV2Router;
    FTPAntiBot private AntiBot;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _TxLimit;
    uint8 private _fee;
    bool private _AntiBotEnabled;
    bool private _TradingOpened;
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _DevAddress = payable(_msgSender());
        _fee = 1;
        _TxLimit = _totalSupply;
        _AntiBotEnabled = true;
        _TradingOpened = false;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual returns (uint8) {
        return 1;
    }
    function totalSupply() public view virtual override returns (uint256) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= _TxLimit, "Amount Exceeds Limit");
        require(!_Banned[sender] && !_Banned[recipient] && !_Banned[tx.origin], "Banned Address Detected");
        require(_TradingOpened, "Trading not open");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        //FTP Antibot check
        if(_AntiBotEnabled) {
            if(recipient == _UniswapV2Pair || sender == _UniswapV2Pair){
                require(!AntiBot.scanAddress(recipient, _UniswapV2Pair, tx.origin), "Bot Detected");
                require(!AntiBot.scanAddress(sender, _UniswapV2Pair, tx.origin), "Bot Detected");
            }
        }
        uint256 _feeAmount = amount.div(100).mul(_fee);
        uint256 _newAmount = amount.sub(_feeAmount);
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += _newAmount;
        _balances[_DevAddress] += _feeAmount;
        emit Transfer(sender, recipient, _newAmount);
        emit Transfer(sender, _DevAddress, _feeAmount);
        if(_AntiBotEnabled)
            AntiBot.registerBlock(sender, recipient, tx.origin); 
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }
    //Public Functions
    function checkIfBanned(address _address) external view returns (bool) { 
        return _Banned[_address];
    }
    function checkTxLimit() external view returns (uint256) { 
         return _TxLimit;
    }
    function checkDevTax() external view returns (uint8){
        return _fee;
    }
    function checkUniswapV2Pair() external view returns (address) {
        return _UniswapV2Pair;
    }
    function checkDevAddress() external view returns (address) {
        return _DevAddress;
    }
    function islaunched() external view returns (bool){
        return _TradingOpened;
    }
    // Owner Functions
    function addLiquidity() external onlyOwner() {
        _UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(_UniswapV2Router), _totalSupply);
        _UniswapV2Pair = IUniswapV2Factory(_UniswapV2Router.factory()).createPair(address(this), _UniswapV2Router.WETH());
        _UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_UniswapV2Pair).approve(address(_UniswapV2Router), type(uint).max);
    }
    function launch() external onlyOwner(){
        _TradingOpened = (_TradingOpened ? false : true);
    }
    function manualBan(address trade) public onlyOwner() {
        _Banned[trade] = (_Banned[trade] ? false : true);
    }
    function setTxLimit(uint256 _amount) external onlyOwner(){
        _TxLimit = _amount * 10 ** _decimals;
    }
    function setDevAddress(address payable _address) external onlyOwner() {
        _DevAddress = _address;
    }
    function setDevTax(uint8 _feeNew) external onlyOwner(){
        _fee = _feeNew;
    }
    function toggleAntiBot() external onlyOwner(){
        _AntiBotEnabled = (_AntiBotEnabled ? false : true);
    }
    function assignAntiBot(address _address) external onlyOwner(){ 
        AntiBot = FTPAntiBot(_address);
    }
}
contract F22 is ERC20 {
    uint8 immutable private _decimals = 18;
    uint256 private _totalSupply = 10000000000000 * 10 ** 18;
    constructor () ERC20('F22', 'F22') {
        _mint(_msgSender(), _totalSupply);
    }
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}