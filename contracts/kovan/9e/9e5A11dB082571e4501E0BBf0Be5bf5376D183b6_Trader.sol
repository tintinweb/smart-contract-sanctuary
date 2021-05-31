pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";

import "./TraderManager.sol";
import "./TraderRelaysHandler.sol";
import "./TraderPools.sol";

import "./interfaces/ITrader.sol";
import "./interfaces/IManipulatorsSet.sol";

import "./lib/PricesLib.sol";

contract Trader is
  ITrader,
  TraderManager,
  TraderRelaysHandler,
  TraderPools,
  Initializable
{
  using SafeMath for uint256;

  /**
   * @dev followed set of ABI manipulators.
   */
  IManipulatorsSet public override manipulatorsSet;

  /**
   * @dev address which's transactions are to be copied.
   */
  address public override followedTrader;

  /// ===== EXTERNAL STATE CHANGERS ===== ///

  /// Clone initializer
  /// @inheritdoc ITrader
  function initialize(
    address initialFollowedTrader_,
    address relayerProxy_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_
  ) external virtual override initializer {
    // Require proxy is not initialized.
    _follow(initialFollowedTrader_);
    _setManipulatorsSet(manipulatorsSet_);
    _setRelaySinceNonce(relaySinceNonce_);
    _setRelayerProxy(relayerProxy_);
    _setRelayerFee(50000);
  }

  /// Clone initializer
  /// @inheritdoc ITrader
  function initialize(
    address initialFollowedTrader_,
    address relayerProxy_,
    uint256 relaySinceNonce_,
    IManipulatorsSet manipulatorsSet_,
    AllowanceToSet[] calldata approvals_
  ) external virtual override initializer {
    // Require proxy is not initialized.
    _follow(initialFollowedTrader_);
    _setManipulatorsSet(manipulatorsSet_);
    _setRelaySinceNonce(relaySinceNonce_);
    _setRelayerProxy(relayerProxy_);
    _setRelayerFee(50000);
    for (uint256 i = 0; i < approvals_.length; i++) {
      _setAllowance(approvals_[i]);
    }
  }

  /// @inheritdoc ITrader
  function follow(address trader_) external override onlyManager {
    require(trader_ != msg.sender, "You cannot follow yourself");
    require(
      trader_ != address(this),
      "This contract instance cannot follow itself"
    );
    require(
      trader_ != followedTrader,
      "You are already following this address"
    );
    _follow(trader_);
  }

  /// @inheritdoc ITrader
  function setManipulatorsSet(IManipulatorsSet manipulatorsSet_)
    external
    override
    onlyManager
  {
    _setManipulatorsSet(manipulatorsSet_);
  }

  function chargePools(
    PoolCharge[] calldata charges_,
    Pool[] calldata chargedPools_
  ) external payable override {
    _handleMultipleCharges(charges_, chargedPools_);
  }

  function withdrawFromOperationPool(PoolCharge calldata withdrawal_)
    external
    override
    onlyManager
  {
    _withdrawFromOperationPool(withdrawal_);
  }

  function withdrawFromRelayPool(PoolCharge calldata withdrawal_)
    external
    override
    onlyManager
  {
    _withdrawFromRelayPool(withdrawal_);
  }

  function setRelayerFee(uint256 fee_) external onlyManager() {
    _setRelayerFee(fee_);
  }

  function changeRelaySinceNonce(uint256 nonce_) external onlyManager {
    _setRelaySinceNonce(nonce_);
  }

  function transact(
    address recipient,
    uint256 value,
    bytes calldata data
  ) external onlyManager {
    (bool success, ) = recipient.call{ value: value }(data);
    require(success);
  }

  function relay(
    address refundAsset_,
    address refundOnBehalfOf_,
    bytes calldata transaction_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_
  ) external override onlyRelayerProxy {
    uint256 gasUsed =
      (_relay(transaction_, v_, r_, s_, followedTrader, manipulatorsSet))
        .add(
        refundAsset_ == address(0)
          ? AFTER_RELAY_ETH_TRANSFER_GAS_USAGE_APPROXIMATION
          : AFTER_RELAY_ERC20_TRANSFER_GAS_USAGE_APPROXIMATION
      )
        .add(AFTER_RELAY_FETCH_GAS_USAGE_APPROXIMATION);

    uint256 weiSpent = gasUsed.mul(tx.gasprice);
    uint256 weiToBeRefunded =
      weiSpent.add(weiSpent.div(RELAYER_FEE_BASE).mul(relayerFee));
    uint256 refundAmount =
      PricesLib.tokenAmountFromWei(refundAsset_, weiToBeRefunded);

    if (refundAsset_ == address(0)) {
      payable(refundOnBehalfOf_).transfer(refundAmount);
    } else {
      require(
        IERC20(refundOnBehalfOf_).transfer(refundOnBehalfOf_, refundAmount),
        "CopyTrader:relay, ERC20 transfer failed"
      );
    }

    _decreaseRelayPool(refundAsset_, refundAmount);
  }

  /// ===== INTERNAL STATE CHANGERS ===== ///

  function _follow(address trader_) internal {
    emit Follow(followedTrader, trader_);

    followedTrader = trader_;
  }

  function _setManipulatorsSet(IManipulatorsSet manipulatorsSet_) internal {
    emit ManipulatorsSetChange(
      address(manipulatorsSet),
      address(manipulatorsSet_)
    );
    manipulatorsSet = manipulatorsSet_;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




import "./interfaces/ITrader.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract TraderManager is ITrader {
  /**
   * @dev emitted when the manager is changed.
   */
  event ManagerSet(address previous, address current);

  /**
   * @dev address allowed to manage the contract.
   */
  address public manager;

  /**
   * @dev Allows to set the contract manager.
   * @notice Change is allowed when contract is still not initialized or msg.sender is the current manager.
   * @param manager_ - manager to be set.
   */
  function setManager(address manager_) external {
    require(
      manager == address(0) || msg.sender == manager,
      "TraderManager:setManager, permission denied"
    );
    emit ManagerSet(manager, manager_);
    manager = manager_;
  }

  /**
   * @dev checks if msg.sender is manager, if not reverts.
   */
  modifier onlyManager() {
    require(msg.sender == manager, "CopyTraderManager, permission denied");
    _;
  }

  /**
   * @dev Allows external address to spend contract's tokens.
   */
  function setAllowance(AllowanceToSet calldata allowance_)
    external
    onlyManager
  {
    _setAllowance(allowance_);
  }

  /**
   * @dev Allows multiple external addresses to spend contract's tokens.
   */
  function setAllowances(AllowanceToSet[] calldata allowances_)
    external
    onlyManager
  {
    _setAllowances(allowances_);
  }

  /// INTERNALS ///
  function _setAllowance(AllowanceToSet memory allowance_) internal {
    IERC20(allowance_.token).approve(allowance_.spender, allowance_.amount);
  }

  function _setAllowances(AllowanceToSet[] memory allowances_) internal {
    for (uint256 i = 0; i < allowances_.length; i++) {
      _setAllowance(allowances_[i]);
    }
  }
}

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




import "@openzeppelin/contracts/math/SafeMath.sol";

import "./lib/ECDSA.sol";
import "./lib/EIP155Utils.sol";

import "./interfaces/IManipulatorsSet.sol";
import "./interfaces/IABIManipulator.sol";
import "./interfaces/ITrader.sol";

abstract contract TraderRelaysHandler {
  using SafeMath for uint256;

  uint256 public constant AFTER_RELAY_ERC20_TRANSFER_GAS_USAGE_APPROXIMATION =
    60000;
  uint256 public constant AFTER_RELAY_ETH_TRANSFER_GAS_USAGE_APPROXIMATION =
    21000;
  uint256 public constant AFTER_RELAY_FETCH_GAS_USAGE_APPROXIMATION = 30000;

  /**
   * @dev division base when calculating relayer reward.
   * @notice relayer fee is the gas used by the tx converted to eth,
   * and then to the requested token + a % fee, the base of that percentage is 100000.
   */
  uint256 public constant RELAYER_FEE_BASE = 100000;

  /**
   * @dev relayer fee.
   */
  uint256 public relayerFee;

  /**
   * @dev stores the nonce of the last copied txns. Replay protection.
   */
  uint256 public lastCopiedTransactionNonce;

  /**
   * @dev protection against relaying multiple different transactions within the same block.
   */
  uint256 public lastRelayBlockNumber;

  /**
   * @dev allows to set the followed address nonce since txns can be relayed.
   */
  uint256 public relaySinceNonce;

  /**
   * @dev Address allowed to call relay function.
   */
  address public relayerProxy;

  modifier onlyRelayerProxy() {
    require(
      msg.sender == relayerProxy,
      "TraderRelaysHandler, Only relayer proxy can call this function"
    );
    _;
  }

  /**
   * @dev Sets relayerProxy.
   * @notice Called only during Trader initialization.
   */
  function _setRelayerProxy(address relayerProxy_) internal {
    relayerProxy = relayerProxy_;
  }

  /**
   * @dev sets relayer fee.
   * @notice consider if emitting an event would make sense.
   */
  function _setRelayerFee(uint256 fee_) internal {
    relayerFee = fee_;
  }

  function _setRelaySinceNonce(uint256 nonce_) internal {
    relaySinceNonce = nonce_;
  }

  function _isRLPSignatureCorrect(
    bytes calldata transaction_,
    uint8 v_,
    bytes32 r_,
    bytes32 s_,
    address signer_
  ) internal pure returns (bool, bytes32) {
    bytes32 txHash = keccak256(transaction_);
    address signer = ECDSA.recover(txHash, v_, r_, s_);
    return (signer_ == signer, txHash);
  }

  function _relay(
    bytes calldata transaction_,
    uint8 txSigV_,
    bytes32 txSigR_,
    bytes32 txSigS_,
    address transactionSigner_,
    IManipulatorsSet manipulatorsSet_
  ) internal returns (uint256 gasUsed) {
    uint256 beforeRelayAvailableGas = gasleft();
    require(
      lastRelayBlockNumber != block.number,
      "CopyTrader:_relay, a transaction has been relayed during current block"
    );

    (bool signatureOk, bytes32 txHash) =
      _isRLPSignatureCorrect(
        transaction_,
        txSigV_,
        txSigR_,
        txSigS_,
        transactionSigner_
      );

    require(signatureOk, "CopyTrader:_relay, invalid signature");

    EIP155Utils.EIP155Transaction memory eip155tx =
      EIP155Utils.decodeEIP155Transaction(transaction_);

    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    require(
      eip155tx.chainId == chainId,
      "CopyTrader:_relay, invalid sig chainId"
    );

    require(
      eip155tx.nonce >= relaySinceNonce,
      "CopyTrader:_relay, invalid nonce"
    );

    require(
      eip155tx.nonce >= lastCopiedTransactionNonce,
      "Transaction with the given nonce has already been copied"
    );
    lastCopiedTransactionNonce = eip155tx.nonce + 1;

    (
      bytes memory abiManipulated,
      uint256 txValue,
      IABIManipulator.ExecutionHook[] memory preExecutionHooks,
      IABIManipulator.ExecutionHook[] memory postExecutionHooks
    ) =
      manipulatorsSet_.manipulationStrategies(eip155tx.to).manipulate(
        eip155tx.data,
        address(this),
        transactionSigner_,
        eip155tx.value,
        eip155tx.to
      );

    require(
      abiManipulated.length > 0,
      "CopyTrader:_relay, relayed tx.data format is not supported by strategy"
    );

    for (uint256 i = 0; i < preExecutionHooks.length; i++) {
      preExecutionHooks[i].target.call{ value: 0 }(preExecutionHooks[i].data);
    }

    uint256 dataLength = abiManipulated.length;
    uint256 gasLimit = eip155tx.gasLimit;
    address to = eip155tx.to;

    bool result;

    assembly {
      let x := mload(0x40)
      let d := add(abiManipulated, 32)
      result := call(gasLimit, to, txValue, d, dataLength, x, 0)
    }
    require(result, "CopyTrader:_relay, execution failed");
    lastRelayBlockNumber = block.number;

    for (uint256 i = 0; i < postExecutionHooks.length; i++) {
      postExecutionHooks[i].target.call{ value: 0 }(postExecutionHooks[i].data);
    }

    return beforeRelayAvailableGas.sub(gasleft());
  }
}

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




import "./interfaces/ITrader.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

abstract contract TraderPools is ITrader {
  using SafeMath for uint256;

  /**
   * @dev map(poolAsset => poolSize).
   * This mapping contains the amount of some tokens locked, in order to pay the tx copping relayers.
   */
  mapping(address => uint256) public relayPools;

  function _chargeRelayPool(PoolCharge memory charge_) internal {
    relayPools[charge_.asset] = relayPools[charge_.asset].add(charge_.value);

    emit PoolCharged(charge_, Pool.RELAY);
  }

  function _chargeOperationsPool(PoolCharge memory charge_) internal {
    emit PoolCharged(charge_, Pool.OPERATIONS);
  }

  function _withdrawFromRelayPool(PoolCharge memory withdrawal_) internal {
    _decreaseRelayPool(withdrawal_.asset, withdrawal_.value);
    if (withdrawal_.asset == address(0)) {
      msg.sender.transfer(withdrawal_.value);
    } else {
      require(
        IERC20(withdrawal_.asset).transfer(msg.sender, withdrawal_.value)
      );
    }
    emit PoolWithdrawn(withdrawal_, Pool.RELAY);
  }

  function _withdrawFromOperationPool(PoolCharge memory withdrawal_) internal {
    require(
      this.poolSize(Pool.OPERATIONS, withdrawal_.asset) >= withdrawal_.value
    );

    if (withdrawal_.asset == address(0)) {
      msg.sender.transfer(withdrawal_.value);
    } else {
      require(
        IERC20(withdrawal_.asset).transfer(msg.sender, withdrawal_.value)
      );
    }
    emit PoolWithdrawn(withdrawal_, Pool.OPERATIONS);
  }

  function _handleMultipleCharges(
    PoolCharge[] memory charges_,
    Pool[] memory chargedPools_
  ) internal {
    require(charges_.length == chargedPools_.length);
    uint256 chargedEther;
    for (uint256 i = 0; i < charges_.length; i++) {
      if (charges_[i].asset == address(0)) {
        require(msg.value >= chargedEther.add(charges_[i].value));
      } else {
        require(
          IERC20(charges_[i].asset).transferFrom(
            msg.sender,
            address(this),
            charges_[i].value
          )
        );
      }

      chargedPools_[i] == Pool.RELAY
        ? _chargeRelayPool(charges_[i])
        : _chargeOperationsPool(charges_[i]);
    }
  }

  function _decreaseRelayPool(address pool_, uint256 amount_) internal {
    relayPools[pool_] = relayPools[pool_].sub(amount_);
  }

  function _balanceOf(address asset_) internal view returns (uint256) {
    if (asset_ == address(0)) {
      return address(this).balance;
    }
    return IERC20(asset_).balanceOf(address(this));
  }

  function poolSize(Pool pool_, address asset_)
    external
    view
    override
    returns (uint256)
  {
    if (pool_ == Pool.RELAY) return relayPools[asset_];
    uint256 balanceOf = _balanceOf(asset_);
    if (relayPools[asset_] > balanceOf) return 0;
    return _balanceOf(asset_).sub(relayPools[asset_]);
  }

  receive() external payable {}
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

// SPDX-License-Identifier: MIT


import "@openzeppelin/contracts/math/SafeMath.sol";

import "../interfaces/uniswap/IUniswapV2Factory.sol";
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";

library PricesLib {
  using SafeMath for uint256;

  IUniswapV2Factory public constant UNISWAP_V2_FACTORY =
    IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);

  IUniswapV2Router02 public constant UNISWAP_V2_ROUTER =
    IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

  function tokenAmountFromWei(address token, uint256 unitsToConvertToWei)
    external
    view
    returns (uint256 tokenAmount)
  {
    if (token == address(0) || token == UNISWAP_V2_ROUTER.WETH()) {
      return unitsToConvertToWei;
    }
    require(unitsToConvertToWei > 0, "PricesLib: INSUFFICIENT_AMOUNT");
    IUniswapV2Pair pair =
      IUniswapV2Pair(
        UNISWAP_V2_FACTORY.getPair(token, UNISWAP_V2_ROUTER.WETH())
      );
    require(address(pair) != address(0), "PricesLib: INVALID_PAIR");
    (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

    // solhint-disable-next-line
    require(reserve0 > 0 && reserve1 > 0, "PricesLib: INSUFFICIENT_LIQUIDITY");

    tokenAmount = unitsToConvertToWei.mul(uint256(reserve0)).div(
      uint256(reserve1)
    );
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



library ECDSA {
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}

pragma solidity 0.7.5;
pragma abicoder v2;

// SPDX-License-Identifier: MIT




import "./RLPReader.sol";

library EIP155Utils {
    struct EIP155Transaction {
        uint256 nonce;
        uint256 gasPrice;
        uint256 gasLimit;
        address to;
        uint256 value;
        bytes data;
        uint256 chainId;
    }

    function decodeEIP155Transaction(bytes memory _transaction)
        internal
        pure
        returns (EIP155Transaction memory _decoded)
    {
        Lib_RLPReader.RLPItem[] memory decoded =
            Lib_RLPReader.readList(_transaction);

        return
            EIP155Transaction({
                nonce: Lib_RLPReader.readUint256(decoded[0]),
                gasPrice: Lib_RLPReader.readUint256(decoded[1]),
                gasLimit: Lib_RLPReader.readUint256(decoded[2]),
                to: Lib_RLPReader.readAddress(decoded[3]),
                value: Lib_RLPReader.readUint256(decoded[4]),
                data: Lib_RLPReader.readBytes(decoded[5]),
                chainId: Lib_RLPReader.readUint256(decoded[6])
            });
    }
}

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {
    /*************
     * Constants *
     *************/

    uint256 internal constant MAX_LIST_LENGTH = 32;

    /*********
     * Enums *
     *********/

    enum RLPItemType {DATA_ITEM, LIST_ITEM}

    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in)
        internal
        pure
        returns (RLPItem memory)
    {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({length: _in.length, ptr: ptr});
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in)
        internal
        pure
        returns (RLPItem[] memory)
    {
        (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(
                itemCount < MAX_LIST_LENGTH,
                "Provided RLP list exceeds max list length."
            );

            (uint256 itemOffset, uint256 itemLength, ) =
                _decodeLength(
                    RLPItem({
                        length: _in.length - offset,
                        ptr: _in.ptr + offset
                    })
                );

            out[itemCount] = RLPItem({
                length: itemLength + itemOffset,
                ptr: _in.ptr + offset
            });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in)
        internal
        pure
        returns (RLPItem[] memory)
    {
        return readList(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in)
        internal
        pure
        returns (bytes memory)
    {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) =
            _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(RLPItem memory _in)
        internal
        pure
        returns (string memory)
    {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(bytes memory _in)
        internal
        pure
        returns (string memory)
    {
        return readString(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) =
            _decodeLength(_in);

        require(
            itemType == RLPItemType.DATA_ITEM,
            "Invalid RLP bytes32 value."
        );

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(bytes memory _in) internal pure returns (bytes32) {
        return readBytes32(toRLPItem(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(bytes memory _in) internal pure returns (uint256) {
        return readUint256(toRLPItem(_in));
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(RLPItem memory _in) internal pure returns (bool) {
        require(_in.length == 1, "Invalid RLP boolean value.");

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(bytes memory _in) internal pure returns (bool) {
        return readBool(toRLPItem(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(readUint256(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(bytes memory _in) internal pure returns (address) {
        return readAddress(toRLPItem(_in));
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in)
        internal
        pure
        returns (bytes memory)
    {
        return _copy(_in);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(_in.length > 0, "RLP item cannot be null.");

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            uint256 strLen = prefix - 0x80;

            require(_in.length > strLen, "Invalid RLP short string.");

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(
                _in.length > lenOfStrLen,
                "Invalid RLP long string length."
            );

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfStrLen))
                )
            }

            require(
                _in.length > lenOfStrLen + strLen,
                "Invalid RLP long string."
            );

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            uint256 listLen = prefix - 0xc0;

            require(_in.length > listLen, "Invalid RLP short list.");

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(_in.length > lenOfListLen, "Invalid RLP long list length.");

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(
                    mload(add(ptr, 1)),
                    exp(256, sub(32, lenOfListLen))
                )
            }

            require(
                _in.length > lenOfListLen + listLen,
                "Invalid RLP long list."
            );

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask = 256**(32 - (_length % 32)) - 1;
        assembly {
            mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
        }

        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(RLPItem memory _in) private pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }
}

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



// https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

pragma solidity 0.7.5;

// SPDX-License-Identifier: MIT



interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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
  "libraries": {
    "cache/solpp-generated-contracts/lib/PricesLib.sol": {
      "PricesLib": "0xd9841993b25d5d34683acc8bee9492aa2c9cd621"
    }
  }
}