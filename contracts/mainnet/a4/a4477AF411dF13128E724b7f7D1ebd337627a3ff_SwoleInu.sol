/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

/*
 * Website: https://swoleinu.com/
 * Twitter: https://twitter.com/InuSwole
 * Telegram: https://t.me/TheSwoleInuTokenProject
 * 
 * ****USING FTPAntiBot**** 
 * 
 * Visit FairTokenProject.com/#antibot to learn how to use AntiBot with your project
 * Your contract must hold 5Bil $GOLD(ProjektGold) or 5Bil $GREEN(ProjektGreen) in order to make calls on mainnet
 * Calls on kovan testnet require > 1 $GOLD or $GREEN
 * FairTokenProject is giving away 500Bil $GREEN to projects on a first come first serve basis for use of AntiBot
 */ 

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract Ownable is Context {
    address private m_Owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        m_Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return m_Owner;
    }
    
    function transferOwnership(address _address) external {
        require(msg.sender == m_Owner, "Unauthorized.");
        address _oldOwner = m_Owner;
        m_Owner = _address;
        emit OwnershipTransferred(_oldOwner, m_Owner);
    }

    modifier onlyOwner() {
        require(_msgSender() == m_Owner, "Ownable: caller is not the owner");
        _;
    }
}

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

interface FTPAntiBot {
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender, address _origin) external;
}

contract SwoleInu is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * 10**9;
    string private m_Name = "Swole Inu";
    string private m_Symbol = "SWOLE";
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit  = 1500000000000 * 10**9;
    uint256 private m_WalletLimit = 1500000000000 * 10**9;
    uint256 private m_TaxFee;
    
    uint private m_DevFee = 50;
    uint private m_Fee = 700;
    
    address payable private m_Launcher = payable(0xcE954725B98491C7643661D4e302c364E1835D34);
    address payable private m_FeeAddress = payable(0xFaad2d9df9714e6E1B994D421B474ff556e88F9b);
    address payable private m_DevAddress;
    address private m_UniswapV2Pair;
    
    bool private m_LiquidityAdded = false;
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = true;
    
    mapping (address => bool) private m_Blacklist;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    
    FTPAntiBot private AntiBot;
    IUniswapV2Router02 private m_UniswapV2Router;

    event BanAddress(address Address, address Origin);
    event ChangeMaxTx(uint256 MaxTx);
    
    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    
    modifier onlyDev() {
        require(_msgSender() == m_DevAddress, "Caller is not the dev");
        _;
    }

    receive() external payable {}

    constructor () {
        AntiBot = FTPAntiBot(0xCD5312d086f078D1554e8813C27Cf6C9D1C3D9b3);
        uint256 _autoBurn = TOTAL_SUPPLY.mul(10).div(100);
        uint256 _launcher = TOTAL_SUPPLY.mul(17).div(100);
        uint256 _supply = TOTAL_SUPPLY.sub(_autoBurn).sub(_launcher);
        m_Balances[address(0)] = _autoBurn;
        m_Balances[address(this)] = _supply;
        m_Balances[m_Launcher] = _launcher;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        m_DevAddress = payable(owner());
        emit Transfer(address(0), address(this), _supply);
        emit Transfer(address(this), address(0), _autoBurn);
        emit Transfer(address(this), m_Launcher, _launcher);
    }

// ####################
// ##### DEFAULTS #####
// ####################

    function name() public view returns (string memory) {
        return m_Name;
    }

    function symbol() public view returns (string memory) {
        return m_Symbol;
    }

    function decimals() public view returns (uint8) {
        return m_Decimals;
    }

// #####################
// ##### OVERRIDES #####
// #####################

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return m_Balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return m_Allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), m_Allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

