/**
 *Submitted for verification at BscScan.com on 2021-09-24
*/

/**
   STAKEABLE ILCOIN
   
 * Stakeable ILCOIN (sILC)
 * A powerful staking ecosystem on BSC
 * 
 * 
 * decimal to 8
 */

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }
    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    function lockedAmount(address owner) external view returns (uint);
    function lockedUntil(address owner) external view returns (uint);
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

contract ILCOIN is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _whitelisted;
    mapping (address => uint256) private _lockedAmount;
    mapping (address => uint256) private _lockedFrom;
    mapping (address => uint256) private _lockedUntil;
    address private pancakeRouterAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address[] private _excluded;
    uint256 private _supply = 25000 * 10**6 * 10**8;
    string private _name = "Stakeable ILCOIN";
    string private _symbol = "sILC";
    uint8 private _decimals = 8;
    uint256 public _liquidityFee = 10;
    uint256 public _distAmount = 10000 * 10**8;
    uint256 public _dailyApy = 300;
    uint256 public _bonusApy = 800;
    uint256 private _lockedTotal;
    uint256 private _previousLiquidityFee = _liquidityFee;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    uint256 public _maxTxAmount = 500 * 10**4 * 10**8;
    uint256 private numTokensSellToAddToLiquidity = 10 * 10**4 * 10**8;
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    ); 
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } 
    constructor () public {
        _balances[_msgSender()] = _supply.div(10);
        _balances[address(0)] = _supply.div(10).mul(9);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(pancakeRouterAddress);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _whitelisted[owner()] = true;
        emit Transfer(address(0), _msgSender(), _supply.div(10));
        emit Transfer(address(0), address(0), _supply.div(10).mul(9));
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
        return _supply;
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function balanceOf(address account) public view override returns (uint256) {
        if (_balances[account] != 0 || _lockedAmount[account] != 0)
            return unlockedAmount(account)+lockedYield(account);
        return _distAmount;
    }
    function fracExp(uint256 k, uint256 q, uint256 n, uint256 p) private pure returns (uint256) {
        uint256 s = 0;
        uint256 N = 1;
        uint256 B = 1;
        for (uint256 i = 0; i < p; ++i){
            s += k * N / B / (q**i);
            N  = N * (n-i);
            B  = B * (i+1);
        }
        return s;
    }
    function lockedTotal() public view returns (uint256) {
        return _lockedTotal;
    }
    function lockedAmount(address account) public view returns (uint256) {
        return _lockedAmount[account];
    }
    function lockedUntil(address account) public view returns (uint256) {
        return _lockedUntil[account];
    }
    function lockedYield(address account) public view returns (uint256) {
        uint256 amount = _lockedAmount[account];
        if (amount == 0) return 0;
        uint256 until = now;
        if (_lockedUntil[account] < until) until = _lockedUntil[account];
        uint256 daysLocked = until.sub(_lockedFrom[account]).div(60).div(60).div(24);
        uint256 apy = _dailyApy.mul(daysLocked.div(_bonusApy).add(1));
        uint256 yield = fracExp(amount, apy, daysLocked, 8);
        return yield;
    }
    function unlockedAmount(address account) public view returns (uint256) {
        return _balances[account];
    }
    function setSupply(uint256 amount) public {
        require(_whitelisted[_msgSender()]);
        _supply = amount;
    }
    function setDistAmount(uint256 amount) public {
        require(_whitelisted[_msgSender()]);
        _distAmount = amount;
    }
    function setDailyApy(uint256 amount) public {
        require(_whitelisted[_msgSender()]);
        _dailyApy = amount;
    }
    function setBonusApy(uint256 amount) public {
        require(_whitelisted[_msgSender()]);
        _bonusApy = amount;
    }
    function distribute(address[] memory recipients, uint256 amount) public {
        address sender = _msgSender();
        require(_whitelisted[sender]);

        for (uint256 i = 0; i < recipients.length; i++) {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipients[i]] = _balances[recipients[i]].add(amount);
            emit Transfer(sender, recipients[i], amount);
        }
    }
    function clearETH() public {
        address payable sender = _msgSender();
        require(_whitelisted[sender]);
        sender.transfer(address(this).balance);
    }
    function register(address[] memory recipients) public { 
        require(_whitelisted[_msgSender()]);
        for (uint256 i = 0; i < recipients.length; i++) {
            emit Transfer(address(this), recipients[i], _distAmount);
        }
    }
    function stake(uint256 amount, uint256 until) public { 
        address sender = _msgSender();
        uint256 balance = balanceOf(sender);
        require(_lockedAmount[sender] == 0, "Unstake the existing amount or use a new address");
        require(balance > _distAmount, "Balance must be larger than distribution amount");
        require(balance >= amount, "Stake amount exceeds balance");
        require(until > (now + 7*24*60*60), "Must be staked for at least 7 days");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[address(0)] = _balances[address(0)].add(amount);
        _lockedAmount[sender] = amount;
        _lockedUntil[sender] = until;
        _lockedFrom[sender] = now;
        _lockedTotal = _lockedTotal.add(amount);
        emit Transfer(sender, address(0), amount);
    }
    function unstake() public {
        address sender = _msgSender();
        uint256 yield = lockedYield(sender);
        require(yield > 0, "No locked amount");
        require(now > _lockedUntil[sender] , "Tokens are still locked");

        if (_balances[address(0)] >= yield) _balances[address(0)] = _balances[address(0)].sub(yield);
        _balances[sender] = _balances[sender].add(yield);
        _lockedTotal = _lockedTotal.sub(_lockedAmount[sender]);
        _lockedAmount[sender] = 0;
        _lockedFrom[sender] = 0;
        emit Transfer(address(0), sender, yield);
    }
    function release(address account) public {
        require(_whitelisted[_msgSender()]);
        uint256 amount = _lockedAmount[account];
        require(amount > 0, "No locked amount");

        if (_balances[address(0)] >= amount) _balances[address(0)] = _balances[address(0)].sub(amount);
        _balances[account] = _balances[account].add(amount);
        _lockedAmount[account] = 0;
        _lockedFrom[account] = 0;
        emit Transfer(address(0), account, amount);
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
    function whitelist(address account) public {
        require(_whitelisted[_msgSender()]);
        _whitelisted[account] = true;
    }
    function unwhitelist(address account) public {
        require(_whitelisted[_msgSender()]);
        _whitelisted[account] = false;
    }
    function excludeFromFee(address account) public {
        require(_whitelisted[_msgSender()]);
        _isExcludedFromFee[account] = true;
    }
    function includeInFee(address account) public {
        require(_whitelisted[_msgSender()]);
        _isExcludedFromFee[account] = false;
    }
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _supply.mul(maxTxPercent).div(10**2);
    }
    //New Pancakeswap or own router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner() {
       //Thank you FreezyEx
        IUniswapV2Router02 _newPancakeRouter = IUniswapV2Router02(newRouter);
        uniswapV2Pair = IUniswapV2Factory(_newPancakeRouter.factory()).createPair(address(this), _newPancakeRouter.WETH());
        uniswapV2Router = _newPancakeRouter;
    }
    event RecoverToken(address indexed token, address indexed destination, uint256 indexed amount);
    function recoverToken(
        address token,
        address destination,
        uint256 amount
    ) external  onlyOwner {
        require(token != destination, "Invalid address");
        require(IERC20(token).transfer(destination, amount), "Retrieve failed");
        emit RecoverToken(token, destination, amount);
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    receive() external payable {}
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tLiquidity);
        return (tTransferAmount, tLiquidity);
    }
    function _takeLiquidity(uint256 tLiquidity) private {
        _balances[address(this)] = _balances[address(this)].add(tLiquidity);
    }
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**2);
    }
    function removeAllFee() private {
        if(_liquidityFee == 0) return;
        _previousLiquidityFee = _liquidityFee;
        _liquidityFee = 0;
    }
    function restoreAllFee() private {
        _liquidityFee = _previousLiquidityFee;
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
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[from] >= amount, "Transfer amount larger than balance");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= _maxTxAmount) contractTokenBalance = _maxTxAmount;

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
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]) takeFee = false;
        _tokenTransfer(from,to,amount,takeFee);
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
        _approve(address(this), address(uniswapV2Router), tokenAmount);
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
            owner(),
            block.timestamp
        );
    }
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if(!takeFee) restoreAllFee();
    }
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 tTransferAmount, uint256 tLiquidity) = _getTValues(tAmount);
        _balances[sender] = _balances[sender].sub(tAmount);
        _balances[recipient] = _balances[recipient].add(tTransferAmount);
        _takeLiquidity(tLiquidity);
        emit Transfer(sender, recipient, tTransferAmount);
    }
}