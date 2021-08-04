/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

//TO-DO Testing;
pragma solidity ^0.8.5;
// SPDX-License-Identifier: MIT
// Developed by: jawadklair

interface IBEP20 {

    /**  
     * @dev Returns the total tokens supply  
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data; // msg.data is used to handle array, bytes, string 
    }
}


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
     * increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
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
     * - the calling contract must have an BNB balance of at least `value`.
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
    
    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    
    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
        _previousOwner = address(0);
    }
}

// pragma solidity >=0.5.0;

interface ISummitSwapFactory {
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

interface ISummitSwapPair {
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

interface ISummitSwapRouter01 {
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

interface ISummitSwapRouter02 is ISummitSwapRouter01 {
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

contract KTest_Liquidity_Provider is Context, Ownable{
    using SafeMath for uint256;
    using Address for address;

    // Below Fees to be deducted and sent as BNB/BUSD/or Kapex
    uint256 public _feeMarketing = 0; // marketing fee 0%
    uint256 private _previousMarketingFee = _feeMarketing; // marketing fee

    uint256 public _feeDev = 50; // marketing fee 0.5%
    uint256 private _previousDevFee = _feeMarketing; // marketing fee
    
    uint256 public _feeBnbLiquidity = 650; // BNB liquidity fee 6.5%
    uint256 private _previousBNBLiquidityFee = _feeBnbLiquidity; // restore BNB liquidity fee

    uint256 public _feeKodaStakingPool = 0; // BNB liquidity fee 6.5%
    uint256 private _previousKodaStakingPoolFee = _feeKodaStakingPool; // restore BNB liquidity fee

    uint256 public _feeBusdLiquidity = 50; // BUSD liquidity fee 0.5%
    uint256 private _previousBUSDLiquidityFee = _feeBusdLiquidity; // restore BUSD liquidity fee

    uint256 public _feeKapexLiquidity = 0; // Kapex liquidity fee 0%
    uint256 private _previousKapexLiquidityFee = _feeKapexLiquidity; // restore kapex liquidity fee

    uint256 private _feeTotalBNBDeductable = _feeMarketing.add(_feeBnbLiquidity).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool); // all liquidity + dev + marketing fee on each transaction
    uint256 private _previousBNBDeductableFee = _feeTotalBNBDeductable; // restore old deductable fee

    address payable public _devAddress             = payable(0x0000000000000000000000000000000000000000); // TO-DO dev Address
    address payable public _burnAddress            = payable(0x000000000000000000000000000000000000dEaD); // Burn Address
    address payable public _busdAddress            = payable(0x0000000000000000000000000000000000000000); // TO-DO BUSD Address
    address payable public _kapexAddress           = payable(0x0000000000000000000000000000000000000000); // TO-DO kapex token Address
    address payable public _kodaTokenAddress       = payable(0x0000000000000000000000000000000000000000); // TO-DO koda token Address
    address payable public _marketingAddress       = payable(0x0000000000000000000000000000000000000000); // TO-DO Marketing Address
    address payable public _kodaStakingPoolAddress = payable(0x0000000000000000000000000000000000000000); // TO-DO koda staking pool address

    IBEP20 public kodaToken; 

    ISummitSwapRouter02 public summitSwapRouter; // Summitswap router assiged using address
    address public summitSwapPair; // for creating WETH pair with our token
    
    bool inSwapAndLiquify; // after each successfull swapandliquify disable the swapandliquify

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } // modifier to after each successfull swapandliquify disable the swapandliquify

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiqiudity
    ); // fire event how many tokens were swapedandLiquified

    constructor () {
        
        ISummitSwapRouter02 _summitSwapRouter = ISummitSwapRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        summitSwapRouter = _summitSwapRouter;
    }
    
    /**  
     * @dev set's marketing fee percentage
     */
    function setMarketingFeePercent(uint256 Fee) external onlyOwner {
        _feeMarketing = Fee;
        _feeTotalBNBDeductable = _feeBnbLiquidity.add(_feeMarketing).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool);
    }

    /**  
     * @dev set's dev fee percentage
     */
    function setDevFeePercent(uint256 Fee) external onlyOwner {
        _feeDev = Fee;
        _feeTotalBNBDeductable = _feeBnbLiquidity.add(_feeMarketing).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool);
    }
    
    /**  
     * @dev set's BNB liquidity fee percentage
     */
    function setBNBLiquidityFeePercent(uint256 Fee) external onlyOwner {
        _feeBnbLiquidity = Fee;
        _feeTotalBNBDeductable = _feeBnbLiquidity.add(_feeMarketing).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool);
    }

    /**  
     * @dev set's BUSD liquidity fee percentage
     */
    function setBUSDLiquidityFeePercent(uint256 Fee) external onlyOwner {
        _feeBusdLiquidity = Fee;
        _feeTotalBNBDeductable = _feeBnbLiquidity.add(_feeMarketing).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool);
    }

    /**  
     * @dev set's Kapex liquidity fee percentage
     */
    function setKapexLiquidityFeePercent(uint256 Fee) external onlyOwner {
        _feeKapexLiquidity = Fee;
        _feeTotalBNBDeductable = _feeBnbLiquidity.add(_feeMarketing).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool);
    }

    /**  
     * @dev set's Kapex liquidity fee percentage
     */
    function setKodaStakingPoolFeePercent(uint256 Fee) external onlyOwner {
        _feeKodaStakingPool = Fee;
        _feeTotalBNBDeductable = _feeBnbLiquidity.add(_feeMarketing).add(_feeDev).add(_feeBusdLiquidity).add(_feeKapexLiquidity).add(_feeKodaStakingPool);
    }

    /**  
     * @dev set's marketing address
     */
    function setMarketingAddress(address payable marketingAddress) external onlyOwner {
        _marketingAddress = marketingAddress;
    }

    /**  
     * @dev set's dev address
     */
    function setDevAddress(address payable devAddress) external onlyOwner {
        _devAddress = devAddress;
    }

    /**  
     * @dev set's BUSD address
     */
    function setBUSDAddress(address payable busdAddress) external onlyOwner {
        _busdAddress = busdAddress;
    }

    /**  
     * @dev set's kapex token address
     */
    function setKapexTokenAddress(address payable kapexAddress) external onlyOwner {
        _kapexAddress = kapexAddress;
    }

    /**  
     * @dev set's koda token address
     */
    function setKodaTokenAddress(address payable kodaAddress) external onlyOwner {
        _kodaTokenAddress = kodaAddress;
        kodaToken = IBEP20(_kodaTokenAddress);
    }

    /**  
     * @dev set's koda staking pool address
     */
    function setKodaStakingPoolAddress(address payable kodastakingAddress) external onlyOwner {
        _kodaStakingPoolAddress = kodastakingAddress;
    }

    function swapAndLiquifyTokens(uint256 amount) public onlyOwner {
        require(amount <= kodaToken.balanceOf(address(this)), "Amount is greater than contract koda token balance");
        _swapAndLiquify(amount);
    }

    //to recieve BNB from summitRouter when swaping
    receive() external payable {}

    /**  
     * @dev swapsAndLiquify tokens to summitswap if swapandliquify is enabled
     */
    function _swapAndLiquify(uint256 tokenBalance) private lockTheSwap {
        // first split contract balance into marketing fee and liquidity fee
        uint256 swapPercent = _feeDev.add(_feeMarketing).add(_feeKodaStakingPool).add(_feeBusdLiquidity/2).add(_feeBnbLiquidity/2).add(_feeKapexLiquidity/2);
        uint256 swapTokens = tokenBalance.div(_feeTotalBNBDeductable).mul(swapPercent);
        uint256 liquidityTokens = tokenBalance.sub(swapTokens);
        uint256 initialBalance = address(this).balance;
        
        swapTokensForBNB(swapTokens);

        uint256 transferredBalance = address(this).balance.sub(initialBalance);

        uint256 liquidityCount = 0;
        if(_feeBnbLiquidity > 0)
            liquidityCount.add(1);
        if(_feeBusdLiquidity > 0)
            liquidityCount.add(1);
        if(_feeKapexLiquidity > 0)
            liquidityCount.add(1);

        if(_feeDev > 0)
        {
            uint256 devAmount = transferredBalance.mul(_feeDev);
            devAmount = devAmount.div(swapPercent);

            _devAddress.transfer(devAmount);
        }

        if(_feeMarketing > 0)
        {
            uint256 marketingAmount = transferredBalance.mul(_feeMarketing);
            marketingAmount = marketingAmount.div(swapPercent);

            _marketingAddress.transfer(marketingAmount);
        }

        if(_feeBnbLiquidity > 0)
        {
            uint256 bnbLiquidityAmount = transferredBalance.mul(_feeKapexLiquidity/2);
            bnbLiquidityAmount = bnbLiquidityAmount.div(swapPercent);

            addLiquidityBNB(owner(), liquidityTokens.div(liquidityCount), bnbLiquidityAmount);

            emit SwapAndLiquify(liquidityTokens, bnbLiquidityAmount, liquidityTokens);
        }

        if(_feeBusdLiquidity > 0)
        {
            uint256 busdLiquidityAmount = transferredBalance.mul(_feeBusdLiquidity/2);
            busdLiquidityAmount = busdLiquidityAmount.div(swapPercent);

            swapBNBForTokens(_busdAddress, busdLiquidityAmount);
            IBEP20 token = IBEP20(_busdAddress);
            busdLiquidityAmount = token.balanceOf(address(this));
            token.approve(address(summitSwapRouter), busdLiquidityAmount);
            addLiquidityTokens(owner(), liquidityTokens.div(liquidityCount), _busdAddress, busdLiquidityAmount);

            emit SwapAndLiquify(liquidityTokens, busdLiquidityAmount, liquidityTokens);
        }

        if(_feeKapexLiquidity > 0)
        {
            uint256 kapexLiquidityAmount = transferredBalance.mul(_feeKapexLiquidity/2);
            kapexLiquidityAmount = kapexLiquidityAmount.div(swapPercent);

            swapBNBForTokens(_busdAddress, kapexLiquidityAmount);
            IBEP20 token = IBEP20(_kapexAddress);
            kapexLiquidityAmount = token.balanceOf(address(this));
            token.approve(address(summitSwapRouter), kapexLiquidityAmount);
            addLiquidityTokens(owner(), liquidityTokens.div(liquidityCount), _kapexAddress, kapexLiquidityAmount);

            emit SwapAndLiquify(liquidityTokens, kapexLiquidityAmount, liquidityTokens);
        }

        if(_feeKodaStakingPool > 0)
        {
            uint256 kodaStakingPoolAmount = transferredBalance.mul(_feeKodaStakingPool);
            kodaStakingPoolAmount = kodaStakingPoolAmount.div(swapPercent);

            swapBNBForTokens(_busdAddress, kodaStakingPoolAmount);
            IBEP20 token = IBEP20(_kapexAddress);
            kodaStakingPoolAmount = token.balanceOf(address(this));
            token.approve(address(summitSwapRouter), kodaStakingPoolAmount);
            token.transfer(_kodaStakingPoolAddress, kodaStakingPoolAmount);
        }
    }

    /**  
     * @dev swap's exact amount of tokens for BNB if swapandliquify is enabled
     */
    function swapTokensForBNB(uint256 tokenAmount) private {
        // generate the summitswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = summitSwapRouter.WETH();

        kodaToken.approve(address(summitSwapRouter), tokenAmount);

        // make the swap
        summitSwapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    /**  
     * @dev swap's exact amount of BNB for tokens if swapandliquify is enabled
     */
    function swapBNBForTokens(address tokenAddress, uint256 bnbAmount) private {
        // generate the summitswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = summitSwapRouter.WETH();
        path[1] = tokenAddress;

        // make the swap
        summitSwapRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: bnbAmount}(
            0, // accept any amount of tokens
            path,
            address(this),
            block.timestamp
        );
    }

    /**  
     * @dev add's liquidy to summitswap if swapandliquify is enabled
     */
    function addLiquidityBNB(address recipient, uint256 tokenAmount, uint256 bnbAmount) private {
        // approve token transfer to cover all possible scenarios
        kodaToken.approve(address(summitSwapRouter), tokenAmount);

        // add the liquidity
        summitSwapRouter.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );
    }

    /**  
     * @dev add's liquidy to summitswap if swapandliquify is enabled
     */
    function addLiquidityTokens(address recipient, uint256 tokenAmount, address tokenBAddress, uint256 tokenBAmount) private {
        // approve token transfer to cover all possible scenarios
        kodaToken.approve(address(summitSwapRouter), tokenAmount);

        // add the liquidity
        summitSwapRouter.addLiquidity(
            address(this),
            tokenBAddress,
            tokenAmount,
            tokenBAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );
    }

    //New SUmmitswap router version?
    //No problem, just change it!
    function setRouterAddress(address newRouter) public onlyOwner {
        ISummitSwapRouter02 _newSummitSwapRouter = ISummitSwapRouter02(newRouter);
        summitSwapPair = ISummitSwapFactory(_newSummitSwapRouter.factory()).createPair(address(this), _newSummitSwapRouter.WETH());
        summitSwapRouter = _newSummitSwapRouter;
    }
}