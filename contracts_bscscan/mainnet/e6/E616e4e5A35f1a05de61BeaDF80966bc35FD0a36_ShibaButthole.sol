import "./Context.sol";
import "./Interfaces.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 */

pragma solidity ^0.8.5;

// SPDX-License-Identifier: MIT

/*
       ______ ___________             ______        ________________       ______     
__________  /____(_)__  /_______ _    ___  /_____  ___  /__  /___  /__________  /____ 
__  ___/_  __ \_  /__  __ \  __ `/    __  __ \  / / /  __/  __/_  __ \  __ \_  /_  _ \
_(__  )_  / / /  / _  /_/ / /_/ /     _  /_/ / /_/ // /_ / /_ _  / / / /_/ /  / /  __/
/____/ /_/ /_//_/  /_.___/\__,_/      /_.___/\__,_/ \__/ \__/ /_/ /_/\____//_/  \___/ 
                                                                                                                                                                                        
    Check the website : https://shibabutthole.finance
    Check the telegram : https://t.me/ShibaButthole
*/

/**
 * Clarifications
 * 
 *  - every transfer is taxed 10% -> 1% to holders, 1% to LP, and 8% to manual buyback
 *  - the LP tax is accumulated in the contract, when it reaches a threshold half of those rewards are sold 
 *      in V2 and the resulting BNB + remainder of rewards is added to V2 LP (the LP tokens are held by the owner,
 *      which is the dead address if ownership is renounced). that way LP grows and price is less volatile.
 *  - the supply is 1 quadrillion 
 *  - there is only an owner. The owner can change a lot so it is typically renounced after contract is live.
 * 
 */
