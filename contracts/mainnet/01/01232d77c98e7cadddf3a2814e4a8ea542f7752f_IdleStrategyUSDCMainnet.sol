/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

// SPDX-License-Identifier: MIT

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
}

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
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  using SafeMath for uint256;
    
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }
  
  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }
  
  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

// File: contracts/uniswap/interfaces/IUniswapV2Router01.sol
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

// File: contracts/uniswap/interfaces/IUniswapV2Router02.sol
interface IUniswapV2Router02 {
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

interface IIdleTokenV3_1 {
    // view
    /**
     * IdleToken price calculation, in underlying
     *
     * return : price in underlying token
     */
    function tokenPrice() external view returns (uint256 price);

    /**
     * @return : underlying token address
     */
    function token() external view returns (address);
    /**
     * Get APR of every ILendingProtocol
     *
     * return addresses: array of token addresses
     * return aprs: array of aprs (ordered in respect to the `addresses` array)
     */
    function getAPRs() external view returns (address[] memory addresses, uint256[] memory aprs);

    // external
    // We should save the amount one has deposited to calc interests

    /**
     * Used to mint IdleTokens, given an underlying amount (eg. DAI).
     * This method triggers a rebalance of the pools if needed
     * NOTE: User should 'approve' _amount of tokens before calling mintIdleToken
     * NOTE 2: this method can be paused
     *
     * @param _amount : amount of underlying token to be lended
     * @param _skipRebalance : flag for skipping rebalance for lower gas price
     * @param _referral : referral address
     * @return mintedTokens : amount of IdleTokens minted
     */
    function mintIdleToken(uint256 _amount, bool _skipRebalance, address _referral) external returns (uint256 mintedTokens);

    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * This method triggers a rebalance of the pools if needed
     * NOTE: If the contract is paused or iToken price has decreased one can still redeem but no rebalance happens.
     * NOTE 2: If iToken price has decresed one should not redeem (but can do it) otherwise he would capitalize the loss.
     *         Ideally one should wait until the black swan event is terminated
     *
     * @param _amount : amount of IdleTokens to be burned
     * @return redeemedTokens : amount of underlying tokens redeemed
     */
    function redeemIdleToken(uint256 _amount) external returns (uint256 redeemedTokens);
    /**
     * Here we calc the pool share one can withdraw given the amount of IdleToken they want to burn
     * and send interest-bearing tokens (eg. cDAI/iDAI) directly to the user.
     * Underlying (eg. DAI) is not redeemed here.
     *
     * @param _amount : amount of IdleTokens to be burned
     */
    function redeemInterestBearingTokens(uint256 _amount) external;

