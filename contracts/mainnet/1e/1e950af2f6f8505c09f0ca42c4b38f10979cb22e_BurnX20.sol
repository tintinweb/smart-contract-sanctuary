// SPDX-License-Identifier: MIT

/**
 * BurnX 2.0 - #ShareFi on fire. Charity. Rewards.
 *
 * A community centric powerhouse of hot mechanics that funds good 
 * causes, rewards holders, & supports a healthy price floor. 
 * Blazing a path to financial freedom, truly. 
 *
 * Website: https://BurnX.finance
 * Telegram: https://t.me/BurnXCommunity
 * Twitter: https://twitter.com/BurnX_Community
*/

pragma solidity ^0.6.12;

// Contracts
import "./SafeMath.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract BurnX20 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    // Reflect and allowances
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    // Reflect exclusions - fees & rewards
    mapping(address => bool) private _isExcludedFromFee; // fee
    mapping(address => bool) private _isExcluded; // reward
    address[] private _excluded;

    // Bots
    mapping(address => bool) private _isBot;
    address[] private _bots;

    // Reflect & Total Supply (capped)
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1_000_000_000_000_000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    // Standard token details
    string private _name = "BurnX 2.0";
    string private _symbol = "BurnX20";
    uint8 private _decimals = 9;

    // Default % trade tax settings
    uint256 private _taxFee = 4; // reflection
    uint256 private _marketingFee = 2; // marketing
    uint256 private _liquidityFee = 4; // liquidity

    // Rollback % trade tax settings
    uint256 private _prevTaxFee = _taxFee;
    uint256 private _prevMarketingFee = _marketingFee;
    uint256 private _prevLiquidityFee = _liquidityFee;

    // Uniswap
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    // Reentrancy, swap & liquify
    bool internal locked = false;
    bool public swapLiquifyEnabled = true;

    // Reentrancy guard
    modifier noReentrant() {
        locked = true;
        _;
        locked = false;
    }

    // Max token amount per TX
    uint256 private _maxTx = _tTotal;

    // Max tokens to be swapped - set to optimum
    uint256 private _amountSellLiquidity = 1000000000 * 10**9;

    // Events
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    // Wallets
    address payable private _marketingAddress;
    address private _lpAddress;

    constructor(address marketingAddress) public {
        // Total Supply to owner
        _rOwned[_msgSender()] = _rTotal;

        // Marketing
        _marketingAddress = payable(marketingAddress);

        // Uniswap router & pair
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        // Exclude addresses from reflect fee
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[_marketingAddress] = true;

        // LP token
        _lpAddress = _msgSender();

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "Amount exceeds allowance")
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
                "Allowance below zero"
            )
        );

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludeFromFee(address account, bool excluded)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = excluded;
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal);

        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);

            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);

            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(rAmount <= _rTotal);

        uint256 currentRate = _getRate();

        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(account != address(uniswapV2Router)); // UniswapV2 router
        require(!_isExcluded[account]);

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }

        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account]);

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

    function addBots(address[] memory botAddresses) external onlyOwner {
        for (uint256 i = 0; i < botAddresses.length; i++) {
            require(botAddresses[i] != address(uniswapV2Router)); // UniswapV2 router

            _isBot[botAddresses[i]] = true;
            _bots.push(botAddresses[i]);
        }
    }

    function removeBot(address account) external onlyOwner {
        require(_isBot[account]);

        for (uint256 i = 0; i < _bots.length; i++) {
            if (_bots[i] == account) {
                _bots[i] = _bots[_bots.length - 1];
                _isBot[account] = false;
                _bots.pop();
                break;
            }
        }
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _marketingFee == 0 && _liquidityFee == 0) return;

        _prevTaxFee = _taxFee;
        _prevMarketingFee = _marketingFee;
        _prevLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _prevTaxFee;
        _marketingFee = _prevMarketingFee;
        _liquidityFee = _prevLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0));
        require(recipient != address(0));
        require(amount > 0);
        require(!_isBot[sender]);
        require(!_isBot[recipient]);
        require(!_isBot[tx.origin]);

        if (sender != owner() && recipient != owner()) {
            require(amount <= _maxTx); // Max TX amount
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        // Is token balance over minimum target for selling?
        bool overMinTokenBalance = contractTokenBalance >= _amountSellLiquidity;
        
        // Token balance over Max TX
        if (contractTokenBalance >= _maxTx) {
            contractTokenBalance = _maxTx;
        } else {
            // Token balance over minimum but below Max TX
            contractTokenBalance = _amountSellLiquidity;
        }

        if (
            !locked &&
            swapLiquifyEnabled &&
            overMinTokenBalance &&
            sender != address(uniswapV2Pair)
        ) {
            // Add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        // Temporarily omit the fee if any account is excluded
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            takeFee = false;
        }

        // Transfer amount - deducts any necessary fees
        _tokenTransfer(sender, recipient, amount, takeFee);
    }

    function swapAndLiquify(uint256 takeAmount) private noReentrant {
        // Marketing vs Liquidity allocation.
        uint256 marketingPecentage = _marketingFee.mul(10000).mul(10**9).div(_marketingFee.add(_liquidityFee));
        uint256 toMarketing = marketingPecentage.mul(takeAmount).div(10000).div(10**9);
        uint256 toLiquify = takeAmount.sub(toMarketing);

        // Split token balance into halves
        uint256 tokenHalfForETH = toLiquify.div(2);
        uint256 halfForTokenLP = toLiquify.sub(tokenHalfForETH);

        uint256 ethBalanceBeforeSwap = address(this).balance;

        // Swap tokens for ETH
        uint256 toSwapForEth = tokenHalfForETH.add(toMarketing);
        swapTokensForEth(toSwapForEth);

        // Get new ETH balance
        uint256 ethRecivedFromSwap = address(this).balance.sub(ethBalanceBeforeSwap);

        // Recent ETH balance * 50% of the allocated LP tokens / marketing tokens
        uint256 ethLpPart = ethRecivedFromSwap.mul(tokenHalfForETH).div(toSwapForEth);

        // Add liquidity to Uniswap
        addLiquidity(halfForTokenLP, ethLpPart);

        emit SwapAndLiquify(tokenHalfForETH, ethLpPart, halfForTokenLP);

        // Send the rest to marketing.
        sendETHToMarketing(ethRecivedFromSwap.sub(ethLpPart));
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // Generate the Uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            _lpAddress,
            block.timestamp
        );
    }

    function sendETHToMarketing(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }

    // Manual swap & send if the token is highly valued
    function manualSwap() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualSend() public onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        sendETHToMarketing(contractETHBalance);
    }

    function setSwapLiquifyEnabled() external onlyOwner {
        swapLiquifyEnabled = !swapLiquifyEnabled;
    }

    function isSwapLiquifyEnabled() public view returns (bool) {
        return swapLiquifyEnabled;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

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

        if (!takeFee) restoreAllFee();
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
            uint256 tMarketingLiquidity
        ) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 rMarketingLiquidity = tMarketingLiquidity.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).sub(rMarketingLiquidity);

        _takeMarketingLiquidity(tMarketingLiquidity);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
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
            uint256 tMarketingLiquidity
        ) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 rMarketingLiquidity = tMarketingLiquidity.mul(currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).sub(rMarketingLiquidity);

        _takeMarketingLiquidity(tMarketingLiquidity);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
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
            uint256 tMarketingLiquidity
        ) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 rMarketingLiquidity = tMarketingLiquidity.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).sub(rMarketingLiquidity);

        _takeMarketingLiquidity(tMarketingLiquidity);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
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
            uint256 tMarketingLiquidity
        ) = _getValues(tAmount);
        uint256 currentRate = _getRate();
        uint256 rMarketingLiquidity = tMarketingLiquidity.mul(currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).sub(rMarketingLiquidity);

        _takeMarketingLiquidity(tMarketingLiquidity);
        _reflectFee(rFee, tFee);

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeMarketingLiquidity(uint256 tMarketingLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rMarketingLiquidity = tMarketingLiquidity.mul(currentRate);

        _rOwned[address(this)] = _rOwned[address(this)].add(rMarketingLiquidity);

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tMarketingLiquidity);
        }
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);

        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    // Recieve ETH when swapping
    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
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
            uint256 tMarketingLiquidityFee
        ) = _getTValues(tAmount, _taxFee, _marketingFee.add(_liquidityFee));
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            currentRate
        );

        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tMarketingLiquidityFee
        );
    }

    function _getTValues(
        uint256 tAmount,
        uint256 taxFee,
        uint256 marketingLiquidityFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tMarketingLiquidityFee = tAmount.mul(marketingLiquidityFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tMarketingLiquidityFee);

        return (tTransferAmount, tFee, tMarketingLiquidityFee);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
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
        uint256 rTransferAmount = rAmount.sub(rFee);

        if (rFee != 0) {
            rFee = currentRate.div(2).add(rFee);
        }

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

    function setTxFees(
        uint256 tax,
        uint256 marketing,
        uint256 liquidity
    ) external onlyOwner {
        require(tax.add(marketing).add(liquidity) <= 10);

        _taxFee = tax;
        _marketingFee = marketing;
        _liquidityFee = liquidity;
    }

    function setWallets(address marketingAddress, address lpAddress)
        external
        onlyOwner
    {
        _marketingAddress = payable(marketingAddress);

        _lpAddress = lpAddress;
    }

    function setAmountSellLiquidity(uint256 amountSellLiquidity)
        external
        onlyOwner
    {
        require(amountSellLiquidity >= 10**9);

        _amountSellLiquidity = amountSellLiquidity;
    }

    function setMaxTx(uint256 maxTx) external onlyOwner {
        require(maxTx >= 10**9);

        _maxTx = maxTx;
    }

    function recoverTokens(uint256 amount) public onlyOwner {
        _approve(address(this), owner(), amount);
        _transfer(address(this), owner(), amount);
    }

    function withdrawToken(
        address token,
        uint256 amount,
        address recipient
    ) external onlyOwner {
        require(token != uniswapV2Pair);
        require(token != address(this));

        IERC20(token).transfer(recipient, amount);
    }

    function migrateHolders(
        address[] memory recipients,
        uint256[] memory amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length);

        for (uint256 i = 0; i < recipients.length; i++) {
            transfer(recipients[i], amounts[i]);
        }
    }
}