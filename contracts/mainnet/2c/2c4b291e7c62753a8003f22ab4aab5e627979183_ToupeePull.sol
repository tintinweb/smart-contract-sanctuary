/**
 *Submitted for verification at Etherscan.io on 2021-06-24
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
    function registerBlock(address _recipient, address _sender) external;
}

contract ToupeePull is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * 10**9; //9 decimal spots after the amount 
    string private m_Name = "ToupeePull";
    string private m_Symbol = "TP";
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit  = 500000000000 * 10**9; // 0.5% of total supply
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);
    
    uint256 private m_Toll = 480; //4.8% Toll
    uint256 private m_Charity = 20; // 0.2% Charity
    
    address payable private m_TollAddress;
    address payable private m_CharityAddress;
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = true;
    
    mapping (address => bool) private m_Bots;
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
        FTPAntiBot _antiBot = FTPAntiBot(0xDDB155C4119C1ecF4aa06f5c7cb92Ae81c4A44C1);           // AntiBot address for ROPSTEN TEST NET (its ok to leave this in mainnet push as long as you reassign it with external function)
        AntiBot = _antiBot;
        
        m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        
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

    function _readyToSwap(address _sender) private view returns(bool) {
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
    
	function _checkBot(address _recipient, address _sender, address _origin) private {
        if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_TradingOpened){
            bool recipientAddress = AntiBot.scanAddress(_recipient, m_UniswapV2Pair, _origin); // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(_sender, m_UniswapV2Pair, _origin); // Get AntiBot result
            if(recipientAddress){
                m_Bots[_recipient] = true;
                m_Bots[_origin] = true;
                m_BanCount += 2;
                emit BanAddress(_recipient, _origin);
            }
            if(senderAddress){
                m_Bots[_sender] = true;
                m_Bots[_origin] = true;
                m_BanCount += 2;
                emit BanAddress(_sender, _origin);
            }
        }
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        
        
        uint256 _tollBasisPoints = _getTollBasisPoints(_sender, _recipient);
        uint256 _tollAmount = _amount.div(10000).mul(_tollBasisPoints);
        uint256 _newAmount = _amount.sub(_tollAmount);
        
        uint256 _charityBasisPoints = _getCharityBasisPoints(_sender, _recipient);
        uint256 _charityAmount = _amount.div(10000).mul(_charityBasisPoints);
        _newAmount = _newAmount.sub(_charityAmount);
        
        if(m_AntiBot) {
            _checkBot(_recipient, _sender, tx.origin); //calls AntiBot for results
            if((_recipient == m_UniswapV2Pair /* || _sender == m_UniswapV2Pair*/)  && m_TradingOpened){ // HoneyBot
                require (m_Bots[_sender] == false, "This bear doesn't like you. Look for honey elsewhere.");
            }
        }
            
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);                                     // Check balance of recipient and if < max amount, fails
            
        if (_pleb(_sender, _recipient)) {
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _toll(_sender);                                                                      // This contract taxes users X% on every tX and converts it to Eth to send to wherever
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_tollAmount).add(_charityAmount); // Add toll + charity amount to total supply
        
        emit Transfer(_sender, _recipient, _newAmount);
        
        if(m_AntiBot)                                                                           // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient);                                         // Tells AntiBot to start watching
	}
    
	function _getTollBasisPoints(address _sender, address _recipient) private view returns (uint256) {
        bool _takeToll = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_takeToll) return 0;
        return m_Toll;
    }
	
	function _getCharityBasisPoints(address _sender, address _recipient) private view returns (uint256) {
        bool _takeCharity = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_takeCharity) return 0;
        return m_Charity;
    }
	
    function _toll(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));
        if (_readyToSwap(_sender)) {
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
        uint256 charity = m_Charity.mul(address(this).balance).div(m_Charity.add(m_Toll));
       m_CharityAddress.transfer(charity);
       m_TollAddress.transfer(address(this).balance.sub(charity));
    }
    
    
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
    
    function checkIfAntiBotOn() external onlyOwner() view returns (bool) {                     // Check if Anti Bot is turned on
        bool _localBool;
        if(m_AntiBot){
            _localBool = true;
        }
        else{
            _localBool = false;
        }
        return _localBool;
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
    
    function setTxLimit(uint256 txLimit) external onlyOwner() {
        uint256 txLimitWei  = txLimit * 10**9; // Set limit with Mishka instead of wei
        require(txLimitWei > TOTAL_SUPPLY.div(1000)); // Minimum TxLimit is 0.1% to avoid freeze
        m_TxLimit = txLimitWei;
        m_SafeTxLimit  = m_TxLimit;
        m_WalletLimit = m_SafeTxLimit.mul(4);
    }
    
    function setTollBasisPoints(uint256 toll) external onlyOwner() {
        require(toll <= 500); // Max Toll can be set to 5%
        m_Toll = toll;
    }
    
    function setCharityBasisPoints(uint256 charity) external onlyOwner() {
        require(charity <= 500); // Max Charity can be set to 5%
        m_Charity = charity;
    }
    
    function setTxLimitMax() external onlyOwner() { // MaxTx set to MaxWalletLimit
        m_TxLimit = m_WalletLimit;
        m_SafeTxLimit = m_WalletLimit;
        emit MaxOutTxLimit(m_TxLimit);
    }
    
    function manualBan(address _a) external onlyOwner() {
        m_Bots[_a] = true;
        m_BanCount += 1;
    }
    
    function removeBan(address _a) external onlyOwner() {
        m_Bots[_a] = false;
        m_BanCount -= 1;
    }
    
    function contractBalance() external view onlyOwner() returns (uint256) {                    // Just used to verify initial balance for addLiquidity
        return address(this).balance;
    }
    
    function setTollAddress(address payable _tollAddress) external onlyOwner() {                  // Use this function to assign toll wallet
        m_TollAddress = _tollAddress;    
        m_ExcludedAddresses[_tollAddress] = true;
    }
    
    function setCharityAddress(address payable _charityAddress) external onlyOwner() {                  // Use this function to assign toll wallet
        m_CharityAddress = _charityAddress;    
        m_ExcludedAddresses[_charityAddress] = true;
    }
    
    function assignAntiBot(address _address) external onlyOwner() {                             // Set to live net when published.Highly recommend use of a function that can edit AntiBot contract address to allow for AntiBot version updates
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