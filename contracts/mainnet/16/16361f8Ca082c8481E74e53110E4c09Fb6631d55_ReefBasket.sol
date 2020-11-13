// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol


pragma solidity ^0.6.0;

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
contract ReentrancyGuard {
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

    constructor () internal {
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
}

// File: @openzeppelin/contracts/GSN/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/utils/Babylonian.sol

// import "@uniswap/lib/contracts/libraries/Babylonian.sol";

pragma solidity ^0.6.12;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// File: interfaces/IUniswapV2Router.sol


pragma solidity ^0.6.12;

interface IUniswapV2Router {
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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
    function approve(address guy, uint wad) external returns (bool);
}

// File: interfaces/IUniswapV2Factory.sol

pragma solidity ^0.6.12;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address);
}

// File: interfaces/IUniswapV2Pair.sol

pragma solidity ^0.6.12;

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address owner) external view returns (uint);

    function totalSupply() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 _reserve0,
            uint112 _reserve1,
            uint32 _blockTimestampLast
        );
}

// File: interfaces/TransferHelper.sol

pragma solidity ^0.6.12;

library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }
}

// File: contracts/ReefUniswap.sol

pragma solidity ^0.6.12;

library ReefUniswap {
    using SafeMath for uint256;
    using Address for address;

    address public constant uniswapV2RouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IUniswapV2Router private constant uniswapV2Router = IUniswapV2Router(
        uniswapV2RouterAddress
    );

    IUniswapV2Factory private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );


    function _investIntoUniswapPool(
        address _FromTokenContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        address _toAccount,
        uint256 _amount
    ) internal returns (uint256) {
        uint256 token0Bought;
        uint256 token1Bought;

        if (canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)) {
            (token0Bought, token1Bought) = exchangeTokensV2(
                _FromTokenContractAddress,
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                _amount
            );
        }

        require(token0Bought > 0 && token1Bought > 0, "Could not exchange");

        TransferHelper.safeApprove(
            _ToUnipoolToken0,
            address(uniswapV2Router),
            token0Bought
        );

        TransferHelper.safeApprove(
            _ToUnipoolToken1,
            address(uniswapV2Router),
            token1Bought
        );

        (uint256 amountA, uint256 amountB, uint256 LP) = uniswapV2Router
            .addLiquidity(
            _ToUnipoolToken0,
            _ToUnipoolToken1,
            token0Bought,
            token1Bought,
            1,
            1,
            _toAccount,
            now + 60
        );

        uint256 residue;
        if (SafeMath.sub(token0Bought, amountA) > 0) {
            if (canSwapFromV2(_ToUnipoolToken0, _FromTokenContractAddress)) {
                residue = swapFromV2(
                    _ToUnipoolToken0,
                    _FromTokenContractAddress,
                    SafeMath.sub(token0Bought, amountA)
                );
            } else {
                TransferHelper.safeTransfer(
                    _ToUnipoolToken0,
                    msg.sender,
                    SafeMath.sub(token0Bought, amountA)
                );
            }
        }

        if (SafeMath.sub(token1Bought, amountB) > 0) {
            if (canSwapFromV2(_ToUnipoolToken1, _FromTokenContractAddress)) {
                residue += swapFromV2(
                    _ToUnipoolToken1,
                    _FromTokenContractAddress,
                    SafeMath.sub(token1Bought, amountB)
                );
            } else {
                TransferHelper.safeTransfer(
                    _ToUnipoolToken1,
                    msg.sender,
                    SafeMath.sub(token1Bought, amountB)
                );
            }
        }

        if (residue > 0) {
            TransferHelper.safeTransfer(
                _FromTokenContractAddress,
                msg.sender,
                residue
            );
        }

        return LP;
    }

    /**
    @notice This function is used to zapout of given Uniswap pair in the bounded tokens
    @param _token0 Token 0 address
    @param _token1 Token 1 address
    @param _IncomingLP The amount of LP
    @return amountA the amount of first token received after zapout
    @return amountB the amount of second token received after zapout
     */
    function _disinvestFromUniswapPool(
        address _ToTokenContractAddress,
        address _token0,
        address _token1,
        uint256 _IncomingLP
    ) internal returns (uint256 amountA, uint256 amountB) {
        address _FromUniPoolAddress = UniSwapV2FactoryAddress.getPair(
            _token0,
            _token1
        );
        IUniswapV2Pair pair = IUniswapV2Pair(_FromUniPoolAddress);
        require(address(pair) != address(0), "Error: Invalid Unipool Address");

        TransferHelper.safeApprove(
            _FromUniPoolAddress,
            address(uniswapV2Router),
            _IncomingLP
        );

        if (_token0 == wethTokenAddress || _token1 == wethTokenAddress) {
            address _token = _token0 == wethTokenAddress ? _token1 : _token0;
            address _wethToken = _token0 != wethTokenAddress
                ? _token1
                : _token0;
            (amountA, amountB) = uniswapV2Router.removeLiquidityETH(
                _token,
                _IncomingLP,
                1,
                1,
                address(this),
                now + 60
            );

            if (canSwapFromV2(_token1, _ToTokenContractAddress)) {
                swapFromV2(_token, _ToTokenContractAddress, amountA);
            } else {
                TransferHelper.safeTransfer(_token, msg.sender, amountA);
            }
        } else {
            (amountA, amountB) = uniswapV2Router.removeLiquidity(
                _token0,
                _token1,
                _IncomingLP,
                1,
                1,
                address(this),
                now + 60
            );

            if (canSwapFromV2(_token0, _ToTokenContractAddress)) {
                swapFromV2(_token0, _ToTokenContractAddress, amountA);
            } else {
                TransferHelper.safeTransfer(_token0, msg.sender, amountA);
            }

            if (canSwapFromV2(_token1, _ToTokenContractAddress)) {
                swapFromV2(_token1, _ToTokenContractAddress, amountB);
            } else {
                TransferHelper.safeTransfer(_token1, msg.sender, amountB);
            }
        }
    }


    function exchangeTokensV2(
        address _FromTokenContractAddress,
        address _ToUnipoolToken0,
        address _ToUnipoolToken1,
        uint256 _amount
    ) internal returns (uint256 token0Bought, uint256 token1Bought) {
        IUniswapV2Pair pair = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_ToUnipoolToken0, _ToUnipoolToken1)
        );
        (uint256 res0, uint256 res1, ) = pair.getReserves();
        if (
            canSwapFromV2(_FromTokenContractAddress, _ToUnipoolToken0) &&
            canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)
        ) {
            token0Bought = swapFromV2(
                _FromTokenContractAddress,
                _ToUnipoolToken0,
                _amount
            );
            uint256 amountToSwap = calculateSwapInAmount(res0, token0Bought);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token0Bought, 2);
            token1Bought = swapFromV2(
                _ToUnipoolToken0,
                _ToUnipoolToken1,
                amountToSwap
            );
            token0Bought = SafeMath.sub(token0Bought, amountToSwap);
        } else if (
            canSwapFromV2(_FromTokenContractAddress, _ToUnipoolToken1) &&
            canSwapFromV2(_ToUnipoolToken0, _ToUnipoolToken1)
        ) {
            token1Bought = swapFromV2(
                _FromTokenContractAddress,
                _ToUnipoolToken1,
                _amount
            );
            uint256 amountToSwap = calculateSwapInAmount(res1, token1Bought);
            //if no reserve or a new pair is created
            if (amountToSwap <= 0) amountToSwap = SafeMath.div(token1Bought, 2);
            token0Bought = swapFromV2(
                _ToUnipoolToken1,
                _ToUnipoolToken0,
                amountToSwap
            );
            token1Bought = SafeMath.sub(token1Bought, amountToSwap);
        }
    }

    function canSwapFromV2(address _fromToken, address _toToken)
        public
        view
        returns (bool)
    {
        require(
            _fromToken != address(0) || _toToken != address(0),
            "Invalid Exchange values"
        );

        if (_fromToken == _toToken) return true;

        if (_fromToken == address(0) || _fromToken == wethTokenAddress) {
            if (_toToken == wethTokenAddress || _toToken == address(0))
                return true;
            IUniswapV2Pair pair = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)
            );
            if (_haveReserve(pair)) return true;
        } else if (_toToken == address(0) || _toToken == wethTokenAddress) {
            if (_fromToken == wethTokenAddress || _fromToken == address(0))
                return true;
            IUniswapV2Pair pair = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)
            );
            if (_haveReserve(pair)) return true;
        } else {
            IUniswapV2Pair pair1 = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)
            );
            IUniswapV2Pair pair2 = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)
            );
            IUniswapV2Pair pair3 = IUniswapV2Pair(
                UniSwapV2FactoryAddress.getPair(_fromToken, _toToken)
            );
            if (_haveReserve(pair1) && _haveReserve(pair2)) return true;
            if (_haveReserve(pair3)) return true;
        }
        return false;
    }

    //checks if the UNI v2 contract have reserves to swap tokens
    function _haveReserve(IUniswapV2Pair pair) internal view returns (bool) {
        if (address(pair) != address(0)) {
            (uint256 res0, uint256 res1, ) = pair.getReserves();
            if (res0 > 0 && res1 > 0) {
                return true;
            }
        }
    }

    function calculateSwapInAmount(uint256 reserveIn, uint256 userIn)
        public
        pure
        returns (uint256)
    {
        return
            Babylonian
                .sqrt(
                reserveIn.mul(userIn.mul(3988000) + reserveIn.mul(3988009))
            )
                .sub(reserveIn.mul(1997)) / 1994;
    }

    //swaps _fromToken for _toToken
    //for eth, address(0) otherwise ERC token address
    function swapFromV2(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) internal returns (uint256) {
        require(
            _fromToken != address(0) || _toToken != address(0),
            "Invalid Exchange values"
        );
        if (_fromToken == _toToken) return amount;

        require(canSwapFromV2(_fromToken, _toToken), "Cannot be exchanged");
        require(amount > 0, "Invalid amount");

        if (_fromToken == address(0)) {
            if (_toToken == wethTokenAddress) {
                IWETH(wethTokenAddress).deposit{value: amount}();
                return amount;
            }
            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _toToken;

            uint256[] memory amounts = uniswapV2Router.swapExactETHForTokens{
                value: amount
            }(0, path, address(this), now + 180);
            return amounts[1];
        } else if (_toToken == address(0)) {
            if (_fromToken == wethTokenAddress) {
                IWETH(wethTokenAddress).withdraw(amount);
                return amount;
            }
            address[] memory path = new address[](2);
            TransferHelper.safeApprove(
                _fromToken,
                address(uniswapV2Router),
                amount
            );
            path[0] = _fromToken;
            path[1] = wethTokenAddress;

            uint256[] memory amounts = uniswapV2Router.swapExactTokensForETH(
                amount,
                0,
                path,
                address(this),
                now + 180
            );
            return amounts[1];
        } else {
            TransferHelper.safeApprove(
                _fromToken,
                address(uniswapV2Router),
                amount
            );
            uint256 returnedAmount = _swapTokenToTokenV2(
                _fromToken,
                _toToken,
                amount
            );
            require(returnedAmount > 0, "Error in swap");
            return returnedAmount;
        }
    }

    //swaps 2 ERC tokens (UniV2)
    function _swapTokenToTokenV2(
        address _fromToken,
        address _toToken,
        uint256 amount
    ) internal returns (uint256) {
        IUniswapV2Pair pair1 = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_fromToken, wethTokenAddress)
        );
        IUniswapV2Pair pair2 = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_toToken, wethTokenAddress)
        );
        IUniswapV2Pair pair3 = IUniswapV2Pair(
            UniSwapV2FactoryAddress.getPair(_fromToken, _toToken)
        );

        uint256[] memory amounts;

        if (_haveReserve(pair3)) {
            address[] memory path = new address[](2);
            path[0] = _fromToken;
            path[1] = _toToken;

            amounts = uniswapV2Router.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                now + 180
            );
            return amounts[1];
        } else if (_haveReserve(pair1) && _haveReserve(pair2)) {
            address[] memory path = new address[](3);
            path[0] = _fromToken;
            path[1] = wethTokenAddress;
            path[2] = _toToken;

            amounts = uniswapV2Router.swapExactTokensForTokens(
                amount,
                0,
                path,
                address(this),
                now + 180
            );
            return amounts[2];
        }
        return 0;
    }
}

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity ^0.6.0;




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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: interfaces/IBPool.sol

