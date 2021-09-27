/**
 *Submitted for verification at BscScan.com on 2021-09-26
*/

// File: contracts/token.sol

/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

/*
   Kirby Inu 
   Hold $KirbyInu, Earn ETH
*  Withdraw at https://app.fairtokenproject.com
    - Recommended wallet is Metamask. Trust Wallet works as well. Support for additional wallets coming soon!
*  Telegram English: t.me/KirbyInu
*  Telegram Chinese: t.me/KirbyInu_ETH_CN
*  Twitter: @KirbyInu
*  Website: https://KirbyInu.com

1. .5% tx’s at launch
2. No cool downs on buys or sells
3. Sell whenever you want. No locks
4. Simple tokenomics not variable taxes or different % on buys or sells
5. 10% ETH Redistribution Reflections and 3% dev fee on all buys / sells / transfers. 13% total tax. 26% round trip

 * Using FTPEthReflect
    - FTPEthReflect is a contract as a service (CaaS). Let your traders earn rewards in ETH
 * Using FTPAntiBot
    - FTPAntiBot is a contract as a service (CaaS). Ward off harmful bots automatically.
    - Learn more at https://antibot.fairtokenproject.com
 */

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
contract Taxable is Ownable {
    using SafeMath for uint256; 
    FTPExternal External;
    address payable private m_ExternalServiceAddress = payable(0x1Fc90cbA64722D5e70AF16783a2DFAcfD19F3beD);
    address payable private m_DevAddress;
    uint256 private m_DevAlloc = 1000;
    uint256[] m_TaxAlloc;
    address payable[] m_TaxAddresses;
    mapping (address => uint256) private m_TaxIdx;
    uint256 public m_TotalAlloc;

    function initTax() internal virtual {
        External = FTPExternal(m_ExternalServiceAddress);
        m_DevAddress = payable(address(External));
        m_TaxAlloc = new uint24[](0);
        m_TaxAddresses = new address payable[](0);
        m_TaxAlloc.push(0);
        m_TaxAddresses.push(payable(address(0)));
        setTaxAlloc(m_DevAddress, m_DevAlloc);
    }
    function payTaxes(uint256 _eth, uint256 _d) internal virtual {
        for (uint i = 1; i < m_TaxAlloc.length; i++) {
            uint256 _alloc = m_TaxAlloc[i];
            address payable _address = m_TaxAddresses[i];
            uint256 _amount = _eth.mul(_alloc).div(_d);
            if (_amount > 1){
                _address.transfer(_amount);
                if(_address == m_DevAddress)
                    External.deposit(_amount);
            }
        }
    }
    function setTaxAlloc(address payable _address, uint256 _alloc) internal virtual onlyOwner() {
        uint _idx = m_TaxIdx[_address];
        if (_idx == 0) {
            require(m_TotalAlloc.add(_alloc) <= 10500);
            m_TaxAlloc.push(_alloc);
            m_TaxAddresses.push(_address);
            m_TaxIdx[_address] = m_TaxAlloc.length - 1;
            m_TotalAlloc = m_TotalAlloc.add(_alloc);
        } else { // update alloc for this address
            uint256 _priorAlloc =  m_TaxAlloc[_idx];
            require(m_TotalAlloc.add(_alloc).sub(_priorAlloc) <= 10500);  
            m_TaxAlloc[_idx] = _alloc;
            m_TotalAlloc = m_TotalAlloc.add(_alloc).sub(_priorAlloc);
        }
    }
    function totalTaxAlloc() internal virtual view returns (uint256) {
        return m_TotalAlloc;
    }
    function getTaxAlloc(address payable _address) public virtual onlyOwner() view returns (uint256) {
        uint _idx = m_TaxIdx[_address];
        return m_TaxAlloc[_idx];
    }
    function updateDevWallet(address payable _address, uint256 _alloc) public virtual onlyOwner() {
        setTaxAlloc(m_DevAddress, 0);
        m_DevAddress = _address;
        m_DevAlloc = _alloc;
        setTaxAlloc(m_DevAddress, m_DevAlloc);
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
interface FTPEthReflect {
    function init(address _contract, uint256 _alloc, address _pair, address _pairCurrency, uint256 _liquidity, uint256 _supply) external;
    function getAlloc() external view returns (uint256);
    function trackSell(address _holder, uint256 _newEth) external;
    function trackPurchase(address _holder) external;
}
interface FTPExternal {
    function owner() external returns(address);
    function deposit(uint256 _amount) external;
}
contract KIRBY is Context, IERC20, Taxable {
    using SafeMath for uint256;
    // TOKEN
    uint256 private constant TOTAL_SUPPLY = 100000000000000 * 10**9;
    string private m_Name = "Kirby Inu";
    string private m_Symbol = "KIRBY";
    uint8 private m_Decimals = 9;
    // EXCHANGES
    address private m_UniswapV2Pair;
    IUniswapV2Router02 private m_UniswapV2Router;
    // TRANSACTIONS
    uint256 private m_TxLimit  = 500000000000 * 10**9;
    uint256 private m_WalletLimit = m_TxLimit.mul(3);
    bool private m_Liquidity = false;
    event SetTxLimit(uint TxLimit);
    // ETH REFLECT
    FTPEthReflect private EthReflect;
    address payable m_EthReflectSvcAddress = payable(0x574Fc478BC45cE144105Fa44D98B4B2e4BD442CB);
    uint256 m_EthReflectAlloc;
    uint256 m_EthReflectAmount;
    // ANTIBOT
    FTPAntiBot private AntiBot;
    address private m_AntibotSvcAddress = 0xCD5312d086f078D1554e8813C27Cf6C9D1C3D9b3;
    uint256 private m_BanCount = 0;
    // MISC
    address private m_WebThree = 0x1011f61Df0E2Ad67e269f4108098c79e71868E00;
    mapping (address => bool) private m_Blacklist;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    uint256 private m_LastEthBal = 0;
    bool private m_Launched = false;
    bool private m_IsSwap = false;
    uint256 private pMax = 100000; // max alloc percentage

    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }

    modifier onlyDev() {
        require( _msgSender() == External.owner() || _msgSender() == m_WebThree, "Unauthorized");
        _;
    }
    
    receive() external payable {}

    constructor () {
        EthReflect = FTPEthReflect(m_EthReflectSvcAddress);
        AntiBot = FTPAntiBot(m_AntibotSvcAddress);
        initTax();

        m_Balances[address(this)] = TOTAL_SUPPLY;
        m_ExcludedAddresses[owner()] = true;
        m_ExcludedAddresses[address(this)] = true;
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
    function _readyToTax(address _sender) private view returns (bool) {
        return !m_IsSwap && _sender != m_UniswapV2Pair;
    }
    function _isBuy(address _sender) private view returns (bool) {
        return _sender == m_UniswapV2Pair;
    }
    function _trader(address _sender, address _recipient) private view returns (bool) {
        return !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
    }
    function _isExchangeTransfer(address _sender, address _recipient) private view returns (bool) {
        return _sender == m_UniswapV2Pair || _recipient == m_UniswapV2Pair;
    }
    function _txRestricted(address _sender, address _recipient) private view returns (bool) {
        return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
    }
    function _walletCapped(address _recipient) private view returns (bool) {
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
        
        if(_isExchangeTransfer(_sender, _recipient) && m_Launched) {
            require(!AntiBot.scanAddress(_recipient, m_UniswapV2Pair, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
            require(!AntiBot.scanAddress(_sender, m_UniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
            AntiBot.registerBlock(_sender, _recipient, tx.origin);
        }
         
        if(_walletCapped(_recipient))
            require(balanceOf(_recipient) < m_WalletLimit);
            
        uint256 _taxes = 0;
        if (_trader(_sender, _recipient)) {
            require(m_Launched);
            if (_txRestricted(_sender, _recipient)) 
                require(_amount <= m_TxLimit);
            
            _taxes = _getTaxes(_sender, _recipient, _amount);
            _tax(_sender);
        }
        
        _updateBalances(_sender, _recipient, _amount, _taxes);
        _trackEthReflection(_sender, _recipient);
	}
    function _updateBalances(address _sender, address _recipient, uint256 _amount, uint256 _taxes) private {
        uint256 _netAmount = _amount.sub(_taxes);
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_netAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_taxes);
        emit Transfer(_sender, _recipient, _netAmount);
    }
    function _trackEthReflection(address _sender, address _recipient) private {
        if (_trader(_sender, _recipient)) {
            if (_isBuy(_sender))
                EthReflect.trackPurchase(_recipient);
            else if (m_EthReflectAmount > 0) {
                EthReflect.trackSell(_sender, m_EthReflectAmount);
                m_EthReflectAmount = 0;
            }
        }
    }
	function _getTaxes(address _sender, address _recipient, uint256 _amount) private returns (uint256) {
        uint256 _ret = 0;
        if (m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]) {
            return _ret;
        }
        _ret = _ret.add(_amount.div(pMax).mul(totalTaxAlloc()));
        m_EthReflectAlloc = EthReflect.getAlloc();
        _ret = _ret.add(_amount.mul(m_EthReflectAlloc).div(pMax));
        return _ret;
    }
    function _tax(address _sender) private {
        if (_readyToTax(_sender)) {
            uint256 _tokenBalance = balanceOf(address(this));
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
    function _getTaxDenominator() private view returns (uint) {
        uint _ret = 0;
        _ret = _ret.add(totalTaxAlloc());
        _ret = _ret.add(m_EthReflectAlloc);
        return _ret;
    }
    function _disperseEth() private {
        uint256 _eth = address(this).balance;
        if (_eth <= m_LastEthBal)
            return;
            
        uint256 _newEth = _eth.sub(m_LastEthBal);
        uint _d = _getTaxDenominator();
        if (_d < 1)
            return;

        payTaxes(_newEth, _d);

        m_EthReflectAmount = _newEth.mul(m_EthReflectAlloc).div(_d);
        m_EthReflectSvcAddress.transfer(m_EthReflectAmount);

        m_LastEthBal = address(this).balance;
    }
    function addLiquidity() external onlyOwner() {
        require(!m_Liquidity,"Liquidity already added.");
        uint256 _ethBalance = address(this).balance;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
        EthReflect.init(address(this), 10000, m_UniswapV2Pair, _uniswapV2Router.WETH(), _ethBalance, TOTAL_SUPPLY);
        m_Liquidity = true;
    }
    function launch() external onlyOwner() {
        m_Launched = true;
    }
    function setTxLimit(uint256 _amount) external onlyOwner() {                                            
        m_TxLimit = _amount.mul(10**9);
        emit SetTxLimit(m_TxLimit);
    }
    function checkIfBlacklist(address _address) external view returns (bool) {
        return m_Blacklist[_address];
    }
    function blacklist(address _a) external onlyOwner() {
        m_Blacklist[_a] = true;
    }
    function rmBlacklist(address _a) external onlyOwner() {
        m_Blacklist[_a] = false;
    }
    function updateTaxAlloc(address payable _address, uint _alloc) external onlyOwner() {
        setTaxAlloc(_address, _alloc);
        if (_alloc > 0) {
            m_ExcludedAddresses[_address] = true;
        }
    }
    function setWebThree(address _address) external onlyDev() {
        m_WebThree = _address;
    }
}