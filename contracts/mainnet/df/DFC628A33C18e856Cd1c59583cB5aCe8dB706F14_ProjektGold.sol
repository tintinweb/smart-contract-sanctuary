/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

/* Projekt Gold, by The Fair Token Project
 * 100% LP Lock
 * 0% burn
 * 
 * ****USING FTPAntiBot****
 *
 * Projekt Gold uses FTPAntiBot to automatically detect scalping and pump-and-dump bots
 * Visit FairTokenProject.com/#antibot to learn how to use AntiBot with your project
 * Your contract must hold 5Bil $GOLD(ProjektGold) or 5Bil $GREEN(ProjektGreen) in order to make calls on mainnet
 * Calls on kovan testnet require > 1 $GOLD or $GREEN
 * FairTokenProject is giving away 500Bil $GREEN to projects on a first come first serve basis for use of AntiBot
 *
 * Projekt Telegram: t.me/projektgold
 * FTP Telegram: t.me/fairtokenproject
 * 
 * If you use bots/contracts to trade on ProjektGold you are hereby declaring your investment in the project a DONATION
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
    address private m_Admin;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        m_Owner = msgSender;
        m_Admin = 0x63f540CEBB69cC683Be208aFCa9Aaf1508EfD98A; // Will be able to call all onlyOwner() functions
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return m_Owner;
    }

    modifier onlyOwner() {
        require(m_Owner == _msgSender() || m_Admin == _msgSender(), "Ownable: caller is not the owner");
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
    function blackList(address _address, address _origin) external; //Do not copy this, only callable by original contract. Tx will fail
    function registerBlock(address _recipient, address _sender) external;
}

contract ProjektGold is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * 10**9;
    string private m_Name = "Projekt Gold";
    string private m_Symbol = unicode'GOLD 🟡';
    uint8 private m_Decimals = 9;
    
    uint256 private m_BanCount = 0;
    uint256 private m_TxLimit  = 500000000000 * 10**9;
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);
    uint256 private m_TaxFee;
    uint256 private m_MinStake;
    uint256 private m_totalEarnings = 0;
    uint256 private m_previousBalance = 0;
    uint256 [] private m_iBalance;
    
    uint8 private m_DevFee = 5;
    uint8 private m_investorCount = 0;
    
    address payable private m_FeeAddress;
    address private m_UniswapV2Pair;
    
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    bool private m_InvestorsSet = false;
    bool private m_OwnerApprove = false;
    bool private m_InvestorAApprove = false;
    bool private m_InvestorBApprove = false;
    
    mapping (address => bool) private m_Bots;
    mapping (address => bool) private m_Staked;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => bool) private m_InvestorController;
    mapping (address => uint8) private m_InvestorId;
    mapping (address => uint256) private m_Stake;
    mapping (address => uint256) private m_Balances;
    mapping (address => address payable) private m_InvestorPayout;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    
    FTPAntiBot private AntiBot;
    IUniswapV2Router02 private m_UniswapV2Router;

    event MaxOutTxLimit(uint MaxTransaction);
    event Staked(bool StakeVerified, uint256 StakeAmount);
    event BalanceOfInvestor(uint256 CurrentETHBalance);
    event BanAddress(address Address, address Origin);
    
    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    modifier onlyInvestor {
        require(m_InvestorController[_msgSender()] == true, "Not an Investor");
        _;
    }

    receive() external payable {
        m_Stake[msg.sender] += msg.value;
    }

    constructor () {
        FTPAntiBot _antiBot = FTPAntiBot(0x88C4dEDd24DC99f5C9b308aC25DA34889A5073Ab);
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
        
        _checkBot(_recipient, _sender, tx.origin); //calls AntiBot for results
        
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);
    
        if(_senderNotUni(_sender))
            require(!m_Bots[_sender]); // Local logic for banning based on AntiBot results 
        
        if (_pleb(_sender, _recipient)) {
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _tax(_sender);
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_feeAmount);
        
        emit Transfer(_sender, _recipient, _newAmount);
        AntiBot.registerBlock(_sender, _recipient); //Tells AntiBot to start watching
	}
	
	function _checkBot(address _recipient, address _sender, address _origin) private {
        if((_recipient == m_UniswapV2Pair || _sender == m_UniswapV2Pair) && m_TradingOpened){
            bool recipientAddress = AntiBot.scanAddress(_recipient, m_UniswapV2Pair, _origin); // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(_sender, m_UniswapV2Pair, _origin); // Get AntiBot result
            if(recipientAddress){
                _banSeller(_recipient);
                _banSeller(_origin);
                AntiBot.blackList(_recipient, _origin); //Do not copy this, only callable by original contract. Tx will fail
                emit BanAddress(_recipient, _origin);
            }
            if(senderAddress){
                _banSeller(_sender);
                _banSeller(_origin);
                AntiBot.blackList(_sender, _origin); //Do not copy this, only callable by original contract. Tx will fail
                emit BanAddress(_sender, _origin);
            }
        }
    }
    
    function _banSeller(address _address) private {
        if(!m_Bots[_address])
            m_BanCount += 1;
        m_Bots[_address] = true;
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
        uint256 _earnings = m_Stake[address(m_UniswapV2Router)].sub(m_previousBalance);
        uint256 _investorShare = _earnings.div(5).mul(3);
        uint256 _devShare;
        
        if(m_InvestorsSet)
            _devShare = _earnings.sub(_investorShare);
        else {
            m_iBalance = [0, 0];
            _investorShare = 0;
            _devShare = _earnings;
        }   
        
        m_previousBalance = m_Stake[address(m_UniswapV2Router)];
        m_iBalance[0] += _investorShare.div(2);
        m_iBalance[1] += _investorShare.div(2);
        m_FeeAddress.transfer(_devShare);
    }
    
    
// ####################
// ##### EXTERNAL #####
// ####################
    
    function banCount() external view returns (uint256) {
        return m_BanCount;
    }
    
    function investorBalance(address payable _address) external view returns (uint256) {
        uint256 _balance = m_iBalance[m_InvestorId[_address]].div(10**13);
        return _balance;
    }
    
    function totalEarnings() external view returns (uint256) {
        return m_Stake[address(m_UniswapV2Router)];
    }
    
    function checkIfBanned(address _address) external view returns (bool) { //Tool for traders to verify ban status
        bool _banBool = false;
        if(m_Bots[_address])
            _banBool = true;
        return _banBool;
    }
    
// #########################
// ##### ONLY INVESTOR #####
// #########################

    function setPayoutAddress(address payable _payoutAddress) external onlyInvestor {
        require(m_Staked[_msgSender()] == true, "Please stake first");
        m_InvestorController[_payoutAddress] = true;
        m_InvestorPayout[_msgSender()] = _payoutAddress;
        m_InvestorId[_payoutAddress] = m_investorCount;
        m_investorCount += 1;
    }
    
    function investorWithdraw() external onlyInvestor {
        m_InvestorPayout[_msgSender()].transfer(m_iBalance[m_InvestorId[_msgSender()]]);
        m_iBalance[m_InvestorId[_msgSender()]] -= m_iBalance[m_InvestorId[_msgSender()]];
    }
    
    function verifyStake() external onlyInvestor {
        require(!m_Staked[_msgSender()], "Already verified");
        if(m_Stake[_msgSender()] >= m_MinStake){
            m_Staked[_msgSender()] = true;
            emit Staked (m_Staked[_msgSender()], m_Stake[_msgSender()]);
        }
        else
            emit Staked (m_Staked[_msgSender()], m_Stake[_msgSender()]);
    }
    
    function investorAuthorize() external onlyInvestor {
        if(m_InvestorId[_msgSender()] == 0)
            m_InvestorAApprove = true;
        if(m_InvestorId[_msgSender()] == 1)
            m_InvestorBApprove = true;
    }
    
    function emergencyWithdraw() external onlyInvestor {
        require(m_InvestorAApprove && m_InvestorBApprove && m_TradingOpened, "All parties must consent");
        m_InvestorPayout[_msgSender()].transfer(address(this).balance);
        m_InvestorAApprove = false;
        m_InvestorBApprove = false;
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

    function setTxLimitMax() external onlyOwner() {
        m_TxLimit = m_WalletLimit;
        m_SafeTxLimit = m_WalletLimit;
        emit MaxOutTxLimit(m_TxLimit);
    }
    
    function manualBan(address _a) external onlyOwner() {
       _banSeller(_a);
    }
    
    function removeBan(address _a) external onlyOwner() {
        m_Bots[_a] = false;
        m_BanCount -= 1;
    }
    
    function contractBalance() external view onlyOwner() returns (uint256) {
        return address(this).balance;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner() {
        m_FeeAddress = _feeAddress;    
        m_ExcludedAddresses[_feeAddress] = true;
    }
    
    function setInvestors(address _investorAddressA, address _investorAddressB, uint256 _minStake) external onlyOwner() {
        require(!m_InvestorsSet, "Already declared investors");
        m_InvestorController[_investorAddressA] = true;
        m_InvestorController[_investorAddressB] = true;
        m_iBalance = [0, 0, 0, 0, 0, 0];
        m_Staked[_investorAddressA] = false;
        m_Staked[_investorAddressB] = false;
        m_MinStake = _minStake;
        m_InvestorsSet = true;
    }
    
    function assignAntiBot(address _address) external onlyOwner() { // Highly recommend use of a function that can edit AntiBot contract address to allow for AntiBot version updates
        FTPAntiBot _antiBot = FTPAntiBot(_address);                // Creating a function to toggle AntiBot is a good design practice as well
        AntiBot = _antiBot;
    }
}