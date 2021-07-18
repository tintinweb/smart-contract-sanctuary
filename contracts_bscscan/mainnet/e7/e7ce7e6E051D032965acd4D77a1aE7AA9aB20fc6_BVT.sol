/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

/**
  
   #BEE
   
   #LIQ+#RFI+#SHIB+#DOGE = #BEE
   #SAFEMOON features:
   3% fee auto add to the liquidity pool to locked forever when selling
   2% fee auto distribute to all holders
   I created a black hole so #Bee token will deflate itself in supply with every transaction
   50% Supply is burned at start.
   
 */

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed
//ERC20标准接口
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




 //安全数学库
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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
	//取模
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
//抽象合约
abstract contract Context {
	//获取当前的地址
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
	//完整的调用数据（完成 calldata）用作唯一标识符？
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev 与地址类型相关的函数集合
 */
 //address库
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
	 /**
* @dev Replacement for Solidity的` transfer ':发送` amount` wei到
* `收件人',转发所有可用的气体和恢复错误。
*
*某些操作码，可能使合同超过2300气体的限制
*通过`转账'实施，使他们无法通过以下途径获得资金
* `transfer `。{发送值}消除了这一限制
*
*重要:由于控制权转移给了“接受方”,因此必须小心谨慎
*注意不要造成可重入性漏洞。考虑使用
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
 //合约拥有者相关
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
	//转让所有权
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

	//放弃合约拥有权（转移到0地址）
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

	//修改合约拥有者
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
	//在规定的时间内锁定业主合同，锁定期间拥有权转移到0地址
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
	//解锁拥有权
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(now > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

// pragma solidity >=0.5.0;
//swap工厂合约调用接口
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
//swap交易对调用接口
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

// pragma solidity >=0.6.2;
//路由调用接口
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
//路由调用接口2
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

//主要合约
contract BVT is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
	//账户分红余额？
    mapping (address => uint256) private _rOwned;
	//当前账户余额
    mapping (address => uint256) private _tOwned;
	//授权的代币数量
    mapping (address => mapping (address => uint256)) private _allowances;
	//是否被排除？被排除的免费交易
    mapping (address => bool) private _isExcludedFromFee;
	//是否被排除？被排除的不计算分红？（黑名单地址？）
    mapping (address => bool) private _isExcluded;
	//排除的地址集合
    address[] private _excluded;
	//最大值？当前的？        ~ (位非)一元操作符，反转操作数中的所有位。
    uint256 private constant MAX = ~uint256(0);
	//真实总量（返回的是这个）
    uint256 private _tTotal = 1000000000 * 10**8;
	//此值初始为0？
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
	//费用合计？
    uint256 private _tFeeTotal;

    string private _name = "baby vault";
    string private _symbol = "BVT";
	//精度
    uint8 private _decimals = 8;
    //税费
    uint256 public _taxFee = 8;
	//之前的税费
    uint256 private _previousTaxFee = _taxFee;
    //流动性费用
    uint256 public _liquidityFee = 8;
	//之前的流动性费用
    uint256 private _previousLiquidityFee = _liquidityFee;
	//团队抽水
	uint256 public _teamFee = 4;
	//之前的团队抽水
	uint256 private _previousTeamFee = _teamFee;
	//团队的抽水地址
	address public _teamAddr;
	// immutable 不变的
    IUniswapV2Router02 public immutable uniswapV2Router;
	//交易对地址
    address public immutable uniswapV2Pair;
    //是否锁定交易
    bool inSwapAndLiquify;
	//是否开启交易？
    bool public swapAndLiquifyEnabled = true;
    //最大发送量
    uint256 public _maxTxAmount = 1000000000 * 10**8;
	//出售多少代币并添加到流动池
    uint256 private numTokensSellToAddToLiquidity = 100000 * 10**8;
    //交换更新前的最小令牌数
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
	//锁定交易
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () public {
		//创建者拥有所有rTotal？
        _rOwned[_msgSender()] = _rTotal;
       
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
         // Create a uniswap pair for this new token
		 //创建一个新的交易对
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;
        _teamAddr = 0xeAE1073d8671412a09fd077D710a5E88B7140d95;
        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }
	//返回名称
    function name() public view returns (string memory) {
        return _name;
    }
	//返回简称
    function symbol() public view returns (string memory) {
        return _symbol;
    }
	//返回代币精度
    function decimals() public view returns (uint8) {
        return _decimals;
    }
	//返回总量
    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }
	//返回账户的余额
    function balanceOf(address account) public view override returns (uint256) {
		//判断是否是被排除的账户
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }
	//转账
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
	//返回授权的余额
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
	//进行授权
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
	//从授权的地址转账
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
	//增加授权
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
	//减少授权
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
	//是否被排除在奖励外？被排除的没有分红
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
	//费用合计
    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }
	//传递？
    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
		//判断是否是排除的地址，排除的地址不能调用此函数
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        //获取rAmount
		(uint256 rAmount,,,,,) = _getValues(tAmount);
		//r个人余额减少
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
		//r代币总量减少
        _rTotal = _rTotal.sub(rAmount);
		//积累费用增加
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }
	//token反射(净值数量）
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        //传入总量是否小于总量
		require(tAmount <= _tTotal, "Amount must be less than supply");
        //如果不扣除运费？
		if (!deductTransferFee) {
			//获取rAmount r传入总量？
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
			//获取rTransferAmount r转移金额？
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }
	//来自反射的令牌（原始的令牌数量）
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        //判断数量是否小于反射总量
		require(rAmount <= _rTotal, "Amount must be less than total reflections");
		//当前汇率？
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }
	//从奖励中排除（加入黑名单）
    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        //如果净值大于0
		if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
		//添加到mapping集合
        _isExcluded[account] = true;
        _excluded.push(account);
    }
	//移除黑名单（代币归零）
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
				//把他移到数组最后一位
                _excluded[i] = _excluded[_excluded.length - 1];
				//代币归零
                _tOwned[account] = 0;
				//移除黑名单
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }
	
	//设置不需要手续费的地址
        function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    //移除不需要手续费的地址
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    //设置交易手续费
    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }
    //设置流动性手续费
    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }
	//设置团队手续费
	function setTeamFeePercent(uint256 teamFee) external onlyOwner() {
        _teamFee = teamFee;
    }
	//设置团队地址
	function setTeamAddr(address teamAddress) external onlyOwner() {
        _teamAddr = teamAddress;
    }
	//设置最大发送量
    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(
            10**2
        );
    }
	//是否开启交易？
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
	 //交换时从uniswapv2外部接收eth
    receive() external payable {}
	//映射费用？（当前费用合计）
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
	//获取值？  传入原始值
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        //获取原始值
		(uint256 tTransferAmount, uint256 tFee, uint256 tTeamFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tTeamFee, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }
	//获取原始值
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256) {
        //原始份额的分红手续费
		uint256 tFee = calculateTaxFee(tAmount);
		//原始份额的流动性手续费
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
		uint256 tTeamFee = calculateTeamFee(tAmount);
		//转账金额为原金额减去交易费
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tTeamFee);
        return (tTransferAmount, tFee, tTeamFee, tLiquidity);
    }
	//获取净值
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tTeamFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        //乘现在汇率
		uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
		uint256 rTeamFee = tTeamFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rTeamFee);
        return (rAmount, rTransferAmount, rFee);
    }
	//获取teamFee的相关金额
	    function _getTeamFeeValues(uint256 tAmount) private view returns (uint256, uint256) {
		uint256 currentRate = _getRate();
		uint256 tTeamFee = calculateTeamFee(tAmount);
		uint256 rTeamFee = tTeamFee.mul(currentRate);
        return (tTeamFee,rTeamFee);
    }
	//获取当前费率
    function _getRate() private view returns(uint256) {
		//获取当前供应量
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		//总净值除以总份额
        return rSupply.div(tSupply);
    }
	//获取当前供应量
    function _getCurrentSupply() private view returns(uint256, uint256) {
        //当前r总量
		uint256 rSupply = _rTotal;
        //当前t总量
		uint256 tSupply = _tTotal;
		//遍历黑名单地址，把黑名单的rowned和towned去除
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
	//获取流动性（传入原始流动性）
    function _takeLiquidity(uint256 tLiquidity) private {
		//获取费率
        uint256 currentRate =  _getRate();
		//获取净值流动性
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
		//如果是黑名单账户
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }
    //计算交易手续费
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }
	//流动性手续费
    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(
            10**2
        );
    }
	//计算团队手续费
	    function calculateTeamFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_teamFee).div(
            10**2
        );
    }
    //移除所有费用
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
		_previousTeamFee = _teamFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
		_teamFee = 0;
    }
    //恢复所有费用
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
	//是否是免手续费地址
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
	//授权代币的方法
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
		
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	//转账方法
    function _transfer(address from,address to,uint256 amount) private {
		//判断地址是否为0，转账是否大于0
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
		//判断转出或接收地址是否是创建者，如果不是有转账限额
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
		//该合同地址的令牌余额是否超过
		//我们需要发起掉期+流动性锁定的代币？
		//还有，不要陷入循环流动性事件。
		//此外，如果发送方是uniswap对，则不要交换和液化。
		//获取代币余额
        uint256 contractTokenBalance = balanceOf(address(this));
        //如果代币余额大于最大转账金额
        if(contractTokenBalance >= _maxTxAmount)
        {
            contractTokenBalance = _maxTxAmount;
        }
        //代币余额是否达到了注入流动池的数量
        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if (
		//代币余额达到注入流动池的数量，没有锁定交易，不是买入代币，已经开启交易
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != uniswapV2Pair &&
            swapAndLiquifyEnabled
        ) {
			//代币余额等于注入流动池数量
            contractTokenBalance = numTokensSellToAddToLiquidity;
            //add liquidity  添加流动性
            swapAndLiquify(contractTokenBalance);
        }
        
        //indicates if fee should be deducted from transfer  指示费用是否应从转账中扣除
        bool takeFee = true;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee 如果任何帐户属于免手续费的帐户，则删除该费用
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        
        //transfer amount, it will take tax, burn, liquidity fee，转移金额，这将需要税收，烧钱，流动资金费
		//代币转移
        _tokenTransfer(from,to,amount,takeFee);
    }
	//添加流动性（添加的时候锁交易）
    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
		//把钱一分为二
        uint256 half = contractTokenBalance.div(2);
        uint256 otherHalf = contractTokenBalance.sub(half);

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
		//捕捉合同当前的ETH余额。
		//这样我们就可以准确地捕捉到
		//掉期产生，并且不使流动性事件包括任何ETH
		//已手动发送到合同
        uint256 initialBalance = address(this).balance;

        // swap tokens for ETH
		//把币换成一半的ETH
        swapTokensForEth(half); // <- this breaks the ETH -> HATE swap when swap+liquify is triggered

        // how much ETH did we just swap into?刚刚获得了多少ETH？
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
		//添加流动性
        addLiquidity(otherHalf, newBalance);
        
        emit SwapAndLiquify(half, newBalance, otherHalf);
    }
	//把币换成ETH
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
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        //判断是否收取费用
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
	//下面为4种不同的转账情况

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		(uint256 tTeamFee,uint256 rTeamFee) = _getTeamFeeValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		//团队地址增加
		_tOwned[_teamAddr] = _tOwned[_teamAddr].add(tTeamFee);
        _rOwned[_teamAddr] = _rOwned[_teamAddr].add(rTeamFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
		(uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		 (uint256 tTeamFee,uint256 rTeamFee) = _getTeamFeeValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
		//团队地址增加
		_tOwned[_teamAddr] = _tOwned[_teamAddr].add(tTeamFee);
        _rOwned[_teamAddr] = _rOwned[_teamAddr].add(rTeamFee);        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		 (uint256 tTeamFee,uint256 rTeamFee) = _getTeamFeeValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);  
		//团队地址增加
		_tOwned[_teamAddr] = _tOwned[_teamAddr].add(tTeamFee);
        _rOwned[_teamAddr] = _rOwned[_teamAddr].add(rTeamFee);		
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
	//转移两者排除？  传入发送者，接收者和原始份额？
        function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
			//获取各种值
         (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
		 (uint256 tTeamFee,uint256 rTeamFee) = _getTeamFeeValues(tAmount);
        //发送者减少
		_tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
		//接收者增加
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
		//团队地址增加
		_tOwned[_teamAddr] = _tOwned[_teamAddr].add(tTeamFee);
        _rOwned[_teamAddr] = _rOwned[_teamAddr].add(rTeamFee);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    

}