pragma solidity ^0.6.12;

interface IBPool {

    function exitswapPoolAmountIn(
        address tokenOut,
        uint256 poolAmountIn,
        uint256 minAmountOut
    ) external payable returns (uint256 tokenAmountOut);

    function joinswapExternAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        uint256 minPoolAmountOut
    ) external payable returns (uint256 poolAmountOut);

    function totalSupply() external view returns (uint256);

    function getFinalTokens() external view returns (address[] memory tokens);

    function getDenormalizedWeight(address token)
        external
        view
        returns (uint256);

    function getTotalDenormalizedWeight() external view returns (uint256);

    function getSwapFee() external view returns (uint256);

    function isBound(address t) external view returns (bool);

    function calcPoolOutGivenSingleIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 poolAmountOut);

    function calcSingleOutGivenPoolIn(
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 poolSupply,
        uint256 totalWeight,
        uint256 poolAmountIn,
        uint256 swapFee
    ) external pure returns (uint256 tokenAmountOut);

    function getBalance(address token) external view returns (uint256);
    function balanceOf(address whom) external view returns (uint);
    function approve(address dst, uint amt) external returns (bool);

}

// File: interfaces/IBFactory.sol

pragma solidity ^0.6.12;

interface IBFactory {

    function isBPool(address b) external view returns (bool);
    function newBPool() external returns (IBPool);
}

// File: contracts/ReefBalancer.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//

///@author Reef
///@notice This contract adds and removes liquidity from Balancer Pools into
//ETH/ERC/Underlying Tokens. Based on Zaper implementation.










pragma solidity ^0.6.12;

