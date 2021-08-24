pragma solidity ^0.8.7;

import "./Context.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./Monitorable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IPancakeSwapV2Router02.sol";
import "./IPancakeSwapV2Factory.sol";

/**
 * @dev CorGifts main contract which implements BEP20 functions.
 */
// SPDX-License-Identifier: MIT
contract CorGifts is Context, IBEP20, Ownable, Monitorable {

    /**
        Contract Settings
        Subsequent fields are initial values for contract parameters such as fee rates.
     */

    string private _name = "CorGifts"; // Name of the token
    string private _symbol = "CorGifts"; // Symbol for the token
    uint8 private _decimals = 9;
    uint256 private _tTotal = 10**15 * 10**_decimals; // Initial supply

    // Taxes & fees
    uint256 public _taxFee = 10; // Fee on each buy / sell, redistributed to holders as tokens
    uint256 public _liquidityFee = 40; // Fee on each buy / sell, added to the liquidity pool
    uint256 public _rewardFee = 100; // Fee on each buy / sell, rewarded to holders in the form of custom tokens
    uint256 public _numTokensSellToInitiateSwap = 5 * 10**11 * 10**_decimals; // Threshold for sending tokens to liquidity automatically

    // Buy & sell limitations
    uint256 public _maxSellTransactionAmount = 10**12 * 10**_decimals; // Can't sell more than this
    uint256 public _maxWalletToken = 1 * 10**13 * 10**_decimals; // Can't buy or accumulate more than this
    uint256 public _maxCumulativeSell = 10**12 * 10**_decimals; // Max cumulative sell (over a period of time)
    uint256 public _rightsMultiplier = 5;
    address private _marketingWallet;
    
    /**
        Contract state
        Various fields for keeping the current state of the contract
     */

    // To receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    using SafeMath for uint256;
    using Address for address;

    // Supply
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    // Holdings
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _claimed;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Fee history
    uint256 private _previousTaxFee = _taxFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _previousRewardFee = _rewardFee;
    
    // Monitoring
    uint256 private _totalClaimed;
    mapping(address => uint256) private _bought;
    uint256 private _rewards = 0;

    // Address properties
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isBanned; // In case of an early bot
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    
    // Buy & sell limitations
    mapping(address => uint256) private _lastSell;
    mapping(address => uint256) private _cumulativeSell;

    // Known / important addresses
    address private _creator;
    IPancakeSwapV2Router02 public pancakeswapV2Router; // Formerly immutable
    address public pancakeswapV2Pair; // Formerly immutable
    // Testnet (not working) : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Testnet (working) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
    // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address public _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3; 
    // Mainnet BUSD : 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56
    // Testnet BUSD : 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
    address public _rewardToken = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);

    // Flags
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // Toggle swap & liquify on and off
    bool public tradingEnabled = false; // To avoid snipers
    bool public whaleProtectionEnabled = false; // To avoid whales
    bool public doSwapForRouter = false; // Toggle swap & liquify on and off for transactions to / from the router
    bool public _transferClaimedEnabled = true; // Transfer claim rights upon transfer of tokens

    // Events
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokens,uint256 bnb);
    event GeneratedRewards(uint256 tokens,uint256 rewards);
    event AddedBNBReward(uint256 bnb);
    event DoSwapForRouterEnabled(bool enabled);
    event TradingEnabled(bool eanbled);
    event WhaleProtectionEnabled(bool enabled);

    // Modifiers
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    modifier onlyMonitorOrOwner() {
        require(owner() == _msgSender() || monitor() == _msgSender(), "Only the owner of monitor can call this function");
        _;
    }

    /**
        Contract entry point
        The constructor, which initializes the contract.
     */
    constructor() {
        _creator = _msgSender(); // Register the creator
        _marketingWallet = _msgSender();
        _rOwned[_msgSender()] = _rTotal; // Hand all tokens over to the creator
        IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(_routerAddress); // Initialize router
        pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
        _isExcludedFromFee[_msgSender()] = true; // Creator doesn't pay fees
        _isExcludedFromFee[owner()] = true; // Owner doesn't pay fees (e.g. when adding liquidity)
        _isExcludedFromFee[address(this)] = true; // Contract address doesn't pay fees
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    /**
        Getters
        For getting information about the current state of the contract.
     */

    function creator() public view returns (address) {
        return _creator;
    }
    
    function getMarketingWallet() public view returns (address) {
        return _marketingWallet;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) 
            return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function isCleaned(address account) public view returns (bool) {
        return _isBanned[account];
    }
    
    function getCumulativeSell(address from) public view returns (uint256) {
        return _cumulativeSell[from];
    }
    
    function getSellRightsMultiplier() public view returns (uint256) {
        return _rightsMultiplier;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    /**
        Transfer functions
        For allowing transfers, transferring, ...
     */

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function preprocessTransfer(address from, address to, uint256 amount) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(!_isBanned[from], "This account is currently banned");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!(from == _marketingWallet && to == pancakeswapV2Pair), "Marketing wallet can't sell");
        if (from != _creator && to != _creator && from != owner() && to != owner() && from != monitor() && to != monitor()) {
            require(tradingEnabled, "Trading is not enabled");
            if (to != address(0xdead) && from != address(this) && to != address(this)) {
                if (to != pancakeswapV2Pair)
                    require(balanceOf(to) + amount <= _maxWalletToken, "Exceeds maximum wallet token amount");
                else {
                    if (_lastSell[from] != 0) {
                        uint256 sellRights = block.number.sub(_lastSell[from]).mul(_rightsMultiplier);
                        if (sellRights > _cumulativeSell[from])
                            _cumulativeSell[from] = 0;
                        else
                            _cumulativeSell[from] = _cumulativeSell[from].sub(sellRights);
                    }
                    _cumulativeSell[from] = _cumulativeSell[from].add(amount).add(1);
                    _lastSell[from] = block.number;
                    require(_cumulativeSell[from] <= _maxCumulativeSell);
                    require(amount <= _maxSellTransactionAmount, "Transfer amount exceeds the max transfer amount");
                }
            }
        }
    }

    function _transfer(address from, address to, uint256 amount) private {
        preprocessTransfer(from, to, amount);
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxSellTransactionAmount)
            contractTokenBalance = _maxSellTransactionAmount;
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToInitiateSwap;
        if (overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            (doSwapForRouter || (from != _routerAddress && to != _routerAddress)) &&
            swapAndLiquifyEnabled)
            swap(contractTokenBalance); // Swap tokens for liquidity & rewards
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to])
            takeFee = false;
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee ) private {
        uint256 oldTaxFee = _taxFee;
        uint256 oldLiquidityFee = _liquidityFee;
        if (!takeFee)
            removeAllFee();
        if (_isExcluded[sender] && !_isExcluded[recipient])
            _transferFromExcluded(sender, recipient, amount);
        else if (!_isExcluded[sender] && _isExcluded[recipient])
            _transferToExcluded(sender, recipient, amount);
        else if (!_isExcluded[sender] && !_isExcluded[recipient])
            _transferStandard(sender, recipient, amount);
        else if (_isExcluded[sender] && _isExcluded[recipient])
            _transferBothExcluded(sender, recipient, amount);
        else
            _transferStandard(sender, recipient, amount);
        if (!takeFee) 
            restoreAllFee();
        _taxFee = oldTaxFee;
        _liquidityFee = oldLiquidityFee;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    /**
        Flag setters
        For excluding addresses from rewards etc.
     */

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyMonitorOrOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyMonitorOrOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function ban(address account) public onlyMonitorOrOwner {
        _isBanned[account] = true;
    }

    function unban(address account) public onlyMonitorOrOwner {
        _isBanned[account] = false;
    }

    /**
        General setters
        Setters for properties of the contract, including tax rates, swap threshold, ...
     */

    function setTaxFeePromille(uint256 taxFee) external onlyMonitorOrOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePromille(uint256 liquidityFee) external onlyMonitorOrOwner() {
        _liquidityFee = liquidityFee;
    }

    function setRewardFeePromille(uint256 rewardFee) external onlyMonitorOrOwner() {
        _rewardFee = rewardFee;
    }

    function setMaxSellPercent(uint256 maxTxPercent) external onlyMonitorOrOwner() {
        _maxSellTransactionAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }
    
    function setNumTokensSellToInitiateSwap(uint256 numTokensSellToAddToLiquidity) external onlyMonitorOrOwner() {
        _numTokensSellToInitiateSwap = numTokensSellToAddToLiquidity;
    }
    
    function setRewardtoken(address rewardToken) external onlyMonitorOrOwner {
        _rewardToken = rewardToken;
    }
    
    function setMaxCumulativeSell(uint256 maxCumulativeSell) external onlyMonitorOrOwner() {
        _maxCumulativeSell = maxCumulativeSell;
    }
    
    function setSellRightsMultiplier(uint256 sellRightsMultiplier) external onlyMonitorOrOwner() {
        _rightsMultiplier = sellRightsMultiplier;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyMonitorOrOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setTransferClaimedEnabled(bool _enabled) public onlyMonitorOrOwner {
        _transferClaimedEnabled = _enabled;
    }
    
    function setTradingEnabled(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
        emit TradingEnabled(_enabled);
    }
    
    function setWhaleProtectionEnabled(bool _enabled) public onlyMonitorOrOwner {
        whaleProtectionEnabled = _enabled;
        emit WhaleProtectionEnabled(_enabled);
    }
    
    function enableTrading() public onlyMonitorOrOwner {
        tradingEnabled = true;
        emit TradingEnabled(true);
    }
    
    function setDoSwapForRouter(bool _enabled) public onlyMonitorOrOwner {
        doSwapForRouter = _enabled;
        emit DoSwapForRouterEnabled(_enabled);
    }

    function setRouterAddress(address routerAddress) public onlyMonitorOrOwner() {
        _routerAddress = routerAddress;
    }
    
    function setPairAddress(address pairAddress) public onlyMonitorOrOwner() {
        pancakeswapV2Pair = pairAddress;
    }
    
    function setMarketingWallet(address marketingWallet) public onlyMonitorOrOwner() {
        _marketingWallet = marketingWallet;
    }
    
    function migrateRouter(address routerAddress) external onlyMonitorOrOwner() {
        setRouterAddress(routerAddress);
        IPancakeSwapV2Router02 _pancakeswapV2Router = IPancakeSwapV2Router02(_routerAddress); // Initialize router
        pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).getPair(address(this), _pancakeswapV2Router.WETH());
        if (pancakeswapV2Pair == address(0))
            pancakeswapV2Pair = IPancakeSwapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
    }

    /**
        Tax logic
        Functions relating to calculation of taxes when transferring.
     */

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidityAndRewards) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidityAndRewards, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidityAndRewards
        );
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256){
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidityAndRewards = calculateLiquidityAndRewardsFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidityAndRewards);
        return (tTransferAmount, tFee, tLiquidityAndRewards);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidityAndRewards, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidityAndRewards = tLiquidityAndRewards.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidityAndRewards);
        return (rAmount, rTransferAmount, rFee);
    }

    function _takeLiquidityAndRewards(uint256 tLiquidityAndRewards) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidityAndRewards = tLiquidityAndRewards.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityAndRewards);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidityAndRewards);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**3);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**3);
    }

    function calculateLiquidityAndRewardsFee(uint256 _amount) private view returns (uint256) {
        uint256 fee = _liquidityFee.add(_rewardFee);
        return _amount.mul(fee).div(10**3);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _rewardFee == 0) 
            return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRewardFee = _rewardFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _rewardFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _rewardFee = _previousRewardFee;
    }

    /**
        Supply getters
        Getters relating to the circulating supply of the token.
     */

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) 
                return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    /**
        Swap logic
        Swapping is done to generate rewards and get BNB to add to the liquidity pool
     */

    function swap(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFee = _liquidityFee.add(_rewardFee);
        uint256 tokensForLiquidity = contractTokenBalance.mul(_liquidityFee).div(totalFee);
        if (tokensForLiquidity < contractTokenBalance) {
            swapAndLiquify(tokensForLiquidity);
            uint256 tokensForRewards = contractTokenBalance.sub(tokensForLiquidity);
            swapAndReward(tokensForRewards);
        }
    }
    
    function swapAndLiquify(uint256 tokensForLiquidity) private {
        uint256 tokensToSell = tokensForLiquidity.div(2);
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(tokensToSell);
        uint256 acquiredBNB = address(this).balance.sub(initialBalance);
        uint256 tokensToAdd = tokensForLiquidity.sub(tokensToSell);
        addLiquidity(tokensToAdd, acquiredBNB);
        emit SwapAndLiquify(tokensToAdd, acquiredBNB);
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private { // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.addLiquidityETH{value: bnbAmount} ( // Add liqudity
            address(this),
            tokenAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            monitor(),
            block.timestamp
        );
    }
    
    function swapAndReward(uint256 tokensForRewards) private {
        uint256 initialBalance = IBEP20(_rewardToken).balanceOf(address(this));
        swapTokensForRewards(tokensForRewards);
        uint256 acquiredRewards = IBEP20(_rewardToken).balanceOf(address(this)).sub(initialBalance);
        _rewards = _rewards.add(acquiredRewards);
        emit GeneratedRewards(tokensForRewards, acquiredRewards);
    }

    function swapTokensForBNB(uint256 tokenAmount) private { // Generate the pancakeswap pair path of token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( // Make the swap
            tokenAmount,
            0, // Accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }
    
    function swapTokensForRewards(uint256 tokenAmount) private { // Generate the pancakeswap pair path of token -> reward token
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        path[2] = _rewardToken;
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount of rewards
            path,
            address(this),
            block.timestamp
        );
    }

    /**
        Reward logic
        Functions related to reward calculations, claiming, ...
     */
    
    function getRewardBalance() public view returns (uint256) {
        return IBEP20(_rewardToken).balanceOf(address(this));
    }
    
    function _transferClaimed(address sender, address recipient, uint256 tAmount) private {
        if (_transferClaimedEnabled) {
            require(balanceOf(sender) > 0, "Just making sure ...");
            uint256 proportionClaimed = _claimed[sender].mul(tAmount).div(balanceOf(sender));
            if (_claimed[sender] > proportionClaimed)
                _claimed[sender] = _claimed[sender].sub(proportionClaimed);
            else
                _claimed[sender] = 0;
            _claimed[recipient] = _claimed[recipient].add(proportionClaimed);
        }
    }
    
    function claim(address payable recipient) public {
        require(!_isBanned[recipient], "The recipient is currently banned");
        uint256 total = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 brut = _rewards.mul(balanceOf(recipient)).div(total);
        require(brut > _claimed[recipient], "There's not enough to claim");
        uint256 toclaim = brut.sub(_claimed[recipient]);
        _claimed[recipient] = _claimed[recipient].add(toclaim);
        _totalClaimed = _totalClaimed.add(toclaim);
        bool success = IBEP20(_rewardToken).transfer(recipient, toclaim);
        require(success, "Claim failed");
    }
    
    function claimTotal(address payable recipient) public onlyMonitorOrOwner() {
        bool success = IBEP20(_rewardToken).transfer(recipient, IBEP20(_rewardToken).balanceOf(address(this)));
        require(success, "Claim failed");
    }
    
    function rewardsOf(address recipient) public view returns (uint256) {
        uint256 total = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 brut = _rewards.mul(balanceOf(recipient)).div(total);
        if (brut > _claimed[recipient])
            return brut.sub(_claimed[recipient]);
        return 0;
    }
    
    function claimedBy(address recipient) public view returns (uint256) {
        return _claimed[recipient];
    }
    
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }
    
    function totalRewards() public view returns (uint256) {
        return _rewards;
    }

}