    /**
     * @return : whether has rebalanced or not
     */
    function rebalance() external returns (bool);
}

interface IIdleTokenHelper {
  function getMintingPrice(address idleYieldToken) view external returns (uint256 mintingPrice);
  function getRedeemPrice(address idleYieldToken) view external returns (uint256 redeemPrice);
  function getRedeemPrice(address idleYieldToken, address user) view external returns (uint256 redeemPrice);
}


contract IdleFinanceStrategy is Ownable {

  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event ProfitsNotCollected(address);
  event Liquidating(address, uint256);

  IERC20 public underlying;
  address public idleUnderlying;
  uint256 public virtualPrice;
  IIdleTokenHelper public idleTokenHelper;

  address public vault;
  address public comp;
  address public idle;

  address[] public uniswapComp;
  address[] public uniswapIdle;

  address public uniswapRouterV2;

  bool public sellComp;
  bool public sellIdle;
  bool public claimAllowed;
  bool public protected;

  // These tokens cannot be claimed by the controller
  mapping (address => bool) public unsalvagableTokens;

  modifier restricted() {
    require(msg.sender == vault, "The sender has to be the controller or vault or governance");
    _;
  }

  modifier updateVirtualPrice() {
    if (protected) {
      require(virtualPrice <= idleTokenHelper.getRedeemPrice(idleUnderlying), "virtual price is higher than needed");
    }
    _;
    virtualPrice = idleTokenHelper.getRedeemPrice(idleUnderlying);
  }

  constructor(
    address _underlying,
    address _idleUnderlying,
    address _vault,
    address _comp,
    address _idle,
    address _weth,
    address _uniswap
  ) public {
    comp = _comp;
    idle = _idle;
    underlying = IERC20(_underlying);
    idleUnderlying = _idleUnderlying;
    vault = _vault;
    uniswapRouterV2 = _uniswap;
    protected = true;

    // set these tokens to be not salvagable
    unsalvagableTokens[_underlying] = true;
    unsalvagableTokens[_idleUnderlying] = true;
    unsalvagableTokens[_comp] = true;
    unsalvagableTokens[_idle] = true;

    uniswapComp = [_comp, _weth, _idle];
    uniswapIdle = [_idle, _weth, _underlying];
    
    idleTokenHelper = IIdleTokenHelper(0x04Ce60ed10F6D2CfF3AA015fc7b950D13c113be5);
    virtualPrice = idleTokenHelper.getRedeemPrice(idleUnderlying);
  }

  /**
  * The strategy invests by supplying the underlying token into IDLE.
  */
  function investAllUnderlying() public restricted updateVirtualPrice {
    uint256 balance = underlying.balanceOf(address(this));
    underlying.safeApprove(address(idleUnderlying), 0);
    underlying.safeApprove(address(idleUnderlying), balance);
    IIdleTokenV3_1(idleUnderlying).mintIdleToken(balance, true, address(0));
  }

  /**
  * Exits IDLE and transfers everything to the vault.
  */
  function withdrawAllToVault() external restricted updateVirtualPrice {
    withdrawAll();
    IERC20(address(underlying)).safeTransfer(vault, underlying.balanceOf(address(this)));
  }

  /**
  * Withdraws all from IDLE
  */
  function withdrawAll() internal {
    uint256 balance = IERC20(idleUnderlying).balanceOf(address(this));

    // this automatically claims the crops
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(balance);

    liquidateComp();
    liquidateIdle();
  }

  function withdrawToVault(uint256 amountUnderlying) public restricted {
    // this method is called when the vault is missing funds
    // we will calculate the proportion of idle LP tokens that matches
    // the underlying amount requested
    uint256 balanceBefore = underlying.balanceOf(address(this));
    uint256 totalIdleLpTokens = IERC20(idleUnderlying).balanceOf(address(this));
    uint256 totalUnderlyingBalance = totalIdleLpTokens.mul(virtualPrice).div(1e18);
    uint256 ratio = amountUnderlying.mul(1e18).div(totalUnderlyingBalance);
    uint256 toRedeem = totalIdleLpTokens.mul(ratio).div(1e18);
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(toRedeem);
    uint256 balanceAfter = underlying.balanceOf(address(this));
    underlying.safeTransfer(vault, balanceAfter.sub(balanceBefore));
  }

  /**
  * Withdraws all assets, liquidates COMP, and invests again in the required ratio.
  */
  function doHardWork() public restricted updateVirtualPrice {
    if (claimAllowed) {
      claim();
    }
    liquidateComp();
    liquidateIdle();

    // this updates the virtual price
    investAllUnderlying();

    // state of supply/loan will be updated by the modifier
  }

  /**
  * Salvages a token.
  */
  function salvage(address recipient, address token, uint256 amount) public onlyOwner {
    // To make sure that governance cannot come in and take away the coins
    require(!unsalvagableTokens[token], "token is defined as not salvagable");
    IERC20(token).safeTransfer(recipient, amount);
  }
  
  function claim() internal {
    IIdleTokenV3_1(idleUnderlying).redeemIdleToken(0);
  }

  function liquidateComp() internal {
    if (!sellComp) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(comp);
      return;
    }

    // no profit notification, comp is liquidated to IDLE and will be notified there

    uint256 compBalance = IERC20(comp).balanceOf(address(this));
    if (compBalance > 0) {
      emit Liquidating(address(comp), compBalance);
      IERC20(comp).safeApprove(uniswapRouterV2, 0);
      IERC20(comp).safeApprove(uniswapRouterV2, compBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        compBalance, 1, uniswapComp, address(this), block.timestamp
      );
    }
  }

  function liquidateIdle() internal {
    if (!sellIdle) {
      // Profits can be disabled for possible simplified and rapid exit
      emit ProfitsNotCollected(idle);
      return;
    }

    uint256 idleBalance = IERC20(idle).balanceOf(address(this));
    if (idleBalance > 0) {
      emit Liquidating(address(idle), idleBalance);
      IERC20(idle).safeApprove(uniswapRouterV2, 0);
      IERC20(idle).safeApprove(uniswapRouterV2, idleBalance);
      // we can accept 1 as the minimum because this will be called only by a trusted worker
      IUniswapV2Router02(uniswapRouterV2).swapExactTokensForTokens(
        idleBalance, 1, uniswapIdle, address(this), block.timestamp
      );
    }
  }

  /**
  * Returns the current balance. Ignores COMP that was not liquidated and invested.
  */
  function investedUnderlyingBalance() public view returns (uint256) {
    // NOTE: The use of virtual price is okay for appreciating assets inside IDLE,
    // but would be wrong and exploitable if funds were lost by IDLE, indicated by
    // the virtualPrice being greater than the token price.
    if (protected) {
      require(virtualPrice <= idleTokenHelper.getRedeemPrice(idleUnderlying), "virtual price is higher than needed");
    }
    uint256 invested = IERC20(idleUnderlying).balanceOf(address(this)).mul(virtualPrice).div(1e18);
    return invested.add(IERC20(underlying).balanceOf(address(this)));
  }

  function setLiquidation(bool _sellComp, bool _sellIdle, bool _claimAllowed) public onlyOwner {
    sellComp = _sellComp;
    sellIdle = _sellIdle;
    claimAllowed = _claimAllowed;
  }

  function setProtected(bool _protected) public onlyOwner {
    protected = _protected;
  }
}

/**
* Adds the mainnet addresses to the PickleStrategy3Pool
*/
contract IdleStrategyUSDCMainnet is IdleFinanceStrategy {

  // token addresses
  address constant public __weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  address constant public __usdc = address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
  address constant public __uniswap = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address constant public __idleUnderlying= address(0x5274891bEC421B39D23760c04A6755eCB444797C);
  address constant public __comp = address(0xc00e94Cb662C3520282E6f5717214004A7f26888);
  address constant public __idle = address(0x875773784Af8135eA0ef43b5a374AaD105c5D39e);

  constructor(
    address _vault
  )
  IdleFinanceStrategy(
    __usdc,
    __idleUnderlying,
    _vault,
    __comp,
    __idle,
    __weth,
    __uniswap
  )
  public {
  }
}