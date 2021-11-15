pragma solidity 0.7.5;

import "../interfaces/ITrader.sol";

contract MulticallContractsPoolSizes {
  function multicall(address[] memory targets, address[] memory assets)
    external
    view
    returns (uint256[] memory sizes)
  {
    sizes = new uint256[](targets.length * assets.length * 2);

    uint256 currentIndex = 0;

    for (uint256 i = 0; i < targets.length; i++) {
      ITrader target = ITrader(targets[i]);
      for (uint256 j = 0; j < assets.length; j++) {
        sizes[currentIndex] = target.poolSize(ITrader.Pool.RELAY, assets[j]);
        sizes[currentIndex + 1] = target.poolSize(ITrader.Pool.OPERATIONS, assets[j]);
        currentIndex += 2;
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

import "./ITradingStrategy.sol";

interface ITrader {
  enum Pool { RELAY, OPERATIONS }
  /**
   * @dev emitted when followed trader changes.
   */
  event Follow(address indexed previouslyFollowed, address indexed newFollow);

  /**
   * @dev emitted when a certain pool is top up.
   */
  event PoolCharged(PoolCharge charge, Pool pool);

  /**
   * @dev emitted when a certain pool is withdrawn.
   */
  event PoolWithdrawn(PoolCharge charge, Pool pool);

  event TradingStrategyChange(address indexed previousStrategy, address indexed newStrategy);

  /**
   * @dev used as arg when a certain pool is charged,
   * instead of passing address[] and uint[] an array of PoolCharge[] will be used to simplify.
   */
  struct PoolCharge {
    address asset;
    uint256 value;
  }

  struct AllowanceToSet {
    address token;
    address spender;
    uint256 amount;
  }

  /**
   * @dev Clone initializer.
   * @param initialFollowedTrader_ - initial address to be copied.
   * @param relaySinceNonce_ - followed trader nonce since which txns can be relayed.
   * @param tradingStrategy_ - initial strategy to be followed.
   */
  function initialize(
    address initialFollowedTrader_,
    address relayerProxy_,
    uint256 relaySinceNonce_,
    ITradingStrategy tradingStrategy_
  ) external;

  /**
   * @dev Clone initializer with initial approvals.
   * @param initialFollowedTrader_ - initial address to be copied.
   * @param relaySinceNonce_ - followed trader nonce since which txns can be relayed.
   * @param tradingStrategy_ - initial strategy to be followed.
   * @param approvals_ - initial approvals to set.
   */
  function initialize(
    address initialFollowedTrader_,
    address relayerProxy_,
    uint256 relaySinceNonce_,
    ITradingStrategy tradingStrategy_,
    AllowanceToSet[] calldata approvals_
  ) external;

  /**
   * @dev allows to change the followed address.
   * @notice must be called only by the contract owner.
   */
  function follow(address trader) external;

  /**
   * @dev sets trading, ABI manipulation strategy.
   * @notice must be called only by the contract owner.
   */
  function setTradingStrategy(ITradingStrategy strategy) external;

  /// ===== GETTERS ===== ///

  /**
   * @dev returns the amount of tokens allocated in a pool
   */
  function poolSize(Pool pool_, address asset_) external view returns (uint256);

  function withdrawFromOperationPool(PoolCharge calldata withdrawal_) external;

  function withdrawFromRelayPool(PoolCharge calldata withdrawal_) external;

  function chargePools(PoolCharge[] calldata charges_, Pool[] calldata chargedPools_)
    external
    payable;

  function relay(
    address refundAsset_,
    address refundOnBehalfOf_,
    bytes calldata transaction_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

interface ITradingStrategy {
  function setManipulator(
    address copiedTradesRecipient,
    bytes4 identifier,
    address manipulator
  ) external;

  function manipulators(address destination, bytes4 identifier) external view returns (address);

  function supportedProtocols() external view returns (address[] memory protocols);

  function protocolManipulators(address protocol_)
    external
    view
    returns (bytes4[] memory protocolManipulators);
}

