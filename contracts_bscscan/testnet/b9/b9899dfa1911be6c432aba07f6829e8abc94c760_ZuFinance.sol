/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// ZuFinance is a DeFi Token issued on Binance Smart Chain (BEP-20), 
                // designed to serve the gaming and sports betting industry, with three simple features implemented at its core; 
                
                       // LP Acquisition 5% 
                       // Burning on each trade 3%
                       // Static Reward (Reflection) 2% to all existing holders
                       
                       // Burn function and all fees - automatically set to 0 as soon as 1B of Tokens remaining in circulation
                       
                       // No team member benefits from Static Reward (Reflection)
                       // The transaction fees applies to all team members (except the owner)
           


// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function safeApprove(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

abstract contract ZuFinanceBase is IERC20, Ownable {
    event UpdateFee(string indexed feeType, uint256 previousTaxFee, uint256 newTaxFee);
    event IncludeReflectionAccount(address account);
    event ExcludeReflectionAccount(address account);
    event IncludeInFee(address account);
    event ExcludeFromFee(address account);
    event Burn(address account, uint256 amount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );

    address public constant BURNING_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    mapping (address => uint256) _rOwned;
    mapping (address => uint256) _tOwned;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) _isExcludedFromFee;
    mapping (address => bool) _isExcluded;
    address[] _excluded;

    uint256 constant MAX = ~uint256(0);
    uint256 internal _tTotal = 100 * 10**12 * 10**9;
    uint256 internal _rTotal = (MAX - (MAX % _tTotal));
    uint256 public currentRate = _rTotal / _tTotal;

    uint256 public maxTxAmount = 1 * 10**9 * 10**9;
    uint256 public numTokensToSwap = 1 * 10**8 * 10**9;
    uint256 public constant numTokensRemainingToStopFees = 1 * 10**9 * 10**9;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    IRouter public immutable router;
    address public immutable pair;

    constructor() {
        _rOwned[_msgSender()] = _rTotal;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        IRouter _router = IRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

         // Create a uniswap pair for this new token
        address _pair = IFactory(_router.factory()).createPair(address(this), _router.WETH());
        pair = _pair;

        // The team wallet addresses are fully disclosed for transparency
        _isExcluded[0x89EbF88686dC667d37738e15866eF80d3862B237] = true;
        _isExcluded[0xD3B7a3c4E88883588e2cF1C0Afce1e97A8fF1C97] = true;
        _isExcluded[0xf9C934f119A8D2c81B6438135B2e9167E024Ab95] = true;
        _isExcluded[0xA113489399F935A260866bEe007d8B0411D2bf75] = true;
        _isExcluded[0x63e2d52e099d5f43E1dbcE74c4FA56a8CF178CB6] = true;
        _isExcluded[0xC1E22b0fE83804677230515C60f80517DC652fe9] = true;
        _isExcluded[0x17c82411CDAAfFAAEEC0b37A4CeF4591393b082E] = true;
        _isExcluded[0x4a2a888F04028E307A6450FeF3c5690A9600eA0b] = true;
        _isExcluded[0x99781dDE8cf5Fb8c2d32A5B33196b21c3Bb6296B] = true;
        _isExcluded[0x5663D90E7e592E6e35B713d99CFd9A52351512cD] = true;
        _isExcluded[0x140ecdD83e98f87Ff67a979F30ec30e11C81278d] = true;


        _isExcluded[_pair] = true;
        _isExcluded[address(this)] = true;

        // set the rest of the contract variables
        router = _router;

        uint256 tokenToBurn = _tTotal / 10;  // 10% is to be burned
        _tokenTransferNoFee(_msgSender(), BURNING_ADDRESS, tokenToBurn);

        emit Transfer(address(0), _msgSender(), _tTotal - tokenToBurn);
    }

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public _taxFee = 2;
    uint256 _previousTaxFee = _taxFee;
    uint256 _tFeeTotal;

    uint256 public _liquidityFee = 5;
    uint256 _previousLiquidityFee = _liquidityFee;
    uint256 _totalTokenForLiquidity;

    uint256 public _burnFee = 3;
    uint256 _previousBurnFee = _burnFee;
    uint256 _totalTokenBurned;

    function _balanceOf(address account) internal view returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return _tokenFromReflection(_rOwned[account]);
    }

    function _reflectionFromToken(uint256 tAmount, bool deductFee) internal view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function _tokenFromReflection(uint256 rAmount) internal view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less reflected total");
        return rAmount/currentRate;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from 0 address");
        require(spender != address(0), "ERC20: approve to 0 address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address account, uint256 amount) internal {
        uint256 _rBurnedAmount = _reflectionFromToken(amount, false);
        _rOwned[account] -= _rBurnedAmount;
        _tOwned[account] -= amount;
        _rTotal -= _rBurnedAmount;
        _tTotal -= amount;
        emit Burn(account, amount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
        _totalTokenForLiquidity += _liquidityFee * tFee / _taxFee;
        _totalTokenBurned += _burnFee * tFee / _taxFee;
    }

    function _updateRate() private {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        currentRate = rSupply / tSupply;
    }

    function _excludeAccount(address account) internal {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = _tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeReflectionAccount(account);
    }

    function _includeAccount(address account) internal {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = _tOwned[account] * currentRate;
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit IncludeReflectionAccount(account);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function _removeAllFee() private {
        if (_taxFee == 0 &&
            _liquidityFee == 0 &&
            _burnFee == 0
        )
            return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }

    function _restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
    }

    function _getValues(uint256 tAmount)
        internal
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity)
        internal
        view
        returns (uint256, uint256, uint256)
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 10**2;
    }

    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * (_liquidityFee + _burnFee) / 10**2;
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            BURNING_ADDRESS,  // 3 possibilities: 1) address(0); 2) address(this); 3) address(another contract)
            block.timestamp
        );

    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from 0 address");
        require(to != address(0), "ERC20: transfer to 0 address");
        require(amount > 0, "ERC20: amount must be greater than 0");
        if (from != owner() && to != owner())
            require(amount <= maxTxAmount, "Amount exceeds maxTxAmount");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = _balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensToSwap;

        if (overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensToSwap;
            //add liquidity
            _swapAndLiquify(contractTokenBalance);
        }

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_tTotal <= numTokensRemainingToStopFees ||
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to])
        {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

            // split the contract balance into halves
            uint256 half = contractTokenBalance / 2;
            uint256 otherHalf = contractTokenBalance - half;

            // capture the contract's current BNB balance.
            // this is so that we can capture exactly the amount of BNB that the
            // swap creates, and not make the liquidity event include any BNB that
            // has been manually sent to the contract
            uint256 initialBalance = address(this).balance;

            // swap tokens for BNB
            _swapTokensForBNB(half);

            // how much BNB did we just swap into
            uint256 newBalance = address(this).balance - initialBalance;

            // add liquidity to uniswap
            _addLiquidity(otherHalf, newBalance);

            emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee)
            _removeAllFee();
        
        else if(_burnFee > 0) {
            uint256 burnAmt = amount * _burnFee / 100;
            _tokenTransferNoFee(sender, BURNING_ADDRESS, burnAmt);
            amount = amount - burnAmt;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        // currentRate is only updated here for every transaction that has a tax fee.
        // Only when a tax fee is collected does the rate need to get updated.
        _updateRate();

        if (!takeFee)
            _restoreAllFee();
    }

    function _tokenTransferNoFee(address sender, address recipient, uint256 amount) private {
        _rOwned[sender] = _rOwned[sender] - amount * currentRate;
        _rOwned[recipient] = _rOwned[recipient] + amount * currentRate;

        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender] - amount;
        }

        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient] + amount;
        }

        emit Transfer(sender, recipient, amount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _buyback() internal {
        uint256 balance = address(this).balance;
        require(balance > 0, "Insufficient BNB balance");

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokens{value: balance} (
            0,
            path,
            BURNING_ADDRESS,
            block.timestamp
        );
    }
}