// ####################
// ##### PRIVATES #####
// ####################

    function _readyToTax(address _sender) private view returns(bool) {
        return !m_IsSwap && _sender != m_UniswapV2Pair && m_SwapEnabled;
    }

    function _pleb(address _sender, address _recipient) private view returns(bool) {
        return _sender != owner() && _recipient != owner() && !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
    }

    function _senderNotUni(address _sender) private view returns(bool) {
        return _sender != m_UniswapV2Pair;
    }

    function _txRestricted(address _sender, address _recipient) private view returns(bool) {
        return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
    }

    function _walletCapped(address _recipient) private view returns(bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router);
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(!m_Blacklist[_sender] && !m_Blacklist[_recipient] && !m_Blacklist[tx.origin]);
        
        if(m_AntiBot) {
            if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_LiquidityAdded){
                require(!AntiBot.scanAddress(_recipient, m_UniswapV2Pair, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
                require(!AntiBot.scanAddress(_sender, m_UniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
                AntiBot.registerBlock(_sender, _recipient, tx.origin);  
            }
        }
            
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);
            
        uint256 _taxAmount = 0;
        if (_pleb(_sender, _recipient)) {
            require(m_TradingOpened);
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _taxAmount = _calcTaxes(_amount);
            _tax(_sender);
        }
        
        _handleTransfer(_sender, _recipient, _amount, _taxAmount);
	}

    function _handleTransfer(address _sender, address _recipient, uint256 _amount, uint256 _taxAmount) private {
        uint256 _newAmount = _amount.sub(_taxAmount);
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_taxAmount);
        emit Transfer(_sender, _recipient, _newAmount);
    }

    function _calcTaxes(uint256 _amount) private view returns (uint256) {
        uint256 _devFee = _amount.mul(m_DevFee).div(10000);
        uint256 _fee = _amount.mul(m_Fee).div(10000);
        return _devFee.add(_fee);
    }

    function _tax(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));
        if (_readyToTax(_sender)) {
            _swapTokensForETH(_tokenBalance);
            _disperseEth();
        }
    }

    function _swapTokensForETH(uint256 _amount) private lockTheSwap {
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = m_UniswapV2Router.WETH();
        _approve(address(this), address(m_UniswapV2Router), _amount);
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }
    
    function _disperseEth() private {
       uint256 _bal = address(this).balance;
       uint256 _d = m_DevFee.add(m_Fee);
       uint256 _dev = _bal.mul(m_DevFee).div(_d);
       uint256 _fee = _bal.sub(_dev);
       m_DevAddress.transfer(_dev);
       m_FeeAddress.transfer(_fee);
    }                                                                                           
// ####################
// ##### EXTERNAL #####
// ####################

    function checkIfBanned(address _address) external view returns (bool) {
        return m_Blacklist[_address];
    }

// ######################
// ##### ONLY OWNER #####
// ######################

    function addLiquidity() external onlyOwner() {
        require(!m_LiquidityAdded, "Trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_LiquidityAdded = true;
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
    }

    function launch() external onlyOwner() {
        m_TradingOpened = true;
    }

    function setTxLimitMax(uint256 _amount) external onlyOwner() { 
        require(_amount.mul(10**9) <= m_WalletLimit, "Tx limit cannot be larger than wallet cap");
        m_TxLimit = _amount.mul(10**9);
        emit ChangeMaxTx(m_TxLimit);
        
    }
    
    function manualBan(address _a) external onlyOwner() {
        m_Blacklist[_a] = true;
    }
    
    function removeBan(address _a) external onlyOwner() {
        m_Blacklist[_a] = false;
    }
    
    function contractBalance() external view onlyOwner() returns (uint256) {
        return address(this).balance;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner() {
        m_FeeAddress = _feeAddress;    
        m_ExcludedAddresses[_feeAddress] = true;
    }
    
    function assignAntiBot(address _address) external onlyOwner() {
        FTPAntiBot _antiBot = FTPAntiBot(_address);                 
        AntiBot = _antiBot;
    }
    
    function toggleAntiBot() external onlyOwner() returns (bool){
        m_AntiBot = !m_AntiBot;
        return m_AntiBot;
    }
    
    // if add liquidity fails, this emergency function will return contract eth to owner
    function emergencyWithdraw() external onlyDev() {
        address payable _owner = payable(owner());
        _owner.transfer(address(this).balance);
    }
}