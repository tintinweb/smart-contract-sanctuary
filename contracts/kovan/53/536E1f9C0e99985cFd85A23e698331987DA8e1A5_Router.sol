// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITradersFactory.sol";
import "./interfaces/IManipulatorsSet.sol";
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
    IManipulatorsSet manipulatorsSet_
  ) external {
    tradersFactory.createTrader(
      msg.sender,
      observe_,
      relaySinceNonce_,
      manipulatorsSet_
    );
  }

  function createTraderAndApprove(
    address observe_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_,
    ITrader.AllowanceToSet[] calldata approvals_
  ) external {
    tradersFactory.createTrader(
      msg.sender,
      observe_,
      relaySinceNonce_,
      manipulatorsSet_,
      approvals_
    );
  }

  function createTraderAndCharge(
    address observe_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_,
    ITrader.PoolCharge[] calldata charges_,
    ITrader.Pool[] calldata chargedPools_
  ) external payable {
    address trader =
      tradersFactory.createTrader(
        msg.sender,
        observe_,
        relaySinceNonce_,
        manipulatorsSet_
      );
    _chargeTraderPools(ITrader(trader), charges_, chargedPools_);
  }

  function createTraderAndApproveAndCharge(
    address observe_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_,
    ITrader.PoolCharge[] calldata charges_,
    ITrader.Pool[] calldata chargedPools_,
    ITrader.AllowanceToSet[] calldata approvals_
  ) external payable {
    address trader =
      tradersFactory.createTrader(
        msg.sender,
        observe_,
        relaySinceNonce_,
        manipulatorsSet_,
        approvals_
      );
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
          IERC20(charges_[i].asset).transferFrom(
            msg.sender,
            address(this),
            charges_[i].value
          ),
          "Router:chargeTraderPools, ERC20 transfer failed"
        );
        require(
          IERC20(charges_[i].asset).approve(
            address(target_),
            type(uint256).max
          ),
          "Router:chargeTraderPools, ERC20 approve failed"
        );
      }
    }

    target_.chargePools{ value: msgValue }(charges_, chargedPools_);
    for (uint256 i = 0; i < charges_.length; i++) {
      if (charges_[i].asset != address(0)) {
        require(
          IERC20(charges_[i].asset).approve(address(target_), 0),
          "Router:chargeTraderPools, ERC20 approve failed"
        );
      }
    }
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

import "./IManipulatorsSet.sol";
import "./ITrader.sol";

interface ITradersFactory {
  event TraderCreated(
    address creator,
    address onContract,
    address manipulatorsSet,
    address observedAddress,
    uint256 relaySinceNonce
  );

  function createTrader(
    address manager_,
    address observe_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_
  ) external returns (address);

  function createTrader(
    address manager_,
    address observe_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_,
    ITrader.AllowanceToSet[] calldata approvals_
  ) external returns (address);

  function relayerProxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

import "./IABIManipulator.sol";

interface IManipulatorsSet {
  function setProtocolManipulatorsSet(
    address protocol,
    IABIManipulator manipulator
  ) external;

  function manipulationStrategies(address protocol)
    external
    view
    returns (IABIManipulator);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;
pragma abicoder v2;

import "./IManipulatorsSet.sol";

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

  event ManipulatorsSetChange(
    address indexed previousManipulator,
    address indexed newManipulator
  );

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
   * @param manipulatorsSet_ - initial set of ABI manipulators.
   */
  function initialize(
    address initialFollowedTrader_,
    address relayerProxy_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_
  ) external;

  /**
   * @dev Clone initializer with initial approvals.
   * @param initialFollowedTrader_ - initial address to be copied.
   * @param relaySinceNonce_ - followed trader nonce since which txns can be relayed.
   * @param manipulatorsSet_ - initial set of ABI manipulators.
   * @param approvals_ - initial approvals to set.
   */
  function initialize(
    address initialFollowedTrader_,
    address relayerProxy_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_,
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
  function setManipulatorsSet(IManipulatorsSet manipulatorsSet_) external;

  /// ===== GETTERS ===== ///

  /**
   * @dev returns the amount of tokens allocated in a pool
   */
  function poolSize(Pool pool_, address asset_) external view returns (uint256);

  function withdrawFromOperationPool(PoolCharge calldata withdrawal_) external;

  function withdrawFromRelayPool(PoolCharge calldata withdrawal_) external;

  function chargePools(
    PoolCharge[] calldata charges_,
    Pool[] calldata chargedPools_
  ) external payable;

  function relay(
    address refundAsset_,
    address refundOnBehalfOf_,
    bytes calldata transaction_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external;

  function manipulatorsSet() external view returns (IManipulatorsSet);

  function followedTrader() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

interface IABIManipulator {
  function manipulate(
    bytes calldata rawTxData,
    address copieer,
    address copiedFrom // TODO add copied from
  ) external view returns (bytes memory txDataManipulated, uint256 txValue); // TODO add transaction value.
}

