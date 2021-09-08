/**
 *Submitted for verification at BscScan.com on 2021-09-08
*/

/**
Welcome to REDBULLCOIN!

Join Our Telegram: https://t.me/REDBULLCOIN

Website: At launch

Total Fee: 17% 

12% ADA reflections

4% Marketing

5% auto LP

CONTRACT MECHANISMS Initial Max wallet: 1.5%
 */

pragma solidity ^0.8.6;

// SPDX-License-Identifier: MIT
interface IERC20 {

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return msg.data;
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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
        return functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: weiValue}(data);
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function getUnlockTime() public view returns (uint256) {
        return _lockTime;
    }
    
    function lock(uint256 time) public virtual onlyOwner { // Locks the contract for owner for the amount of time provided
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual { // Unlocks the contract for owner when _lockTime is exceeds
        require(
            _previousOwner == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTime, "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
    
}

/**
 * @dev Contract module which provides ability of changing less important parameters, like
 *  the router address (in case of a migration).
 */
contract Janitable is Context {

    address private _janitor;
    address private _previousJanitor;
    uint256 private _lockTimeJanitor;

    event JanitorTransferred(
        address indexed previousJanitor,
        address indexed newJanitor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial janitor.
     */
    constructor() {
        address msgSender = _msgSender();
        _janitor = msgSender;
        emit JanitorTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current janitor.
     */
    function janitor() public view returns (address) {
        return _janitor;
    }

    /**
     * @dev Throws if called by any account other than the janitor.
     */
    modifier onlyJanitor() {
        require(_janitor == _msgSender(), "Janitable: caller is not the janitor");
        _;
    }

    /**
     * @dev Leaves the contract without janitor. It will not be possible to call
     * `onlyJanitor` functions anymore. Can only be called by the current janitor.
     */
    function renounceJanitorship() public virtual onlyJanitor {
        emit JanitorTransferred(_janitor, address(0));
        _janitor = address(0);
    }

    /**
     * @dev Transfers janitorship of the contract to a new account (`newJanitor`).
     * Can only be called by the current janitor.
     */
    function transferJanitorship(address newJanitor) public virtual onlyJanitor {
        require(
            newJanitor != address(0),
            "Janitable: new janitor is the zero address"
        );
        emit JanitorTransferred(_janitor, newJanitor);
        _janitor = newJanitor;
    }

    function getUnlockTimeJanitor() public view returns (uint256) {
        return _lockTimeJanitor;
    }
    
    function lockJanitor(uint256 time) public virtual onlyJanitor { // Locks the contract for janitor for the amount of time provided
        _previousJanitor = _janitor;
        _janitor = address(0);
        _lockTimeJanitor = block.timestamp + time;
        emit JanitorTransferred(_janitor, address(0));
    }

    function unlockJanitor() public virtual { // Unlocks the contract for janitor when _lockTime is exceeds
        require(
            _previousJanitor == msg.sender,
            "You don't have permission to unlock"
        );
        require(block.timestamp > _lockTimeJanitor, "Contract is locked until 7 days");
        emit JanitorTransferred(_janitor, _previousJanitor);
        _janitor = _previousJanitor;
    }
    
}

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {

    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

}

// pragma solidity >=0.5.0;

interface IUniswapV2Pair {

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);

    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

}

// pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}

contract REDBULLCOIN is Context, IERC20, Ownable, Janitable {
    
    // Settings for the contract (supply, taxes, ...)

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _totalClaimed;

    string private _name = "RED BULL";
    string private _symbol = "REDBULLCOIN";
    uint8 private _decimals = 9;

    uint256 public _taxFee = 20; 
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 20;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _rewardFee = 100;
    uint256 private _previousRewardFee = _rewardFee;

    uint256 public _maxSellTransactionAmount = 250000 * 10**9; // can't sell more than this
    uint256 public _maxWalletToken = 900000000 * 10**9; // can't buy or accumulate more than this
    uint256 public _numTokensSellToAddToLiquidity = 20 * 10**9;
    
    mapping(address => uint256) private _bought;
    uint256 private _boughtTotal = 0;
    uint256 private _BNBRewards = 0;
    
    // 

    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => uint256) private _claimed;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isCleaned;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    IUniswapV2Router02 public pancakeswapV2Router; // Formerly immutable
    address public pancakeswapV2Pair; // Formerly immutable
    // Testnet (not working) : 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    // Testnet (working) : 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
    // V1 : 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F
    // V2 : 0x10ED43C718714eb63d5aA57B78B54704E256024E
    address public _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; 

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true; // Toggle swap & liquify on and off
    bool public tradingEnabled = false; // To avoid snipers
    bool public whaleProtectionEnabled = true; // To avoid whales
    bool public progressiveFeeEnabled = false; // The default is a fixed tax scheme
    bool public doSwapForRouter = true; // Toggle swap & liquify on and off for transactions to / from the router
    bool public _transferClaimedEnabled = true; // Transfer claim rights upon transfer of tokens

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokens,uint256 bnb);
    event AddedBNBReward(uint256 bnb);
    event ProgressiveFeeEnabled(bool enabled);
    event DoSwapForRouterEnabled(bool enabled);
    event TradingEnabled(bool eanbled);
    event WhaleProtectionEnabled(bool enabled);

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /**
     * @dev Throws if called by any account other than the janitor or the owner.
     */
    modifier onlyJanitorOrOwner() {
        require(janitor() == _msgSender() || owner() == _msgSender(), "Caller is not the janitor or the owner.");
        _;
    }

    constructor() {
        _rOwned[_msgSender()] = _rTotal;
        IUniswapV2Router02 _pancakeswapV2Router = IUniswapV2Router02(_routerAddress); // Initialize router
        pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
        _isExcludedFromFee[owner()] = true; // Owner doesn't pay fees (e.g. when adding liquidity)
        _isExcludedFromFee[address(this)] = true; // Contract address doesn't pay fees
        emit Transfer(address(0), _msgSender(), _tTotal);
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
    
    function boughtBy(address account) public view returns (uint256) {
        return _bought[account];
    }
    
    function boughtTotal() public view returns (uint256) {
        return _boughtTotal;
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
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }
    
    function isCleaned(address account) public view returns (bool) {
        return _isCleaned[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
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
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
    
    function clean(address account) public onlyOwner {
        _isCleaned[account] = true;
    }

    function unclean(address account) public onlyOwner {
        _isCleaned[account] = false;
    }

    function setTaxFeePromille(uint256 taxFee) external onlyOwner() {
        _taxFee = taxFee;
    }

    function setLiquidityFeePromille(uint256 liquidityFee) external onlyOwner() {
        _liquidityFee = liquidityFee;
    }

    function setMaxSellPercent(uint256 maxTxPercent) external onlyJanitorOrOwner() {
        _maxSellTransactionAmount = _tTotal.mul(maxTxPercent).div(10**2);
    }
    
    function setNumTokensSellToAddToLiquidity(uint256 numTokensSellToAddToLiquidity) external onlyJanitorOrOwner() {
        _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyJanitorOrOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    function setTransferClaimedEnabled(bool _enabled) public onlyJanitorOrOwner {
        _transferClaimedEnabled = _enabled;
    }
    
    function setProgressiveFeeEnabled(bool _enabled) public onlyJanitorOrOwner {
        progressiveFeeEnabled = _enabled;
        emit ProgressiveFeeEnabled(_enabled);
    }
    
    function setTradingEnabled(bool _enabled) public onlyOwner {
        tradingEnabled = _enabled;
        emit TradingEnabled(_enabled);
    }
    
    function setWhaleProtectionEnabled(bool _enabled) public onlyJanitorOrOwner {
        whaleProtectionEnabled = _enabled;
        emit WhaleProtectionEnabled(_enabled);
    }
    
    function enableTrading() public onlyJanitorOrOwner {
        tradingEnabled = true;
        emit TradingEnabled(true);
    }
    
    function setDoSwapForRouter(bool _enabled) public onlyJanitorOrOwner {
        doSwapForRouter = _enabled;
        emit DoSwapForRouterEnabled(_enabled);
    }

    function setRouterAddress(address routerAddress) public onlyJanitorOrOwner() {
        _routerAddress = routerAddress;
    }
    
    function setPairAddress(address pairAddress) public onlyJanitorOrOwner() {
        pancakeswapV2Pair = pairAddress;
    }
    
    function migrateRouter(address routerAddress) external onlyJanitorOrOwner() {
        setRouterAddress(routerAddress);
        IUniswapV2Router02 _pancakeswapV2Router = IUniswapV2Router02(_routerAddress); // Initialize router
        pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).getPair(address(this), _pancakeswapV2Router.WETH());
        if (pancakeswapV2Pair == address(0))
            pancakeswapV2Pair = IUniswapV2Factory(_pancakeswapV2Router.factory()).createPair(address(this), _pancakeswapV2Router.WETH());
        pancakeswapV2Router = _pancakeswapV2Router;
    }

    // To recieve BNB from pancakeswapV2Router when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidityAndRewards) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidityAndRewards, _getRate());
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidityAndRewards
        );
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256){
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidityAndRewards = calculateLiquidityAndRewardsFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidityAndRewards);
        return (tTransferAmount, tFee, tLiquidityAndRewards);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidityAndRewards, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidityAndRewards = tLiquidityAndRewards.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidityAndRewards);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidityAndRewards(uint256 tLiquidityAndRewards) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidityAndRewards = tLiquidityAndRewards.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidityAndRewards);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidityAndRewards);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**3);
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_liquidityFee).div(10**3);
    }

    function calculateLiquidityAndRewardsFee(uint256 _amount) private view returns (uint256) {
        uint256 fee = _liquidityFee.add(_rewardFee);
        return _amount.mul(fee).div(10**3);
    }

    function calculateProgressiveFee(uint256 amount) private view returns (uint256) { // Punish whales
        uint256 currentSupply = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 fee;
        uint256 txSize = amount.mul(10**1).div(currentSupply);
        if (txSize <= 10) {
            fee = 2;
        } else if (txSize <= 25) {
            fee = 4;
        } else if (txSize <= 50) {
            fee = 6;
        } else if (txSize <= 100) {
            fee = 8;
        } else if (txSize <= 250) {
            fee = 10;
        } else if (txSize <= 500) {
            fee = 12;
        } else if (txSize <= 1000) {
            fee = 16;
        } else {
            fee = 20;
        }
        return fee.div(2).mul(10);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _rewardFee == 0) 
            return;
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousRewardFee = _rewardFee;
        _taxFee = 0;
        _liquidityFee = 0;
        _rewardFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _rewardFee = _previousRewardFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function sweep(address payable recipient) public onlyJanitorOrOwner() {
        (bool success, ) = recipient.call{value:address(this).balance}("");
        require(success, "Clean failed.");
        _BNBRewards = 0;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isCleaned[from], "Jannniiieeeeeeeeeeeeeeeeeees!");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (from != owner() && to != owner() && from != janitor() && to != janitor()) {
            require(tradingEnabled, "Trading is not enabled");
            if (to != address(0) && to != address(0xdead) && from != address(this) && to != address(this)) {
                if (to != pancakeswapV2Pair)
                    require(balanceOf(to) + amount <= _maxWalletToken, "Exceeds maximum wallet token amount.");
                else
                    require(amount <= _maxSellTransactionAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }
        if (from == pancakeswapV2Pair) {
            _boughtTotal = _boughtTotal.add(amount);
            _bought[to] = _bought[to].add(amount);
        }
        else if (to == pancakeswapV2Pair) {
            _boughtTotal = _boughtTotal.sub(_bought[from]);
            _bought[from] = 0;
        }
        uint256 contractTokenBalance = balanceOf(address(this));
        if (contractTokenBalance >= _maxSellTransactionAmount)
            contractTokenBalance = _maxSellTransactionAmount;
        bool overMinTokenBalance = contractTokenBalance >= _numTokensSellToAddToLiquidity;
        if (overMinTokenBalance &&
            !inSwapAndLiquify &&
            from != pancakeswapV2Pair &&
            (doSwapForRouter || (from != _routerAddress && to != _routerAddress)) &&
            swapAndLiquifyEnabled) {
            swap(contractTokenBalance); // add liquidity
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
    }

    function swap(uint256 contractTokenBalance) private lockTheSwap {
        uint256 totalFee = _liquidityFee.add(_rewardFee);
        uint256 tokensForLiquidity = contractTokenBalance.mul(_liquidityFee).div(totalFee).div(2);
        if (tokensForLiquidity < contractTokenBalance) {
            // sell tokens
            uint256 tokensToSell = contractTokenBalance.sub(tokensForLiquidity);
            uint256 initialBalance = address(this).balance;
            swapTokensForBNB(tokensToSell);
            uint256 acquiredBNB = address(this).balance.sub(initialBalance);
            // calculate share for liquidity or rewards 
            uint256 bnbForLiquidity = acquiredBNB.mul(tokensForLiquidity).div(tokensToSell);
            uint256 bnbForRewards = acquiredBNB.sub(bnbForLiquidity);
            // update rewards
            _BNBRewards = _BNBRewards.add(bnbForRewards);
            // add liquidity
            addLiquidity(tokensForLiquidity, bnbForLiquidity);
            emit SwapAndLiquify(tokensForLiquidity, bnbForLiquidity);
        }
    }

    function swapTokensForBNB(uint256 tokenAmount) private { // Generate the pancakeswap pair path of token -> BNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeswapV2Router.WETH();
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens( // Make the swap
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private { // Approve token transfer to cover all possible scenarios
        _approve(address(this), address(pancakeswapV2Router), tokenAmount);
        pancakeswapV2Router.addLiquidityETH{value: bnbAmount} ( // Add liqudity
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            janitor(),
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee ) private {
        uint256 oldTaxFee = _taxFee;
        uint256 oldLiquidityFee = _liquidityFee;
        if (!takeFee) {
            removeAllFee();
        } else {
            if (progressiveFeeEnabled) {
                _taxFee = calculateProgressiveFee(amount);
                _liquidityFee = _taxFee;
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
        if (!takeFee) 
            restoreAllFee();
        _taxFee = oldTaxFee;
        _liquidityFee = oldLiquidityFee;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidityAndRewards
        ) = _getValues(tAmount);
        _transferClaimed(sender, recipient, tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidityAndRewards(tLiquidityAndRewards);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function totalRewards() public view returns (uint256) {
        return _BNBRewards;
    }
    
    function rewards(address recipient) public view returns (uint256) {
        uint256 total = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
        uint256 brut = _BNBRewards.mul(balanceOf(recipient)).div(total);
        if (brut > _claimed[recipient])
            return brut.sub(_claimed[recipient]);
        return 0;
    }
    
    function claimed(address recipient) public view returns (uint256) {
        return _claimed[recipient];
    }
    
    function _transferClaimed(address sender, address recipient, uint256 tAmount) private {
        if (_transferClaimedEnabled) {
            require(balanceOf(sender) > 0, "Just making sure ...");
            uint256 proportionClaimed = _claimed[sender].mul(tAmount).div(balanceOf(sender));
            if (_claimed[sender] > proportionClaimed)
                _claimed[sender] = _claimed[sender].sub(proportionClaimed);
            else
                _claimed[sender] = 0;
            _claimed[recipient] = _claimed[recipient].add(proportionClaimed);
        }
    }
    
    function claim(address payable recipient) public {
        if (_boughtTotal > 0) {
            uint256 total = _tTotal.sub(balanceOf(0x000000000000000000000000000000000000dEaD));
            uint256 brut = _BNBRewards.mul(balanceOf(recipient)).div(total);
            require(brut > _claimed[recipient], "Not enough to claim.");
            uint256 toclaim = brut.sub(_claimed[recipient]);
            _claimed[recipient] = _claimed[recipient].add(toclaim);
            (bool success, ) = recipient.call{value:toclaim}("");
            require(success, "Claim failed.");
            _totalClaimed = _totalClaimed.add(toclaim);
        }
    }
    
    function totalClaimed() public view returns (uint256) {
        return _totalClaimed;
    }

}