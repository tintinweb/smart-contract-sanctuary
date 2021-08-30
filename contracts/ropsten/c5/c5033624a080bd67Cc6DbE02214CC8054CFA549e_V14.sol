/**
 *Submitted for verification at Etherscan.io on 2021-08-30
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
contract V14 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _Banned;
    address private _UniswapV2Pair;
    address payable private _DevAddress;
    IUniswapV2Router02 private _UniswapV2Router;
    FTPAntiBot private _AntiBot;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _TxLimit;
    uint8 private _fee;
    bool private _AntiBotEnabled;
    bool private _TradingOpened;
    constructor () {
        _name = 'V14';
        _symbol  = 'V14';
        _decimals = 18;
        _totalSupply = 10000000000000 * 10 ** _decimals;
        _TxLimit = _totalSupply;
        _DevAddress = payable(_msgSender());
        _fee = 1;
        _AntiBotEnabled = true;
        _TradingOpened = false;
        _AntiBot = FTPAntiBot(0xCD5312d086f078D1554e8813C27Cf6C9D1C3D9b3); //AntiBotV2
        _UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //UniswapV2
        emit Transfer(address(0), _DevAddress, _totalSupply);
    }
    function name() public view returns (string memory) {
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
    function balanceOf(address account_) public view virtual override returns (uint256) {
        return _balances[account_];
    }
    function transfer(address recipient_, uint256 amount_) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient_, amount_);
        return true;
    }
    function allowance(address owner_, address spender_) public view virtual override returns (uint256) {
        return _allowances[owner_][spender_];
    }
    function approve(address spender_, uint256 amount_) public virtual override returns (bool) {
        _approve(_msgSender(), spender_, amount_);
        return true;
    }
    function transferFrom(address sender_, address recipient_, uint256 amount_) public virtual override returns (bool) {
        _transfer(sender_, recipient_, amount_);
        _approve(sender_, _msgSender(), _allowances[sender_][_msgSender()].sub(amount_, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender_, uint256 addedValue_) public virtual returns (bool) {
        _approve(_msgSender(), spender_, _allowances[_msgSender()][spender_] + addedValue_);
        return true;
    }
    function decreaseAllowance(address spender_, uint256 subtractedValue_) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender_];
        require(currentAllowance >= subtractedValue_, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender_, currentAllowance - subtractedValue_);
        return true;
    }
    function _transfer(address sender_, address recipient_, uint256 amount_) internal virtual {
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");
        require(amount_ > 0, "Transfer amount must be greater than zero");
        require(amount_ <= _TxLimit, "Amount Exceeds Limit");
        require(!_Banned[sender_] && !_Banned[recipient_] && !_Banned[tx.origin], "Banned Address Detected");
        require(_TradingOpened, "Trading not open");
        uint256 senderBalance = _balances[sender_];
        require(senderBalance >= amount_, "ERC20: transfer amount exceeds balance");
        //FTP Antibot check
        if(_AntiBotEnabled) {
            if(recipient_ == _UniswapV2Pair || sender_ == _UniswapV2Pair){
                require(!_AntiBot.scanAddress(recipient_, _UniswapV2Pair, tx.origin), "Bot Detected");
                require(!_AntiBot.scanAddress(sender_, _UniswapV2Pair, tx.origin), "Bot Detected");
            }
        }
        uint256 _feeAmount = amount_.div(100).mul(_fee);
        uint256 _newAmount = amount_.sub(_feeAmount);
        _balances[sender_] = senderBalance - amount_;
        _balances[recipient_] += _newAmount;
        _balances[_DevAddress] += _feeAmount;
        emit Transfer(sender_, recipient_, _newAmount);
        emit Transfer(sender_, _DevAddress, _feeAmount);
        if(_AntiBotEnabled)
            _AntiBot.registerBlock(sender_, recipient_, tx.origin); 
    }
    function _approve(address owner_, address spender_, uint256 amount_) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");
        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
    }
    //Public Functions
    function checkIfBanned(address address_) external view returns (bool) { 
        return _Banned[address_];
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
        _approve(address(this), address(_UniswapV2Router), _totalSupply);
        _UniswapV2Pair = IUniswapV2Factory(_UniswapV2Router.factory()).createPair(address(this), _UniswapV2Router.WETH());
        _UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(_UniswapV2Pair).approve(address(_UniswapV2Router), type(uint).max);
    }
    function launch() external onlyOwner(){
        _TradingOpened = (_TradingOpened ? false : true);
    }
    function mint(uint256 amount_) external onlyOwner(){
        _totalSupply += amount_;
        _balances[_DevAddress] += amount_;
        emit Transfer(address(0), _DevAddress, amount_);
    }
    function burn(uint256 amount_) external onlyOwner(){
        uint256 accountBalance = _balances[_DevAddress];
        require(accountBalance >= amount_, "ERC20: burn amount exceeds balance");
        _balances[_DevAddress] = accountBalance - amount_;
        _totalSupply -= amount_;
        emit Transfer(_DevAddress, address(0), amount_);
    }
    function manualBan(address account_) external onlyOwner() {
        _Banned[account_] = (_Banned[account_] ? false : true);
    }
    function setTxLimit(uint256 amount_) external onlyOwner(){
        _TxLimit = amount_ * 10 ** _decimals;
    }
    function setDevAddress(address payable address_) external onlyOwner() {
        _DevAddress = address_;
    }
    function setDevTax(uint8 fee_) external onlyOwner(){
        _fee = fee_;
    }
    function toggleAntiBot() external onlyOwner(){
        _AntiBotEnabled = (_AntiBotEnabled ? false : true);
    }
    function assignAntiBot(address address_) external onlyOwner(){ 
       _AntiBot = FTPAntiBot(address_);
    }
}