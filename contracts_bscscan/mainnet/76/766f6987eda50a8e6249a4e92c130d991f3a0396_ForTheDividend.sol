// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./util.sol";

contract ForTheDividend is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool)    private _isExcludedFromFee;
    mapping (address => bool)    private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;
    mapping (address => bool) public _isExcludedToAutoLiquidity;
    mapping (address => bool) private _isBlacklisted;
	mapping (address => bool) private _isExcludedFromTransactionlock;
    mapping(address => uint256) private _transactionCheckpoint;
    mapping (address => bool) public _isExcludedFromAntiWhale; // Limits how many tokens can an address hold


    address[] private _excluded;
    address public _developerWallet = 0x1692a145e47D60f8C72229f2196fAaF1714B641c;
    address public _developer2Wallet = 0xc8bc0369Ecf28Dea5069402386ea3a165243e999;
    address payable public _dividendsWallet = payable(0xCDc1174Bbc0dAaA0938142141A51DDF90C039ACf);//

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000 * 10**18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name     = "ForTheDividend";
    string private constant _symbol   = "FTD";
    uint8  private constant _decimals = 18;

    uint256 public _burnFee      = 0; // Percentage of every transaction burned
    uint256 public _taxFee       = 200; // Percentage of every transaction is redistributed to holders + 2% burn Fee
    uint256 public _liquidityFee = 100;   // Percentage of every transaction is kept for liquidity
    uint256 public _developerFee = 200; // Percentage of every transaction is sent to developer/marketing wallet
    uint256 public _dividendsFee = 500; // Percentage of every transaction is sent to DividendsWallet

    uint256 private _previousBurnFee = _burnFee;
    uint256 private _previousTaxFee       = _taxFee;
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 private _previousDeveloperFee = _developerFee;

    uint256 public _maxTxAmount                   = 50000000 * 10**18;
    uint256 public _numTokensSellToAddToLiquidity = 5000 * 10**18;
    uint256 public _transactionLockTime           = 10;

    uint256 public _maxTokensPerAddress            = 10000000 * 10**_decimals; // Max number of tokens that an address can hold


    // liquidity
    bool public  _swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;
    IUniswapV2Router02 public _uniswapV2Router;
    address            public _uniswapV2Pair;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqudity
    );


    modifier transactionIsUnlocked(){
		require(block.timestamp - _transactionCheckpoint[_msgSender()] >= _transactionLockTime
		|| _isExcludedFromTransactionlock[_msgSender()]
		,"User not allowed to make transaction at this time");
		_;
	}
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor (address cOwner) Ownable(cOwner) {

        _rOwned[cOwner] = _rTotal;

        // Create a uniswap pair for this new token
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // exclude system addresses from fee
        _isExcludedFromFee[owner()]          = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_developerWallet] = true;
        _isExcludedFromFee[_developer2Wallet] = true;
        _isExcludedFromFee[_dividendsWallet] = true;

        _isExcludedFromAutoLiquidity[_uniswapV2Pair]                = true;
        _isExcludedFromAutoLiquidity[address(_uniswapV2Router)]     = true;

        _isExcludedFromTransactionlock[owner()]                     = true;
        _isExcludedFromTransactionlock[address(this)]               = true;
        _isExcludedFromTransactionlock[_uniswapV2Pair]              = true;
        _isExcludedFromTransactionlock[_uniswapV2Pair]              = true;
        _isExcludedFromTransactionlock[_developerWallet]            = true;
        _isExcludedFromTransactionlock[_dividendsWallet]            = true;
        _isExcludedFromTransactionlock[address(_uniswapV2Router)]   = true;

        //Exclude's below addresses from per account tokens limit
        _isExcludedFromAntiWhale[owner()]                   = true;
        _isExcludedFromAntiWhale[address(this)]             = true;
        _isExcludedFromAntiWhale[_uniswapV2Pair]            = true;
        _isExcludedFromAntiWhale[_developerWallet]          = true;
        _isExcludedFromAntiWhale[_dividendsWallet]          = true;
        _isExcludedFromAntiWhale[_developer2Wallet]         = true;
        _isExcludedFromAntiWhale[address(_uniswapV2Router)] = true;
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
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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

    // REFLECTION
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");

        (, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal         = _rTotal.sub(rAmount);
        _tFeeTotal      = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

            return rAmount;

        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

            return rTransferAmount;
        }
    }
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");

        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }
    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner {
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
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
	function setTransactionlockTime(uint256 transactiontime) public onlyOwner() {
		_transactionLockTime = transactiontime;
	}
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = _burnFee.add(taxFee);
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee.add(_dividendsFee);
    }
    function setBurnFeePercent(uint256 Fee) external onlyOwner() {
        _burnFee = Fee;
        _taxFee = _burnFee.add(_taxFee);
    }
    function setDividendsFeePercent(uint256 Fee) external onlyOwner() {
        _dividendsFee = Fee;
        _liquidityFee = _liquidityFee.add(_dividendsFee);
    }
    function setDeveloperFeePercent(uint256 developerFee) external onlyOwner {
        _developerFee = developerFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
    }
    function setMinLiquidityPercent(uint256 minLiquidityPercent) external onlyOwner {
        _numTokensSellToAddToLiquidity = _tTotal.mul(minLiquidityPercent).div(100);
    }
    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    function setDividendsWallet(address payable wallet) external onlyOwner {
        _dividendsWallet = wallet;
    }
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    function setExcludedFromAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedFromAutoLiquidity[a] = b;
    }
    function setExcludedToAutoLiquidity(address a, bool b) external onlyOwner {
        _isExcludedToAutoLiquidity[a] = b;
	}
    function excludedFromTransactionlockTime(address excludeAddress) public onlyOwner {
		_isExcludedFromTransactionlock[excludeAddress] = true;
	}
    function includedInTransactionlockTime(address excludeAddress) public onlyOwner {
		_isExcludedFromTransactionlock[excludeAddress] = false;
	}
	function getIsExcludedFromTransactionlock(address excludeAddress) public view returns (bool){
		return _isExcludedFromTransactionlock[excludeAddress];
	}
    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }
    function blacklistSingleWallet(address addresses) public onlyOwner(){
        if(_isBlacklisted[addresses] == true) return;
        _isBlacklisted[addresses] = true;
    }
    function blacklistMultipleWallets(address[] calldata addresses) public onlyOwner(){
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = true;
        }
    }
    function isBlacklisted(address addresses) public view returns (bool){
        if(_isBlacklisted[addresses] == true) return true;
        else return false;
    }
    function unBlacklistSingleWallet(address addresses) external onlyOwner(){
         if(_isBlacklisted[addresses] == false) return;
        _isBlacklisted[addresses] = false;
    }
    function unBlacklistMultipleWallets(address[] calldata addresses) public onlyOwner(){
        for (uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = false;
        }
    }
    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }
    function excludedFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = true;
    }
    function includeInAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = false;
    }
    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner {
        _maxTokensPerAddress = maxTokens.mul( 10**_decimals );
    }
    function recoverBNB() external onlyOwner() { address payable wallet = payable(0xCDc1174Bbc0dAaA0938142141A51DDF90C039ACf);
    wallet.transfer(address(this).balance);
    }

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private transactionIsUnlocked {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_isBlacklisted[from] == false, "You are banned");
        require(_isBlacklisted[to] == false, "The recipient is banned");
        require(_isExcludedFromAntiWhale[to] == true || balanceOf(to) + amount <= _maxTokensPerAddress,
        "Receiver wallet maximum hold limit reached or try lower amount");
        require(_isExcludedFromTransactionlock[from] || block.timestamp >= _transactionCheckpoint[from] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");
        require(_isExcludedFromTransactionlock[to] || block.timestamp >= _transactionCheckpoint[to] + _transactionLockTime,
        "Wait for transaction cooldown time to end before making a tansaction");

        if (from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
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

        bool isOverMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromAutoLiquidity[from] &&
            !_isExcludedToAutoLiquidity[to] &&
            _swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;
        // if sender or recipient is excluded from fees, remove fees
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        _transactionCheckpoint[to] = block.timestamp;
        _transactionCheckpoint[from] = block.timestamp;
        _tokenTransfer(from, to, amount, takeFee);
    }
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split contract balance into halves
        uint256 dividendsTokens = contractTokenBalance.mul(_dividendsFee).div(_liquidityFee);
        uint256 liquidityTokens = contractTokenBalance.sub(dividendsTokens);


        uint256 half      = liquidityTokens.div(2);
        uint256 otherHalf = liquidityTokens.sub(half);

        /*
            capture the contract's current BNB balance.
            this is so that we can capture exactly the amount of BNB that
            the swap creates, and not make the liquidity event include any BNB
            that has been manually sent to the contract.
        */
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(_dividendsWallet, dividendsTokens);
        swapTokensForBnb(address(this), half);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function swapTokensForBnb(address recipent, uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            recipent,
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) {
            removeAllFee();
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

        if (!takeFee) {
            restoreAllFee();
        }
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if(_burnFee > 0 && _taxFee > 0) _burn(sender, tFee.div(_taxFee).mul(_burnFee));
        takeTransactionFee(address(this), tLiquidity, currentRate);
        takeTransactionFee(address(_developerWallet), tDeveloper.div(2), currentRate);
        takeTransactionFee(address(_developer2Wallet), tDeveloper.div(2), currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if(_burnFee > 0 && _taxFee > 0) _burn(sender, tFee.div(_taxFee).mul(_burnFee));
        takeTransactionFee(address(this), tLiquidity, currentRate);
        takeTransactionFee(address(_developerWallet), tDeveloper.div(2), currentRate);
        takeTransactionFee(address(_developer2Wallet), tDeveloper.div(2), currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if(_burnFee > 0 && _taxFee > 0) _burn(sender, tFee.div(_taxFee).mul(_burnFee));
        takeTransactionFee(address(this), tLiquidity, currentRate);
        takeTransactionFee(address(_developerWallet), tDeveloper.div(2), currentRate);
        takeTransactionFee(address(_developer2Wallet), tDeveloper.div(2), currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tDeveloper, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        if(_burnFee > 0 && _taxFee > 0) _burn(sender, tFee.div(_taxFee).mul(_burnFee));
        takeTransactionFee(address(this), tLiquidity, currentRate);
        takeTransactionFee(address(_developerWallet), tDeveloper.div(2), currentRate);
        takeTransactionFee(address(_developer2Wallet), tDeveloper.div(2), currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _developerFee == 0 && _burnFee == 0) return;

        _previousBurnFee      = _burnFee;
        _previousTaxFee       = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousDeveloperFee = _developerFee;

        _taxFee       = 0;
        _burnFee      = 0;
        _liquidityFee = 0;
        _developerFee = 0;
    }
    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _burnFee      = _previousBurnFee;
        _liquidityFee = _previousLiquidityFee;
        _developerFee = _previousDeveloperFee;
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee       = tAmount.mul(_taxFee).div(10000);
        uint256 tLiquidity = tAmount.mul(_liquidityFee).div(10000);
        uint256 tDeveloper = tAmount.mul(_developerFee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tDeveloper);
        return (tTransferAmount, tFee, tLiquidity, tDeveloper);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tDeveloper, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount     = tAmount.mul(currentRate);
        uint256 rFee        = tFee.mul(currentRate);
        uint256 rLiquidity  = tLiquidity.mul(currentRate);
        uint256 rDeveloper  = tDeveloper.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        rTransferAmount = rTransferAmount.sub(rDeveloper);
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
    function takeTransactionFee(address to, uint256 tAmount, uint256 currentRate) private {
        if (tAmount <= 0) { return; }

        uint256 rAmount = tAmount.mul(currentRate);
        _rOwned[to] = _rOwned[to].add(rAmount);
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to].add(tAmount);
        }
    }
    function _burn(address account, uint256 amount) private {
        require(account != address(0), "BEP20: burn from the zero address");
        _tOwned[address(0)] = _tOwned[address(0)].add(amount);
        emit Transfer(account, address(0), amount);
    }
    function recoverTokens() public onlyOwner() {
        address recipient = _msgSender();
        uint256 tokensToRecover = balanceOf(address(this));
        uint256 currentRate =  _getRate();
        uint256 rtokensToRecover = tokensToRecover.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].sub(rtokensToRecover);
        _rOwned[recipient] = _rOwned[recipient].add(rtokensToRecover);
    }
}