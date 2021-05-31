pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITradersFactory.sol";
import "./interfaces/IManipulatorsSet.sol";
import "./interfaces/ITrader.sol";

/// @title Malibu Router
/// @author Marcello Bardus
/// @notice Routes most of transferFrom engaging transactions in order to decrease needed approvals.
contract Router {
  /// @notice Minimal proxies factory for Trader contracts
  ITradersFactory public immutable tradersFactory;

  /// @param tradersFactory_ - Traders factory contract
  constructor(ITradersFactory tradersFactory_) {
    tradersFactory = tradersFactory_;
  }

  /// @notice Creates a copy trading contract.
  /// @param observe_ - Address of the EOA to be copied
  /// @param relaySinceNonce_ - EOA's nonce since copied txns will be valid
  /// @param manipulatorsSet_ - Default manipulators set
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

  /// @notice Creates a copy trading contract and approves external contracts to spend it's tokens.
  /// @param observe_ - Address of the EOA to be copied
  /// @param relaySinceNonce_ - EOA's nonce since copied txns will be valid
  /// @param manipulatorsSet_ - Default manipulators set
  /// @param approvals_ - List of ERC20 approvals to be set
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

  /// @notice Creates a copy trading contract and charges it's pools.
  /// @param observe_ - Address of the EOA to be copied
  /// @param relaySinceNonce_ - EOA's nonce since copied txns will be valid
  /// @param manipulatorsSet_ - Default manipulators set
  /// @param charges_ - List of pools charges see ITrader.PoolCharge
  /// @param chargedPools_ - Charges destinations
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

  /// @notice Creates a copy trading contract, charges it's pools and sets ERC20 approvals.
  /// @param observe_ - Address of the EOA to be copied
  /// @param relaySinceNonce_ - EOA's nonce since copied txns will be valid
  /// @param manipulatorsSet_ - Default manipulators set
  /// @param charges_ - List of pools charges see ITrader.PoolCharge
  /// @param chargedPools_ - Charges destinations
  /// @param approvals_ - List of ERC20 approvals to be set
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

  /// @notice Charges Copy trading contract pools.
  /// @param target_ - Instance of the contract to be charged
  /// @param charges_ - List of pools charges see ITrader.PoolCharge
  /// @param chargedPools_ - Charges destinations
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

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




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

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



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

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




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

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




interface IABIManipulator {
  struct ExecutionHook {
    bytes data;
    address target;
  }

  function manipulate(
    bytes calldata rawTxData,
    address copieer,
    address copiedFrom,
    uint256 txValue,
    address interactedProtocol
  )
    external
    view
    returns (
      bytes memory,
      uint256,
      ExecutionHook[] calldata,
      ExecutionHook[] calldata
    );
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
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
  "libraries": {}
}