// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import './Proxy.sol';
import '../contracts/Address.sol';

/**
 * @title BaseUpgradeabilityProxy
 * @dev This contract implements a proxy that allows to change the
 * implementation address to which it will delegate.
 * Such a change is called an implementation upgrade.
 */
contract BaseUpgradeabilityProxy is Proxy {
  /**
   * @dev Emitted when the implementation is upgraded.
   * @param implementation Address of the new implementation.
   */
  event Upgraded(address indexed implementation);

  /**
   * @dev Storage slot with the address of the current implementation.
   * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
   * validated in the constructor.
   */
  bytes32 internal constant IMPLEMENTATION_SLOT =
    0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

  /**
   * @dev Returns the current implementation.
   * @return impl Address of the current implementation
   */
  function _implementation() internal view override returns (address impl) {
    bytes32 slot = IMPLEMENTATION_SLOT;
    //solium-disable-next-line
    assembly {
      impl := sload(slot)
    }
  }

  /**
   * @dev Upgrades the proxy to a new implementation.
   * @param newImplementation Address of the new implementation.
   */
  function _upgradeTo(address newImplementation) internal {
    _setImplementation(newImplementation);
    emit Upgraded(newImplementation);
  }

  /**
   * @dev Sets the implementation address of the proxy.
   * @param newImplementation Address of the new implementation.
   */
  function _setImplementation(address newImplementation) internal {
    require(
      Address.isContract(newImplementation),
      'Cannot set a proxy implementation to a non-contract address'
    );

    bytes32 slot = IMPLEMENTATION_SLOT;

    //solium-disable-next-line
    assembly {
      sstore(slot, newImplementation)
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import './BaseUpgradeabilityProxy.sol';

/**
 * @title InitializableUpgradeabilityProxy
 * @dev Extends BaseUpgradeabilityProxy with an initializer for initializing
 * implementation and init data.
 */
contract InitializableUpgradeabilityProxy is BaseUpgradeabilityProxy {
  /**
   * @dev Contract initializer.
   * @param _logic Address of the initial implementation.
   * @param _data Data to send as msg.data to the implementation to initialize the proxied contract.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   * This parameter is optional, if no data is given the initialization call to proxied contract will be skipped.
   */
  function initialize(address _logic, bytes memory _data) public payable {
    require(_implementation() == address(0));
    assert(IMPLEMENTATION_SLOT == bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1));
    _setImplementation(_logic);
    if (_data.length > 0) {
      (bool success, ) = _logic.delegatecall(_data);
      require(success);
    }
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title Proxy
 * @dev Implements delegation of calls to other contracts, with proper
 * forwarding of return values and bubbling of failures.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
abstract contract Proxy {
  /**
   * @dev Fallback function.
   * Will run if no other function in the contract matches the call data.
   * Implemented entirely in `_fallback`.
   */
  fallback() external payable {
    _fallback();
  }

  /**
   * @return The Address of the implementation.
   */
  function _implementation() internal view virtual returns (address);

  /**
   * @dev Delegates execution to an implementation contract.
   * This is a low level function that doesn't return to its internal call site.
   * It will return to the external caller whatever the implementation returns.
   * @param implementation Address to delegate.
   */
  function _delegate(address implementation) internal {
    //solium-disable-next-line
    assembly {
      // Copy msg.data. We take full control of memory in this inline assembly
      // block because it will not return to Solidity code. We overwrite the
      // Solidity scratch pad at memory position 0.
      calldatacopy(0, 0, calldatasize())

      // Call the implementation.
      // out and outsize are 0 because we don't know the size yet.
      let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())

      switch result
      // delegatecall returns 0 on error.
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /**
   * @dev Function that is run as the first thing in the fallback function.
   * Can be redefined in derived contracts to add functionality.
   * Redefinitions must call super._willFallback().
   */
  function _willFallback() internal virtual {}

  /**
   * @dev fallback implementation.
   * Extracted to enable manual triggering.
   */
  function _fallback() internal {
    _willFallback();
    _delegate(_implementation());
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IAaveIncentivesController
 * @author Aave
 * @notice Defines the basic interface for an Aave Incentives Controller.
 **/
interface IAaveIncentivesController {
  /**
   * @notice Emitted during `handleAction`, `claimRewards` and `claimRewardsOnBehalf`
   * @param user The user that accrued rewards
   * @param amount The amount of accrued rewards
   */
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  /**
   * @notice Emitted during `claimRewards` and `claimRewardsOnBehalf`
   * @param user The address that accrued rewards
   * @param to The address that will be receiving the rewards
   * @param claimer The address that performed the claim
   * @param amount The amount of rewards
   */
  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  /**
   * @notice Emitted during `setClaimer`
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  event ClaimerSet(address indexed user, address indexed claimer);

  /**
   * @notice Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index
   * @return The emission per second
   * @return The last updated timestamp
   **/
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /**
   * LEGACY **************************
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function assets(address asset)
    external
    view
    returns (
      uint128,
      uint128,
      uint256
    );

  /**
   * @notice Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @notice Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @notice Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;

  /**
   * @notice Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the pool
   * @param totalSupply The total supply of the asset in the pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @notice Returns the total of rewards of a user, already accrued + not yet accrued
   * @param assets The assets to accumulate rewards for
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @notice Claims reward for a user, on the assets of the pool, accumulating the pending rewards
   * @param assets The assets to accumulate rewards for
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Claims reward for a user on its behalf, on the assets of the pool, accumulating the pending rewards.
   * @dev The caller must be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param assets The assets to accumulate rewards for
   * @param amount The amount of rewards to claim
   * @param user The address to check and claim rewards
   * @param to The address that will be receiving the rewards
   * @return The amount of rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @notice Returns the unclaimed rewards of the user
   * @param user The address of the user
   * @return The unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
   * @notice Returns the user index for a specific asset
   * @param user The address of the user
   * @param asset The asset to incentivize
   * @return The user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @notice for backward compatibility with previous implementation of the Incentives controller
   * @return The address of the reward token
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @notice for backward compatibility with previous implementation of the Incentives controller
   * @return The precision used in the incentives controller
   */
  function PRECISION() external view returns (uint8);

  /**
   * @dev Gets the distribution end timestamp of the emissions
   */
  function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IPool} from './IPool.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IInitializableAToken
 * @author Aave
 * @notice Interface for the initialize function on AToken
 **/
interface IInitializableAToken {
  /**
   * @notice Emitted when an aToken is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param treasury The address of the treasury
   * @param incentivesController The address of the incentives controller for this aToken
   * @param aTokenDecimals The decimals of the underlying
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address treasury,
    address incentivesController,
    uint8 aTokenDecimals,
    string aTokenName,
    string aTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the aToken
   * @param treasury The address of the Aave treasury, receiving the fees on this aToken
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param aTokenDecimals The decimals of the aToken, same as the underlying asset's
   * @param aTokenName The name of the aToken
   * @param aTokenSymbol The symbol of the aToken
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    address treasury,
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 aTokenDecimals,
    string calldata aTokenName,
    string calldata aTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IPool} from './IPool.sol';
import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

/**
 * @title IInitializableDebtToken
 * @author Aave
 * @notice Interface for the initialize function common between debt tokens
 **/
interface IInitializableDebtToken {
  /**
   * @notice Emitted when a debt token is initialized
   * @param underlyingAsset The address of the underlying asset
   * @param pool The address of the associated pool
   * @param incentivesController The address of the incentives controller for this aToken
   * @param debtTokenDecimals The decimals of the debt token
   * @param debtTokenName The name of the debt token
   * @param debtTokenSymbol The symbol of the debt token
   * @param params A set of encoded parameters for additional initialization
   **/
  event Initialized(
    address indexed underlyingAsset,
    address indexed pool,
    address incentivesController,
    uint8 debtTokenDecimals,
    string debtTokenName,
    string debtTokenSymbol,
    bytes params
  );

  /**
   * @notice Initializes the debt token.
   * @param underlyingAsset The address of the underlying asset of this aToken (E.g. WETH for aWETH)
   * @param incentivesController The smart contract managing potential incentives distribution
   * @param debtTokenDecimals The decimals of the debtToken, same as the underlying asset's
   * @param debtTokenName The name of the token
   * @param debtTokenSymbol The symbol of the token
   * @param params A set of encoded parameters for additional initialization
   */
  function initialize(
    address underlyingAsset,
    IAaveIncentivesController incentivesController,
    uint8 debtTokenDecimals,
    string memory debtTokenName,
    string memory debtTokenSymbol,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IPoolAddressesProvider} from './IPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

/**
 * @title IPool
 * @author Aave
 * @notice Defines the basic interface for an Aave Pool.
 **/
interface IPool {
  /**
   * @notice Emitted on mintUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supplied assets, receiving the aTokens
   * @param amount The amount of supplied assets
   * @param referral The referral code used
   **/
  event MintUnbacked(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @notice Emitted on backUnbacked()
   * @param reserve The address of the underlying asset of the reserve
   * @param backer The address paying for the backing
   * @param amount The amount added as backing
   **/
  event BackUnbacked(address indexed reserve, address indexed backer, uint256 amount, uint256 fee);

  /**
   * @notice Emitted on supply()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the supply
   * @param onBehalfOf The beneficiary of the supply, receiving the aTokens
   * @param amount The amount supplied
   * @param referralCode The referral code used
   **/
  event Supply(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referralCode
  );

  /**
   * @notice Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to The address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @notice Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @notice Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @notice Emitted on swapBorrowRateMode()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user swapping his rate mode
   * @param rateMode The rate mode that the user wants to swap to
   **/
  event Swap(address indexed reserve, address indexed user, uint256 rateMode);

  /**
   * @notice Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @notice Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @notice Emitted on rebalanceStableBorrowRate()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user for which the rebalance has been executed
   **/
  event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

  /**
   * @notice Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @notice Emitted when a borrower is liquidated.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @notice Emitted when the state of a reserve is updated.
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The next liquidity rate
   * @param stableBorrowRate The next stable borrow rate
   * @param variableBorrowRate The next variable borrow rate
   * @param liquidityIndex The next liquidity index
   * @param variableBorrowIndex The next variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @notice Emitted when the protocol treasury receives minted aTokens from the accrued interest.
   * @param reserve The address of the reserve
   * @param amountMinted The amount minted to the treasury
   **/
  event MintedToTreasury(address indexed reserve, uint256 amountMinted);

  /**
   * @dev Mints an `amount` of aTokens to the `onBehalfOf`
   * @param asset The address of the underlying asset to mint
   * @param amount The amount to mint
   * @param onBehalfOf The address that will receive the aTokens
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function mintUnbacked(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Back the current unbacked underlying with `amount` and pay `fee`.
   * @param asset The address of the underlying asset to back
   * @param amount The amount to back
   * @param fee The amount paid in fees
   **/
  function backUnbacked(
    address asset,
    uint256 amount,
    uint256 fee
  ) external;

  /**
   * @notice Emitted when the user selects a certain asset category for eMode
   * @param user The address of the user
   * @param categoryId The category id
   **/
  event UserEModeSet(address indexed user, uint8 categoryId);

  /*
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function supply(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @notice Supply with transfer approval of asset to be supplied done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param deadline The deadline timestamp that the permit is valid
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   **/
  function supplyWithPermit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external;

  /**
   * @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to The address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already supplied enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf The address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Repay with transfer approval of asset to be repaid done via permit function
   * see: https://eips.ethereum.org/EIPS/eip-2612 and https://eips.ethereum.org/EIPS/eip-713
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @param deadline The deadline timestamp that the permit is valid
   * @param permitV The V parameter of ERC712 permit sig
   * @param permitR The R parameter of ERC712 permit sig
   * @param permitS The S parameter of ERC712 permit sig
   * @return The final amount repaid
   **/
  function repayWithPermit(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf,
    uint256 deadline,
    uint8 permitV,
    bytes32 permitR,
    bytes32 permitS
  ) external returns (uint256);

  /**
   * @notice Repays a borrowed `amount` on a specific reserve using the reserve aTokens held by the repayer, burning the equivalent debt tokens
   * - E.g. User repays 100 USDC using 100 aUSDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf The address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repayWithATokens(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @notice Allows a borrower to swap his debt between stable and variable mode, or viceversa
   * @param asset The address of the underlying asset borrowed
   * @param rateMode The rate mode that the user wants to swap to
   **/
  function swapBorrowRateMode(address asset, uint256 rateMode) external;

  /**
   * @notice Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
   * - Users can be rebalanced if the following conditions are satisfied:
   *     1. Usage ratio is above 95%
   *     2. the current supply APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
   *        borrowed at a stable rate and suppliers are not earning enough
   * @param asset The address of the underlying asset borrowed
   * @param user The address of the user to be rebalanced
   **/
  function rebalanceStableBorrowRate(address asset, address user) external;

  /**
   * @notice Allows suppliers to enable/disable a specific supplied asset as collateral
   * @param asset The address of the underlying asset supplied
   * @param useAsCollateral True if the user wants to use the supply as collateral, false otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @notice Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken True if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
   * @param assets The addresses of the assets being flash-borrowed
   * @param amounts The amounts of the assets being flash-borrowed
   * @param modes Types of the debt to open if the flash loan is not returned:
   *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
   *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
   * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoan(
    address receiverAddress,
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Allows smartcontracts to access the liquidity of the pool within one transaction,
   * as long as the amount taken plus a fee is returned.
   * @dev IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
   * For further details please visit https://developers.aave.com
   * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanSimpleReceiver interface
   * @param asset The address of the asset being flash-borrowed
   * @param amount The amount of the asset being flash-borrowed
   * @param params Variadic packed params to pass to the receiver as extra information
   * @param referralCode The code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function flashLoanSimple(
    address receiverAddress,
    address asset,
    uint256 amount,
    bytes calldata params,
    uint16 referralCode
  ) external;

  /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralBase The total collateral of the user in the base currency used by the price feed
   * @return totalDebtBase The total debt of the user in the base currency used by the price feed
   * @return availableBorrowsBase The borrowing power left of the user in the base currency used by the price feed
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralBase,
      uint256 totalDebtBase,
      uint256 availableBorrowsBase,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  /**
   * @notice Initializes a reserve, activating it, assigning an aToken and debt tokens and an
   * interest rate strategy
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param aTokenAddress The address of the aToken that will be assigned to the reserve
   * @param stableDebtAddress The address of the StableDebtToken that will be assigned to the reserve
   * @param variableDebtAddress The address of the VariableDebtToken that will be assigned to the reserve
   * @param interestRateStrategyAddress The address of the interest rate strategy contract
   **/
  function initReserve(
    address asset,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external;

  /**
   * @notice Drop a reserve
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   **/
  function dropReserve(address asset) external;

  /**
   * @notice Updates the address of the interest rate strategy contract
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param rateStrategyAddress The address of the interest rate strategy contract
   **/
  function setReserveInterestRateStrategyAddress(address asset, address rateStrategyAddress)
    external;

  /**
   * @notice Sets the configuration bitmap of the reserve as a whole
   * @dev Only callable by the PoolConfigurator contract
   * @param asset The address of the underlying asset of the reserve
   * @param configuration The new configuration bitmap
   **/
  function setConfiguration(address asset, uint256 configuration) external;

  /**
   * @notice Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @notice Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @notice Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @notice Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @notice Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  /**
   * @notice Validates and finalizes an aToken transfer
   * @dev Only callable by the overlying aToken of the `asset`
   * @param asset The address of the underlying asset of the aToken
   * @param from The user from which the aTokens are transferred
   * @param to The user receiving the aTokens
   * @param amount The amount being transferred/withdrawn
   * @param balanceFromBefore The aToken balance of the `from` user before the transfer
   * @param balanceToBefore The aToken balance of the `to` user before the transfer
   */
  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromBefore,
    uint256 balanceToBefore
  ) external;

  /**
   * @notice Returns the list of the initialized reserves
   * @dev It does not include dropped reserves
   * @return The addresses of the reserves
   **/
  function getReservesList() external view returns (address[] memory);

  /**
   * @notice Returns the cached PoolAddressesProvider connected to this contract
   * @return The address of the PoolAddressesProvider
   **/
  function getAddressesProvider() external view returns (IPoolAddressesProvider);

  /**
   * @notice Updates the protocol fee on the bridging
   * @param bridgeProtocolFee The part of the premium sent to protocol
   */
  function updateBridgeProtocolFee(uint256 bridgeProtocolFee) external;

  /**
   * @notice Updates flash loan premiums. Flash loan premium consist in 2 parts
   * - A part is sent to aToken holders as extra balance
   * - A part is collected by the protocol reserves
   * @dev Only callable by the PoolConfigurator contract
   * @param flashLoanPremiumTotal The total premium in bps
   * @param flashLoanPremiumToProtocol The part of the premium sent to protocol
   */
  function updateFlashloanPremiums(
    uint256 flashLoanPremiumTotal,
    uint256 flashLoanPremiumToProtocol
  ) external;

  /**
   * @notice Configures a new category for the eMode.
   * @dev In eMode, the protocol allows very high borrowing power to borrow assets of the same category.
   * The category 0 is reserved as it's the default for volatile assets
   * @param id The id of the category
   * @param config The configuration of the category
   */
  function configureEModeCategory(uint8 id, DataTypes.EModeCategory memory config) external;

  /**
   * @notice Returns the data of an eMode category
   * @param id The id of the category
   * @return The configuration data of the category
   */
  function getEModeCategoryData(uint8 id) external view returns (DataTypes.EModeCategory memory);

  /**
   * @notice Allows a user to use the protocol in eMode
   * @param categoryId The id of the category
   */
  function setUserEMode(uint8 categoryId) external;

  /**
   * @notice Returns the eMode the user is using
   * @param user The address of the user
   * @return The eMode id
   */
  function getUserEMode(address user) external view returns (uint256);

  /**
   * @notice Returns the percentage of available liquidity that can be borrowed at once at stable rate
   * @return The percentage of available liquidity to borrow
   */
  function MAX_STABLE_RATE_BORROW_SIZE_PERCENT() external view returns (uint256);

  /**
   * @notice Returns the total fee on flash loans
   * @return The total fee on flashloans
   */
  function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

  /**
   * @notice Returns the part of the bridge fees sent to protocol
   * @return The bridge fee sent to the protocol
   */
  function BRIDGE_PROTOCOL_FEE() external view returns (uint256);

  /**
   * @notice Returns the part of the flashloan fees sent to protocol
   * @return The flashloan fee sent to the protocol
   */
  function FLASHLOAN_PREMIUM_TO_PROTOCOL() external view returns (uint256);

  /**
   * @notice Returns the maximum number of reserves supported to be listed in this Pool
   * @return The maximum number of reserves supported
   */
  function MAX_NUMBER_RESERVES() external view returns (uint256);

  /**
   * @notice Mints the assets accrued through the reserve factor to the treasury in the form of aTokens
   * @param assets The list of reserves for which the minting needs to be executed
   **/
  function mintToTreasury(address[] calldata assets) external;

  /**
   * @notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User supplies 100 USDC and gets in return 100 aUSDC
   * @dev Deprecated: Use the `supply` function instead
   * @param asset The address of the underlying asset to supply
   * @param amount The amount to be supplied
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title IPoolAddressesProvider
 * @author Aave
 * @notice Defines the basic interface for a Pool Addresses Provider.
 **/
interface IPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event PoolUpdated(address indexed newAddress);
  event PoolConfiguratorUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event ACLManagerUpdated(address indexed newAddress);
  event ACLAdminUpdated(address indexed newAddress);
  event PriceOracleSentinelUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event BridgeAccessControlUpdated(address indexed newAddress);
  event PoolDataProviderUpdated(address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  /**
   * @notice Returns the id of the Aave market to which this contract points to
   * @return The market id
   **/
  function getMarketId() external view returns (string memory);

  /**
   * @notice Allows to set the market which this PoolAddressesProvider represents
   * @param marketId The market id
   */
  function setMarketId(string calldata marketId) external;

  /**
   * @notice Sets an address for an id replacing the address saved in the addresses map
   * @dev IMPORTANT Use this function carefully, as it will do a hard replacement
   * @param id The id
   * @param newAddress The address to set
   */
  function setAddress(bytes32 id, address newAddress) external;

  /**
   * @notice General function to update the implementation of a proxy registered with
   * certain `id`. If there is no proxy registered, it will instantiate one and
   * set as implementation the `impl`
   * @dev IMPORTANT Use this function carefully, only for ids that don't have an explicit
   * setter function, in order to avoid unexpected consequences
   * @param id The id
   * @param impl The address of the new implementation
   */
  function setAddressAsProxy(bytes32 id, address impl) external;

  /**
   * @notice Returns an address by id
   * @return The address
   */
  function getAddress(bytes32 id) external view returns (address);

  /**
   * @notice Returns the address of the Pool proxy
   * @return The Pool proxy address
   **/
  function getPool() external view returns (address);

  /**
   * @notice Updates the implementation of the Pool, or creates the proxy
   * setting the new `pool` implementation on the first time calling it
   * @param pool The new Pool implementation
   **/
  function setPoolImpl(address pool) external;

  /**
   * @notice Returns the address of the PoolConfigurator proxy
   * @return The PoolConfigurator proxy address
   **/
  function getPoolConfigurator() external view returns (address);

  /**
   * @notice Updates the implementation of the PoolConfigurator, or creates the proxy
   * setting the new `configurator` implementation on the first time calling it
   * @param configurator The new PoolConfigurator implementation
   **/
  function setPoolConfiguratorImpl(address configurator) external;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external;

  /**
   * @notice Returns the address of the ACL manager proxy
   * @return The ACLManager proxy address
   */
  function getACLManager() external view returns (address);

  /**
   * @notice Updates the address of the ACLManager
   * @param aclManager The address of the new ACLManager
   **/
  function setACLManager(address aclManager) external;

  /**
   * @notice Returns the address of the ACL admin
   * @return The address of the ACL admin
   */
  function getACLAdmin() external view returns (address);

  /**
   * @notice Updates the address of the ACL admin
   * @param aclAdmin The address of the new ACL admin
   */
  function setACLAdmin(address aclAdmin) external;

  /**
   * @notice Returns the address of the PriceOracleSentinel
   * @return The PriceOracleSentinel address
   */
  function getPriceOracleSentinel() external view returns (address);

  /**
   * @notice Updates the address of the PriceOracleSentinel
   * @param oracleSentinel The address of the new PriceOracleSentinel
   **/
  function setPriceOracleSentinel(address oracleSentinel) external;

  /**
   * @notice Updates the address of the DataProvider
   * @param dataProvider The address of the new DataProvider
   **/
  function setPoolDataProvider(address dataProvider) external;

  /**
   * @notice Returns the address of the DataProvider
   * @return The DataProvider address
   */
  function getPoolDataProvider() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {BaseUpgradeabilityProxy} from '../../../dependencies/openzeppelin/upgradeability/BaseUpgradeabilityProxy.sol';

/**
 * @title BaseImmutableAdminUpgradeabilityProxy
 * @author Aave, inspired by the OpenZeppelin upgradeability proxy pattern
 * @notice This contract combines an upgradeability proxy with an authorization
 * mechanism for administrative tasks.
 * @dev The admin role is stored in an immutable, which helps saving transactions costs
 * All external functions in this contract must be guarded by the
 * `ifAdmin` modifier. See ethereum/solidity#3864 for a Solidity
 * feature proposal that would enable this to be done automatically.
 */
contract BaseImmutableAdminUpgradeabilityProxy is BaseUpgradeabilityProxy {
  address immutable ADMIN;

  constructor(address admin) {
    ADMIN = admin;
  }

  modifier ifAdmin() {
    if (msg.sender == ADMIN) {
      _;
    } else {
      _fallback();
    }
  }

  /**
   * @notice Return the admin address
   * @return The address of the proxy admin.
   */
  function admin() external ifAdmin returns (address) {
    return ADMIN;
  }

  /**
   * @notice Return the implementation address
   * @return The address of the implementation.
   */
  function implementation() external ifAdmin returns (address) {
    return _implementation();
  }

  /**
   * @notice Upgrade the backing implementation of the proxy.
   * @dev Only the admin can call this function.
   * @param newImplementation The address of the new implementation.
   */
  function upgradeTo(address newImplementation) external ifAdmin {
    _upgradeTo(newImplementation);
  }

  /**
   * @notice Upgrade the backing implementation of the proxy and call a function
   * on the new implementation.
   * @dev This is useful to initialize the proxied contract.
   * @param newImplementation The address of the new implementation.
   * @param data Data to send as msg.data in the low level call.
   * It should include the signature and the parameters of the function to be called, as described in
   * https://solidity.readthedocs.io/en/v0.4.24/abi-spec.html#function-selector-and-argument-encoding.
   */
  function upgradeToAndCall(address newImplementation, bytes calldata data)
    external
    payable
    ifAdmin
  {
    _upgradeTo(newImplementation);
    (bool success, ) = newImplementation.delegatecall(data);
    require(success);
  }

  /**
   * @notice Only fall back when the sender is not the admin.
   */
  function _willFallback() internal virtual override {
    require(msg.sender != ADMIN, 'Cannot call fallback function from the proxy admin');
    super._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {InitializableUpgradeabilityProxy} from '../../../dependencies/openzeppelin/upgradeability/InitializableUpgradeabilityProxy.sol';
import {Proxy} from '../../../dependencies/openzeppelin/upgradeability/Proxy.sol';
import {BaseImmutableAdminUpgradeabilityProxy} from './BaseImmutableAdminUpgradeabilityProxy.sol';

/**
 * @title InitializableAdminUpgradeabilityProxy
 * @author Aave
 * @dev Extends BaseAdminUpgradeabilityProxy with an initializer function
 */
contract InitializableImmutableAdminUpgradeabilityProxy is
  BaseImmutableAdminUpgradeabilityProxy,
  InitializableUpgradeabilityProxy
{
  constructor(address admin) BaseImmutableAdminUpgradeabilityProxy(admin) {}

  /// @inheritdoc BaseImmutableAdminUpgradeabilityProxy
  function _willFallback() internal override(BaseImmutableAdminUpgradeabilityProxy, Proxy) {
    BaseImmutableAdminUpgradeabilityProxy._willFallback();
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {Errors} from '../helpers/Errors.sol';
import {DataTypes} from '../types/DataTypes.sol';

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
  uint256 constant LTV_MASK =                       0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
  uint256 constant LIQUIDATION_THRESHOLD_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
  uint256 constant LIQUIDATION_BONUS_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
  uint256 constant DECIMALS_MASK =                  0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
  uint256 constant ACTIVE_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant FROZEN_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWING_MASK =                 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant STABLE_BORROWING_MASK =          0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant PAUSED_MASK =                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROWABLE_IN_ISOLATION_MASK =   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant RESERVE_FACTOR_MASK =            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant BORROW_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant SUPPLY_CAP_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant LIQUIDATION_PROTOCOL_FEE_MASK =  0xFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant EMODE_CATEGORY_MASK =            0xFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant UNBACKED_MINT_CAP_MASK =         0xFFFFFFFFFFF000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore
  uint256 constant DEBT_CEILING_MASK =              0xF0000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

  /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
  uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
  uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
  uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
  uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
  uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
  uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
  uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
  uint256 constant IS_PAUSED_START_BIT_POSITION = 60;
  uint256 constant BORROWABLE_IN_ISOLATION_START_BIT_POSITION = 61;
  /// @dev bits 62 63 reserved

  uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;
  uint256 constant BORROW_CAP_START_BIT_POSITION = 80;
  uint256 constant SUPPLY_CAP_START_BIT_POSITION = 116;
  uint256 constant LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION = 152;
  uint256 constant EMODE_CATEGORY_START_BIT_POSITION = 168;
  uint256 constant UNBACKED_MINT_CAP_START_BIT_POSITION = 176;
  uint256 constant DEBT_CEILING_START_BIT_POSITION = 212;

  uint256 constant MAX_VALID_LTV = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
  uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
  uint256 constant MAX_VALID_DECIMALS = 255;
  uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;
  uint256 constant MAX_VALID_BORROW_CAP = 68719476735;
  uint256 constant MAX_VALID_SUPPLY_CAP = 68719476735;
  uint256 constant MAX_VALID_LIQUIDATION_PROTOCOL_FEE = 10000;
  uint256 constant MAX_VALID_EMODE_CATEGORY = 255;
  uint256 constant MAX_VALID_UNBACKED_MINT_CAP = 68719476735;
  uint256 constant MAX_VALID_DEBT_CEILING = 1099511627775;

  uint256 public constant DEBT_CEILING_DECIMALS = 2;

  /**
   * @notice Sets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @param ltv The new ltv
   **/
  function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
    require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

    self.data = (self.data & LTV_MASK) | ltv;
  }

  /**
   * @notice Gets the Loan to Value of the reserve
   * @param self The reserve configuration
   * @return The loan to value
   **/
  function getLtv(DataTypes.ReserveConfigurationMap memory self) internal pure returns (uint256) {
    return self.data & ~LTV_MASK;
  }

  /**
   * @notice Sets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @param threshold The new liquidation threshold
   **/
  function setLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self, uint256 threshold)
    internal
    pure
  {
    require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

    self.data =
      (self.data & LIQUIDATION_THRESHOLD_MASK) |
      (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation threshold of the reserve
   * @param self The reserve configuration
   * @return The liquidation threshold
   **/
  function getLiquidationThreshold(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @param bonus The new liquidation bonus
   **/
  function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
    internal
    pure
  {
    require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

    self.data =
      (self.data & LIQUIDATION_BONUS_MASK) |
      (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the liquidation bonus of the reserve
   * @param self The reserve configuration
   * @return The liquidation bonus
   **/
  function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self)
    internal
    view
    returns (uint256)
  {
    return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @param decimals The decimals
   **/
  function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
    internal
    pure
  {
    require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

    self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
  }

  /**
   * @notice Gets the decimals of the underlying asset of the reserve
   * @param self The reserve configuration
   * @return The decimals of the asset
   **/
  function getDecimals(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
  }

  /**
   * @notice Sets the active state of the reserve
   * @param self The reserve configuration
   * @param active The active state
   **/
  function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
    self.data =
      (self.data & ACTIVE_MASK) |
      (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
  }

  /**
   * @notice Gets the active state of the reserve
   * @param self The reserve configuration
   * @return The active state
   **/
  function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~ACTIVE_MASK) != 0;
  }

  /**
   * @notice Sets the frozen state of the reserve
   * @param self The reserve configuration
   * @param frozen The frozen state
   **/
  function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
    self.data =
      (self.data & FROZEN_MASK) |
      (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
  }

  /**
   * @notice Gets the frozen state of the reserve
   * @param self The reserve configuration
   * @return The frozen state
   **/
  function getFrozen(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~FROZEN_MASK) != 0;
  }

  /**
   * @notice Sets the paused state of the reserve
   * @param self The reserve configuration
   * @param paused The paused state
   **/
  function setPaused(DataTypes.ReserveConfigurationMap memory self, bool paused) internal pure {
    self.data =
      (self.data & PAUSED_MASK) |
      (uint256(paused ? 1 : 0) << IS_PAUSED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the paused state of the reserve
   * @param self The reserve configuration
   * @return The paused state
   **/
  function getPaused(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
    return (self.data & ~PAUSED_MASK) != 0;
  }

  /**
   * @notice Sets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed amount will be accumulated in the isolated collateral's total debt exposure.
   * Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @param borrowable True if the asset is borrowable
   **/
  function setBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self, bool borrowable)
    internal
    pure
  {
    self.data =
      (self.data & BORROWABLE_IN_ISOLATION_MASK) |
      (uint256(borrowable ? 1 : 0) << BORROWABLE_IN_ISOLATION_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowable in isolation flag for the reserve.
   * @dev When this flag is set to true, the asset will be borrowable against isolated collaterals and the borrowed amount will be accumulated in the isolated collateral's total debt exposure.
   * Only assets of the same family (eg USD stablecoins) should be borrowable in isolation mode to keep consistency in the debt ceiling calculations.
   * @param self The reserve configuration
   * @return The borrowable in isolation flag
   **/
  function getBorrowableInIsolation(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
  }

  /**
   * @notice Enables or disables borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the borrowing needs to be enabled, false otherwise
   **/
  function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
    internal
    pure
  {
    self.data =
      (self.data & BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrowing state of the reserve
   * @param self The reserve configuration
   * @return The borrowing state
   **/
  function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~BORROWING_MASK) != 0;
  }

  /**
   * @notice Enables or disables stable rate borrowing on the reserve
   * @param self The reserve configuration
   * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
   **/
  function setStableRateBorrowingEnabled(
    DataTypes.ReserveConfigurationMap memory self,
    bool enabled
  ) internal pure {
    self.data =
      (self.data & STABLE_BORROWING_MASK) |
      (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
  }

  /**
   * @notice Gets the stable rate borrowing state of the reserve
   * @param self The reserve configuration
   * @return The stable rate borrowing state
   **/
  function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (bool)
  {
    return (self.data & ~STABLE_BORROWING_MASK) != 0;
  }

  /**
   * @notice Sets the reserve factor of the reserve
   * @param self The reserve configuration
   * @param reserveFactor The reserve factor
   **/
  function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
    internal
    pure
  {
    require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

    self.data =
      (self.data & RESERVE_FACTOR_MASK) |
      (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
  }

  /**
   * @notice Gets the reserve factor of the reserve
   * @param self The reserve configuration
   * @return The reserve factor
   **/
  function getReserveFactor(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
  }

  /**
   * @notice Sets the borrow cap of the reserve
   * @param self The reserve configuration
   * @param borrowCap The borrow cap
   **/
  function setBorrowCap(DataTypes.ReserveConfigurationMap memory self, uint256 borrowCap)
    internal
    pure
  {
    require(borrowCap <= MAX_VALID_BORROW_CAP, Errors.RC_INVALID_BORROW_CAP);

    self.data = (self.data & BORROW_CAP_MASK) | (borrowCap << BORROW_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the borrow cap of the reserve
   * @param self The reserve configuration
   * @return The borrow cap
   **/
  function getBorrowCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the supply cap of the reserve
   * @param self The reserve configuration
   * @param supplyCap The supply cap
   **/
  function setSupplyCap(DataTypes.ReserveConfigurationMap memory self, uint256 supplyCap)
    internal
    pure
  {
    require(supplyCap <= MAX_VALID_SUPPLY_CAP, Errors.RC_INVALID_SUPPLY_CAP);

    self.data = (self.data & SUPPLY_CAP_MASK) | (supplyCap << SUPPLY_CAP_START_BIT_POSITION);
  }

  /**
   * @notice Gets the supply cap of the reserve
   * @param self The reserve configuration
   * @return The supply cap
   **/
  function getSupplyCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION;
  }

  /**
   * @notice Sets the debt ceiling in isolation mode for the asset
   * @param self The reserve configuration
   * @param ceiling The maximum debt ceiling for the asset
   **/
  function setDebtCeiling(DataTypes.ReserveConfigurationMap memory self, uint256 ceiling)
    internal
    pure
  {
    require(ceiling <= MAX_VALID_DEBT_CEILING, Errors.RC_INVALID_DEBT_CEILING);

    self.data = (self.data & DEBT_CEILING_MASK) | (ceiling << DEBT_CEILING_START_BIT_POSITION);
  }

  /**
   * @notice Gets the debt ceiling for the asset if the asset is in isolation mode
   * @param self The reserve configuration
   * @return The debt ceiling (0 = isolation mode disabled)
   **/
  function getDebtCeiling(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~DEBT_CEILING_MASK) >> DEBT_CEILING_START_BIT_POSITION;
  }

  /**
   * @notice Sets the liquidation protocol fee of the reserve
   * @param self The reserve configuration
   * @param liquidationProtocolFee The liquidation protocol fee
   **/
  function setLiquidationProtocolFee(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 liquidationProtocolFee
  ) internal pure {
    require(
      liquidationProtocolFee <= MAX_VALID_LIQUIDATION_PROTOCOL_FEE,
      Errors.RC_INVALID_LIQUIDATION_PROTOCOL_FEE
    );

    self.data =
      (self.data & LIQUIDATION_PROTOCOL_FEE_MASK) |
      (liquidationProtocolFee << LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION);
  }

  /**
   * @dev Gets the liquidation protocol fee
   * @param self The reserve configuration
   * @return The liquidation protocol fee
   **/
  function getLiquidationProtocolFee(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return
      (self.data & ~LIQUIDATION_PROTOCOL_FEE_MASK) >> LIQUIDATION_PROTOCOL_FEE_START_BIT_POSITION;
  }

  /**
   * @notice Sets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @param unbackedMintCap The unbacked mint cap
   **/
  function setUnbackedMintCap(
    DataTypes.ReserveConfigurationMap memory self,
    uint256 unbackedMintCap
  ) internal pure {
    require(unbackedMintCap <= MAX_VALID_UNBACKED_MINT_CAP, Errors.RC_INVALID_UNBACKED_MINT_CAP);

    self.data =
      (self.data & UNBACKED_MINT_CAP_MASK) |
      (unbackedMintCap << UNBACKED_MINT_CAP_START_BIT_POSITION);
  }

  /**
   * @dev Gets the unbacked mint cap of the reserve
   * @param self The reserve configuration
   * @return The unbacked mint cap
   **/
  function getUnbackedMintCap(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~UNBACKED_MINT_CAP_MASK) >> UNBACKED_MINT_CAP_START_BIT_POSITION;
  }

  /*
   * @notice Sets the eMode asset category
   * @param self The reserve configuration
   * @param category The asset category when the user selects the eMode
   **/
  function setEModeCategory(DataTypes.ReserveConfigurationMap memory self, uint256 category)
    internal
    pure
  {
    require(category <= MAX_VALID_EMODE_CATEGORY, Errors.RC_INVALID_EMODE_CATEGORY);

    self.data = (self.data & EMODE_CATEGORY_MASK) | (category << EMODE_CATEGORY_START_BIT_POSITION);
  }

  /**
   * @dev Gets the eMode asset category
   * @param self The reserve configuration
   * @return The eMode category for the asset
   **/
  function getEModeCategory(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256)
  {
    return (self.data & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION;
  }

  /**
   * @notice Gets the configuration flags of the reserve
   * @param self The reserve configuration
   * @return The state flag representing active
   * @return The state flag representing frozen
   * @return The state flag representing borrowing enabled
   * @return The state flag representing stabelRateBorrowing enabled
   * @return The state flag representing paused
   **/
  function getFlags(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      bool,
      bool,
      bool,
      bool,
      bool
    )
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~ACTIVE_MASK) != 0,
      (dataLocal & ~FROZEN_MASK) != 0,
      (dataLocal & ~BORROWING_MASK) != 0,
      (dataLocal & ~STABLE_BORROWING_MASK) != 0,
      (dataLocal & ~PAUSED_MASK) != 0
    );
  }

  /**
   * @notice Gets the configuration paramters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing ltv
   * @return The state param representing liquidation threshold
   * @return The state param representing liquidation bonus
   * @return The state param representing reserve decimals
   * @return The state param representing reserve factor
   * @return The state param representing eMode category
   **/
  function getParams(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 dataLocal = self.data;

    return (
      dataLocal & ~LTV_MASK,
      (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
      (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
      (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
      (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION,
      (dataLocal & ~EMODE_CATEGORY_MASK) >> EMODE_CATEGORY_START_BIT_POSITION
    );
  }

  /**
   * @notice Gets the caps  paramters of the reserve from storage
   * @param self The reserve configuration
   * @return The state param representing borrow cap
   * @return The state param representing supply cap.
   **/
  function getCaps(DataTypes.ReserveConfigurationMap memory self)
    internal
    pure
    returns (uint256, uint256)
  {
    uint256 dataLocal = self.data;

    return (
      (dataLocal & ~BORROW_CAP_MASK) >> BORROW_CAP_START_BIT_POSITION,
      (dataLocal & ~SUPPLY_CAP_MASK) >> SUPPLY_CAP_START_BIT_POSITION
    );
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - P = Pool
 *  - PAPR = PoolAddressesProviderRegistry
 *  - PC = PoolConfiguration
 *  - RL = ReserveLogic
 *  - P = Pausable
 */
library Errors {
  //common errors
  string public constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'

  //contract specific errors
  string public constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string public constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string public constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string public constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string public constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string public constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string public constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of a user an explicit amount to repay is needed'
  string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string public constant VL_SUPPLIED_ASSETS_ALREADY_IN_USE = '20'; // 'User supplied assets are already being used as collateral'
  string public constant P_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string public constant P_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  string public constant P_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string public constant P_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string public constant P_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string public constant P_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string public constant P_CALLER_NOT_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the pool configurator'
  string public constant P_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string public constant CT_CALLER_MUST_BE_POOL = '29'; // 'The caller of this function must be a pool'
  string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string public constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string public constant PC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string public constant PC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string public constant PC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string public constant PAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string public constant VL_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string public constant VL_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string public constant VL_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  string public constant P_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string public constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string public constant MATH_ADDITION_OVERFLOW = '49';
  string public constant MATH_DIVISION_BY_ZERO = '50';
  string public constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string public constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string public constant P_REENTRANCY_NOT_ALLOWED = '62';
  string public constant P_CALLER_MUST_BE_AN_ATOKEN = '63';
  string public constant P_IS_PAUSED = '64'; // Deprecated 'Pool is paused'
  string public constant P_NO_MORE_RESERVES_ALLOWED = '65';
  string public constant P_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string public constant RC_INVALID_LTV = '67';
  string public constant RC_INVALID_LIQ_THRESHOLD = '68';
  string public constant RC_INVALID_LIQ_BONUS = '69';
  string public constant RC_INVALID_DECIMALS = '70';
  string public constant RC_INVALID_RESERVE_FACTOR = '71';
  string public constant PAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string public constant P_INCONSISTENT_PARAMS_LENGTH = '74';
  string public constant UL_INVALID_INDEX = '77';
  string public constant P_NOT_CONTRACT = '78';
  string public constant SDT_STABLE_DEBT_OVERFLOW = '79'; // Deprecated moved to general `HLP_UINT128_OVERFLOW`
  string public constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string public constant VL_BORROW_CAP_EXCEEDED = '81';
  string public constant RC_INVALID_BORROW_CAP = '82';
  string public constant VL_SUPPLY_CAP_EXCEEDED = '83';
  string public constant RC_INVALID_SUPPLY_CAP = '84';
  string public constant PC_CALLER_NOT_EMERGENCY_OR_POOL_ADMIN = '85';
  string public constant VL_RESERVE_PAUSED = '86';
  string public constant PC_CALLER_NOT_RISK_OR_POOL_ADMIN = '87';
  string public constant RL_ATOKEN_SUPPLY_NOT_ZERO = '88';
  string public constant RL_STABLE_DEBT_NOT_ZERO = '89';
  string public constant RL_VARIABLE_DEBT_SUPPLY_NOT_ZERO = '90';
  string public constant VL_LTV_VALIDATION_FAILED = '93';
  string public constant VL_SAME_BLOCK_BORROW_REPAY = '94';
  string public constant PC_FLASHLOAN_PREMIUMS_MISMATCH = '95';
  string public constant PC_FLASHLOAN_PREMIUM_INVALID = '96';
  string public constant RC_INVALID_LIQUIDATION_PROTOCOL_FEE = '97';
  string public constant RC_INVALID_EMODE_CATEGORY = '98';
  string public constant VL_INCONSISTENT_EMODE_CATEGORY = '99';
  string public constant HLP_UINT128_OVERFLOW = '100';
  string public constant PC_CALLER_NOT_ASSET_LISTING_OR_POOL_ADMIN = '101';
  string public constant P_CALLER_NOT_BRIDGE = '102';
  string public constant RC_INVALID_UNBACKED_MINT_CAP = '103';
  string public constant VL_UNBACKED_MINT_CAP_EXCEEDED = '104';
  string public constant VL_PRICE_ORACLE_SENTINEL_CHECK_FAILED = '105';
  string public constant RC_INVALID_DEBT_CEILING = '106';
  string public constant VL_ASSET_NOT_BORROWABLE_IN_ISOLATION = '107';
  string public constant VL_DEBT_CEILING_CROSSED = '108';
  string public constant SL_USER_IN_ISOLATION_MODE = '109';
  string public constant PC_BRIDGE_PROTOCOL_FEE_INVALID = '110';
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

import {IPool} from '../../../interfaces/IPool.sol';
import {IInitializableAToken} from '../../../interfaces/IInitializableAToken.sol';
import {IInitializableDebtToken} from '../../../interfaces/IInitializableDebtToken.sol';
import {IAaveIncentivesController} from '../../../interfaces/IAaveIncentivesController.sol';
import {InitializableImmutableAdminUpgradeabilityProxy} from '../aave-upgradeability/InitializableImmutableAdminUpgradeabilityProxy.sol';
import {ReserveConfiguration} from '../configuration/ReserveConfiguration.sol';
import {DataTypes} from '../types/DataTypes.sol';
import {ConfiguratorInputTypes} from '../types/ConfiguratorInputTypes.sol';

/**
 * @title ConfiguratorLogic library
 * @author Aave
 * @notice Implements the functions to initialize reserves and update atokens/debt tokens
 */
library ConfiguratorLogic {
  using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

  // See `IPoolConfigurator` for description
  event ReserveInitialized(
    address indexed asset,
    address indexed aToken,
    address stableDebtToken,
    address variableDebtToken,
    address interestRateStrategyAddress
  );

  // See `IPoolConfigurator` for description
  event ATokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  // See `IPoolConfigurator` for description
  event StableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  // See `IPoolConfigurator` for description
  event VariableDebtTokenUpgraded(
    address indexed asset,
    address indexed proxy,
    address indexed implementation
  );

  function initReserve(IPool pool, ConfiguratorInputTypes.InitReserveInput calldata input) public {
    address aTokenProxyAddress = _initTokenWithProxy(
      input.aTokenImpl,
      abi.encodeWithSelector(
        IInitializableAToken.initialize.selector,
        input.treasury,
        input.underlyingAsset,
        IAaveIncentivesController(input.incentivesController),
        input.underlyingAssetDecimals,
        input.aTokenName,
        input.aTokenSymbol,
        input.params
      )
    );

    address stableDebtTokenProxyAddress = _initTokenWithProxy(
      input.stableDebtTokenImpl,
      abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        input.underlyingAsset,
        IAaveIncentivesController(input.incentivesController),
        input.underlyingAssetDecimals,
        input.stableDebtTokenName,
        input.stableDebtTokenSymbol,
        input.params
      )
    );

    address variableDebtTokenProxyAddress = _initTokenWithProxy(
      input.variableDebtTokenImpl,
      abi.encodeWithSelector(
        IInitializableDebtToken.initialize.selector,
        input.underlyingAsset,
        IAaveIncentivesController(input.incentivesController),
        input.underlyingAssetDecimals,
        input.variableDebtTokenName,
        input.variableDebtTokenSymbol,
        input.params
      )
    );

    pool.initReserve(
      input.underlyingAsset,
      aTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );

    DataTypes.ReserveConfigurationMap memory currentConfig = pool.getConfiguration(
      input.underlyingAsset
    );

    currentConfig.setDecimals(input.underlyingAssetDecimals);

    currentConfig.setActive(true);
    currentConfig.setPaused(false);
    currentConfig.setFrozen(false);

    pool.setConfiguration(input.underlyingAsset, currentConfig.data);

    emit ReserveInitialized(
      input.underlyingAsset,
      aTokenProxyAddress,
      stableDebtTokenProxyAddress,
      variableDebtTokenProxyAddress,
      input.interestRateStrategyAddress
    );
  }

  function updateAToken(IPool cachedPool, ConfiguratorInputTypes.UpdateATokenInput calldata input)
    public
  {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableAToken.initialize.selector,
      input.treasury,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(reserveData.aTokenAddress, input.implementation, encodedCall);

    emit ATokenUpgraded(input.asset, reserveData.aTokenAddress, input.implementation);
  }

  function updateStableDebtToken(
    IPool cachedPool,
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableDebtToken.initialize.selector,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(
      reserveData.stableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit StableDebtTokenUpgraded(
      input.asset,
      reserveData.stableDebtTokenAddress,
      input.implementation
    );
  }

  function updateVariableDebtToken(
    IPool cachedPool,
    ConfiguratorInputTypes.UpdateDebtTokenInput calldata input
  ) public {
    DataTypes.ReserveData memory reserveData = cachedPool.getReserveData(input.asset);

    (, , , uint256 decimals, , ) = cachedPool.getConfiguration(input.asset).getParams();

    bytes memory encodedCall = abi.encodeWithSelector(
      IInitializableDebtToken.initialize.selector,
      input.asset,
      input.incentivesController,
      decimals,
      input.name,
      input.symbol,
      input.params
    );

    _upgradeTokenImplementation(
      reserveData.variableDebtTokenAddress,
      input.implementation,
      encodedCall
    );

    emit VariableDebtTokenUpgraded(
      input.asset,
      reserveData.variableDebtTokenAddress,
      input.implementation
    );
  }

  function _initTokenWithProxy(address implementation, bytes memory initParams)
    internal
    returns (address)
  {
    InitializableImmutableAdminUpgradeabilityProxy proxy = new InitializableImmutableAdminUpgradeabilityProxy(
        address(this)
      );

    proxy.initialize(implementation, initParams);

    return address(proxy);
  }

  function _upgradeTokenImplementation(
    address proxyAddress,
    address implementation,
    bytes memory initParams
  ) internal {
    InitializableImmutableAdminUpgradeabilityProxy proxy = InitializableImmutableAdminUpgradeabilityProxy(
        payable(proxyAddress)
      );

    proxy.upgradeToAndCall(implementation, initParams);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

library ConfiguratorInputTypes {
  struct InitReserveInput {
    address aTokenImpl;
    address stableDebtTokenImpl;
    address variableDebtTokenImpl;
    uint8 underlyingAssetDecimals;
    address interestRateStrategyAddress;
    address underlyingAsset;
    address treasury;
    address incentivesController;
    string underlyingAssetName;
    string aTokenName;
    string aTokenSymbol;
    string variableDebtTokenName;
    string variableDebtTokenSymbol;
    string stableDebtTokenName;
    string stableDebtTokenSymbol;
    bytes params;
  }

  struct UpdateATokenInput {
    address asset;
    address treasury;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }

  struct UpdateDebtTokenInput {
    address asset;
    address incentivesController;
    string name;
    string symbol;
    address implementation;
    bytes params;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.7;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the quickwithdraw balance waiting for underlying to be backed
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap, borrowCap == 0 => disabled
    //bit 116-151 supply cap, supplyCap == 0 => disabled
    //bit 80-115 borrow cap, borrowCap == 0 => disabled
    //bit 116-151 supply cap, supplyCap == 0 => disabled
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap, unbackedMintCap == 0 => disabled
    //bit 212-251 debt ceiling

    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }

  struct ReserveCache {
    uint256 currScaledVariableDebt;
    uint256 nextScaledVariableDebt;
    uint256 currPrincipalStableDebt;
    uint256 currAvgStableBorrowRate;
    uint256 currTotalStableDebt;
    uint256 nextAvgStableBorrowRate;
    uint256 nextTotalStableDebt;
    uint256 currLiquidityIndex;
    uint256 nextLiquidityIndex;
    uint256 currVariableBorrowIndex;
    uint256 nextVariableBorrowIndex;
    uint256 currLiquidityRate;
    uint256 currVariableBorrowRate;
    uint256 reserveFactor;
    DataTypes.ReserveConfigurationMap reserveConfiguration;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    uint40 reserveLastUpdateTimestamp;
    uint40 stableDebtLastUpdateTimestamp;
  }

  struct ExecuteLiquidationCallParams {
    uint256 reservesCount;
    uint256 debtToCover;
    address collateralAsset;
    address debtAsset;
    address user;
    bool receiveAToken;
    address priceOracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteSupplyParams {
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBorrowParams {
    address asset;
    address user;
    address onBehalfOf;
    uint256 amount;
    uint256 interestRateMode;
    uint16 referralCode;
    bool releaseUnderlying;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
  }

  struct ExecuteRepayParams {
    address asset;
    uint256 amount;
    uint256 rateMode;
    address onBehalfOf;
    bool useATokens;
  }

  struct ExecuteWithdrawParams {
    address asset;
    uint256 amount;
    address to;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ExecuteSetUserEModeParams {
    uint256 reservesCount;
    address oracle;
    uint8 categoryId;
  }

  struct FinalizeTransferParams {
    address asset;
    address from;
    address to;
    uint256 amount;
    uint256 balanceFromBefore;
    uint256 balanceToBefore;
    uint256 reservesCount;
    address oracle;
    uint8 fromEModeCategory;
    uint8 toEModeCategory;
  }

  struct FlashloanParams {
    address receiverAddress;
    address[] assets;
    uint256[] amounts;
    uint256[] modes;
    address onBehalfOf;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
    uint256 maxStableRateBorrowSizePercent;
    uint256 reservesCount;
    address addressesProvider;
    uint8 userEModeCategory;
    bool isAuthorizedFlashBorrower;
  }

  struct FlashloanSimpleParams {
    address receiverAddress;
    address asset;
    uint256 amount;
    bytes params;
    uint16 referralCode;
    uint256 flashLoanPremiumToProtocol;
    uint256 flashLoanPremiumTotal;
  }

  struct CalculateUserAccountDataParams {
    UserConfigurationMap userConfig;
    uint256 reservesCount;
    address user;
    address oracle;
    uint8 userEModeCategory;
  }

  struct ValidateBorrowParams {
    DataTypes.ReserveCache reserveCache;
    DataTypes.UserConfigurationMap userConfig;
    address asset;
    address userAddress;
    uint256 amount;
    uint256 interestRateMode;
    uint256 maxStableLoanPercent;
    uint256 reservesCount;
    address oracle;
    uint8 userEModeCategory;
    address priceOracleSentinel;
    bool isolationModeActive;
    address isolationModeCollateralAddress;
    uint256 isolationModeDebtCeiling;
  }

  struct ValidateLiquidationCallParams {
    DataTypes.ReserveCache debtReserveCache;
    uint256 totalDebt;
    uint256 healthFactor;
    address priceOracleSentinel;
  }

  struct CalculateInterestRatesParams {
    uint256 unbacked;
    uint256 liquidityAdded;
    uint256 liquidityTaken;
    uint256 totalStableDebt;
    uint256 totalVariableDebt;
    uint256 averageStableBorrowRate;
    uint256 reserveFactor;
    address reserve;
    address aToken;
  }
}