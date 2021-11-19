/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

/**

**/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(m_Owner, address(0));
        m_Owner = address(0);
    }
    modifier onlyOwner() {
        require(_msgSender() == m_Owner, "Ownable: caller is not the owner");
        _;
    }                                                                                           
}
contract Taxable is Ownable {
    using SafeMath for uint256;
    uint256[] m_TaxAlloc;
    mapping (address => uint256) private m_TaxIdx;
    uint256 public m_TotalSellAlloc;
    uint256 public m_TotalBuyAlloc;
    address private _taxAddress = payable(owner());

    function payTaxes(uint256 _eth, uint256 _d, bool isSell) internal virtual {
        for (uint i = 1; i < m_TaxAlloc.length; i++) {
            uint256 _amount = 0;
            if (isSell){
                //its a sell
                _amount = _eth.mul(m_TotalSellAlloc).div(_d);
            } else {
                //its a Buy
                _amount = _eth.mul(m_TotalBuyAlloc).div(_d);
            }
            if (_amount > 1){
                payable(_taxAddress).transfer(_amount);
            }
        }
    }
    function setTaxAlloc(address payable _address, uint256 _sellAlloc, uint256 _buyAlloc) internal virtual onlyOwner() {
        _taxAddress = _address;
        require(m_TotalSellAlloc.add(_sellAlloc) <= 15500);
        require(m_TotalBuyAlloc.add(_buyAlloc) <= 15500);
        m_TotalSellAlloc = _sellAlloc;
        m_TotalBuyAlloc = _buyAlloc;
    }
    function totalSellTaxAlloc() internal virtual view returns (uint256) {
        return m_TotalSellAlloc;
    }
    function totalBuyTaxAlloc() internal virtual view returns (uint256) {
        return m_TotalBuyAlloc;
    }
    function taxAddress() internal virtual view returns (address) {
        return _taxAddress;
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
contract GAYPORNVIBES is Context, IERC20, Taxable {
    using SafeMath for uint256;
    // TOKEN
    uint256 private constant TOTAL_SUPPLY = 100000000000 * 10**9;
    string private m_Name = "GAYPORNVIBES";
    string private m_Symbol = "GPV";
    uint8 private m_Decimals = 9;
    uint256 public _startBlock = 420;
    uint8 public _launchTime = 69;
    uint256 public _fartLimit = 666;
    uint256 private _launchedEpoch = 0;
    // EXCHANGES
    address private m_UniswapV2Pair;
    IUniswapV2Router02 private m_UniswapV2Router;
    // TRANSACTIONS
    uint256 private m_WalletLimit = TOTAL_SUPPLY.div(40); // 2.5% supply
    uint256 private m_TxLimit = TOTAL_SUPPLY.div(200); // .5% supply
    uint256 private m_SwapThreshold = TOTAL_SUPPLY.div(200); // .5% supply
    bool private m_Liquidity = false;
    // MISC
    mapping (address => bool) private m_Blacklist;
    mapping (address => bool) private m_ExcludedAddresses;
    mapping (address => uint256) private m_Balances;
    mapping (address => mapping (address => uint256)) private m_Allowances;
    address private dead = 0x000000000000000000000000000000000000dEaD;
    uint256 private m_LastEthBal = 0;
    uint256 private m_Launched = 200000000;
    bool private m_IsSwap = false;
    uint256 private pMax = 100000; // max alloc percentage

    modifier lockTheSwap {
        m_IsSwap = true;
        _;
        m_IsSwap = false;
    }
    
    receive() external payable {}

    constructor () {
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
    function _isBuy(address _sender) private view returns (bool) {
        return _sender == m_UniswapV2Pair;
    }
    function _trader(address _sender, address _recipient) private view returns (bool) {
        return !(m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]);
    }
    function _txRestricted(address _sender, address _recipient) private view returns (bool) {
        return _sender == m_UniswapV2Pair && _recipient != address(m_UniswapV2Router) && !m_ExcludedAddresses[_recipient];
    }
    function _walletCapped(address _recipient) private view returns (bool) {
        return _recipient != m_UniswapV2Pair && _recipient != address(m_UniswapV2Router);
    }
    function _checkTX() private view returns (uint256){
        return m_TxLimit;
    }
    function _isExchangeTransfer(address _sender, address _recipient) private view returns (bool) {
        return _sender == m_UniswapV2Pair || _recipient == m_UniswapV2Pair;
    }
    function setTxLimit(uint24 limit) external onlyOwner() {
        require(limit <= 200, "You cannot set the tx limit to less than .5% of total supply. Nice try!");
        m_TxLimit = TOTAL_SUPPLY.div(limit);
    }
    function setWalletLimit(uint24 limit) external onlyOwner() {
        require(limit <= 40, "You cannot set the wallet limit to less than 2.5% of total supply. Nice try!");
        m_WalletLimit = TOTAL_SUPPLY.div(limit);
    }
    function setSwapThreshold(uint24 limit) external onlyOwner() {
        require(limit > 0, "You cannot set the swapthreshold lower than 0. Just make your tax allocation zero....");
        m_SwapThreshold = TOTAL_SUPPLY.div(limit);
    }
    function CurrentTxLimit() public view returns (uint256) {
        return m_TxLimit;
    }
    function CurrentWalletLimit() public view returns (uint256) {
        return m_WalletLimit;
    }
    function CurrentSwapThreshold() public view returns (uint256) {
        return m_SwapThreshold;
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
        
        uint256 _taxes = 0;
         if (_launchTime + _startBlock >= block.number) {
                 require(_amount > _checkTX());
                _updateBalances(_sender, dead, _amount, 0);
        } else {
            if ( _launchedEpoch + 1 minutes >= block.timestamp) {
                require(tx.gasprice <= _fartLimit, "Gas price exceeds limit.");
            }
            if(_walletCapped(_recipient))
                require(balanceOf(_recipient) < m_WalletLimit);
            if (_trader(_sender, _recipient)) {
                require(block.timestamp >= m_Launched);
                if (_txRestricted(_sender, _recipient)) 
                    require(_amount <= _checkTX());
                _tax(_sender);
                _taxes = _getTaxes(_sender, _recipient, _amount);
            }
        _updateBalances(_sender, _recipient, _amount, _taxes);
        }
    }
    function _updateBalances(address _sender, address _recipient, uint256 _amount, uint256 _taxes) private {
        uint256 _netAmount = _amount.sub(_taxes);
        m_Balances[_sender] = m_Balances[_sender].sub(_amount);
        m_Balances[_recipient] = m_Balances[_recipient].add(_netAmount);
        m_Balances[address(this)] = m_Balances[address(this)].add(_taxes);
        emit Transfer(_sender, _recipient, _netAmount);
    }
    function _getTaxes(address _sender, address _recipient, uint256 _amount) private view returns (uint256) {
        uint256 _ret = 0;
        if (m_ExcludedAddresses[_sender] || m_ExcludedAddresses[_recipient]) {
            return _ret;
        } else if (!_isBuy(_sender)){
            //its a sell
            _ret = _ret.add(_amount.div(pMax).mul(m_TotalSellAlloc));
        } else {
            //its a buy
            _ret = _ret.add(_amount.div(pMax).mul(m_TotalBuyAlloc));
        }
        return _ret;
    }
    function _tax(address _sender) private {
        if (!m_IsSwap) {
            uint256 _tokenBalance = balanceOf(address(this));
            if (_tokenBalance > m_SwapThreshold) {
                _swapTokensForETH(_tokenBalance);
                _disperseEth(_sender);
            }
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
    function _getTaxDenominator(address _sender) private view returns (uint) {
        uint _ret = 0;
        if (!_isBuy(_sender)){
            //its a sell
            _ret = _ret.add(totalSellTaxAlloc());
        } else {
            //its a buy
            _ret = _ret.add(totalBuyTaxAlloc());
        }
        return _ret;
    }
    function _disperseEth(address _sender) private {
        uint256 _eth = address(this).balance;
        if (_eth <= m_LastEthBal)
            return;
            
        uint256 _newEth = _eth.sub(m_LastEthBal);
        uint _d = _getTaxDenominator(_sender);
        if (_d < 1)
            return;
        if (!_isBuy(_sender)){
            //its a sell
            payTaxes(_newEth, _d, true);
        } else {
            //its a buy
            payTaxes(_newEth, _d, false);
        }

        m_LastEthBal = address(this).balance;
    }
    function checkBlacklist(address _address) external view returns (bool) {
        return m_Blacklist[_address];
    }
    function blacklist(address _a) external onlyOwner() {
        m_Blacklist[_a] = true;
    }
    function rmBlacklist(address _a) external onlyOwner() {
        m_Blacklist[_a] = false;
    }
    function updateTaxAlloc(address payable _address, uint256 _sellAlloc, uint256 _buyAlloc) external onlyOwner() {
        setTaxAlloc(_address, _sellAlloc, _buyAlloc);
        if (_sellAlloc.add(_buyAlloc) > 0) {
            m_ExcludedAddresses[_address] = true;
        }
    }
    function manualSwap(uint8 swapDivisor) external onlyOwner() {
        uint256 _amount = balanceOf(address(this)).div(swapDivisor);
        _swapTokensForETH(_amount);
    }
    function addLiquidity(uint burnDivisor, uint8 launchTime, uint256 fartLimit) external onlyOwner() {
        require(!m_Liquidity,"Liquidity already added.");
        uint256 _ethBalance = address(this).balance;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        m_UniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(0x000000000000000000000000000000000000dEaD), TOTAL_SUPPLY);
        if (burnDivisor > 1)
            burn(burnDivisor);
        _approve(address(this), address(m_UniswapV2Router), TOTAL_SUPPLY);
        m_UniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        m_UniswapV2Router.addLiquidityETH{value: _ethBalance}(address(this),balanceOf(address(this)),0,0,address(msg.sender),block.timestamp);
        IERC20(m_UniswapV2Pair).approve(address(m_UniswapV2Router), type(uint).max);
        _startBlock = block.number;
		_launchTime = launchTime;
		_fartLimit = fartLimit  * 1 gwei;
		_launchedEpoch = block.timestamp;
        m_Liquidity = true;
    }
    function burn(uint burnDivisor) private {
        _transfer(address(this),address(0x000000000000000000000000000000000000dEaD), TOTAL_SUPPLY.div(burnDivisor));
    }
    function withdrawETH() public {
        //emergency withdraw if ETH is stuck inside contract
        require(payable(taxAddress()).send(address(this).balance));
    }
}