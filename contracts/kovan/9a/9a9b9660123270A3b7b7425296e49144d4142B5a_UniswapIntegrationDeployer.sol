// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../core/Controlled.sol";
import "../core/ModuleMapConsumer.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IUniswapTrader.sol";
import "../interfaces/IUniswapFactory.sol";
import "../interfaces/IUniswapPositionManager.sol";
import "../interfaces/IUniswapSwapRouter.sol";
import "../interfaces/IUniswapIntegration.sol";
import "../interfaces/IUniswapPool.sol";
import "../interfaces/IUniswapIntegrationDeployer.sol";
import "../interfaces/IUniswapIntegration.sol";
import "../libraries/LiquidityAmounts.sol";
import "../libraries/TickMath.sol";

/// @notice Integrates 0x Nodes to Uniswap v3
/// @notice tokenA/tokenB naming implies tokens are unordered
/// @notice token0/token1 naming implies tokens are ordered
contract UniswapIntegrationDeployer is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IUniswapIntegrationDeployer
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    address private factoryAddress;
    address private positionManagerAddress;
    IUniswapIntegration private uniswapIntegration;

    /// @param controllers_ Array of controller addresses
    /// @param moduleMap_ The address of the module map contract
    /// @param factoryAddress_ The address of the Uniswap v3 factory
    /// @param positionManagerAddress_ The address of the Uniswap v3 position manager
    /// @param uniswapIntegrationAddress_ The address of the Uniswap Integration contract
    function initialize(
        address[] memory controllers_, 
        address moduleMap_, 
        address factoryAddress_, 
        address positionManagerAddress_,
        address uniswapIntegrationAddress_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        __ModuleMapConsumer_init(moduleMap_);
        factoryAddress = factoryAddress_;
        positionManagerAddress = positionManagerAddress_;
        uniswapIntegration = IUniswapIntegration(uniswapIntegrationAddress_);
    }

    /// @param token The address of the token to approve transfers for
    function tokenApprovals(address token) external override onlyController {
        if(IERC20MetadataUpgradeable(token).allowance(address(this), address(uniswapIntegration)) == 0) {
            IERC20MetadataUpgradeable(token).safeApprove(address(uniswapIntegration), type(uint256).max);
        }

        if(IERC20MetadataUpgradeable(token).allowance(address(this), positionManagerAddress) == 0) {
            IERC20MetadataUpgradeable(token).safeApprove(positionManagerAddress, type(uint256).max);
        }
    }

    /// @param tokenDesiredAmounts Array of the desired amounts of each token
    function swapExcessTokensForBaseStablecoin(uint256[] memory tokenDesiredAmounts) public override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap));
        IUniswapTrader uniswapTrader = IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader));
        address baseStablecoinAddress = uniswapIntegration.getBaseStablecoinAddress();

        for(uint256 tokenId; tokenId < tokenDesiredAmounts.length; tokenId++) {
            address tokenAddress = integrationMap.getTokenAddress(tokenId);

            if(tokenAddress != baseStablecoinAddress) {
                IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(tokenAddress);
                uint256 tokenBalance = token.balanceOf(address(this));

                if(tokenBalance > tokenDesiredAmounts[tokenId]) {
                    IERC20MetadataUpgradeable(tokenAddress).safeTransfer(address(uniswapTrader), tokenBalance - tokenDesiredAmounts[tokenId]);
                    uniswapTrader.swapExactInput(tokenAddress, baseStablecoinAddress, address(this), tokenBalance - tokenDesiredAmounts[tokenId]);
                }
            }
        }   
    }

    /// @param tokenDesiredAmounts Array of the desired amounts of each token
    function swapExcessBaseStablecoinForTokens(uint256[] memory tokenDesiredAmounts) external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap));
        IUniswapTrader uniswapTrader = IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader));
        address baseStablecoinAddress = uniswapIntegration.getBaseStablecoinAddress();

        for(uint256 tokenId; tokenId < tokenDesiredAmounts.length; tokenId++) {
            if(integrationMap.getTokenAddress(tokenId) != baseStablecoinAddress) {
                
                address tokenAddress = integrationMap.getTokenAddress(tokenId);
                IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(tokenAddress);
                uint256 tokenBalance = token.balanceOf(address(this));
                
                if(tokenBalance < tokenDesiredAmounts[tokenId]) {
                    uint256 baseStablecoinAmount = uniswapIntegration.getTokenValueInBaseStablecoin(tokenAddress, tokenDesiredAmounts[tokenId] - tokenBalance);
                    if(baseStablecoinAmount > IERC20MetadataUpgradeable(baseStablecoinAddress).balanceOf(address(this))) {
                        baseStablecoinAmount = IERC20MetadataUpgradeable(baseStablecoinAddress).balanceOf(address(this));
                    }
                    
                    IERC20MetadataUpgradeable(baseStablecoinAddress).safeTransfer(address(uniswapTrader), baseStablecoinAmount);
                    uniswapTrader.swapExactInput(baseStablecoinAddress, tokenAddress, address(this), baseStablecoinAmount);
                }
            }
        }
    }
    
    /// @param token0 The address of token0 of the liquidity position
    /// @param token1 The address of token1 of the liquidity position
    /// @param fee The liquidity position pool fee
    /// @param tickLower The liquidity position lower tick
    /// @param tickUpper The liquidity position upper tick
    /// @param amount0Desired The desired amount of token0 to mint into the position
    /// @param amount1Desired The desired amount of token1 to mint into the position
    /// @return success Bool indicating whether the mint succeeded
    /// @return liquidityPositionId The token ID of the minted liquidity position
    function mintLiquidityPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external override onlyController returns (
        bool success, 
        uint256 liquidityPositionId
    ) {
        if(amount0Desired > IERC20MetadataUpgradeable(token0).balanceOf(address(this))) {
            amount0Desired = IERC20MetadataUpgradeable(token0).balanceOf(address(this));
        }

        if(amount1Desired > IERC20MetadataUpgradeable(token1).balanceOf(address(this))) {
            amount1Desired = IERC20MetadataUpgradeable(token1).balanceOf(address(this));
        }   

        IUniswapPositionManager.MintParams memory mintParams;

        mintParams.token0 = token0;
        mintParams.token1 = token1;
        mintParams.fee = fee;
        mintParams.tickLower = tickLower;
        mintParams.tickUpper = tickUpper;
        mintParams.amount0Desired = amount0Desired;
        mintParams.amount1Desired = amount1Desired;
        mintParams.amount0Min = 0;
        mintParams.amount1Min = 0;
        mintParams.recipient = address(this);
        mintParams.deadline = block.timestamp;

        try IUniswapPositionManager(positionManagerAddress).mint(mintParams) 
            returns (uint256 returnedLiquidityPositionId, uint128, uint256 , uint256) {
            success = true;
            liquidityPositionId = returnedLiquidityPositionId;
        } catch {
            success = false;
            liquidityPositionId = 0;
        }
    }

    /// @param liquidityPositionId The token ID of the liquidity position
    /// @param token0 The address of token0 of the liquidity position
    /// @param token1 The address of token1 of the liquidity position
    /// @param amount0Desired The desired amount of token0 to add to the liquidity position
    /// @param amount1Desired The desired amount of token1 to add to the liquidity position
    /// @return success Bool indicating whether the increase succeeded
    function increaseLiquidityPosition(
        uint256 liquidityPositionId,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired) external override onlyController returns (bool success) {

        if(amount0Desired > IERC20MetadataUpgradeable(token0).balanceOf(address(this))) {
            amount0Desired = IERC20MetadataUpgradeable(token0).balanceOf(address(this));
        }
        if(amount1Desired > IERC20MetadataUpgradeable(token1).balanceOf(address(this))) {
            amount1Desired = IERC20MetadataUpgradeable(token1).balanceOf(address(this));
        }   

        IUniswapPositionManager.IncreaseLiquidityParams memory increaseLiquidityParams;

        increaseLiquidityParams.tokenId = liquidityPositionId;
        increaseLiquidityParams.amount0Desired = amount0Desired;
        increaseLiquidityParams.amount1Desired = amount1Desired;
        increaseLiquidityParams.amount0Min = 0;
        increaseLiquidityParams.amount1Min = 0;
        increaseLiquidityParams.deadline = block.timestamp;

        try IUniswapPositionManager(positionManagerAddress).increaseLiquidity(increaseLiquidityParams) {
            success = true;
        } catch {
            success = false;
        }
    }  

    /// @notice This function closes liquidity positions until the specified amount of the 
    /// @notice token has been obtained, or until all liquidity positions have been closed
    /// @param tokenAddress The address of the token being withdrawn
    /// @param amount The amount of the token being withdrawn needed
    function closePositionsForWithdrawal(address tokenAddress, uint256 amount) public override onlyController {
        IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(tokenAddress);
        bool doneClosingPositions;
        uint256 liquidityPositionIndex;
        uint256 withdrawalAmountInBaseStablecoinValue = uniswapIntegration.getTokenValueInBaseStablecoin(tokenAddress, amount);

        // Close liquidity positions until enough of token has been withdrawn
        while(!doneClosingPositions) {
            if(uniswapIntegration.getPositionBaseStablecoinValue(liquidityPositionIndex) 
                + uniswapIntegration.getTokenValueInBaseStablecoin(tokenAddress, token.balanceOf(address(this))) 
                <= withdrawalAmountInBaseStablecoinValue)
            {
                // Need to fully close the position
                decreaseLiquidityPosition(liquidityPositionIndex, uniswapIntegration.getPositionBaseStablecoinValue(liquidityPositionIndex));
                swapReservesForWithdrawalToken(tokenAddress);
                if(token.balanceOf(address(this)) >= amount) {
                    doneClosingPositions = true;
                }
                
            } else {
                // Partially close position for 2% more of value needed to account for slippage
                decreaseLiquidityPosition(liquidityPositionIndex, 102 * (withdrawalAmountInBaseStablecoinValue 
                    - uniswapIntegration.getTokenValueInBaseStablecoin(tokenAddress, token.balanceOf(address(this)))) / 100);
                swapReservesForWithdrawalToken(tokenAddress);

                // Check if the new token balance is enough for withdrawal
                if(token.balanceOf(address(this)) >= amount) {
                    // Token balance is enough for withdrawal, done closing positions
                    doneClosingPositions = true;
                } else {
                    // Partial position closure was not enough, fully close the position
                    decreaseLiquidityPosition(liquidityPositionIndex, uniswapIntegration.getPositionBaseStablecoinValue(liquidityPositionIndex));
                    swapReservesForWithdrawalToken(tokenAddress);
                    if(token.balanceOf(address(this)) >= amount) {
                        doneClosingPositions = true;
                    }
                }               
            }

            // Check if the final liquidity position has been reached
            if(liquidityPositionIndex == uniswapIntegration.getLiquidityPositionsCount() - 1) {
                doneClosingPositions = true;
            }

            // Increment to the next liquidity position
            liquidityPositionIndex++;
        }
    }

    /// @param tokenAddress The address of the token being withdrawn
    function swapReservesForWithdrawalToken(address tokenAddress) public override onlyController {
        uint256 tokenCount = IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap)).getTokenAddressesLength();
        uint256[] memory tokenDesiredAmounts = new uint256[](tokenCount);
        swapExcessTokensForBaseStablecoin(tokenDesiredAmounts);
        IERC20MetadataUpgradeable baseStablecoin = IERC20MetadataUpgradeable(uniswapIntegration.getBaseStablecoinAddress());
        if(tokenAddress != address(baseStablecoin)) {
            baseStablecoin.safeTransfer(moduleMap.getModuleAddress(Modules.UniswapTrader), 
                baseStablecoin.balanceOf(address(this)));
            IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader)).swapExactInput(address(baseStablecoin), 
                tokenAddress, address(this), baseStablecoin.balanceOf(moduleMap.getModuleAddress(Modules.UniswapTrader)));
        }
    }

    function decreaseLiquidityPosition(
        uint256 liquidityPositionIndex, 
        uint256 baseStablecoinValue
    ) public override onlyController returns (
        bool success
    ) {
        (,,,,,,uint256 liquidityPositionId,) = uniswapIntegration.getLiquidityPosition(liquidityPositionIndex);
        (,,,,,,,uint128 currentLiquidity,,,uint128 tokensOwed0Before, uint128 tokensOwed1Before) = 
            IUniswapPositionManager(positionManagerAddress).positions(liquidityPositionId);

        if(uniswapIntegration.getPositionBaseStablecoinValue(liquidityPositionIndex) > 0) {
            uint128 reduceLiquidityAmount = uint128((baseStablecoinValue) 
                * currentLiquidity / uniswapIntegration.getPositionBaseStablecoinValue(liquidityPositionIndex));
            
            if(reduceLiquidityAmount > currentLiquidity) {
                reduceLiquidityAmount = currentLiquidity;
            }

            IUniswapPositionManager.DecreaseLiquidityParams memory decreaseLiquidityParams;

            decreaseLiquidityParams.tokenId = liquidityPositionId;
            decreaseLiquidityParams.liquidity = reduceLiquidityAmount;
            decreaseLiquidityParams.amount0Min = 0;
            decreaseLiquidityParams.amount1Min = 0;
            decreaseLiquidityParams.deadline = block.timestamp; 

            try IUniswapPositionManager(positionManagerAddress).decreaseLiquidity(decreaseLiquidityParams) {
                success = true;
            } catch {
                success = false;
            }

            (,,,,,,,,,,uint128 tokensOwed0After, uint128 tokensOwed1After) = IUniswapPositionManager(positionManagerAddress).positions(liquidityPositionId);

            // Collect tokens from decreased position while leaving previous yield for future collection
            collectTokensFromPosition(liquidityPositionId, tokensOwed0After - tokensOwed0Before, tokensOwed1After - tokensOwed1Before);
        } else {
            success = false;
        }
    }

    // Harvests all available yield and transfers to the YieldManager
    function harvestYield() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap));
        uint256 tokenCount = integrationMap.getTokenAddressesLength();
        address baseStablecoinAddress = uniswapIntegration.getBaseStablecoinAddress();

        uint256[] memory tokensHarvestedYield = new uint256[](tokenCount);
        
        uint256 baseStablecoinBalanceBefore = IERC20MetadataUpgradeable(baseStablecoinAddress).balanceOf(address(this));

        // Collect all available yield for liquidity positions
        for(uint256 liquidityPositionIndex; liquidityPositionIndex < uniswapIntegration.getLiquidityPositionsCount(); liquidityPositionIndex++) { 
            (address token0, address token1,,,,,uint256 liquidityPositionId,) = uniswapIntegration.getLiquidityPosition(liquidityPositionIndex);            

            uint256 token0Id = integrationMap.getTokenId(token0);
            uint256 token1Id = integrationMap.getTokenId(token1);

            (bool success, uint256 amount0, uint256 amount1) = collectTokensFromPosition(liquidityPositionId, 2**127, 2**127);

            if(success) {
                tokensHarvestedYield[token0Id] += amount0;
                tokensHarvestedYield[token1Id] += amount1;
            }
        }

        uint256 totalBalanceBaseStablecoinValue;
        uint256[] memory tokenBalancesBaseStablecoinValue = new uint256[](tokenCount);
        
        // Swap harvested yield for base stablecoin
        for(uint256 tokenId; tokenId < tokenCount; tokenId++) {
            if(tokensHarvestedYield[tokenId] > 0) {
                address tokenAddress = integrationMap.getTokenAddress(tokenId);

                // Check that the token is the baseStablecoin, or a pool has been setup between the token and the base stablecoin
                if(tokenAddress == baseStablecoinAddress || IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader))
                    .getTokenPairPoolsLength(tokenAddress, baseStablecoinAddress) > 0) {
                
                    uint256 tokenBalanceBaseStablecoinValue = uniswapIntegration
                        .getTokenValueInBaseStablecoin(tokenAddress, uniswapIntegration.getBalance(tokenAddress));
                    tokenBalancesBaseStablecoinValue[tokenId] = tokenBalanceBaseStablecoinValue;
                    totalBalanceBaseStablecoinValue += tokenBalanceBaseStablecoinValue;

                    if(tokenAddress != baseStablecoinAddress) {
                        IERC20MetadataUpgradeable(tokenAddress)
                            .safeTransfer(moduleMap.getModuleAddress(Modules.UniswapTrader), tokensHarvestedYield[tokenId]);
                        IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader))
                            .swapExactInput(tokenAddress, baseStablecoinAddress, address(this), tokensHarvestedYield[tokenId]);
                    }
                }
            }
        }

        uint256 baseStablecoinHarvested = IERC20MetadataUpgradeable(baseStablecoinAddress).balanceOf(address(this)) - baseStablecoinBalanceBefore;

        // Swap base stablecoin for yield tokens and transfer to YieldManager in proportion 
        // to token deposit values into this integration
        if(baseStablecoinHarvested > 0 && totalBalanceBaseStablecoinValue > 0) {
            for(uint256 tokenId; tokenId < tokenCount; tokenId++) {
                address tokenAddress = integrationMap.getTokenAddress(tokenId);
                uint256 baseStablecoinAmount = baseStablecoinHarvested * 
                    tokenBalancesBaseStablecoinValue[tokenId] / totalBalanceBaseStablecoinValue;
            
                if(baseStablecoinAmount > 0) {
                    if(tokenAddress != baseStablecoinAddress) {
                    IERC20MetadataUpgradeable(baseStablecoinAddress)
                        .safeTransfer(moduleMap.getModuleAddress(Modules.UniswapTrader), baseStablecoinAmount);

                    IUniswapTrader(moduleMap.getModuleAddress(Modules.UniswapTrader)).swapExactInput(baseStablecoinAddress, tokenAddress, 
                        moduleMap.getModuleAddress(Modules.YieldManager), baseStablecoinAmount);
                    } else {
                        IERC20MetadataUpgradeable(baseStablecoinAddress)
                            .safeTransfer(moduleMap.getModuleAddress(Modules.YieldManager), baseStablecoinAmount);
                    }
                }
            }
        }
    }

    function collectTokensFromPosition(
        uint256 liquidityPositionId, 
        uint128 amount0Max, 
        uint128 amount1Max
    ) public override onlyController returns (
        bool success,
        uint256 amount0Collected, 
        uint256 amount1Collected
    ) {

        IUniswapPositionManager.CollectParams memory collectParams;

        collectParams.tokenId = liquidityPositionId;
        collectParams.recipient = address(this);
        collectParams.amount0Max = amount0Max;
        collectParams.amount1Max = amount1Max;

        try IUniswapPositionManager(positionManagerAddress).collect(collectParams) 
        returns (uint256 returnedAmount0, uint256 returnedAmount1) {
            success = true;
            amount0Collected = returnedAmount0;
            amount1Collected = returnedAmount1;
        } catch {
            success = false;
            amount0Collected = 0;
            amount1Collected = 0;
        }
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
pragma solidity ^0.8.4;

interface IUniswapTrader {    
    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param fee The Uniswap pool fee
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    function addPool(address tokenA, address tokenB, uint24 fee, uint24 slippageNumerator) external;

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(address tokenA, address tokenB, uint256 poolIndex, uint24 slippageNumerator) external;

    /// @notice Changes which Uniswap pool to use as the default pool 
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(address tokenA, address tokenB, uint256 primaryPoolIndex) external;
 
    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountIn The exact amount of the input to swap
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactInput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountIn
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param recipient The address to receive the tokens
    /// @param amountOut The exact amount of the output token to receive
    /// @return tradeSuccess Indicates whether the trade succeeded
    function swapExactOutput(
        address tokenIn,
        address tokenOut,
        address recipient,
        uint256 amountOut
    ) external returns (bool tradeSuccess);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountOut The exact amount of token being swapped for
    /// @return amountInMaximum The maximum amount of tokenIn to spend, factoring in allowable slippage
    function getAmountInMaximum(address tokenIn, address tokenOut, uint256 amountOut) external view returns (uint256 amountInMaximum);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256 amountOut);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB) external pure returns (address token0, address token1);

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB) external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(address tokenA, address tokenB, uint256 poolId) external view returns (uint24 feeNumerator);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapFactory {
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IIntegration.sol";

interface IUniswapIntegration is IIntegration {
    /// @param uniswapIntegrationDeployerAddress The address of the Uniswap Integration Deployer contract
    function setUniswapIntegrationDeployer(address uniswapIntegrationDeployerAddress) external;

    /// @param baseStablecoinAddress_ The base stablecoin token that the Uniswap Integration uses for swaps
    function setBaseStablecoin(address baseStablecoinAddress_) external;

    /// @param liquidityPositionIndex The index of the liquidity position
    /// @return token0 The address of token0 of the liquidity position
    /// @return token1 The address of token1 of the liquidity position
    /// @return feeNumerator The fee of the liquidity position
    /// @return tickLower The lower tick bound of the liquidity position
    /// @return tickUpper The upper tick bound of the liquidity position
    /// @return minted Boolean indicating whether the position has been minted yet
    /// @return id The token ID of the liquidity position
    /// @return weight The relative weight of the liquidity position
    function getLiquidityPosition(uint256 liquidityPositionIndex) external view returns (        
        address token0,
        address token1,
        uint24 feeNumerator,
        int24 tickLower,
        int24 tickUpper,
        bool minted,
        uint256 id,
        uint256 weight
    );

    /// @return The address of the base stablecoin
    function getBaseStablecoinAddress() external view returns (address);

    /// @param tokenAddress The address of the token
    /// @param amount The amount of the token
    /// @return tokenValueInBaseStablecoin The value of the amount of the token converted to the base stablecoin
    function getTokenValueInBaseStablecoin(address tokenAddress, uint256 amount) external view returns (uint256 tokenValueInBaseStablecoin);

    /// @return The number of configured liquidity positions
    function getLiquidityPositionsCount() external view returns (uint256);

    /// @param liquidityPositionIndex The index of the liquidity position
    /// @return positionBaseStablecoinValue The value of the liquidity position converted to the base stablecoin
    function getPositionBaseStablecoinValue(uint256 liquidityPositionIndex) external view returns (uint256 positionBaseStablecoinValue);
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapPool {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUniswapIntegrationDeployer {
    function tokenApprovals(address token) external;

    function closePositionsForWithdrawal(address tokenAddress, uint256 amount) external;

    function swapExcessTokensForBaseStablecoin(uint256[] memory tokenDesiredAmounts) external;

    function swapExcessBaseStablecoinForTokens(uint256[] memory tokenDesiredAmounts) external;

    function swapReservesForWithdrawalToken(address tokenAddress) external;

    function harvestYield() external;

    function mintLiquidityPosition(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external returns (
        bool success, 
        uint256 liquidityPositionId
    );

    function increaseLiquidityPosition(
        uint256 liquidityPositionId,
        address token0,
        address token1,
        uint256 amount0Desired,
        uint256 amount1Desired) 
    external returns (
        bool success
    );

    function decreaseLiquidityPosition(uint256 liquidityPositionIndex, uint256 baseStablecoinValue) external returns (bool success);

    function collectTokensFromPosition(
        uint256 liquidityPositionId, 
        uint128 amount0Max, 
        uint128 amount1Max
    ) external returns (
        bool success,
        uint256 amount0Collected, 
        uint256 amount1Collected
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

import './FullMath.sol';
import './FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IIntegration {
    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount) external;

    /// @param tokenAddress The address of the withdrawal token
    /// @param amount The amount of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount) external;

    /// @dev Deploys all tokens held in the integration contract to the integrated protocol
    function deploy() external;

    /// @dev Harvests token yield from the Aave lending pool
    function harvestYield() external;

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param tokenAddress The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.6;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}