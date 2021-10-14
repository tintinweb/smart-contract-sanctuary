/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.3;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        if (a == 0) { return 0; }

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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is still locked");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
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


contract SkyRocket is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool)    private _isExcludedFromFee;
    mapping (address => bool)    private _isExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) public _isExcludedFromAutoLiquidity;
    mapping (address => bool) public _isExcludedToAutoLiquidity;

    address[] private _excluded;
    address public _marketingWallet = 0x7d01E482d6a9417CaCB8Dd3e222f48FEa971fee6;
    address public _devWallet       = 0x6Abc06ce06acde536E8e6C8d5028A80F32C98E9D; 
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**9; // 1,000,000,000,000 Trillion
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name     = "TestToken";
    string private constant _symbol   = "TT";
    uint8  private constant _decimals =  9;

    // Buy tax 
    uint256 private _buyTaxFee       = 300;
    uint256 private _buyLiquidityFee = 400;
    uint256 private _buyMarketingFee = 100;
    uint256 private _buyDevFee       = 100;

    // Sell tax 
    uint256 private _sellTaxFee       = 900; 
    uint256 private _sellLiquidityFee = 1200;
    uint256 private _sellMarketingFee = 300;
    uint256 private _sellDevFee       = 300;

    uint256 public _taxFee;
    uint256 public _liquidityFee;
    uint256 public _marketingFee;
    uint256 public _devFee;

    uint256 private _previousTaxFee;
    uint256 private _previousLiquidityFee;
    uint256 private _previousMarketingFee;
    uint256 private _previousDevFee;

    uint256 public _maxWalletBalance              = 5000000000 * 10**9; //  5,000,000,000 (5 billions - 0,5% of total supply)
    uint256 public _numTokensSellToAddToLiquidity = 2000000 * 10**9;      //  2,000,000 (2 Million)
    uint256 public _doubleFeeLimit                = 1500000000 * 10**9; // 1,500,000,000 (1.5 billion - 0,15% of total supply)

    
    // liquidity
    bool public  _swapAndLiquifyEnabled = true;
    bool public  _sellFeeEnabled = true;
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
    
    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }
    
    constructor () Ownable(_msgSender()) {

        _rOwned[_msgSender()] = _rTotal;

        _taxFee = _buyTaxFee;
        _previousTaxFee = _taxFee;

        _liquidityFee = _buyLiquidityFee;
        _previousLiquidityFee = _liquidityFee;

        _marketingFee = _buyMarketingFee;
        _previousMarketingFee = _marketingFee;

        _devFee = _buyDevFee;
        _previousDevFee = _devFee;
        
        // Create a uniswap pair for this new token
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        _uniswapV2Pair =    IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Router = uniswapV2Router;

        // exclude system addresses from fee
        _isExcludedFromFee[_msgSender()]     = true;
        _isExcludedFromFee[address(this)]    = true;
        _isExcludedFromFee[_marketingWallet] = true;

        _isExcludedFromAutoLiquidity[_uniswapV2Pair]            = true;
        _isExcludedFromAutoLiquidity[address(_uniswapV2Router)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
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

        (, uint256 tFee, uint256 tLiquidity, uint256 tMarketing , uint256 tDev) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tMarketing , tDev, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal         = _rTotal.sub(rAmount);
        _tFeeTotal      = _tFeeTotal.add(tAmount);
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");

        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (uint256 rAmount,,) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tDev, currentRate);

            return rAmount;

        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev) = _getTValues(tAmount);
            uint256 currentRate = _getRate();
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tDev, currentRate);

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
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    function setBuyTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _buyTaxFee = taxFee;
    }
    
    function setSellTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _sellTaxFee = taxFee;
    }
    
    function setBuyLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _buyLiquidityFee = liquidityFee;
    }
    
    function setSellLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _sellLiquidityFee = liquidityFee;
    }
    
    function setBuyMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _buyMarketingFee = marketingFee;
    }
    
    function setSellMarketingFeePercent(uint256 marketingFee) external onlyOwner() {
        _sellMarketingFee = marketingFee;
    }
    function setBuyDevFeePercent(uint256 devFee) external onlyOwner(){
        _buyDevFee = devFee;
    }

    function setSellDevFeePercent(uint256 devFee) external onlyOwner(){
        _sellDevFee = devFee;
    }
    function setMaxWalletBalance(uint256 maxWalletBalance) external onlyOwner {
        _maxWalletBalance = _tTotal.mul(maxWalletBalance).div(100);
    }
    function setMinTokenForLiquidity(uint256 minLiquidityPercent) external onlyOwner {
        _numTokensSellToAddToLiquidity = minLiquidityPercent * 10**9;
    }
    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        _swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }
    function setSellFeeEnabled(bool enabled) external onlyOwner{
        _sellFeeEnabled = enabled;
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
    function setUniswapRouter(address r) external onlyOwner {
        IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(r);
        _uniswapV2Router = uniswapV2Router;
    }
    function setUniswapPair(address p) external onlyOwner {
        _uniswapV2Pair = p;
    }
    function setMarketingWallet(address m) external onlyOwner {
        _marketingWallet = m;
    }
    function setDevWallet(address d) external onlyOwner {
        _devWallet = d;
    }
    function setDoubleFeeLimit(uint256 limit) external onlyOwner{
        _doubleFeeLimit = limit * 10**9;
    }

    // TRANSFER
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        if(owner() != to && _uniswapV2Pair != to){
            require(balanceOf(to).add(amount) <= _maxWalletBalance, 'Balance is exceeding maxWalletBalance');
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
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
        else {

            if (from == _uniswapV2Pair) { // Buy
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee;
                _marketingFee = _buyMarketingFee;
                _devFee       = _buyDevFee;
                }
                 else if (to == _uniswapV2Pair && _sellFeeEnabled){ // Sell
                _taxFee = _sellTaxFee;
                _liquidityFee = _sellLiquidityFee;
                _marketingFee = _sellMarketingFee;
                _devFee       = _sellDevFee;
                }
                else if(to == _uniswapV2Pair && amount >= _doubleFeeLimit) { // double fee limit
                _taxFee = _buyTaxFee.mul(2);
                _liquidityFee = _buyLiquidityFee.mul(2);
                _marketingFee = _buyMarketingFee.mul(2);
                _devFee       = _buyDevFee.mul(2);
                }
                 else { // other
                _taxFee = _buyTaxFee;
                _liquidityFee = _buyLiquidityFee;
                _marketingFee = _buyMarketingFee;
                _devFee       = _buyDevFee;
                }
        }
        
        _tokenTransfer(from, to, amount, takeFee);
    }


    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

         // Calculate the fees
        uint256 tFee = _devFee.add(_liquidityFee);

         // Calculate the token for swaping and liquidity
        uint256 devTokens = contractTokenBalance.div(tFee).mul(_devFee);
        uint256 liquidityTokens = contractTokenBalance.sub(devTokens);

        // Update the fees
        tFee = _devFee.add(_liquidityFee.div(2));

        // split contract balance into halves
        uint256 half      = liquidityTokens.div(2);
        uint256 otherHalf = liquidityTokens.sub(half);

        uint256 initialBalance = address(this).balance;

        uint256 swapTokens = devTokens.add(half);

        // swap tokens for BNB
        swapTokensForBnb(swapTokens);

        // this is the amount of BNB that we just swapped into
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // Send funds to dev wallet into bnb
        uint256 devFunds = newBalance.div(tFee).mul(_devFee);
        (bool success, ) = payable(_devWallet).call{
            value: devFunds,
            gas: 30000
        }("");
        require(success, " _devWallet transfer is reverted");

        // Calculate funds for liquidity
        uint256 halfFunds = newBalance.div(tFee).mul(_liquidityFee.div(2));

        // add liquidity to uniswap
        addLiquidity(otherHalf, halfFunds);
        
        emit SwapAndLiquify(half, halfFunds, otherHalf);
    }
    function swapTokensForBnb(uint256 tokenAmount) private {
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
            address(this),
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
            owner(),
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
         (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tDev, currentRate);

        _rOwned[sender]    = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this),tLiquidity.add(tDev), currentRate);
        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
         (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tDev, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity.add(tDev),currentRate);
        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tDev, currentRate);

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity.add(tDev), currentRate);
        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tDev, currentRate);

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);

        takeTransactionFee(address(this), tLiquidity.add(tDev), currentRate);
        takeTransactionFee(_marketingWallet, tMarketing, currentRate);
        reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal    = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0 && _devFee == 0) return;
        
        _previousTaxFee       = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousDevFee       = _devFee;
        
        _taxFee       = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _devFee       = 0;
    }

    function doubleAllFee() private{
        if (_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0 && _devFee == 0) return;
        
        _previousTaxFee       = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousDevFee       = _devFee;
        
        _taxFee       = _taxFee * 2;
        _liquidityFee = _liquidityFee * 2;
        _marketingFee = _marketingFee * 2;
        _devFee       = _devFee * 2;
    }

    function restoreAllFee() private {
        _taxFee       = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _devFee       = _previousDevFee;
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256,uint256) {
        uint256 tFee       = tAmount.mul(_taxFee).div(10000);
        uint256 tLiquidity = tAmount.mul(_liquidityFee).div(10000);
        uint256 tMarketing = tAmount.mul(_marketingFee).div(10000);
        uint256 tDev       = tAmount.mul(_devFee).div(10000);
        uint256 tTransferAmount = tAmount.sub(tFee);
        tTransferAmount = tTransferAmount.sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tMarketing);
        tTransferAmount = tTransferAmount.sub(tDev);
        return (tTransferAmount, tFee, tLiquidity, tMarketing , tDev);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDev , uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount     = tAmount.mul(currentRate);
        uint256 rFee        = tFee.mul(currentRate);
        uint256 rLiquidity  = tLiquidity.mul(currentRate);
        uint256 rMarketing  = tMarketing.mul(currentRate);
        uint256 rDev        = tDev.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        rTransferAmount = rTransferAmount.sub(rLiquidity);
        rTransferAmount = rTransferAmount.sub(rMarketing);
        rTransferAmount = rTransferAmount.sub(rDev);
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
}