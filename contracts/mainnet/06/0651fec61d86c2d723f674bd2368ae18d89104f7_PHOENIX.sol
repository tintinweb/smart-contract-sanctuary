/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

/*
 * Insert info about your project here
 *
 * 
 * ****USING FTPAntiBot**** 
 *
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
    function registerBlock(address _recipient, address _sender) external;
}

contract PHOENIX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 500000000 * 10**9;
    uint256 private constant TEAM_SUPPLY = 10000000 * 10**9;
    string private m_Name = "PHOENIX";
    string private m_Symbol = "PHOENIX";
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit  = 300000000 * 10**9;
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);
    uint256 private m_TaxFee;
    
    uint8 private m_DevFee = 15;
    
    address payable private m_FeeAddress;
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = true;
    
    mapping (address => bool) private m_Bots;
    mapping (address => bool) private m_Staked;
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

    receive() external payable {}

    constructor () {
        FTPAntiBot _antiBot = FTPAntiBot(0x590C2B20f7920A2D21eD32A21B616906b4209A43);           // AntiBot address for KOVAN TEST NET (its ok to leave this in mainnet push as long as you reassign it with external function)
        AntiBot = _antiBot;
        
        m_Balances[address(this)] = TOTAL_SUPPLY - TEAM_SUPPLY;
        m_Balances[owner()] = TEAM_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        emit Transfer(address(0),owner(), TEAM_SUPPLY);
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
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
        
        
        uint8 _fee = _setFee(_sender, _recipient);
        uint256 _feeAmount = _amount.div(100).mul(_fee);
        uint256 _newAmount = _amount.sub(_feeAmount);
        
        if(m_AntiBot) {
            if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_TradingOpened){
                require(!AntiBot.scanAddress(_recipient, m_UniswapV2Pair, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
                require(!AntiBot.scanAddress(_sender, m_UniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
            }
        }
            
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);                                     // Check balance of recipient and if < max amount, fails
            
        if (_pleb(_sender, _recipient)) {
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _tax(_sender);                                                                      // This contract taxes users X% on every tX and converts it to Eth to send to wherever
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_feeAmount);
        
        emit Transfer(_sender, _recipient, _newAmount);
        
        if(m_AntiBot)                                                                           // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient);                                         // Tells AntiBot to start watching
	}
    
	function _setFee(address _sender, address _recipient) private returns(uint8){
        bool _takeFee = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_takeFee)
            m_DevFee = 0;
        if(_takeFee)
            m_DevFee = 15;
        return m_DevFee;
    }

    function _tax(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));
        if (_readyToTax(_sender)) {
            _swapTokensForETH(_tokenBalance);
            _disperseEth();
        }
    }

    function _swapTokensForETH(uint256 _amount) private lockTheSwap {                           // If you want to do something like add taxes to Liquidity, change the logic in this block
        address[] memory _path = new address[](2);                                              // say m_AmountEth = _amount.div(2).add(_amount.div(100))   (Make sure to define m_AmountEth up top)
        _path[0] = address(this);                                                               // ^This provides a buffer for the 0.6% tax that uniswap charges.
        _path[1] = m_UniswapV2Router.WETH();                                                    // This prevents the declination of value that is trending in current coins
        _approve(address(this), address(m_UniswapV2Router), _amount);                           // change _amount to m_AmountEth if you want to addLiquidity from tax
        m_UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            address(this),
            block.timestamp
        );
    }
    
    function _disperseEth() private {
       m_FeeAddress.transfer(address(this).balance);                                            // If you want to add taxes to Liquidity, instead of sending to m_FeeAddress
    }                                                                                           // call _UniswapV2Router.addLiquidityETH{value: m_AmountEth}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
    
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
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_TradingOpened = true;
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
    }

    function setTxLimitMax() external onlyOwner() {                                             // As it sits here, this function raises maxTX to maxWallet
        m_TxLimit = m_WalletLimit;
        m_SafeTxLimit = m_WalletLimit;
        emit MaxOutTxLimit(m_TxLimit);
    }
    
    function manualBan(address _a) external onlyOwner() {
        m_Bots[_a] = true;
    }
    
    function removeBan(address _a) external onlyOwner() {
        m_Bots[_a] = false;
        m_BanCount -= 1;
    }
    
    function contractBalance() external view onlyOwner() returns (uint256) {                    // Just used to verify initial balance for addLiquidity
        return address(this).balance;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner() {                  // Use this function to assign Dev tax wallet
        m_FeeAddress = _feeAddress;    
        m_ExcludedAddresses[_feeAddress] = true;
    }
    
    function assignAntiBot(address _address) external onlyOwner() {                             // Highly recommend use of a function that can edit AntiBot contract address to allow for AntiBot version updates
        FTPAntiBot _antiBot = FTPAntiBot(_address);                 
        AntiBot = _antiBot;
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