library ReefBalancer {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    IUniswapV2Factory
        private constant UniSwapV2FactoryAddress = IUniswapV2Factory(
        0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f
    );
    IUniswapV2Router private constant uniswapRouter = IUniswapV2Router(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    IBFactory private constant BalancerFactory = IBFactory(
        0x9424B1412450D0f8Fc2255FAf6046b98213B76Bd
    );

    address
        private constant wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256
        private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

    /**
    @notice This function for investing into BalancerPool
    @param _toWhomToIssue The user address who want to invest
    @param _FromTokenContractAddress The token used for investment (address(0x00) if ether)
    @param _ToBalancerPoolAddress The address of balancer pool to zapin
    @param _amount The amount of ETH/ERC to invest
    @param _minPoolTokens for slippage
    @return tokensBought The quantity of Balancer Pool tokens returned
    */
    function investIntoBalancerPool(
        address _toWhomToIssue,
        address _FromTokenContractAddress,
        address _ToBalancerPoolAddress,
        uint256 _amount,
        uint256 _minPoolTokens
    ) public returns (uint256 tokensBought) {

        address _IntermediateToken = _getBestDeal(
            _ToBalancerPoolAddress,
            _amount,
            _FromTokenContractAddress
        );

        // check if isBound()
        bool isBound = IBPool(_ToBalancerPoolAddress).isBound(
            _FromTokenContractAddress
        );

        uint256 balancerTokens;

        if (isBound) {
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _FromTokenContractAddress,
                _amount,
                _minPoolTokens
            );
        } else {
            // swap tokens or eth
            uint256 tokenBought;
            if (_FromTokenContractAddress == address(0)) {
                tokenBought = ReefUniswap.swapFromV2(_FromTokenContractAddress,
                                                     _IntermediateToken, _amount);
            } else {
                tokenBought = _token2Token(
                    _FromTokenContractAddress,
                    address(this),
                    _IntermediateToken,
                    _amount
                );
            }

            //get BPT
            balancerTokens = _enter2Balancer(
                _ToBalancerPoolAddress,
                _IntermediateToken,
                tokenBought,
                _minPoolTokens
            );
        }

        //transfer tokens to user
        IERC20(_ToBalancerPoolAddress).safeTransfer(
            _toWhomToIssue,
            balancerTokens
        );

        return balancerTokens;
    }

    /**
    @notice This function is used for zapping out of balancer pools
    @param _ToTokenContractAddress The token in which we want zapout (for ethers, its zero address)
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _IncomingBPT The quantity of balancer pool tokens
    @param _minTokensRec slippage user wants
    @return success or failure
    */
    function disinvestFromBalancerPool(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress,
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        uint256 _minTokensRec
    ) public returns (uint256) {
        require(
            BalancerFactory.isBPool(_FromBalancerPoolAddress),
            "Invalid Balancer Pool"
        );

        address _FromTokenAddress;
        if (IBPool(_FromBalancerPoolAddress).isBound(_ToTokenContractAddress)) {
            _FromTokenAddress = _ToTokenContractAddress;
        } else if (
            _ToTokenContractAddress == address(0) &&
            IBPool(_FromBalancerPoolAddress).isBound(wethTokenAddress)
        ) {
            _FromTokenAddress = wethTokenAddress;
        } else {
            _FromTokenAddress = _getBestDeal(
                _FromBalancerPoolAddress,
                _IncomingBPT
            );
        }
        return (
            _performZapOut(
                _toWhomToIssue,
                _ToTokenContractAddress,
                _FromBalancerPoolAddress,
                _IncomingBPT,
                _FromTokenAddress,
                _minTokensRec
            )
        );
    }

    /**
    @notice This method is called by disinvestFromBalancerPool()
    @param _toWhomToIssue is the address of user
    @param _ToTokenContractAddress is the address of the token to which you want to convert to
    @param _FromBalancerPoolAddress the address of the Balancer Pool from which you want to ZapOut
    @param _IncomingBPT is the quantity of Balancer Pool tokens that the user wants to ZapOut
    @param _IntermediateToken is the token to which the Balancer Pool should be Zapped Out
    @notice this is only used if the outgoing token is not amongst the Balancer Pool tokens
    @return success or failure
    */
    function _performZapOut(
        address payable _toWhomToIssue,
        address _ToTokenContractAddress,
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        address _IntermediateToken,
        uint256 _minTokensRec
    ) internal returns (uint256) {
        if (IBPool(_FromBalancerPoolAddress).isBound(_ToTokenContractAddress)) {
            return (
                _directZapout(
                    _FromBalancerPoolAddress,
                    _ToTokenContractAddress,
                    _toWhomToIssue,
                    _IncomingBPT,
                    _minTokensRec
                )
            );
        }

        //exit balancer
        uint256 _returnedTokens = _exitBalancer(
            _FromBalancerPoolAddress,
            _IntermediateToken,
            _IncomingBPT
        );

        if (_ToTokenContractAddress == address(0)) {
            uint256 ethBought = ReefUniswap.swapFromV2(_IntermediateToken, address(0),
                                               _returnedTokens);

            require(ethBought >= _minTokensRec, "High slippage");

            _toWhomToIssue.transfer(ethBought);
            return ethBought;
        } else {
            uint256 tokenBought = _token2Token(
                _IntermediateToken,
                _toWhomToIssue,
                _ToTokenContractAddress,
                _returnedTokens
            );
            require(tokenBought >= _minTokensRec, "High slippage");
            return tokenBought;
        }
    }

    /**
    @notice This function is used for zapping out of balancer pool
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _ToTokenContractAddress The token in which we want to zapout (for ethers, its zero address)
    @param _toWhomToIssue The address of user
    @param tokens2Trade The quantity of balancer pool tokens
    @return returnedTokens success or failure
    */
    function _directZapout(
        address _FromBalancerPoolAddress,
        address _ToTokenContractAddress,
        address _toWhomToIssue,
        uint256 tokens2Trade,
        uint256 _minTokensRec
    ) internal returns (uint256 returnedTokens) {
        returnedTokens = _exitBalancer(
            _FromBalancerPoolAddress,
            _ToTokenContractAddress,
            tokens2Trade
        );

        require(returnedTokens >= _minTokensRec, "High slippage");

        IERC20(_ToTokenContractAddress).transfer(
            _toWhomToIssue,
            returnedTokens
        );
    }

    /**
    @notice This function gives the amount of tokens on zapping out from given
    IBPool
    @param _FromBalancerPoolAddress Address of balancer pool to zapout from
    @param _IncomingBPT The amount of BPT to zapout
    @param _toToken Address of token to zap out with
    @return tokensReturned Amount of ERC token
     */
    function _getBPT2Token(
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT,
        address _toToken
    ) internal view returns (uint256 tokensReturned) {
        uint256 totalSupply = IBPool(_FromBalancerPoolAddress).totalSupply();
        uint256 swapFee = IBPool(_FromBalancerPoolAddress).getSwapFee();
        uint256 totalWeight = IBPool(_FromBalancerPoolAddress)
            .getTotalDenormalizedWeight();
        uint256 balance = IBPool(_FromBalancerPoolAddress).getBalance(_toToken);
        uint256 denorm = IBPool(_FromBalancerPoolAddress).getDenormalizedWeight(
            _toToken
        );

        tokensReturned = IBPool(_FromBalancerPoolAddress)
            .calcSingleOutGivenPoolIn(
            balance,
            denorm,
            totalSupply,
            totalWeight,
            _IncomingBPT,
            swapFee
        );
    }

    /**
    @notice Function gives the expected amount of pool tokens on investing
    @param _ToBalancerPoolAddress Address of balancer pool to zapin
    @param _IncomingERC The amount of ERC to invest
    @param _FromToken Address of token to zap in with
    @return tokensReturned Amount of BPT token
    */
    function getToken2BPT(
        address _ToBalancerPoolAddress,
        uint256 _IncomingERC,
        address _FromToken
    ) internal view returns (uint256 tokensReturned) {
        uint256 totalSupply = IBPool(_ToBalancerPoolAddress).totalSupply();
        uint256 swapFee = IBPool(_ToBalancerPoolAddress).getSwapFee();
        uint256 totalWeight = IBPool(_ToBalancerPoolAddress)
            .getTotalDenormalizedWeight();
        uint256 balance = IBPool(_ToBalancerPoolAddress).getBalance(_FromToken);
        uint256 denorm = IBPool(_ToBalancerPoolAddress).getDenormalizedWeight(
            _FromToken
        );

        tokensReturned = IBPool(_ToBalancerPoolAddress)
            .calcPoolOutGivenSingleIn(
            balance,
            denorm,
            totalSupply,
            totalWeight,
            _IncomingERC,
            swapFee
        );
    }


    /**
    @notice This function is used to zapin to balancer pool
    @param _ToBalancerPoolAddress The address of balancer pool to zap in
    @param _FromTokenContractAddress The token used to zap in
    @param tokens2Trade The amount of tokens to invest
    @return poolTokensOut The quantity of Balancer Pool tokens returned
    */
    function _enter2Balancer(
        address _ToBalancerPoolAddress,
        address _FromTokenContractAddress,
        uint256 tokens2Trade,
        uint256 _minPoolTokens
    ) internal returns (uint256 poolTokensOut) {
        require(
            IBPool(_ToBalancerPoolAddress).isBound(_FromTokenContractAddress),
            "Token not bound"
        );

        uint256 allowance = IERC20(_FromTokenContractAddress).allowance(
            address(this),
            _ToBalancerPoolAddress
        );

        if (allowance < tokens2Trade) {
            IERC20(_FromTokenContractAddress).safeApprove(
                _ToBalancerPoolAddress,
                uint256(-1)
            );
        }

        poolTokensOut = IBPool(_ToBalancerPoolAddress).joinswapExternAmountIn(
            _FromTokenContractAddress,
            tokens2Trade,
            _minPoolTokens
        );

        require(poolTokensOut > 0, "Error in entering balancer pool");
    }

    /**
    @notice This function is used to zap out of the given balancer pool
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _ToTokenContractAddress The Token address which will be zapped out
    @param _amount The amount of token for zapout
    @return returnedTokens The amount of tokens received after zap out
     */
    function _exitBalancer(
        address _FromBalancerPoolAddress,
        address _ToTokenContractAddress,
        uint256 _amount
    ) internal returns (uint256 returnedTokens) {
        require(
            IBPool(_FromBalancerPoolAddress).isBound(_ToTokenContractAddress),
            "Token not bound"
        );

        uint256 minTokens = _getBPT2Token(
            _FromBalancerPoolAddress,
            _amount,
            _ToTokenContractAddress
        );
        minTokens = SafeMath.div(SafeMath.mul(minTokens, 98), 100);

        returnedTokens = IBPool(_FromBalancerPoolAddress).exitswapPoolAmountIn(
            _ToTokenContractAddress,
            _amount,
            minTokens
        );

        require(returnedTokens > 0, "Error in exiting balancer pool");
    }

    /**
    @notice This function is used to swap tokens
    @param _FromTokenContractAddress The token address to swap from
    @param _ToWhomToIssue The address to transfer after swap
    @param _ToTokenContractAddress The token address to swap to
    @param tokens2Trade The quantity of tokens to swap
    @return tokenBought The amount of tokens returned after swap
     */
    function _token2Token(
        address _FromTokenContractAddress,
        address _ToWhomToIssue,
        address _ToTokenContractAddress,
        uint256 tokens2Trade
    ) internal returns (uint256 tokenBought) {
        IERC20(_FromTokenContractAddress).approve(
            address(uniswapRouter),
            tokens2Trade
        );

        if (_FromTokenContractAddress != wethTokenAddress) {
            if (_ToTokenContractAddress != wethTokenAddress) {
                address[] memory path = new address[](3);
                path[0] = _FromTokenContractAddress;
                path[1] = wethTokenAddress;
                path[2] = _ToTokenContractAddress;
                tokenBought = uniswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    _ToWhomToIssue,
                    deadline
                )[path.length - 1];
            } else {
                address[] memory path = new address[](2);
                path[0] = _FromTokenContractAddress;
                path[1] = wethTokenAddress;

                tokenBought = uniswapRouter.swapExactTokensForTokens(
                    tokens2Trade,
                    1,
                    path,
                    _ToWhomToIssue,
                    deadline
                )[path.length - 1];
            }
        } else {
            address[] memory path = new address[](2);
            path[0] = wethTokenAddress;
            path[1] = _ToTokenContractAddress;
            tokenBought = uniswapRouter.swapExactTokensForTokens(
                tokens2Trade,
                1,
                path,
                _ToWhomToIssue,
                deadline
            )[path.length - 1];
        }

        require(tokenBought > 0, "Error in swapping ERC: 1");
    }

    /**
    @notice This function finds best token from the final tokens of balancer pool
    @param _ToBalancerPoolAddress The address of balancer pool to zap in
    @param _amount amount of eth/erc to invest
    @param _FromTokenContractAddress the token address which is used to invest
    @return _token The token address having max liquidity
    */
    function _getBestDeal(
        address _ToBalancerPoolAddress,
        uint256 _amount,
        address _FromTokenContractAddress
    ) internal view returns (address _token) {
        // If input is not eth or weth
        if (
            _FromTokenContractAddress != address(0) &&
            _FromTokenContractAddress != wethTokenAddress
        ) {
            // check if input token or weth is bound and if so return it as intermediate
            bool isBound = IBPool(_ToBalancerPoolAddress).isBound(
                _FromTokenContractAddress
            );
            if (isBound) return _FromTokenContractAddress;
        }

        bool wethIsBound = IBPool(_ToBalancerPoolAddress).isBound(
            wethTokenAddress
        );
        if (wethIsBound) return wethTokenAddress;

        //get token list
        address[] memory tokens = IBPool(_ToBalancerPoolAddress)
            .getFinalTokens();

        uint256 amount = _amount;
        address[] memory path = new address[](2);

        if (
            _FromTokenContractAddress != address(0) &&
            _FromTokenContractAddress != wethTokenAddress
        ) {
            path[0] = _FromTokenContractAddress;
            path[1] = wethTokenAddress;
            //get eth value for given token
            amount = uniswapRouter.getAmountsOut(_amount, path)[1];
        }

        uint256 maxBPT;
        path[0] = wethTokenAddress;

        for (uint256 index = 0; index < tokens.length; index++) {
            uint256 expectedBPT;

            if (tokens[index] != wethTokenAddress) {
                if (
                    UniSwapV2FactoryAddress.getPair(
                        tokens[index],
                        wethTokenAddress
                    ) == address(0)
                ) {
                    continue;
                }

                //get qty of tokens
                path[1] = tokens[index];
                uint256 expectedTokens = uniswapRouter.getAmountsOut(
                    amount,
                    path
                )[1];

                //get bpt for given tokens
                expectedBPT = getToken2BPT(
                    _ToBalancerPoolAddress,
                    expectedTokens,
                    tokens[index]
                );

                //get token giving max BPT
                if (maxBPT < expectedBPT) {
                    maxBPT = expectedBPT;
                    _token = tokens[index];
                }
            } else {
                //get bpt for given weth tokens
                expectedBPT = getToken2BPT(
                    _ToBalancerPoolAddress,
                    amount,
                    tokens[index]
                );
            }

            //get token giving max BPT
            if (maxBPT < expectedBPT) {
                maxBPT = expectedBPT;
                _token = tokens[index];
            }
        }
    }


    /**
    @notice This function finds best token from the final tokens of balancer pool
    @param _FromBalancerPoolAddress The address of balancer pool to zap out
    @param _IncomingBPT The amount of balancer pool token to covert
    @return _token The token address having max liquidity
     */
    function _getBestDeal(
        address _FromBalancerPoolAddress,
        uint256 _IncomingBPT
    ) internal view returns (address _token) {
        //get token list
        address[] memory tokens = IBPool(_FromBalancerPoolAddress)
            .getFinalTokens();

        uint256 maxEth;

        for (uint256 index = 0; index < tokens.length; index++) {
            //get token for given bpt amount
            uint256 tokensForBPT = _getBPT2Token(
                _FromBalancerPoolAddress,
                _IncomingBPT,
                tokens[index]
            );

            //get eth value for each token
            if (tokens[index] != wethTokenAddress) {
                if (
                    UniSwapV2FactoryAddress.getPair(
                        tokens[index],
                        wethTokenAddress
                    ) == address(0)
                ) {
                    continue;
                }

                address[] memory path = new address[](2);
                path[0] = tokens[index];
                path[1] = wethTokenAddress;
                uint256 ethReturned = uniswapRouter.getAmountsOut(
                    tokensForBPT,
                    path
                )[1];

                //get max eth value
                if (maxEth < ethReturned) {
                    maxEth = ethReturned;
                    _token = tokens[index];
                }
            } else {
                //get max eth value
                if (maxEth < tokensForBPT) {
                    maxEth = tokensForBPT;
                    _token = tokens[index];
                }
            }
        }
    }
}

