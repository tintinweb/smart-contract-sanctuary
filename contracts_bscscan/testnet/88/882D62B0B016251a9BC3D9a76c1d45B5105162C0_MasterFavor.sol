/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

pragma solidity 0.8.7;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}



//pragma solidity ^0.8.0;

/**
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

//pragma solidity ^0.8.0;

//import "../utils/Context.sol";

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


//pragma solidity ^0.8.0;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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



//pragma solidity ^0.8.0;

//import "../IERC20.sol";
//import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


//pragma solidity ^0.8.0;

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

//pragma solidity 0.8.7;

//import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "@nomiclabs/buidler/console.sol";

//Interfeace for interact with pancakeswap farm smart contract
interface IFarm {
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Favors to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Favors distribution occurs.
        uint256 accFavorPerShare; // Accumulated Favors per share, times 1e12. See below.
    }

    function enterStaking(uint256 _amount) external;
    function poolLength() external view returns (uint256);

    function poolInfo(uint _index) external view returns(PoolInfo memory);
    function leaveStaking(uint256 _amount) external;
    
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}

interface IPancakeRouter {
  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);
  
  function swapExactTokensForTokens(
  
    //amount of tokens we are sending in
    uint256 amountIn,
    //the minimum amount of tokens we want out of the trade
    uint256 amountOutMin,
    //list of token addresses we are going to trade in.  this is necessary to calculate amounts
    address[] calldata path,
    //this is the address we are going to send the output tokens to
    address to,
    //the last time that the trade is valid for
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

contract Router {
    address userOwner;
    IPancakeRouter PancakeRouter;
    IFarm pancakeswapFarm;
    IERC20 favor;
    IERC20 cake;
    IERC20 cake_favor_LP_pool;

    constructor (address _userOwner, address _PancakeRouter, address _pancakeswapFarm, address _favor, address _cake, address _cake_favor_LP_pool){
        userOwner = _userOwner;
        PancakeRouter = IPancakeRouter(_PancakeRouter);
        pancakeswapFarm = IFarm(_pancakeswapFarm);
        favor = IERC20(_favor);
        cake = IERC20(_cake);
        cake_favor_LP_pool = IERC20(_cake_favor_LP_pool);
    }

    function _getRewardFromPancakeSwap() private returns (uint){

        address[] memory path = new address[](2);

        path[0] = address(cake);
        path[1] = address(favor);

        uint cake_amount = cake.balanceOf(address(this));

        if (cake_amount != 0){
            cake.approve(address(PancakeRouter), cake_amount); 

            uint[] memory balances;
            balances = IPancakeRouter(PancakeRouter).swapExactTokensForTokens(cake_amount, 0, path, address(this), block.timestamp);  

            favor.transfer(userOwner, balances[1]);

            return balances[1];   
        }
        else {
            return 0;
        }   
    } 

    function deposit(uint _poolId, uint _amount) external returns(uint){
        pancakeswapFarm.poolInfo(_poolId).lpToken.approve(address(pancakeswapFarm), _amount);
        pancakeswapFarm.deposit(_poolId, _amount);


        return _getRewardFromPancakeSwap();

    }

    function withdraw(uint _poolId, uint _amount) external returns(uint){
        pancakeswapFarm.withdraw(_poolId, _amount);
        pancakeswapFarm.poolInfo(_poolId).lpToken.transfer(msg.sender, _amount);

        return _getRewardFromPancakeSwap();
    }    

}

contract RouterForPancakeswap {
    function create_router_contract(address MasterFavor, address PancakeRouter, address pancakeswapFarm, address favor, address cake, address cake_favor_LP_pool) public returns (Router) {
        
        Router rout;
        
            rout = new Router(
                address(MasterFavor),
                address(PancakeRouter),
                address(pancakeswapFarm),
                address(favor),
                address(cake),
                address(cake_favor_LP_pool)
            );
            
       

        return rout;
        
    }
}

interface IRouterForPancakeswap{
    function create_router_contract(address MasterFavor, address PancakeRouter, address pancakeswapFarm, address favor, address cake, address cake_favor_LP_pool) external returns (Router) ;
}


// MasterChef is the master of Favor. He can make Favor and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Favor is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterFavor is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;

    address public u_a;
    bool public zero;

    // Info of each user.
    struct UserInfo {
        uint amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Favors
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accFavorPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accFavorPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }



    struct FavorCampaignOwnerInformation {
        uint totalAmount;                //сумма, которую хочет собрать стартап
        uint contribution_percantage;    //процент от первоначальной суммы, contribution
        uint start_time;                 //начало работы фермы. Вложился первый инвестор
        uint period_of_life;             //время, за которое планирует собрать средства(в секундах)
        uint refund_period;              //время, за которое планирует вернуть средства
        bool farm_close;                 //флаг закрытия фермы(средства не принимаются и не возвращаются)
        uint refund_amount;              //средства, которые вернул владелец фермы
        uint deposit_in_last_period;     //сумма средств, вложенная инвесторами в последнем периоде
        bool start;                      //флаг начала работы фермы. Вложился первый инвестор
        uint stop_block;                 //последний блок, на котором выдавалась награда
        uint balanceInFavor;             //собранные средства в favor
        uint balanceInBUSD;              //собранные средства в BUSD
        uint[] CampaingPools;            //номера пулов, принадлежащих ферме
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;                                         // Address of LP token contract.
        address favorCampaignOwner;                             // Address of campaign owner
        uint256 pancakeswapPid;                                 // Pancakeswap farm pool id
        uint256 allocPoint;                                     // How many allocation points assigned to this pool. Favors to distribute per block.
        uint256 lastRewardBlock;                                // Last block number that Favors distribution occurs.
        uint256 accFavorPerShare;                               // Accumulated Favors per share, times 1e12. See below.
        bool onPancakeswap;
    }

    //структура LP токена, который может быть на ферме
    struct LP_token{
        address LP_token_address;   //адрес LP токенв
        uint pancakeSwapPoolId;     //номер пула с таким LP токеном на Pancakeswap
        bool onPancakeswap;         //флаг наличия пула на pancakeswap
    }

    //информация о пользователе
    struct User {
        mapping(address => HonorInfo) honors; //адрес владельца фермы -> информация о хонор(размер хонор и получал ли его)
        address rout_contract; //вспомогательный контракт для перезакладывания токенов на Pancakeswap
    }    

    //информация о honor
    struct HonorInfo{
        uint honor;  //размер honor
        bool getHonor;  //получал ли honor
    }

    // The Favor TOKEN!
    IERC20 public favor;

    IERC20 public BUSD;

    IERC20 public BNB;

    LP_token[] public LP_tokens_for_farm;

    IPancakeRouter public PancakeRouter; 
    address public favor_BUSD_LP_pool;
    address public cake_favor_LP_pool;
    // The SYRUP TOKEN!
    //SyrupBar public syrup;
    // Dev address.
    address public devaddr;
    // Favor tokens created per block.
    uint256 public favorPerBlock;
    // Bonus muliplier for early favor makers.
    uint256 public BONUS_MULTIPLIER = 1;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Info of user's honors and rout contracts
    mapping(address => User) public users;
    //Info about each farms
    mapping (address => FavorCampaignOwnerInformation) public favorCampaignOwnerInformation;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    //uint256 public totalAllocPoint = 0;
    // The block number when Favor mining starts.
    uint256 public startBlock;
    // Pancakeswap farm smart contract
    IFarm public pancakeswapFarm;
    // Cake Token address 
    IERC20 public cake;

    IRouterForPancakeswap public routerForPancakeSwap;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        /*
        IERC20 _favor,

        IERC20 _BUSD,

        IERC20 _BNB,

        IPancakeRouter _PancakeRouter,
        address _favor_BUSD_LP_pool,
    //    SyrupBar _syrup,
    //    address _devaddr,
        IFarm _pancakeswapFarm,
        IERC20 _cake,
        uint256 _favorPerBlock,
        uint256 _startBlock
        */
    ) public {
        //for test
        favor = IERC20(0x7127aE4F3DdeE1C6e405a5a9814cA5250Eb9cAa4);
        BUSD = IERC20(0xe6cB69edd7Fd31C178CE3C4bc47aF7A1A5A85e9c);
        favor_BUSD_LP_pool = 0x83f7F3aE82c575eb7380a449bFB6DA3ffdAd11d6;
        cake_favor_LP_pool = 0x83f7F3aE82c575eb7380a449bFB6DA3ffdAd11d6;
        PancakeRouter = IPancakeRouter(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
    //    syrup = _syrup;
        devaddr = 0xE9FCEB59C8BCef62c942026791737890aF66f790;// _devaddr;
        pancakeswapFarm = IFarm(0x5aeDD7ad66b792C635e894c35BA840c539457CAe);
        cake = IERC20(0x598edCFCF57bFA92D253cB6266684feDC81f498E);
        favorPerBlock = 100;
        startBlock = 123;

        add_LP_token(favor_BUSD_LP_pool);
        add_LP_token(address(favor));
        addFavorWell(0xE9FCEB59C8BCef62c942026791737890aF66f790, 1000, 30, 120, 120);

        routerForPancakeSwap = IRouterForPancakeswap(0xB9BF0A2244a8f5Ea6C4626A6477AC7e0DCCfdc8F);

        //totalAllocPoint = 1000;

    }

    //добавляет новый LP токен, который может быть на ферме
    function add_LP_token(address _LP_token) public onlyOwner{
        uint pancakeswapPid;
        bool _onPancakeswap;
        
        uint pid_index;
        uint pool_length = pancakeswapFarm.poolLength();
            
        for (pid_index = 0; pid_index < pool_length; pid_index++){          
            if (address(pancakeswapFarm.poolInfo(pid_index).lpToken) == _LP_token){
                    
                pancakeswapPid = pid_index;
                _onPancakeswap = true;
                break;
                    
            }
                
        }
        
        LP_tokens_for_farm.push(LP_token({
                                LP_token_address: _LP_token,
                                pancakeSwapPoolId: pancakeswapPid,
                                onPancakeswap: _onPancakeswap
            })); 
    }


    //добавляет ферму
    function addFavorWell(address _FavorCampaignOwner, uint _totalAmount, uint _contribution_percantage, uint _period_of_life, uint _refund_period) public onlyOwner{
        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[_FavorCampaignOwner];
        FCOI.totalAmount = _totalAmount;
        FCOI.contribution_percantage = _contribution_percantage;
        FCOI.period_of_life = _period_of_life;
        FCOI.refund_period = _refund_period;
        //FCOI.start_time = 0;
        //FCOI.start = false;
        //FCOI.farm_close = false;
        //FCOI.refund_amount = 0;


        uint allocationPoint;
        if (_contribution_percantage == 10){
            allocationPoint = 21;
        } else if (_contribution_percantage == 30){
            allocationPoint = 22;
        } else if (_contribution_percantage == 50){
            allocationPoint = 23;
        }

        for (uint i = 0; i < LP_tokens_for_farm.length; i++){
                add(allocationPoint, IERC20(LP_tokens_for_farm[i].LP_token_address), _FavorCampaignOwner, LP_tokens_for_farm[i].pancakeSwapPoolId , true, LP_tokens_for_farm[i].onPancakeswap);
        }
    }

    //владелец фермы вносит contribution + комиссия 5 процентов
    function makeContribution(address _FavorCampaignOwner) public {
        uint contribution;
        uint fee;
        address[] memory path = new address[](2);

        path[0] = address(BUSD);
        path[1] = address(favor);

        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[_FavorCampaignOwner];

        contribution = FCOI.totalAmount.div(100).mul(FCOI.contribution_percantage);
        fee = FCOI.totalAmount.div(100).mul(5);

        BUSD.transferFrom(msg.sender, address(this), contribution);
        BUSD.transferFrom(msg.sender, address(this), fee);
        BUSD.approve(address(PancakeRouter), contribution); 

        uint[] memory balances;
        balances = IPancakeRouter(PancakeRouter).swapExactTokensForTokens(contribution, 0, path, address(this), block.timestamp);

        FCOI.balanceInBUSD = balances[0];
        FCOI.balanceInFavor = balances[1];

        FCOI.start = true;
        

    }

/*
    function updateMultiplier(uint256 multiplierNumber) public onlyOwner {
        BONUS_MULTIPLIER = multiplierNumber;
    }
    */

/*
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    */

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken, address _favorCampaignOwner, uint256 _pancakeswapPid, bool _withUpdate, bool _onPancakeswap) public {
        if (_withUpdate) {
//            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        //totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            favorCampaignOwner: _favorCampaignOwner,
            pancakeswapPid: _pancakeswapPid,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accFavorPerShare: 0,
            onPancakeswap: _onPancakeswap
        }));

        favorCampaignOwnerInformation[_favorCampaignOwner].CampaingPools.push(poolInfo.length - 1);

        //updateStakingPool();

        _lpToken.approve(address(pancakeswapFarm), MAX_UINT);
    }


    // Update the given pool's Favor allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        //if (_withUpdate) {
       //     massUpdatePools();
       // }
        //uint256 prevAllocPoint = poolInfo[_pid].allocPoint;
        poolInfo[_pid].allocPoint = _allocPoint;
        /*
        if (prevAllocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint.sub(prevAllocPoint).add(_allocPoint);
            //updateStakingPool();
        }
        */
    }
    

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }


    // View function to see pending Favors on frontend.
    function pendingFavor(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accFavorPerShare = pool.accFavorPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            //uint256 favorReward = multiplier.mul(favorPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            uint256 favorReward = multiplier.mul(favorPerBlock).mul(pool.allocPoint).div(10);
            accFavorPerShare = accFavorPerShare.add(favorReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accFavorPerShare).div(1e12).sub(user.rewardDebt);
    }


