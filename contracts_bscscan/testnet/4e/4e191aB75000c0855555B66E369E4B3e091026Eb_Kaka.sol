// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Address.sol";
import "./EnumerableSet.sol";
import "./IBEP20.sol";
import "./Ownable.sol";
import "./Routers.sol";
import "./SafeMath.sol";

contract Kaka is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Excluded reward array should never get large
    // This constant will help keep the gas fees reasonable
    uint256 private constant MAX_EXCLUDED = 1024;
    EnumerableSet.AddressSet private _isExcludedFromReward;
    EnumerableSet.AddressSet private _isExcludedFromFee;
    EnumerableSet.AddressSet private _isExcludedFromSwapAndLiquify;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 105000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    string private constant _name = "Kaka";
    string private constant _symbol = "KAKA";
    uint8 private constant _decimals = 9;

    // No tax fee - this is the fee that gets redistributed to token holders
    uint256 public _taxFee = 0;
    // 5% of every transaction will be converted into BNB for liquidity
    uint256 public _liquidityFee = 500;
    // 5% of every transaction will be converted into BNB for dev fees
    uint256 public _devFee = 500;
    // 2% of every transaction is burned
    uint256 public _burnFee = 200;

    // At any given time, all fees can NOT exceed 13%
    // This is one of the differentiating factors for Catchy
    // This allows the team to tweak fees based on community feedback
    // More burn? No problem. Need more liquidity? We got you covered
    // Think the devs are getting too big of a cut? We can decrease that as well
    uint256 private constant TOTAL_FEES_LIMIT = 1300;
    // Dev fees will NEVER exceed 5%
    uint256 private constant DEV_FEES_LIMIT = 500;

    // The minimum maximum transaction limit
    // This answers the question of, how low can we set the maximum transaction limit?
    // We set this to 0.1%. So, the contract owner can NOT set the maximum
    // transaction tokens to less than 0.1% of the total supply
    uint256 private constant MIN_TX_LIMIT = 10;
    uint256 public _maxTxAmount = 105000000 * 10**9;
    uint256 public _numTokensSellToAddToLiquidity = 20000 * 10**9;

    uint256 private _totalDevFeesCollected = 0;

    // Liquidity
    bool public _swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;

    IUniswapV2Router02 public _uniswapV2Router;
    address public _uniswapV2Pair;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );
    event DevFeesCollected(uint256 bnbCollected);

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(address cOwner) Ownable(cOwner) {
        _rOwned[cOwner] = _rTotal;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // Exclude system addresses from fee
        _isExcludedFromFee.add(owner());
        _isExcludedFromFee.add(address(this));

        _isExcludedFromSwapAndLiquify.add(_uniswapV2Pair);
        _isExcludedFromSwapAndLiquify.add(address(_uniswapV2Router));

        emit Transfer(address(0), cOwner, _tTotal);
    }

    receive() external payable {}

    // BEP20
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcludedFromReward.contains(account)) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    // REFLECTION
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcludedFromReward.contains(sender),
            "Excluded addresses cannot call this function"
        );

        (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
            tAmount
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, , ) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
                tAmount
            );
            uint256 currentRate = _getRate();
            (uint256 rAmount, , ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tBurn,
                currentRate
            );

            return rAmount;
        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(
                tAmount
            );
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount, ) = _getRValues(
                tAmount,
                tFee,
                tLiquidity,
                tBurn,
                currentRate
            );

            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        require(
            !_isExcludedFromReward.contains(account),
            "Account is already excluded in reward"
        );
        require(
            _isExcludedFromReward.length() < MAX_EXCLUDED,
            "Excluded reward set reached maximum capacity"
        );

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward.add(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(
            _isExcludedFromReward.contains(account),
            "Account is already included in reward"
        );

        _isExcludedFromReward.remove(account);
        _tOwned[account] = 0;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function devPercentageOfLiquidity() public view returns (uint256) {
        return (_devFee * 10000) / (_devFee.add(_liquidityFee));
    }

    /**
        @dev This is the portion of liquidity that will be sent to the uniswap router.
        Dev fees are considered part of the liquidity conversion.
     */
    function pureLiquidityPercentage() public view returns (uint256) {
        return (_liquidityFee * 10000) / (_devFee.add(_liquidityFee));
    }

    function totalDevFeesCollected() external view onlyDev returns (uint256) {
        return _totalDevFeesCollected;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee.add(account);
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee.remove(account);
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(
            taxFee.add(_liquidityFee).add(_devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(
            _taxFee.add(liquidityFee).add(_devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _liquidityFee = liquidityFee;
    }

    function setDevFeePercent(uint256 devFee) external onlyOwner {
        require(
            devFee <= DEV_FEES_LIMIT,
            "Dev fees can not exceed the declared limit"
        );
        require(
            _taxFee.add(_liquidityFee).add(devFee).add(_burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _devFee = devFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        require(
            _taxFee.add(_liquidityFee).add(_devFee).add(burnFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        _burnFee = burnFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(
            maxTxPercent <= 10000,
            "Maximum transaction limit percentage can't be more than 100%"
        );
        require(
            maxTxPercent >= MIN_TX_LIMIT,
            "Maximum transaction limit can't be less than the declared limit"
        );
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
    }

    function setMinLiquidityPercent(uint256 minLiquidityPercent)
        external
        onlyOwner
    {
        require(
            minLiquidityPercent <= 10000,
            "Minimum liquidity percentage percentage can't be more than 100%"
        );
        _numTokensSellToAddToLiquidity = _tTotal.mul(minLiquidityPercent).div(
            10000
        );
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee.contains(account);
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward.contains(account);
    }

    function setIsExcludedFromSwapAndLiquify(address a, bool b)
        external
        onlyOwner
    {
        if (b) {
            _isExcludedFromSwapAndLiquify.add(a);
        } else {
            _isExcludedFromSwapAndLiquify.remove(a);
        }
    }

    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }

    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(to != devWallet(), "Dev wallet address cannot receive tokens");
        require(from != devWallet(), "Dev wallet address cannot send tokens");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }

        /*
            - swapAndLiquify will be initiated when token balance of this contract
            has accumulated enough over the minimum number of tokens required.
            - don't get caught in a circular liquidity event.
            - don't swapAndLiquify if sender is uniswap pair.
        */

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool isOverMinTokenBalance = contractTokenBalance >=
            _numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromSwapAndLiquify.contains(from) &&
            _swapAndLiquifyEnabled
        ) {
            swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        bool takeFee = true;
        if (
            _isExcludedFromFee.contains(from) || _isExcludedFromFee.contains(to)
        ) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function collectDevFees() public onlyDev {
        _totalDevFeesCollected = _totalDevFeesCollected.add(
            address(this).balance
        );
        devWallet().transfer(address(this).balance);
        emit DevFeesCollected(address(this).balance);
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        // This variable holds the liquidity tokens that won't be converted
        uint256 liqTokens = tokenAmount.mul(pureLiquidityPercentage()).div(
            20000
        );
        // Everything else from the tokens should be converted
        uint256 tokensForBnbExchange = tokenAmount.sub(liqTokens);
        // This would be in the non-percentage form, 0 (0%) < devPortion < 10000 (100%)
        // The devPortion here indicates the portion of the converted tokens (BNB) that
        // would be assigned to the devWallet
        uint256 devPortion = tokenAmount.mul(devPercentageOfLiquidity()).div(
            tokensForBnbExchange
        );

        uint256 initialBalance = address(this).balance;

        swapTokensForBnb(tokensForBnbExchange);

        // How many BNBs did we gain after this conversion?
        uint256 gainedBnb = address(this).balance.sub(initialBalance);

        // Calculate the amount of BNB that's assigned to devWallet
        uint256 balanceToDev = (gainedBnb.mul(devPortion)).div(10000);
        // The leftover BNBs are purely for liquidity
        uint256 liqBnb = gainedBnb.sub(balanceToDev);

        addLiquidity(liqTokens, liqBnb);

        emit SwapAndLiquify(tokensForBnbExchange, liqBnb, liqTokens);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // Add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lockedLiquidity(),
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        uint256 previousTaxFee = _taxFee;
        uint256 previousLiquidityFee = _liquidityFee;
        uint256 previousDevFee = _devFee;
        uint256 previousBurnFee = _burnFee;

        if (!takeFee) {
            _taxFee = 0;
            _liquidityFee = 0;
            _devFee = 0;
            _burnFee = 0;
        }

        bool senderExcluded = _isExcludedFromReward.contains(sender);
        bool recipientExcluded = _isExcludedFromReward.contains(recipient);
        if (senderExcluded && !recipientExcluded) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!senderExcluded && recipientExcluded) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!senderExcluded && !recipientExcluded) {
            _transferStandard(sender, recipient, amount);
        } else if (senderExcluded && recipientExcluded) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) {
            _taxFee = previousTaxFee;
            _liquidityFee = previousLiquidityFee;
            _devFee = previousDevFee;
            _burnFee = previousBurnFee;
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            currentRate
        );
        uint256 rBurn = tBurn.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity, currentRate);
        _reflectFee(rFee, rBurn, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(
        uint256 rFee,
        uint256 rBurn,
        uint256 tFee,
        uint256 tBurn
    ) private {
        _rTotal = _rTotal.sub(rFee).sub(rBurn);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _tBurnTotal = _tBurnTotal.add(tBurn);
        _tTotal = _tTotal.sub(tBurn);
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
        uint256 tFee = tAmount.mul(_taxFee).div(10000);
        // We treat the dev fee as part of the total liquidity fee
        uint256 tLiquidity = tAmount.mul(_liquidityFee.add(_devFee)).div(10000);
        uint256 tBurn = tAmount.mul(_burnFee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBurn,
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
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        rTransferAmount = rTransferAmount.sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _isExcludedFromReward.length(); i++) {
            address excludedAddress = _isExcludedFromReward.at(i);
            if (
                _rOwned[excludedAddress] > rSupply ||
                _tOwned[excludedAddress] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[excludedAddress]);
            tSupply = tSupply.sub(_tOwned[excludedAddress]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function takeTransactionFee(
        address to,
        uint256 tAmount,
        uint256 currentRate
    ) private {
        if (tAmount <= 0) {
            return;
        }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcludedFromReward.contains(to)) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
}