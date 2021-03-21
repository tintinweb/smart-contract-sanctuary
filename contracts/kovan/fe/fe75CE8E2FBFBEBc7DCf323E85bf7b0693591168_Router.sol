// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITradersFactory.sol";
import "./interfaces/ITradingStrategy.sol";
import "./interfaces/ITrader.sol";

// This contract will route creating copytraders, adding/removing funds from them.
contract Router {
  ITradersFactory public immutable tradersFactory;

  constructor(ITradersFactory tradersFactory_) {
    tradersFactory = tradersFactory_;
  }

  function createTrader(
    address observe_,
    uint256 relaySinceNonce_,
    ITradingStrategy strategy_
  ) external {
    tradersFactory.createTrader(msg.sender, observe_, relaySinceNonce_, strategy_);
  }

  function createTraderAndApprove(
    address observe_,
    uint256 relaySinceNonce_,
    ITradingStrategy strategy_,
    ITrader.AllowanceToSet[] calldata approvals_
  ) external {
    tradersFactory.createTrader(msg.sender, observe_, relaySinceNonce_, strategy_, approvals_);
  }

  function createTraderAndCharge(
    address observe_,
    uint256 relaySinceNonce_,
    ITradingStrategy strategy_,
    ITrader.PoolCharge[] calldata charges_,
    ITrader.Pool[] calldata chargedPools_
  ) external payable {
    address trader = tradersFactory.createTrader(msg.sender, observe_, relaySinceNonce_, strategy_);
    _chargeTraderPools(ITrader(trader), charges_, chargedPools_);
  }

  function createTraderAndApproveAndCharge(
    address observe_,
    uint256 relaySinceNonce_,
    ITradingStrategy strategy_,
    ITrader.PoolCharge[] calldata charges_,
    ITrader.Pool[] calldata chargedPools_,
    ITrader.AllowanceToSet[] calldata approvals_
  ) external payable {
    address trader =
      tradersFactory.createTrader(msg.sender, observe_, relaySinceNonce_, strategy_, approvals_);
    _chargeTraderPools(ITrader(trader), charges_, chargedPools_);
  }

  function chargeTraderPools(
    ITrader target_,
    ITrader.PoolCharge[] calldata charges_,
    ITrader.Pool[] calldata chargedPools_
  ) external payable {
    _chargeTraderPools(target_, charges_, chargedPools_);
  }

  function _chargeTraderPools(
    ITrader target_,
    ITrader.PoolCharge[] calldata charges_,
    ITrader.Pool[] calldata chargedPools_
  ) internal {
    uint256 msgValue;
    for (uint256 i = 0; i < charges_.length; i++) {
      if (charges_[i].asset == address(0)) {
        require(
          msg.value >= charges_[i].value + msgValue,
          "Router:chargeTraderPools, invalid tx value"
        );
        msgValue += charges_[i].value;
      } else {
        require(
          IERC20(charges_[i].asset).transferFrom(msg.sender, address(this), charges_[i].value),
          "Router:chargeTraderPools, ERC20 transfer failed"
        );
        require(
          IERC20(charges_[i].asset).approve(address(target_), charges_[i].value),
          "Router:chargeTraderPools, ERC20 approve failed"
        );
      }
    }
    target_.chargePools{ value: msgValue }(charges_, chargedPools_);
  }

  // TODO
  function withdrawFromRelayPool() external {}

  // TODO
  function withdrawFromOperationsPool() external {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity 0.7.5;
pragma abicoder v2;

import "./ITradingStrategy.sol";
import "./ITrader.sol";

interface ITradersFactory {
  event TraderCreated(
    address creator,
    address onContract,
    address strategy,
    address observedAddress,
    uint256 relaySinceNonce
  );

  function createTrader(
    address manager_,
    address observe_,
    uint256 relaySinceNonce_,
    ITradingStrategy strategy_
  ) external returns (address);

  function createTrader(
    address manager_,
    address observe_,
    uint256 relaySinceNonce_,
    ITradingStrategy strategy_,
    ITrader.AllowanceToSet[] calldata approvals_
  ) external returns (address);

  function relayerProxy() external view returns (address);
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