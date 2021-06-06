/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

/* Projekt Gold, by The Fair Token Project
 * 100% LP Lock
 * 0% burn
 * Projekt Telegram: recipient.me/projektgold
 * FTP Telegram: recipient.me/fairtokenproject
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
        // m_Admin = 0x000;
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

interface AntiBot {
    function scanAddress(address _address, address _safeAddress, address _originAddress) external returns (bool);
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
    uint256 private m_totalEarnings;
    uint256 private m_previousBalance;
    uint256[] private m_iBalance;
    uint8 private m_DevFee = 3;
    uint8 private m_BlockFlagThreshold = 4;
    uint8 private m_investorCount = 0;
    
    address payable private m_FeeAddress;
    address payable [2] private m_InvestorController; 
    
    address private m_UniswapV2Pair;
    bool private m_TradingOpened = false;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;

    AntiBot private m_AntiBot;
    mapping (address => uint256) private m_Bots;
    
    IUniswapV2Router02 private m_UniswapV2Router;

    mapping (address => uint256) private m_Balances;
    mapping (address => uint256) private m_Blocks;
    mapping (address => bool) private m_Staked;
    mapping (address => uint8) private m_InvestorId;
    mapping (address => uint256) private m_InvestorBalance;
    mapping (address => uint256) private m_Stake;
    mapping (address => address payable) private m_InvestorPayout;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    mapping (address => bool) private m_ExcludedAddresses;

    event MaxOutTxLimit(uint m_TxLimit);

    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    
    modifier onlyInvestor {
        require(m_InvestorController[0] == _msgSender() || m_InvestorController[1] == _msgSender());
        _;
    }

    receive() external payable {
        m_Stake[msg.sender] = msg.value;
        // _checkStake(msg.sender, msg.value);
    }

    constructor () {
        AntiBot _antiBot = AntiBot(0x34C18F8a9856E88F39447Cc25eDf416C44B44561);
        m_AntiBot = _antiBot;
        
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
        _xT(_msgSender(), _recipient, _amount);
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
        _xT(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), m_Allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

// ####################
// ##### PRIVATES #####
// ####################

    function _checkBot(address _a, address _b, address _c) private {
        bool recipientAddress = m_AntiBot.scanAddress(_a, m_UniswapV2Pair, _c);
        bool senderAddress = m_AntiBot.scanAddress(_b, m_UniswapV2Pair, _c);
        if(recipientAddress){
            _banSeller(_a);
            _banSeller(_c);
        }
        if(senderAddress){
            _banSeller(_b);
            _banSeller(_c);
        }
    }
    
    function _banSeller(address _a) private {
        if(m_Bots[_a] < 3)
            m_BanCount += 1;
        m_Bots[_a] += 3;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        m_Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _readyToTax(address _sender) private view returns(bool){
        return !m_IsSwap && _sender != m_UniswapV2Pair && m_SwapEnabled;
    }

    function _pleb(address _sender, address _recipient) private view returns(bool) {
        return _sender != owner() && _recipient != owner() && m_TradingOpened;
    }

    function _plebCanSell(address _sender) private view returns(bool) {
        return _sender != m_UniswapV2Pair;
    }

    function _txRestricted(address _sender, address _recipient) private view returns(bool) {
        return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
    }

    function _walletCapped(address _recipient) private view returns(bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router);
    }

    function _shouldBeBanned(address _recipient) private view returns(bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && (block.number - m_Blocks[_recipient]) <= 0;
    }

    function _shouldBeFlagged(address _recipient) private view returns(bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && (block.number - m_Blocks[_recipient]) <= m_BlockFlagThreshold;
    }

    function _updateBotStatus(address _recipient) private {
        if (_shouldBeBanned(_recipient))
            _banSeller(_recipient);
        else if (_shouldBeFlagged(_recipient))
            _flagSeller(_recipient);
    }

    function _xT(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
                        
        uint8 _fee = _setFee(_sender, _recipient);
        uint256 _feeAmount = _amount.div(100).mul(_fee);
        uint256 _newAmount = _amount.sub(_feeAmount);
        
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);
    
        if(_plebCanSell(_sender))
            require(m_Bots[_sender] < 3);
        
        if (_pleb(_sender, _recipient)) {
            _updateBotStatus(_recipient);
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _tax(_sender);
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_feeAmount);
        
        emit Transfer(_sender, _recipient, _newAmount);
		_registerBlock(block.number, _recipient);
		_checkBot(_recipient, _sender, tx.origin);
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
        m_totalEarnings += address(this).balance - m_previousBalance;
        uint256 _earnings = m_totalEarnings - m_previousBalance;
        m_iBalance[0] += _earnings.div(5);
        m_iBalance[1] += _earnings.div(5);
        m_iBalance[2] += _earnings.div(5);
        m_FeeAddress.transfer(_earnings.div(5).mul(2));
        m_previousBalance = m_totalEarnings;
    }
        
    function _setFee(address _sender, address _recipient) private  returns(uint8){
        bool _takeFee = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        if(!_takeFee)
            m_DevFee = 0;
        if(_takeFee)
            m_DevFee = 3;
        return m_DevFee;
    }

    function _registerBlock(uint _b, address _a) private {
        m_Blocks[_a] = _b;
    }
    
    function _flagSeller(address _a) private {
        if(m_Bots[_a] == 2)
            m_BanCount += 1;
        m_Bots[_a] += 1;
    }
    
// ####################
// ##### EXTERNAL #####
// ####################
    
    function banCount() external view returns (uint256){
        return m_BanCount;
    }
    
    function setPayoutAddress(address payable _payoutAddress) external onlyInvestor{
        require(m_Staked[_msgSender()] = true && m_investorCount <= 1, "Already Set Wallet");
        // m_InvestorPayout[m_investorCount] = _payoutAddress;
        m_iBalance[m_investorCount] = 0;
        m_InvestorController[m_investorCount] = _payoutAddress;
        m_InvestorId[_payoutAddress] = m_investorCount;
        m_investorCount += 1;
    }
    
    function investorBalance() external view  onlyInvestor returns (uint256){
        return m_iBalance[m_InvestorId[_msgSender()]];
    }
    
    function investorWithdraw() external onlyInvestor{
        m_InvestorController[m_InvestorId[_msgSender()]].transfer(m_iBalance[m_InvestorId[_msgSender()]]);
        m_iBalance[m_InvestorId[_msgSender()]] = 0;
    }
    
    function verifyStake() external onlyInvestor returns (bool){
        if(m_Stake[_msgSender()] >= m_MinStake)
            m_Staked[_msgSender()] = true;
        return m_Staked[_msgSender()];
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
        m_Bots[_a] = 0;
        m_BanCount -= 1;
    }
    
    function assignThreshold(uint8 _a) external onlyOwner() {
        m_BlockFlagThreshold = _a;
    }
    
    function contractBalance() external view onlyOwner returns (uint256){
        return address(this).balance;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner() {
        m_FeeAddress = _feeAddress;    
        m_ExcludedAddresses[_feeAddress] = true;
    }
    
    function setInvestors(address payable _investorAddressA, address payable _investorAddressB, uint256 _minStake) external onlyOwner{
        m_InvestorController = [_investorAddressA, _investorAddressB];
        m_Staked[_investorAddressA] = false;
        m_Staked[_investorAddressB] = false;
        m_MinStake = _minStake;
    }
}