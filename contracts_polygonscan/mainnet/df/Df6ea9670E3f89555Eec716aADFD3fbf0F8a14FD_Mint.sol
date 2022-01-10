/**
 *Submitted for verification at polygonscan.com on 2022-01-10
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

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


// File contracts/interface/IChainlinkAggregator.sol

pragma solidity ^0.8.0;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}


// File contracts/interface/IERC20Extented.sol

pragma solidity ^0.8.0;

interface IERC20Extented is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);
}


// File contracts/interface/IAssetToken.sol

pragma solidity ^0.8.0;

interface IAssetToken is IERC20Extented {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function owner() external view;
}


// File contracts/interface/IAsset.sol

pragma solidity ^0.8.2;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


struct IPOParams {
    uint256 mintEnd;
    uint256 preIPOPrice;
    // >= 1000
    uint16 minCRatioAfterIPO;
}

struct AssetConfig {
    IAssetToken token;
    IChainlinkAggregator oracle;
    uint16 auctionDiscount;
    uint16 minCRatio;
    uint16 targetRatio;
    uint256 endPrice;
    uint8 endPriceDecimals;
    // is in preIPO stage
    bool isInPreIPO;
    IPOParams ipoParams;
    // is it been delisted
    bool delisted;
    // the Id of the pool in ShortStaking contract.
    uint256 poolId;
    // if it has been assined
    bool assigned;
}

// Collateral Asset Config
struct CAssetConfig {
    IERC20Extented token;
    IChainlinkAggregator oracle;
    uint16 multiplier;
    // if it has been assined
    bool assigned;
}

interface IAsset {
    function asset(address nToken) external view returns (AssetConfig memory);

    function cAsset(address token) external view returns (CAssetConfig memory);

    function isCollateralInPreIPO(address cAssetToken)
        external
        view
        returns (bool);
}


// File contracts/interface/IShortLock.sol

pragma solidity ^0.8.2;

struct PositionLockInfo {
    uint256 positionId;
    address receiver;
    IERC20 lockedToken; // address(1) means native token, such as ETH or MITIC.
    uint256 lockedAmount;
    uint256 unlockTime;
    bool assigned;
}

interface IShortLock {
    function lock(
        uint256 positionId,
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function unlock(uint256 positionId) external;

    function release(uint256 positionId) external;

    function lockInfoMap(uint256 positionId)
        external
        view
        returns (PositionLockInfo memory);
}


// File contracts/interface/IStakingToken.sol

pragma solidity ^0.8.0;

interface IStakingToken is IERC20Extented {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function owner() external view returns (address);
}


// File contracts/interface/IShortStaking.sol

pragma solidity ^0.8.2;

interface IShortStaking {
    function pendingNSDX(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _realUser
    ) external;

    function withdraw(
        uint256 _pid,
        uint256 _amount,
        address _realUser
    ) external;

    function poolLength() external view returns (uint256);
}


// File contracts/interface/IPositions.sol

pragma solidity ^0.8.2;

struct Position {
    uint256 id;
    address owner;
    // collateral asset token.
    IERC20Extented cAssetToken;
    uint256 cAssetAmount;
    // nAsset token.
    IAssetToken assetToken;
    uint256 assetAmount;
    // if is it short position
    bool isShort;
    bool assigned;
}

interface IPositions {
    function openPosition(
        address owner,
        IERC20Extented cAssetToken,
        uint256 cAssetAmount,
        IAssetToken assetToken,
        uint256 assetAmount,
        bool isShort
    ) external returns (uint256 positionId);

    function updatePosition(Position memory position_) external;

    function removePosition(uint256 positionId) external;

    function getPosition(uint256 positionId)
        external
        view
        returns (Position memory);

    function getNextPositionId() external view returns (uint256);

    function getPositions(
        address ownerAddr,
        uint256 startAt,
        uint256 limit
    ) external view returns (Position[] memory);
}


// File contracts/interface/IUniswapV2Router.sol

pragma solidity ^0.8.2;

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
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
}


// File contracts/library/Swappable.sol

pragma solidity ^0.8.2;

library Swappable {
    function swapExactTokensForTokens(
        address swapRouter,
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        uint256[] memory amounts = IUniswapV2Router(swapRouter)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                deadline
            );
        amountOut = amounts[amounts.length - 1];
    }

    function swapExactTokensForETH(
        address swapRouter,
        address weth,
        uint256 amountIn,
        uint256 amountOutMin,
        address tokenIn,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        uint256[] memory amounts = IUniswapV2Router(swapRouter)
            .swapExactTokensForETH(amountIn, amountOutMin, path, to, deadline);
        amountOut = amounts[amounts.length - 1];
    }
}


// File contracts/Mint.sol

pragma solidity ^0.8.2;

// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// import "hardhat/console.sol";






/// @title Mint
/// @author Iwan
/// @notice The Mint Contract implements the logic for Collateralized Debt Positions (CDPs),
/// @notice through which users can mint or short new nAsset tokens against their deposited collateral.
/// @dev The Mint Contract also contains the logic for liquidating CDPs with C-ratios below the
/// @dev minimum for their minted mAsset through auction.
contract Mint is Ownable {
    using SafeERC20 for IERC20Extented;
    using SafeERC20 for IAssetToken;
    using SafeERC20 for IERC20;

    // Using the struct to avoid Stack too deep error
    struct VarsInFuncs {
        uint256 assetPrice;
        uint8 assetPriceDecimals;
        uint256 collateralPrice;
        uint8 collateralPriceDecimals;
    }

    struct VarsInAuction {
        uint256 returnedCollateralAmount;
        uint256 refundedAssetAmount;
        uint256 liquidatedAssetAmount;
        uint256 leftAssetAmount;
        uint256 leftCAssetAmount;
        uint256 protocolFee_;
    }

    /// @dev address(1) means native token, such as ETH or MATIC.
    // address constant private NATIVE_TOKEN = address(1);

    uint256 MAX_UINT256 = 2**256 - 1;

    /// @notice token address => total fee amount
    mapping(address => uint256) public protocolFee;

    address public feeTo;

    IAsset public asset;

    IPositions public positions;

    // 0 ~ 1000, fee = amount * feeRate / 1000.
    uint16 public feeRate;

    // Specify a token which will swap to it after
    // selling nAsset when people create a short position.
    address public swapToToken;

    /// @notice Short lock contract address.
    IShortLock public lock;

    /// @notice Short staking contract address.
    IShortStaking public staking;

    // oracle max delay.
    uint256 public oracleMaxDelay;

    address swapRouter;
    address weth;

    /// @notice Triggered when deposit.
    /// @param positionId The index of this position.
    /// @param cAssetAmount collateral amount.
    event Deposit(uint256 positionId, uint256 cAssetAmount);

    /// @notice Triggered when withdraw.
    /// @param positionId The index of this position.
    /// @param cAssetAmount collateral amount.
    event Withdraw(uint256 positionId, uint256 cAssetAmount);

    /// @notice Triggered when mint.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event MintAsset(uint256 positionId, uint256 assetAmount);

    /// @notice Triggered when burn.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event Burn(uint256 positionId, uint256 assetAmount);

    /// @notice Triggered when auction.
    /// @param positionId The index of this position.
    /// @param assetAmount asset amount.
    event Auction(uint256 positionId, uint256 assetAmount);

    /// @notice Constructor
    /// @param feeRate_ The percent of charging fee.
    /// @param swapRouter_ A router address of a swap like Uniswap.
    constructor(
        uint16 feeRate_,
        address asset_,
        address positions_,
        address swapToToken_,
        address lock_,
        address staking_,
        address swapRouter_,
        address weth_,
        address feeTo_
    ) {
        weth = weth_;

        updateState(
            asset_,
            positions_,
            300,
            swapToToken_,
            feeRate_,
            lock_,
            staking_,
            swapRouter_,
            feeTo_
        );
    }

    function updateState(
        address asset_,
        address positions_,
        uint256 oracleMaxDelay_,
        address swapToToken_,
        uint16 feeRate_,
        address lock_,
        address staking_,
        address swapRouter_,
        address feeTo_
    ) public onlyOwner {
        // IERC20Extented(swapToToken).safeApprove(address(lock), 0);
        // IERC20Extented(swapToToken).safeApprove(swapRouter, 0);
        asset = IAsset(asset_);
        positions = IPositions(positions_);
        require(feeRate_ >= 0 || feeRate_ <= 1000, "out of range");
        feeRate = feeRate_;
        require(swapToToken_ != address(0), "wrong address");
        swapToToken = swapToToken_;
        oracleMaxDelay = oracleMaxDelay_;
        lock = IShortLock(lock_);
        staking = IShortStaking(staking_);
        swapRouter = swapRouter_;
        feeTo = feeTo_;
        IERC20Extented(swapToToken).approve(address(lock), MAX_UINT256);
        IERC20Extented(swapToToken).approve(swapRouter, MAX_UINT256);
    }

    /// @notice Open a new position by collateralizing assets. (Mint nAsset)
    /// @dev The C-Ratio users provided cannot less than the min C-Ratio in system.
    /// @param assetToken nAsset token address
    /// @param cAssetToken collateral token address
    /// @param cAssetAmount collateral amount
    /// @param cRatio collateral ratio
    function openPosition(
        IAssetToken assetToken,
        IERC20Extented cAssetToken,
        uint256 cAssetAmount,
        uint16 cRatio
    ) public {
        _openPosition(
            assetToken,
            cAssetToken,
            cAssetAmount,
            cRatio,
            msg.sender,
            msg.sender,
            false
        );
    }

    /// @notice Open a short position, it will sell the nAsset immediately after mint.
    /// @notice 1.mint nAsset
    /// @notice 2.sell nAsset(swap to usdc)
    /// @notice 3.lock usdc by ShortLock contract
    /// @notice 4.mint sLP token and stake sLP to ShortStaking contract to earn reward
    /// @dev The C-Ratio users provided cannot less than the min C-Ratio in system.
    /// @param assetToken nAsset token address
    /// @param cAssetToken collateral token address
    /// @param cAssetAmount collateral amount
    /// @param cRatio collateral ratio
    /// @param swapAmountMin The minimum expected value during swap.
    /// @param swapDeadline When selling n assets, the deadline for the execution of this transaction
    function openShortPosition(
        IAssetToken assetToken,
        IERC20Extented cAssetToken,
        uint256 cAssetAmount,
        uint16 cRatio,
        uint256 swapAmountMin,
        uint256 swapDeadline
    ) external {
        uint256 positionId;
        uint256 mintAmount;
        (positionId, mintAmount) = _openPosition(
            assetToken,
            cAssetToken,
            cAssetAmount,
            cRatio,
            msg.sender,
            address(this),
            true
        );

        if (assetToken.allowance(address(this), swapRouter) < mintAmount) {
            assetToken.approve(swapRouter, MAX_UINT256);
        }

        uint256 amountOut;
        if (swapToToken == address(1)) {
            amountOut = Swappable.swapExactTokensForETH(
                swapRouter,
                weth,
                mintAmount,
                swapAmountMin,
                address(assetToken),
                address(this),
                swapDeadline
            );
            amountOut = min(amountOut, address(this).balance);
        } else {
            amountOut = Swappable.swapExactTokensForTokens(
                swapRouter,
                mintAmount,
                swapAmountMin,
                address(assetToken),
                swapToToken,
                address(this),
                swapDeadline
            );
            amountOut = min(
                amountOut,
                IERC20(swapToToken).balanceOf(address(this))
            );
        }

        if (swapToToken == address(1)) {
            lock.lock{value: amountOut}(
                positionId,
                msg.sender,
                swapToToken,
                amountOut
            );
        } else {
            lock.lock(positionId, msg.sender, swapToToken, amountOut);
        }

        staking.deposit(
            asset.asset(address(assetToken)).poolId,
            mintAmount,
            msg.sender
        );
    }

    function _openPosition(
        IAssetToken assetToken,
        IERC20Extented cAssetToken,
        uint256 cAssetAmount,
        uint16 cRatio,
        address spender,
        address receiver,
        bool isShort
    ) private returns (uint256 positionId, uint256 mintAmount) {
        // AssetConfig memory assetConfig = asset.asset(address(assetToken));
        require(
            asset.asset(address(assetToken)).assigned &&
                (!asset.asset(address(assetToken)).delisted),
            "Asset invalid"
        );

        if (asset.asset(address(assetToken)).isInPreIPO) {
            require(
                asset.asset(address(assetToken)).ipoParams.mintEnd >
                    block.timestamp
            );
            require(
                asset.isCollateralInPreIPO(address(cAssetToken)),
                "wrong collateral in PreIPO"
            );
        }

        // CAssetConfig memory cAssetConfig = asset.cAsset(address(cAssetToken));
        require(
            asset.cAsset(address(cAssetToken)).assigned,
            "wrong collateral"
        );
        //cRatio >= min_cRatio * multiplier
        require(
            asset.asset(address(assetToken)).minCRatio *
                asset.cAsset(address(cAssetToken)).multiplier <=
                cRatio,
            "wrong C-Ratio"
        );

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(
            asset.asset(address(assetToken)).token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(
            asset.cAsset(address(cAssetToken)).token,
            true
        );

        // calculate mint amount.
        // uint collateralPriceInAsset = (collateralPrice / (10 ** collateralPriceDecimals)) / (assetPrice / (10 ** assetPriceDecimals));
        // uint mintAmount = (cAssetAmount / (10 ** cAssetToken.decimals())) * collateralPriceInAsset / (cRatio / 1000);
        // mintAmount = mintAmount * (10 ** assetToken.decimals());
        // To avoid calculation deviation caused by accuracy problems, the above three lines can be converted into the following two lines
        // uint mintAmount = cAssetAmount * collateralPrice * (10 ** assetPriceDecimals) * cRatio * (10 ** assetToken.decimals())
        //     / 1000 / (10 ** cAssetToken.decimals()) / (10 ** collateralPriceDecimals) / assetPrice;
        // To avoid stack depth issues, the above two lines can be converted to the following two lines
        uint256 a = cAssetAmount *
            v.collateralPrice *
            (10**v.assetPriceDecimals) *
            1000 *
            (10**assetToken.decimals());
        mintAmount =
            a /
            cRatio /
            (10**cAssetToken.decimals()) /
            (10**v.collateralPriceDecimals) /
            v.assetPrice;
        require(mintAmount > 0, "wrong mint amount");

        // transfer token
        cAssetToken.safeTransferFrom(spender, address(this), cAssetAmount);

        //create position
        positionId = positions.openPosition(
            spender,
            cAssetToken,
            cAssetAmount,
            assetToken,
            mintAmount,
            isShort
        );

        //mint token
        asset.asset(address(assetToken)).token.mint(receiver, mintAmount);
    }

    /// @notice Deposit collateral and increase C-Ratio
    /// @dev must approve first
    /// @param positionId position id
    /// @param cAssetAmount collateral amount
    function deposit(uint256 positionId, uint256 cAssetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "no such a position");
        require(position.owner == msg.sender, "not owner");
        require(cAssetAmount > 0, "wrong cAmount");
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );
        require(cAssetConfig.assigned, "wrong collateral");

        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        require(assetConfig.assigned, "wrong asset");

        require(!assetConfig.delisted, "Asset delisted");

        // transfer token
        position.cAssetToken.safeTransferFrom(
            msg.sender,
            address(this),
            cAssetAmount
        );

        // Increase collateral amount
        position.cAssetAmount += cAssetAmount;

        positions.updatePosition(position);

        emit Deposit(positionId, cAssetAmount);
    }

    /// @notice Withdraw collateral from a position
    /// @dev C-Ratio cannot less than min C-Ratio after withdraw
    /// @param positionId position id
    /// @param cAssetAmount collateral amount
    function withdraw(uint256 positionId, uint256 cAssetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "no such a position");
        require(position.owner == msg.sender, "not owner.");
        require(cAssetAmount > 0, "wrong amount");
        require(position.cAssetAmount >= cAssetAmount, "withdraw too much");

        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        // get price
        uint256 assetPrice;
        uint8 assetPriceDecimals;
        (assetPrice, assetPriceDecimals) = _getPrice(assetConfig.token, false);
        uint256 collateralPrice;
        uint8 collateralPriceDecimals;
        (collateralPrice, collateralPriceDecimals) = _getPrice(
            cAssetConfig.token,
            true
        );

        // ignore multiplier for delisted assets
        uint16 multiplier = (
            assetConfig.delisted ? 1 : cAssetConfig.multiplier
        );

        uint256 remainingAmount = position.cAssetAmount - cAssetAmount;

        // Check minimum collateral ratio is satisfied
        // uint assetPriceInCollateral = (assetPrice / (10 ** assetPriceDecimals)) / (collateralPrice / (10 ** collateralPriceDecimals));
        // uint assetValueInCollateral = position.assetAmount / position.assetToken.decimals() * assetPriceInCollateral * position.cAssetToken.decimals();
        uint256 assetValueInCollateral = (position.assetAmount *
            assetPrice *
            (10**collateralPriceDecimals) *
            (10**position.cAssetToken.decimals())) /
            (10**assetPriceDecimals) /
            collateralPrice /
            (10**position.assetToken.decimals());
        uint256 expectedAmount = (assetValueInCollateral *
            assetConfig.minCRatio *
            multiplier) / 1000;
        require(expectedAmount <= remainingAmount, "unsatisfied c-ratio");

        if (remainingAmount == 0 && position.assetAmount == 0) {
            positions.removePosition(positionId);
            // if it is a short position, release locked funds
            if (position.isShort) {
                lock.release(positionId);
            }
        } else {
            position.cAssetAmount = remainingAmount;
            positions.updatePosition(position);
        }

        // // charge a fee.
        // uint feeAmount = cAssetAmount * feeRate / 1000;
        // uint amountAfterFee = cAssetAmount - feeAmount;
        // protocolFee[address(position.cAssetToken)] += feeAmount;

        position.cAssetToken.safeTransfer(msg.sender, cAssetAmount);

        emit Withdraw(positionId, cAssetAmount);
    }

    /// @notice Mint more nAsset from an exist position.
    /// @dev C-Ratio cannot less than min C-Ratio after mint
    /// @param positionId position ID
    /// @param assetAmount nAsset amount
    /// @param swapAmountMin Min amount you wanna received when sold to a swap if this position is a short position.
    /// @param swapDeadline Deadline time when sold to swap.
    function mint(
        uint256 positionId,
        uint256 assetAmount,
        uint256 swapAmountMin,
        uint256 swapDeadline
    ) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "no such a position");

        uint256 mintAmount = assetAmount;
        if (!position.isShort) {
            _mint(position, assetAmount, msg.sender);
            return;
        }

        _mint(position, assetAmount, address(this));

        uint256 amountOut;
        if (swapToToken == address(1)) {
            amountOut = Swappable.swapExactTokensForETH(
                swapRouter,
                weth,
                mintAmount,
                swapAmountMin,
                address(position.assetToken),
                address(this),
                swapDeadline
            );
            amountOut = min(amountOut, address(this).balance);
        } else {
            amountOut = Swappable.swapExactTokensForTokens(
                swapRouter,
                mintAmount,
                swapAmountMin,
                address(position.assetToken),
                swapToToken,
                address(this),
                swapDeadline
            );
            uint256 bal = IERC20(swapToToken).balanceOf(address(this));
            amountOut = min(amountOut, bal);
        }

        if (swapToToken == address(1)) {
            lock.lock{value: amountOut}(
                positionId,
                msg.sender,
                swapToToken,
                amountOut
            );
        } else {
            lock.lock(positionId, msg.sender, swapToToken, amountOut);
        }

        staking.deposit(
            asset.asset(address(position.assetToken)).poolId,
            mintAmount,
            msg.sender
        );
    }

    function _mint(
        Position memory position,
        uint256 assetAmount,
        address receiver
    ) private {
        require(position.owner == msg.sender, "not owner");
        require(assetAmount > 0, "wrong amount");

        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        require(assetConfig.assigned, "wrong asset");

        require(!assetConfig.delisted, "asset delisted");

        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );
        require(cAssetConfig.assigned, "wrong collateral");

        if (assetConfig.isInPreIPO) {
            require(assetConfig.ipoParams.mintEnd > block.timestamp);
        }

        // get price
        uint256 assetPrice;
        uint8 assetPriceDecimals;
        (assetPrice, assetPriceDecimals) = _getPrice(assetConfig.token, false);
        uint256 collateralPrice;
        uint8 collateralPriceDecimals;
        (collateralPrice, collateralPriceDecimals) = _getPrice(
            cAssetConfig.token,
            true
        );

        uint16 multiplier = cAssetConfig.multiplier;
        // Compute new asset amount
        uint256 mintedAmount = position.assetAmount + assetAmount;

        // Check minimum collateral ratio is satisfied
        // uint assetPriceInCollateral = (assetPrice / (10 ** assetPriceDecimals)) / (collateralPrice / (10 ** collateralPriceDecimals));
        // uint assetValueInCollateral = mintedAmount / position.assetToken.decimals() * assetPriceInCollateral * position.cAssetToken.decimals();
        uint256 assetValueInCollateral = (mintedAmount *
            assetPrice *
            (10**collateralPriceDecimals) *
            (10**position.cAssetToken.decimals())) /
            (10**assetPriceDecimals) /
            collateralPrice /
            (10**position.assetToken.decimals());
        uint256 expectedAmount = (assetValueInCollateral *
            assetConfig.minCRatio *
            multiplier) / 1000;
        require(expectedAmount <= position.cAssetAmount, "unsatisfied amount");

        position.assetAmount = mintedAmount;
        positions.updatePosition(position);

        position.assetToken.mint(receiver, assetAmount);

        emit MintAsset(position.id, assetAmount);
    }

    /// @notice Burn nAsset and increase C-Ratio
    /// @dev The position will be closed if all of the nAsset has been burned.
    /// @param positionId position id
    /// @param assetAmount nAsset amount to be burned
    function burn(uint256 positionId, uint256 assetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "no such a position");
        require(
            (assetAmount > 0) && (assetAmount <= position.assetAmount),
            "Wrong burn amount"
        );

        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        require(assetConfig.assigned, "wrong asset");

        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        if (assetConfig.isInPreIPO) {
            require(assetConfig.ipoParams.mintEnd > block.timestamp);
        }

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        // uint collateralPrice;
        // uint8 collateralPriceDecimals;
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(
            cAssetConfig.token,
            true
        );

        bool closePosition = false;
        // uint assetPrice;
        // uint8 assetPriceDecimals;
        uint256 cAssetAmount;
        uint256 protocolFee_;

        if (assetConfig.delisted) {
            v.assetPrice = assetConfig.endPrice;
            v.assetPriceDecimals = assetConfig.endPriceDecimals;
            // uint assetPriceInCollateral = (assetPrice / (10 ** assetPriceDecimals)) / (collateralPrice / (10 ** collateralPriceDecimals));
            // uint conversionRate = position.cAssetAmount / position.assetAmount;
            // uint amount1 = assetAmount / (10 ** assetConfig.token.decimals()) * assetPriceInCollateral * (10 ** cAssetConfig.token.decimals());
            // uint amount2 = assetAmount * conversionRate;

            uint256 a = assetAmount *
                (10**cAssetConfig.token.decimals()) *
                v.assetPrice *
                (10**v.collateralPriceDecimals);
            uint256 amount1 = a /
                (10**v.assetPriceDecimals) /
                v.collateralPrice /
                (10**assetConfig.token.decimals());
            uint256 amount2 = (assetAmount * position.cAssetAmount) /
                position.assetAmount;
            cAssetAmount = min(amount1, amount2);

            position.assetAmount -= assetAmount;
            position.cAssetAmount -= cAssetAmount;

            // due to rounding, include 1
            if (position.cAssetAmount <= 1 && position.assetAmount == 0) {
                closePosition = true;
                positions.removePosition(positionId);
            } else {
                positions.updatePosition(position);
            }

            protocolFee_ = (cAssetAmount * feeRate) / 1000;
            protocolFee[address(position.cAssetToken)] += protocolFee_;
            cAssetAmount = cAssetAmount - protocolFee_;

            position.cAssetToken.safeTransfer(msg.sender, cAssetAmount);
            position.assetToken.burnFrom(msg.sender, assetAmount);
        } else {
            require(msg.sender == position.owner, "not owner");

            (v.assetPrice, v.assetPriceDecimals) = _getPrice(
                assetConfig.token,
                false
            );
            cAssetAmount =
                (assetAmount *
                    (10**cAssetConfig.token.decimals()) *
                    v.assetPrice *
                    (10**v.collateralPriceDecimals)) /
                (10**v.assetPriceDecimals) /
                v.collateralPrice /
                (10**assetConfig.token.decimals());
            protocolFee_ = (cAssetAmount * feeRate) / 1000;
            protocolFee[address(position.cAssetToken)] += protocolFee_;

            position.assetAmount -= assetAmount;
            position.cAssetAmount -= protocolFee_;

            if (position.assetAmount == 0) {
                closePosition = true;
                positions.removePosition(positionId);
                position.cAssetToken.safeTransfer(
                    msg.sender,
                    position.cAssetAmount
                );
            } else {
                positions.updatePosition(position);
            }

            position.assetToken.burnFrom(msg.sender, assetAmount);

            emit Burn(positionId, assetAmount);
        }

        if (position.isShort) {
            staking.withdraw(assetConfig.poolId, assetAmount, msg.sender);
            if (closePosition) {
                lock.release(positionId);
            }
        }
    }

    /// @notice The position can be liquidited if the C-Ratio is less than the min C-Ratio.
    /// @notice During the liquidating, system will sell the collateral at a discounted price.
    /// @notice Everyone can buy it.
    /// @param positionId position id
    /// @param assetAmount nAsset amount
    function auction(uint256 positionId, uint256 assetAmount) public {
        Position memory position = positions.getPosition(positionId);
        require(position.assigned, "no such a position");
        require(
            (assetAmount > 0) && assetAmount <= position.assetAmount,
            "wrong amount"
        );

        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        require(!assetConfig.delisted, "wrong asset");

        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(
            assetConfig.token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(
            cAssetConfig.token,
            true
        );

        require(_checkPositionInAuction(position, v), "safe position");

        uint256 maxAssetAmount = _amountInAuction(
            assetConfig,
            cAssetConfig,
            position,
            v
        );

        VarsInAuction memory va = VarsInAuction(0, 0, 0, 0, 0, 0);
        va.liquidatedAssetAmount = min(assetAmount, maxAssetAmount);
        va.returnedCollateralAmount = _cAmountInAuction(
            assetConfig,
            cAssetConfig,
            v,
            va.liquidatedAssetAmount
        );

        va.leftAssetAmount = position.assetAmount - va.liquidatedAssetAmount;
        va.leftCAssetAmount =
            position.cAssetAmount -
            va.returnedCollateralAmount;

        bool closedPosition = false;

        if (va.leftCAssetAmount == 0) {
            closedPosition = true;
            positions.removePosition(positionId);
        } else if (va.leftAssetAmount == 0) {
            closedPosition = true;
            positions.removePosition(positionId);
            // refunds left collaterals to position owner
            position.cAssetToken.safeTransfer(
                position.owner,
                va.leftCAssetAmount
            );
        } else {
            position.cAssetAmount = va.leftCAssetAmount;
            position.assetAmount = va.leftAssetAmount;
            positions.updatePosition(position);
        }

        position.assetToken.burnFrom(msg.sender, va.liquidatedAssetAmount);

        {
            uint256 aDecimalDivisor = 10**assetConfig.token.decimals();
            uint256 cDecimalDivisor = 10**cAssetConfig.token.decimals();
            uint256 aPriceDecimalDivisor = 10**v.assetPriceDecimals;
            uint256 cPriceDecimalDivisor = 10**v.collateralPriceDecimals;

            // uint assetPriceInCollateral = (v.assetPrice / aPriceDecimalDivisor) / (v.collateralPrice / cPriceDecimalDivisor);
            // uint protocolFee_ = liquidatedAssetAmount * assetPriceInCollateral * feeRate / 1000;
            va.protocolFee_ =
                (va.liquidatedAssetAmount *
                    v.assetPrice *
                    feeRate *
                    cPriceDecimalDivisor *
                    cDecimalDivisor) /
                aDecimalDivisor /
                aPriceDecimalDivisor /
                v.collateralPrice /
                1000;
            protocolFee[address(position.cAssetToken)] += va.protocolFee_;
        }

        va.returnedCollateralAmount =
            va.returnedCollateralAmount -
            va.protocolFee_;
        position.cAssetToken.safeTransfer(
            msg.sender,
            va.returnedCollateralAmount
        );

        emit Auction(positionId, va.liquidatedAssetAmount);

        if (position.isShort) {
            staking.withdraw(
                assetConfig.poolId,
                va.liquidatedAssetAmount,
                msg.sender
            );
            if (closedPosition) {
                lock.release(positionId);
            }
        }
    }

    function claimFee(address cAssetToken, uint256 amount) external {
        require(msg.sender == feeTo, "only feeTo");
        require(amount <= protocolFee[cAssetToken], "wrong amount");
        protocolFee[cAssetToken] -= amount;
        IERC20(cAssetToken).safeTransfer(msg.sender, amount);
    }

    /// @notice View function, can shows the max nAsset amount and collateral amount in an auction.
    /// @param positionId Index of a position.
    /// @return 1.max nAsset amount(can be burned)
    /// @return 2.max collateral amount(in auction)
    function amountInAuction(uint256 positionId)
        external
        view
        returns (uint256, uint256)
    {
        Position memory position = positions.getPosition(positionId);
        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        if ((!position.assigned) || assetConfig.delisted) {
            return (0, 0);
        }

        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(
            assetConfig.token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(
            cAssetConfig.token,
            true
        );

        if (_checkPositionInAuction(position, v) == false) {
            return (0, 0);
        }

        uint256 maxAssetAmount = _amountInAuction(
            assetConfig,
            cAssetConfig,
            position,
            v
        );

        uint256 returnedCAssetAmount = _cAmountInAuction(
            assetConfig,
            cAssetConfig,
            v,
            maxAssetAmount
        );

        return (maxAssetAmount, returnedCAssetAmount);
    }

    function _amountInAuction(
        AssetConfig memory assetConfig,
        CAssetConfig memory cAssetConfig,
        Position memory position,
        VarsInFuncs memory v
    ) private view returns (uint256 maxAssetAmount) {
        uint256 aDecimalDivisor = 10**assetConfig.token.decimals();
        uint256 cDecimalDivisor = 10**cAssetConfig.token.decimals();
        uint256 aPriceDecimalDivisor = 10**v.assetPriceDecimals;
        uint256 cPriceDecimalDivisor = 10**v.collateralPriceDecimals;

        // uint collateralInUsd = (position.cAssetAmount / cDecimalDivisor) * (v.collateralPrice / cPriceDecimalDivisor);
        // uint collateralInUsd = position.cAssetAmount * v.collateralPrice / (cDecimalDivisor * cPriceDecimalDivisor);
        // uint assetInUsd = (position.assetAmount / aDecimalDivisor) * (v.assetPrice / aPriceDecimalDivisor);
        // uint assetInUsd = position.assetAmount * v.assetPrice / (aDecimalDivisor * aPriceDecimalDivisor);
        // uint curRatio = collateralInUsd / assetInUsd * 100000;

        uint256 curRatio = (position.cAssetAmount *
            v.collateralPrice *
            aDecimalDivisor *
            aPriceDecimalDivisor *
            100000) /
            cDecimalDivisor /
            cPriceDecimalDivisor /
            position.assetAmount /
            v.assetPrice;

        uint256 discountRatio = (1000 * 100000) / assetConfig.auctionDiscount;

        // console.log("~~~ curRatio: %d", curRatio);
        // console.log("~~~ discountRatio: %d", discountRatio);
        if (curRatio > discountRatio) {
            // Aa' = ((Aa * Pa * R'') - (Ac * Pc)) / (Pa * R'' - (Pa / D))
            // a = (Aa * Pa * R'')
            // b = (Ac * Pc)
            // c = Pa * R''
            // d = Pa / D
            // d = Pa / (aD / 1000)
            // d = Pa * 1000 / aD
            // Aa' = (a - b) / (c - d)
            // Aa' = ((a - b) * 10000) / ((c - d) * 10000)
            uint256 a = (position.assetAmount *
                v.assetPrice *
                assetConfig.targetRatio *
                10000) /
                1000 /
                aPriceDecimalDivisor /
                aDecimalDivisor;
            uint256 b = (position.cAssetAmount * 10000 * v.collateralPrice) /
                cPriceDecimalDivisor /
                cDecimalDivisor;
            uint256 c = (v.assetPrice * assetConfig.targetRatio * 10000) /
                1000 /
                cPriceDecimalDivisor;
            uint256 d = (v.assetPrice * 1000 * 10000) /
                aPriceDecimalDivisor /
                assetConfig.auctionDiscount;
            maxAssetAmount = ((a - b) * aDecimalDivisor) / (c - d);
        } else {
            maxAssetAmount =
                (position.cAssetAmount *
                    aPriceDecimalDivisor *
                    v.collateralPrice *
                    assetConfig.auctionDiscount) /
                (v.assetPrice * cPriceDecimalDivisor * 1000);
        }
    }

    function _cAmountInAuction(
        AssetConfig memory assetConfig,
        CAssetConfig memory cAssetConfig,
        VarsInFuncs memory v,
        uint256 assetAmount
    ) private view returns (uint256 returnedCAssetAmount) {
        uint256 aDecimalDivisor = 10**assetConfig.token.decimals();
        uint256 cDecimalDivisor = 10**cAssetConfig.token.decimals();

        // uint assetPriceInCollateral = (v.assetPrice / (10 ** v.assetPriceDecimals)) / (v.collateralPrice / (10 ** v.collateralPriceDecimals));
        // uint discountedPrice = assetPriceInCollateral / (assetConfig.auctionDiscount / 1000);
        // uint discountedValue = (assetAmount / aDecimalDivisor) * discountedPrice * cDecimalDivisor;
        // uint discountedPrice = v.assetPrice * (10 ** v.collateralPriceDecimals) * 1000 / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.auctionDiscount;
        // uint discountedValue = assetAmount * v.assetPrice * cDecimalDivisor * (10 ** v.collateralPriceDecimals) * 1000 / (10 ** v.assetPriceDecimals) / v.collateralPrice / assetConfig.auctionDiscount / aDecimalDivisor;
        uint256 c = assetAmount *
            v.assetPrice *
            (10**v.collateralPriceDecimals) *
            cDecimalDivisor *
            1000;
        returnedCAssetAmount =
            c /
            (10**v.assetPriceDecimals) /
            v.collateralPrice /
            assetConfig.auctionDiscount /
            aDecimalDivisor;
    }

    /// @notice Query whether a certain position is in liquidation status
    /// @param positionId position id
    /// @return bool - is in liquidation status
    function isInAuction(uint256 positionId) external view returns (bool) {
        VarsInFuncs memory v = VarsInFuncs(0, 0, 0, 0);
        Position memory position = positions.getPosition(positionId);
        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );

        if (!position.assigned) {
            return false;
        }

        (v.assetPrice, v.assetPriceDecimals) = _getPrice(
            assetConfig.token,
            false
        );
        (v.collateralPrice, v.collateralPriceDecimals) = _getPrice(
            cAssetConfig.token,
            true
        );

        return _checkPositionInAuction(position, v);
    }

    function _getPrice(IERC20Extented token, bool isCollateral)
        private
        view
        returns (uint256, uint8)
    {
        IChainlinkAggregator oracle;
        if (isCollateral) {
            require(asset.cAsset(address(token)).assigned, "wrong collateral");
            if (address(asset.cAsset(address(token)).oracle) == address(0x0)) {
                // Stablecoin
                return (uint256(100000000), uint8(8));
            }
            if (
                asset.asset(address(token)).assigned &&
                asset.asset(address(token)).delisted
            ) {
                // It is collateral and nAssets, and it has been delisted
                return (
                    asset.asset(address(token)).endPrice,
                    asset.asset(address(token)).endPriceDecimals
                );
            }
            oracle = asset.cAsset(address(token)).oracle;
        } else {
            require(asset.asset(address(token)).assigned, "wrong asset");
            if (asset.asset(address(token)).delisted) {
                // delisted nAsset
                return (
                    asset.asset(address(token)).endPrice,
                    asset.asset(address(token)).endPriceDecimals
                );
            }
            oracle = asset.asset(address(token)).oracle;
        }

        (, int256 price, uint256 startedAt, , ) = oracle.latestRoundData();

        require(
            (block.timestamp - startedAt) < oracleMaxDelay,
            "Price expired."
        );
        require(price >= 0, "Price is incorrect.");

        uint8 decimals = oracle.decimals();

        return (uint256(price), decimals);
    }

    function _checkPositionInAuction(
        Position memory position,
        VarsInFuncs memory v
    ) private view returns (bool) {
        CAssetConfig memory cAssetConfig = asset.cAsset(
            address(position.cAssetToken)
        );
        AssetConfig memory assetConfig = asset.asset(
            address(position.assetToken)
        );
        // uint assetPriceInCollateral = (v.assetPrice / (10 ** v.assetPriceDecimals)) / (v.collateralPrice / (10 ** v.collateralPriceDecimals));
        // uint assetValueInCollateral = position.assetAmount / position.assetToken.decimals() * assetPriceInCollateral * position.cAssetToken.decimals();
        uint256 assetValueInCollateral = (position.assetAmount *
            v.assetPrice *
            (10**v.collateralPriceDecimals) *
            (10**position.cAssetToken.decimals())) /
            (10**v.assetPriceDecimals) /
            v.collateralPrice /
            (10**position.assetToken.decimals());

        uint256 expectedAmount = ((assetValueInCollateral *
            assetConfig.minCRatio) / 1000) * cAssetConfig.multiplier;

        return (expectedAmount >= position.cAssetAmount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}