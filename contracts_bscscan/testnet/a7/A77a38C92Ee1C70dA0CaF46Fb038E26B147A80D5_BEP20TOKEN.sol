/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

pragma solidity 0.6.9;
// SPDX-License-Identifier: Unlicensed
interface IBEP20 {

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
 * @dev Returns the decimals.
 */
    function decimals() external view returns (uint8);

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

library SafeMath {
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

// pragma solidity >=0.5.0;

interface IPancakeV2Factory {
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

interface IPancakeV2Pair {
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

interface IPancakeV2Router01 {
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
    function getotal_AmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getotal_AmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getotal_AmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getotal_AmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IPancakeV2Router02 is IPancakeV2Router01 {
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


contract BEP20TOKEN is Context, IBEP20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _TotalOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;

    mapping (address => bool) private _isExcluded;
    mapping(address => uint) public lockTime;
    address public icoAddress;
    bool public lock = true; 


    address[] private _excluded;


    uint256 private constant MAX = ~uint256(0);
//***********************************************************************************************************
    uint256 private _TotalSupply = 5000 * 10**6 * 10**18;// Supply 5,000,000,000

    uint256 private _rTotal = (MAX - (MAX % _TotalSupply));
    uint256 private _totalFeeTotal;

    string constant private _name = "Digital Seed Boost";
    string constant private _symbol = "DSBT";
    uint8 constant private _decimals = 18;

    uint256 public _totaltaxFee = 1; // 1% for token administration
    uint256 private _previousTaxFee = _totaltaxFee;

    uint256 public _Total_liquidityFee = 3;//3% liquidity pancakeswap
    uint256 private _previousLiquidityFee = _Total_liquidityFee;

    uint256 public _TotalAdminFee = 15; //1.5% for holders awards 
    uint256 private _previousAdminFee = _TotalAdminFee;
    
    uint256 public _TotalPartnerFee = 3; //3% Founding partners
    uint256 private _previousPartnerFee = _TotalPartnerFee;

    uint256 public _TotalburnFee = 15;// 1.5% Auto burn
    uint256 private _previousBurnFee = _TotalburnFee;
//***********************************************************************************************************

    IPancakeV2Router02 public pancakeV2Router;
    address public pancakeV2Pair;
    address payable public _AdminWalletAddress;
    address payable public _PartnerWalletAddress;
    address payable public _burnWalletAddress;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;

    uint256 public _maxTxAmount = 1000 * 10**6 * 10**18;

    event Burn(address indexed sender, uint amount);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
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

    constructor () public {
        _AdminWalletAddress = 0xe0EC0C4bA98f27CeC1C0Bc9e890B336f2cD4465c;
        _burnWalletAddress = 0x000000000000000000000000000000000000dEaD;
        _PartnerWalletAddress = 0x91e3988d9DE9FE5a869e0EBeD51a8Ee8F0fF09f3;
       

        _rOwned[msg.sender] = _rTotal; // owner 
   

        IPancakeV2Router02 _pancakeV2Router = IPancakeV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
         // Create a pancakeswap pair for this new token
        pancakeV2Pair = IPancakeV2Factory(_pancakeV2Router.factory())
            .createPair(address(this), _pancakeV2Router.WETH());
        // set the rest of the contract variables
        pancakeV2Router = _pancakeV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] =true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), msg.sender, _rTotal); 
    }

    
    function setIcoContract(address icoA) external onlyOwner() {
        icoAddress = icoA;
    }
    
    function unlock() external onlyOwner() {
        lock = false;
    }
    
    function lockTransfer(uint time,address holder) public returns (bool){
        require(msg.sender == icoAddress);
        lockTime[holder] = time;
    }
    
    
    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _TotalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _TotalOwned[account];
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
        return _totalFeeTotal;
    }

    function deliver(uint256 total_Amount, uint256 tax_fee) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256[3] memory rValues,) =  _getotalValues(total_Amount, tax_fee);
        uint256 rAmount = rValues[0];

        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _totalFeeTotal = _totalFeeTotal.add(total_Amount);
    }

    function reflectionFromToken(uint256 total_Amount, bool deductTransferFee,uint256 tax_fee) public view returns(uint256) {
        require(total_Amount <= _TotalSupply, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256[3] memory rValues,) =  _getotalValues(total_Amount,tax_fee);
            uint256 rAmount = rValues[0];

            return rAmount;
        } else {
            (uint256[3] memory rValues,) =  _getotalValues(total_Amount, tax_fee);
            uint256 rTransferAmount = rValues[1];

            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _TotalOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _TotalOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner() {
        //require(taxFee <= 3, "Max fee 3%");
        _totaltaxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner() {
        //require(liquidityFee <= 3, "Max fee 3%");
        _Total_liquidityFee = liquidityFee;
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = maxTxPercent;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to receive Eth from pancakeV2Router when swapping
    receive() external payable {}

    function _reflectotalFee(uint256 rFee, uint256 totalFee) private {

            // Reflect fee between holders as usual
            _rTotal = _rTotal.sub(rFee);
            _totalFeeTotal = _totalFeeTotal.add(totalFee);
        
    }

    function _getotalValues(uint256 total_Amount, uint256 tax_fee) private view returns (uint256[3] memory, uint256[6] memory) {
        uint256[6] memory totalValues = _gettotalValues(total_Amount, tax_fee);
        uint256[3] memory rValues = _getRValues(total_Amount, totalValues[1], totalValues[2], totalValues[3], totalValues[4], totalValues[5],  _getRate());

        return (rValues, totalValues);
    }

    function _gettotalValues(uint256 total_Amount, uint256 tax_fee) private view returns (uint256[6] memory) {
        uint256[6] memory totalValues = [0, calculateTaxFee(total_Amount, tax_fee), calculateLiquidityFee(total_Amount), calculateAdminFee(total_Amount),calculatePartnerFee(total_Amount), calculateBurnFee(total_Amount)];
        totalValues[0] = _gettotal_TransferAmount(total_Amount, totalValues);

        return totalValues;
    }

    function _getRValues(uint256 total_Amount, uint256 totalFee, uint256 total_Liquidity, uint256 total_Admin, uint256 total_Partner,uint256 total_Burn,   uint256 currentRate) private pure returns (uint256[3] memory) {
        uint256 rAmount = total_Amount.mul(currentRate);
        uint256 rFee = totalFee.mul(currentRate);
        uint256 rLiquidity = total_Liquidity.mul(currentRate);
        uint256 rAdmin = total_Admin.mul(currentRate);
        uint256 rBurn = total_Burn.mul(currentRate);
        uint256 rPartner = total_Partner.mul(currentRate);

        uint256[6] memory tempRValues = [rAmount, rLiquidity, rFee, rAdmin, rPartner, rBurn];

        // uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rMarketing).sub(rBurn).sub(rTresor);
        // uint256 rTransferAmount = _getRTransferAmount(rAmount, rLiquidity, rFee, rMarketing, rBurn, rTresor);
        uint256[3] memory rValues = [rAmount, _getRTransferAmount(tempRValues), rFee];

        // return (rAmount, rTransferAmount, rFee);
        return rValues;
    }

    function _gettotal_TransferAmount(uint256 total_Amount, uint256[6] memory totalValues) private pure returns(uint256) {
        // return total_Amount.sub(totalFee).sub(total_Liquidity).sub(total_Marketing).sub(total_Burn).sub(tBuyback);
        return total_Amount.sub(totalValues[1]).sub(totalValues[2]).sub(totalValues[3]).sub(totalValues[4]).sub(totalValues[5]);
    }

    function _getRTransferAmount(uint256[6] memory rValues) private pure returns(uint256) {
        return rValues[0].sub(rValues[2]).sub(rValues[1]).sub(rValues[3]).sub(rValues[4]).sub(rValues[5]);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 total_Supply) = _getCurrentotal_Supply();
        return rSupply.div(total_Supply);
    }

    function _getCurrentotal_Supply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 total_Supply = _TotalSupply;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _TotalOwned[_excluded[i]] > total_Supply) return (_rTotal, _TotalSupply);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            total_Supply = total_Supply.sub(_TotalOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_TotalSupply)) return (_rTotal, _TotalSupply);
        return (rSupply, total_Supply);
    }   

    function _takeLiquidity(uint256 total_Liquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = total_Liquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if(_isExcluded[address(this)])
            _TotalOwned[address(this)] = _TotalOwned[address(this)].add(total_Liquidity);
    }

    function _takeAdmin(uint256 total_Marketing) private {
        uint256 currentRate =  _getRate();
        uint256 rMarketing = total_Marketing.mul(currentRate);
        _rOwned[_AdminWalletAddress] = _rOwned[_AdminWalletAddress].add(rMarketing);
        if(_isExcluded[_AdminWalletAddress])
            _TotalOwned[_AdminWalletAddress] = _TotalOwned[_AdminWalletAddress].add(total_Marketing);
    }

    function _takeBurn(uint256 total_Burn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = total_Burn.mul(currentRate);
        _rOwned[_burnWalletAddress] = _rOwned[_burnWalletAddress].add(rBurn);
        if(_isExcluded[_burnWalletAddress]) {
            _TotalOwned[_burnWalletAddress] = _TotalOwned[_burnWalletAddress].add(total_Burn);
        }
    }

    function _takePartner(uint256 tBuyback) private {
        uint256 currentRate =  _getRate();
        uint256 rTresor = tBuyback.mul(currentRate);
        _rOwned[_PartnerWalletAddress] = _rOwned[_PartnerWalletAddress].add(rTresor);
        if(_isExcluded[_PartnerWalletAddress])
            _TotalOwned[_PartnerWalletAddress] = _TotalOwned[_PartnerWalletAddress].add(tBuyback);
    }



    function calculateTaxFee(uint256 _amount, uint256 tax_fee) pure private returns (uint256) {
        return _amount.mul(tax_fee).div(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_Total_liquidityFee).div(
            10**2
        );
    }

    function calculateAdminFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_TotalAdminFee).div(
            10**3
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_TotalburnFee).div(
            10**3
        );
    }

    function calculatePartnerFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_TotalPartnerFee).div(
            10**2
        );
    }




    function removeAllFee() private {
        if(_totaltaxFee == 0 && _Total_liquidityFee == 0  && _TotalburnFee == 0 && _TotalPartnerFee == 0 && _TotalAdminFee == 0) return;

        _previousTaxFee = _totaltaxFee;
        _previousLiquidityFee = _Total_liquidityFee;
        _previousPartnerFee = _TotalPartnerFee;
        _previousAdminFee = _TotalAdminFee;
        _previousBurnFee = _TotalburnFee;

        _totaltaxFee = 0;
        _Total_liquidityFee = 0;
        _TotalAdminFee = 0;
        _TotalPartnerFee = 0;
        _TotalburnFee = 0;
    }

    function restoreAllFee() private {
        _totaltaxFee = _previousTaxFee;
        _Total_liquidityFee = _previousLiquidityFee;
        _TotalPartnerFee = _previousPartnerFee;
        _TotalAdminFee = _previousAdminFee;
        _TotalburnFee = _previousBurnFee;
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

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        if(sender != icoAddress){
            if(lock == true){
                require(block.timestamp > lockTime[msg.sender], "lock time has not expired");
            }        
            restoreAllFee();
        }else{
            removeAllFee();
        }
        
        if(sender != owner() && recipient != owner())
          require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            
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


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeV2Router), tokenAmount);

        // add the liquidity
        pancakeV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }



    function _transferStandard(address sender, address recipient, uint256 total_Amount) private {
        (uint256[3] memory rValues, uint256[6] memory totalValues) =  _getotalValues(total_Amount, _totaltaxFee);
        uint256 rAmount = rValues[0];
        uint256 rTransferAmount = rValues[1];
        uint256 rFee = rValues[2];
        uint256 total_TransferAmount = totalValues[0];
        uint256 totalFee = totalValues[1];
        uint256 total_Liquidity = totalValues[2];
        uint256 total_Admin = totalValues[3];
        uint256 total_Partner = totalValues[4];
        uint256 total_Burn = totalValues[5];


        decreaseROwned(sender, rAmount);
        increaseROwned(recipient, rTransferAmount);
        _takeLiquidity(total_Liquidity);
        _takeAdmin(total_Admin);
        _takeBurn(total_Burn);
        _takePartner(total_Partner);
        _reflectotalFee(rFee, totalFee);
        emit Transfer(sender, recipient, total_TransferAmount);
        emit Transfer(sender, _AdminWalletAddress, total_Admin);
        emit Transfer(sender, _PartnerWalletAddress, total_Partner);
        emit Transfer(sender, _burnWalletAddress, total_Burn);
    }

    function _transferToExcluded(address sender, address recipient, uint256 total_Amount) private {
        (uint256[3] memory rValues, uint256[6] memory totalValues) =  _getotalValues(total_Amount, _totaltaxFee);
        uint256 rAmount = rValues[0];
        uint256 rTransferAmount = rValues[1];
        uint256 rFee = rValues[2];
        uint256 total_TransferAmount = totalValues[0];
        uint256 totalFee = totalValues[1];
        uint256 total_Liquidity = totalValues[2];
        uint256 total_Admin = totalValues[3];
        uint256 total_Partner = totalValues[4];
        uint256 total_Burn = totalValues[5];


        decreaseROwned(sender, rAmount);
        increaseROwned(recipient, rTransferAmount);
        _takeLiquidity(total_Liquidity);
        _takeAdmin(total_Admin);
        _takeBurn(total_Burn);
        _takePartner(total_Partner);
        _reflectotalFee(rFee, totalFee);
        emit Transfer(sender, recipient, total_TransferAmount);
        emit Transfer(sender, _AdminWalletAddress, total_Admin);
        emit Transfer(sender, _PartnerWalletAddress, total_Partner);
        emit Transfer(sender, _burnWalletAddress, total_Burn);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 total_Amount) private {
        (uint256[3] memory rValues, uint256[6] memory totalValues) =  _getotalValues(total_Amount, _totaltaxFee);
        uint256 rAmount = rValues[0];
        uint256 rTransferAmount = rValues[1];
        uint256 rFee = rValues[2];
        uint256 total_TransferAmount = totalValues[0];
        uint256 totalFee = totalValues[1];
        uint256 total_Liquidity = totalValues[2];
        uint256 total_Admin = totalValues[3];
        uint256 total_Partner = totalValues[4];
        uint256 total_Burn = totalValues[5];


        decreaseROwned(sender, rAmount);
        increaseROwned(recipient, rTransferAmount);
        _takeLiquidity(total_Liquidity);
        _takeAdmin(total_Admin);
        _takeBurn(total_Burn);
        _takePartner(total_Partner);
        _reflectotalFee(rFee, totalFee);
        emit Transfer(sender, recipient, total_TransferAmount);
    }
    
    function _transferBothExcluded(address sender, address recipient, uint256 total_Amount) private {
        (uint256[3] memory rValues, uint256[6] memory totalValues) =  _getotalValues(total_Amount, _totaltaxFee);
        uint256 rAmount = rValues[0];
        uint256 rTransferAmount = rValues[1];
        uint256 rFee = rValues[2];
        uint256 total_TransferAmount = totalValues[0];
        uint256 totalFee = totalValues[1];
        uint256 total_Liquidity = totalValues[2];
        uint256 total_Admin = totalValues[3];
        uint256 total_Partner = totalValues[4];
        uint256 total_Burn = totalValues[5];


        decreaseROwned(sender, rAmount);
        increaseROwned(recipient, rTransferAmount);
        _takeLiquidity(total_Liquidity);
        _takeAdmin(total_Admin);
        _takeBurn(total_Burn);
        _takePartner(total_Partner);
        _reflectotalFee(rFee, totalFee);
        emit Transfer(sender, recipient, total_TransferAmount);
        emit Transfer(sender, _AdminWalletAddress, total_Admin);
        emit Transfer(sender, _PartnerWalletAddress, total_Partner);
        emit Transfer(sender, _burnWalletAddress, total_Burn);
    }
    function decreaseTOwned(address sender, uint256 total_Amount) private {
        _TotalOwned[sender] = _TotalOwned[sender].sub(total_Amount);
    }

    function decreaseROwned(address sender, uint256 rAmount) private {
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
    }

    function increaseROwned(address recipient, uint256 rTransferAmount) private {
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
    }

    function increaseTOwned(address recipient, uint256 total_TransferAmount) private {
        _TotalOwned[recipient] = _TotalOwned[recipient].add(total_TransferAmount);
    }


    function setAdminWalletAddress(address payable newAdress)  external onlyOwner() {
        _AdminWalletAddress = newAdress;
    }



    function setPartnerWalletAddress(address payable newAdress)  external onlyOwner() {
        _PartnerWalletAddress = newAdress;
    }

  

    function setBurnWalletAddress(address payable newAdress)  external onlyOwner() {
        _burnWalletAddress = newAdress;
    }




    function setAdminFeePercent(uint256 adminFee) external onlyOwner() {
       // require(marketingFee <= 3, "Max fee 3%");
        _TotalAdminFee = adminFee;
    }

    function setPartnerFeePercent(uint256 partnerFee) external onlyOwner() {
       // require(stakingFee <= 3, "Max fee 3%");
        _TotalPartnerFee = partnerFee;
    }

    function setBurnFeePercent(uint256 burnFee) external onlyOwner() {
        //require(burnFee <= 3, "Max fee 3%");
        _TotalburnFee = burnFee;
    }


}