// File: interfaces/IMooniswap.sol

pragma solidity ^0.6.12;

interface IMooniswap {
    function swap(address src, address dst, uint256 amount, uint256 minReturn, address referral) external payable returns(uint256 result);
    function deposit(uint256[] calldata amounts, uint256[] calldata minAmounts) external payable returns(uint256 fairSupply);
    function withdraw(uint256 amount, uint256[] memory minReturns) external;

    function getTokens() external view returns(IERC20[] memory);

    function balanceOf(address whom) external view returns (uint);
    function getReturn(IERC20 src, IERC20 dst, uint256 amount) external view returns(uint256);

    function totalSupply() external view returns (uint256);
}

// File: contracts/libraries/UniERC20.sol

pragma solidity ^0.6.12;

library UniERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    function isETH(IERC20 token) internal pure returns(bool) {
        return (address(token) == address(0));
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniTransferFromSenderToThis(IERC20 token, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                require(msg.value >= amount, "UniERC20: not enough value");
                if (msg.value > amount) {
                    // Return remainder if exist
                    msg.sender.transfer(msg.value.sub(amount));
                }
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
        }
    }

    function uniSymbol(IERC20 token) internal view returns(string memory) {
        if (isETH(token)) {
            return "ETH";
        }

        (bool success, bytes memory data) = address(token).staticcall{ gas: 20000 }(
            abi.encodeWithSignature("symbol()")
        );
        if (!success) {
            (success, data) = address(token).staticcall{ gas: 20000 }(
                abi.encodeWithSignature("SYMBOL()")
            );
        }

        if (success && data.length >= 96) {
            (uint256 offset, uint256 len) = abi.decode(data, (uint256, uint256));
            if (offset == 0x20 && len > 0 && len <= 256) {
                return string(abi.decode(data, (bytes)));
            }
        }

        if (success && data.length == 32) {
            uint len = 0;
            while (len < data.length && data[len] >= 0x20 && data[len] <= 0x7E) {
                len++;
            }

            if (len > 0) {
                bytes memory result = new bytes(len);
                for (uint i = 0; i < len; i++) {
                    result[i] = data[i];
                }
                return string(result);
            }
        }

        return _toHex(address(token));
    }

    function _toHex(address account) private pure returns(string memory) {
        return _toHex(abi.encodePacked(account));
    }

    function _toHex(bytes memory data) private pure returns(string memory) {
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        uint j = 2;
        for (uint i = 0; i < data.length; i++) {
            uint a = uint8(data[i]) >> 4;
            uint b = uint8(data[i]) & 0x0f;
            str[j++] = byte(uint8(a + 48 + (a/10)*39));
            str[j++] = byte(uint8(b + 48 + (b/10)*39));
        }

        return string(str);
    }
}

