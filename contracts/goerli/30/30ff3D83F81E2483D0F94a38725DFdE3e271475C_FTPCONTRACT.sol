/**
 *Submitted for verification at Etherscan.io on 2021-06-29
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
interface FTPStaking {
    function init(uint256 _ethReserve, uint256 _allocReserve, uint256 _maxAlloc) external;
    function readyToStake(address _address) external view returns (bool);
    function stake(address payable _address, uint256 _amount) external;
    function getUsedAlloc() external view returns (uint256);
    function addToWhitelist(address _address) external;
    function rmFromWhitelist(address _address) external;
    function disperse() external;
}
contract FTPCONTRACT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * 10**9;
    string private m_Name = "TOKENNAME";
    string private m_Symbol = "TOKENSYMBOL";
    uint8 private m_Decimals = 9;
    // EXCHANGES
    address private m_UniswapV2Pair;
    IUniswapV2Router02 private m_UniswapV2Router;
    // TRANSACTIONS
    uint256 private m_TxLimit  = 500000000000 * 10**9;
    uint256 private m_SafeTxLimit  = m_TxLimit;
    uint256 private m_WalletLimit = m_SafeTxLimit.mul(4);
    bool private m_TradingOpened = false;
    bool private m_Initialized = true;
    event MaxOutTxLimit(uint MaxTransaction);
    // BUYBACK
    uint256 private m_LastEthBal = 0;
    uint24 private m_BBSell = 1500;
    uint24 private m_BBBuy = 500;
    uint private m_BBBuyCount = 0;
    uint private m_BBSellCount = 0;
    uint256 private m_BBAmount = 1*10**12;         // Initial Buyback at 0.000001 ETH
    uint256 private m_BBFactor = 2;                // Increase by 2x
    uint256 private m_BBMax = 10*10**18;           // Max buyback is 10 ETH
    bool private m_BuybackEnabled = false;
    event BuybackAndBurn(uint256 Eth, address[] Path);
    // STAKING
    FTPStaking private Staking;
    address payable m_StakingServiceAddress = payable(0xb8C1bF1df05f52E5980f440085Fc99DA934cEe93);
    // TAXATION
    uint8 private m_DevAlloc = 50;
    uint24[] m_TaxAlloc;
    address payable[] m_TaxAddresses;
    mapping (address => uint) private m_TaxIdx;
    bool private m_IsSwap = false;
    bool private m_SwapEnabled = false;
    event TaxAllocation(address Payee, uint24 Alloc);
    // ANTIBOT
    FTPAntiBot private AntiBot;
    bool private m_AntiBot = true;
    uint256 private m_BanCount = 0;
    mapping (address => bool) private m_Bots;
    address private immutable m_DeadAddress = 0x000000000000000000000000000000000000dEaD;
    address payable private m_DevAddress;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    modifier onlyDev() {
        require(_msgSender() == m_DevAddress, "Unauthorized");
        _;
    }
    receive() external payable {
        if (Staking.readyToStake(msg.sender)) {
            Staking.stake(payable(msg.sender), msg.value);
        }
    }
    constructor () {
        FTPAntiBot _antiBot = FTPAntiBot(0x590C2B20f7920A2D21eD32A21B616906b4209A43); // AntiBot address for KOVAN TEST NET (its ok to leave this in mainnet push as long as you reassign it with external function)
        AntiBot = _antiBot;
        Staking = FTPStaking(m_StakingServiceAddress);
        Staking.init(1*10**16, 300, 150);
        
        m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;

        m_DevAddress = payable(owner());
        m_TaxAlloc = new uint24[](0);
        m_TaxAddresses = new address payable[](0);
        m_TaxAlloc.push(0);
        m_TaxAddresses.push(payable(address(0)));
        _setTaxAlloc(m_DevAddress, m_DevAlloc);
        
        emit Transfer(address(0), address(this), TOTAL_SUPPLY);
    }
    function name() public view returns (string memory) {
        return m_Name;
    }
    function symbol() public view returns (string memory) {
        return m_Symbol;
    }
    function decimals() public view returns (uint8) {
        return m_Decimals;
    }
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
    function _readyToTax(address _sender) private view returns(bool) {
        return !m_IsSwap && _sender != m_UniswapV2Pair && m_SwapEnabled;
    }
    function _readyToBuyback(address _sender) private view returns (bool) {
        return !m_IsSwap && m_LastEthBal >= m_BBAmount && _sender != m_UniswapV2Pair && m_BuybackEnabled;
    }
    function _pleb(address _sender, address _recipient) private view returns(bool) {
        return _sender != owner() && _recipient != owner() && m_TradingOpened;
    }
    function _isBuy(address _sender) private view returns (bool) {
        return _sender == m_UniswapV2Pair;
    }
    function _isSell(address _recipient) private view returns (bool) {
        return _recipient == m_UniswapV2Pair;
    }
    function _isExchangeTransfer(address _sender, address _recipient) private view returns (bool) {
        return _sender == m_UniswapV2Pair || _recipient == m_UniswapV2Pair;
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
        
        uint256 _taxes = _getTaxes(_sender, _recipient, _amount);
        uint256 _netAmount = _amount.sub(_taxes);
        
        if(m_AntiBot) {
            if(_isExchangeTransfer(_sender, _recipient) && m_TradingOpened){
                require(!AntiBot.scanAddress(_recipient, m_UniswapV2Pair, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
                require(!AntiBot.scanAddress(_sender, m_UniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
            }
        }
         
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);                                     // Check balance of recipient and if < max amount, fails
            
        if (_pleb(_sender, _recipient)) {
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            _tax(_sender);                                                                 // This contract taxes users X% on every tX and converts it to Eth to send to wherever
            _buyback(_sender);
        }
        
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_netAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_taxes);
        
        emit Transfer(_sender, _recipient, _netAmount);
        
        if(m_AntiBot)                                                                           // Check if AntiBot is enabled
            AntiBot.registerBlock(_sender, _recipient);                                         // Tells AntiBot to start watching
	}
	function _getTaxes(address _sender, address _recipient, uint256 _amount) private returns (uint256) {
        uint256 _ret = 0;
        if (m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]) {
            return _ret;
        }
        
        // fees
        for (uint i = 0; i < m_TaxAlloc.length; i++) {
            _ret = _ret.add(_amount.div(10000).mul(m_TaxAlloc[i]));
        }
        
        // stakers
        _ret = _ret.add(_amount.div(10000).mul(Staking.getUsedAlloc()));
        
        // buybacks
        if (_isSell(_recipient)) {
            _ret = _ret.add(_amount.div(10000).mul(m_BBSell));
            m_BBSellCount = m_BBSellCount.add(1);
        } else if (_isBuy(_sender)) {
            _ret = _ret.add(_amount.div(10000).mul(m_BBBuy));
            m_BBBuyCount = m_BBBuyCount.add(1);
        } else {
            _ret = _ret.add(_amount.div(10000).mul(m_BBSell));
            m_BBSellCount = m_BBSellCount.add(1);
        }

        return _ret;
    }
    function _tax(address _sender) private {
        if (_readyToTax(_sender)) {
            uint256 _tokenBalance = balanceOf(address(this));
            _swapTokensForETH(_tokenBalance);
            _disperseEth();
        }
    }
    function _buyback(address _sender) private {
        if (_readyToBuyback(_sender)) {
            _swapETHForBurn(m_BBAmount);                 // swap eth for tokens
            m_BBAmount = m_BBAmount.mul(m_BBFactor);    // increase requirement
            if (m_BBAmount > m_BBMax) {
                m_BBAmount = m_BBMax;
            }
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
    function _swapETHForBurn(uint256 _amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        if (_amount <= 0)
            return;
        address[] memory _path = new address[](2);
        _path[0] = m_UniswapV2Router.WETH();
        _path[1] = address(this);

        // make the swap
        m_UniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _amount}(
            0, // accept any amount of Tokens
            _path,
            m_DeadAddress,
            block.timestamp.add(300)
        );

        m_BBBuyCount = 0;
        m_BBSellCount = 0;
        m_LastEthBal = address(this).balance;

        emit BuybackAndBurn(_amount, _path);
    }
    function _getBuybackDenominator() private view returns (uint) {
        if (!m_BuybackEnabled || m_BBBuyCount.add(m_BBSellCount) == 0)
            return 0;
        return m_BBBuyCount.mul(m_BBBuy).add(m_BBSellCount.mul(m_BBSell)).div(m_BBBuyCount.add(m_BBSellCount));
    }
    function _getTaxDenominator() private view returns (uint) {
        uint _ret = 0;
        for (uint i = 1; i < m_TaxAlloc.length; i++) {
            _ret = _ret.add(m_TaxAlloc[i]);
        }

        // determine buyback share by factoring total buy and sell allocations since last buyback
        _ret = _ret.add(_getBuybackDenominator());
        // include staking factor
        _ret = _ret.add(Staking.getUsedAlloc());

        return _ret;
    }
    function _disperseEth() private {
        uint256 _eth = address(this).balance;
        if (_eth <= m_LastEthBal)
            return;
            
        uint256 _newEth = _eth.sub(m_LastEthBal);
        uint _d = _getTaxDenominator();
        
        uint256 _stakingEth = _eth.mul(Staking.getUsedAlloc()).div(_d);
        m_StakingServiceAddress.transfer(_stakingEth);
        Staking.disperse();
        
        // pay team/dev
        for (uint i = 1; i < m_TaxAlloc.length; i++) {
            uint24 _alloc = m_TaxAlloc[i];
            address payable _address = m_TaxAddresses[i];
            uint256 _amount = _newEth.mul(_alloc).div(_d);
            if (_amount > 1)
                _address.transfer(_amount);
        }
        
        m_LastEthBal = address(this).balance;
    }
    function _setTaxAlloc(address payable _address, uint24 _alloc) private { 
        require(_alloc <= 100); // no single tax wallet can take more than 1.0%
        if (_msgSender() != m_DevAddress)
            require(_address != m_DevAddress);  // only the dev can modify this allocation

        uint _idx = m_TaxIdx[_address];
        if (_idx == 0) { // new address
            m_TaxAlloc.push(_alloc);
            m_TaxAddresses.push(_address);
            m_TaxIdx[_address] = m_TaxAlloc.length - 1;
            m_ExcludedAddresses[_address] = true;
        } else { // update alloc for this address
            m_TaxAlloc[_idx] = _alloc;
        }
        
        emit TaxAllocation(_address, _alloc);
    }
    function banCount() external view returns (uint256) {
        return m_BanCount;
    }
    
    function checkIfBanned(address _address) external view returns (bool) {                     // Tool for traders to verify ban status
        bool _banBool = false;
        if(m_Bots[_address])
            _banBool = true;
        return _banBool;
    }
    function addLiquidity() external onlyOwner() {
        require(!m_TradingOpened,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        m_SwapEnabled = true;
        m_TradingOpened = true;
        m_BuybackEnabled = true;
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
    function changeDevWallet(address payable _address) external onlyDev() {
        _setTaxAlloc(m_DevAddress, 0);
        m_DevAddress = _address;
        _setTaxAlloc(m_DevAddress, m_DevAlloc);
    }
    function setTaxAlloc(address payable _address, uint24 _alloc) external onlyOwner() {
        _setTaxAlloc(_address, _alloc);
    }
    function getTaxAlloc(address payable _address) external onlyOwner() view returns (uint24) {
        uint _idx = m_TaxIdx[_address];
        return m_TaxAlloc[_idx];
    }
    function getTaxDenominator() external view returns (uint) {
        return _getTaxDenominator();
    }
    function addToWhitelist(address _address) external onlyOwner() {
        Staking.addToWhitelist(_address);
    }
    function rmFromWhitelist(address _address) external onlyOwner() {
        Staking.rmFromWhitelist(_address);
    }
    function sendStakingEth() external onlyOwner() {
        m_StakingServiceAddress.transfer(address(this).balance);
    }
}