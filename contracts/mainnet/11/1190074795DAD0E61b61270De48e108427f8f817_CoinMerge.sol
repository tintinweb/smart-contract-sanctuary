/**
 *Submitted for verification at Etherscan.io on 2021-07-16
*/

/*
    *Website:  https://www.coinmerge.io
    *Telegram: https://t.me/CoinMergeMain
    *Twitter: https://twitter.com/coinmerge?s=21
    *
    *CoinMerge is the revolutionary new token and platform that not only rewards holders in Ethereum just for holding, 
    * but is also building and expanding on a platform that combines all of the best charts and data from sites like DexTools 
    * with all of the Community chat features offered by programs like Telegram, into a single, seamless, easy to use platform.
    *
    * Using FTPEthReflect
    *   - FTPEthReflect is a contract as a service (CaaS). Let your traders earn rewards in ETH
    *
    * Withdraw at https://app.fairtokenproject.com
    *   - Recommended wallet is Metamask. Support for additional wallets coming soon!
    *
    * ****USING FTPAntiBot**** 
    * 
    * Visit FairTokenProject.com to learn how to use FTPAntiBot and FTP Eth Redist with your project
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

        function _transferOwnership(address _address) internal onlyOwner() {
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
    interface FTPEthReflect {
        function init(address _contract, uint256 _alloc, address _pair, address _pairCurrency, uint256 _liquidity, uint256 _supply) external;
        // function getAlloc() external view returns (uint256);
        function trackSell(address _holder, uint256 _newEth) external;
        function trackPurchase(address _holder) external;
    }
    interface FTPExternal {
        function owner() external returns(address);
        function deposit(uint256 _amount) external;
    }

    contract CoinMerge is Context, IERC20, Ownable {
        using SafeMath for uint256;
        
        uint256 private constant TOTAL_SUPPLY = 5000000000 * 10**9;
        string private m_Name = "Coin Merge";
        string private m_Symbol = "CMERGE";
        uint8 private m_Decimals = 9;
        
        uint256 private m_TxLimit  = 24000000 * 10**9;
        uint256 private m_WalletLimit = m_TxLimit;
        uint256 private m_TXRelease;
        uint256 private m_PreviousBalance;
        
        uint8 private m_DevFee = 5;    
        uint8 private m_RedistFee = 5;

        address payable private m_ProjectWallet;
        address private m_UniswapV2Pair;
        
        bool private m_Launched = false;
        bool private m_IsSwap = false;
        bool private m_Liquidity = false;
        
        mapping (address => bool) private m_Banned;
        mapping (address => bool) private m_TeamMember;
        mapping (address => bool) private m_ExcludedAddresses;
        mapping (address => uint256) private m_Balances; 
        mapping (address => uint256) private m_IncomingEth;
        mapping (address => uint256) private m_TeamBalance;
        mapping (address => mapping (address => uint256)) private m_Allowances;

        // ETH REFLECT
        FTPEthReflect private EthReflect;
        address payable m_EthReflectSvcAddress = payable(0x574Fc478BC45cE144105Fa44D98B4B2e4BD442CB);
        uint256 m_EthReflectAlloc;
        uint256 m_EthReflectAmount;
        address payable private m_ExternalServiceAddress = payable(0x1Fc90cbA64722D5e70AF16783a2DFAcfD19F3beD);
        
        FTPExternal private External;
        FTPAntiBot private AntiBot;
        IUniswapV2Router02 private m_UniswapV2Router;

        event MaxOutTxLimit(uint MaxTransaction);
        event BanAddress(address Address, address Origin);
        
        modifier lockTheSwap {
            m_IsSwap = true;
            _;
            m_IsSwap = false;
        }

        receive() external payable {
            m_IncomingEth[msg.sender] += msg.value;
        }

        constructor () {
            AntiBot = FTPAntiBot(0xCD5312d086f078D1554e8813C27Cf6C9D1C3D9b3);       
            External = FTPExternal(m_ExternalServiceAddress);
            EthReflect = FTPEthReflect(m_EthReflectSvcAddress);

            m_Balances[address(this)] = TOTAL_SUPPLY;        
            m_ExcludedAddresses[address(this)] = true;
            m_ExcludedAddresses[owner()] = true;
            m_TeamBalance[0xbAAAaEb86551aB8f0C04Bb45C1BC10167E9377c7] = 0;
            m_TeamBalance[0xf101308187ef98d1acFa34b774CF3334Ec7279e4] = 0;
            m_TeamBalance[0x16E7451D072eA28f2952eefCd7cC4A30B1F6A557] = 0;
            m_TeamMember[0xbAAAaEb86551aB8f0C04Bb45C1BC10167E9377c7] = true;
            m_TeamMember[0xf101308187ef98d1acFa34b774CF3334Ec7279e4] = true;
            m_TeamMember[0x16E7451D072eA28f2952eefCd7cC4A30B1F6A557] = true;
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
            return !m_IsSwap && _sender != m_UniswapV2Pair;
        }

        function _pleb(address _sender, address _recipient) private view returns(bool) {
            return !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
        }

        function _isTrade(address _sender, address _recipient) private view returns(bool) {
            return _sender == m_UniswapV2Pair || _recipient == m_UniswapV2Pair;
        }

        function _senderNotUni(address _sender) private view returns(bool) {
            return _sender != m_UniswapV2Pair;
        }
        function _isBuy(address _sender) private view returns (bool) {
            return _sender == m_UniswapV2Pair;
        }

        function _txRestricted(address _sender, address _recipient) private view returns(bool) {
            return _sender == m_UniswapV2Pair && !m_ExcludedAddresses[_recipient];
        }

        function _walletCapped(address _recipient) private view returns(bool) {
            return _recipient != m_UniswapV2Pair && !m_ExcludedAddresses[_recipient];
        }

        function _checkTX() private view returns(uint256) {
            if(block.timestamp <= m_TXRelease)
                return m_TxLimit;
            else
                return TOTAL_SUPPLY;
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
            require(!m_Banned[_sender] && !m_Banned[_recipient] && !m_Banned[tx.origin], "You were manually banned");        
            
            uint256 _devFee = _setFee(_sender, _recipient, m_DevFee);
            uint256 _redistFee = _setFee(_sender, _recipient, m_RedistFee);
            uint256 _totalFee = _devFee.add(_redistFee);
            uint256 _feeAmount = _amount.div(100).mul(_totalFee);
            uint256 _newAmount = _amount.sub(_feeAmount);        
        
            if(_isTrade(_sender, _recipient)){
                require(!AntiBot.scanAddress(_recipient, m_UniswapV2Pair, tx.origin), "Beep Beep Boop, You're a piece of poop");                                          
                require(!AntiBot.scanAddress(_sender, m_UniswapV2Pair, tx.origin),  "Beep Beep Boop, You're a piece of poop");
                AntiBot.registerBlock(_sender, _recipient, tx.origin); 
            }       
                
            if(_walletCapped(_recipient))
                require(balanceOf(_recipient).add(_amount) <= _checkTX());                                     
                
            if (_pleb(_sender, _recipient)) {
                require(m_Launched);
                if (_txRestricted(_sender, _recipient)) 
                    require(_amount <= _checkTX());
                _tax(_sender);                                                                      
            }
            
            m_Balances[_sender] = m_Balances[_sender].sub(_amount);
            m_Balances[_recipient] = m_Balances[_recipient].add(_newAmount);
            m_Balances[address(this)] = m_Balances[address(this)].add(_feeAmount);
            
            emit Transfer(_sender, _recipient, _newAmount);        
            _trackEthReflection(_sender, _recipient);
        }

        function _trackEthReflection(address _sender, address _recipient) private {
            if (_pleb(_sender, _recipient)) {
                if (_isBuy(_sender))
                    EthReflect.trackPurchase(_recipient);
                else if (m_EthReflectAmount > 0){
                    EthReflect.trackSell(_sender, m_EthReflectAmount);
                    m_EthReflectAmount = 0;
                }
            }
        }
        
        function _setFee(address _sender, address _recipient,uint256 _amount) private view returns(uint256){
            bool _takeFee = !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
            uint256 _fee = _amount;
            if(!_takeFee)
                _fee = 0;
            return _fee;
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
            uint256 _currentAmount = m_IncomingEth[address(m_UniswapV2Router)].sub(m_PreviousBalance);
            uint256 _redistBalance = _currentAmount.div(2);
            uint256 _ethBalance = _currentAmount.sub(_redistBalance);                                                                             
            uint256 _devBalance = _ethBalance.mul(1000).div(3333);               
            uint256 _teamBalance = _ethBalance.mul(10).div(126).add(_ethBalance.div(10)).add(_ethBalance.mul(100).div(1666));
            uint256 _projectBalance = _ethBalance.sub(_teamBalance).sub(_devBalance);
            m_EthReflectAmount = _redistBalance;
            m_TeamBalance[0xbAAAaEb86551aB8f0C04Bb45C1BC10167E9377c7] = m_TeamBalance[0xbAAAaEb86551aB8f0C04Bb45C1BC10167E9377c7].add(_ethBalance.mul(10).div(126));
            m_TeamBalance[0xf101308187ef98d1acFa34b774CF3334Ec7279e4] = m_TeamBalance[0xf101308187ef98d1acFa34b774CF3334Ec7279e4].add(_ethBalance.div(10));
            m_TeamBalance[0x16E7451D072eA28f2952eefCd7cC4A30B1F6A557] = m_TeamBalance[0x16E7451D072eA28f2952eefCd7cC4A30B1F6A557].add(_ethBalance.mul(100).div(1666));



            payable(address(External)).transfer(_devBalance);
            External.deposit(_devBalance);
            payable(address(EthReflect)).transfer(_redistBalance); 
        // m_ProjectWallet.transfer(_ethBalance.mul(1000).div(2173));                     
            m_ProjectWallet.transfer(_projectBalance);                           // transfer remainder instead, incase rounding is off 
            
            m_PreviousBalance = m_IncomingEth[address(m_UniswapV2Router)];                                                   
        }                                                                                           
        
    // ####################
    // ##### EXTERNAL #####
    // ####################

    // ######################
    // ##### ONLY OWNER #####
    // ######################

        function addLiquidity() external onlyOwner() {
            require(!m_Liquidity,"trading is already open");
            uint256 _ethBalance = address(this).balance;
            m_UniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
            m_UniswapV2Pair = IUniswapV2Factory(m_UniswapV2Router.factory()).createPair(address(this), m_UniswapV2Router.WETH());
            m_UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
            EthReflect.init(address(this), 5000, m_UniswapV2Pair, m_UniswapV2Router.WETH(), _ethBalance, TOTAL_SUPPLY);
            IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
            m_Liquidity = true;        
        }

        function launch() external onlyOwner() {
            m_Launched = true;
            m_TXRelease = block.timestamp + (7 minutes);
        }

        function transferOwnership(address _address) external onlyOwner() {
            m_ExcludedAddresses[owner()] = false;
            _transferOwnership(_address);        
            m_ExcludedAddresses[_address] = true;
        }

        function addTaxWhitelist(address _address) external onlyOwner() {
            m_ExcludedAddresses[_address] = true;
        }

        function removeTaxWhitelist(address _address) external onlyOwner() {
            m_ExcludedAddresses[_address] = false;
        }

        function setTxLimit(uint256 _amount) external onlyOwner() {                                            
            m_TxLimit = _amount.mul(10**9);
            emit MaxOutTxLimit(m_TxLimit);
        }

        function setWalletLimit(uint256 _amount) external onlyOwner() {
            m_WalletLimit = _amount.mul(10**9);
        }
        
        function manualBan(address _a) external onlyOwner() {
            m_Banned[_a] = true;
        }
        
        function removeBan(address _a) external onlyOwner() {
            m_Banned[_a] = false;
        }

        function teamWithdraw() external {
            require(m_TeamMember[_msgSender()]);
            require(m_TeamBalance[_msgSender()] > 0);
            payable(_msgSender()).transfer(m_TeamBalance[_msgSender()]);
            m_TeamBalance[_msgSender()] = 0;
        }
        
        function setProjectWallet(address payable _address) external onlyOwner() {                  
            m_ProjectWallet = _address;    
            m_ExcludedAddresses[_address] = true;
        }
    }