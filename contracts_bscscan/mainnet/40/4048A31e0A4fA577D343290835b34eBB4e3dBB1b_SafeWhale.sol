/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
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

contract SafeWhale is Context, IERC20, Ownable {
    using Address for address;
    
    address public constant BURN_ADDRESS =
    0x000000000000000000000000000000000000dEaD;
    
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    address payable public _prizePoolAddress;
    address payable public _marketingWalletAddress;

    uint256 public taxFee = 10; 
    uint256 public prizeFee = 30;
    uint256 public marketingFee = 20;
    uint256 public liquidityFee = 90;
    
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    uint256 private constant _MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000 * 10**18;
    uint256 private _rTotal = (_MAX - (_MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    string  private _name = "SafeWhale";
    string  private _symbol = "SWHAL";
    uint8   private _decimals = 18;
    
    uint256 private _previousTaxFee = taxFee;
    uint256 private _previousPrizeFee = prizeFee;
    uint256 private _previousMarketingFee = marketingFee;
    uint256 private _previousLiquidityFee = liquidityFee;
    
    uint256 private _reflectedTotal;
    uint256 private _holdersTotal;
    uint256 private _burnedTotal;
    
    uint256 private _maxTxAmount = 5000000 * 10**18;
    uint256 private _numTokensSellToAddToLiquidity = 100000 * 10**18;
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor (
        address payable marketingWalletAddress, 
        address payable prizePoolAddress) {
            
        _prizePoolAddress = prizePoolAddress;
        _marketingWalletAddress = marketingWalletAddress;
        
        _rOwned[owner()] = _rTotal;
        _holdersTotal++;
        
        IUniswapV2Router02 _uniswapV2Router = 
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());
            
        uniswapV2Router = _uniswapV2Router;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(_marketingWalletAddress)] = true;
        _isExcludedFromFee[address(_prizePoolAddress)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }
    
    receive() external payable {}
    
    function setTaxFeePercent(uint256 newFee) external onlyOwner() {
        taxFee = newFee;
    }
    function setMarketingFeePercent(uint256 newFee) external onlyOwner() {
        marketingFee = newFee;
    }
    function setPrizePoolFeePercent(uint256 newFee) external onlyOwner() {
        prizeFee = newFee;
    }
    function setLiquidityFeePercent(uint256 newFee) external onlyOwner() {
        liquidityFee = newFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = (_tTotal * maxTxPercent) / 10**3;
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    function setLiquiditySwapTrigger(uint256 amount) external onlyOwner {
        _numTokensSellToAddToLiquidity = amount;
    }
    
    function setmaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxAmount = maxTxAmount;
    }
    function setMarketingWalletAddress(address payable marketingWalletAddress) external onlyOwner() {
            _marketingWalletAddress = marketingWalletAddress;
    }
    function setPrizePoolWalletAddress(address payable prizeWalletAddress) external onlyOwner() {
            _prizePoolAddress = prizeWalletAddress;
    }
    
    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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
    function excludeFromFee(address account) external onlyOwner {
    _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function getHoldersTotal() external view returns (uint256) {
        return _holdersTotal;
    }
    function getReflectedTotal() external view returns (uint256) {
        return _reflectedTotal;
    }
    function getBurnedTotal() external view returns (uint256) {
        return balanceOf(BURN_ADDRESS);
    }
    
    function getLiquidityUSDT() external view returns (uint256) {
        address USDT = 0x55d398326f99059fF775485246999027B3197955;
        uint256 total = _calculateLiquidityBNB() + uniswapV2Pair.balance;
         
        if (total == 0) {
            return 0; 
        } else {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = USDT; 
        
            uint256[] memory amountOutMins = IUniswapV2Router02(uniswapV2Router).getAmountsOut(total, path);
            return amountOutMins[path.length -1];  
        }
    }  
    function getBurnedUSDT() external view returns (uint256) {
        address USDT = 0x55d398326f99059fF775485246999027B3197955;
        uint256 total = _calculateTokenBNB(BURN_ADDRESS);
         
        if (total == 0) {
            return 0; 
        } else {
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = USDT; 
        
            uint256[] memory amountOutMins = IUniswapV2Router02(uniswapV2Router).getAmountsOut(total, path);
            return amountOutMins[path.length -1];  
        }
    }  
    
    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
            (uint256 rAmount,, ) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
            // (uint256 rAmount,,,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
            (, uint256 rTransferAmount,) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
            // (,uint256 rTransferAmount,,,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
        (uint256 rAmount, , ) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
        // (uint256 rAmount,,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }    
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
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
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }
    function _takeMarketing(uint256 tMarketing, address sender) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = tMarketing * currentRate;
        _rOwned[_marketingWalletAddress] = _rOwned[_marketingWalletAddress] + rMarketing;
        if(_isExcluded[_marketingWalletAddress])
            _tOwned[_marketingWalletAddress] = _tOwned[_marketingWalletAddress] + tMarketing;
        emit Transfer(sender, _marketingWalletAddress, tMarketing);
    }
    function _takePrizePool(uint256 tPrizePool, address sender) private {
        uint256 currentRate =  _getRate();
        uint256 rPrizePool = tPrizePool * currentRate;
        _rOwned[_prizePoolAddress] = _rOwned[_prizePoolAddress] + rPrizePool;
        if(_isExcluded[_prizePoolAddress])
            _tOwned[_prizePoolAddress] = _tOwned[_prizePoolAddress] + tPrizePool;
        emit Transfer(sender, _prizePoolAddress, tPrizePool);
    }
    
    function removeAllFee() private {
        if (taxFee == 0 && liquidityFee == 0 && prizeFee == 0 && marketingFee == 0) return;
        
        _previousTaxFee = taxFee;
        _previousPrizeFee = prizeFee;
        _previousMarketingFee = marketingFee;
        _previousLiquidityFee = liquidityFee;
        
        taxFee = 0;
        prizeFee = 0;
        marketingFee = 0;
        liquidityFee = 0;
    }
    function restoreAllFee() private {
        taxFee = _previousTaxFee;
        prizeFee = _previousPrizeFee;
        marketingFee = _previousMarketingFee;
        liquidityFee = _previousLiquidityFee;
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
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
            contractTokenBalance = _numTokensSellToAddToLiquidity;
            _swapAndLiquify(contractTokenBalance);
        }
        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        _trackHolders(from, to);
        _tokenTransfer(from,to,amount,takeFee);
    }
    
    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 half = contractTokenBalance / 2;
        uint256 otherHalf = contractTokenBalance - half;
        uint256 initialBalance = address(this).balance;
        _swapTokensForEth(half);
        uint256 newBalance = address(this).balance - initialBalance;
        _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
    function _swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }
    
    function _trackHolders(address sender, address recipient) private {
            if (balanceOf(sender) == 0) _holdersTotal--;
            if (balanceOf(recipient) == 0) _holdersTotal++;
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
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
        if(!takeFee)
            restoreAllFee();
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getValues(tAmount);
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _takePrizePool(tPrizePool, sender);
        _reflectFee(rFee, tFee);
        _reflectedTotal += tFee;
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getValues(tAmount);
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _takePrizePool(tPrizePool, sender);
        _reflectFee(rFee, tFee);
        _reflectedTotal += tFee;
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getValues(tAmount);
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _takePrizePool(tPrizePool, sender);
        _reflectFee(rFee, tFee);
        _reflectedTotal += tFee;
        emit Transfer(sender, recipient, tTransferAmount);
    }
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
    // (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getValues(tAmount);
    (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool) = _getTValues(tAmount);
    (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tMarketing, tPrizePool, _getRate());
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;        
        _takeLiquidity(tLiquidity);
        _takeMarketing(tMarketing, sender);
        _takePrizePool(tPrizePool, sender);
        _reflectFee(rFee, tFee);
        _reflectedTotal += tFee;
    emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee = _calculateTaxFee(tAmount);
        uint256 tLiquidity = _calculateLiquidityFee(tAmount);
        uint256 tMarketing = _calculateMarketingFee(tAmount);
        uint256 tPrizePool = _calculatePrizePoolFee(tAmount);
        uint256 tempTransferAmount = tAmount - tFee - tLiquidity;
        uint256 tTransferAmount = tempTransferAmount - tMarketing - tPrizePool;
        
        return (tTransferAmount, tFee, tLiquidity, tMarketing, tPrizePool);
    }
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tPrizePool, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rMarketing = tMarketing * currentRate;
        uint256 rPrizePool = tPrizePool * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity - rMarketing - rPrizePool;
        return (rAmount, rTransferAmount, rFee);
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
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }
    
    function _calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * taxFee) / 10**3;
    }
    function _calculateMarketingFee(uint256 _amount) private view returns (uint256) {
        return (_amount * marketingFee) / 10**3;
    }
    function _calculatePrizePoolFee(uint256 _amount) private view returns (uint256) {
        return (_amount * prizeFee) / 10**3;
    }
    function _calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return (_amount * liquidityFee) / 10**3;
    }
    
    function _calculateLiquidityBNB() private view returns (uint256) {
        address env = address(this);
        uint256 pool = IERC20(env).balanceOf(uniswapV2Pair);
         
        if (pool == 0) {
            return 0; 
        } else {
            address[] memory path = new address[](2);
            path[0] = env;
            path[1] = uniswapV2Router.WETH(); 
        
            uint256[] memory amountOutMins = IUniswapV2Router02(uniswapV2Router).getAmountsOut(pool, path);
            return amountOutMins[path.length -1];  
        }
    }  
    function _calculateTokenBNB(address dst) private view returns (uint256) {
        address env = address(this);
        uint256 pool = IERC20(env).balanceOf(dst);
         
        if (pool == 0) {
            return 0; 
        } else {
            address[] memory path = new address[](2);
            path[0] = env;
            path[1] = uniswapV2Router.WETH(); 
        
            uint256[] memory amountOutMins = IUniswapV2Router02(uniswapV2Router).getAmountsOut(pool, path);
            return amountOutMins[path.length -1];  
        }
    }  
    

}