/**
 *Submitted for verification at Etherscan.io on 2021-07-09
*/

/*
 *  Grey Token's primary goal is to gather original Paranormal/UFO/Inter dimensional
 *  Video Evidence, and put it on the Blockchain. Grey Team aims to achieve this through Incentive based 
 *  community interactions. Including voting, deflationary events/Deflationary events, Grey burn vaults, 
 *  and a new way for communities to interact with, and generate value for NFT's, and the underlying asset(Grey).

 *  https://t.me/greytokendiscussion

 * ****USING FTPAntiBot**** 
 * Visit antibot.FairTokenProject.com to learn how to use AntiBot with your project
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
        m_Owner = _address;
        emit OwnershipTransferred(_msgSender(), _address);
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

interface FTPAntiBot {                                                                          // Here we create the interface to interact with AntiBot
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender, address _origin) external;
}

interface ExtWETH {
    function balanceOf(address _address) external view returns (uint256);
}

contract GreyToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 10000000000000 * 10**9;
    string private m_Name = "Grey Token";
    string private m_Symbol = "GREY";
    uint8 private m_Decimals = 9;
    
    uint256 private m_TxLimit  = 50000000000 * 10**9;
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit;
    
    uint8 private m_DevFee = 5;
    
    address payable private m_ProjectAddress;
    address payable private m_DevAddress;
    address payable private m_LiqWallet = payable(0x78033340d9adA6B2F2E17e966336a616E31B575B);
    address private m_DevelopmentWallet = 0x5f1e5399e205cCb7c35Df2bf5d1f412076Ed03D8;
    address private m_MarketingWallet = 0x10b041392Dde6907854528BCb2681E1ee409C162;
    address private m_TeamWallet = 0xEE65B59BdE2066E032041184F82110DF19B1bdfa;
    address private m_EventWallet = 0xc9a141d3fFd090154fa3dD8adcef9E963815ce64;
    address private m_PresaleAllocWallet = 0xCD4F207FB5d551Fc6f513281eF66a7893852151A;    
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = true;
    bool private m_Initialized = false;
    bool private m_AddLiq = true;
    bool private m_OpenTrading =  false;
    
    mapping (address => bool) private m_Banned;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    
    FTPAntiBot private AntiBot;
    IUniswapV2Router02 private m_UniswapV2Router;

    event MaxOutTxLimit(uint MaxTransaction);
    event BanAddress(address Address, address Origin);
    
    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    modifier onlyDev {
        require(_msgSender() == 0xC69857409822c90Bd249e55B397f63a79a878A55);
        _;
    }

    receive() external payable {}

    constructor () {
        uint256 _supplyAmount = (TOTAL_SUPPLY.div(10).add(TOTAL_SUPPLY.div(40))).mul(1000).div(1087);
        AntiBot = FTPAntiBot(0xCD5312d086f078D1554e8813C27Cf6C9D1C3D9b3); //AntiBotV2
        
        m_Balances[address(this)] = _supplyAmount;
        m_Balances[address(0)] = TOTAL_SUPPLY.div(10).add(TOTAL_SUPPLY.div(40)).sub(_supplyAmount);
        m_Balances[m_DevelopmentWallet] = TOTAL_SUPPLY.div(10000).mul(1500);
        m_Balances[m_MarketingWallet] = TOTAL_SUPPLY.div(40);
        m_Balances[m_TeamWallet] = TOTAL_SUPPLY.div(20);
        m_Balances[m_EventWallet] = TOTAL_SUPPLY.div(2);
        m_Balances[m_PresaleAllocWallet] = TOTAL_SUPPLY.div(10000).mul(1500);

        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        m_ExcludedAddresses[m_DevelopmentWallet] = true;
        m_ExcludedAddresses[m_MarketingWallet] = true;
        m_ExcludedAddresses[m_TeamWallet] = true;
        m_ExcludedAddresses[m_EventWallet] = true;
        m_ExcludedAddresses[m_PresaleAllocWallet] = true;
        
        emit Transfer(address(this), address(0), TOTAL_SUPPLY.div(10).add(TOTAL_SUPPLY.div(40)).sub(_supplyAmount));
        emit Transfer(address(0), address(this), TOTAL_SUPPLY.div(10).add(TOTAL_SUPPLY.div(40)));
        emit Transfer(address(0), m_DevelopmentWallet, TOTAL_SUPPLY.div(10000).mul(1500));
        emit Transfer(address(0), m_MarketingWallet, TOTAL_SUPPLY.div(40));
        emit Transfer(address(0), m_TeamWallet, TOTAL_SUPPLY.div(20));
        emit Transfer(address(0), m_EventWallet, TOTAL_SUPPLY.div(2));
        emit Transfer(address(0), m_PresaleAllocWallet, TOTAL_SUPPLY.div(10000).mul(1500));
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
        bool _localBool = true;
        if(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient])
            _localBool = false;
        return _localBool;
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
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(m_Initialized, "All parties must consent");
        require(!m_Banned[_sender] && !m_Banned[_recipient] && !m_Banned[tx.origin]);
        
        
        uint8 _fee = _setFee(_sender, _recipient);
        uint256 _feeAmount = _amount.div(100).mul(_fee);
        uint256 _newAmount = _amount.sub(_feeAmount);
        
        if(m_AntiBot) {
            if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_TradingOpened){
                require(!AntiBot.scanAddress(_recipient, m_UniswapV2Pair, tx.origin), "Beep beep boop! You're a piece of poop.");
                require(!AntiBot.scanAddress(_sender, m_UniswapV2Pair, tx.origin), "Beep beep boop! You're a piece of poop.");
            }
        }
            
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);                                     // Check balance of recipient and if < max amount, fails
            
        if (_pleb(_sender, _recipient)) {
            require(m_OpenTrading);
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _tax(_sender);                                                                      
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_feeAmount);
        
        emit Transfer(_sender, _recipient, _newAmount);
        
        if(m_AntiBot)                                                                           // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient, tx.origin);                                         // Tells AntiBot to start watching
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
            _swapTokensForETH(_tokenBalance);
            _disperseEth();
        }
    }

    function _swapTokensForETH(uint256 _amount) private lockTheSwap {           
        uint256 _liqAmount = _amount.div(4).mul(3); 
        uint256 _transferAmount = _amount;            
        
        if(m_AddLiq)
            _transferAmount = _liqAmount;
            m_Balances[m_LiqWallet] = m_Balances[m_LiqWallet].add(balanceOf(address(this)).sub(_liqAmount));
            emit Transfer(address(this), m_LiqWallet, _amount.div(4));
            
       
        address[] memory _path = new address[](2);                                              
        _path[0] = address(this);                                                              
        _path[1] = m_UniswapV2Router.WETH();                                                    
        _approve(address(this), address(m_UniswapV2Router), _transferAmount);                           
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _transferAmount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }
    
    function _disperseEth() private {
            
        uint256 _ethBalance = address(this).balance;
        uint256 _devAmount = _ethBalance.add(_ethBalance.div(3)).div(10);
        uint256 _projectAmount;
        
        if(m_AddLiq)
            _projectAmount = _ethBalance.add(_ethBalance.div(3)).div(2).sub(_devAmount).sub(_ethBalance.div(165));
        else
            _projectAmount = _ethBalance.sub(_devAmount);
            
        m_DevAddress.transfer(_devAmount);
        m_ProjectAddress.transfer(_projectAmount);
        
        if(m_AddLiq){
            m_LiqWallet.transfer(address(this).balance);
        }
    }      
    
// ####################
// ##### EXTERNAL #####
// ####################
    
    function checkIfBanned(address _address) external view returns (bool) { 
        bool _banBool = false;
        if(m_Banned[_address])
            _banBool = true;
        return _banBool;
    }

// ######################
// ##### ONLY OWNER #####
// ######################

    function addLiquidity() external onlyOwner() {
        require(!m_TradingOpened,"trading is already open");
        m_UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(m_UniswapV2Router.factory()).createPair(address(this), m_UniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_TradingOpened = true;
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
    }

    function launch() external onlyOwner() {
        m_OpenTrading = true;
    }
    
    function manualBan(address _a) external onlyOwner() {
        m_Banned[_a] = true;
    }
    
    function removeBan(address _a) external onlyOwner() {
        m_Banned[_a] = false;
    }
    
    function setTxLimitMax(uint256 _amount) external onlyOwner() { 
        m_TxLimit = _amount.mul(10**9);
        m_SafeTxLimit = _amount.mul(10**9);
        emit MaxOutTxLimit(m_TxLimit);
        
    }

    function addTaxWhiteList(address _address) external onlyOwner() {        
        m_ExcludedAddresses[_address] = true;        
    }
    
    function setProjectAddress(address payable _address) external onlyOwner() {
        m_ProjectAddress = _address;    
        m_ExcludedAddresses[_address] = true;
    }
    
    function setDevAddress(address payable _address) external onlyDev {
        m_DevAddress = _address;
        m_Initialized = true;
    }

    function toggleAddLiq() external onlyOwner() returns(bool) {
        if(m_AddLiq)
            m_AddLiq = false;
        else 
            m_AddLiq = true;
        return m_AddLiq;
    }
    
    function assignAntiBot(address _address) external onlyOwner() { 
        AntiBot = FTPAntiBot(_address);
    }
    
    function toggleAntiBot() external onlyOwner() returns (bool){
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