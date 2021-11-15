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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IIntegrationMap.sol";
import "../interfaces/IBiosRewards.sol";
import "../interfaces/IEtherRewards.sol";
import "../interfaces/IUserPositions.sol";
import "../interfaces/IWeth9.sol";
import "../interfaces/IYieldManager.sol";
import "../interfaces/IIntegration.sol";
import "../interfaces/IStrategyMap.sol";
import "./Controlled.sol";
import "./ModuleMapConsumer.sol";

/// @title User Positions
/// @notice Allows users to deposit/withdraw erc20 tokens
contract UserPositions is
  Initializable,
  ModuleMapConsumer,
  Controlled,
  IUserPositions
{
  using SafeERC20Upgradeable for IERC20MetadataUpgradeable;

  uint32 private _biosRewardsDuration;

  // Token address => total supply held by the contract
  mapping(address => uint256) private _totalSupply;

  // Token address => User address => User's balance of token held by the contract
  mapping(address => mapping(address => uint256)) private _balances;

  /// @param controllers_ The addresses of the controlling contracts
  /// @param moduleMap_ Address of the Module Map
  /// @param biosRewardsDuration_ The duration is seconds for a BIOS rewards period to last
  function initialize(
    address[] memory controllers_,
    address moduleMap_,
    uint32 biosRewardsDuration_
  ) public initializer {
    __Controlled_init(controllers_, moduleMap_);
    __ModuleMapConsumer_init(moduleMap_);
    _biosRewardsDuration = biosRewardsDuration_;
  }

  /// @param biosRewardsDuration_ The duration in seconds for a BIOS rewards period to last
  function setBiosRewardsDuration(uint32 biosRewardsDuration_)
    external
    override
    onlyController
  {
    require(
      _biosRewardsDuration != biosRewardsDuration_,
      "UserPositions::setBiosRewardsDuration: Duration must be set to a new value"
    );
    require(
      biosRewardsDuration_ > 0,
      "UserPositions::setBiosRewardsDuration: Duration must be greater than zero"
    );

    _biosRewardsDuration = biosRewardsDuration_;
  }

  /// @param sender The account seeding BIOS rewards
  /// @param biosAmount The amount of BIOS to add to rewards
  function seedBiosRewards(address sender, uint256 biosAmount)
    external
    override
    onlyController
  {
    require(
      biosAmount > 0,
      "UserPositions::seedBiosRewards: BIOS amount must be greater than zero"
    );

    IERC20MetadataUpgradeable bios = IERC20MetadataUpgradeable(
      IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
        .getBiosTokenAddress()
    );

    bios.safeTransferFrom(
      sender,
      moduleMap.getModuleAddress(Modules.Kernel),
      biosAmount
    );

    _increaseBiosRewards();
  }

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
  ) external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      // Token must be accepting deposits
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[tokenId]),
        "UserPositions::deposit: This token is not accepting deposits"
      );

      require(
        amounts[tokenId] > 0,
        "UserPositions::deposit: Deposit amount must be greater than zero"
      );

      IERC20MetadataUpgradeable erc20 = IERC20MetadataUpgradeable(
        tokens[tokenId]
      );

      // Get the balance before the transfer
      uint256 beforeBalance = erc20.balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      );

      // Transfer the tokens from the depositor to the Kernel
      erc20.safeTransferFrom(
        depositor,
        moduleMap.getModuleAddress(Modules.Kernel),
        amounts[tokenId]
      );

      // Get the balance after the transfer
      uint256 afterBalance = erc20.balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      );
      uint256 actualAmount = afterBalance - beforeBalance;

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(tokens[tokenId], depositor, actualAmount);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], depositor);

      // Update balances
      _totalSupply[tokens[tokenId]] += actualAmount;
      _balances[tokens[tokenId]][depositor] += actualAmount;
    }

    if (ethAmount > 0) {
      address wethAddress = integrationMap.getWethTokenAddress();

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(wethAddress, depositor, ethAmount);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(wethAddress, depositor);

      // Update WETH balances
      _totalSupply[wethAddress] += ethAmount;
      _balances[wethAddress][depositor] += ethAmount;
    }
  }

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
  ) external override onlyController returns (uint256 ethWithdrawn) {
    ethWithdrawn = _withdraw(recipient, tokens, amounts, withdrawWethAsEth);
  }

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
    override
    onlyController
    returns (
      uint256[] memory tokenAmounts,
      uint256 ethWithdrawn,
      uint256 ethClaimed,
      uint256 biosClaimed
    )
  {
    tokenAmounts = new uint256[](tokens.length);

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      tokenAmounts[tokenId] = userTokenBalance(tokens[tokenId], recipient);
    }

    ethWithdrawn = _withdraw(
      recipient,
      tokens,
      tokenAmounts,
      withdrawWethAsEth
    );

    if (
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .getUserEthRewards(recipient) > 0
    ) {
      ethClaimed = _claimEthRewards(recipient);
    }

    biosClaimed = _claimBiosRewards(recipient);
  }

  /// @notice User is allowed to withdraw tokens
  /// @param recipient The address of the user withdrawing
  /// @param tokens Array of token the token addresses
  /// @param amounts Array of token amounts
  /// @param withdrawWethAsEth Boolean indicating whether should receive WETH balance as ETH
  function _withdraw(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts,
    bool withdrawWethAsEth
  ) private returns (uint256 ethWithdrawn) {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address wethAddress = integrationMap.getWethTokenAddress();

    require(
      tokens.length == amounts.length,
      "UserPositions::_withdraw: Tokens array length does not match amounts array length"
    );

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      require(
        amounts[tokenId] > 0,
        "UserPositions::_withdraw: Withdraw amount must be greater than zero"
      );
      require(
        integrationMap.getTokenAcceptingWithdrawals(tokens[tokenId]),
        "UserPositions::_withdraw: This token is not accepting withdrawals"
      );
      require(
        amounts[tokenId] <= _balances[tokens[tokenId]][recipient],
        "UserPositions::_withdraw: Withdraw amount exceeds user balance"
      );

      if (
        IERC20MetadataUpgradeable(tokens[tokenId]).balanceOf(
          moduleMap.getModuleAddress(Modules.Kernel)
        ) < amounts[tokenId]
      ) {
        // Token reserve balance in Kernel is not enough to support to withdrawal, need to close integration positions
        closePositionsForWithdrawal(tokens[tokenId], amounts[tokenId]);

        if (
          IERC20MetadataUpgradeable(tokens[tokenId]).balanceOf(
            moduleMap.getModuleAddress(Modules.Kernel)
          ) < amounts[tokenId]
        ) {
          // If token reserve balance is still not enough, adjust the token amount
          amounts[tokenId] = IERC20MetadataUpgradeable(tokens[tokenId])
            .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));
        }
      }

      if (tokens[tokenId] == wethAddress && withdrawWethAsEth) {
        ethWithdrawn = amounts[tokenId];
      } else {
        // Send the tokens back to specified recipient
        IERC20MetadataUpgradeable(tokens[tokenId]).safeTransferFrom(
          moduleMap.getModuleAddress(Modules.Kernel),
          recipient,
          amounts[tokenId]
        );
      }

      // Decrease rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .decreaseRewards(tokens[tokenId], recipient, amounts[tokenId]);

      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], recipient);

      // Update balances
      _totalSupply[tokens[tokenId]] -= amounts[tokenId];
      _balances[tokens[tokenId]][recipient] -= amounts[tokenId];
    }
  }

  /// @param token The address of the token to withdraw from integrations
  /// @param amount The token amount needed in the Kernel for withdrawal
  function closePositionsForWithdrawal(address token, uint256 amount) private {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IStrategyMap strategyMap = IStrategyMap(
      moduleMap.getModuleAddress(Modules.StrategyMap)
    );

    uint256 integrationWeightSum = strategyMap.getIntegrationWeightSum();

    // Iterate through integrations and close positions in proportion to integration weights
    for (
      uint256 integrationId;
      integrationId < integrationMap.getIntegrationAddressesLength();
      integrationId++
    ) {
      address integrationAddress = integrationMap.getIntegrationAddress(
        integrationId
      );
      uint256 desiredWithdrawAmount = (amount *
        strategyMap.getIntegrationWeight(integrationAddress)) /
        integrationWeightSum;

      if (
        desiredWithdrawAmount >
        IIntegration(integrationAddress).getBalance(token)
      ) {
        desiredWithdrawAmount = IIntegration(integrationAddress).getBalance(
          token
        );
      }

      IIntegration(integrationAddress).withdraw(token, desiredWithdrawAmount);
    }

    if (
      IERC20MetadataUpgradeable(token).balanceOf(
        moduleMap.getModuleAddress(Modules.Kernel)
      ) < amount
    ) {
      // Amount in Kernel is still not enough, start fully closing integration positions until amount is satisfied
      fullyClosePositionsForWithdrawal(token, amount);
    }
  }

  /// @notice Fully closes the specified token positions in each integration until the desired balance
  /// @notice in the Kernel is satisfied, or all positions have been closed
  function fullyClosePositionsForWithdrawal(address token, uint256 amount)
    private
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    uint256 integrationId;
    bool doneClosingPositions;

    while (!doneClosingPositions) {
      IIntegration integration = IIntegration(
        integrationMap.getIntegrationAddress(integrationId)
      );

      // Withdraw the tokens full balance from the integration
      integration.withdraw(token, integration.getBalance(token));

      if (
        integrationId == integrationMap.getIntegrationAddressesLength() - 1 ||
        IERC20MetadataUpgradeable(token).balanceOf(
          moduleMap.getModuleAddress(Modules.Kernel)
        ) >=
        amount
      ) {
        // If the last integration has been reached, or the desired Kernel amount has been satisfied,
        // Then stop closing positions
        doneClosingPositions = true;
      }

      integrationId++;
    }
  }

  /**
    @notice Moves funds from a user's position to a strategy
    @param recipient The user to move the funds from
    @param tokens The tokens to be moved
    @param amounts The amounts to be moved
     */
  function transferToStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external override onlyController {
    require(
      tokens.length == amounts.length,
      "UserPositions::_withdraw: Tokens array length does not match amounts array length"
    );

    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      require(
        amounts[tokenId] > 0,
        "UserPositions::_withdraw: Withdraw amount must be greater than zero"
      );
      require(
        amounts[tokenId] <= _balances[tokens[tokenId]][recipient],
        "UserPositions::_withdraw: Withdraw amount exceeds user balance"
      );

      // Decrease rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .decreaseRewards(tokens[tokenId], recipient, amounts[tokenId]);

      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], recipient);

      // Update balances
      _totalSupply[tokens[tokenId]] -= amounts[tokenId];
      _balances[tokens[tokenId]][recipient] -= amounts[tokenId];
    }
  }

  /**
    @notice Updates a user's position with funds moved from a strategy
    @param recipient The user to move the funds to
    @param tokens The tokens to be moved
    @param amounts The amounts to be moved
     */
  function transferFromStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external override onlyController {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    for (uint256 tokenId; tokenId < tokens.length; tokenId++) {
      // Token must be accepting deposits
      require(
        integrationMap.getTokenAcceptingDeposits(tokens[tokenId]),
        "UserPositions::deposit: This token is not accepting deposits"
      );
      require(
        amounts[tokenId] > 0,
        "UserPositions::deposit: Deposit amount must be greater than zero"
      );

      // Increase rewards
      IBiosRewards(moduleMap.getModuleAddress(Modules.BiosRewards))
        .increaseRewards(tokens[tokenId], recipient, amounts[tokenId]);
      IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
        .updateUserRewards(tokens[tokenId], recipient);

      // Update balances
      _totalSupply[tokens[tokenId]] += amounts[tokenId];
      _balances[tokens[tokenId]][recipient] += amounts[tokenId];
    }
  }

  /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
  function increaseBiosRewards() external override onlyController {
    _increaseBiosRewards();
  }

  /// @notice Sends all BIOS available in the Kernel to each token BIOS rewards pool based up configured weights
  function _increaseBiosRewards() private {
    IBiosRewards biosRewards = IBiosRewards(
      moduleMap.getModuleAddress(Modules.BiosRewards)
    );
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    address biosAddress = integrationMap.getBiosTokenAddress();
    uint256 kernelBiosBalance = IERC20MetadataUpgradeable(biosAddress)
      .balanceOf(moduleMap.getModuleAddress(Modules.Kernel));

    require(
      kernelBiosBalance >
        biosRewards.getBiosRewards() + _totalSupply[biosAddress],
      "UserPositions::increaseBiosRewards: No available BIOS to add to rewards"
    );

    uint256 availableBiosRewards = kernelBiosBalance -
      biosRewards.getBiosRewards() -
      _totalSupply[biosAddress];

    uint256 tokenCount = integrationMap.getTokenAddressesLength();
    uint256 biosRewardWeightSum = integrationMap.getBiosRewardWeightSum();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address token = integrationMap.getTokenAddress(tokenId);
      uint256 tokenBiosRewardWeight = integrationMap.getTokenBiosRewardWeight(
        token
      );
      uint256 tokenBiosRewardAmount = (availableBiosRewards *
        tokenBiosRewardWeight) / biosRewardWeightSum;
      _increaseTokenBiosRewards(token, tokenBiosRewardAmount);
    }
  }

  /// @param token The address of the ERC20 token contract
  /// @param biosReward The added reward amount
  function _increaseTokenBiosRewards(address token, uint256 biosReward)
    private
  {
    IBiosRewards biosRewards = IBiosRewards(
      moduleMap.getModuleAddress(Modules.BiosRewards)
    );

    require(
      IERC20MetadataUpgradeable(
        IIntegrationMap(moduleMap.getModuleAddress(Modules.IntegrationMap))
          .getBiosTokenAddress()
      ).balanceOf(moduleMap.getModuleAddress(Modules.Kernel)) >=
        biosReward + biosRewards.getBiosRewards(),
      "UserPositions::increaseTokenBiosRewards: Not enough available BIOS for specified amount"
    );

    biosRewards.notifyRewardAmount(token, biosReward, _biosRewardsDuration);
  }

  /// @param recipient The address of the user claiming BIOS rewards
  function claimEthRewards(address recipient)
    external
    override
    onlyController
    returns (uint256 ethClaimed)
  {
    ethClaimed = _claimEthRewards(recipient);
  }

  /// @param recipient The address of the user claiming BIOS rewards
  function _claimEthRewards(address recipient)
    private
    returns (uint256 ethClaimed)
  {
    ethClaimed = IEtherRewards(moduleMap.getModuleAddress(Modules.EtherRewards))
      .claimEthRewards(recipient);
  }

  /// @notice Allows users to claim their BIOS rewards for each token
  /// @param recipient The address of the user claiming BIOS rewards
  function claimBiosRewards(address recipient)
    external
    override
    onlyController
    returns (uint256 biosClaimed)
  {
    biosClaimed = _claimBiosRewards(recipient);
  }

  /// @notice Allows users to claim their BIOS rewards for each token
  /// @param recipient The address of the user claiming BIOS rewards
  function _claimBiosRewards(address recipient)
    private
    returns (uint256 biosClaimed)
  {
    IIntegrationMap integrationMap = IIntegrationMap(
      moduleMap.getModuleAddress(Modules.IntegrationMap)
    );
    IBiosRewards biosRewards = IBiosRewards(
      moduleMap.getModuleAddress(Modules.BiosRewards)
    );

    uint256 tokenCount = integrationMap.getTokenAddressesLength();

    for (uint256 tokenId; tokenId < tokenCount; tokenId++) {
      address token = integrationMap.getTokenAddress(tokenId);

      if (biosRewards.earned(token, recipient) > 0) {
        biosClaimed += IBiosRewards(
          moduleMap.getModuleAddress(Modules.BiosRewards)
        ).claimReward(token, recipient);
      }
    }

    IERC20MetadataUpgradeable(integrationMap.getBiosTokenAddress())
      .safeTransferFrom(
        moduleMap.getModuleAddress(Modules.Kernel),
        recipient,
        biosClaimed
      );
  }

  /// @param asset Address of the ERC20 token contract
  /// @return The total balance of the asset deposited in the system
  function totalTokenBalance(address asset)
    public
    view
    override
    returns (uint256)
  {
    return _totalSupply[asset];
  }

  /// @param asset Address of the ERC20 token contract
  /// @param account Address of the user account
  function userTokenBalance(address asset, address account)
    public
    view
    override
    returns (uint256)
  {
    return _balances[asset][account];
  }

  /// @return The Bios Rewards Duration
  function getBiosRewardsDuration() public view override returns (uint32) {
    return _biosRewardsDuration;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBiosRewards {
    /// @param token The address of the ERC20 token contract
    /// @param reward The updated reward amount
    /// @param duration The duration of the rewards period
    function notifyRewardAmount(
        address token,
        uint256 reward,
        uint32 duration
    ) external;

    function increaseRewards(address token, address account, uint256 amount) external;

    function decreaseRewards(address token, address account, uint256 amount) external;

    function claimReward(address asset, address account) external returns (uint256 reward);

    function lastTimeRewardApplicable(address token) external view returns (uint256);

    function rewardPerToken(address token) external view returns (uint256);

    function earned(address token, address account) external view returns (uint256);

    function getUserBiosRewards(address account) external view returns (uint256 userBiosRewards);

    function getTotalClaimedBiosRewards() external view returns (uint256);
    
    function getTotalUserClaimedBiosRewards(address account) external view returns (uint256);

    function getBiosRewards() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEtherRewards {
    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    function updateUserRewards(address token, address user) external;
    
    /// @param token The address of the token ERC20 contract
    /// @param ethRewardsAmount The amount of Ether rewards to add
    function increaseEthRewards(address token, uint256 ethRewardsAmount) external;

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function claimEthRewards(address user) external returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserTokenEthRewards(address token, address user) external view returns (uint256 ethRewards);

    /// @param user The address of the user
    /// @return ethRewards The amount of Ether claimed
    function getUserEthRewards(address user) external view returns (uint256 ethRewards);

    /// @param token The address of the token ERC20 contract
    /// @return The amount of Ether rewards for the specified token
    function getTokenEthRewards(address token) external view returns (uint256);

    /// @return The total value of ETH claimed by users
    function getTotalClaimedEthRewards() external view returns (uint256);

    /// @return The total value of ETH claimed by a user
    function getTotalUserClaimedEthRewards(address user) external view returns (uint256);

    /// @return The total amount of Ether rewards
    function getEthRewards() external view returns (uint256);
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
pragma solidity ^0.8.4;

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
    function addIntegration(address contractAddress, string memory name) external;

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
    function updateTokenRewardWeight(address tokenAddress, uint256 rewardWeight) external;

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
  UniswapTrader, // 7
  StrategyMap, // 8
  StrategyManager // 9
}

interface IModuleMap {
  function getModuleAddress(Modules key) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "../interfaces/IIntegration.sol";

interface IStrategyMap {
  // #### Structs
  struct WeightedIntegration {
    address integration;
    uint256 weight;
  }

  struct Strategy {
    string name;
    uint256 totalStrategyWeight;
    WeightedIntegration[] integrations;
  }

  struct StrategyTransaction {
    uint256 amount;
    address token;
  }

  // #### Events
  event NewStrategy(
    uint256 indexed id,
    string name,
    WeightedIntegration[] integrations
  );
  event UpdateName(uint256 indexed id, string name);
  event UpdateIntegrations(
    uint256 indexed id,
    WeightedIntegration[] integrations
  );
  event DeleteStrategy(
    uint256 indexed id,
    string name,
    WeightedIntegration[] integrations
  );

  event EnterStrategy(
    uint256 indexed id,
    address indexed user,
    address[] tokens,
    uint256[] amounts
  );
  event ExitStrategy(
    uint256 indexed id,
    address indexed user,
    address[] tokens,
    uint256[] amounts
  );

  // #### Functions
  /**
     @notice Adds a new strategy to the list of available strategies
     @param name  the name of the new strategy
     @param integrations  the integrations and weights that form the strategy
     */
  function addStrategy(
    string calldata name,
    WeightedIntegration[] memory integrations
  ) external;

  /**
    @notice Updates the strategy name
    @param name  the new name
     */
  function updateName(uint256 id, string calldata name) external;

  /**
    @notice Updates the strategy integrations 
    @param integrations  the new integrations
     */
  function updateIntegrations(
    uint256 id,
    WeightedIntegration[] memory integrations
  ) external;

  /**
    @notice Deletes a strategy
    @dev This can only be called successfully if the strategy being deleted doesn't have any assets invested in it
    @param id  the strategy to delete
     */
  function deleteStrategy(uint256 id) external;

  /**
    @notice Increases the amount of a set of tokens in a strategy
    @param id  the strategy to deposit into
    @param tokens  the tokens to deposit
    @param amounts  The amounts to be deposited
     */
  function enterStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
    @notice Decreases the amount of a set of tokens invested in a strategy
    @param id  the strategy to withdraw assets from
    @param tokens  the tokens to withdraw
    @param amounts  The amounts to be withdrawn
     */
  function exitStrategy(
    uint256 id,
    address user,
    address[] calldata tokens,
    uint256[] calldata amounts
  ) external;

  /**
    @notice Getter function to return the nested arrays as well as the name
    @param id  the strategy to return
     */
  function getStrategy(uint256 id) external view returns (Strategy memory);

  /**
    @notice Returns the expected balance of a given token in a given integration
    @param integration  the integration the amount should be invested in
    @param token  the token that is being invested
    @return balance  the balance of the token that should be currently invested in the integration 
     */
  function getExpectedBalance(address integration, address token)
    external
    view
    returns (uint256 balance);

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
    @notice Returns the total amount of a token invested across all strategies
    @param token  the token to fetch the balance for
    @return amount  the amount of the token currently invested
    */
  function getTokenTotalBalance(address token)
    external
    view
    returns (uint256 amount);

  /**
  @notice Returns the weight of an individual integration within the system
  @param integration  the integration to look up
  @return The weight of the integration
   */
  function getIntegrationWeight(address integration)
    external
    view
    returns (uint256);

  /**
  @notice Returns the sum of all weights in the system.
  @return The sum of all integration weights within the system
   */
  function getIntegrationWeightSum() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUserPositions {
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
  function claimEthRewards(address user) external returns (uint256 ethClaimed);

  /// @notice Allows users to claim their BIOS rewards for each token
  /// @param recipient The address of the usuer claiming BIOS rewards
  function claimBiosRewards(address recipient)
    external
    returns (uint256 biosClaimed);

  /// @param asset Address of the ERC20 token contract
  /// @return The total balance of the asset deposited in the system
  function totalTokenBalance(address asset) external view returns (uint256);

  /// @param asset Address of the ERC20 token contract
  /// @param account Address of the user account
  function userTokenBalance(address asset, address account)
    external
    view
    returns (uint256);

  /// @return The Bios Rewards Duration
  function getBiosRewardsDuration() external view returns (uint32);

  /// @notice Transfers tokens to the StrategyMap
  /// @dev This is a ledger adjustment. The tokens remain in the kernel.
  /// @param recipient  The user to transfer funds for
  /// @param tokens  the tokens to be moved
  /// @param amounts  the amounts of each token to move
  function transferToStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external;

  /// @notice Transfers tokens from the StrategyMap
  /// @dev This is a ledger adjustment. The tokens remain in the kernel.
  /// @param recipient  The user to transfer funds for
  /// @param tokens  the tokens to be moved
  /// @param amounts  the amounts of each token to move
  function transferFromStrategy(
    address recipient,
    address[] memory tokens,
    uint256[] memory amounts
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWeth9 {
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    function deposit() external payable;

    /// @param wad The amount of wETH to withdraw into ETH
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IYieldManager {
    /// @param gasAccountTargetEthBalance_ The target ETH balance of the gas account
    function updateGasAccountTargetEthBalance(uint256 gasAccountTargetEthBalance_) external;

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

    /// @notice Withdraws and then re-deploys tokens to integrations according to configured weights
    function rebalance() external;

    /// @notice Deploys all tokens to all integrations according to configured weights
    function deploy() external;

    /// @notice Harvests available yield from all tokens and integrations
    function harvestYield() external;

    /// @notice Swaps harvested yield for all tokens for ETH
    function processYield() external;

    /// @notice Distributes ETH to the gas account, BIOS buy back, treasury, protocol fee accrual, and user rewards
    function distributeEth() external;

    /// @notice Uses WETH to buy back BIOS which is sent to the Kernel
    function biosBuyBack() external;

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return harvestedTokenBalance The amount of the token yield harvested held in the Kernel
    function getHarvestedTokenBalance(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of the token held in the Kernel as reserves
    function getReserveTokenBalance(address tokenAddress) external view returns (uint256);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The desired amount of the token to hold in the Kernel as reserves
    function getDesiredReserveTokenBalance(address tokenAddress) external view returns (uint256);

    /// @return ethWeightSum The sum of ETH distribution weights
    function getEthWeightSum() external view returns (uint32 ethWeightSum);

    /// @return processedWethSum The sum of yields processed into WETH
    function getProcessedWethSum() external view returns (uint256 processedWethSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return The amount of WETH received from token yield processing
    function getProcessedWethByToken(address tokenAddress) external view returns (uint256);

    /// @return processedWethByTokenSum The sum of processed WETH
    function getProcessedWethByTokenSum() external view returns (uint256 processedWethByTokenSum);

    /// @param tokenAddress The address of the token ERC20 contract
    /// @return tokenTotalIntegrationBalance The total amount of the token that can be withdrawn from integrations
    function getTokenTotalIntegrationBalance(address tokenAddress) external view returns (uint256 tokenTotalIntegrationBalance);

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
    function getEthDistributionWeights() external view returns (uint32, uint32, uint32, uint32);
}