/*
    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }
    */
    


    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint stop_block = favorCampaignOwnerInformation[pool.favorCampaignOwner].stop_block;
        uint block_to;

        if (stop_block == 0){
            block_to = block.number;
        } else {
            block_to = stop_block;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block_to);
        //uint256 favorReward = multiplier.mul(favorPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 favorReward = multiplier.mul(favorPerBlock).mul(pool.allocPoint);
        //favor.mint(favorReward.div(10));
        //favor.mint(address(syrup), favorReward);
        pool.accFavorPerShare = pool.accFavorPerShare.add(favorReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block_to;
    }

    function _return_honor (address _favorCampaignOwner, address _user) private{
        uint honor;
        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[_favorCampaignOwner];
        
        honor = users[_user].honors[_favorCampaignOwner].honor.div(FCOI.deposit_in_last_period).mul(FCOI.refund_amount);
        favor.transfer(_user, honor);
        users[_user].honors[_favorCampaignOwner].getHonor = true;
        
    }

    function _check_farm_state (address _favorCampaignOwner) private{
        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[_favorCampaignOwner];
        if (FCOI.farm_close != true && FCOI.start != false){
            if (FCOI.balanceInBUSD >= FCOI.totalAmount){
                        FCOI.start = false;
                        FCOI.start_time = block.timestamp;
                        FCOI.stop_block = block.number;
                        favor.transfer(_favorCampaignOwner, FCOI.balanceInFavor);
                        FCOI.refund_amount = FCOI.balanceInFavor;
            } else if (FCOI.start_time != 0 && FCOI.start_time + FCOI.period_of_life < block.timestamp){
                FCOI.start = false;
                FCOI.farm_close = true;
                FCOI.stop_block = block.number; //block.number.div(block.timestamp).mul(FCOI.period_of_life);
                FCOI.refund_amount = FCOI.balanceInFavor;
            }
        }
    }
    

    // Deposit LP tokens to MasterChef for Favor allocation.
    function deposit(uint256 _pid, uint256 _amount) public {

        require (_pid != 0, 'deposit Favor by staking');

        PoolInfo storage pool = poolInfo[_pid];
        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[pool.favorCampaignOwner];


        _check_farm_state(pool.favorCampaignOwner);
        require(FCOI.start == true, "Farm doesn't work");

        UserInfo storage user = userInfo[_pid][msg.sender];


        updatePool(_pid);

        uint favorFromPancakeswap;

        if (pool.onPancakeswap == true){
            favorFromPancakeswap = _depositOnPancakeswap(pool.pancakeswapPid, _amount, pool.lpToken, msg.sender);    
        }

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt) + favorFromPancakeswap;
            if(pending > 0) {
                uint256 half = pending.div(2);
                favorTransfer(msg.sender, half);
                //favor.transfer(address(this), pending - half);

                FCOI.balanceInFavor = FCOI.balanceInFavor.add(pending - half);

                address[] memory path = new address[](2);
                //address[] memory path ;
                path[0] = address(favor);
                path[1] = address(BUSD);
                

                FCOI.balanceInBUSD = IPancakeRouter(PancakeRouter).getAmountsOut(FCOI.balanceInFavor, path)[1];
                
                users[msg.sender].honors[pool.favorCampaignOwner].honor = users[msg.sender].honors[pool.favorCampaignOwner].honor.add(half);
                FCOI.deposit_in_last_period = FCOI.deposit_in_last_period.add(half);
        
    
            }
        }

        

        if (_amount > 0) {
            if (FCOI.start_time == 0){
                FCOI.start_time = block.timestamp;
            }
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);

        _check_farm_state(pool.favorCampaignOwner);
        
        emit Deposit(msg.sender, _pid, _amount);

        
    }

    function _checkRouter(address user_address) private returns (Router) {
        Router rout;
        if (users[user_address].rout_contract == address(0)){
                    
            /*
            rout = new Router(
                address(this),
                address(PancakeRouter),
                address(pancakeswapFarm),
                address(favor),
                address(cake),
                address(cake_favor_LP_pool)
            );
            */
            rout = routerForPancakeSwap.create_router_contract(address(this), address(PancakeRouter), address(pancakeswapFarm), address(favor), address(cake), cake_favor_LP_pool);
            
            users[user_address].rout_contract = address(rout);
            
        } else {
           rout = Router(users[user_address].rout_contract);
        }

        return rout;
    }

    function _depositOnPancakeswap(uint _pid, uint _amount, IERC20 _token, address _user) private returns(uint){
        Router rout = _checkRouter(_user);

        _token.safeTransfer(address(rout), _amount);
        return rout.deposit(_pid, _amount);
    }

    function _withdrawFromPancakeswap(uint _pid, uint _amount) private returns(uint){
        Router rout = _checkRouter(msg.sender);

        return rout.withdraw(_pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public {

       // require (_pid != 0, 'withdraw Favor by unstaking');
        PoolInfo storage pool = poolInfo[_pid];

        _check_farm_state(pool.favorCampaignOwner);

        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[pool.favorCampaignOwner];
        //require(FCOI.start == true, "Farm doesn't work");

        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        updatePool(_pid);

        

        uint favorFromPancakeswap;

        if (pool.onPancakeswap == true){
            favorFromPancakeswap = _withdrawFromPancakeswap(_pid, _amount);        
        }
        
        
        
        
        uint pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
        

        if(pending > 0) {
            uint256 half = pending.div(2);
            favorTransfer(msg.sender, half);
            favorTransfer(pool.favorCampaignOwner, pending - half);    

            if (_amount > 0 && FCOI.start == true){
                uint user_amount_in_farm;
                for (uint i = 0; i < FCOI.CampaingPools.length; i++){
                    user_amount_in_farm.add(userInfo[FCOI.CampaingPools[i]][msg.sender].amount);
                }
                
                if (user_amount_in_farm == 0){
                    FCOI.deposit_in_last_period.sub(users[msg.sender].honors[pool.favorCampaignOwner].honor).add(half);
                    users[msg.sender].honors[pool.favorCampaignOwner].honor = half;
                } else {
                    users[msg.sender].honors[pool.favorCampaignOwner].honor = users[msg.sender].honors[pool.favorCampaignOwner].honor.add(half);
                    FCOI.deposit_in_last_period.add(half);
                }
            }
            
        }
    
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);      
        }

        _check_farm_state(pool.favorCampaignOwner);
         

        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);


        FCOI.balanceInFavor = FCOI.balanceInFavor.add(pending);


        address[] memory path = new address[](2) ;
        path[0] = address(favor);
        path[1] = address(BUSD);

        FCOI.balanceInBUSD = IPancakeRouter(PancakeRouter).getAmountsOut(FCOI.balanceInFavor, path)[1];
        
        emit Withdraw(msg.sender, _pid, _amount);
    
    }

    function RefundHonor(address _favorCampaignOwnerInformation, uint _amount) public {
        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[_favorCampaignOwnerInformation];
        require(FCOI.start == false, "Farm is working yet");
        require(FCOI.farm_close == false, "Farm closed");

        uint honor_amount = FCOI.balanceInFavor;
        uint fee = FCOI.balanceInFavor.mul(5).div(100); 

        favor.transferFrom(msg.sender, address(this), _amount);
        FCOI.refund_amount = FCOI.refund_amount.add(_amount);

        if (honor_amount + fee <= FCOI.refund_amount || (
            FCOI.start_time + FCOI.refund_period <= block.timestamp &&
            FCOI.start_time != 0)) {
            FCOI.farm_close = true;
        }
    }
        
    function getHonor(address _favorCampaignOwnerInformation) public {
        address _user = msg.sender;
        FavorCampaignOwnerInformation storage FCOI = favorCampaignOwnerInformation[_favorCampaignOwnerInformation];
        require(FCOI.start == false, "Farm is working yet");
        require(FCOI.farm_close == true, "Farm doesn't refund favor yet");
        require(users[msg.sender].honors[_favorCampaignOwnerInformation].getHonor == false, "You already get honor");
        require(users[msg.sender].honors[_favorCampaignOwnerInformation].honor != 0, "You haven't honor");

        _return_honor(_favorCampaignOwnerInformation, _user);
    }

        
    


    /*
    // Stake Favor tokens to MasterChef
    function enterStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                favorTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);
    //    syrup.mint(msg.sender, _amount);
        emit Deposit(msg.sender, 0, _amount);
    }
    // Withdraw Favor tokens from STAKING.
    function leaveStaking(uint256 _amount) public {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending = user.amount.mul(pool.accFavorPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            favorTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accFavorPerShare).div(1e12);
    //    syrup.burn(msg.sender, _amount);
        emit Withdraw(msg.sender, 0, _amount);
    }
    */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pancakeswapFarm.withdraw(pool.pancakeswapPid, user.amount);
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Favor transfer function
    function favorTransfer(address _to, uint256 _amount) internal {
        uint256 favorBal = favor.balanceOf(address(this));
        require(favorBal >= _amount, "not enough favor in smart contract");
        favor.transfer(_to, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    /*
    // Withdraw cake reward from samrt contract to dev
    function cakeWithdraw() public onlyOwner {
        uint256 cakeBal = cake.balanceOf(address(this));
        cake.transfer(devaddr, cakeBal);
    }
    */

    // Withdraw favor reward from samrt contract to dev
    function favorWithdraw() public onlyOwner {
        uint256 favorBal = favor.balanceOf(address(this));
        favor.transfer(devaddr, favorBal);
    }
}