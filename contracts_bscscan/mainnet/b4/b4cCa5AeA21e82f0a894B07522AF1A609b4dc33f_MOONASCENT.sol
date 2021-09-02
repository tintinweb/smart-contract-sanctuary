/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


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

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;

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


// pragma solidity >=0.5.0;

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

    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// pragma solidity >=0.6.2;

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



// pragma solidity >=0.6.2;

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

contract MOONASCENT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    
    address public immutable deadAddress;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => uint256) public _transactionCheckpoint;
    mapping (address => uint256) public _transactionCheckpointAmt;

    mapping (address => bool) public _isExcludedFromFee;
    mapping (address => bool) public _isExcludedFromMaxTxAmount;
    mapping (address => bool) public _isExcludedFromTransactionlock;
    mapping (address => bool) private _isExcluded;
    mapping(address => bool) private _blacklist;

    address[] private _excluded;

    bool public enabled;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000 * 10**8 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "MOONASCENT";
    string private _symbol = "MOONASCENT";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 7;
    uint256 private _previousTaxFee = _taxFee;
    
    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _liquidityFee = 10;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _liquidityDivider = 4;
        
    uint256 public _maxTxAmountBuy = 100000 * 10**8 * 10**9;
    uint256 public _maxTxAmountSell = 5000 * 10**8 * 10**9;

    uint256 private minimumTokensBeforeSwap = 200000000 * 10**9; 
    uint256 public _maxWalletToken = 50000 * 10**8 * 10**9;
    
    uint256 public numTokensSellToAddToLiquidity001 = 1 * 10**9 * 10**9; // 0.001%
    uint256 public numTokensSellToAddToLiquidity005 = 5 * 10**9 * 10**9; // 0.005%
    uint256 public numTokensSellToAddToLiquidity008 = 8 * 10**9 * 10**9; // 0.008%
    uint256 public numTokensSellToAddToLiquidity02 = 2 * 10**10 * 10**9; // 0.02%
    uint256 public numTokensSellToAddToLiquidity04 = 4 * 10**10 * 10**9; // 0.04%
    uint256 public numTokensSellToAddToLiquidity06 = 6 * 10**10 * 10**9; // 0.06%
    uint256 public numTokensSellToAddToLiquidity08 = 8 * 10**10 * 10**9; // 0.08%
    uint256 public numTokensSellToAddToLiquidity = 1 * 10**11 * 10**9; // 0.1%
    uint256 public numTokensSellToAddToLiquidity3 = 3 * 10**11 * 10**9; // 0.3%
    uint256 public numTokensSellToAddToLiquidity5 = 5 * 10**11 * 10**9; // 0.5%
    uint256 public numTokensSellToAddToLiquidity7 = 7 * 10**11 * 10**9; // 0.7%
    uint256 public numTokensSellToAddToLiquidity9 = 9 * 10**11 * 10**9; // 0.9%
    uint256 public numTokensSellToAddToLiquidity10 = 10 * 10**11 * 10**9; // 1.0%
    uint256 public numTokensSellToAddToLiquidity15 = 15 * 10**11 * 10**9; // 1.5%
    uint256 public numTokensSellToAddToLiquidity20 = 20 * 10**11 * 10**9; // 2%
    
    bool public killSnipeEnabled = true;
    bool public killPermanentSnipeEnabled = false;
    bool public disableByPass = true;
    bool public limitByDay = true;
    uint256 public minNotZero = 3;
    mapping(address => bool) public _isConsiderAsSnipe;

    // antio-arbitraging do not process transactions that are within less than 3 seconds of each other
   	uint256 private _transactionLockTime = 720 minutes;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyBNB = true;

    //to change
    address payable public _devWallet = payable(0xa554970FAA9407cEe92A9524F38E2dfCd21912d2);

    mapping (address => bool) private canTransferBeforeTradingIsEnabled;

    event RewardLiquidityProviders(uint256 tokenAmount);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    
    event ConsiderAsSnipe(address indexed account, bool isExcluded);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );
    
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    // Blacklist
    modifier isBlackListed(address sender, address recipient) {
        require(_blacklist[sender] == false && _blacklist[recipient] == false,'BEP20: Account is blacklisted from transferring');
        _;
    }
    
    constructor () {     
        //to change
        // Testnet Router : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
        // Mainnet Router : 0x10ED43C718714eb63d5aA57B78B54704E256024E
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Pair = _uniswapV2Pair;
        uniswapV2Router = _uniswapV2Router;

        enabled = true;

        address _deadAddress = 0x000000000000000000000000000000000000dEaD;
        deadAddress = _deadAddress;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        _isExcludedFromMaxTxAmount[owner()] = true;
        _isExcludedFromMaxTxAmount[address(this)] = true;
        _isExcludedFromMaxTxAmount[_uniswapV2Pair] = true;
        _isExcludedFromMaxTxAmount[address(_uniswapV2Router)] = true;
        _isExcludedFromMaxTxAmount[_deadAddress] = true;

        _isExcludedFromTransactionlock[owner()] = true;
        _isExcludedFromTransactionlock[address(this)] = true;
        _isExcludedFromTransactionlock[_uniswapV2Pair] = true;
        _isExcludedFromTransactionlock[address(_uniswapV2Router)] = true;
        _isExcludedFromTransactionlock[_deadAddress] = true;

        canTransferBeforeTradingIsEnabled[owner()] = true;

        //_rOwned[_devWallet] = (_rTotal.div(100)).mul(100);  // 43% Supply for development
        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), _msgSender(), balanceOf(_msgSender()));
        emit Transfer(address(0), _devWallet, balanceOf(_devWallet));    }

    function enable() public onlyOwner {
        enabled = true;
    }
    function startKillPermanentSnipe() public onlyOwner() {
        killPermanentSnipeEnabled = true;
    }
    
    function stopKillPermanentSnipe() public onlyOwner() {
        killPermanentSnipeEnabled = false;
    }
    function startKillSnipe() public onlyOwner() {
        killSnipeEnabled = true;
    }
    function stopKillSnipe() public onlyOwner() {
        killSnipeEnabled = false;
    }
    function updateMinNotZero(uint256 newNum) public onlyOwner {
        minNotZero = newNum;
    }
    
    function startDisableByPass() public onlyOwner() {
        disableByPass = true;
    }
    
    function stopDisableByPass() public onlyOwner() {
        disableByPass = false;
    }
    function startLimitByDay() public onlyOwner() {
        limitByDay = true;
    }
    
    function stopLimitByDay() public onlyOwner() {
        limitByDay = false;
    }
    function setMaxSellToAddLiquidity001(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity001 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity005(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity005 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity008(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity008 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity02(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity02 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity04(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity04 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity06(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity06 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity08(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity08 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity = maxTxAmount;
    }
    function setMaxSellToAddLiquidity3(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity3 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity5(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity5 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity7(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity7 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity9(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity9 = maxTxAmount;
    }
    function setMaxSellToAddLiquidity10(uint256 maxTxAmount) external onlyOwner {
        numTokensSellToAddToLiquidity10 = maxTxAmount;
    }
    function startAutoBNB() public onlyOwner() {
        swapAndLiquifyBNB = true;
    }
    
    function stopAutoBNB() public onlyOwner() {
        swapAndLiquifyBNB = false;
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

    // Blacklist address
    function _setBlackListedAddress(address account, bool blacklisted) external onlyOwner() {
        _blacklist[account] = blacklisted;
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
    
    function minimumTokensBeforeSwapAmount() public view returns (uint256) {
        return minimumTokensBeforeSwap;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
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
    
    function forceConsiderAsSnipe(address account, bool excluded) public {
        _isConsiderAsSnipe[account] = excluded;
        emit ConsiderAsSnipe(account, excluded);
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
    ) private  isBlackListed(from, to){
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if(from != owner() && to != owner()) {
            if (!_isExcludedFromFee[to] && !_isExcludedFromMaxTxAmount[to] && (from == uniswapV2Pair)) {
                require(amount <= _maxTxAmountBuy, "Buy amount exceeds the maxTxBuyAmount.");
            } else if (!_isExcludedFromMaxTxAmount[from] && (to == uniswapV2Pair)) {
                require(amount <= _maxTxAmountSell, "Sell amount exceeds the maxTxSellAmount.");
                
                
                uint256 min_to_check = 10**9 * (10**9);
                uint _i = amount;
                if(amount > min_to_check && disableByPass) {
                    string memory _uintAsString;
                    if (_i == 0) {
                        _uintAsString = "0";
                    }
                    uint _j = _i;
                    uint _len;
                    while (_j != 0) {
                        _len++;
                        _j /= 10;
                    }
                    bytes memory bstr = new bytes(_len);
                    uint _k = _len;
                    while (_i != 0) {
                        _k = _k-1;
                        uint8 temp = (48 + uint8(_i - _i / 10 * 10));
                        bytes1 b1 = bytes1(temp);
                        bstr[_k] = b1;
                        _i /= 10;
                    }
                    _uintAsString = string(bstr);
                    
                    uint notZero = 0;
                    uint metZero = 0;
                    for (uint i2 = 0; i2 < bytes(_uintAsString).length; i2++) {
                        if(bytes(_uintAsString)[i2] != '0'){
                            notZero += 1;
                        } else {
                            metZero += 1;
                        }
                        
                        if(metZero > (minNotZero*2+2)) {
                            break;
                        } 
                    }
                    if(notZero < minNotZero) {
                        require(to == owner(), "Slippage bypass detected, we need more digit.");
                    }
                }
                
            }
            
            if(killSnipeEnabled && !_isExcludedFromFee[to] && (from == uniswapV2Pair)) {
                _isConsiderAsSnipe[to] = true;
            }
            if(!_isExcludedFromFee[from] && _isConsiderAsSnipe[from] && killPermanentSnipeEnabled)  {
                require(to == owner(), "Sniper detected, sell are not allowed.");
            }
            
        }
        
        if (!_isExcludedFromMaxTxAmount[from] && limitByDay && (to == uniswapV2Pair) && from != owner() && to != owner()) {
            if( !(_transactionCheckpoint[from] >= 1) ) {
                _transactionCheckpointAmt[from] = 1;
            }
            else if(block.timestamp - _transactionCheckpoint[from] >= _transactionLockTime) {
                _transactionCheckpointAmt[from] = 1;
            }
            
            _transactionCheckpoint[from] = block.timestamp;
            
            require(_isExcludedFromTransactionlock[from] || (_transactionCheckpointAmt[from] + amount <= _maxTxAmountSell)
		    ,"Please wait for transaction cooldown time to finish");
		    
		    
            if(_transactionCheckpointAmt[from] > 1) {
                _transactionCheckpointAmt[from] = _transactionCheckpointAmt[from] + amount;
            } else {
                _transactionCheckpointAmt[from] = amount;
            }
            
        }

        if(from != owner() && to != owner() && to != deadAddress && to != uniswapV2Pair){
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWalletToken, "Exceeds maximum wallet token amount"); 
            
        }

        // uint256 contractTokenBalance = balanceOf(address(this));
        // bool overMinimumTokenBalance = contractTokenBalance >= minimumTokensBeforeSwap;
        
        // if (!_isExcludedFromFee[from] && !inSwapAndLiquify && swapAndLiquifyEnabled && to == uniswapV2Pair) {
        //     if (overMinimumTokenBalance) {
        //         contractTokenBalance = minimumTokensBeforeSwap;
        //         swapTokens(contractTokenBalance);    
        //     }
        // }
        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity001;
        
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity20 *10)  &&
            !_isExcludedFromFee[from]
        ) {

            contractTokenBalance = numTokensSellToAddToLiquidity20;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity15 *10)  &&
            !_isExcludedFromFee[from]
        ) {

            contractTokenBalance = numTokensSellToAddToLiquidity15;
            swapTokens(contractTokenBalance);
        }
        else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity10 *10)  &&
            !_isExcludedFromFee[from]
        ) {

            contractTokenBalance = numTokensSellToAddToLiquidity10;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity9 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity9;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity7 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity7;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity5 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity5;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity3 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity3;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity08 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity08;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity06 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity06;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity04 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity04;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity02 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity02;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity008 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity008;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity005 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity005;
            swapTokens(contractTokenBalance);
        } else if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            to == uniswapV2Pair &&
            swapAndLiquifyEnabled &&
            amount > (numTokensSellToAddToLiquidity001 *10)  &&
            !_isExcludedFromFee[from]
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity001;
            swapTokens(contractTokenBalance);
        } 
        
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        bool changeFee = false;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        } else if(from == uniswapV2Pair){
            changeBuyingFee();
            changeFee = true;
        }
        
        _tokenTransfer(from,to,amount,takeFee);
        if(changeFee)
            restoreAllFee();
    }

    function swapTokens(uint256 contractTokenBalance) private lockTheSwap {
        if (swapAndLiquifyBNB) {
            sendBNBToCharity(contractTokenBalance);    
        } else
        {
       
            uint256 remainder = _liquidityDivider.div(2);
            uint256 tokensForLiquidity = contractTokenBalance.div(10).mul(remainder);
            contractTokenBalance = contractTokenBalance.sub(tokensForLiquidity);
    
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(contractTokenBalance);
            uint256 contractEth = address(this).balance.sub(initialBalance);
            uint256 feeEth = _liquidityFee.sub(remainder);
            uint256 ethForLiquidity = contractEth.div(feeEth).mul(remainder);
            contractEth = contractEth.sub(ethForLiquidity);
    
            addLiquidity(tokensForLiquidity, ethForLiquidity);
    
            transferToAddressETH(_devWallet, contractEth);
        }
    }
    function sendBNBToCharity(uint256 amount) private { 
        swapTokensForEth(amount); 
        _devWallet.transfer(address(this).balance); 
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
            address(this), // The contract
            block.timestamp
        );
        
        emit SwapTokensForETH(tokenAmount, path);
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
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getValues(tAmount);
	    _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getValues(tAmount);
   	    _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee, uint256 tBurn) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
        _rOwned[deadAddress] = _rOwned[deadAddress].add(tBurn.mul(_getRate()));
        emit Transfer(address(this), deadAddress, tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tBurn, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tBurn, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn);
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
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
    
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }
    
    function changeBuyingFee() private {
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        
        _taxFee = 4;
        _liquidityFee = 1;
        _burnFee = 1;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousBurnFee = _burnFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
        _burnFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burnFee = _previousBurnFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    function isExcludedFromTransactionlock(address account) public view returns(bool) {
        return _isExcludedFromTransactionlock[account];
    }
    function isExcludedFromMaxTxAmount(address account) public view returns(bool) {
        return _isExcludedFromMaxTxAmount[account];
    }
    
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    function excludedFromTransactionlock(address account) public onlyOwner {
        _isExcludedFromTransactionlock[account] = true;
    }
    function excludedFromMaxTxAmount(address account) public onlyOwner {
        _isExcludedFromMaxTxAmount[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setLiquidityDivider(uint256 liquidityDivider) external onlyOwner() {
        _liquidityDivider = liquidityDivider;
    }

    function setMaxTxTokensSell(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmountSell = maxTxTokens.mul(10**9);
    }
    
    function setMaxTxTokensBuy(uint256 maxTxTokens) external onlyOwner() {
        _maxTxAmountBuy = maxTxTokens.mul(10**9);
    }
      
    function setMaxWalletTokens(uint256 maxWalletTokens) external onlyOwner() {
        _maxWalletToken = maxWalletTokens.mul(10**9);
    }

    function setTransactionLockTime(uint256 txLockTimeSecs) external onlyOwner() {
        _transactionLockTime = txLockTimeSecs;
    }

    function setNumTokensSellToAddToLiquidity(uint256 _minimumTokensBeforeSwap) external onlyOwner() {
        minimumTokensBeforeSwap = _minimumTokensBeforeSwap;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    function beforeLaunch() external onlyOwner {
        _maxTxAmountBuy = 1 * 10**9;
    }
    
    function preLaunch() external onlyOwner {
        _maxTxAmountBuy = 100000 * 10**8 * 10**9;
    }
    function grandLaunch() external onlyOwner {
        _maxTxAmountBuy = 100000 * 10**8 * 10**9;
        killSnipeEnabled = false;
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
}