contract ZuFinance is ZuFinanceBase {

    string public constant name = "ZuFinance";
    string public constant symbol = "ZUF";
    uint8 public constant decimals = 9;

    receive() external payable {}

    function totalSupply() external view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balanceOf(account);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function safeApprove(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function burn(uint256 amount) external onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function buyback() external onlyOwner returns (bool) {
        _buyback();
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductFee) external view returns (uint256) {
        return _reflectionFromToken(tAmount, deductFee);
    }

    function tokenFromReflection(uint256 rAmount) external view returns(uint256) {
        return _tokenFromReflection(rAmount);
    }

    function excludeAccountForReflection(address account) external onlyOwner {
        _excludeAccount(account);
    }

    function includeAccountForReflection(address account) external onlyOwner {
        _includeAccount(account);
    }

    function isExcludedFromReflection(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee <= 20, "TaxFee exceeds 20");
        _taxFee = taxFee;
        emit UpdateFee("Tax", _taxFee, taxFee);
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(liquidityFee <= 20, "LiquidityFee exceeds 20");
        _liquidityFee = liquidityFee;
        emit UpdateFee("Liquidity", _liquidityFee, liquidityFee);
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner {
        require(burnFee <= 20, "BurnFee exceeds 20");
        _burnFee = burnFee;
        emit UpdateFee("Burn", _burnFee, burnFee);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        require(maxTxPercent <= 20, "MaxTxPercent exceeds 20");
        uint256 newMaxTxAmount = _tTotal * maxTxPercent / 10**2;
        maxTxAmount = newMaxTxAmount;
        emit UpdateFee("MaxTx", maxTxAmount, newMaxTxAmount);
    }
    
    function setNumTokensToSwap(uint256 amount) external onlyOwner{
        numTokensToSwap = amount * 10**9;
    }

    function setSwapAndLiquifyEnabled(bool enabled) external onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(swapAndLiquifyEnabled);
    }

    function getTotalReflectionFee() external view returns (uint256) {
        return _tFeeTotal;
    }

    function getTotalTokenForLiquidity() external view returns (uint256) {
        return _totalTokenForLiquidity;
    }

    function getTotalTokenBurned() external view returns (uint256) {
        return _totalTokenBurned;
    }
}