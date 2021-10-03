/**
 *Submitted for verification at BscScan.com on 2021-10-03
*/

//                        ,
//                        *%#%.
//                        %%(#%%
//                       (%((((%%     ..*****..
//                       %%((((((%%********************.
//                       %%((((((((%%%**********************,
//                   ,***%%(((((((((((#%%%#**********************
//                .******%%((((((((((((((((#%%%*********************
//              **********(%%((((((((((((((((((#%%*********************
//            ***************%%(((((((((((((((((((%%**********************
//          ******************#%((((((((((((((((((((%%**********************
//        .********************%%((((((((((((((((((((#%#*********************,
//       **********************/%#(((((((((((((((((((((%%**********************
//      ***********************(%#((((((((((((((((((((((%%**********************.
//     ************************%%((((((((((((((((((((((((#%**********************
//    ************************/%#(((((((((((((((((((((((((%%**********************
//   *************************%%(((((((((((((((((((((((((((%#**********************
//  *************************%%((((((((((((((((((((((((((((#%%*********************
//  ************************%%((((((((((((((((((((((((((((((((%#*******************
// ************************%%(((((((((((((((((((((((((((((((((%%*******************
// ***********************%%(((((((((((#%%%%%%%%%%((((((((((((%%*******************
// **********************#%(((((((((%%#*,,,,,,,,,,#%#(((((((((%%*******************
// **********************#%%(((((##%%**,,,,,,,,,,,,,%%(((((((((%%******************
//  *******************(%#(#%%%/,,,,%(*,,,,,,,,,,,,,%(/###(*,,*#%%/***************
//  ******************(%#%%/,,,,,,,,*%%***,,,,,,,/%%/,,,,,,,,,,*%****************,
//   ******************(/(,,,,,,,,,,,,,/%%%%%%%%(,,,,,,,,,,,,,,*%/***************
//    *******************#%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,/%/**************
//     *******************%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%%*************.
//      ******************/%/,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%#************
//        *****************%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,%%************
//         *****************%%,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,(%***********
//            **************/%**%%,,,,,,,,,,,,,,,,,,,,,,*%%%%%/********
//              ,************%%%#%%,,,,,,,,,,,,,,,,,,,,%%***%********
//                  **********#/**%%,,,,,,,,,,,,,,,,,/%#*********
//                       **********%%*%%,,,,,,,(#,,,%%******,
//                               .**%%%(%*,,,#%/(%#%%.
//                                      %%/,(%    %,
//                                       (%#%(
// TG: https://t.me/GnomeArmy
// WWW: https://gnome.army
// @
// A hyper-deflationary BEP20 staking rewards contract
// Stake GNOME to earn BNB
//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.12;

