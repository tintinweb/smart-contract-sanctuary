/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IBEP20 {

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (){
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

contract MAD is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    // Mappings for tracking
    mapping (address => uint256) public amountSoldTrack;
    mapping (address => uint256) public amountBlockToSellNext;
    uint256 public limitToSellBeforeBlockCooldown = 2000000 * 10**9; // Default: 0.2% of total Supply
    uint256 public _blocksToWait = 720;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isAdminAccount;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9; // 1 billion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "MAD Token";
    string private _symbol = "MAD";
    uint8 private _decimals = 9;

    uint256 private priceImpact = 5;

    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _marketingFee = 3;
    uint256 private _previousMarketingFee = _marketingFee;
    address public marketingAddr = 0x989554CBFf6fecc03c73B2f504AfE6493064ca7D;
    
    uint256 public _charityFee = 4;
    uint256 private _previousCharityFee = _charityFee;
    address public charityAddr = 0x7fd775Ac6745eEAE8Df2151424490B222A667Af7;

    uint256 public _liquidityFee = 0;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _maxAllowedBalanceAmount = 1000000000 * 10**9; //Default: 100% of totalSupply
    uint256 public _maxTxAmount = 2500000 * 10**9; // Default: 0.25% of totalSupply

    IUniswapV2Router02 public  uniswapV2Router;
    address public uniswapV2Pair;
    uint256 private numTokensSellToAddToLiquidity = 2500000 * 10**9; //0.25% of totalSupply
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    event Purchase(address indexed to, uint256 amount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
        _rOwned[_msgSender()] = _rTotal;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isAdminAccount[owner()] = true;
        _isAdminAccount[address(this)] = true;
        _isAdminAccount[uniswapV2Pair] = true;

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
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
    
    function addAdminAccount(address account) public onlyOwner() {
        _isAdminAccount[account] = true;
    }

    function removeAdminAccount(address account) public onlyOwner() {
        _isAdminAccount[account] = false;
    }

    function excludeFromFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner() {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        require(taxFee <= 10, "Percentage too high. Please use a lower percentage.");
        _taxFee = taxFee;
    }

    function setMarketingAddr(address addr) external onlyOwner() {
        marketingAddr = addr;
    }

    function setCharityAddr(address addr) external onlyOwner() {
        charityAddr = addr;
    }

    function setMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        require(marketingFee <= 10, "Percentage too high. Please use a lower percentage.");
        _marketingFee = marketingFee;
    }

    function setCharityFeePercent(uint256 charityFee) external onlyOwner() {
        require(charityFee <= 10, "Percentage too high. Please use a lower percentage.");
        _charityFee = charityFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        require(liquidityFee <= 10, "Percentage too high. Please use a lower percentage.");
        _liquidityFee = liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner() {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setMaxAllowedBalance(uint256 maxBalancePercent) external onlyOwner() {
        require(maxBalancePercent >= 1, "Percentage too low. Please use a higher percentage.");
        _maxAllowedBalanceAmount = _tTotal.mul(maxBalancePercent).div(
            10**2
        );
    }

    function getMaxAllowedBalance() public view returns(uint256) {
        return _maxAllowedBalanceAmount;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount >= 2000000 * 10**9, "Amount is too low. Please set a higher maxTxAmount.");
        _maxTxAmount = maxTxAmount;
    }

    function getMaxTxAmount() public view returns(uint256) {
        return _maxTxAmount;
    }

    function setSellLimitForBlockCooldown(uint256 SellLimitForBlockCooldown) external onlyOwner() {
        require(SellLimitForBlockCooldown >= 2000000 * 10**9, "Amount is too low. Please set a higher SellLimitForBlockCooldown.");
        limitToSellBeforeBlockCooldown = SellLimitForBlockCooldown;
    }

    function getLimitToSellBeforeBlockCooldown() public view returns(uint256) {
        return limitToSellBeforeBlockCooldown;
    }

    function setBlocksToWait(uint256 newBlocks) external onlyOwner() {
        require(newBlocks <= 8640, "Block wait time is too hight. Set it below than 8640 (12Hrs).");
        _blocksToWait = newBlocks;
    }

    function getBlocksToWait() public view returns(uint256) {
        return _blocksToWait;
    }

    receive() external payable {
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tMarketing, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tMarketing, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tMarketing, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 marketing = calculateMarketingFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(marketing).sub(tLiquidity);
        return (tTransferAmount, tFee, marketing, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 marketing, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rMarketing = marketing.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rMarketing);
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

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeMarketing(uint256 marketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = marketing.mul(currentRate);
        _rOwned[marketingAddr] = _rOwned[marketingAddr].add(rMarketing);
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(marketing);
    }

    function _takeCharity(uint256 charity) private {
        uint256 currentRate =  _getRate();
        uint256 rCharity = charity.mul(currentRate);
        _rOwned[charityAddr] = _rOwned[charityAddr].add(rCharity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_marketingFee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_charityFee).div(
            10**2
        );
    }

    function setPriceImpact(uint256 percent) external onlyOwner(){
        require(percent >= 1, "Price impact set too low");
        priceImpact = percent;
    }


    function removeAllFee() private {
        if(_taxFee == 0 && _marketingFee == 0 && _liquidityFee == 0 && _charityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousMarketingFee = _marketingFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCharityFee = _charityFee;

        _taxFee = 0;
        _marketingFee = 0;
        _liquidityFee = 0;
        _charityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _marketingFee = _previousMarketingFee;
        _liquidityFee = _previousLiquidityFee;
        _charityFee = _previousCharityFee;
    }

    function isAdminAccount(address account) public view returns(bool) {
        return _isAdminAccount[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        if (from != owner() && to != owner()) { // Owner can send to the zero address on demand.
            require(to != address(0), "ERC20: transfer to the zero address");
        }

        uint256 currentBalance = balanceOf(to);
        
        if(to == uniswapV2Pair && !_isAdminAccount[from]){
            require(amount <= balanceOf(uniswapV2Pair).mul(priceImpact).div(100) && amount <= _maxTxAmount);
            require(block.number >= amountBlockToSellNext[from], "You have sold or transferred too much recently. Please try to sell again later.");
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            amountSoldTrack[from] += amount;
        }

        if(to != uniswapV2Pair && !_isAdminAccount[to] && !_isAdminAccount[from]){
            require((currentBalance + amount) <= _maxAllowedBalanceAmount, "Account balance exceeds the maxAllowedBalanceAmount.");
            require(block.number >= amountBlockToSellNext[from], "You have sold or transferred too much recently. Please try to sell again later.");
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            amountSoldTrack[from] += amount;
        }

        if(from == uniswapV2Pair && !_isAdminAccount[to]) {
            require((currentBalance + amount) <= _maxAllowedBalanceAmount, "Account balance exceeds the maxAllowedBalanceAmount.");
        }

        
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        if(to == address(0)) {
            takeFee = false;
        }

        _tokenTransfer(from,to,amount,takeFee);

        if(amountSoldTrack[from] >= limitToSellBeforeBlockCooldown){
            amountBlockToSellNext[from] = block.number.add(_blocksToWait);
            amountSoldTrack[from] = 0;
        }
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForEth(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

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

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    //Call this function with true, before presale and false after presale and LQ is added on PCS.
    function setPresaleState(bool presale) external onlyOwner() {
        if (presale) {
            _taxFee = 0;
            _previousTaxFee = _taxFee;
            _liquidityFee = 0;
            _previousLiquidityFee = _liquidityFee;
            _marketingFee = 0;
            _previousMarketingFee = _marketingFee;
            _charityFee = 0;
            _previousCharityFee = _charityFee;
            inSwapAndLiquify = false;
            swapAndLiquifyEnabled = false;
            _maxTxAmount = _tTotal;
            emit SwapAndLiquifyEnabledUpdated(false);
        } else {
            _taxFee = 3;
            _previousTaxFee = _taxFee;
            _liquidityFee = 0;
            _previousLiquidityFee = _liquidityFee;
            _marketingFee = 3;
            _previousMarketingFee = _marketingFee;
            _charityFee = 4;
            _previousCharityFee = _charityFee;
            inSwapAndLiquify = true;
            swapAndLiquifyEnabled = true;
            _maxTxAmount = 2500000 * 10**9;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

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
    
    function setRouterAddress(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketing, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tCharityAmount = calculateCharityFee(tAmount);
        tTransferAmount = tTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(_liquidityFee);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _takeMarketing(marketing);
        _takeCharity(tCharityAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, marketingAddr, marketing);
        emit Transfer(sender, recipient, tTransferAmount.sub(tCharityAmount));
        emit Transfer(sender, charityAddr, tCharityAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketing, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tCharityAmount = calculateCharityFee(tAmount);
        tTransferAmount = tTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(_liquidityFee);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _takeMarketing(marketing);
        _takeCharity(tCharityAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, marketingAddr, marketing);
        emit Transfer(sender, recipient, tTransferAmount.sub(tCharityAmount));
        emit Transfer(sender, charityAddr, tCharityAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketing, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tCharityAmount = calculateCharityFee(tAmount);
        tTransferAmount = tTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(_liquidityFee);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _takeMarketing(marketing);
        _takeCharity(tCharityAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, marketingAddr, marketing);
        emit Transfer(sender, recipient, tTransferAmount.sub(tCharityAmount));
        emit Transfer(sender, charityAddr, tCharityAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 marketing, uint256 tLiquidity) = _getValues(tAmount);
        uint256 tCharityAmount = calculateCharityFee(tAmount);
        tTransferAmount = tTransferAmount.sub(tCharityAmount);
        rTransferAmount = rTransferAmount.sub(tCharityAmount);
        rAmount = rAmount.sub(tCharityAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _takeMarketing(marketing);
        _takeCharity(tCharityAmount);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, marketingAddr, marketing);
        emit Transfer(sender, recipient, tTransferAmount.sub(tCharityAmount));
        emit Transfer(sender, charityAddr, tCharityAmount);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

event Recovered(address token, uint256 amount);

}