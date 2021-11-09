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

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ModuleMapConsumer.sol";
import "../interfaces/IKernel.sol";

abstract contract Controlled is Initializable, ModuleMapConsumer {
    // controller address => is a controller
    mapping(address => bool) internal _controllers;
    address[] public controllers;

    function __Controlled_init(
        address[] memory controllers_,
        address moduleMap_
    ) public initializer {
        for (uint256 i; i < controllers_.length; i++) {
            _controllers[controllers_[i]] = true;
        }
        controllers = controllers_;
        __ModuleMapConsumer_init(moduleMap_);
    }

    function addController(address controller) external onlyOwner {
        _controllers[controller] = true;
        bool added;
        for (uint256 i; i < controllers.length; i++) {
            if (controller == controllers[i]) {
                added = true;
            }
        }
        if (!added) {
            controllers.push(controller);
        }
    }

    modifier onlyOwner() {
        require(
            IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isOwner(
                msg.sender
            ),
            "Controlled::onlyOwner: Caller is not owner"
        );
        _;
    }

    modifier onlyManager() {
        require(
            IKernel(moduleMap.getModuleAddress(Modules.Kernel)).isManager(
                msg.sender
            ),
            "Controlled::onlyManager: Caller is not manager"
        );
        _;
    }

    modifier onlyController() {
        require(
            _controllers[msg.sender],
            "Controlled::onlyController: Caller is not controller"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IModuleMap.sol";

abstract contract ModuleMapConsumer is Initializable {
    IModuleMap public moduleMap;

    function __ModuleMapConsumer_init(address moduleMap_) internal initializer {
        moduleMap = IModuleMap(moduleMap_);
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IAMMIntegration.sol";
import "../interfaces/IEtherRewards.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IUniswapTrader.sol";
import "../interfaces/ISushiSwapTrader.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IWeth9.sol";
import "../interfaces/IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";
import "hardhat/console.sol";

/// @title Yield Manager
/// @notice Manages yield deployments, harvesting, processing, and distribution
contract YieldManager is
    Initializable,
    ModuleMapConsumer,
    Controlled,
    IYieldManager
{
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

    uint256 private gasAccountTargetEthBalance;
    uint32 private biosBuyBackEthWeight;
    uint32 private treasuryEthWeight;
    uint32 private protocolFeeEthWeight;
    uint32 private rewardsEthWeight;
    uint256 private lastEthRewardsAmount;

    address payable private gasAccount;
    address payable private treasuryAccount;

    mapping(address => uint256) private processedWethByToken;

    receive() external payable {}

    /// @param controllers_ The addresses of the controlling contracts
    /// @param moduleMap_ Address of the Module Map
    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
    /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
    /// @param treasuryAccount_ The address of the system treasury account
    function initialize(
        address[] memory controllers_,
        address moduleMap_,
        uint256 gasAccountTargetEthBalance_,
        uint32 biosBuyBackEthWeight_,
        uint32 treasuryEthWeight_,
        uint32 protocolFeeEthWeight_,
        uint32 rewardsEthWeight_,
        address payable gasAccount_,
        address payable treasuryAccount_
    ) public initializer {
        __Controlled_init(controllers_, moduleMap_);
        gasAccountTargetEthBalance = gasAccountTargetEthBalance_;
        biosBuyBackEthWeight = biosBuyBackEthWeight_;
        treasuryEthWeight = treasuryEthWeight_;
        protocolFeeEthWeight = protocolFeeEthWeight_;
        rewardsEthWeight = rewardsEthWeight_;
        gasAccount = gasAccount_;
        treasuryAccount = treasuryAccount_;
    }

    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(
        uint256 gasAccountTargetEthBalance_
    ) external override onlyController {
        gasAccountTargetEthBalance = gasAccountTargetEthBalance_;
    }

    /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
    function updateEthDistributionWeights(
        uint32 biosBuyBackEthWeight_,
        uint32 treasuryEthWeight_,
        uint32 protocolFeeEthWeight_,
        uint32 rewardsEthWeight_
    ) external override onlyController {
        biosBuyBackEthWeight = biosBuyBackEthWeight_;
        treasuryEthWeight = treasuryEthWeight_;
        protocolFeeEthWeight = protocolFeeEthWeight_;
        rewardsEthWeight = rewardsEthWeight_;
    }

    /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
    function updateGasAccount(address payable gasAccount_)
        external
        override
        onlyController
    {
        gasAccount = gasAccount_;
    }

    /// @param treasuryAccount_ The address of the system treasury account
    function updateTreasuryAccount(address payable treasuryAccount_)
        external
        override
        onlyController
    {
        treasuryAccount = treasuryAccount_;
    }

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy(DeployRequest[] calldata deployments)
        external
        override
        onlyController
    {
        IStrategyMap strategyMap = IStrategyMap(
            moduleMap.getModuleAddress(Modules.StrategyMap)
        );

        for (uint256 i = 0; i < deployments.length; i++) {
            if (deployments[i].ammPoolID > 0) {
                require(deployments[i].tokens.length <= 2, "too many tokens");
            }

            for (uint256 j = 0; j < deployments[i].tokens.length; j++) {
                int256 deployAmount = strategyMap.getDeployAmount(
                    deployments[i].integration,
                    deployments[i].ammPoolID,
                    deployments[i].tokens[j]
                );

                uint256 reserveBalance = IERC20MetadataUpgradeable(
                    deployments[i].tokens[j]
                ).balanceOf(moduleMap.getModuleAddress(Modules.Kernel));
                if (deployAmount > 0 && reserveBalance < abs(deployAmount)) {
                    strategyMap.closePositionsForWithdrawal(
                        deployments[i].tokens[j],
                        0x1000000000000000000000000000000000000000000000000000000000000000
                    );
                    deployAmount = strategyMap.getDeployAmount(
                        deployments[i].integration,
                        deployments[i].ammPoolID,
                        deployments[i].tokens[j]
                    );
                }

                if (deployments[i].ammPoolID > 0) {
                    IAMMIntegration integration = IAMMIntegration(
                        deployments[i].integration
                    );

                    if (deployAmount > 0) {
                        uint256 balanceBefore = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);

                        IERC20MetadataUpgradeable(deployments[i].tokens[j])
                            .safeTransferFrom(
                                moduleMap.getModuleAddress(Modules.Kernel),
                                deployments[i].integration,
                                abs(deployAmount)
                            );
                        uint256 balanceAfter = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);
                        integration.deposit(
                            deployments[i].tokens[j],
                            balanceAfter - balanceBefore,
                            deployments[i].ammPoolID
                        );
                        integration.deploy(deployments[i].ammPoolID);
                    } else if (deployAmount < 0) {
                        integration.withdraw(
                            deployments[i].tokens[j],
                            abs(deployAmount),
                            deployments[i].ammPoolID
                        );
                    }
                } else {
                    IIntegration integration = IIntegration(
                        deployments[i].integration
                    );
                    if (deployAmount > 0) {
                        uint256 balanceBefore = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);
                        IERC20MetadataUpgradeable(deployments[i].tokens[j])
                            .safeTransferFrom(
                                moduleMap.getModuleAddress(Modules.Kernel),
                                deployments[i].integration,
                                abs(deployAmount)
                            );
                        uint256 balanceAfter = IERC20MetadataUpgradeable(
                            deployments[i].tokens[j]
                        ).balanceOf(deployments[i].integration);

                        integration.deposit(
                            deployments[i].tokens[j],
                            balanceAfter - balanceBefore
                        );
                        integration.deploy();
                    } else if (deployAmount < 0) {
                        integration.withdraw(
                            deployments[i].tokens[j],
                            abs(deployAmount)
                        );
                    }
                }
                strategyMap.decreaseDeployAmountChange(
                    deployments[i].integration,
                    deployments[i].ammPoolID,
                    deployments[i].tokens[j],
                    abs(deployAmount)
                );
            }
            strategyMap.clearClosablePositions(deployments[i].tokens);
        }
    }

    function abs(int256 val) internal pure returns (uint256) {
        return uint256(val >= 0 ? val : -val);
    }

    function _calculateReserveAmount(
        uint256 amount,
        uint256 numerator,
        uint256 denominator
    ) internal pure returns (uint256) {
        return (amount == 0 ? 1 : amount * numerator) / denominator;
    }

    /// @notice Harvests available yield from provided tokens and integration
    function harvestYield(
        address integrationAddress,
        address[] calldata tokenAddresses
    ) public override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        IERC20MetadataUpgradeable weth = IERC20MetadataUpgradeable(
            integrationMap.getWethTokenAddress()
        );

        uint256 wethBalanceBeforeHarvest = weth.balanceOf(address(this));

        IIntegration(integrationAddress).harvestYield();

        processedWethByToken[address(weth)] +=
            weth.balanceOf(address(this)) -
            wethBalanceBeforeHarvest;

        for (
            uint256 tokenIterator;
            tokenIterator < tokenAddresses.length;
            tokenIterator++
        ) {
            IERC20MetadataUpgradeable token = IERC20MetadataUpgradeable(
                tokenAddresses[tokenIterator]
            );

            if (token.balanceOf(address(this)) > 0) {
                token.safeTransfer(
                    moduleMap.getModuleAddress(Modules.Kernel),
                    _calculateReserveAmount(
                        token.balanceOf(address(this)),
                        integrationMap.getTokenReserveRatioNumerator(
                            address(token)
                        ),
                        integrationMap.getReserveRatioDenominator()
                    )
                );
                if (address(token) != address(weth)) {
                    uint256 wethBalanceBefore = weth.balanceOf(address(this));
                    // If token is not WETH, need to swap it for WETH
                    // Swap token harvested yield for WETH. If trade succeeds, update accounting. Otherwise, do not update accounting
                    token.safeTransfer(
                        moduleMap.getModuleAddress(Modules.UniswapTrader),
                        token.balanceOf(address(this))
                    );

                    IUniswapTrader(
                        moduleMap.getModuleAddress(Modules.UniswapTrader)
                    ).swapExactInput(
                            address(token),
                            address(weth),
                            address(this),
                            token.balanceOf(
                                moduleMap.getModuleAddress(
                                    Modules.UniswapTrader
                                )
                            )
                        );
                    // Update accounting
                    processedWethByToken[address(token)] +=
                        weth.balanceOf(address(this)) -
                        wethBalanceBefore;
                }
            }
        }
    }

    /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external override onlyController {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address wethAddress = IIntegrationMap(integrationMap)
            .getWethTokenAddress();

        // First fill up gas wallet with ETH
        ethToGasAccount();

        uint256 wethToDistribute = IERC20MetadataUpgradeable(wethAddress)
            .balanceOf(address(this));

        if (wethToDistribute > 0) {
            uint256 biosBuyBackWethAmount = (wethToDistribute *
                biosBuyBackEthWeight) / getEthWeightSum();
            uint256 treasuryWethAmount = (wethToDistribute *
                treasuryEthWeight) / getEthWeightSum();
            uint256 protocolFeeWethAmount = (wethToDistribute *
                protocolFeeEthWeight) / getEthWeightSum();
            uint256 rewardsWethAmount = wethToDistribute -
                biosBuyBackWethAmount -
                treasuryWethAmount -
                protocolFeeWethAmount;

            // Send WETH to SushiSwap trader for BIOS buy back
            IERC20MetadataUpgradeable(wethAddress).safeTransfer(
                moduleMap.getModuleAddress(Modules.SushiSwapTrader),
                biosBuyBackWethAmount
            );

            // Swap WETH for ETH and transfer to the treasury account
            IWeth9(wethAddress).withdraw(treasuryWethAmount);
            payable(treasuryAccount).transfer(treasuryWethAmount);

            // Send ETH to protocol fee accrual rewards (BIOS stakers)
            ethToProtocolFeeAccrual(protocolFeeWethAmount);

            // Send ETH to token rewards
            ethToRewards(rewardsWethAmount);
        }
    }

    /// @notice Distributes WETH to gas wallet
    function ethToGasAccount() private {
        address wethAddress = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getWethTokenAddress();
        uint256 wethBalance = IERC20MetadataUpgradeable(wethAddress).balanceOf(
            address(this)
        );

        if (wethBalance > 0) {
            uint256 gasAccountActualEthBalance = gasAccount.balance;
            if (gasAccountActualEthBalance < gasAccountTargetEthBalance) {
                // Need to send ETH to gas account
                uint256 ethAmountToGasAccount;
                if (
                    wethBalance <
                    gasAccountTargetEthBalance - gasAccountActualEthBalance
                ) {
                    // Send all of WETH to gas wallet
                    ethAmountToGasAccount = wethBalance;
                    IWeth9(wethAddress).withdraw(ethAmountToGasAccount);
                    gasAccount.transfer(ethAmountToGasAccount);
                } else {
                    // Send portion of WETH to gas wallet
                    ethAmountToGasAccount =
                        gasAccountTargetEthBalance -
                        gasAccountActualEthBalance;
                    IWeth9(wethAddress).withdraw(ethAmountToGasAccount);
                    gasAccount.transfer(ethAmountToGasAccount);
                }
            }
        }
    }

    /// @notice Uses any WETH held in the SushiSwap trader to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external override onlyController {
        if (
            IERC20MetadataUpgradeable(
                IIntegrationMap(
                    moduleMap.getModuleAddress(Modules.IntegrationMap)
                ).getWethTokenAddress()
            ).balanceOf(moduleMap.getModuleAddress(Modules.SushiSwapTrader)) > 0
        ) {
            // Use all ETH sent to the SushiSwap trader to buy BIOS
            ISushiSwapTrader(
                moduleMap.getModuleAddress(Modules.SushiSwapTrader)
            ).biosBuyBack();

            // Use all BIOS transferred to the Kernel to increase bios rewards
            IUserPositions(moduleMap.getModuleAddress(Modules.UserPositions))
                .increaseBiosRewards();
        }
    }

    /// @notice Distributes ETH to Rewards per token
    /// @param ethRewardsAmount The amount of ETH rewards to distribute
    function ethToRewards(uint256 ethRewardsAmount) private {
        uint256 processedWethByTokenSum = getProcessedWethSum();
        require(
            processedWethByTokenSum > 0,
            "YieldManager::ethToRewards: No processed WETH to distribute"
        );

        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address wethAddress = integrationMap.getWethTokenAddress();
        uint256 tokenCount = integrationMap.getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address tokenAddress = integrationMap.getTokenAddress(tokenId);

            if (processedWethByToken[tokenAddress] > 0) {
                IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                    .increaseEthRewards(
                        tokenAddress,
                        (ethRewardsAmount *
                            processedWethByToken[tokenAddress]) /
                            processedWethByTokenSum
                    );

                processedWethByToken[tokenAddress] = 0;
            }
        }

        lastEthRewardsAmount = ethRewardsAmount;

        IWeth9(wethAddress).withdraw(ethRewardsAmount);

        payable(moduleMap.getModuleAddress(Modules.Kernel)).transfer(
            ethRewardsAmount
        );
    }

    /// @notice Distributes ETH to protocol fee accrual (BIOS staker rewards)
    /// @param protocolFeeEthRewardsAmount Amount of ETH to distribute to protocol fee accrual
    function ethToProtocolFeeAccrual(uint256 protocolFeeEthRewardsAmount)
        private
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        address biosAddress = integrationMap.getBiosTokenAddress();
        address wethAddress = integrationMap.getWethTokenAddress();

        if (
            IStrategyMap(moduleMap.getModuleAddress(Modules.StrategyMap))
                .getTokenTotalBalance(biosAddress) > 0
        ) {
            // BIOS has been deposited, increase Ether rewards for BIOS depositors
            IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
                .increaseEthRewards(biosAddress, protocolFeeEthRewardsAmount);

            IWeth9(wethAddress).withdraw(protocolFeeEthRewardsAmount);

            payable(moduleMap.getModuleAddress(Modules.Kernel)).transfer(
                protocolFeeEthRewardsAmount
            );
        } else {
            // No BIOS has been deposited, send WETH back to Kernel as reserves
            IERC20MetadataUpgradeable(wethAddress).transfer(
                moduleMap.getModuleAddress(Modules.Kernel),
                protocolFeeEthRewardsAmount
            );
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of the token held in the Kernel as reserves
    function getReserveTokenBalance(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        require(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getIsTokenAdded(tokenAddress),
            "YieldManager::getReserveTokenBalance: Token not added"
        );
        return
            IERC20MetadataUpgradeable(tokenAddress).balanceOf(
                moduleMap.getModuleAddress(Modules.Kernel)
            );
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The desired amount of the token to hold in the Kernel as reserves
    function getDesiredReserveTokenBalance(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        require(
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getIsTokenAdded(tokenAddress),
            "YieldManager::getDesiredReserveTokenBalance: Token not added"
        );
        uint256 tokenReserveRatioNumerator = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getTokenReserveRatioNumerator(tokenAddress);
        uint256 tokenTotalBalance = IStrategyMap(
            moduleMap.getModuleAddress(Modules.StrategyMap)
        ).getTokenTotalBalance(tokenAddress);
        return
            (tokenTotalBalance * tokenReserveRatioNumerator) /
            IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
                .getReserveRatioDenominator();
    }

    /// @return ethWeightSum The sum of ETH distribution weights
    function getEthWeightSum()
        public
        view
        override
        returns (uint32 ethWeightSum)
    {
        ethWeightSum =
            biosBuyBackEthWeight +
            treasuryEthWeight +
            protocolFeeEthWeight +
            rewardsEthWeight;
    }

    /// @return processedWethSum The sum of yields processed into WETH
    function getProcessedWethSum()
        public
        view
        override
        returns (uint256 processedWethSum)
    {
        uint256 tokenCount = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        ).getTokenAddressesLength();

        for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
            address tokenAddress = IIntegrationMap(
                moduleMap.getModuleAddress(Modules.IntegrationMap)
            ).getTokenAddress(tokenId);
            processedWethSum += processedWethByToken[tokenAddress];
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of WETH received from token yield processing
    function getProcessedWethByToken(address tokenAddress)
        public
        view
        override
        returns (uint256)
    {
        return processedWethByToken[tokenAddress];
    }

    /// @return processedWethByTokenSum The sum of processed WETH
    function getProcessedWethByTokenSum(address[] calldata tokenAddresses)
        public
        view
        override
        returns (uint256 processedWethByTokenSum)
    {
        for (uint256 tokenId; tokenId < tokenAddresses.length; tokenId++) {
            processedWethByTokenSum += processedWethByToken[
                tokenAddresses[tokenId]
            ];
        }
    }

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
    function getTokenTotalIntegrationBalance(address tokenAddress)
        public
        view
        override
        returns (uint256 tokenTotalIntegrationBalance)
    {
        IIntegrationMap integrationMap = IIntegrationMap(
            moduleMap.getModuleAddress(Modules.IntegrationMap)
        );
        uint256 integrationCount = integrationMap
            .getIntegrationAddressesLength();

        for (
            uint256 integrationId;
            integrationId < integrationCount;
            integrationId++
        ) {
            tokenTotalIntegrationBalance += IIntegration(
                integrationMap.getIntegrationAddress(integrationId)
            ).getBalance(tokenAddress);
        }
    }

    /// @return The address of the gas account
    function getGasAccount() public view override returns (address) {
        return gasAccount;
    }

    /// @return The address of the treasury account
    function getTreasuryAccount() public view override returns (address) {
        return treasuryAccount;
    }

    /// @return The last amount of ETH distributed to rewards
    function getLastEthRewardsAmount() public view override returns (uint256) {
        return lastEthRewardsAmount;
    }

    /// @return The target ETH balance of the gas account
    function getGasAccountTargetEthBalance()
        public
        view
        override
        returns (uint256)
    {
        return gasAccountTargetEthBalance;
    }

    /// @return The BIOS buyback ETH weight
    /// @return The Treasury ETH weight
    /// @return The Protocol fee ETH weight
    /// @return The rewards ETH weight
    function getEthDistributionWeights()
        public
        view
        override
        returns (
            uint32,
            uint32,
            uint32,
            uint32
        )
    {
        return (
            biosBuyBackEthWeight,
            treasuryEthWeight,
            protocolFeeEthWeight,
            rewardsEthWeight
        );
    }

    function transferClosedPositionsValue(address token, uint256 amount)
        external
        override
        onlyController
    {
        IERC20MetadataUpgradeable(token).transfer(
            moduleMap.getModuleAddress(Modules.Kernel),
            amount
        );
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IAMMIntegration {
    /// @dev IMPORTANT: poolID starts at 1 for all amm integrations. A poolID of 0 is used to designate a non amm integration.
    /// For UniswapV2 and Sushiswap, retrieve the pool address by calling the Router.
    struct Pool {
        address tokenA;
        address tokenB;
        uint256 positionID; // Used for Uniswap V3
    }

    /// @param token The address of the deposited token
    /// @param amount The amount of token being deposited
    /// @param poolID  The id of the pool to deposit into
    function deposit(
        address token,
        uint256 amount,
        uint32 poolID
    ) external;

    /// @param token  the token to withdraw
    /// @param amount The amount of token in the pool to withdraw
    /// @param poolID  the pool to withdraw from
    function withdraw(
        address token,
        uint256 amount,
        uint32 poolID
    ) external;

    /// @dev Deploys all the tokens for the specified pools
    function deploy(uint32 poolID) external;

    /// @notice Returns the balance of a specific pool
    /// @param poolID  the id of the pool to return balances from
    function getPoolBalance(uint32 poolID)
        external
        view
        returns (uint256 tokenA, uint256 tokenB);

    /// @notice returns the details of an amm pool
    /// @dev This should throw if poolID is == 0
    /// @param poolID  the ID of the pool to retrieve details for
    function getPool(uint32 poolID) external view returns (Pool memory pool);

    /// @notice Adds an existing position to the integration for use in a strategy
    /// @dev Should be restricted to admin accounts
    /// @param tokenA  The first token in the position
    /// @param tokenB the second token in the position
    /// @param positionID  The position id if required (uniswap v3)
    function createPool(
        address tokenA,
        address tokenB,
        uint256 positionID
    ) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IEtherRewards {
    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    function updateUserRewards(address token, address user) external;

    /// @param token The address of the token ERC20 contract
    /// @param ethRewardsAmount The amount of Ether rewards to add
    function increaseEthRewards(address token, uint256 ethRewardsAmount)
        external;

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimEthRewards(address user)
        external
        returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserTokenEthRewards(address token, address user)
        external
        view
        returns (uint256 ethRewards);

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserEthRewards(address user)
        external
        view
        returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @return The amount of Ether rewards for the specified token
    function getTokenEthRewards(address token) external view returns (uint256);

    /// @return The total value of ETH claimed by users
    function getTotalClaimedEthRewards() external view returns (uint256);

    /// @return The total value of ETH claimed by a user
    function getTotalUserClaimedEthRewards(address user)
        external
        view
        returns (uint256);

    /// @return The total amount of Ether rewards
    function getEthRewards() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IIntegration {
    /// @param tokenAddress The address of the deposited token
    /// @param amount The amount of the token being deposited
    function deposit(address tokenAddress, uint256 amount) external;

    /// @param tokenAddress The address of the withdrawal token
    /// @param amount The amount of the token to withdraw
    function withdraw(address tokenAddress, uint256 amount) external;

    /// @dev Deploys all tokens held in the integration contract to the integrated protocol
    function deploy() external;

    /// @dev Harvests token yield from the integration
    function harvestYield() external;

    /// @dev This returns the total amount of the underlying token that
    /// @dev has been deposited to the integration contract
    /// @param tokenAddress The address of the deployed token
    /// @return The amount of the underlying token that can be withdrawn
    function getBalance(address tokenAddress) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IIntegrationMap {
    struct Integration {
        bool added;
        string name;
    }

    struct Token {
        uint256 id;
        bool added;
        bool acceptingDeposits;
        bool acceptingWithdrawals;
        uint256 biosRewardWeight;
        uint256 reserveRatioNumerator;
    }

    /// @param contractAddress The address of the integration contract
    /// @param name The name of the protocol being integrated to
    function addIntegration(address contractAddress, string memory name)
        external;

    /// @param tokenAddress The address of the ERC20 token contract
    /// @param acceptingDeposits Whether token deposits are enabled
    /// @param acceptingWithdrawals Whether token withdrawals are enabled
    /// @param biosRewardWeight Token weight for BIOS rewards
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function addToken(
        address tokenAddress,
        bool acceptingDeposits,
        bool acceptingWithdrawals,
        uint256 biosRewardWeight,
        uint256 reserveRatioNumerator
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
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight)
        external;

    /// @param tokenAddress the address of the token ERC20 contract
    /// @param reserveRatioNumerator Number that gets divided by reserve ratio denominator to get reserve ratio
    function updateTokenReserveRatioNumerator(
        address tokenAddress,
        uint256 reserveRatioNumerator
    ) external;

    /// @param integrationId The ID of the integration
    /// @return The address of the integration contract
    function getIntegrationAddress(uint256 integrationId)
        external
        view
        returns (address);

    /// @param integrationAddress The address of the integration contract
    /// @return The name of the of the protocol being integrated to
    function getIntegrationName(address integrationAddress)
        external
        view
        returns (string memory);

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
    function getTokenBiosRewardWeight(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return rewardWeightSum reward weight of depositable tokens
    function getBiosRewardWeightSum()
        external
        view
        returns (uint256 rewardWeightSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether depositing this token is currently enabled
    function getTokenAcceptingDeposits(address tokenAddress)
        external
        view
        returns (bool);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return bool indicating whether withdrawing this token is currently enabled
    function getTokenAcceptingWithdrawals(address tokenAddress)
        external
        view
        returns (bool);

    // @param tokenAddress The address of the token ERC20 contract
    // @return bool indicating whether the token has been added
    function getIsTokenAdded(address tokenAddress) external view returns (bool);

    // @param integrationAddress The address of the integration contract
    // @return bool indicating whether the integration has been added
    function getIsIntegrationAdded(address tokenAddress)
        external
        view
        returns (bool);

    /// @notice get the length of supported tokens
    /// @return The quantity of tokens added
    function getTokenAddressesLength() external view returns (uint256);

    /// @notice get the length of supported integrations
    /// @return The quantity of integrations added
    function getIntegrationAddressesLength() external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The value that gets divided by the reserve ratio denominator
    function getTokenReserveRatioNumerator(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return The token reserve ratio denominator
    function getReserveRatioDenominator() external view returns (uint32);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IKernel {
    /// @param account The address of the account to check if they are a manager
    /// @return Bool indicating whether the account is a manger
    function isManager(address account) external view returns (bool);

    /// @param account The address of the account to check if they are an owner
    /// @return Bool indicating whether the account is an owner
    function isOwner(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

enum Modules {
    Kernel, // 0
    UserPositions, // 1
    YieldManager, // 2
    IntegrationMap, // 3
    BiosRewards, // 4
    EtherRewards, // 5
    SushiSwapTrader, // 6
    UniswapTrader, // 7
    StrategyMap, // 8
    StrategyManager // 9
}

interface IModuleMap {
    function getModuleAddress(Modules key) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "../interfaces/IIntegration.sol";
import "./IUserPositions.sol";

interface IStrategyMap {
    // #### Structs
    struct Integration {
        address integration;
        uint32 ammPoolID;
    }
    struct Token {
        uint256 integrationPairIdx;
        address token;
        uint32 weight;
    }

    struct TokenDeploy {
        address integration;
        uint32 ammPoolID;
        address token;
        uint256 amount;
    }

    struct Strategy {
        string name;
        Integration[] integrations;
        Token[] tokens;
        mapping(address => bool) availableTokens;
    }

    struct StrategySummary {
        string name;
        Integration[] integrations;
        Token[] tokens;
    }

    struct StrategyBalance {
        uint256 strategyID;
        GeneralBalance[] tokens;
    }

    struct GeneralBalance {
        address token;
        uint256 balance;
    }

    struct ClosablePosition {
        address integration;
        uint32 ammPoolID;
        uint256 amount;
    }

    // #### Events
    // NewStrategy, UpdateName, UpdateStrategy, DeleteStrategy
    event NewStrategy(
        uint256 indexed id,
        Integration[] integrations,
        Token[] tokens,
        string name
    );
    event UpdateName(uint256 indexed id, string name);
    event UpdateStrategy(
        uint256 indexed id,
        Integration[] integrations,
        Token[] tokens
    );
    event DeleteStrategy(uint256 indexed id);

    // #### Functions
    /**
     @notice Adds a new strategy to the list of available strategies
     @param name  the name of the new strategy
     @param integrations  the integrations and weights that form the strategy
     */
    function addStrategy(
        string calldata name,
        Integration[] calldata integrations,
        Token[] calldata tokens
    ) external;

    /**
    @notice Updates the strategy name
    @param name  the new name
     */
    function updateName(uint256 id, string calldata name) external;

    /**
    @notice Updates a strategy's integrations and tokens
    @param id  the strategy to update
    @param integrations  the new integrations that will be used
    @param tokens  the tokens accepted for new entries
    */
    function updateStrategy(
        uint256 id,
        Integration[] calldata integrations,
        Token[] calldata tokens
    ) external;

    /**
    @notice Deletes a strategy
    @dev This can only be called successfully if the strategy being deleted doesn't have any assets invested in it.
    @dev To delete a strategy with funds deployed in it, first update the strategy so that the existing tokens are no longer available in the strategy, then delete the strategy. This will unwind the users positions, and they will be able to withdraw their funds.
    @param id  the strategy to delete
     */
    function deleteStrategy(uint256 id) external;

    /**
    @notice Increases the amount of a set of tokens in a strategy
    @param id  the strategy to deposit into
    @param tokens  the tokens to deposit
     */
    function increaseStrategy(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external;

    /**
    @notice Decreases the amount of a set of tokens invested in a strategy
    @param id  the strategy to withdraw assets from
    @param tokens  details of the tokens being deposited
     */
    function decreaseStrategy(
        uint256 id,
        IUserPositions.TokenMovement[] calldata tokens
    ) external;

    /**
    @notice Getter function to return the nested arrays as well as the name
    @param id  the strategy to return
     */
    function getStrategy(uint256 id)
        external
        view
        returns (StrategySummary memory);

    /**
    @notice Decreases the deployable amount after a deployment/withdrawal
    @param integration  the integration that was changed
    @param poolID  the pool within the integration that handled the tokens
    @param token  the token to decrease for
    @param amount  the amount to reduce the vector by
     */
    function decreaseDeployAmountChange(
        address integration,
        uint32 poolID,
        address token,
        uint256 amount
    ) external;

    /**
    @notice Returns the amount of a given token currently invested in a strategy
    @param id  the strategy id to check
    @param token  The token to retrieve the balance for
    @return amount  the amount of token that is invested in the strategy
     */
    function getStrategyTokenBalance(uint256 id, address token)
        external
        view
        returns (uint256 amount);

    /**
    @notice Returns the total amount of a token invested across all strategies
    @param token  the token to fetch the balance for
    @return amount  the amount of the token currently invested
    */
    function getTokenTotalBalance(address token)
        external
        view
        returns (uint256 amount);

    /**
    @notice Returns the current amount awaiting deployment
    @param integration  the integration to deploy to
    @param poolID  the pool within the integration that should receive the tokens
    @param token  the token to be deployed
    @return the pending deploy amount
     */
    function getDeployAmount(
        address integration,
        uint32 poolID,
        address token
    ) external view returns (int256);

    /**
    @notice Returns balances per strategy, and total invested balances
    @param _strategies  The strategies to retrieve balances for
    @param _tokens  The tokens to retrieve
     */
    function getStrategyBalances(
        uint256[] calldata _strategies,
        address[] calldata _tokens
    )
        external
        view
        returns (
            StrategyBalance[] memory strategyBalances,
            GeneralBalance[] memory generalBalances
        );

    /**
  @notice Returns 1 or more strategies in a single call.
  @param ids  The ids of the strategies to return.
   */
    function getMultipleStrategies(uint256[] calldata ids)
        external
        view
        returns (StrategySummary[] memory);

    /// @notice autogenerated getter definition
    function idCounter() external view returns (uint256);

    /**
    @notice returns the length of the tokens array in a strategy
    @param strategy  the strategy to look up
    @return the length
    */
    function getStrategyTokenLength(uint256 strategy)
        external
        view
        returns (uint256);

    /**
    @notice Clears the list of positions that can be closed to supply a token
    @param tokens  The list of tokens to clear
     */
    function clearClosablePositions(address[] calldata tokens) external;

    /**
    @notice Closes enough positions to provide a requested amount of a token
    @param token  the token to source
    @param amount  the amount to source
     */
    function closePositionsForWithdrawal(address token, uint256 amount)
        external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

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

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IUniswapTrader {
    struct Path {
        address tokenOut;
        uint256 firstPoolFee;
        address tokenInTokenOut;
        uint256 secondPoolFee;
        address tokenIn;
    }

    /// @param tokenA The address of tokenA ERC20 contract
    /// @param tokenB The address of tokenB ERC20 contract
    /// @param fee The Uniswap pool fee
    /// @param slippageNumerator The value divided by the slippage denominator
    /// to calculate the allowable slippage
    function addPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint24 slippageNumerator
    ) external;

    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param poolIndex The index of the pool for the specified token pair
    /// @param slippageNumerator The new slippage numerator to update the pool
    function updatePoolSlippageNumerator(
        address tokenA,
        address tokenB,
        uint256 poolIndex,
        uint24 slippageNumerator
    ) external;

    /// @notice Changes which Uniswap pool to use as the default pool
    /// @notice when swapping between token0 and token1
    /// @param tokenA The address of tokenA of the pool
    /// @param tokenB The address of tokenB of the pool
    /// @param primaryPoolIndex The index of the Uniswap pool to make the new primary pool
    function updatePairPrimaryPool(
        address tokenA,
        address tokenB,
        uint256 primaryPoolIndex
    ) external;

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
    function getAmountInMaximum(
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) external view returns (uint256 amountInMaximum);

    /// @param tokenIn The address of the input token
    /// @param tokenOut The address of the output token
    /// @param amountIn The exact amount of the input to swap
    /// @return amountOut The estimated amount of tokenOut to receive
    function getEstimatedTokenOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) external view returns (uint256 amountOut);

    function getPathFor(address tokenOut, address tokenIn)
        external
        view
        returns (Path memory);

    function setPathFor(
        address tokenOut,
        address tokenIn,
        uint256 firstPoolFee,
        address tokenInTokenOut,
        uint256 secondPoolFee
    ) external;

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return token0 The address of the sorted token0
    /// @return token1 The address of the sorted token1
    function getTokensSorted(address tokenA, address tokenB)
        external
        pure
        returns (address token0, address token1);

    /// @return The number of token pairs configured
    function getTokenPairsLength() external view returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @return The quantity of pools configured for the specified token pair
    function getTokenPairPoolsLength(address tokenA, address tokenB)
        external
        view
        returns (uint256);

    /// @param tokenA The address of tokenA
    /// @param tokenB The address of tokenB
    /// @param poolId The index of the pool in the pools mapping
    /// @return feeNumerator The numerator that gets divided by the fee denominator
    function getPoolFeeNumerator(
        address tokenA,
        address tokenB,
        uint256 poolId
    ) external view returns (uint24 feeNumerator);

    function getPoolAddress(address tokenA, address tokenB)
        external
        view
        returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;
import "./IStrategyMap.sol";

interface IUserPositions {
    // ##### Structs
    struct TokenMovement {
        address token;
        uint256 amount;
    }

    struct StrategyRecord {
        uint256 strategyId;
        uint256 timestamp;
    }

    // ##### Events
    event EnterStrategy(
        uint256 indexed id,
        address indexed user,
        TokenMovement[] tokens
    );
    event ExitStrategy(
        uint256 indexed id,
        address indexed user,
        TokenMovement[] tokens
    );
    event Deposit(
        address indexed user,
        address[] tokens,
        uint256[] tokenAmounts,
        uint256 ethAmount
    );

    // ##### Functions

    /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
    function setBiosRewardsDuration(uint32 biosRewardsDuration_) external;

    /// @param sender The account seeding BIOS rewards
    /// @param biosAmount The amount of BIOS to add to rewards
    function seedBiosRewards(address sender, uint256 biosAmount) external;

    /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
    function increaseBiosRewards() external;

    /// @notice User is allowed to deposit whitelisted tokens
    /// @param depositor Address of the account depositing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param ethAmount The amount of ETH sent with the deposit
    function deposit(
        address depositor,
        address[] memory tokens,
        uint256[] memory amounts,
        uint256 ethAmount
    ) external;

    /// @notice User is allowed to withdraw tokens
    /// @param recipient The address of the user withdrawing
    /// @param tokens Array of token the token addresses
    /// @param amounts Array of token amounts
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    function withdraw(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bool withdrawWethAsEth
    ) external returns (uint256 ethWithdrawn);

    /// @notice Allows a user to withdraw entire balances of the specified tokens and claim rewards
    /// @param recipient The address of the user withdrawing tokens
    /// @param tokens Array of token address that user is exiting positions from
    /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
    /// @return tokenAmounts The amounts of each token being withdrawn
    /// @return ethWithdrawn The amount of ETH being withdrawn
    /// @return ethClaimed The amount of ETH being claimed from rewards
    /// @return biosClaimed The amount of BIOS being claimed from rewards
    function withdrawAllAndClaim(
        address recipient,
        address[] memory tokens,
        bool withdrawWethAsEth
    )
        external
        returns (
            uint256[] memory tokenAmounts,
            uint256 ethWithdrawn,
            uint256 ethClaimed,
            uint256 biosClaimed
        );

    /// @param user The address of the user claiming ETH rewards
    function claimEthRewards(address user)
        external
        returns (uint256 ethClaimed);

    /// @notice Allows users to claim their BIOS rewards for each token
    /// @param recipient The address of the usuer claiming BIOS rewards
    function claimBiosRewards(address recipient)
        external
        returns (uint256 biosClaimed);

    /// @param asset Address of the ERC20 token contract
    /// @return The total balance of the asset deposited in the system
    function totalTokenBalance(address asset) external view returns (uint256);

    /// @notice Returns the amount that a user has deposited, but that isn't in a strategy
    /// @param asset Address of the ERC20 token contract
    /// @param account Address of the user account
    function userTokenBalance(address asset, address account)
        external
        view
        returns (uint256);

    /// @return The Bios Rewards Duration
    function getBiosRewardsDuration() external view returns (uint32);

    /**
    @notice Adds a user's funds to a strategy to be deployed
    @param strategyID  The strategy to enter
    @param tokens  The tokens and amounts to enter into the strategy
     */
    function enterStrategy(uint256 strategyID, TokenMovement[] calldata tokens)
        external;

    /**
    @notice Marks a user's funds as withdrawable
    @param strategyID  The strategy to withdrawfrom
    @param tokens  The tokens and amounts to withdraw
     */
    function exitStrategy(uint256 strategyID, TokenMovement[] calldata tokens)
        external;

    /**
    @notice returns the amount of a given token a user has invested in a given strategy
    @param id  the strategy id
    @param token  the token address
    @param user  the user who holds the funds
    @return amount  the amount of token that the user has invested in the strategy 
     */
    function getUserStrategyBalanceByToken(
        uint256 id,
        address token,
        address user
    ) external view returns (uint256 amount);

    /**
    @notice Returns the amount of a given token that a user has invested across all strategies
    @param token  the token address
    @param user  the user holding the funds
    @return amount  the amount of tokens the user has invested across all strategies
     */
    function getUserInvestedAmountByToken(address token, address user)
        external
        view
        returns (uint256 amount);

    /**
    @notice Returns a user's balances for requested strategies, and the users total invested amounts for each token requested
    @param user  the user to request for
    @param _strategies  the strategies to get balances for
    @param _tokens  the tokens to get balances for
    @return userStrategyBalances  The user's invested funds in the strategies
    @return userBalance  User total token balances
     */
    function getUserBalances(
        address user,
        uint256[] calldata _strategies,
        address[] calldata _tokens
    )
        external
        view
        returns (
            IStrategyMap.StrategyBalance[] memory userStrategyBalances,
            IStrategyMap.GeneralBalance[] memory userBalance
        );
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IWeth9 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    /// @param wad The amount of wETH to withdraw into ETH
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity 0.8.4;

interface IYieldManager {
    // #### Structs

    struct DeployRequest {
        address integration;
        address[] tokens; // If ammPoolID > 0, this should contain exactly two addresses
        uint32 ammPoolID; // The pool to deposit into. This is 0 for non-AMM integrations
    }

    // #### Functions
    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(
        uint256 gasAccountTargetEthBalance_
    ) external;

    /// @param biosBuyBackEthWeight_ The relative weight of ETH to send to BIOS buy back
    /// @param treasuryEthWeight_ The relative weight of ETH to send to the treasury
    /// @param protocolFeeEthWeight_ The relative weight of ETH to send to protocol fee accrual
    /// @param rewardsEthWeight_ The relative weight of ETH to send to user rewards
    function updateEthDistributionWeights(
        uint32 biosBuyBackEthWeight_,
        uint32 treasuryEthWeight_,
        uint32 protocolFeeEthWeight_,
        uint32 rewardsEthWeight_
    ) external;

    /// @param gasAccount_ The address of the account to send ETH to gas for executing bulk system functions
    function updateGasAccount(address payable gasAccount_) external;

    /// @param treasuryAccount_ The address of the system treasury account
    function updateTreasuryAccount(address payable treasuryAccount_) external;

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy(DeployRequest[] calldata deployments) external;

    /// @notice Harvests available yield from all tokens and integrations
    function harvestYield(
        address integrationAddress,
        address[] calldata tokenAddresses
    ) external;

    /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external;

    /// @notice Uses WETH to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of the token held in the Kernel as reserves
    function getReserveTokenBalance(address tokenAddress)
        external
        view
        returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The desired amount of the token to hold in the Kernel as reserves
    function getDesiredReserveTokenBalance(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return ethWeightSum The sum of ETH distribution weights
    function getEthWeightSum() external view returns (uint32 ethWeightSum);

    /// @return processedWethSum The sum of yields processed into WETH
    function getProcessedWethSum()
        external
        view
        returns (uint256 processedWethSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of WETH received from token yield processing
    function getProcessedWethByToken(address tokenAddress)
        external
        view
        returns (uint256);

    /// @return processedWethByTokenSum The sum of processed WETH
    function getProcessedWethByTokenSum(address[] calldata)
        external
        view
        returns (uint256 processedWethByTokenSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
    function getTokenTotalIntegrationBalance(address tokenAddress)
        external
        view
        returns (uint256 tokenTotalIntegrationBalance);

    /// @return The address of the gas account
    function getGasAccount() external view returns (address);

    /// @return The address of the treasury account
    function getTreasuryAccount() external view returns (address);

    /// @return The last amount of ETH distributed to rewards
    function getLastEthRewardsAmount() external view returns (uint256);

    /// @return The target ETH balance of the gas account
    function getGasAccountTargetEthBalance() external view returns (uint256);

    /// @return The BIOS buyback ETH weight
    /// @return The Treasury ETH weight
    /// @return The Protocol fee ETH weight
    /// @return The rewards ETH weight
    function getEthDistributionWeights()
        external
        view
        returns (
            uint32,
            uint32,
            uint32,
            uint32
        );

    function transferClosedPositionsValue(address token, uint256 amount)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}