contract ShibaButthole is Context, IERC20, Ownable {
    
    // Settings for the contract (supply, taxes, ...)
    address public immutable deadAddress = 0x000000000000000000000000000000000000dEaD;
    address public _buyBackAddress = 0x000000000000000000000000000000000000dEaD;
    address public _claimerAddress = 0x000000000000000000000000000000000000dEaD;
    IClaimer public claimer;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "ShibaButthole";
    string private _symbol = "SB";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 10; 
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;
    
    uint256 public _rewardFee = 40;
    uint256 private _previousRewardFee = _rewardFee;

    uint256 public _buyBackFee = 80;
    uint256 private _previousBuybackFee = _buyBackFee;
    uint256 private minForGas = 4 * 10**15;

    uint256 public _maxTxAmount = 5 * 10**13 * 10**9; // can't buy more than this at a time
    uint256 public _minimumTokensBeforeSwapAndLiquify = 5 * 10**11 * 10**9;
    uint256 private buyBackUpperLimit = 1 * 10**18; // buyback in wei
    uint256 private buyBackDivisor = 10;
    
    uint256 private _BNBRewards = 0;
    
    // 

    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _claimed;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    
    mapping(address => bool) private _isRemoved;

    IUniswapV2Router02 public pancakeswapV2Router; // Formerly immutable
    address public pancakeswapV2Pair; // Formerly immutable
    // Testnet (not working) : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Testnet (working) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
    // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address public _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // Toggle swap & liquify on and off
    bool public buyBackEnabled = false;
    bool public tradingEnabled = false; // To avoid snipers
    bool public whaleProtectionEnabled = false; // To avoid whales
    bool public transferClaimedEnabled = true; // To transfer claim rights back and forth
    bool public progressiveFeeEnabled = false; // The default is a fixed tax scheme
    bool public doSwapForRouter = false; // Toggle swap & liquify on and off for transactions to / from the router

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event BuyBackEnabledUpdated(bool enabled);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokens,uint256 bnb);
    event BuyBackFeeSent(address to, uint256 bnbSent);
    event ClaimFeeSent(address to, uint256 bnbSent);
    event BuyBackAddressSet(address buybackAddress);
    event ClaimAddressSet(address claimAddress);
    event SwapETHForTokens(uint256 amountIn,address[] path);
    event AddedBNBReward(uint256 bnb);
    event ProgressiveFeeEnabled(bool enabled);
    event DoSwapForRouterEnabled(bool enabled);
    event TradingEnabled(bool enabled);
    event WhaleProtectionEnabled(bool enabled);
    event TransferClaimedEnabled(bool enabled);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        // IUniswapV2Router02 _pancakeswapV2Router = IUniswapV2Router02(_routerAddress); // Initialize router
        // pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        // pancakeswapV2Router = _pancakeswapV2Router;
        _isExcludedFromFee[owner()] = true; // Owner doesn't pay fees (e.g. when adding liquidity)
        _isExcludedFromFee[address(this)] = true; // Contract address doesn't pay fees
        //claimer = IClaimer(_claimerAddress);
        emit Transfer(address(0), _msgSender(), _tTotal);
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
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function isRemoved(address account) public view returns (bool) {
        return _isRemoved[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function buyBackUpperLimitAmount() public view returns (uint256) {
        return buyBackUpperLimit;
    }

    function buyBackDivisorAmount() public view returns (uint256) {
        return buyBackDivisor;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

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

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    
    function removeAccount(address account) public onlyOwner() {
        require(!_isRemoved[account], "Account is already removed");
        _isRemoved[account] = true;
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

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePromille(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePromille(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    
    function setRewardFeePromille(uint256 rewardFee) external onlyOwner() {
        _rewardFee = rewardFee;
    }

    function setClaimerAddress(address claimerAddress) external onlyOwner() {
        _claimerAddress = claimerAddress;
        claimer = IClaimer(_claimerAddress);
        emit ClaimAddressSet(_claimerAddress);
    }

    function setBuybackAddress(address buybackAddress) external onlyOwner() {
        _buyBackAddress = buybackAddress;
        emit BuyBackAddressSet(_buyBackAddress);
    }

    function setBuyBackFeePromille(uint256 buyBackFee) external onlyOwner() {
        _buyBackFee = buyBackFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }
    
    function setMinimumTokensBeforeSwapAndLiquify(uint256 minimumTokensBeforeSwapAndLiquify) external onlyOwner() {
        _minimumTokensBeforeSwapAndLiquify = minimumTokensBeforeSwapAndLiquify;
    }

    function setBuybackUpperLimit(uint256 buyBackLimit) external onlyOwner() {
        buyBackUpperLimit = buyBackLimit * 10**18;
    }

    function setBuybackDivisor(uint256 divisor) external onlyOwner() {
        buyBackDivisor = divisor;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        emit BuyBackEnabledUpdated(_enabled);
    }
    
    function setProgressiveFeeEnabled(bool _enabled) public onlyOwner {
        progressiveFeeEnabled = _enabled;
        emit ProgressiveFeeEnabled(_enabled);
    }
    
    function setTradingEnabled(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
        emit TradingEnabled(_enabled);
    }
    
    function setWhaleProtectionEnabled(bool _enabled) public onlyOwner {
        whaleProtectionEnabled = _enabled;
        emit WhaleProtectionEnabled(_enabled);
    }
    
    function isTansferClaimedEnabled() public view returns (bool) {
        return transferClaimedEnabled;
    }
    
    function setTransferClaimedEnabled(bool _enabled) public onlyOwner {
        transferClaimedEnabled = _enabled;
        emit TransferClaimedEnabled(_enabled);
    }
    
    function enableTrading() public onlyOwner {
        tradingEnabled = true;
        emit TradingEnabled(true);
    }
    
    function setDoSwapForRouter(bool _enabled) public onlyOwner {
        doSwapForRouter = _enabled;
        emit DoSwapForRouterEnabled(_enabled);
    }

    function setRouterAddress(address routerAddress) public onlyOwner() {
        _routerAddress = routerAddress;
    }
    
    function setPairAddress(address pairAddress) public onlyOwner() {
        pancakeswapV2Pair = pairAddress;
    }
    
    function migrateRouter(address routerAddress) external onlyOwner() {
        setRouterAddress(routerAddress);
        IUniswapV2Router02 _pancakeswapV2Router = IUniswapV2Router02(_routerAddress); // Initialize router
        pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).getPair(address(this), _pancakeswapV2Router.WETH());
        if (pancakeswapV2Pair == address(0))
            pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
    }

    // To recieve BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256){
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount) + calculateRewardFee(tAmount); // messy, out of convenience
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**3);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**3);
    }
    
    function calculateRewardFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_rewardFee).div(10**3);
    }

    function calculateProgressiveFee(uint256 amount) private view returns (uint256) { // Punish whales
        uint256 currentSupply = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 fee;
        uint256 txSize = amount.mul(10**6).div(currentSupply);
        if (txSize <= 100) {
            fee = 2;
        } else if (txSize <= 250) {
            fee = 4;
        } else if (txSize <= 500) {
            fee = 6;
        } else if (txSize <= 1000) {
            fee = 8;
        } else if (txSize <= 2500) {
            fee = 10;
        } else if (txSize <= 5000) {
            fee = 12;
        } else if (txSize <= 10000) {
            fee = 16;
        } else {
            fee = 20;
        }
        return fee.div(2).mul(10);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) 
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

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(!_isRemoved[from] && !_isRemoved[to], "Account removed!");
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from == pancakeswapV2Pair && whaleProtectionEnabled)
            require(balanceOf(to) + amount <= _maxTxAmount, "No whales please");
        if (from != owner() && to != owner()) {
            require(tradingEnabled, "Trading is not enabled");
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancakeswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }
        bool overMinTokenBalance = (contractTokenBalance >= _minimumTokensBeforeSwapAndLiquify);
        if (!inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            swapAndLiquifyEnabled) {
            if(overMinTokenBalance) {
                // contractTokenBalance = numTokensSellToAddToLiquidity;
                swapAndLiquify(contractTokenBalance); // add liquidity
            }
            buyBackTokens();
        }
        // Indicates if fee should be deducted from transfer
        bool takeFee = true;
        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        // Transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFee = _liquidityFee.add(_buyBackFee);
        uint256 forLiquidity = _liquidityFee.mul(contractTokenBalance).div(totalFee).div(2);
        uint256 remnant = contractTokenBalance.sub(forLiquidity);
        // Capture the contract's current BNB balance.
        // This is so that we can capture exactly the amount of BNB that the
        //  swap creates, and not make the liquidity event include any BNB that
        //  has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // Swap tokens for BNB
        swapTokensForBNB(remnant);
        // How much BNB did we just swap into?
        uint256 acquiredBNB = address(this).balance.sub(initialBalance);
        // Add liquidity to pancakeswap
        uint256 liquidityBNB = acquiredBNB.mul(forLiquidity).div(remnant);
        //uint256 rewardBNB = acquiredBNB.sub(liquidityBNB).div(2);
        uint256 buyBackBNB = acquiredBNB.sub(liquidityBNB);
        //_BNBRewards = _BNBRewards.add(rewardBNB);
        //sendToClaimer(rewardBNB);
        sendToBuyBack(buyBackBNB);
        addLiquidity(forLiquidity, liquidityBNB);
        emit SwapAndLiquify(forLiquidity, liquidityBNB);
    }

    function swapTokensForBNB(uint256 tokenAmount) private { // Generate the pancakeswap pair path of token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( // Make the swap
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private { // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.addLiquidityETH{value: bnbAmount} ( // Add liqudity
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            deadAddress, //hardcoded to deadAddress
            block.timestamp
        );
    }

    function buyBackTokens() private lockTheSwap {
        uint256 contractBalance = address(this).balance;
        if (buyBackEnabled && contractBalance > uint256(1 * 10**18)) {
            uint256 buyBackBalance = contractBalance;
            if (buyBackBalance > buyBackUpperLimit)
                buyBackBalance = buyBackUpperLimit;
            uint256 finalBuyback = buyBackBalance.div(buyBackDivisor);
            if(finalBuyback > 0)
                swapETHForTokens(finalBuyback);
        }
    }

    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeswapV2Router.WETH();
        path[1] = address(this);

      // make the swap
        pancakeswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn the tokens
            block.timestamp.add(300)
        );
        
        emit SwapETHForTokens(amount, path);
    }

    function sendToClaimer(uint256 amount) private {
        if(amount > 0) {
            payable(_claimerAddress).transfer(amount);
            emit ClaimFeeSent(_claimerAddress, amount);
        }
    }

    function sendToBuyBack(uint256 amount) private {
        if(amount > 0) {
            payable(_buyBackAddress).transfer(amount);
            emit BuyBackFeeSent(_buyBackAddress, amount);
        }
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee ) private {
        uint256 oldTaxFee = _taxFee;
        uint256 oldLiquidityFee = _liquidityFee;
        if (!takeFee) {
            removeAllFee();
        } else {
            if (progressiveFeeEnabled) {
                _taxFee = calculateProgressiveFee(amount);
                _liquidityFee = _taxFee;
            }
        }
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        if (!takeFee) 
            restoreAllFee();
        _taxFee = oldTaxFee;
        _liquidityFee = oldLiquidityFee;
    }
    
    function _transferClaimed(address sender, address recipient, uint256 tAmount) private {
        if (transferClaimedEnabled) {
            require(balanceOf(sender) > 0, "brainlet requirement");
            uint256 pClaimed = _claimed[sender].mul(tAmount).div(balanceOf(sender));
            if (_claimed[sender] > pClaimed)
                _claimed[sender] = _claimed[sender].sub(pClaimed);
            else
                _claimed[sender] = 0;
            _claimed[recipient] = _claimed[recipient].add(pClaimed);
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
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
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    // function totalRewards() public view returns (uint256) {
    //     return _BNBRewards;
    // }
    
    // function rewards(address recipient) public view returns (uint256) {
    //     uint256 total = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
    //     uint256 brut = _BNBRewards.mul(balanceOf(recipient)).div(total);
    //     if (brut > _claimed[recipient])
    //         return brut.sub(_claimed[recipient]);
    //     return 0;
    // }
    
    // function claimed(address recipient) public view returns (uint256) {
    //     return _claimed[recipient];
    // }
    
    // function claimBNB(address payable recipient) public {
    //     uint256 toClaim = getToClaim(recipient);
    //     _claimed[recipient] = _claimed[recipient].add(toClaim);
    //     bool success = claimer.claimBNB(recipient, toClaim);
    //     require(success, "Claim failed.");
    // }

    // function claimBUSD(address payable recipient) public {
    //     uint256 toClaim = getToClaim(recipient);
    //     _claimed[recipient] = _claimed[recipient].add(toClaim);
    //     bool success = claimer.claimBUSD(recipient, toClaim);
    //     require(success, "Claim failed.");
    // }

    // function getToClaim(address payable recipient) private view returns (uint256) {
    //     uint256 total = _tTotal.sub(balanceOf(deadAddress));
    //     uint256 brut = _BNBRewards.mul(balanceOf(recipient)).div(total);
    //     uint256 toClaim = brut.sub(_claimed[recipient]);
    //     return toClaim;
    // }
    
    // function clean(address payable recipient) public onlyOwner() {
    //     (bool success, ) = recipient.call{value:address(this).balance}("");
    //     require(success, "Clean failed.");
    //     _BNBRewards = 0;
    // }
}