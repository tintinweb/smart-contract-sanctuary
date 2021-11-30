// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Uniswap.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
Wine Gurus
    A portuguese founded DeFi project. 
    A project that aims to bring the wine industry closer to the cryptoworld.
    Our team seeks to create the biggest portuguese token with multiple usage purposes in the real world.
 
    # Wine Gurus Features:
 
    10% TRANSACTION FEE
    - 1% fee per transaction gets added to the weekly lottery pool
    - 1% to the Marketing wallet 
    - 2% to the Development wallet
    - 3% fee per transaction gets added to the liquidity pool.
    - 3% fee per transaction gets distributed to holders.
*/

contract WineGurus is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 1000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _lotteryTotal;

    string private _name = "Wine Gurus";
    string private _symbol = "WINEGURU";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 300;  // 3% fee per transaction gets distributed to holders.
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _total3Fee = 600;  // 6% liquidity + development fee + marketing fee
    uint256 private _previousTotal3Fee = _total3Fee;

    uint256 public _liquidityFee = 300; // 3% liquidity fee;

    address payable public _marketingWallet = 0xA1cb74d58b7C1D3b219E5d816D24cBa8373A674A;
    uint256 public _marketingFee = 100; // 1% marketing fee

    address payable public _developmentWallet = 0x796223b27E626fc98c51E0Bd5A819c4fc1C91445;
    uint256 public _developmentFee = 200; // 2% development fee

    address public _lotteryfeewallet = 0xb17b7C66c24e8082258ea193d01dF36167D1AE51;
    uint256 public _lotteryFeePercent = 100; // 1% lottery fee
    uint256 private _previouslotteryFeePercent = _lotteryFeePercent;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    bool public openTrading = false;

    uint256 public _maxTxAmount = 5000000000000 * 10**9;
    uint256 public numTokensSellToAddToLiquidity = 500000000000 * 10**9;

    event OpenTradingEnabledUpdated(bool enabled);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () public {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);  // Pancakeswap mainnet router

        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);  // Pancakeswap testnet router
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), msg.sender, _tTotal);
    }


    function getBNBBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdrawOverFlowBNB() public onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(getBNBBalance());
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal + _lotteryTotal;
    }

    function totalLotteries() public view returns (uint256) {
        return _lotteryTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
        updateTotal3Fee();
    }

    function setDevelopmentFeePercent(uint256 developmentFee) external onlyOwner() {
        _developmentFee = developmentFee;
        updateTotal3Fee();
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _marketingFee = marketingFee;
        updateTotal3Fee();
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }

    function setNumTokensSell(uint256 numtokenSell) external onlyOwner() {
        numTokensSellToAddToLiquidity = numtokenSell;
        emit MinTokensBeforeSwapUpdated(numtokenSell);
    }

    function setlotteryFeePercent(uint256 lotteryFeePercent) external onlyOwner() {
        _lotteryFeePercent = lotteryFeePercent;
    }

    function setlotteryfeewallet(address lotteryWallet) external onlyOwner() {
        _lotteryfeewallet = lotteryWallet;
    }

    function setDevelopmentWallet(address payable developmentWallet) external onlyOwner() {
        _developmentWallet = developmentWallet;
    }

    function setMarketingWallet(address payable marketingWallet) external onlyOwner() {
        _marketingWallet = marketingWallet;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to receive BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee, uint256 xFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _lotteryTotal = _lotteryTotal.add(xFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTotal3) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTotal3, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTotal3);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tTotal3 = calculateTotal3Fee(tAmount);
        uint256 tLottery = calculateLotteryFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTotal3).sub(tLottery);
        return (tTransferAmount, tFee, tTotal3);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTotal3, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTotal3 = tTotal3.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTotal3);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeTotal3(uint256 tTotal3) private {
        uint256 currentRate =  _getRate();
        uint256 rTotal3 = tTotal3.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTotal3);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tTotal3);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**4
        );
    }

    function calculateTotal3Fee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_total3Fee).div(
            10**4
        );
    }

    function calculateLotteryFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_lotteryFeePercent).div(
            10**4
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _total3Fee == 0 && _lotteryFeePercent == 0) return;

        _previousTaxFee = _taxFee;
        _previousTotal3Fee = _total3Fee;
        _previouslotteryFeePercent = _lotteryFeePercent;

        _taxFee = 0;
        _total3Fee = 0;
        _lotteryFeePercent = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _total3Fee = _previousTotal3Fee;
        _lotteryFeePercent = _previouslotteryFeePercent;
    }

    function updateTotal3Fee() private {
        _total3Fee = _liquidityFee + _developmentFee + _marketingFee;
        _previousTotal3Fee = _total3Fee;
    }

    function setOpenTrading(bool _enabled) public onlyOwner {
        openTrading = _enabled;
        emit OpenTradingEnabledUpdated(_enabled);
    }

    function prepareForPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(false);
        setOpenTrading(false);
        _taxFee = 0;
        _total3Fee = 0;
        _lotteryFeePercent = 0;
        _maxTxAmount = 1000000000000000 * 10**9;
    }
    
    function afterPreSale() external onlyOwner {
        setSwapAndLiquifyEnabled(true);
        setOpenTrading(true);
        _taxFee = 300;
        _total3Fee = 600;
        _lotteryFeePercent = 100;
        _maxTxAmount = 5000000000000 * 10**9;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(!openTrading){
            require(_msgSender() != address(uniswapV2Router) && _msgSender() != uniswapV2Pair, "ERR: disable adding liquidity");
        }

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;

            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        //transfer amount, it will take tax, raid, marketing, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 liqTokens = contractTokenBalance.mul(_liquidityFee).div(_total3Fee).div(2);
        uint256 otherTokens = contractTokenBalance - liqTokens;  // liqidity half + development + marketing tokens for swap to bnb

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(otherTokens); // <- this breaks the BNB -> TOKEN swap when swap+liquify is triggered

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        uint256 bnbPercent = _liquidityFee.div(2) + _developmentFee + _marketingFee;

        uint256 liqBNB = newBalance.mul(_liquidityFee).div(2).div(bnbPercent);

        uint256 developmentBNB = newBalance.mul(_developmentFee).div(bnbPercent);

        uint256 marketingBNB = newBalance.sub(liqBNB).sub(developmentBNB);

        // add liquidity to uniswap
        addLiquidity(liqTokens, newBalance);

        // transfer bnb to development wallet
        _developmentWallet.transfer(developmentBNB);

        //transfer bnb to marketing wallet
        _marketingWallet.transfer(marketingBNB);

        emit SwapAndLiquify(otherTokens, liqBNB, liqTokens);
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> bnb
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTotal3) = _getValues(tAmount);

        uint256 lotteryFeeAmount;

        if (_lotteryFeePercent != 0) {
            lotteryFeeAmount = rAmount / (10000 / _lotteryFeePercent);
        } else {
            lotteryFeeAmount = 0;
        }

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount).sub(lotteryFeeAmount);

        _rOwned[_lotteryfeewallet] = _rOwned[_lotteryfeewallet].add(lotteryFeeAmount);

        _takeTotal3(tTotal3);
        _reflectFee(rFee, tFee, lotteryFeeAmount);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTotal3) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTotal3(tTotal3);
        _reflectFee(rFee, tFee, 0);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTotal3) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTotal3(tTotal3);
        _reflectFee(rFee, tFee, 0);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTotal3) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTotal3(tTotal3);
        _reflectFee(rFee, tFee, 0);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}