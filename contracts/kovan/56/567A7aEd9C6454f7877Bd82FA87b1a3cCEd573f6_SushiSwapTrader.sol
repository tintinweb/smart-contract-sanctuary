// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/ISushiSwapTrader.sol";
import "../interfaces/ISushiSwapFactory.sol";
import "../interfaces/ISushiSwapRouter.sol";
import "../interfaces/ISushiSwapPair.sol";
import "../interfaces/IIntegrationMap.sol";

/// @notice Integrates 0x Nodes to SushiSwap
contract SushiSwapTrader is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    ISushiSwapTrader
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint24 private constant SLIPPAGE_DENOMINATOR = 1_000_000;
    uint24 private slippageNumerator;
    address private factoryAddress;
    address private swapRouterAddress;

    event ExecutedSwapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 amountOut
    );

    event FailedSwapExactInput(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin
    );

    event SushiSwapSlippageNumeratorUpdated(uint24 slippageNumerator);

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ The address of the module map contract
    /// @param factoryAddress_ The address of the SushiSwap factory contract
    /// @param swapRouterAddress_ The address of the SushiSwap swap router contract
    /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
    function initialize(address[] memory controllers_, address moduleMap_, address factoryAddress_, address swapRouterAddress_, uint24 slippageNumerator_) public initializer {
        require(slippageNumerator <= SLIPPAGE_DENOMINATOR, 
            "SushiSwapTrader::initialize: Slippage Numerator must be less than or equal to slippage denominator");
        __Controlled_init(controllers_, moduleMap_);
        __ModuleMapConsumer_init(moduleMap_);
        factoryAddress = factoryAddress_;
        swapRouterAddress = swapRouterAddress_;
        slippageNumerator = slippageNumerator_;
    }

    /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
    function updateSlippageNumerator(uint24 slippageNumerator_) external override onlyManager {
        require(slippageNumerator_ != slippageNumerator, 
            "SushiSwapTrader::setSlippageNumerator: Slippage numerator must be set to a new value");
        require(slippageNumerator <= SLIPPAGE_DENOMINATOR, 
            "SushiSwapTrader::setSlippageNumerator: Slippage Numerator must be less than or equal to slippage denominator");

        slippageNumerator = slippageNumerator_;

        emit SushiSwapSlippageNumeratorUpdated(slippageNumerator_);
    }

    /// @notice Swaps all WETH held in this contract for BIOS and sends to the kernel
    /// @return Bool indicating whether the trade succeeded
    function biosBuyBack() external override onlyController returns (bool) {
        IIntegrationMap integrationMap = IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap));
        address wethAddress = integrationMap.getWethTokenAddress();
        address biosAddress = integrationMap.getBiosTokenAddress();
        uint256 wethAmountIn = IERC20MetadataUpgradeable(wethAddress).balanceOf(address(this));

        uint256 biosAmountOutMin = getAmountOutMinimum(wethAddress, biosAddress, wethAmountIn);

        return swapExactInput(wethAddress, integrationMap.getBiosTokenAddress(), 
            moduleMap.getModuleAddress(Modules.Kernel), wethAmountIn, biosAmountOutMin);
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address of the token out recipient
    /// @param amountIn The exact amount of the input to swap
    /// @param amountOutMin The minimum amount of tokenOut to receive from the swap
    /// @return bool Indicates whether the swap succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) public override onlyController returns (bool) {
        require(IERC20MetadataUpgradeable(tokenIn).balanceOf(address(this)) >= amountIn, 
            "SushiSwapTrader::swapExactInput: Balance is less than trade amount");

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        uint256 deadline = block.timestamp;

        if(IERC20MetadataUpgradeable(tokenIn).allowance(address(this), swapRouterAddress) == 0) {
            IERC20MetadataUpgradeable(tokenIn).safeApprove(swapRouterAddress, type(uint256).max);
        }


        uint256 tokenOutBalanceBefore = IERC20MetadataUpgradeable(tokenOut).balanceOf(recipient);

        try ISushiSwapRouter(swapRouterAddress).swapExactTokensForTokens(amountIn, amountOutMin, path, recipient, deadline) {
            emit ExecutedSwapExactInput(
                tokenIn, 
                tokenOut, 
                amountIn, 
                amountOutMin, 
                IERC20MetadataUpgradeable(tokenOut).balanceOf(recipient) - tokenOutBalanceBefore
            );
            return true;
        } catch {
            emit FailedSwapExactInput(
                tokenIn, 
                tokenOut, 
                amountIn, 
                amountOutMin
            );
            return false;
        }
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOutMinimum The minimum amount of tokenOut to receive, factoring in allowable slippage
    function getAmountOutMinimum(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 amountOutMinimum) {
        amountOutMinimum = getAmountOut(tokenIn, tokenOut, amountIn) * (SLIPPAGE_DENOMINATOR - slippageNumerator) / SLIPPAGE_DENOMINATOR;
    }

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) public view returns (uint256 amountOut) {
        require(amountIn > 0, "SushiSwapTrader::getAmountOut: amountIn must be greater than zero");
        (uint256 reserveIn, uint256 reserveOut) = getReserves(tokenIn, tokenOut);
        require(reserveIn > 0 && reserveOut > 0, "SushiSwapTrader::getAmountOut: No liquidity in pool reserves");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * (reserveOut);
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return reserveA The reserve balance of tokenA in the pool
    /// @return reserveB The reserve balance of tokenB in the pool
    function getReserves(address tokenA, address tokenB) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0,) = getTokensSorted(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1,) = ISushiSwapPair(getPairFor(tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of sorted token0
    /// @return token1 The address of sorted token1
    function getTokensSorted(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "SushiSwapTrader::sortToken: Identical token addresses");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'SushiSwapTrader::sortToken: Zero address');
    }


    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return pair The address of the SushiSwap pool contract
    function getPairFor(address tokenA, address tokenB) internal view returns (address pair) {
        pair = ISushiSwapFactory(factoryAddress).getPair(tokenA, tokenB);
    }

    /// @return SushiSwap Factory address
    function getFactoryAddress() public view returns (address) {
        return factoryAddress;
    }

    /// @return The slippage numerator
    function getSlippageNumerator() public view returns (uint24) {
        return slippageNumerator;
    }

    /// @return The slippage denominator
    function getSlippageDenominator() public pure returns (uint24) {
        return SLIPPAGE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IKernel.sol";

abstract contract Controlled is 
    Initializable,
    ModuleMapConsumer
{
    address[] public controllers;

    function __Controlled_init(address[] memory controllers_, address moduleMap_) public initializer {
        controllers = controllers_;
        __ModuleMapConsumer_init(moduleMap_);
    }

    function addController(address controller) external onlyOwner {
        bool controllerAdded;
        for(uint256 i; i < controllers.length; i++) {
            if(controller == controllers[i]) {
                controllerAdded = true;
            }
        }
        require(!controllerAdded, "Controlled::addController: Address is already a controller");
        controllers.push(controller);
    }

    modifier onlyOwner() {
        require(IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isOwner(msg.sender), "Controlled::onlyOwner: Caller is not owner");
        _;
    }

    modifier onlyManager() {
        require(IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isManager(msg.sender), "Controlled::onlyManager: Caller is not manager");
        _;
    }

    modifier onlyController() {
        bool senderIsController;
        for(uint256 i; i < controllers.length; i++) {
            if(msg.sender == controllers[i]) {
                senderIsController = true;
                break;
            }
        }
        require(senderIsController, "Controlled::onlyController: Caller is not controller");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModuleMap.sol";

abstract contract ModuleMapConsumer is Initializable {
    IModuleMap public moduleMap;

    function __ModuleMapConsumer_init(address moduleMap_) internal initializer {
        moduleMap = IModuleMap(moduleMap_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISushiSwapTrader {
    /// @param slippageNumerator_ The number divided by the slippage denominator to get the slippage percentage
    function updateSlippageNumerator(uint24 slippageNumerator_) external;

    /// @notice Swaps all WETH held in this contract for BIOS and sends to the kernel
    /// @return Bool indicating whether the trade succeeded
    function biosBuyBack() external returns (bool);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address of the token out recipient
    /// @param amountIn The exact amount of the input to swap
    /// @param amountOutMin The minimum amount of tokenOut to receive from the swap
    /// @return bool Indicates whether the swap succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn,
        uint256 amountOutMin
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISushiSwapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISushiSwapRouter {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISushiSwapPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IIntegrationMap {
    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    /// @param weightsByTokenId The weights of each token for the added integration
    function addIntegration(address contractAddress, string memory name, uint256[] memory weightsByTokenId) external;

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    /// @param weightsByIntegrationId The weights of each integration for the added token
    function addToken(
        address tokenAddress, 
        bool acceptingDeposits, 
        bool acceptingWithdrawals, 
        uint256 biosRewardWeight, 
        uint256 reserveRatioNumerator, 
        uint256[] memory weightsByIntegrationId
    ) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenDeposits(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenDeposits(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function enableTokenWithdrawals(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    function disableTokenWithdrawals(address tokenAddress) external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @param rewardWeight The updated token BIOS reward weight
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight) external;

    /// @param integrationAddress The address of the integration contract
    /// @param tokenAddress the address of the token ERC20 contract
    /// @param updatedWeight The updated token integration weight
    function updateTokenIntegrationWeight(address integrationAddress, address tokenAddress, uint256 updatedWeight) external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(address tokenAddress, uint256 reserveRatioNumerator) external;

    /// @param integrationId The ID of the integration
    /// @return The address of the integration contract
    function getIntegrationAddress(uint256 integrationId) external view returns (address);

    /// @param integrationAddress The address of the integration contract
    /// @return The name of the of the protocol being integrated to
    function getIntegrationName(address integrationAddress) external view returns (string memory);

    /// @return The address of the WETH token
    function getWethTokenAddress() external view returns (address);

    /// @return The address of the BIOS token
    function getBiosTokenAddress() external view returns (address);

    /// @param tokenId The ID of the token
    /// @return The address of the token ERC20 contract
    function getTokenAddress(uint256 tokenId) external view returns (address);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The index of the token in the tokens array
    function getTokenId(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The token BIOS reward weight
    function getTokenBiosRewardWeight(address tokenAddress) external view returns (uint256);

    /// @return rewardWeightSum reward weight of depositable tokens
    function getBiosRewardWeightSum() external view returns (uint256 rewardWeightSum);

    /// @param integrationAddress The address of the integration contract
    /// @param tokenAddress the address of the token ERC20 contract
    /// @return The weight of the specified integration & token combination
    function getTokenIntegrationWeight(address integrationAddress, address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenWeightSum The sum of the specified token weights
    function getTokenIntegrationWeightSum(address tokenAddress) external view returns (uint256 tokenWeightSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether depositing this token is currently enabled
    function getTokenAcceptingDeposits(address tokenAddress) external view returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether withdrawing this token is currently enabled
    function getTokenAcceptingWithdrawals(address tokenAddress) external view returns (bool);

    // @param tokenAddress The address of the token ERC20 contract
    // @return bool indicating whether the token has been added
    function getIsTokenAdded(address tokenAddress) external view returns (bool);

    // @param integrationAddress The address of the integration contract
    // @return bool indicating whether the integration has been added
    function getIsIntegrationAdded(address tokenAddress) external view returns (bool);

    /// @notice get the length of supported tokens
    /// @return The quantity of tokens added
    function getTokenAddressesLength() external view returns (uint256);

    /// @notice get the length of supported integrations
    /// @return The quantity of integrations added
    function getIntegrationAddressesLength() external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The value that gets divided by the reserve ratio denominator
    function getTokenReserveRatioNumerator(address tokenAddress) external view returns (uint256);

    /// @return The token reserve ratio denominator
    function getReserveRatioDenominator() external view returns (uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IKernel {
    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) external view returns (bool);

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Modules {
    Kernel, // 0
    UserPositions, // 1
    YieldManager, // 2
    IntegrationMap, // 3
    BiosRewards, // 4
    EtherRewards, // 5
    SushiSwapTrader, // 6
    UniswapTrader // 7
}

interface IModuleMap {
    function getModuleAddress(Modules key) external view returns (address);
}