// File: contracts/ReefMooniswapV1.sol

pragma solidity ^0.6.12;

library ReefMooniswapV1 {
    using SafeMath for uint256;
    using Address for address;
    using UniERC20 for IERC20;

    function investIntoMooniswapPool(
        address _FromTokenContractAddress,
        address poolAddress,
        uint256 _amount
    ) public returns(uint256 fairSupply) {
        IMooniswap pool = IMooniswap(poolAddress);
        IERC20[] memory ercTokens = pool.getTokens();

        uint256[] memory amounts = new uint256[](2);
        uint256[] memory minAmounts = new uint256[](2);

        if (ercTokens[0].isETH() || ercTokens[1].isETH()) {
            IERC20 token = ercTokens[0].isETH() ? ercTokens[1] : ercTokens[0];

            //uint256 rate = pool.getReturn(ercTokens[0], ercTokens[1], _amount);
            uint256 halfAmount = _amount.mul(50).div(100);
            uint256 tokenBought = ReefUniswap.swapFromV2(_FromTokenContractAddress,
                                                 address(token), halfAmount);

            amounts[0] = halfAmount;
            amounts[1] = tokenBought;

            token.approve(
                poolAddress,
                tokenBought
            );

            fairSupply = pool.deposit{value: halfAmount}(
                amounts,
                minAmounts
            );
        } else {
            (uint256 token0Bought, uint256 token1Bought) = ReefUniswap.exchangeTokensV2(
                _FromTokenContractAddress,
                address(ercTokens[0]),
                address(ercTokens[1]),
                _amount
            );

            amounts[0] = token0Bought;
            amounts[1] = token1Bought;

            ercTokens[0].approve(
                poolAddress,
                token0Bought
            );

            TransferHelper.safeApprove(address(ercTokens[1]),
                poolAddress,
                token1Bought
            );

            fairSupply = pool.deposit(
                amounts,
                minAmounts
            );

            // Check for change and return it (there must be a better way for
            // this)
            uint256 token0Balance = ercTokens[0].balanceOf((address(this)));
            uint256 token1Balance = ercTokens[1].balanceOf((address(this)));

            if (token0Balance > 0) {
                ReefUniswap.swapFromV2(address(ercTokens[0]),
                                       _FromTokenContractAddress, token0Balance);
            }

            if (token1Balance > 0) {
                ReefUniswap.swapFromV2(address(ercTokens[1]),
                                       _FromTokenContractAddress, token1Balance);
            }
        }
    }

    function disinvestFromMooniswapPool(
        address _ToTokenContractAddress,
        address poolAddress,
        uint256 _amount
    ) public {
        IMooniswap pool = IMooniswap(poolAddress);
        IERC20[] memory ercTokens = pool.getTokens();
        uint256 totalSupply = pool.totalSupply();

        uint256[] memory minAmounts = new uint256[](2);
        uint256[] memory tokenReturns = new uint256[](2);

        for (uint i = 0; i < ercTokens.length; i++) {
            uint256 preBalance = ercTokens[i].uniBalanceOf(poolAddress);
            tokenReturns[i] = preBalance.mul(_amount).div(totalSupply);
        }

        pool.withdraw(
            _amount,
            minAmounts
        );

        for (uint i = 0; i < tokenReturns.length; i++) {
            if (!ercTokens[i].isETH()) {
                ReefUniswap.swapFromV2(address(ercTokens[i]),
                                       _ToTokenContractAddress,
                                       tokenReturns[i]);
            }
        }
    }

}

