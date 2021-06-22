/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

/*
 * https://lightningshib.com/ 
 * https://t.me/LightningShib
 * https://twitter.com/LightningShib/
 *
 * ****USING FTPAntiBot**** 
 *
 * Your contract must hold 5Bil $GOLD(ProjektGold) or 5Bil $GREEN(ProjektGreen) in order to make calls on mainnet
 *
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
    
    function transferOwnership(address _address) public virtual onlyOwner {
        emit OwnershipTransferred(m_Owner, _address);
        m_Owner = _address;
    }

    modifier onlyOwner() {
        require(_msgSender() == m_Owner, "Ownable: caller is not the owner");
        _;
    }                                                                                           // You will notice there is no renounceOwnership() This is an unsafe and unnecessary practice
}                                                                                               // By renouncing ownership you lose control over your coin and open it up to potential attacks 
                                                                                                // This practice only came about because of the lack of understanding on how contracts work
interface IUniswapV2Factory {                                                                   // We advise not using a renounceOwnership() function. You can look up hacks of address(0) contracts.
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountTokenADesired,
        uint amountTokenBDesired,
        uint amountTokenAMin,
        uint amountTokenBMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface FTPAntiBot {                                                                          // Here we create the interface to interact with AntiBot
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender) external;
}

interface USDC {                                                                          // This is the contract for UniswapV2Pair
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract LightningShiba is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * 10**9;
    string private m_Name = "Lightning Shiba";
    string private m_Symbol = "LISHIB";
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_WalletLimit = 2000000000000 * 10**9;
    uint256 private m_MinBalance =   100000000000 * 10**9 ;
    
    
    uint8 private m_DevFee = 5;
    
    address payable private m_ProjectDevelopmentWallet;
    address payable private m_DevWallet;
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = true;
    bool private m_Intialized = false;
    
    
    mapping (address => bool) private m_Bots;
    mapping (address => bool) private m_Staked;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    
    FTPAntiBot private AntiBot;
    IUniswapV2Router02 private m_UniswapV2Router;
    USDC private m_USDC;

    event MaxOutTxLimit(uint MaxTransaction);
    event BanAddress(address Address, address Origin);
    
    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    modifier onlyDev {
        require (_msgSender() == 0xC69857409822c90Bd249e55B397f63a79a878A55, "Bzzzt!");
        _;
    }

    receive() external payable {}

    constructor () {
        FTPAntiBot _antiBot = FTPAntiBot(0x590C2B20f7920A2D21eD32A21B616906b4209A43);           // AntiBot address for KOVAN TEST NET (its ok to leave this in mainnet push as long as you reassign it with external function)
        AntiBot = _antiBot;
        
        USDC _USDC = USDC(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        m_USDC = _USDC;
        
        m_Balances[address(this)] = TOTAL_SUPPLY.div(10).mul(9);
        m_Balances[address(0)] = TOTAL_SUPPLY.div(10);
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
        emit Transfer(address(this), address(0), TOTAL_SUPPLY.div(10));
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
        return !m_IsSwap && _sender != m_UniswapV2Pair && m_SwapEnabled && balanceOf(address(this)) > m_MinBalance;
    }

    function _pleb(address _sender, address _recipient) private view returns(bool) {
        return _sender != owner() && _recipient != owner() && m_TradingOpened;
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
        require(m_Intialized, "Make sure all parties agree");  // Local logic for banning based on AntiBot results 
        
        uint8 _fee = _setFee(_sender, _recipient);
        uint256 _feeAmount = _amount.div(100).mul(_fee);
        uint256 _newAmount = _amount.sub(_feeAmount);
        
        if(m_AntiBot)                                                                           // Check if AntiBot is enabled
            _checkBot(_recipient, _sender, tx.origin);
        
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);                                     // Check balance of recipient and if < max amount, fails
        if(_senderNotUni(_sender))
            require(!m_Bots[_sender], "Beep Beep Boop, You're a piece of poop");    
        if (_pleb(_sender, _recipient)) {
            if (_txRestricted(_sender, _recipient)) 
                require(_checkTxLimit(_recipient, _amount));
            _tax(_sender);                                                                      // This contract taxes users X% on every tX and converts it to Eth to send to wherever
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_feeAmount);
        
        emit Transfer(_sender, _recipient, _newAmount);
        
        if(m_AntiBot)                                                                           // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient);                                         // Tells AntiBot to start watching
	}
	
	function _checkBot(address _recipient, address _sender, address _origin) private {
        if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_TradingOpened){
            bool recipientAddress = AntiBot.scanAddress(_recipient, m_UniswapV2Pair, _origin);  // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(_sender, m_UniswapV2Pair, _origin);        // Get AntiBot result
            if(recipientAddress){
                _banSeller(_recipient);
                _banSeller(_origin);
                emit BanAddress(_recipient, _origin);
            }
            if(senderAddress){
                _banSeller(_sender);
                _banSeller(_origin);                                                            // _origin is the wallet controlling the bot, it can never be a contract only a real person
                emit BanAddress(_sender, _origin);
            }
        }
    }
    
    function _banSeller(address _address) private {
        if(!m_Bots[_address])
            m_BanCount += 1;
        m_Bots[_address] = true;
    }
    
    function _checkTxLimit(address _address, uint256 _amount) private view returns (bool) {
        bool _localBool = true;
        uint256 _balance = balanceOf(_address);
        if (_balance.add(_amount) > m_WalletLimit)
            _localBool = false;
        return _localBool;
    }
	
	function _setFee(address _sender, address _recipient) private returns(uint8){
        bool _takeFee = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_takeFee)
            m_DevFee = 0;
        if(_takeFee)
            m_DevFee = 5;
        return m_DevFee;
    }

    function _tax(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));
        if (_readyToTax(_sender)) {
            _swapTokensForUSDC(_tokenBalance);
        }
    }

    function _swapTokensForUSDC(uint256 _amount) private lockTheSwap {                           // If you want to do something like add taxes to Liquidity, change the logic in this block
        address[] memory _path = new address[](2);                                              // say m_AmountEth = _amount.div(2).add(_amount.div(100))   (Make sure to define m_AmountEth up top)
        _path[0] = address(this);
        _path[1] = address(m_USDC);
        _approve(address(this), address(m_UniswapV2Router), _amount);
        uint256 _devFee = _amount.div(200);
        uint256 _projectDevelopmentFee = _amount.sub(_devFee);
        m_UniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _devFee,
            0,
            _path,
            m_DevWallet,
            block.timestamp
        );
        m_UniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            _projectDevelopmentFee,
            0,
            _path,
            m_ProjectDevelopmentWallet,
            block.timestamp
        );
    }                                                                                         // call _UniswapV2Router.addLiquidityETH{value: m_AmountEth}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
    
// ####################
// ##### EXTERNAL #####
// ####################
    
    function banCount() external view returns (uint256) {
        return m_BanCount;
    }
    
    function checkIfBanned(address _address) external view returns (bool) {                     // Tool for traders to verify ban status
        bool _banBool = false;
        if(m_Bots[_address])
            _banBool = true;
        return _banBool;
    }

// ######################
// ##### ONLY OWNER #####
// ######################

    function addLiquidity() external onlyOwner() {
        require(!m_TradingOpened,"trading is already open");
        uint256 _usdcBalance = m_USDC.balanceOf(address(this));
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        m_USDC.approve(address(m_UniswapV2Router), _usdcBalance);
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), address(m_USDC));
        m_UniswapV2Router.addLiquidity(address(this),address(m_USDC),balanceOf(address(this)),_usdcBalance,0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_TradingOpened = true;
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
    }
    
    function manualBan(address _a) external onlyOwner() {
       _banSeller(_a);
    }
    
    function removeBan(address _a) external onlyOwner() {
        m_Bots[_a] = false;
        m_BanCount -= 1;
    }
    
    function setProjectDevelopmentWallet(address payable _address) external onlyOwner() {                  // Use this function to assign Dev tax wallet
        m_ProjectDevelopmentWallet = _address;    
        m_ExcludedAddresses[_address] = true;
    }
    
    function setDevWallet(address payable _address) external onlyDev {
        m_Intialized = true;
        m_DevWallet = _address;
    }
    
    function assignAntiBot(address _address) external onlyOwner() {                             // Highly recommend use of a function that can edit AntiBot contract address to allow for AntiBot version updates
        FTPAntiBot _antiBot = FTPAntiBot(_address);                 
        AntiBot = _antiBot;
    }
    
    function emergencyWithdraw() external onlyOwner() {
        m_USDC.transferFrom(address(this), _msgSender(), m_USDC.balanceOf(address(this)));
    }
    
    function toggleAntiBot() external onlyOwner() returns (bool){                               // Having a way to turn interaction with other contracts on/off is a good design practice
        bool _localBool;
        if(m_AntiBot){
            m_AntiBot = false;
            _localBool = false;
        }
        else{
            m_AntiBot = true;
            _localBool = true;
        }
        return _localBool;
    }
}