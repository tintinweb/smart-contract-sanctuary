// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router02.sol";

// TBD
// add cliffs for buying at the beginning
// are all the getters and setters needed
// implement onlyOwnerOrAdmin modifier
// implement admin related functions - set admin, transfer admin, etc. Ownable like
// do not forget to exclude the admin from fees (also while transferring rights. revoke and grant exclusion)

contract TestCoin is Ownable, IERC20 {
    string private constant _name = "XXX"; //TBD
    string private constant _symbol = "XXX"; //TBD    
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _setCoolDown;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;
    address private _uniswapV2Pair;
    IUniswapV2Router02 private _uniswapV2Router;
    address payable private _charityWallet;
    address payable private _marketingWallet;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**3 * 10**18; //TBD
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _maxTxAmount;
    uint256 private _numTokensSellToAddToLiquidity;
    uint256 private _tFeeTotal;
    uint8 private constant _decimals = 18;
    uint8 private _refTax = 2; // Fee for holders TBD
    uint8 private _liqTax = 2; // Fee for liquidity TBD
    uint8 private _charityTax = 3; // Fee for charity TBD
    uint8 private _marketingTax = 3; // Fee for marketing TBD
    uint8 private _previousRefTax = _refTax;
    uint8 private _previousLiqTax = _liqTax;
    uint8 private _previousCharityTax = _charityTax;
    uint8 private _previousMarketingTax = _marketingTax;
    bool private _inSwapAndLiquify = false;
    bool private _swapAndLiquifyEnabled = true;
    bool private _coolDownEnabled = true;
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    receive() external payable {}

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        _maxTxAmount = _tTotal;
        _numTokensSellToAddToLiquidity = _tTotal/100; //TBD
        _isExcludedFromFee[_msgSender()] = true;
        _isExcludedFromFee[address(this)] = true;

        _charityWallet = payable(0x90Bf054Af0Af77567488eeaF4E0EE91C8A30710e); // TBD
        _marketingWallet = payable(0x2e7b2039C947086a76ab95D4d51d3F066799048b); // TBD
        _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                            .createPair(address(this), _uniswapV2Router.WETH());

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
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
        require(_allowances[sender][_msgSender()] - amount >= 0, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        require(_allowances[_msgSender()][spender] - subtractedValue >= 0, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
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
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = 
            _getRValues(tAmount, tFee, tLiquidity, _getRate());
        
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, uint256, uint256)
    {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate)
        private
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
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
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) {
                return (_rTotal, _tTotal); 
            }
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }

        if (rSupply < _rTotal / _tTotal) {
            return (_rTotal, _tTotal);
        }

        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;

        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        }
    }

    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _refTax / 10**2;
    }

    function _calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount * (_liqTax + _charityTax + _marketingTax) / 10**2;
    }

    function _removeAllFee() private {
        _previousRefTax = _refTax;
        _previousLiqTax = _liqTax;
        _previousCharityTax = _charityTax;
        _previousMarketingTax = _marketingTax;

        _refTax = 0;
        _liqTax = 0;
        _charityTax = 0;
        _marketingTax = 0;
    }

    function _restoreAllFee() private {
        _refTax = _previousRefTax;
        _liqTax = _previousLiqTax;
        _charityTax = _previousCharityTax;
        _marketingTax = _previousMarketingTax;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function failSafeSwapAndLiquify(uint256 amount) external onlyOwner {
        _swapAndLiquify(amount);
    }    

    function setCharityWallet(address payable newCharityWallet) external onlyOwner {
        _charityWallet = newCharityWallet;
    }

    function getCharityWallet() external view returns (address) {
        return _charityWallet;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        _marketingWallet = newMarketingWallet;
    }

    function getMarketingWallet() external view returns (address) {
        return _marketingWallet;
    }    

    function setLiquidityFeePercent(uint8 newLiqTax) external onlyOwner {
        require(newLiqTax % 2 == 0, "Liquidity tax must be even number");
        _liqTax = newLiqTax;
    }

    function getLiquidityFeePercent() external view returns (uint8) {
        return _liqTax;
    }

    function setCharityFeePercent(uint8 newCharityTax) external onlyOwner {
        _charityTax = newCharityTax;
    }

    function getCharityFeePercent() external view returns (uint8) {
        return _charityTax;
    }

    function setMarketingFeePercent(uint8 newMarketingTax) external onlyOwner {
        _marketingTax = newMarketingTax;
    }

    function getMarketingFeePercent() external view returns (uint8) {
        return _marketingTax;
    }    

    function setMaxTxAmount(uint256 newMaxTxAmount) external onlyOwner {
        _maxTxAmount = newMaxTxAmount;
    }

    function getMaxTxAmount() external view returns (uint256) {
        return _maxTxAmount;
    }

    function setNumTokensSellToAddToLiquidity(uint256 newNumTokensSellToAddToLiquidity) external onlyOwner {
        _numTokensSellToAddToLiquidity = newNumTokensSellToAddToLiquidity;
    }

    function getNumTokensSellToAddToLiquidity() external view returns (uint256) {
        return _numTokensSellToAddToLiquidity;
    }    

    function setCooldown(bool isEnabled) external onlyOwner {
        _coolDownEnabled = isEnabled;
    }    

    function getCooldown() external view returns (bool) {
        return _coolDownEnabled;
    }    

    function setExcludedFromFee(address account, bool isExcluded) external onlyOwner {
        _isExcludedFromFee[account] = isExcluded;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setExcludedFromReward(address account, bool isExcluded) external onlyOwner {
        if(isExcluded) {
            require(!_isExcluded[account], "Account already excluded");
            
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else {
            require(_isExcluded[account],  "Account already included");
            
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
        
        _isExcluded[account] = isExcluded;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function setRouter(IUniswapV2Router02 newRouter) external onlyOwner {
        _uniswapV2Router = newRouter;
    }

    function getRouter() external view returns (address) {
        return address(_uniswapV2Router);
    }

    function setPair(address newPair) external onlyOwner {
        _uniswapV2Pair = newPair;
    }

    function getPair() external view returns (address) {
        return _uniswapV2Pair;
    }

    function setSwapAndLiquify(bool isEnabled) external onlyOwner {
        _swapAndLiquifyEnabled = isEnabled;
    } 

    function getSwapAndLiquify() external view returns (bool) {
        return _swapAndLiquifyEnabled;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(spender != address(0), "ERC20: approve to zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(to != address(0), "ERC20: transfer to zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
        }

        if (_coolDownEnabled && from == _uniswapV2Pair && !_isExcludedFromFee[to]) {
            require(_setCoolDown[to] < block.timestamp);
            _setCoolDown[to] = block.timestamp + (30 seconds);
        }

        if(_swapAndLiquifyEnabled) {
            bool readyToSwapAndLiquify = (balanceOf(address(this)) >= _numTokensSellToAddToLiquidity);
            if (readyToSwapAndLiquify && !_inSwapAndLiquify && to == _uniswapV2Pair) {
                _swapAndLiquify(_numTokensSellToAddToLiquidity);
            }
        }

        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function _swapAndLiquify(uint256 amount) private lockTheSwap {
        require(amount <= balanceOf(address(this)), "Swap amount exceeds the contract balance");
        if(_liqTax == 0 && _charityTax == 0 && _marketingTax == 0) return;

        // optimize function to call swap only once
        uint256 initialBalance = address(this).balance;
        uint256 swapAmount = amount * ((_liqTax / 2) + _charityTax + _marketingTax) / (_liqTax + _charityTax + _marketingTax);
        uint256 liqAmount = amount - swapAmount;
        _swapTokensForETH(swapAmount);

        uint256 newBalance = address(this).balance;
        uint256 balanceDifference = newBalance - initialBalance;

        if(liqAmount > 0) {
            // send whole balance difference to the pool. the rest will be refunded
            _addLiquidity(liqAmount, balanceDifference);

            // pass real share that was swapped for liquidity and real eth amount that
            // was taken by the pool
            emit SwapAndLiquify(liqAmount,
                                newBalance - address(this).balance, 
                                liqAmount);
        }

        // whatever eth left send it to charity and for marketing 
        // (assumed that the most of the eth that wasn't needed was refunded by the pool) 
        // charity/marketing share ratio is respected
        if(_charityWallet == _marketingWallet) {
            _charityWallet.transfer(address(this).balance);
        } else {
            _charityWallet.transfer(address(this).balance * _charityTax / (_charityTax + _marketingTax));
            _marketingWallet.transfer(address(this).balance);
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) _removeAllFee();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee,
         uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(amount);
        
        if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            // standard transfer, both parties are subject to fees
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
            // transfer to excluded from fees
            _tOwned[sender]    = _tOwned[sender]    - amount;
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            // transfer from excluded from fees
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        } else {
            // transfer from excluded to excluded from fees
            _tOwned[sender]    = _tOwned[sender]    - amount;
            _rOwned[sender]    = _rOwned[sender]    - rAmount;
            _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
            _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        }

        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);

        if (!takeFee) _restoreAllFee();
    }
}

// SPDX-License-Identifier: GPL3.0

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: GPL3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}