/**
 *Submitted for verification at Etherscan.io on 2021-08-09
*/

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/access/[email protected]

pragma solidity ^0.8.0;

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


// File contracts/interfaces/IUniswapV2Router01.sol

pragma solidity ^0.8.4;

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


// File contracts/interfaces/IUniswapV2Router02.sol

pragma solidity ^0.8.4;

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


// File contracts/interfaces/IUniswapV2Factory.sol

pragma solidity ^0.8.4;

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


// File contracts/Momento.sol

pragma solidity ^0.8.4;



contract Momento is IERC20, Ownable {
    struct User {
        uint256 buy;
        uint256 sell;
    }

    address public marketingAddress = payable(0xCfc5835d709A837d7445C0a881c293fF58309d5a);
    address public teamAddress = payable(0x857ed7E7b4C40F29CB7391FCF88EAc76BD284032);
    address public constant deadAddress = 0x000000000000000000000000000000000000dEaD;

    uint256 private _rTeamLock;

    uint256 public teamUnlockTime;
    uint8 public teamUnlockCount;
    uint256 private _rTeamUnlockTokenCount;

    uint256 private _rBurnLock;
    uint256 private _tBurnLock;

    mapping(address => User) private _cooldown;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    // mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isUniswapV2Pair;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    uint256 private _holderCount;
    uint256 private _lastMaxHolderCount = 99;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Momento";
    string private _symbol = "MOMENTO";
    uint8 private _decimals = 9;
    
    uint256 public _taxFee = 5;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _liquidityFee = 5;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _marketingFee = 1;
    uint256 private _previousMarketingFee = _marketingFee;
    
    uint256 public _buyBackFee = 4;
    uint256 private _previousBuyBackFee = _buyBackFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 5000000000 * 10**9;
    uint256 private numTokensSellToAddToLiquidity = 500000000 * 10**9;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor() {
        // 1% of total reflection supply
        uint256 onePercentR = _rTotal / 100;
        // 1% of total t supply
        uint256 onePercentT = _tTotal / 100;

        // add 60% of tokens to owner(for adding to liquidity pool)
        _rOwned[_msgSender()] = onePercentR * 60;
        // add 5% of tokens to marketing address
        _rOwned[marketingAddress] = onePercentR * 5;
        // lock 10% of tokens for burning further
        _rBurnLock = onePercentR * 10;
        _tBurnLock = onePercentT * 10;
        // lock 3% of tokens for team for 6 months and vested over 18 months
        _rTeamLock = onePercentR * 3;

        _rTeamUnlockTokenCount = _rTeamLock / 18;

        teamUnlockTime = block.timestamp + 180 days;

        // burning 10% of totalsupply
        _rTotal = onePercentR * 78;
        _tTotal = onePercentT * 78;


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        
        // exclude owner and this contract from fee
        // _isExcludedFromFee[owner()] = true;
        // _isExcludedFromFee[address(this)] = true;

        _isUniswapV2Pair[uniswapV2Pair] = true;

        emit Transfer(address(0), _msgSender(), onePercentT * 60);
        emit Transfer(address(0), marketingAddress, onePercentT * 5);
        emit Transfer(address(0), deadAddress, onePercentT * 32);
        emit Transfer(deadAddress, address(0), onePercentT * 22);
    }

    function unlockTeam() public {
        require(_msgSender() == teamAddress, "Function can be called only with team address");
        require(block.timestamp > teamUnlockTime, "Fucntion can be called only if teamUnlockTime has passed");
        require(teamUnlockCount < 18, "You are already unlocked all tokens");
        uint256 difference = block.timestamp - teamUnlockTime;
        uint256 monthCount = difference / 30 days;
        uint8 remainingMonths = 18 - teamUnlockCount;
        if (monthCount > remainingMonths) monthCount = remainingMonths;
        uint amountToTransfer = monthCount * _rTeamUnlockTokenCount;
        _rOwned[teamAddress] += amountToTransfer;
        teamUnlockCount += uint8(monthCount);
        teamUnlockTime += monthCount * 30 days;
        emit Transfer(address(0), teamAddress, tokenFromReflection(amountToTransfer));
    }

    function setMarketingAddress(address _markeingAddress) public onlyOwner {
        marketingAddress = _markeingAddress;
    }

    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }

    function _burnTenPercent() private {
        if (_tBurnLock != 0) {
            uint256 tBurnCount = _tBurnLock / 10;
            uint256 rBurnCount = _rBurnLock / 10;
            if (tBurnCount == 0) {
                tBurnCount = _tBurnLock;
                rBurnCount = _rBurnLock;
            }
            _tBurnLock -= tBurnCount;
            _rBurnLock -= rBurnCount;
            _tTotal -= tBurnCount;
            _rTotal -= rBurnCount;
            emit Transfer(deadAddress, address(0), tBurnCount);
        }
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
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

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketing, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBuyBack) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;        
        _rOwned[marketingAddress] += rMarketing;
        _tOwned[deadAddress] += tBuyBack;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    // function excludeFromFee(address account) public onlyOwner {
    //     _isExcludedFromFee[account] = true;
    // }
    
    // function includeInFee(address account) public onlyOwner {
    //     _isExcludedFromFee[account] = false;
    // }
    
    function addUniswapV2PairAddress(address account) public onlyOwner {
        _isUniswapV2Pair[account] = true;
    }
    
    function removeUniswapV2PairAddress(address account) public onlyOwner {
        _isUniswapV2Pair[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
   
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal * maxTxPercent / 100;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        uint256[5] memory tValues = _getTValues(tAmount);
        uint256[4] memory rValues = _getRValues(tAmount, tValues[0], tValues[1], tValues[2], tValues[3], _getRate());

        return (rValues[0], rValues[3], rValues[1], rValues[2], tValues[4], tValues[0], tValues[1], tValues[3]);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256[5] memory) {
        uint256[5] memory tValues;
        tValues[0] = calculateTaxFee(tAmount); // tFee
        tValues[1] = calculateLiquidityFee(tAmount); // tLiquidity
        tValues[2] = calculateMarketingFee(tAmount); // tMarketing
        tValues[3] = calculateBuyBackFee(tAmount); // tBuyBack
        tValues[4] = tAmount - tValues[0] - tValues[1] - tValues[2] - tValues[3]; // tTrasnferAmount
        return tValues;
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tBuyBack, uint256 currentRate) private pure returns (uint256[4] memory) {
        uint256[4] memory rValues;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rBuyBack = tBuyBack * currentRate;
        rValues[0] = tAmount * currentRate; // rAmount
        rValues[1] = tFee * currentRate; // rFee
        rValues[2] = tMarketing * currentRate; // rMarketing
        rValues[3] = rValues[0] - rValues[1] - rLiquidity - rValues[2] - rBuyBack; // rTransferAmount
        return rValues;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        }
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 100;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 100;
    }

    function calculateMarketingFee(uint256 _amount) private view returns(uint256) {
        return _amount * _marketingFee / 100;
    }

    function calculateBuyBackFee(uint256 _amount) private view returns(uint256) {
        return _amount * _buyBackFee / 100;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _marketingFee == 0 && _buyBackFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousMarketingFee = _marketingFee;
        _previousBuyBackFee = _buyBackFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _buyBackFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _marketingFee = _previousMarketingFee;
        _buyBackFee = _previousBuyBackFee;
    }
    
    // function isExcludedFromFee(address account) public view returns(bool) {
    //     return _isExcludedFromFee[account];
    // }
    
    function isUniswapV2PairAddress(address account) public view returns(bool) {
        return _isUniswapV2Pair[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner()) {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }


        if (balanceOf(to) == 0) _holderCount++;

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));
        
        if(contractTokenBalance >= _maxTxAmount) {
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
        bool takeFee;
        
        // buy
        if (_isUniswapV2Pair[from] && to != address(uniswapV2Router)) {
            takeFee = true;
            uint256 timestamp = block.timestamp;
            require(_cooldown[from].buy < timestamp, "You can transfer tokens once in 15 seconds");
            _cooldown[from].buy = timestamp + 30;
        } 
        // sell 
        else if (_isUniswapV2Pair[to]) {
            takeFee = true;
            uint256 timestamp = block.timestamp;
            require(_cooldown[to].sell < timestamp, "You can transfer tokens once in 15 seconds");
            _cooldown[to].sell = timestamp + 30;
        }

        // //if any account belongs to _isExcludedFromFee account then remove the fee
        // if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
        //     takeFee = false;
        // }
        
        // transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from,to,amount,takeFee);

        if (balanceOf(from) == 0) _holderCount--;
        if (_holderCount > _lastMaxHolderCount) {
            _burnTenPercent();
            _lastMaxHolderCount += 100;
        }
        if (address(this).balance >= 0.2 ether) {
            _buyBackAndBurn(address(this).balance);
        }
    }

    function _buyBackAndBurn(uint256 amount) private lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: amount }(
            0, // accept any amount of Tokens
            path,
            deadAddress, // Burn address
            block.timestamp
        );

        emit SwapETHForTokens(amount, path);

        // burn
        uint256 balance = balanceOf(deadAddress);
        if (balance > 0) {
            _rTotal -= _rOwned[deadAddress];
            _tTotal -= balance;
            _rOwned[deadAddress] = 0;
            emit Transfer(deadAddress, address(0), balance);
        }
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if(!takeFee) {
            removeAllFee();
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
        
        if(!takeFee) {
            restoreAllFee();
        }
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketing, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBuyBack) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;
        _rOwned[marketingAddress] += rMarketing;
        _tOwned[deadAddress] += tBuyBack;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketing, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBuyBack) = _getValues(tAmount);
        _rOwned[sender] -= rAmount;
        _tOwned[recipient] += tTransferAmount;
        _rOwned[recipient] += rTransferAmount;
        _rOwned[marketingAddress] += rMarketing;
        _tOwned[deadAddress] += tBuyBack;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 rMarketing, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBuyBack) = _getValues(tAmount);
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= rAmount;
        _rOwned[recipient] += rTransferAmount;   
        _rOwned[marketingAddress] += rMarketing;
        _tOwned[deadAddress] += tBuyBack;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}