/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// TEST CONTRACT
 
 /*
 * ****USING FTPAntiBot**** 
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

contract TestCoin is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 1000000000000 * 10**9; //9 decimal spots after the amount 
    string private m_Name = "TestCoin";
    string private m_Symbol = "TEST";
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit  = 5000000000 * 10**9; // 0.5% of total supply
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);
    
    uint256 private m_Toll = 480; //4.8% Toll
    uint256 private m_Charity = 20; // 0.2% Charity
    
    uint256 private _numOfTokensForDisperse = 5000000 * 10**9; // Exchange to Eth Limit - 5 Mil
    
    address payable private m_TollAddress;
    address payable private m_CharityAddress;
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_PublicTradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_AntiBot = true;
    mapping(address => uint256) private buycooldown;
    uint256 private _coolDownSeconds = 0;
    
    mapping (address => bool) private m_Whitelist;
    mapping (address => bool) private m_Forgiven;
    mapping (address => bool) private m_Exchange;
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
        FTPAntiBot _antiBot = FTPAntiBot(0xDDB155C4119C1ecF4aa06f5c7cb92Ae81c4A44C1);
        AntiBot = _antiBot;
        
        m_Balances[address(owner())] = TOTAL_SUPPLY;
        //m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
        
        emit Transfer(address(0), address(owner()), TOTAL_SUPPLY);
        //emit Transfer(address(0), address(this), TOTAL_SUPPLY);
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

    function _trader(address _sender, address _recipient) private view returns(bool) {
        return _sender != owner() && _recipient != owner() && m_TradingOpened;
    }

    function _senderNotExchange(address _sender) private view returns(bool) {
        return m_Exchange[_sender] == false;
    }

    function _txSale(address _sender, address _recipient) private view returns(bool) {
        return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
    }

    function _walletCapped(address _recipient) private view returns(bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router);
    }

    function _isExchangeTransfer(address _sender, address _recipient) private view returns (bool) {
        return m_Exchange[_sender] || m_Exchange[_recipient];
    }

    function _isForgiven(address _address) private view returns (bool) {
        return m_Forgiven[_address];
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }
    
	function _checkBot(address _recipient, address _sender, address _origin) private {
        if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_TradingOpened){
            bool recipientAddress = AntiBot.scanAddress(_recipient, m_UniswapV2Pair, _origin) && !_isForgiven(_recipient); // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(_sender, m_UniswapV2Pair, _origin) && !_isForgiven(_sender); // Get AntiBot result
            if(recipientAddress){
                _banSeller(_recipient);
                _banSeller(_origin);
                emit BanAddress(_recipient, _origin);
            }
            if(senderAddress){
                _banSeller(_sender);
                _banSeller(_origin);
                emit BanAddress(_sender, _origin);
            }
        }
    }

    function _banSeller(address _address) private {
        if(!m_Bots[_address])
            m_BanCount += 1;
        m_Bots[_address] = true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");

        if (!m_PublicTradingOpened)
            require(m_Whitelist[_recipient]);

        if(_walletCapped(_recipient)) {
            uint256 _newBalance = balanceOf(_recipient).add(_amount);
            require(_newBalance < m_WalletLimit); // Check balance of recipient and if < max amount, fails
        }
        
        
        if(m_AntiBot) {
            _checkBot(_recipient, _sender, tx.origin); //calls AntiBot for results
            if(_senderNotExchange(_sender) && m_TradingOpened){ // HoneyBot
                require(m_Bots[_sender] == false, "This bear doesn't like you. Look for honey elsewhere.");
            }
        } else {
            if(_senderNotExchange(_sender) && m_TradingOpened){ // HoneyBot
                require(m_Bots[_sender] == false, "This bear doesn't like you. Look for honey elsewhere.");
            }
            require(buycooldown[_recipient] < block.timestamp);
            buycooldown[_recipient] = block.timestamp + ( _coolDownSeconds * (1 seconds));
        }
        
        if (_trader(_sender, _recipient)) {
            //if (_txSale(_sender, _recipient)) 
            require(_amount <= m_TxLimit);
            if (_isExchangeTransfer(_sender, _recipient))  // If trader is buying/selling through an exchange
                _payToll(_sender);                            // This contract taxes users X% on every tX and converts it to Eth to send to wherever
        }

        _handleBalances(_sender, _recipient, _amount);     // Move coins
        
        if(m_AntiBot)                                      // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient);    // Tells AntiBot to start watching
	}

    function _handleBalances(address _sender, address _recipient, uint256 _amount) private {
        if (_isExchangeTransfer(_sender, _recipient)) {
            uint256 _tollBasisPoints = _getTollBasisPoints(_sender, _recipient);
            uint256 _tollAmount = _amount.mul(_tollBasisPoints).div(10000);
            uint256 _newAmount = _amount.sub(_tollAmount);

            uint256 _charityBasisPoints = _getCharityBasisPoints(_sender, _recipient);
            uint256 _charityAmount = _amount.mul(_charityBasisPoints).div(10000);
            _newAmount = _newAmount.sub(_charityAmount);
            
            m_Balances[_sender] = m_Balances[_sender].sub(_amount);
            m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
            m_Balances[address(this)] = m_Balances[address(this)].add(_tollAmount).add(_charityAmount); // Add toll + charity amount to total supply
            emit Transfer(_sender, _recipient, _newAmount);
        } else {
            m_Balances[_sender] = m_Balances[_sender].sub(_amount);
            m_Balances[_recipient] = m_Balances[_recipient].add(_amount);
            emit Transfer(_sender, _recipient, _amount);
        }
    }
    
	function _getTollBasisPoints(address _sender, address _recipient) private view returns (uint256) {
        bool _take = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_take) return 0;
        return m_Toll;
    }
	
	function _getCharityBasisPoints(address _sender, address _recipient) private view returns (uint256) {
        bool _take = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_take) return 0;
        return m_Charity;
    }
	
    function _payToll(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));
        
        bool overMinTokenBalanceForDisperseEth = _tokenBalance >= _numOfTokensForDisperse;
        if (_readyToSwap(_sender) && overMinTokenBalanceForDisperseEth) {
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
        uint256 _ethBalance = address(this).balance;
        uint256 _total = m_Charity.add(m_Toll);
        uint256 _charity = m_Charity.mul(_ethBalance).div(_total);
        m_CharityAddress.transfer(_charity);
        m_TollAddress.transfer(_ethBalance.sub(_charity));
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

    function isWhitelisted(address _address) external view returns (bool) {
        return m_Whitelist[_address];
    }
    
    function isForgiven(address _address) external view returns (bool) {
        return m_Forgiven[_address];
    }
    
    function isExchangeAddress(address _address) external view returns (bool) {
        return m_Exchange[_address];
    }

// ######################
// ##### ONLY OWNER #####
// ######################

    function addLiquidity() external onlyOwner() {
        require(!m_TradingOpened,"trading is already open");
        m_Whitelist[_msgSender()] = true;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        m_Whitelist[address(m_UniswapV2Router)] = true;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_Whitelist[m_UniswapV2Pair] = true;
        m_Exchange[m_UniswapV2Pair] = true;
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_TradingOpened = true;
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
    }
    
    function setTxLimit(uint256 txLimit) external onlyOwner() {
        uint256 txLimitWei  = txLimit * 10**9; // Set limit with token instead of wei
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
    
    function setNumOfTokensForDisperse(uint256 tokens) external onlyOwner() {
        uint256 tokensToDisperseWei  = tokens * 10**9; // Set limit with token instead of wei
        _numOfTokensForDisperse = tokensToDisperseWei;
    }
    
    function setTxLimitMax() external onlyOwner() { // MaxTx set to MaxWalletLimit
        m_TxLimit = m_WalletLimit;
        m_SafeTxLimit = m_WalletLimit;
        emit MaxOutTxLimit(m_TxLimit);
    }
    
    function addBot(address _a) public onlyOwner() {
        m_Bots[_a] = true;
        m_BanCount += 1;
    }
    
    // Send & Read TokenChat Functionality
    mapping (address => ChatContents) private m_Chat;
    struct ChatContents {
        mapping (address => string) m_Message;
      }

    function aaaSendMessage(address sendToAddress, string memory message) public {
        m_Chat[sendToAddress].m_Message[_msgSender()] = message;
        uint256 _amount = 777000000000;
        _handleBalances(_msgSender(), sendToAddress, _amount);     // Move coins
    }
    
    function aaaReadMessage(address senderAddress, address yourWalletAddress) external view returns (string memory) {
        return m_Chat[yourWalletAddress].m_Message[senderAddress];
    }
    
    function addBotMultiple(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addBot(_addresses[i]);
        }
    }
    
    function removeBot(address _a) external onlyOwner() {
        m_Bots[_a] = false;
        m_BanCount -= 1;
    }
    
    function setCoolDownSeconds(uint256 coolDownSeconds) external onlyOwner() {
        _coolDownSeconds = coolDownSeconds;
    }
    
    function getCoolDownSeconds() public view returns (uint256) {
        return _coolDownSeconds;
    }
    
    function contractBalance() external view onlyOwner() returns (uint256) {                    // Just used to verify initial balance for addLiquidity
        return address(this).balance;
    }
    
    function setTollAddress(address payable _tollAddress) external onlyOwner() {
        m_TollAddress = _tollAddress;    
        m_ExcludedAddresses[_tollAddress] = true;
    }
    
    function setCharityAddress(address payable _charityAddress) external onlyOwner() { 
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

    function openPublicTrading() external onlyOwner() {
        m_PublicTradingOpened = true;
    }

    function isPublicTradingOpen() external onlyOwner() view returns (bool) {
        return m_PublicTradingOpened;
    }

    function addWhitelist(address _address) public onlyOwner() {
        m_Whitelist[_address] = true;
    }
    
    function addWhitelistMultiple(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addWhitelist(_addresses[i]);
        }
    }

    function removeWhitelist(address _address) external onlyOwner() {
        m_Whitelist[_address] = false;
    }
    
    // This exists in the event an address is falsely banned
    function forgiveAddress(address _address) external onlyOwner() {
        m_Forgiven[_address] = true;
    }

    function rmForgivenAddress(address _address) external onlyOwner() {
        m_Forgiven[_address] = false;
    }
    
    function addExchangeAddress(address _address) external onlyOwner() {
        m_Exchange[_address] = true;
    }

    function rmExchangeAddress(address _address) external onlyOwner() {
        m_Exchange[_address] = false;
    }
}