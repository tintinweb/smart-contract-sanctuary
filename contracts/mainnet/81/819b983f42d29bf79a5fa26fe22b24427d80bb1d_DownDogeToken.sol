/**
 *Submitted for verification at Etherscan.io on 2021-07-14
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
    address private _Owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _Owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _Owner;
    }

    modifier onlyOwner() {
        require(_Owner == _msgSender(), "Ownable: caller is not the owner");
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

interface FTPAntiBot {
    function scanAddress(address _address, address _safeAddress, address _origin) external returns (bool);
    function registerBlock(address _recipient, address _sender, address _origin) external;
}

contract Balancer {
    constructor()  {
    }
}

contract DownDogeToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    
    uint256 internal _total_supply = 1_000_000_000_000 * 10**9;
    string private _Name = "Down Doge Token";
    string private _Symbol = "DDT";
    uint8 private _Decimals = 9;
    
    uint256 private _BanCount = 0;

    uint256 public _minTokensBeforeSwap = 1_000_000 * 10**9; // 1,000,000 DDT
    uint256 public _minWeiBeforeSwap = 1000_000_000 * 10**9; // 1 Eth

    uint256 public _lastBuyAndBurn = block.timestamp ;
    uint256 public _buyAndBurnInterval = 30 minutes;
    uint256 public _totalBurntFees;
    
    uint256 private _BuyBackFee = 6;
    uint256 private _CharityFee = 2;
    uint256 private _DevFee = 2;
    
    address payable private _FeeAddress;
    address payable private _DevAddress;
    address private _UniswapV2Pair;
    

    bool private _IsSwap = false;
    bool private _AntiBotEnabled = true;
    bool private _buyAndBurnEnabled = true;

    address public _AntiBotAddress = 0xCD5312d086f078D1554e8813C27Cf6C9D1C3D9b3;
    address public _DeadWallet = 0x000000000000000000000000000000000000dEaD;
    address public _balancer;
    bool public _SwapEnabled = false;
    bool public _TradingOpened = false;
    
    uint256 public _CalledReadyToTax = 0;
    bool public _CalledReadyToTax2 = false;
    uint256 public _CalledTax1 = 0;
    uint256 public _CalledTax2 = 0;
    uint256 public _CalledTax3 = 0;
    uint256 public _CalledSenderNotUni = 0;
    uint256 public _CalledBuyAndBurn = 0;
    uint256 public _CalledCanSwap = 0;
    uint256 public _CalledSwapTokensForETH = 0;
    
    mapping (address => bool) private _Bots;
    mapping (address => bool) private _ExcludedAddresses;

    mapping (address => uint256) private _Balances;
    mapping (address => mapping (address => uint256)) private _Allowances;
    
    FTPAntiBot private AntiBot;
    IUniswapV2Router02 private _UniswapV2Router;

    event BanAddress(address Address, address Origin);
    event Burnt(uint256 Amount);
    
    modifier lockTheSwap {
        _IsSwap = true;
        _;
        _IsSwap = false;
    }

    constructor (address payable _feeAddress, address payable _devAddress ) {
        
        _FeeAddress = _feeAddress;
        _DevAddress = _DevAddress;
        _initAntiBot(); // activates antibot if enabled
        _balancer = address(new Balancer()); // new contract to handle auto buy-back

        _Balances[owner()] = _total_supply.div(100).mul(50); // send 50% to owner address for presale, remaining will be sent back to contract before liquidity will be added.
        _Balances[address(this)] = _total_supply.div(100).mul(50);
        _ExcludedAddresses[owner()] = true;
        _ExcludedAddresses[address(this)] = true;
        _ExcludedAddresses[_balancer] = true;
        _ExcludedAddresses[_feeAddress] = true;
        _ExcludedAddresses[_devAddress] = true;

        
        emit Transfer(address(0), address(this), _total_supply);
    }
    
    receive() external payable {}

// ####################
// ##### DEFAULTS #####
// ####################

    function name() public view returns (string memory) {
        return _Name;
    }

    function symbol() public view returns (string memory) {
        return _Symbol;
    }

    function decimals() public view returns (uint8) {
        return _Decimals;
    }

// #####################
// ##### OVERRIDES #####
// #####################

    function totalSupply() public view override returns (uint256) {
        return _total_supply;
    }

    function balanceOf(address _account) public view override returns (uint256) {
        return _Balances[_account];
    }

    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _Allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(_msgSender(), _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, _msgSender(), _Allowances[_sender][_msgSender()].sub(_amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

// ####################
// ##### PRIVATES #####
// ####################

    function _readyToTax(address _sender) private returns(bool) {
        _CalledReadyToTax += 1;
        _CalledReadyToTax2 = _senderNotUni(_sender) && !_ExcludedAddresses[_sender] && _SwapEnabled;
        return _CalledReadyToTax2;
    }
    
    function _notOwnerAddress(address _sender, address _recipient) private view returns(bool) {
        return _sender != owner() && _recipient != owner() && _TradingOpened;
    }

    function _senderNotUni(address _sender) private view returns(bool) {
        return _sender != _UniswapV2Pair;
    }

    function _approve(address _owner, address _spender, uint256 _amount) private {
        require(_owner != address(0), "ERC20: approve from the zero address");
        require(_spender != address(0), "ERC20: approve to the zero address");
        _Allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) private {
        require(_sender != address(0), "ERC20: transfer from the zero address");
        require(_recipient != address(0), "ERC20: transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        require(_TradingOpened || _sender == owner() || _recipient == owner() ||
                _ExcludedAddresses[_sender] || _ExcludedAddresses[_recipient], "Trading is locked.");
        
                        
        uint256 _bbFee = _setBuyBackFee(_sender, _recipient); // buy-back fees
        uint256 _cFee = _setCharityFee(_sender, _recipient); // charity fee
        uint256 _dFee = _setDevFee(_sender, _recipient); // dev fee

        uint256 _bbFeeAmount = _amount.div(100).mul(_bbFee);
        uint256 _cFeeAmount = _amount.div(100).mul(_cFee);
        uint256 _dFeeAmount = _amount.div(100).mul(_dFee);
        uint256 _totalFee = _bbFeeAmount.add(_cFeeAmount).add(_dFeeAmount);

        uint256 _newAmount = _amount.sub(_totalFee);
        _Balances[address(this)] = _Balances[address(this)].add(_totalFee);
        
         if (_AntiBotEnabled)
            _checkBot(_recipient, _sender, tx.origin); //calls AntiBot for results
        
        if(_senderNotUni(_sender)) {
            _CalledSenderNotUni += 1;
            require(!_Bots[_sender]); // Local logic for banning based on AntiBot results 
            _tax(_sender);
        }

        _Balances[_sender] = _Balances[_sender].sub(_amount);
        _Balances[_recipient] = _Balances[_recipient].add(_newAmount);

        
        emit Transfer(_sender, _recipient, _newAmount);

        if (_AntiBotEnabled)
            AntiBot.registerBlock(_sender, _recipient, tx.origin); //Tells AntiBot to start watching
	}
	
	function _checkBot(address _recipient, address _sender, address _origin) private {
        if((_recipient == _UniswapV2Pair || _sender == _UniswapV2Pair) && _TradingOpened){
            bool recipientAddress = AntiBot.scanAddress(_recipient, _UniswapV2Pair, _origin); // Get AntiBot result
            bool senderAddress = AntiBot.scanAddress(_sender, _UniswapV2Pair, _origin); // Get AntiBot result
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
        if(!_Bots[_address])
            _BanCount += 1;
        _Bots[_address] = true;
    }
	
	function _setBuyBackFee(address _sender, address _recipient) private view returns(uint256){
        bool _takeFee = !(_ExcludedAddresses[_sender] || _ExcludedAddresses[_recipient]);
        uint256 _buyBackFee;
        
        if(!_takeFee)
            _buyBackFee = 0;
        if(_takeFee)
            _buyBackFee = _BuyBackFee;
        return _buyBackFee;
    }

	function _setCharityFee(address _sender, address _recipient) private view returns(uint256){
        bool _takeFee = !(_ExcludedAddresses[_sender] || _ExcludedAddresses[_recipient]);
        uint256 _charityFee;
        
        if(!_takeFee)
            _charityFee = 0;
        if(_takeFee)
            _charityFee = _CharityFee;
        return _charityFee;
    }
    
	function _setDevFee(address _sender, address _recipient) private view returns(uint256){
        bool _takeFee = !(_ExcludedAddresses[_sender] || _ExcludedAddresses[_recipient]);
        uint256 _devFee;
        
        if(!_takeFee)
            _devFee = 0;
        if(_takeFee)
            _devFee = _DevFee;
        return _devFee;
    }

    function _tax(address _sender) private {
        uint256 _tokenBalance = balanceOf(address(this));
        uint256 _FeesSum = _CharityFee.add(_BuyBackFee).add(_DevFee);
        
        uint256 _cAmount = _tokenBalance.div(_FeesSum).mul(_CharityFee);
        uint256 _bbAmount = _tokenBalance.div(_FeesSum).mul(_BuyBackFee);
        uint256 _dAmount = _tokenBalance.div(_FeesSum).mul(_DevFee);
        
        uint256 _contractBalance = address(this).balance;
        
        bool swap = true;
        
        _CalledTax1 += 1;

        if (block.timestamp > _lastBuyAndBurn + _buyAndBurnInterval 
            && _buyAndBurnEnabled
            && _contractBalance >= _minWeiBeforeSwap) {
                _CalledBuyAndBurn += 1;
                _buyAndBurnToken(_contractBalance);
                swap = false;
        }
        
        if (swap) {
            _CalledCanSwap += 1;
            if (_readyToTax(_sender)) {
                _CalledTax2 += 1;
                if (_tokenBalance >= _minTokensBeforeSwap) {
                    _CalledTax3 += 1;
                    _swapTokensForETH(address(this), _bbAmount);
                    _swapTokensForETH(_FeeAddress, _cAmount);
                    _swapTokensForETH(_DevAddress, _dAmount);
                }
            }
        }
    }

    function _swapTokensForETH(address _recipient, uint256 _amount) private lockTheSwap {
        _CalledSwapTokensForETH += 1;
        address[] memory _path = new address[](2);
        _path[0] = address(this);
        _path[1] = _UniswapV2Router.WETH();
        _approve(address(this), address(_UniswapV2Router), _amount);
        _UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            _path,
            _recipient,
            block.timestamp
        );
    }
    
    function _swapEthForTokens(uint256 _EthAmount) private {
        address[] memory _path = new address[](2);
        _path[0] = _UniswapV2Router.WETH();
        _path[1] = address(this);

        //@dev buy back tokens but send bought tokens to balancer to be burnt
        _UniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _EthAmount}(
                0,
                _path,
                address(_balancer),
                block.timestamp
            );
    }
    
    function _initAntiBot() private {
        if (_AntiBotEnabled) {
            FTPAntiBot _antiBot = FTPAntiBot(_AntiBotAddress);
            AntiBot = _antiBot;
        }
    }

    function _buyAndBurnToken(uint256 _contractBalance) private lockTheSwap {
        _lastBuyAndBurn = block.timestamp;
        
        //@dev using smart contract generated account to automate buybacks, Uniswap doesn't allow for a contract to by itself
        _swapEthForTokens(_contractBalance);

        //@dev How much tokens we swaped into
        uint256 _swapedTokens = balanceOf(address(_balancer));
        uint256 amountToBurn = _swapedTokens;
        _Balances[address(_balancer)] = 0;
        _Balances[_DeadWallet] = _Balances[_DeadWallet].add(amountToBurn);

        
        _totalBurntFees = _totalBurntFees.add(amountToBurn);

        emit Transfer(address(_balancer), _DeadWallet, amountToBurn);
        emit Burnt(amountToBurn);
    }
    
    
// ####################
// ##### EXTERNAL #####
// ####################
    function banCount() external view returns (uint256) {
        return _BanCount;
    }
    
    function checkIfBanned(address _address) external view returns (bool) { //Tool for traders to verify ban status
        bool _banBool = false;
        if(_Bots[_address])
            _banBool = true;
        return _banBool;
    }

    function isAntiBotEnabled() external view returns (bool) {
        return _AntiBotEnabled;
    }    
    
    function isBuyAndBurnEnabled() external view returns (bool) {
        return _buyAndBurnEnabled;
    }
    
// ######################
// ##### ONLY OWNER #####
// ######################
    function addLiquidity() external onlyOwner() {
        require(!_TradingOpened,"trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(_UniswapV2Router), _total_supply);
        _UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _UniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp); // check 
        _SwapEnabled = true;
        _TradingOpened = true;
        IERC20(_UniswapV2Pair).approve(address(_UniswapV2Router), type(uint).max);
    }
    
    function manualBan(address _a) external onlyOwner() {
       _banSeller(_a);
    }
    
    function removeBan(address _a) external onlyOwner() {
        _Bots[_a] = false;
        _BanCount -= 1;
    }
    
    function contractEthBalance() external view onlyOwner() returns (uint256) {
        return address(this).balance;
    }
    
    function setFeeAddress(address payable _feeAddress) external onlyOwner() {
        _FeeAddress = _feeAddress;    
        _ExcludedAddresses[_feeAddress] = true;
    }
   
    function setBuyAndBurnFee(uint256 _fee) external onlyOwner() {
        _BuyBackFee = _fee;    
    }
   
    function setCharityFee(uint256 _fee) external onlyOwner() {
        _CharityFee = _fee;    
    }
     
    function setDevFee(uint256 _fee) external onlyOwner() {
        _DevFee = _fee;    
    }

    function assignAntiBot(address _address) external onlyOwner() {                             // Highly recommend use of a function that can edit AntiBot contract address to allow for AntiBot version updates
        _AntiBotAddress = _address;                 
        _initAntiBot();
    }

    function setMinBuyAndBurnWei(uint256 _amount) public onlyOwner {
        _minWeiBeforeSwap = _amount;
    }

    function setMinTokensSellForBuyBack(uint256 _amount) public onlyOwner {
        _minTokensBeforeSwap = _amount;
    }
    
    function emergencyContractEthRemoval(uint256 _amount, address payable _recipient) public onlyOwner {
        //@dev all contract ETH is considered ETH to be used for buybacks. 
        //If someone accidentally sends ETH to contract there might be a slight chance to refund their ETH as long as buy back has not executed
        uint256 _contractBalance = address(this).balance;
        require( _amount <= _contractBalance, "Can't remove more ETH than available ETH");
        
        _recipient.transfer(_amount);
    }
    
    function toggleAntiBot() external onlyOwner() {                               // Having a way to turn interaction with other contracts on/off is a good design practice
        _AntiBotEnabled = !_AntiBotEnabled;
    }    
    
    function toggleBuyAndBurn() external onlyOwner() {                               // Having a way to turn interaction with other contracts on/off is a good design practice
        _buyAndBurnEnabled = !_buyAndBurnEnabled;
    }
    
    function toggleSwapAndOpenTrade() external onlyOwner() {
        _SwapEnabled = !_SwapEnabled;
        _TradingOpened = !_TradingOpened;
    }
}