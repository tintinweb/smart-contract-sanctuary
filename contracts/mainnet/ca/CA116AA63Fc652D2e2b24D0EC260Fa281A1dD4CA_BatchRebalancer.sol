// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./interfaces/INirnVault.sol";
import "./interfaces/IAdapterRegistry.sol";


contract BatchRebalancer {
  bytes4 internal constant rebalance = INirnVault.rebalance.selector;
  bytes4 internal constant rebalanceWithNewWeights = INirnVault.rebalanceWithNewWeights.selector;
  bytes4 internal constant rebalanceWithNewAdapters = INirnVault.rebalanceWithNewAdapters.selector;

  IAdapterRegistry public immutable registry;

  constructor(address _registry) {
    registry = IAdapterRegistry(_registry);
  }

  function revertWithReturnData(bytes memory _returnData) internal pure {
    // Taken from BoringCrypto
    // If the _res length is less than 68, then the transaction failed silently (without a revert message)
    if (_returnData.length < 68) revert("silent revert");

    assembly {
      // Slice the sighash.
      _returnData := add(_returnData, 0x04)
    }
    revert(abi.decode(_returnData, (string))); // All that remains is the revert string
  }

  function batchExecuteRebalance(address[] calldata vaults, bytes[] calldata calldatas) external {
    require(msg.sender == tx.origin, "!EOA");
    uint256 len = vaults.length;
    require(calldatas.length == len, "bad lengths");
    for (uint256 i; i < len; i++) {
      INirnVault vault = INirnVault(vaults[i]);
      require(
        registry.vaultsByUnderlying(vault.underlying()) == address(vault),
        "bad vault"
      );
      bytes memory data = calldatas[i];
      bytes4 sig;
      assembly { sig := mload(add(data, 32)) }
      require(
        sig == rebalance ||
        sig == rebalanceWithNewWeights ||
        sig == rebalanceWithNewAdapters,
        "fn not allowed"
      );
      (bool success, bytes memory returnData) = address(vault).call(data);
      if (!success) revertWithReturnData(returnData);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IAdapterRegistry {
/* ========== Events ========== */

  event ProtocolAdapterAdded(uint256 protocolId, address protocolAdapter);

  event ProtocolAdapterRemoved(uint256 protocolId);

  event TokenAdapterAdded(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenAdapterRemoved(address adapter, uint256 protocolId, address underlying, address wrapper);

  event TokenSupportAdded(address underlying);

  event TokenSupportRemoved(address underlying);

  event VaultFactoryAdded(address factory);

  event VaultFactoryRemoved(address factory);

  event VaultAdded(address underlying, address vault);

  event VaultRemoved(address underlying, address vault);

/* ========== Structs ========== */

  struct TokenAdapter {
    address adapter;
    uint96 protocolId;
  }

/* ========== Storage ========== */

  function protocolsCount() external view returns (uint256);

  function protocolAdapters(uint256 id) external view returns (address protocolAdapter);

  function protocolAdapterIds(address protocolAdapter) external view returns (uint256 id);

  function vaultsByUnderlying(address underlying) external view returns (address vault);

  function approvedVaultFactories(address factory) external view returns (bool approved);

/* ========== Vault Factory Management ========== */

  function addVaultFactory(address _factory) external;

  function removeVaultFactory(address _factory) external;

/* ========== Vault Management ========== */

  function addVault(address vault) external;

  function removeVault(address vault) external;

/* ========== Protocol Adapter Management ========== */

  function addProtocolAdapter(address protocolAdapter) external returns (uint256 id);

  function removeProtocolAdapter(address protocolAdapter) external;

/* ========== Token Adapter Management ========== */

  function addTokenAdapter(address adapter) external;

  function addTokenAdapters(address[] calldata adapters) external;

  function removeTokenAdapter(address adapter) external;

/* ========== Vault Queries ========== */

  function getVaultsList() external view returns (address[] memory);

  function haveVaultFor(address underlying) external view returns (bool);

/* ========== Protocol Queries ========== */

  function getProtocolAdaptersAndIds() external view returns (address[] memory adapters, uint256[] memory ids);

  function getProtocolMetadata(uint256 id) external view returns (address protocolAdapter, string memory name);

  function getProtocolForTokenAdapter(address adapter) external view returns (address protocolAdapter);

/* ========== Supported Token Queries ========== */

  function isSupported(address underlying) external view returns (bool);

  function getSupportedTokens() external view returns (address[] memory list);

/* ========== Token Adapter Queries ========== */

  function isApprovedAdapter(address adapter) external view returns (bool);

  function getAdaptersList(address underlying) external view returns (address[] memory list);

  function getAdapterForWrapperToken(address wrapperToken) external view returns (address);

  function getAdaptersCount(address underlying) external view returns (uint256);

  function getAdaptersSortedByAPR(address underlying)
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdaptersSortedByAPRWithDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  )
    external
    view
    returns (address[] memory adapters, uint256[] memory aprs);

  function getAdapterWithHighestAPR(address underlying) external view returns (address adapter, uint256 apr);

  function getAdapterWithHighestAPRForDeposit(
    address underlying,
    uint256 deposit,
    address excludingAdapter
  ) external view returns (address adapter, uint256 apr);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./IAdapterRegistry.sol";
import "./ITokenAdapter.sol";
import "./IRewardsSeller.sol";


interface INirnVault {
/* ========== Events ========== */

  /** @dev Emitted when an adapter is removed and its balance fully withdrawn. */
  event AdapterRemoved(IErc20Adapter adapter);

  /** @dev Emitted when weights or adapters are updated. */
  event AllocationsUpdated(IErc20Adapter[] adapters, uint256[] weights);

  /** @dev Emitted when performance fees are claimed. */
  event FeesClaimed(uint256 underlyingAmount, uint256 sharesMinted);

  /** @dev Emitted when a rebalance happens without allocation changes. */
  event Rebalanced();

  /** @dev Emitted when max underlying is updated. */
  event SetMaximumUnderlying(uint256 maxBalance);

  /** @dev Emitted when fee recipient address is set. */
  event SetFeeRecipient(address feeRecipient);

  /** @dev Emitted when performance fee is set. */
  event SetPerformanceFee(uint256 performanceFee);

  /** @dev Emitted when reserve ratio is set. */
  event SetReserveRatio(uint256 reserveRatio);

  /** @dev Emitted when rewards seller contract is set. */
  event SetRewardsSeller(address rewardsSeller);

  /** @dev Emitted when a deposit is made. */
  event Deposit(uint256 shares, uint256 underlying);

  /** @dev Emitted when a deposit is made. */
  event Withdrawal(uint256 shares, uint256 underlying);

/* ========== Structs ========== */

  struct DistributionParameters {
    IErc20Adapter[] adapters;
    uint256[] weights;
    uint256[] balances;
    int256[] liquidityDeltas;
    uint256 netAPR;
  }

/* ========== Initializer ========== */

  function initialize(
    address _underlying,
    address _rewardsSeller,
    address _feeRecipient,
    address _owner
  ) external;

/* ========== Config Queries ========== */

  function minimumAPRImprovement() external view returns (uint256);

  function registry() external view returns (IAdapterRegistry);

  function eoaSafeCaller() external view returns (address);

  function underlying() external view returns (address);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);  

  function feeRecipient() external view returns (address);

  function rewardsSeller() external view returns (IRewardsSeller);

  function lockedTokens(address) external view returns (bool);

  function maximumUnderlying() external view returns (uint256);

  function performanceFee() external view returns (uint64);

  function reserveRatio() external view returns (uint64);

  function priceAtLastFee() external view returns (uint128);

  function minimumCompositionChangeDelay() external view returns (uint256);

  function canChangeCompositionAfter() external view returns (uint96);

/* ========== Admin Actions ========== */

  function setMaximumUnderlying(uint256 _maximumUnderlying) external;

  function setPerformanceFee(uint64 _performanceFee) external;

  function setFeeRecipient(address _feeRecipient) external;

  function setRewardsSeller(IRewardsSeller _rewardsSeller) external;

  function setReserveRatio(uint64 _reserveRatio) external;

/* ========== Balance Queries ========== */

  function balance() external view returns (uint256 sum);

  function reserveBalance() external view returns (uint256);

/* ========== Fee Queries ========== */

  function getPendingFees() external view returns (uint256);

/* ========== Price Queries ========== */

  function getPricePerFullShare() external view returns (uint256);

  function getPricePerFullShareWithFee() external view returns (uint256);

/* ========== Reward Token Sales ========== */

  function sellRewards(address rewardsToken, bytes calldata params) external;

/* ========== Adapter Queries ========== */

  function getBalances() external view returns (uint256[] memory balances);

  function getAdaptersAndWeights() external view returns (
    IErc20Adapter[] memory adapters,
    uint256[] memory weights
  );

/* ========== Status Queries ========== */

  function getCurrentLiquidityDeltas() external view returns (int256[] memory liquidityDeltas);

  function getAPR() external view returns (uint256);

  function currentDistribution() external view returns (
    DistributionParameters memory params,
    uint256 totalProductiveBalance,
    uint256 _reserveBalance
  );

/* ========== Deposit/Withdraw ========== */

  function deposit(uint256 amount) external returns (uint256 shares);

  function depositTo(uint256 amount, address to) external returns (uint256 shares);

  function withdraw(uint256 shares) external returns (uint256 owed);

  function withdrawUnderlying(uint256 amount) external returns (uint256 shares);

/* ========== Rebalance Actions ========== */

  function rebalance() external;

  function rebalanceWithNewWeights(uint256[] calldata proposedWeights) external;

  function rebalanceWithNewAdapters(
    IErc20Adapter[] calldata proposedAdapters,
    uint256[] calldata proposedWeights
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;


interface IRewardsSeller {
  /**
   * @dev Sell `rewardsToken` for `underlyingToken`.
   * Should only be called after `rewardsToken` is transferred.
   * @param sender - Address of account that initially triggered the call. Can be used to restrict who can trigger a sale.
   * @param rewardsToken - Address of the token to sell.
   * @param underlyingToken - Address of the token to buy.
   * @param params - Any additional data that the caller provided.
   */
  function sellRewards(
    address sender,
    address rewardsToken,
    address underlyingToken,
    bytes calldata params
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;


interface IErc20Adapter {
/* ========== Metadata ========== */

  function underlying() external view returns (address);

  function token() external view returns (address);

  function name() external view returns (string memory);

  function availableLiquidity() external view returns (uint256);

/* ========== Conversion ========== */

  function toUnderlyingAmount(uint256 tokenAmount) external view returns (uint256);

  function toWrappedAmount(uint256 underlyingAmount) external view returns (uint256);

/* ========== Performance Queries ========== */

  function getAPR() external view returns (uint256);

  function getHypotheticalAPR(int256 liquidityDelta) external view returns (uint256);

  function getRevenueBreakdown()
    external
    view
    returns (
      address[] memory assets,
      uint256[] memory aprs
    );

/* ========== Caller Balance Queries ========== */

  function balanceWrapped() external view returns (uint256);

  function balanceUnderlying() external view returns (uint256);

/* ========== Interactions ========== */

  function deposit(uint256 amountUnderlying) external returns (uint256 amountMinted);

  function withdraw(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAll() external returns (uint256 amountReceived);

  function withdrawUnderlying(uint256 amountUnderlying) external returns (uint256 amountBurned);

  function withdrawUnderlyingUpTo(uint256 amountUnderlying) external returns (uint256 amountReceived);
}

interface IEtherAdapter is IErc20Adapter {
  function depositETH() external payable returns (uint256 amountMinted);

  function withdrawAsETH(uint256 amountToken) external returns (uint256 amountReceived);

  function withdrawAllAsETH() external returns (uint256 amountReceived);

  function withdrawUnderlyingAsETH(uint256 amountUnderlying) external returns (uint256 amountBurned); 
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "none",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 800
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}