interface Token {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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
    constructor() internal {
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

    //Locks the contract for owner for the amount of time provided
    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = now + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    //Unlocks the contract for owner when _lockTime is exceeds
    function unlock() public virtual {
        require(
            _previousOwner == msg.sender,
            "GnomeToken: You don't have permission to unlock"
        );
        require(now > _lockTime, "GnomeToken: Contract is locked for 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}

interface IPancakeFactory {
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

interface IPancakePair {
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

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
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
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

interface IPancakeRouter02 is IPancakeRouter01 {
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

// File: contracts/protocols/bep/Utils.sol

pragma solidity >=0.6.12;

library Utils {
    using SafeMath for uint256;

    function swapTokensForEth(address routerAddress, uint256 tokenAmount)
        public
    {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
}

// File: contracts/protocols/bep/ReentrancyGuard.sol

pragma solidity >=0.6.12;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() public {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    modifier isHuman() {
        require(tx.origin == msg.sender, "GnomeToken: tx.origin error");
        _;
    }
}

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

contract GNOMETOKEN is Context, IBEP20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    address public constant BURN_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public STAKING_POOL = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee; //excluded from fees
    mapping(address => bool) private _isExcluded; //excluded from reflections (we have none)
    mapping(address => bool) private _isExcludedFromMaxTx; //excluded from maxtx limit, only after it is enforced
    mapping(address => bool) public bannedUsers; //bots manually added
    mapping(address => bool) private authorised; //used for timelock delegators eventually

    address[] private _excluded; //excluded from reward - not used

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10**9; //supply 1 billion GNOME
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;
    uint256 public _maxTxAmount = _tTotal;

    bool public swapAndLiquifyEnabled = false; // set to true upon launch

    uint256 public disruptiveTransferEnabledFrom = 0; // when to start encforcing max tx amount, from launch
    uint256 public TradingEnabledFromTimestamp = 0;

    bool public TradingEnabled = false; // set to true upon launch and can never be disabled

    uint256 public _taxFee = 0; // no reflections
    uint256 private _previousTaxFee = _taxFee;
    uint256 public _liquidityFee = 73; // 7.3%
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public _burningFee = 2; //0.2%
    uint256 private _previousburningFee = _burningFee;

    uint256 public minTokenNumberToSell = _tTotal.mul(1).div(10000000); // 0.00001% will trigger swap and liquify - 100 GNOME
    uint256 public lastBNBSentToStakingPoolInterval = 3600; //send BNB only every 60 mins to reduce gas fees and save that sweet, sweet BNB for gnomes.
    uint256 public lastBNBSentToStakingPoolTimestamp = 0; //initalised when BNB sent for the 1st time after _transfer

    string private _name = "GnomeToken";
    string private _symbol = "GNOME";
    uint8 private _decimals = 9;

    IPancakeRouter02 public pancakeRouter;
    address public pancakePair;

    bool inSwapAndLiquify = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapAndLiquifyExtInfo(
        uint256 contractTokenBalance,
        uint256 halfTokenBalance,
        uint256 piece,
        uint256 otherPiece,
        uint256 tokenAmountToBeSwapped,
        uint256 bnbToBeAddedToLiquidity
    );

    event ManualBNBBuy(uint256 amount);

    event BoughtBackTokens(uint256 bnb);

    event RouterUpdated(address newRouter);

    event SentBNBToStakingPool(uint256 currBNB);

    event UpdateMinTokenNumberToSell(uint256 minTokenNumberToSell);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    event WalletBanStatusUpdated(address user, bool banned);
    event StakingPoolUpdated(address StakingPool);
    event UpdateMaxTxPercent(uint256 MaxTxPercent);
    event UpdateExcludedFromMaxTx(address _address, bool excluded);
    event UpdateExcludeFromFee(address _address, bool excluded);
    event UpdateTaxFee(uint256 taxFee);
    event UpdateLiquidityFee(uint256 liquidityFee);
    event UpdateBurningFee(uint256 burningFee);
    event UpdateRewardInclusion(address account, bool IsExcluded);

    constructor(address payable routerAddress) public {
        _rOwned[_msgSender()] = _rTotal;

        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(routerAddress);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[BURN_ADDRESS] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[BURN_ADDRESS] = true;
        _isExcludedFromMaxTx[address(0)] = true;

        authorised[address(0)] = true;
        authorised[address(this)] = true;
        authorised[owner()] = true;

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

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount, 0);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount, 0);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function setAuthorised(address[] calldata _addresses) external onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            authorised[_addresses[i]] = true;
        }
    }

     function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurnt() public view returns (uint256) {
        return balanceOf(BURN_ADDRESS);
    }

    // function deliver(uint256 tAmount) public {
    //     address sender = _msgSender();
    //     require(
    //         !_isExcluded[sender],
    //         "GnomeToken: Excluded addresses cannot call this function"
    //     );
    //     (uint256 rAmount, , , , , , ) = _getValues(tAmount);
    //     _rOwned[sender] = _rOwned[sender].sub(rAmount);
    //     _rTotal = _rTotal.sub(rAmount);
    //     _tFeeTotal = _tFeeTotal.add(tAmount);
    // }

    function updateRouter(address newRouter) external onlyOwner {
        IPancakeRouter02 _pancakeRouter = IPancakeRouter02(newRouter);
        // Create a pancake pair for this new token
        pancakePair = IPancakeFactory(_pancakeRouter.factory()).createPair(
            address(this),
            _pancakeRouter.WETH()
        );

        // set the rest of the contract variables
        pancakeRouter = _pancakeRouter;
        _approve(address(this), address(pancakeRouter), 2**256 - 1);
        emit RouterUpdated(newRouter);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        public
        view
        returns (uint256)
    {
        require(
            tAmount <= _tTotal,
            "GnomeToken: Amount must be less than supply"
        );
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "GnomeToken: Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeFromReward(address account) public onlyOwner {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Pancake router.');
        require(
            !_isExcluded[account],
            "GnomeToken: Account is already excluded"
        );
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit UpdateRewardInclusion(account, true);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "GnomeToken: Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                emit UpdateRewardInclusion(account, false);
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        _burnFee(sender, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
        emit UpdateExcludeFromFee(account, true);
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
        emit UpdateExcludeFromFee(account, false);
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        require(taxFee <= 10, "GnomeToken: Tax fee cannot be greater than 10%");
        _taxFee = taxFee;
        emit UpdateTaxFee(taxFee);
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        require(
            liquidityFee <= 200,
            "GnomeToken: LP fee cannot be greater than 20%"
        );
        _liquidityFee = liquidityFee;
        emit UpdateLiquidityFee(liquidityFee);
    }

    function setBurningFeePercent(uint256 burningFee) external onlyOwner {
        //1=0.1%, 100=10%
        require(
            burningFee <= 100,
            "GnomeToken: Burn percent cannot be greater than 10%"
        );
        _burningFee = burningFee;
        emit UpdateBurningFee(burningFee);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to receive BNB from pancakeRouter when swapping
    receive() external payable {}

    // Function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out GNOME
    function transferAnyBEP20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        require(
            _tokenAddr != address(this),
            "GnomeToken: Cannot transfer out GnomeToken!"
        ); //cant send GNOME
        Token(_tokenAddr).transfer(_to, _amount);
    }

    function setWalletBanStatus(address user, bool banned) external onlyOwner {
        if (banned) {
            require(
                TradingEnabledFromTimestamp + 14 days >= block.timestamp,
                "GnomeToken: Owner cannot longer ban wallets"
            );
            require(
                user != pancakePair,
                "GnomeToken: Cannot ban the PancakePair!"
            );
            bannedUsers[user] = true;
        } else {
            delete bannedUsers[user];
        }
        emit WalletBanStatusUpdated(user, banned);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _burnFee(address sender, uint256 tBurn) private {
        if (tBurn == 0) return;
        _tBurnTotal = _tBurnTotal.add(tBurn);

        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[BURN_ADDRESS] = _rOwned[BURN_ADDRESS].add(rBurn);
        if (_isExcluded[BURN_ADDRESS]) {
            _tOwned[BURN_ADDRESS] = _tOwned[BURN_ADDRESS].add(tBurn);
        }
        emit Transfer(sender, BURN_ADDRESS, tBurn);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tBurn,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity,
            tBurn
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tBurn = calculateBurningFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity).sub(tBurn);
        return (tTransferAmount, tFee, tLiquidity, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tBurn,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity).sub(rBurn);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() public view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() public view returns (uint256, uint256) {
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

    function _getCirculatingSupply() external view returns (uint256) {
        uint256 cSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            cSupply = cSupply.sub(_tOwned[_excluded[i]]);
        }
        cSupply = cSupply.sub(balanceOf(BURN_ADDRESS));
        return (cSupply);
    }

    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        if (tLiquidity == 0) return;
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)]) {
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
        }
        _tFeeTotal = _tFeeTotal.add(tLiquidity);
        emit Transfer(sender, address(this), tLiquidity);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return
            _amount.mul(_liquidityFee).div(
                //10 ** 3 so LP fee is 0.X%
                10**3
            );
    }

    function calculateBurningFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        //10 ** 3 so burning fee is 0.X%
        return _amount.mul(_burningFee).div(10**3);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0 && _burningFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousburningFee = _burningFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _burningFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _burningFee = _previousburningFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(
            amount > 0,
            "GnomeToken: Transfer amount must be greater than zero"
        );
        require(bannedUsers[from] == false, "GnomeToken: Sender is banned");
        require(bannedUsers[to] == false, "GnomeToken: Recipient is banned");

        ensureMaxTxAmount(from, to, amount, value);
        uint256 contractTokenBalance = balanceOf(address(this));
        // swap and liquify - redesigned!

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is pancake pair.
        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != pancakePair &&
            swapAndLiquifyEnabled // swap 1 time
        ) {
            contractTokenBalance = minTokenNumberToSell;
            //add liquidity
            swapAndLiquify(contractTokenBalance);
        }

        //swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
        //Send BNB in the contract to the staking pool every 30 mins
        uint256 remBNB = address(this).balance;
        TopUpStakingPool(remBNB);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!authorised[sender] && !authorised[recipient]) {
            require(TradingEnabled, "GnomeToken: Trading not open yet!");
        }
        
        if (!takeFee) removeAllFee();

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

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        _burnFee(sender, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        _burnFee(sender, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tBurn
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeLiquidity(sender, tLiquidity);
        _reflectFee(rFee, tFee);
        _burnFee(sender, tBurn);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        //div 100 so maxTx (100) = 100%
        require(
            TradingEnabledFromTimestamp + 120 days >= block.timestamp,
            "GnomeToken: Cannot adjust max TX after 120 days"
        );
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(100);
        emit UpdateMaxTxPercent(_maxTxAmount);
    }

    function setMinTokenNumberToSell(uint256 min) external onlyOwner {
        require(min <= 15000000, "GnomeToken: Cannot exceed 1.5% of supply!");
        minTokenNumberToSell = min.mul(10**9);
        emit UpdateMinTokenNumberToSell(minTokenNumberToSell);
    }

    function setStakingPool(address StakingPool) external onlyOwner {
        require(
            Address.isContract(StakingPool) == true,
            "GnomeToken: Staking Pool must be a contract address"
        );
        STAKING_POOL = address(StakingPool);
        setExcludeFromMaxTx(StakingPool, true);
        excludeFromFee(StakingPool);
        excludeFromReward(StakingPool);
        emit StakingPoolUpdated(StakingPool);
    }

    function setExcludeFromMaxTx(address _address, bool value)
        public
        onlyOwner
    {
        _isExcludedFromMaxTx[_address] = value;
        emit UpdateExcludedFromMaxTx(_address, value);
    }

    function ensureMaxTxAmount(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private view {
        if (
            _isExcludedFromMaxTx[from] == false && // default will be false
            _isExcludedFromMaxTx[to] == false // default will be false
        ) {
            if (block.timestamp >= disruptiveTransferEnabledFrom) {
                require(
                    amount <= _maxTxAmount,
                    "GnomeToken: Transfer amount exceeds the maxTxAmount."
                );
            }
        }
    }

    function aquireBNB(uint256 tokens) external onlyOwner {
        //Use available tokens from the contract token balance (from fees, or sent from the staking pool)
        //To buy BNB
        require(tokens > 0, "GnomeToken: Must be greater than 0");
        require(
            tokens < 100000000,
            "GnomeToken: Cannot swap more than 1% of supply"
        );
        uint256 amount = tokens.mul(10**9);
        Utils.swapTokensForEth(address(pancakeRouter), amount);
        emit ManualBNBBuy(amount);
    }

    function BuyBack(uint256 bnbAmount) external onlyOwner {
        //Buy tokens using BNB contract balance
        require(
            bnbAmount > 0,
            "GnomeToken: Cannot buy back tokens using nothing?"
        );
        require(
            bnbAmount < address(this).balance,
            "GnomeToken: Not enough BNB available for buy back."
        );
        Utils.swapETHForTokens(
            address(pancakeRouter),
            address(BURN_ADDRESS),
            bnbAmount
        );
        emit BoughtBackTokens(bnbAmount);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into 3 pieces
        //example 100 tokens minimum add
        //50 tokens
        uint256 halfTokenBalance = contractTokenBalance.div(2);
        //quarter of the token balance
        //25 tokens
        uint256 piece = contractTokenBalance.sub(halfTokenBalance).div(2);
        //To keep the ratio of GNOME/BNB in the pool more consistent we also supply less tokens to the pool
        //since we are supplying less BNB!
        //25 tokens
        uint256 otherPiece = halfTokenBalance.sub(piece);
        //75 tokens
        uint256 tokenAmountToBeSwapped = halfTokenBalance.add(piece);
        //get BNB balance before swap to capture amount we recieve from swapping
        uint256 initialBalance = address(this).balance;
        //75 tokens -> BNB
        Utils.swapTokensForEth(address(pancakeRouter), tokenAmountToBeSwapped);
        // how much BNB did we just recieve from swapping
        uint256 deltaBalance = address(this).balance.sub(initialBalance);
        //send 1/3rd to the LP pool, the remaining is for staking rewards
        uint256 bnbToBeAddedToLiquidity = deltaBalance.div(3);
        // add liquidity to pancake, send tokens to this contract - NOT the deployer!!
        //25 tokens -> LP pool & BNB/3
        Utils.addLiquidity(
            address(pancakeRouter),
            address(this),
            otherPiece,
            bnbToBeAddedToLiquidity
        );

        emit SwapAndLiquify(piece, bnbToBeAddedToLiquidity, otherPiece);
        emit SwapAndLiquifyExtInfo(
            contractTokenBalance,
            halfTokenBalance,
            piece,
            otherPiece,
            tokenAmountToBeSwapped,
            bnbToBeAddedToLiquidity
        );
        //send contract BNB balance to the staking pool
    }

    function TopUpStakingPool(uint256 currbnb) private {
        //Check that the 60 mins have passed since we last sent BNB
        if (
            block.timestamp >
            lastBNBSentToStakingPoolTimestamp.add(
                lastBNBSentToStakingPoolInterval
            ) &&
            currbnb > 0
        ) {
            lastBNBSentToStakingPoolTimestamp = block.timestamp;
            address payable receiver = payable(STAKING_POOL);

            (bool success, ) = receiver.call{value: currbnb}("");

            if (success) {
                emit SentBNBToStakingPool(currbnb);
            }
        }
    }

    function ManualStakingPoolTopUp() external onlyOwner {
        //Manually send the contract BNB balance to the staking pool
        uint256 currbnb = address(this).balance;
        lastBNBSentToStakingPoolTimestamp = block.timestamp;
        address payable receiver = payable(STAKING_POOL);

        (bool success, ) = receiver.call{value: currbnb}("");

        if (success) {
            emit SentBNBToStakingPool(currbnb);
        }
    }

    function activateContract() external onlyOwner {
        disruptiveTransferEnabledFrom = block.timestamp;
        TradingEnabledFromTimestamp = block.timestamp;
        TradingEnabled = true;
        setMaxTxPercent(20); //25%
        setSwapAndLiquifyEnabled(true);
        // approve contract
        _approve(address(this), address(pancakeRouter), 2**256 - 1);
    }
}