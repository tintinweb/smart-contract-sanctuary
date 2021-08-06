/**
 *Submitted for verification at BscScan.com on 2021-08-06
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

pragma solidity ^0.8.0;

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

    constructor() {
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

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;


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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity ^0.8.0;

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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
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
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


pragma solidity ^0.8.0;

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

// File: contracts/JackpotGame.sol

pragma solidity 0.8.6;





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

contract JackpotGame is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct BettorInfo {
        uint256 betAmount;
        uint256 betTime;
        uint256 startCredit;
        uint256 endCredit;
        bool isBetted;
    }

    // Timestamps for Game
    uint256 public startTime;
    uint256 public endTime;

    // Total colltected BNB amount
    uint256 public totalCredits;

    // Price of single credit 0.001 BNB
    uint256 public creditPrice = 10**15;

    // Award split factors
    uint256 public constant SHARES_DENOMINATOR = 10000;

    // TODO: Remove these hardcoded fee factors.
    uint256[] marketFeeFactors = [100, 50, 50, 50, 50];
    uint256[] jackpotFeeFactors = [100, 50, 50, 50, 50];
    uint256[] buyBackFeeFactors = [300, 300, 200, 100, 0];
    uint256[] tierLimitAmounts = [
        0,
        1000000000,
        5000000000,
        10000000000,
        50000000000
    ];

    // tier limit amount => fee factor index
    mapping(uint256 => uint256) feeFactorIndexMapping;

    uint256 private validTierIndex;

    // Constant addresses
    address public MARKET_ADDRESS;
    address public JACKPOT_ADDRESS;
    address burnAddress = 0x000000000000000000000000000000000000dEaD;

    // Winner address
    address public winner;

    // Buyback token and V2Router for buyback
    IERC20 public immutable buybackToken;
    IUniswapV2Router02 public immutable uniswapV2Router;

    mapping(address => BettorInfo) private _betMapping;
    address[] private _betted;
    // address[] private _jackpots;

    // $MOONRISE: 0x7ee7f14427cc41d6db17829eb57dc74a26796b9d
    // V2 PCS: 0x10ED43C718714eb63d5aA57B78B54704E256024E

    // Events to let the front end know about changes
    event NewPlayerBet(address bettorAddress, uint256 betAmount);
    event NewGameStarted(uint256 gameStartTime, uint256 gameEndTime);
    event WinnerAnnounced(
        address winnerAddress,
        uint256 winnerAmount,
        uint256 winnerTotalCredits
    );

    constructor(
        address token_,
        address router_,
        address marketAddr_,
        address jackpotAddr_
    ) {
        startTime = block.timestamp;
        endTime = block.timestamp;
        totalCredits = 0;
        validTierIndex = 0;
        buybackToken = IERC20(token_);
        uniswapV2Router = IUniswapV2Router02(router_);
        MARKET_ADDRESS = marketAddr_;
        JACKPOT_ADDRESS = jackpotAddr_;
    }

    modifier gameProceed() {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "JackpotGame: seems like the game has already ended"
        );
        _;
    }

    modifier gameEnded() {
        require(block.timestamp > endTime, "JackpotGame: seems like the game has not ended yet");
        _;
    }

    modifier onlyFresh() {
        require(
            _betMapping[msg.sender].isBetted == false,
            "JackpotGame: existing bettor"
        );
        _;
    }

    modifier onlyUser(address addr) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "JackpotGame: invalid bettor");
        _;
    }

    // === === ===
    function updateMinBetAmount(uint256 amount_) external onlyOwner {
        require(amount_ > 0, "JackpotGame: invalid creditPrice");
        creditPrice = amount_;
    }

    // function updateJackpots(address[] memory pots_) external onlyOwner {
    //     require(pots_.length > 0, "JackpotGame: invalid pots");
    //     _jackpots = pots_;
    // }

    function updateTierLimitAmount(uint256 oldLimit_, uint256 newLimit_)
        external
        onlyOwner
    {
        require(
            oldLimit_ != newLimit_,
            "JackpotGame: new tier limit amount cannot be same as previous one"
        );
        require(newLimit_ > 0, "JackpotGame: invalid tier limit amount");

        uint256 tierIndex = feeFactorIndexMapping[oldLimit_];

        // Checking on zero because fee factor arrays on zero index will always be reserved for zero MOONRISE tier
        // and also because zero returned means it does not exist.
        require(
            tierIndex > 0,
            "JackpotGame: could not find fee factors with this tier limit amount"
        );

        tierLimitAmounts[tierIndex] = newLimit_;
    }

    /// @notice Updates an existing one or add new tier
    /// @param tierLimit_ Tier limit to be updated or for which new factors to be added
    /// @param jackpotFeeFactor_ Updated or new jackpot fee factor value
    /// @param marketFeeFactor_ Updated or new market fee factor value
    /// @param buyBackFeeFactor_ Updated or new buyback fee factor value
    function updateFeeFactors(
        uint256 tierLimit_,
        uint256 jackpotFeeFactor_,
        uint256 marketFeeFactor_,
        uint256 buyBackFeeFactor_
    ) external onlyOwner {
        require(marketFeeFactor_ > 0, "JackpotGame: invalid marketFeeFactor");
        require(buyBackFeeFactor_ > 0, "JackpotGame: invalid buyBackFeeFactor");
        require(jackpotFeeFactor_ > 0, "JackpotGame: invalid jackpotFeeFactor");

        uint256 tierIndex = feeFactorIndexMapping[tierLimit_];

        if (tierIndex == 0) {
            if (tierLimit_ != 0) {
                // No fee factors found for tierLimit_
                // Add new factors for tierLimit_
                feeFactorIndexMapping[tierLimit_] = tierLimitAmounts.length;
                tierLimitAmounts.push(tierLimit_);
                jackpotFeeFactors.push(jackpotFeeFactor_);
                marketFeeFactors.push(marketFeeFactor_);
                buyBackFeeFactors.push(buyBackFeeFactor_);
                return;
            }
        }

        // Either updating 0 MOONRISE or some other tier
        jackpotFeeFactors[tierIndex] = jackpotFeeFactor_;
        marketFeeFactors[tierIndex] = marketFeeFactor_;
        buyBackFeeFactors[tierIndex] = buyBackFeeFactor_;
    }

    function setBurnAddress(address _newBurnAddress) public onlyOwner {
        burnAddress = _newBurnAddress;
    }

    function getAllTiers()
        external
        view
        returns (
            uint256[] memory _tierLimitAmounts,
            uint256[] memory _marketFeeFactors,
            uint256[] memory _jackpotFeeFactors,
            uint256[] memory _buyBackFeeFactors
        )
    {
        return (
            tierLimitAmounts,
            marketFeeFactors,
            jackpotFeeFactors,
            buyBackFeeFactors
        );
    }

    function getAllBettors()
        external
        view
        returns (
            address[] memory _bettedAddresses,
            uint256[] memory _bettedAmounts,
            uint256 _totalBNB
        )
    {
        uint256[] memory bettedAmounts = new uint256[](_betted.length);
        for (uint256 i = 0; i < _betted.length; i++) {
            bettedAmounts[i] = _betMapping[_betted[i]].betAmount;
        }
        return (_betted, bettedAmounts, totalCredits * creditPrice);
    }

    function getBettorInfo(address _bettorAddress) external returns (uint256 _tierIndex, uint256 _bnbAmount, uint256 _moonriseBalance) {
        _validateFeeFactors(_bettorAddress);
        return (validTierIndex, _betMapping[_bettorAddress].betAmount, buybackToken.balanceOf(_bettorAddress));
    }

    // === Game functions ===
    function newGame(uint256 startTime_, uint256 endTime_)
        external
        onlyOwner
        gameEnded
    {
        require(
            startTime_ > block.timestamp,
            "JackpotGame: invalid start time"
        );
        require(
            endTime_ > block.timestamp && endTime_ > startTime_,
            "JackpotGame: invalid end time"
        );

        startTime = startTime_;
        endTime = endTime_;
        totalCredits = 0;
        validTierIndex = 0;
        winner = address(0);

        if (_betted.length > 0) {
            uint256 totalNumber = _betted.length;
            for (uint256 i = totalNumber - 1; i >= 0; i--) {
                _betMapping[_betted[i]].isBetted = false;
                _betted.pop();
            }
        }

        emit NewGameStarted(startTime, endTime);
    }

    function extendGame(uint256 endTime_) external onlyOwner gameProceed {
        require(endTime_ > endTime, "JackpotGame: invalid extend time");

        endTime = endTime_;
    }

    function endGame() external onlyOwner gameEnded nonReentrant {
        if (_betted.length == 1) {
            _refundSinglePlayer();
        } else if (_betted.length > 1) {
            uint256 hashValue = _random(_betted);
            uint256 creditValue = hashValue % totalCredits;

            for (uint256 i = 0; i < _betted.length; i++) {
                if (
                    creditValue >= _betMapping[_betted[i]].startCredit &&
                    creditValue < _betMapping[_betted[i]].endCredit
                ) {
                    winner = _betted[i];
                    break;
                }
            }

            _validateFeeFactors(winner);
            _awardShares();
        }
    }

    function _placeBet()
        private
        gameProceed
        onlyFresh
        onlyUser(msg.sender)
        nonReentrant
    {
        require(
            msg.value > creditPrice,
            "JackpotGame: did not receive enough for a credit"
        );
        require(
            msg.value % creditPrice == 0,
            "JackpotGame: only whole credits can be bought"
        );

        uint256 _thisPlayerCredits = msg.value / creditPrice;

        _betMapping[msg.sender] = BettorInfo(
            msg.value,
            block.timestamp,
            totalCredits,
            totalCredits + _thisPlayerCredits,
            true
        );
        totalCredits += _thisPlayerCredits;
        _betted.push(msg.sender);

        emit NewPlayerBet(msg.sender, msg.value);
    }

    function _refundSinglePlayer() private {
        uint256 totalBNBShares = totalCredits * creditPrice;
        payable(_betted[0]).transfer(totalBNBShares);

        emit WinnerAnnounced(winner, totalBNBShares, totalCredits);
    }

    function _validateFeeFactors(address _validateFor) private {
        uint256 balance = buybackToken.balanceOf(_validateFor);
        uint256 decimals = 9; // Moonrise Token decimals

        for (uint256 i = tierLimitAmounts.length; i >= 0; i--) {
            if (balance == tierLimitAmounts[i] * 10**decimals) {
                validTierIndex = i;
                break;
            }
        }
    }

    function _awardShares() private {
        uint256 totalBNBShares = totalCredits * creditPrice;
        require(
            address(this).balance >= totalBNBShares,
            "JackpotGame: invalid total shares"
        );

        uint256 jackpotFeeAmount = (totalBNBShares *
            jackpotFeeFactors[validTierIndex]) / SHARES_DENOMINATOR;
        uint256 marketFeeAmount = (totalBNBShares *
            marketFeeFactors[validTierIndex]) / SHARES_DENOMINATOR;
        uint256 buyBackFeeAmount = (totalBNBShares *
            buyBackFeeFactors[validTierIndex]) / SHARES_DENOMINATOR;

        payable(JACKPOT_ADDRESS).transfer(jackpotFeeAmount);
        payable(MARKET_ADDRESS).transfer(marketFeeAmount);
        _swapExactETHForTokens(buyBackFeeAmount);

        uint256 winnerAwardAmount = totalBNBShares -
            jackpotFeeAmount -
            marketFeeAmount -
            buyBackFeeAmount;
        payable(winner).transfer(winnerAwardAmount);

        emit WinnerAnnounced(winner, winnerAwardAmount, totalCredits);
    }

    function _swapExactETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(buybackToken);

        // make the swap
        uniswapV2Router.swapExactETHForTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            address(this),
            block.timestamp
        );
        buybackToken.transfer(
            burnAddress,
            buybackToken.balanceOf(address(this))
        );
    }

    function _random(address[] memory data) internal view returns (uint256) {
        uint256 hashValue = uint256(
            keccak256(abi.encodePacked(block.difficulty, block.timestamp, data))
        );
        return hashValue;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        _placeBet();
    }

    // Fallback function is called when msg.data is not empty
    fallback() external payable {
        _placeBet();
    }
}