// File: contracts/ReefBasket.sol











pragma solidity ^0.6.12;

contract ReefBasket is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    bool private stopped = false;
    uint16 public protocolTokenDisinvestPercentage;
    address public protocolTokenAddress;
    uint256 public minimalInvestment = 1 ether;

    // Limit how much funds we can handle
    uint256 public maxInvestedFunds = 100 ether;
    uint256 public currentInvestedFunds;

    // Define baskets
    struct UniswapV2Pool {
        uint8 weight;
        address uniswapToken0;
        address uniswapToken1;
    }

    struct Token {
        uint8 weight;
        address tokenAddress;
    }

    struct Pool {
        uint8 weight;
        address poolAddress;
    }

    struct Basket {
        string name;
        address referrer;
        UniswapV2Pool[] uniswapPools;
        Token[] tokens;
        Pool[] balancerPools;
        Pool[] mooniswapPools;
    }

    struct BasketBalance {
        uint256 investedAmount;
        mapping(uint256 => uint256) uniswapPools;
        mapping(uint256 => uint256) balancerPools;
        mapping(uint256 => uint256) mooniswapPools;
        mapping(uint256 => uint256) tokens;
    }

    struct UserBalance {
        mapping(uint256 => BasketBalance) basketBalances;
    }

    event Invest(
        address indexed user,
        uint256 indexed basketId,
        uint256 investedAmount
    );

    event Disinvest(
        address indexed user,
        uint256 indexed basketId,
        uint256 disinvestedAmount
    );

    event BasketCreated(uint256 indexed basketId, address indexed user);

    uint256 public availableBasketsSize;
    mapping(uint256 => Basket) public availableBaskets;

    mapping(address => UserBalance) private userBalance;

    address wethTokenAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        uint16 _protocolTokenDisinvestPercentage,
        address _protocolTokenAddress
    ) public {
        protocolTokenDisinvestPercentage = _protocolTokenDisinvestPercentage;
        protocolTokenAddress = _protocolTokenAddress;
    }

    function balanceOfUniswapPools(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        uint256[] memory uniswapBalances = new uint256[](
            basket.uniswapPools.length
        );
        for (uint256 i = 0; i < basket.uniswapPools.length; i++) {
            uniswapBalances[i] = userBalance[_owner]
                .basketBalances[_basketIndex]
                .uniswapPools[i];
        }

        return uniswapBalances;
    }

    function balanceOfTokens(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        uint256[] memory tokenBalances = new uint256[](basket.tokens.length);
        for (uint256 i = 0; i < basket.tokens.length; i++) {
            tokenBalances[i] = userBalance[_owner].basketBalances[_basketIndex]
                .tokens[i];
        }

        return tokenBalances;
    }

    function balanceOfBalancerPools(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        uint256[] memory balancerBalances = new uint256[](
            basket.balancerPools.length
        );
        for (uint256 i = 0; i < basket.balancerPools.length; i++) {
            balancerBalances[i] = userBalance[_owner]
                .basketBalances[_basketIndex]
                .balancerPools[i];
        }

        return balancerBalances;
    }

    function balanceOfMooniswapPools(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        uint256[] memory mooniswapBalances = new uint256[](
            basket.mooniswapPools.length
        );
        for (uint256 i = 0; i < basket.mooniswapPools.length; i++) {
            mooniswapBalances[i] = userBalance[_owner]
                .basketBalances[_basketIndex]
                .mooniswapPools[i];
        }

        return mooniswapBalances;
    }

    function investedAmountInBasket(address _owner, uint256 _basketIndex)
        public
        view
        returns (uint256)
    {
        return userBalance[_owner].basketBalances[_basketIndex].investedAmount;
    }

    function getAvailableBasketUniswapPools(uint256 _basketIndex)
        public
        view
        returns (address[2][] memory, uint8[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        address[2][] memory uniswapPools = new address[2][](
            basket.uniswapPools.length
        );
        uint8[] memory uniswapWeights = new uint8[](basket.uniswapPools.length);

        for (uint256 i = 0; i < basket.uniswapPools.length; i++) {
            uniswapPools[i][0] = basket.uniswapPools[i].uniswapToken0;
            uniswapPools[i][1] = basket.uniswapPools[i].uniswapToken1;

            uniswapWeights[i] = basket.uniswapPools[i].weight;
        }

        return (uniswapPools, uniswapWeights);
    }

    function getAvailableBasketTokens(uint8 _basketIndex)
        public
        view
        returns (address[] memory, uint8[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        address[] memory tokens = new address[](basket.tokens.length);
        uint8[] memory tokensWeights = new uint8[](basket.tokens.length);
        for (uint256 i = 0; i < basket.tokens.length; i++) {
            tokens[i] = basket.tokens[i].tokenAddress;

            tokensWeights[i] = basket.tokens[i].weight;
        }

        return (tokens, tokensWeights);
    }

    function getAvailableBasketBalancerPools(uint256 _basketIndex)
        public
        view
        returns (address[] memory, uint8[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        address[] memory balancerPools = new address[](
            basket.balancerPools.length
        );
        uint8[] memory balancerWeights = new uint8[](
            basket.balancerPools.length
        );
        for (uint256 i = 0; i < basket.balancerPools.length; i++) {
            balancerPools[i] = basket.balancerPools[i].poolAddress;

            balancerWeights[i] = basket.balancerPools[i].weight;
        }

        return (balancerPools, balancerWeights);
    }

    function getAvailableBasketMooniswapPools(uint256 _basketIndex)
        public
        view
        returns (address[] memory, uint8[] memory)
    {
        Basket storage basket = availableBaskets[_basketIndex];

        address[] memory mooniswapPools = new address[](
            basket.mooniswapPools.length
        );
        uint8[] memory mooniswapWeights = new uint8[](
            basket.mooniswapPools.length
        );
        for (uint256 i = 0; i < basket.mooniswapPools.length; i++) {
            mooniswapPools[i] = basket.mooniswapPools[i].poolAddress;

            mooniswapWeights[i] = basket.mooniswapPools[i].weight;
        }

        return (mooniswapPools, mooniswapWeights);
    }

    function createBasket(
        string memory _name,
        address[2][] memory _uniswapPools,
        uint8[] memory _uniswapPoolsWeights,
        address[] memory _tokens,
        uint8[] memory _tokensWeights,
        address[] memory _balancerPools,
        uint8[] memory _balancerPoolsWeights,
        address[] memory _mooniswapPools,
        uint8[] memory _mooniswapPoolsWeights
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        require(
            _uniswapPoolsWeights.length > 0 ||
                _tokensWeights.length > 0 ||
                _balancerPoolsWeights.length > 0 ||
                _mooniswapPoolsWeights.length > 0,
            "0 assets given"
        );
        require(_uniswapPools.length == _uniswapPoolsWeights.length);
        require(_tokens.length == _tokensWeights.length);
        require(_balancerPools.length == _balancerPoolsWeights.length);
        require(_mooniswapPools.length == _mooniswapPoolsWeights.length);

        uint256 totalWeights;
        Basket storage basket = availableBaskets[availableBasketsSize];
        availableBasketsSize++;

        basket.name = _name;
        basket.referrer = msg.sender;

        for (uint256 i = 0; i < _uniswapPoolsWeights.length; i++) {
            totalWeights = (totalWeights).add(_uniswapPoolsWeights[i]);
        }
        for (uint256 i = 0; i < _tokensWeights.length; i++) {
            totalWeights = (totalWeights).add(_tokensWeights[i]);
        }
        for (uint256 i = 0; i < _balancerPoolsWeights.length; i++) {
            totalWeights = (totalWeights).add(_balancerPoolsWeights[i]);
        }
        for (uint256 i = 0; i < _mooniswapPoolsWeights.length; i++) {
            totalWeights = (totalWeights).add(_mooniswapPoolsWeights[i]);
        }

        require(totalWeights == 100, "Basket weights have to sum up to 100.");

        for (uint256 i = 0; i < _uniswapPools.length; i++) {
            UniswapV2Pool memory pool = UniswapV2Pool(
                _uniswapPoolsWeights[i],
                _uniswapPools[i][0],
                _uniswapPools[i][1]
            );

            basket.uniswapPools.push(pool);
        }

        for (uint256 i = 0; i < _tokensWeights.length; i++) {
            Token memory token = Token(_tokensWeights[i], _tokens[i]);

            basket.tokens.push(token);
        }

        for (uint256 i = 0; i < _balancerPools.length; i++) {
            Pool memory balancerPool = Pool(
                _balancerPoolsWeights[i],
                _balancerPools[i]
            );

            basket.balancerPools.push(balancerPool);
        }

        for (uint256 i = 0; i < _mooniswapPools.length; i++) {
            Pool memory mooniswapPool = Pool(
                _mooniswapPoolsWeights[i],
                _mooniswapPools[i]
            );

            basket.mooniswapPools.push(mooniswapPool);
        }

        emit BasketCreated(availableBasketsSize - 1, msg.sender);

        uint256[] memory baskets = new uint256[](1);
        uint256[] memory weights = new uint256[](1);
        baskets[0] = availableBasketsSize - 1;
        weights[0] = 100;

        return _multiInvest(baskets, weights, 1);
    }

    /**
    @notice This function is used to invest in given Uniswap V2 pair through ETH/ERC20 Tokens
    @param _basketIndexes basket indexes to invest into
    @param _weights corresponding basket weights (percentage) how much to invest
    @param _minPoolTokens Reverts if less tokens received than this
    @return Amount of LP bought
     */
    function invest(
        uint256[] memory _basketIndexes,
        uint256[] memory _weights,
        uint256 _minPoolTokens
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        return _multiInvest(_basketIndexes, _weights, _minPoolTokens);
    }

    function _multiInvest(
        uint256[] memory _basketIndexes,
        uint256[] memory _weights,
        uint256 _minPoolTokens
    ) internal returns (uint256) {
        require(msg.value > 0, "Error: ETH not sent");

        // Check weights
        require(_basketIndexes.length == _weights.length);
        uint256 totalWeights;
        for (uint256 i = 0; i < _weights.length; i++) {
            totalWeights = (totalWeights).add(_weights[i]);
        }

        require(totalWeights == 100, "Basket _weights have to sum up to 100.");

        for (uint256 i = 0; i < _weights.length; i++) {
            uint256 basketInvestAmount = (msg.value).mul(_weights[i]).div(100);
            require(
                basketInvestAmount >= minimalInvestment,
                "Too low invest amount."
            );

            _invest(_basketIndexes[i], basketInvestAmount, _minPoolTokens);
        }

        // Return change
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
    }

    function _invest(
        uint256 _basketIndex,
        uint256 _amount,
        uint256 _minPoolTokens
    ) internal returns (uint256) {
        require(
            _basketIndex < availableBasketsSize,
            "Error: basket index out of bounds"
        );
        uint256 startBalance = address(this).balance;

        // Invest into pools
        for (
            uint256 i = 0;
            i < availableBaskets[_basketIndex].uniswapPools.length;
            i++
        ) {
            UniswapV2Pool memory pool = availableBaskets[_basketIndex]
                .uniswapPools[i];

            uint256 investAmount = (_amount).mul(pool.weight).div(100);

            uint256 LPBought = ReefUniswap._investIntoUniswapPool(
                address(0),
                pool.uniswapToken0,
                pool.uniswapToken1,
                address(this),
                investAmount
            );

            require(LPBought >= _minPoolTokens, "ERR: High Slippage");

            userBalance[msg.sender].basketBalances[_basketIndex]
                .uniswapPools[i] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .uniswapPools[i]
                .add(LPBought);
        }

        // Invest into tokens
        for (
            uint256 i = 0;
            i < availableBaskets[_basketIndex].tokens.length;
            i++
        ) {
            Token memory token = availableBaskets[_basketIndex].tokens[i];
            uint256 investAmount = (_amount).mul(token.weight).div(100);

            uint256 tokenBought = ReefUniswap.swapFromV2(
                address(0),
                token.tokenAddress,
                investAmount
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .tokens[i] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .tokens[i]
                .add(tokenBought);
        }

        // Invest into balancer pool
        for (
            uint256 i = 0;
            i < availableBaskets[_basketIndex].balancerPools.length;
            i++
        ) {
            Pool memory balancerPool = availableBaskets[_basketIndex]
                .balancerPools[i];
            uint256 investAmount = (_amount).mul(balancerPool.weight).div(100);

            uint256 balancerTokens = ReefBalancer.investIntoBalancerPool(
                address(this),
                address(0),
                balancerPool.poolAddress,
                investAmount,
                _minPoolTokens
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .balancerPools[i] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .balancerPools[i]
                .add(balancerTokens);
        }

        // Invest into Mooniswap pool
        for (
            uint256 i = 0;
            i < availableBaskets[_basketIndex].mooniswapPools.length;
            i++
        ) {
            Pool memory mooniswapPool = availableBaskets[_basketIndex]
                .mooniswapPools[i];
            uint256 investAmount = (_amount).mul(mooniswapPool.weight).div(100);

            uint256 fairSupply = ReefMooniswapV1.investIntoMooniswapPool(
                address(0),
                mooniswapPool.poolAddress,
                investAmount
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .mooniswapPools[i] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .mooniswapPools[i]
                .add(fairSupply);
        }

        // Update user balance
        uint256 diffBalance = startBalance.sub(address(this).balance);

        userBalance[msg.sender].basketBalances[_basketIndex]
            .investedAmount = userBalance[msg.sender]
            .basketBalances[_basketIndex]
            .investedAmount
            .add(diffBalance);

        // Update current funds
        currentInvestedFunds = currentInvestedFunds.add(diffBalance);
        require(
            currentInvestedFunds <= maxInvestedFunds,
            "Max invested funds exceeded"
        );

        emit Invest(
            msg.sender,
            _basketIndex,
            userBalance[msg.sender].basketBalances[_basketIndex].investedAmount
        );

        return
            userBalance[msg.sender].basketBalances[_basketIndex].investedAmount;
    }

    function disinvest(
        uint256 _basketIndex,
        uint256 _percent,
        uint256 _protocolYieldRatio,
        bool shouldRestake
    ) public payable nonReentrant stopInEmergency returns (uint256) {
        require(
            _basketIndex < availableBasketsSize,
            "Basket index out of bounds"
        );

        require(
            _percent > 0 && _percent <= 100,
            "Percent has to in interval (0, 100]"
        );
        require(
            _protocolYieldRatio <= 100,
            "Protocol yield ratio not in interval (0, 100]"
        );

        // Disinvest uniswap pools
        for (
            uint256 p = 0;
            p < availableBaskets[_basketIndex].uniswapPools.length;
            p++
        ) {
            uint256 currentBalance = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .uniswapPools[p];

            require(currentBalance > 0, "balance must be positive");

            UniswapV2Pool memory pool = availableBaskets[_basketIndex]
                .uniswapPools[p];
            uint256 disinvestAmount = (currentBalance).mul(_percent).div(100);

            (uint256 amountA, uint256 amountB) = ReefUniswap
                ._disinvestFromUniswapPool(
                address(0),
                pool.uniswapToken0,
                pool.uniswapToken1,
                disinvestAmount
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .uniswapPools[p] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .uniswapPools[p]
                .sub(disinvestAmount);
        }

        // Disinvest tokens
        for (
            uint256 t = 0;
            t < availableBaskets[_basketIndex].tokens.length;
            t++
        ) {
            uint256 currentBalance = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .tokens[t];

            require(currentBalance > 0, "balance must be positive");

            Token memory token = availableBaskets[_basketIndex].tokens[t];
            uint256 disinvestAmount = (currentBalance).mul(_percent).div(100);

            if (ReefUniswap.canSwapFromV2(token.tokenAddress, address(0))) {
                uint256 tokenBought = ReefUniswap.swapFromV2(
                    token.tokenAddress,
                    address(0),
                    disinvestAmount
                );

                TransferHelper.safeTransfer(
                    address(0),
                    msg.sender,
                    tokenBought
                );
            }

            userBalance[msg.sender].basketBalances[_basketIndex]
                .tokens[t] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .tokens[t]
                .sub(disinvestAmount);
        }

        // Disinvest Balancer pools
        for (
            uint256 b = 0;
            b < availableBaskets[_basketIndex].balancerPools.length;
            b++
        ) {
            require(
                userBalance[msg.sender].basketBalances[_basketIndex]
                    .balancerPools[b] > 0,
                "balance must be positive"
            );

            uint256 disinvestAmount = (
                userBalance[msg.sender].basketBalances[_basketIndex]
                    .balancerPools[b]
            )
                .mul(_percent)
                .div(100);

            IERC20(availableBaskets[_basketIndex].balancerPools[b].poolAddress)
                .approve(address(ReefBalancer), disinvestAmount);

            // TODO: figure out slippage
            uint256 balancerTokens = ReefBalancer.disinvestFromBalancerPool(
                payable(address(this)),
                address(0),
                availableBaskets[_basketIndex].balancerPools[b].poolAddress,
                disinvestAmount,
                1
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .balancerPools[b] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .balancerPools[b]
                .sub(disinvestAmount);
        }

        // Disinvest Mooniswap pools
        for (
            uint256 b = 0;
            b < availableBaskets[_basketIndex].mooniswapPools.length;
            b++
        ) {
            require(
                userBalance[msg.sender].basketBalances[_basketIndex]
                    .mooniswapPools[b] > 0,
                "balance must be positive"
            );

            uint256 disinvestAmount = (
                userBalance[msg.sender].basketBalances[_basketIndex]
                    .mooniswapPools[b]
            )
                .mul(_percent)
                .div(100);

            // TODO: figure out slippage
            ReefMooniswapV1.disinvestFromMooniswapPool(
                address(0),
                availableBaskets[_basketIndex].mooniswapPools[b].poolAddress,
                disinvestAmount
            );

            userBalance[msg.sender].basketBalances[_basketIndex]
                .mooniswapPools[b] = userBalance[msg.sender]
                .basketBalances[_basketIndex]
                .mooniswapPools[b]
                .sub(disinvestAmount);
        }

        // Update user balance
        uint256 basketDisinvestAmount = (
            userBalance[msg.sender].basketBalances[_basketIndex].investedAmount
        )
            .mul(_percent)
            .div(100);

        userBalance[msg.sender].basketBalances[_basketIndex]
            .investedAmount = userBalance[msg.sender]
            .basketBalances[_basketIndex]
            .investedAmount
            .sub(basketDisinvestAmount);

        emit Disinvest(msg.sender, _basketIndex, basketDisinvestAmount);

        // Update current funds
        currentInvestedFunds = currentInvestedFunds.sub(basketDisinvestAmount);

        // Stake the profit into REEF tokens
        if (address(this).balance > basketDisinvestAmount) {
            uint256 profit = address(this).balance - basketDisinvestAmount;

            // Return the liquidation
            uint256 yieldRatio = protocolTokenDisinvestPercentage >
                _protocolYieldRatio
                ? protocolTokenDisinvestPercentage
                : _protocolYieldRatio;

            if (yieldRatio > 0) {
                // Check if we restake into the ETH/protocolToken pool
                if (shouldRestake) {
                    ReefUniswap._investIntoUniswapPool(
                        address(0),
                        wethTokenAddress,
                        protocolTokenAddress,
                        msg.sender,
                        profit.mul(yieldRatio).div(100)
                    );
                } else {
                    uint256 protocolTokenAmount = ReefUniswap.swapFromV2(
                        address(0),
                        protocolTokenAddress,
                        profit.mul(yieldRatio).div(100)
                    );

                    if (protocolTokenAmount > 0) {
                        TransferHelper.safeTransfer(
                            protocolTokenAddress,
                            msg.sender,
                            protocolTokenAmount
                        );
                    }
                }
            }
        }

        // Return the remaining ETH
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
    }

    function setProtocolTokenDisinvestPercentage(uint16 _newPercentage)
        public
        onlyOwner
    {
        require(
            _newPercentage >= 0 && _newPercentage < 100,
            "_newPercentage must be between 0 and 100."
        );
        protocolTokenDisinvestPercentage = _newPercentage;
    }

    function setProtocolTokenAddress(address _newProtocolTokenAddress)
        public
        onlyOwner
    {
        protocolTokenAddress = _newProtocolTokenAddress;
    }

    function setMinimalInvestment(uint256 _minimalInvestment) public onlyOwner {
        minimalInvestment = _minimalInvestment;
    }

    function setMaxInvestedFunds(uint256 _maxInvestedFunds) public onlyOwner {
        require(
            _maxInvestedFunds >= currentInvestedFunds,
            "Max funds lower than current funds."
        );
        maxInvestedFunds = _maxInvestedFunds;
    }

    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    function inCaseTokengetsStuck(IERC20 _TokenAddress) public onlyOwner {
        uint256 qty = _TokenAddress.balanceOf(address(this));
        TransferHelper.safeTransfer(address(_TokenAddress), owner(), qty);
    }

    // to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
    }

    // to withdraw any ETH balance sitting in the contract
    function withdraw() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        address payable _to = payable(owner());
        _to.transfer(contractBalance);
    }

    receive() external payable {}
}