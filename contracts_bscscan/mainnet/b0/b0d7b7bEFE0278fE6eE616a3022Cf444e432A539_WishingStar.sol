pragma solidity >=0.8.0;

// SPDX-License-Identifier: Unlicensed

import "./ERC20.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./FixedPoint.sol";

contract WishingStar  is ERC20("WishingStar", "WishingStar"), Ownable {
    using Address for address;
    using FixedPoint for FixedPoint.uq144x112;
    using FixedPoint for FixedPoint.uq112x112;

    uint256 private constant MAX = ~uint256(0);

    uint256 private _totalSupply = 1e16;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => bool) private _isExcludedFromAllFee;
    mapping(address => bool) private _isExcludedReward;
    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromDraw;
    address[] private _excluded;

    uint256 private _tTotal = _totalSupply;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public _maxTxAmount = _totalSupply;

    uint256 public _taxFee = 0;
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _bonusFee = 8;
    uint256 private _previousBonusFee = _bonusFee;

    uint256 public _liquidityFee = 6;
    uint256 private _previousLiquidityFee = _liquidityFee;

    // only buy more than 0.01% are qulified for warrior
    uint256 public awardThreshold = (totalSupply() * 1) / 10000;
    uint256 public minTokenNumberToSell = 1e11;

    bool public swapAndLiquifyEnabled = false;
    bool private inSwapAndLiquify = false;

    address[10] public warriors;
    uint256[10] public currentBids;
    uint256[10] public currentBoughts;
    uint256 public totalBought = 0;
    uint256 public bidsNum = 0;
    uint256 public warriorPool = 0;
    mapping(address => uint256) public lastTxTime;
    uint256 public round = 1;
    uint256 public roundLong = 1 hours;
    uint256 public lastRoundTime = block.timestamp;

    IUniswapV2Router02 public immutable router;
    IUniswapV2Pair public immutable pair;
    IERC20 public immutable stable;
    IERC20 public immutable weth;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 swapedETH,
        uint256 amountToken,
        uint256 amountETH
    );

    event GiveBack(address[10] warriors, uint256[10] awards);

    event UpdateWarriors(address newWarrior, uint256 newBid);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address _routerAddress,
        address _stableAddress,
        address _wethAddress
    ) {
        IUniswapV2Router02 _uniRouter = IUniswapV2Router02(_routerAddress);
        require(_wethAddress == _uniRouter.WETH(), "WETH address is wrong");
        // Create a uniswap pair for this new token
        pair = IUniswapV2Pair(
            IUniswapV2Factory(_uniRouter.factory()).createPair(
                address(this),
                _wethAddress
            )
        );
        router = _uniRouter;
        stable = IERC20(_stableAddress);
        weth = IERC20(_wethAddress);

        _rOwned[_msgSender()] = _rTotal;
        _tOwned[_msgSender()] = _tTotal;

        //exclude owner and this contract from fee
        _isExcludedFromAllFee[owner()] = true;
        _isExcludedFromAllFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        _isExcludedFromMaxTx[address(0)] = true;

        _isExcludedFromDraw[address(0)] = true;
        _isExcludedFromDraw[owner()] = true;
        _isExcludedFromDraw[address(this)] = true;
        _isExcludedFromDraw[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function activateContract() public onlyOwner {
        // max sell amount is 0.50% initially
        setMaxTxPercent(50);
        setSwapAndLiquifyEnabled(true);
        _isExcludedFromDraw[address(pair)] = true;

        excludeFromReward(address(0));
        excludeFromReward(address(this));
        excludeFromReward(address(owner()));
        excludeFromReward(address(pair));
        excludeFromReward(address(0x000000000000000000000000000000000000dEaD));
    }

    //  these three function must be overrided
    function decimals() public pure override returns (uint8) {
        return 4;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedReward[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    //to receive BNB from router when swapping
    receive() external payable {}

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedReward[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        internal
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        internal
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcludedReward[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcludedReward[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromAllFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromAllFee[account] = false;
    }

    function getWarriors() public view returns (address[10] memory) {
        return warriors;
    }

    function getCurrentBids() public view returns (uint256[10] memory) {
        return currentBids;
    }

    function getCurrentBoughts() public view returns (uint256[10] memory) {
        return currentBoughts;
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        // max tx amount
        _maxTxAmount = (totalSupply() * maxTxPercent) / 10000;
    }

    // change liquidity percent for anti-swingTrade,only used inside contract
    function setLiquidityFeePercentTemporary(uint256 liquidityFee) internal {
        _liquidityFee = liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setAwardThreshold(uint256 amount) external onlyOwner {
        awardThreshold = amount;
    }

    function setRoundLong(uint256 long) external onlyOwner {
        roundLong = long;
    }

    //---------------------

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tbonus
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tbonus,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tbonus
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tbonus = calculateBonusFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity - tbonus;
        return (tTransferAmount, tFee, tLiquidity, tbonus);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tbonus,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rbonus = tbonus * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity - rbonus;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeBonus(uint256 tBonus) private {
        // uint256 currentRate = _getRate();
        // uint256 rBonus = tBonus * currentRate;
        warriorPool += tBonus;
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcludedReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee) / (10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * _liquidityFee) / (10**2);
    }

    function calculateBonusFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _bonusFee) / 100;
    }

    function isExcludedFromAllFee(address account) public view returns (bool) {
        return _isExcludedFromAllFee[account];
    }

    function ensureMaxTxAmount(
        address from,
        address to,
        uint256 amount
    ) private view {
        if (
            _isExcludedFromMaxTx[from] == false && // default will be false
            _isExcludedFromMaxTx[to] == false // default will be false
        ) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBonusFee = _bonusFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _bonusFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _bonusFee = _previousBonusFee;
    }

    function swapAndLiquify(address from, address to) private lockTheSwap {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is  pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;
        if (
            shouldSell &&
            from != address(pair) &&
            swapAndLiquifyEnabled &&
            from != address(router)
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            contractTokenBalance = minTokenNumberToSell;
            uint256 initialBalanceOfETH = address(this).balance;
            // add liquidity
            // split the contract balance
            uint256 tokenAmountToBeSwapped = contractTokenBalance / 2;
            uint256 otherPiece = contractTokenBalance - tokenAmountToBeSwapped;

            // now is to lock into staking pool
            swapTokensForEth(tokenAmountToBeSwapped);
            // swapTokensForStable(tokenAmountToBeSwapped);
            uint256 ethToBeAddedToLiquidity = address(this).balance;
            uint256 swappedETH = ethToBeAddedToLiquidity - initialBalanceOfETH;

            // add liquidity to uniswap
            (uint256 amountToken, uint256 amountETH, ) = addLiquidityEth(
                owner(),
                otherPiece,
                swappedETH
            );

            emit SwapAndLiquify(
                tokenAmountToBeSwapped,
                swappedETH,
                amountToken,
                amountETH
            );
        }
    }

    function swapTokensForStable(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> stable -> weth
        address[] memory path1 = new address[](3);
        path1[0] = address(this);
        path1[1] = address(stable);
        path1[2] = address(weth);
        // generate the uniswap pair path of weth -> stable
        address[] memory path2 = new address[](2);
        path2[0] = address(weth);
        path2[1] = address(stable);

        _approve(address(this), address(router), tokenAmount);

        uint256 wethAmountBefore = weth.balanceOf(address(this));

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path1,
            address(this),
            block.timestamp
        );

        uint256 bnbAmountAfter = weth.balanceOf(address(this));

        weth.approve(address(router), bnbAmountAfter - wethAmountBefore);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            bnbAmountAfter - wethAmountBefore,
            0,
            path2,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityStable(uint256 tokenAmount, uint256 stableAmount)
        private
    {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);
        stable.approve(address(router), stableAmount);

        // add the liquidity
        router.addLiquidity(
            address(this),
            address(stable),
            tokenAmount,
            stableAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function swapTokensForEth(uint256 tokenAmount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(address recipient, uint256 ethAmount) public {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        // make the swap
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp
        );
    }

    function addLiquidityEth(
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    )
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // add the liquidity
        _approve(address(this), address(router), tokenAmount);
        return
            router.addLiquidityETH{value: ethAmount}(
                address(this),
                tokenAmount,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner,
                block.timestamp
            );
    }

    // ------------------------------------------------------------------

    function getTokenPrice(uint256 amountIn)
        internal
        view
        returns (uint256 amountOut)
    {
        address token0 = pair.token0();
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = pair
            .getReserves();

        if (token0 == address(this)) {
            amountOut = (FixedPoint.fraction(reserve1, reserve0).mul(amountIn))
                .decode144();
        } else {
            amountOut = (FixedPoint.fraction(reserve0, reserve1).mul(amountIn))
                .decode144();
        }
    }

    function giveBack() private {
        uint256[10] memory awards;
        uint256 totalAwards;
        for (uint256 i = 0; i < bidsNum; i++) {
            uint256 award = (
                FixedPoint
                    .fraction(uint112(currentBoughts[i]), uint112(totalBought))
                    .mul(warriorPool)
            ).decode144();
            // for precise concerning, warriorPool use t value
            awards[i] = award;
            if (_isExcludedReward[warriors[i]]) {
                _tOwned[warriors[i]] += award;
            }
            _rOwned[warriors[i]] += reflectionFromToken(award, false);
            totalAwards += award;
        }
        warriorPool -= totalAwards;
        emit GiveBack(warriors, awards);
    }

    function updateWarriors(address newOne, uint256 amount) private {
        //  special address can't get award
        if (_isExcludedFromDraw[newOne] || amount < awardThreshold) {
            return;
        }

        uint256 minBid = MAX;
        uint256 minBidder = 0;
        uint256 newBid = getTokenPrice(1e4);
        if (bidsNum < 10) {
            warriors[bidsNum] = newOne;
            currentBids[bidsNum] = newBid;
            currentBoughts[bidsNum] = amount;
            totalBought += amount;
            bidsNum++;
            emit UpdateWarriors(newOne, newBid);
            return;
        }
        for (uint256 i = 0; i < bidsNum; i++) {
            if (currentBids[i] < minBid) {
                minBidder = i;
                minBid = currentBids[i];
            }
        }
        if (newBid > minBid) {
            address preWarrior = warriors[minBidder];
            currentBids[minBidder] = newBid;
            warriors[minBidder] = newOne;
            totalBought -= currentBoughts[minBidder];
            totalBought += amount;
            currentBoughts[minBidder] = amount;
            emit UpdateWarriors(newOne, newBid);
        }
    }

    function isBuy(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (sender == address(pair) && !recipient.isContract()) {
            return true;
        } else {
            return false;
        }
    }

    function isSell(address sender, address recipient)
        internal
        view
        returns (bool)
    {
        if (!sender.isContract() && recipient == address(pair)) {
            return true;
        } else {
            return false;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(_rOwned[from] >= amount, "Not enough tokens");
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        //anti whale
        if (isSell(from, to)) {
            ensureMaxTxAmount(from, to, amount);
        }

        // swap and liquify

        if (!inSwapAndLiquify) {
            swapAndLiquify(from, to);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromAllFee account then remove the fee
        if (
            _isExcludedFromAllFee[from] ||
            _isExcludedFromAllFee[to] ||
            (from == address(pair) && (to == address(router)))
        ) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        // consecutive trades in 1 hour will cause high fee
        if (
            isSell(sender, recipient) &&
            block.timestamp < lastTxTime[sender] + roundLong
        ) {
            setLiquidityFeePercentTemporary(22);
        }

        lastTxTime[sender] = block.timestamp;
        lastTxTime[recipient] = block.timestamp;

        if (!takeFee) removeAllFee();

        if (
            isBuy(sender, recipient) &&
            block.timestamp < lastRoundTime + roundLong
        ) {
            updateWarriors(recipient, amount);
        }

        // start a new round
        if (block.timestamp >= lastRoundTime + roundLong) {
            giveBack();
            for (uint256 i = 0; i < bidsNum; i++) {
                warriors[i] = address(0);
                currentBids[i] = 0;
                currentBoughts[i] = 0;
            }
            round++;
            totalBought = 0;
            lastRoundTime = block.timestamp;
            bidsNum = 0;
        }

        _transferStandard(sender, recipient, amount);

        if (!takeFee) restoreAllFee();

        // restore basic liquidity fee
        setLiquidityFeePercentTemporary(6);
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBonus
        ) = _getValues(tAmount);
        if (_isExcludedReward[sender]) {
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        _rOwned[sender] = _rOwned[sender] - rAmount;
        if (_isExcludedReward[recipient]) {
            _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        }
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeBonus(tBonus);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}