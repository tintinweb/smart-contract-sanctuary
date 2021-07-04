/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity 0.6.12;

contract Rebasable is Ownable {
  address private _rebaser;

  event TransferredRebasership(address indexed previousRebaser, address indexed newRebaser);

  constructor() internal {
    address msgSender = _msgSender();
    _rebaser = msgSender;
    emit TransferredRebasership(address(0), msgSender);
  }

  function Rebaser() public view returns(address) {
    return _rebaser;
  }

  modifier onlyRebaser() {
    require(_rebaser == _msgSender(), "caller is not rebaser");
    _;
  }

  function transferRebasership(address newRebaser) public virtual onlyOwner {
    require(newRebaser != address(0), "new rebaser is address zero");
    emit TransferredRebasership(_rebaser, newRebaser);
    _rebaser = newRebaser;
  }
}

/// SWC-103:  Floating Pragma

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

pragma solidity 0.6.12;

contract SCORPION is Ownable, Rebasable
{
    using SuSafeMath for uint256;
	using Address for address;
	
	IUniswapV2Router02 public immutable _uniswapV2Router;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approval(address indexed owner, address indexed spender, uint amount);

    event Rebase(uint256 indexed epoch, uint256 scalingFactor);

    event WhitelistFrom(address _addr, bool _whitelisted);
    event WhitelistTo(address _addr, bool _whitelisted);
    event UniswapPairAddress(address _addr, bool _whitelisted);

    string public name     = "Scorpion";
    string public symbol   = "SCORPION";
    uint8  public decimals = 9;

    address payable public marketingAddress = payable(0xf367211931B78153F67960300378F7665086a60F); // Marketing Address
    
    address public BurnAddress = 0x000000000000000000000000000000000000dEaD;
	
    address public rewardAddress;


    
    uint256 private constant internalDecimals = 10**9;

    
    uint256 private constant BASE = 10**9;

    
    uint256 private SuScalingFactor  = BASE;

	mapping (address => uint256) private _rOwned;
	mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) internal _allowedFragments;
	
	mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    mapping(address => bool) public whitelistFrom;
    mapping(address => bool) public whitelistTo;
    mapping(address => bool) public uniswapPairAddress;
	address private currentPoolAddress;
	address private currentPairTokenAddress;
	address public uniswapETHPool;
	address[] private futurePools;


    bool public tradingEnabled;
    event TradingEnabled();

    uint256 initSupply = 10**11 * 10**9;
    uint256 _totalSupply = 10**11 * 10**9;
    uint16 public SELL_FEE = 10;
    uint16 public TX_FEE = 0;
    uint16 public BURN_TOP = 0;
	uint16 public BURN_BOTTOM = 2;
	uint256 private _tFeeTotal;
	uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _totalSupply));
	
	uint256 public _maxTxAmount = 10**11 * 10**9;
	uint256 public _minTokensBeforeSwap = 1000 * 10**9;
	
	bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    
	
	event MaxTxAmountUpdated(uint256 maxTxAmount);
	
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );
    event SwapAndLiquify(
        address indexed pairTokenAddress,
        uint256 tokensSwapped,
        uint256 pairTokenReceived,
        uint256 tokensIntoLiqudity
    );
	event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    
	modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(IUniswapV2Router02 uniswapV2Router)
    public
    Ownable()
    Rebasable()
    {
		_uniswapV2Router = uniswapV2Router;
        
        currentPoolAddress = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());
        currentPairTokenAddress = uniswapV2Router.WETH();
        uniswapETHPool = currentPoolAddress;
		rewardAddress = address(this);
        
        updateSwapAndLiquifyEnabled(false);
        
        _rOwned[_msgSender()] = reflectionFromToken(_totalSupply, false);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    function getSellBurn(uint256 value) public view returns (uint256)
    {
        uint256 nPercent = value.mul(SELL_FEE).divRound(100);
        return nPercent;
    }

    function getTxBurn(uint256 value) public view returns (uint256)
    {
        uint256 nPercent = value.mul(TX_FEE).divRound(100);
        return nPercent;
    }

    function _isWhitelisted(address _from, address _to) internal view returns (bool)
    {
        return whitelistFrom[_from]||whitelistTo[_to];
    }

    function _isUniswapPairAddress(address _addr) internal view returns (bool)
    {
        return uniswapPairAddress[_addr];
    }

    function setWhitelistedTo(address _addr, bool _whitelisted) external onlyOwner
    {
        emit WhitelistTo(_addr, _whitelisted);
        whitelistTo[_addr] = _whitelisted;
    }

    function setTxFee(uint16 fee) external onlyOwner
    {
		require(fee < 90, 'Su: Transaction fee should be less than 90%');
        TX_FEE = fee;
    }

    function setSellFee(uint16 fee) external onlyOwner
    {
		require(fee < 90, 'Su: Sell fee should be less than 90%');
        SELL_FEE = fee;
    }
	
    function setBurnTop(uint16 burntop) external onlyOwner
    {
        BURN_TOP = burntop;
    }
	
	function setBurnBottom(uint16 burnbottom) external onlyOwner
    {
        BURN_BOTTOM = burnbottom;
    }
    
    function setMarketingAddress(address _marketingAddress) external onlyOwner() {
        marketingAddress = payable(_marketingAddress);
    }
	
    function setWhitelistedFrom(address _addr, bool _whitelisted) external onlyOwner
    {
        emit WhitelistFrom(_addr, _whitelisted);
        whitelistFrom[_addr] = _whitelisted;
    }

    function setUniswapPairAddress(address _addr, bool _whitelisted) external onlyOwner 
	{
        emit UniswapPairAddress(_addr, _whitelisted);
        uniswapPairAddress[_addr] = _whitelisted;
    }
	
	function addfuturePool(address futurePool) external onlyOwner
	{
		IUniswapV2Pair(futurePool).sync();
		futurePools.push(futurePool);
	}

    function maxScalingFactor() external view returns (uint256)
    {
        return _maxScalingFactor();
    }

    function _maxScalingFactor() internal view returns (uint256)
    {
        // scaling factor can only go up to 2**256-1 = initSupply * SuScalingFactor
        // this is used to check if SuScalingFactor will be too high to compute balances when rebasing.
        return uint256(-1) / initSupply;
    }

   function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
		_transfer(sender, recipient, amount);
		// decrease allowance
        _approve(sender, _msgSender(), _allowedFragments[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

	function balanceOf(address account) public view returns (uint256) {
	  
        if (_isExcluded[account]) return _tOwned[account].mul(SuScalingFactor).div(internalDecimals);
        uint256 tOwned = tokenFromReflection(_rOwned[account]);
		return _scaling(tOwned);
	}

    function balanceOfUnderlying(address account) external view returns (uint256)
    {
        return tokenFromReflection(_rOwned[account]);
    }

    
    function allowance(address owner_, address spender) external view returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool)
    {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue)
        {
            _allowedFragments[msg.sender][spender] = 0;
        }
        else
        {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }

        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
	
	function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "Su: approve from the zero address");
        require(spender != address(0), "Su: approve to the zero address");

        _allowedFragments[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function isExcluded(address account) private view returns (bool) 
	{
        return _isExcluded[account];
    }
	
	function totalFees() public view returns (uint256) 
	{
        return _tFeeTotal;
    }
	
	function reflect(uint256 tAmount) private 
	{
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        uint256 currentRate = _getRate();
        uint256 TAmount = tAmount.mul(internalDecimals).div(SuScalingFactor);
		uint256 rAmount = TAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
	
	function reflectionFromToken(uint256 tAmount, bool deductTransferFee) private view returns(uint256) 
	{
        require(tAmount <= _totalSupply, "Amount must be less than supply");
        uint256 currentRate = _getRate();
        uint256 TAmount = tAmount.mul(internalDecimals).div(SuScalingFactor);
        uint256 fee = getTxBurn(TAmount);
		uint256 rAmount = TAmount.mul(currentRate);
        if (!deductTransferFee) {
            return rAmount;
        } else {
            (uint256 rTransferAmount,,) = _getRValues(TAmount, fee, currentRate);
            return rTransferAmount;
        }
    }
	
	function tokenFromReflection(uint256 rAmount) private view returns(uint256) 
	{
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
	
	function excludeAccount(address account) internal onlyOwner() 
	{
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _rOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }
	
	function includeAccount(address account) internal onlyOwner() 
	{
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _rOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
    
    function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }
	
	function _transfer(address sender, address recipient, uint256 amount) private 
	{
        
		require(sender != address(0), "Su: cannot transfer from the zero address");
        require(recipient != address(0), "Su: cannot transfer to the zero address");
        require(amount > 0, "Su: Transfer amount must be greater than zero");
		
		if(sender != owner() && recipient != owner() && !inSwapAndLiquify) {
            require(amount <= _maxTxAmount, "Su: Transfer amount exceeds the maxTxAmount.");
        if((_msgSender() == currentPoolAddress || _msgSender() == address(_uniswapV2Router)) && !tradingEnabled)
                require(false, "Su: trading is disabled.");
		}
        
        if(!inSwapAndLiquify) {
            uint256 lockedBalanceForPool = balanceOf(address(this));
            bool overMinTokenBalance = lockedBalanceForPool >= _minTokensBeforeSwap;
			currentPairTokenAddress == _uniswapV2Router.WETH();
            if (
                overMinTokenBalance &&
                msg.sender != currentPoolAddress &&
                swapAndLiquifyEnabled
            ) {
                swapTokens(lockedBalanceForPool);
            }
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
    }
	
	receive() external payable {}
    
    function swapTokens(uint256 lockedBalanceForPool) private lockTheSwap {
        
        uint256 lockedForSwap = lockedBalanceForPool;
		
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
        swapTokensForEth(lockedForSwap);
        
        // how much ETH did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        
         transferToAddressETH(marketingAddress, newBalance);
    }
    
    
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // make the swap
        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityForEth(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(_uniswapV2Router), tokenAmount);

        // add the liquidity
        _uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

	
	function _transferStandard(address sender, address recipient, uint256 tAmount) private 
	{
	    uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(SuScalingFactor);
		uint256 rAmount = TAmount.mul(currentRate);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		
		if(inSwapAndLiquify) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
		}
		
	    else if (_isUniswapPairAddress(recipient))
        {
		 uint256 fee = getSellBurn(TAmount);
		(uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
		_totalSupply = _totalSupply.sub(_scaling(tBurnFee));
	
		_transferStandardSell(sender, recipient, tBurnFee, rTransferAmount, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
        }
        else
        {
            if(!_isWhitelisted(sender, recipient))
            {
	     uint256 fee = getTxBurn(TAmount);
		(uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
		_totalSupply = _totalSupply.sub(_scaling(tBurnFee));
	
		_transferStandardTx(sender, recipient, tBurnFee, rTransferAmount, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
            }
            else
            {           
                _rOwned[recipient] = _rOwned[recipient].add(rAmount);
                emit Transfer(sender, recipient, tAmount);
             }
        }
    }
    
    function _transferStandardSell(address sender, address recipient, uint256 tBurnFee, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee) private 
	{
            _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);        
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
		
            emit Transfer(sender, recipient, _scaling(tTransferAmount));
            emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
            emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
        
    }
    
    function _transferStandardTx(address sender, address recipient, uint256 tBurnFee, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee) private 
	{        
                _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);                
                _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
                _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
			
                emit Transfer(sender, recipient, _scaling(tTransferAmount));
                emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
                emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
        
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private 
	{
		uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(SuScalingFactor);
		uint256 rAmount = TAmount.mul(currentRate);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);

		if(inSwapAndLiquify) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
		}
		
		else if(_isUniswapPairAddress(recipient))
        {
		 uint256 fee = getSellBurn(TAmount);
		(, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
		_totalSupply = _totalSupply.sub(_scaling(tBurnFee));
	
		_transferToExcludedSell(sender, recipient, tBurnFee, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
        }
        else
        {
            if(!_isWhitelisted(sender, recipient))
            {
	     uint256 fee = getTxBurn(TAmount);
		(, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
		_totalSupply = _totalSupply.sub(_scaling(tBurnFee));
	
        _transferToExcludedSell(sender, recipient, tBurnFee, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
            }
            else
            {
                _tOwned[recipient] = _tOwned[recipient].add(TAmount);
                emit Transfer(sender, recipient, tAmount);
             }
        }
    }
    
    function _transferToExcludedSell (address sender, address recipient, uint256 tBurnFee, uint256 tTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 tRewardFee) private 
	{
            _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
            emit Transfer(sender, recipient, _scaling(tTransferAmount));
            emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
            emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
        
    }
    
    function _transferToExcludedTx (address sender, address recipient, uint256 tBurnFee, uint256 tTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 tRewardFee) private 
	{        
                _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);
                _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
                _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
                emit Transfer(sender, recipient, _scaling(tTransferAmount));
                emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
                emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
    }
         
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private 
	{
		uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(SuScalingFactor);
		uint256 rAmount = TAmount.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		
		if(inSwapAndLiquify) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
		}
		
		else if(_isUniswapPairAddress(recipient))
        {
		 uint256 fee = getSellBurn(TAmount);
		(uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
		_totalSupply = _totalSupply.sub(_scaling(tBurnFee));
	
		_transferFromExcludedSell(sender, recipient, tBurnFee, rTransferAmount, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
        }
        else
        {
            if(!_isWhitelisted(sender, recipient))
            {
	     uint256 fee = getTxBurn(TAmount);
		(uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
		_totalSupply = _totalSupply.sub(_scaling(tBurnFee));
	
		_transferFromExcludedTx(sender, recipient, tBurnFee, rTransferAmount, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
                
            }
            else
            {
                _rOwned[recipient] = _rOwned[recipient].add(rAmount);
                emit Transfer(sender, recipient, tAmount);
             }
        }
    }
    
    function _transferFromExcludedSell(address sender, address recipient, uint256 tBurnFee, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee) private 
	{
            _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
            _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
            emit Transfer(sender, recipient, _scaling(tTransferAmount));
            emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
            emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
    }
    
    function _transferFromExcludedTx(address sender, address recipient, uint256 tBurnFee, uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee, uint256 tTransferAmount, uint256 tRewardFee) private 
	{
                _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);
                _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
                _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
                emit Transfer(sender, recipient, _scaling(tTransferAmount));
                emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
                emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private 
	{
	    uint256 currentRate =  _getRate();
		uint256 TAmount = tAmount.mul(internalDecimals).div(SuScalingFactor);
		uint256 rAmount = TAmount.mul(currentRate);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
		_rOwned[sender] = _rOwned[sender].sub(rAmount);
		
		if(inSwapAndLiquify) {
            _rOwned[recipient] = _rOwned[recipient].add(rAmount);
            emit Transfer(sender, recipient, tAmount);
		}
		
        else if(_isUniswapPairAddress(recipient))
        {
		 uint256 fee = getSellBurn(TAmount);
		(uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
            _totalSupply = _totalSupply.sub(_scaling(tBurnFee));
            
            _transferBothExcludedSell(sender, recipient, tBurnFee, rTransferAmount, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
            
        }
        else
        {
            if(!_isWhitelisted(sender, recipient))
            {
	     uint256 fee = getTxBurn(TAmount);
		(uint256 rTransferAmount, uint256 rBurnFee, uint256 rRewardFee) = _getRValues(rAmount, fee, currentRate);
		(uint256 tTransferAmount, uint256 tBurnFee, uint256 tRewardFee) = _getTValues(TAmount, fee);
           _totalSupply = _totalSupply.sub(_scaling(tBurnFee));
            
            _transferBothExcludedTx(sender, recipient, tBurnFee, rTransferAmount, rBurnFee, rRewardFee, tTransferAmount, tRewardFee);
            }
            else
            {
                _rOwned[recipient] = _rOwned[recipient].add(rAmount);
				_tOwned[recipient] = _tOwned[recipient].add(TAmount);
                emit Transfer(sender, recipient, tAmount);
             }
        }
    }
    
    function _transferBothExcludedSell(address sender, address recipient, uint256 tBurnFee, uint256 rTransferAmount, uint256 rBurnFee, uint256 tTransferAmount, uint256 rRewardFee, uint256 tRewardFee) private 
	{   
            _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
			_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
			
            emit Transfer(sender, recipient, _scaling(tTransferAmount));
            emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
            emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
        
    }
    
     function _transferBothExcludedTx(address sender, address recipient, uint256 tBurnFee, uint256 rTransferAmount, uint256 rBurnFee, uint256 tTransferAmount, uint256 rRewardFee, uint256 tRewardFee) private 
	 {
                _rOwned[BurnAddress] = _rOwned[BurnAddress].add(rBurnFee);
                _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
				_tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
                _rOwned[rewardAddress] = _rOwned[rewardAddress].add(rRewardFee);
				
                emit Transfer(sender, recipient, _scaling(tTransferAmount));
                emit Transfer(sender, BurnAddress, _scaling(tBurnFee));
                emit Transfer(sender, rewardAddress, _scaling(tRewardFee));
     }
	 
	function _scaling(uint256 amount) private view returns (uint256)
	
	{
		uint256 scaledAmount = amount.mul(SuScalingFactor).div(internalDecimals);
		return(scaledAmount);
	}
	
	 function prepareForLaunch() external onlyOwner {
        updateSwapAndLiquifyEnabled(false);
        SELL_FEE = 0;
        TX_FEE = 0;
        _maxTxAmount = 10**11 * 10**9;
    }
    
    function afterLaunch() external onlyOwner {
        updateSwapAndLiquifyEnabled(true);
        tradingEnabled = true;
        SELL_FEE = 10;
        TX_FEE = 90;
        _maxTxAmount = 10**11 * 10**9;
    }
    
    function afterXminsLaunch() external onlyOwner {
        SELL_FEE = 10;
        TX_FEE = 0;
    }
    
    function _reflectFee(uint256 rFee, uint256 tFee) private 
	{
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getTValues(uint256 TAmount, uint256 fee) private view returns ( uint256, uint256, uint256) 
	{
         
		uint256 tBurnFee = BURN_TOP*fee/BURN_BOTTOM;
		uint256 tRewardFee = fee.sub(tBurnFee);
        uint256 tTransferAmount = TAmount.sub(tBurnFee).sub(tRewardFee);
        return (tTransferAmount, tBurnFee, tRewardFee);
    }
	
    function _getRValues(uint256 rAmount, uint256 fee, uint256 currentRate) private view returns ( uint256, uint256, uint256) 
	{
        
		uint256 rBurnFee = (BURN_TOP*fee/BURN_BOTTOM).mul(currentRate);
		uint256 rRewardFee = fee.mul(currentRate).sub(rBurnFee);
		uint256 rTransferAmount = _getRValues2(rAmount, rBurnFee, rRewardFee);
        return (rTransferAmount, rBurnFee, rRewardFee);
    }
	
	function _getRValues2(uint256 rAmount, uint256 rBurnFee, uint256 rRewardFee) private pure returns (uint256) 
	{
        uint256 rTransferAmount = rAmount.sub(rBurnFee).sub(rRewardFee);
        return (rTransferAmount);
    }
	

    function _getRate() private view returns(uint256) 
	{
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) 
	{
        uint256 rSupply = _rTotal;
        uint256 tSupply = initSupply;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, initSupply);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(initSupply)) return (_rTotal, initSupply);
        return (rSupply, tSupply);
    }

    function _setRewardAddress(address rewards_) external onlyOwner
    {
        rewardAddress = rewards_;
    }

    /**
    * @notice Initiates a new rebase operation, provided the minimum time period has elapsed.
    *
    * @dev The supply adjustment equals (totalSupply * DeviationFromTargetRate) / rebaseLag
    *      Where DeviationFromTargetRate is (MarketOracleRate - targetRate) / targetRate
    *      and targetRate is CpiOracleRate / baseCpi
    */
    function rebase(uint256 epoch, uint256 indexDelta, bool positive) external onlyRebaser returns (uint256)
    {
		uint256 currentRate = _getRate();
        if (!positive)
        {
		uint256 newScalingFactor = SuScalingFactor.mul(BASE.sub(indexDelta)).div(BASE);
		SuScalingFactor = newScalingFactor;
        _totalSupply = ((initSupply.sub(_rOwned[BurnAddress].div(currentRate))
            .mul(SuScalingFactor).div(internalDecimals)));
        emit Rebase(epoch, SuScalingFactor);
		IUniswapV2Pair(uniswapETHPool).sync();
		for (uint256 i = 0; i < futurePools.length; i++) {
			address futurePoolAddress = futurePools[i];
			IUniswapV2Pair(futurePoolAddress).sync();
		}
        return _totalSupply;
        }
		
        else 
		{
        uint256 newScalingFactor = SuScalingFactor.mul(BASE.add(indexDelta)).div(BASE);
        if (newScalingFactor < _maxScalingFactor())
        {
            SuScalingFactor = newScalingFactor;
        }
        else
        {
            SuScalingFactor = _maxScalingFactor();
        }

        _totalSupply = ((initSupply.sub(_rOwned[BurnAddress].div(currentRate))
            .mul(SuScalingFactor).div(internalDecimals)));
        emit Rebase(epoch, SuScalingFactor);
		IUniswapV2Pair(uniswapETHPool).sync();
		for (uint256 i = 0; i < futurePools.length; i++) {
			address futurePoolAddress = futurePools[i];
			IUniswapV2Pair(futurePoolAddress).sync();
		}
        return _totalSupply;
		}
	}
	
	function getCurrentPoolAddress() private view returns(address) {
        return currentPoolAddress;
    }
    
    function getCurrentPairTokenAddress() private view returns(address) {
        return currentPairTokenAddress;
    }
	
	function _setMaxTxAmount(uint256 maxTxAmount) external onlyOwner() {
        require(maxTxAmount >= 10**8 , 'Su: maxTxAmount should be greater than 0.1 Su');
        _maxTxAmount = maxTxAmount;
        emit MaxTxAmountUpdated(maxTxAmount);
    }
	
	function _setMinTokensBeforeSwap(uint256 minTokensBeforeSwap) external onlyOwner() {
        require(minTokensBeforeSwap >= 1 * 10**9 && minTokensBeforeSwap <= 2000 * 10**9, 'Su: minTokenBeforeSwap should be between 1 and 2000 Su');
        _minTokensBeforeSwap = minTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(minTokensBeforeSwap);
    }
	
	function updateSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
	
	function _enableTrading() external onlyOwner() {
        tradingEnabled = true;
        TradingEnabled();
    }
}

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SuSafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function ceil(uint256 a, uint256 m) internal pure returns (uint256)
    {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
    }

    function divRound(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        uint256 r = x / y;
        if (x % y != 0) {
            r = r + 1;
        }

        return r;
    }
}