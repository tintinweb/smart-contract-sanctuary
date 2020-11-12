pragma solidity 0.5.17; // optimization runs: 200, evm version: istanbul
// WARNING - `executeActionWithAtomicBatchCalls` has a `bytes[]` argument that
// requires ABIEncoderV2. Exercise caution when calling that specific function.
pragma experimental ABIEncoderV2;


interface DharmaSmartWalletImplementationV1Interface {
  event CallSuccess(
    bytes32 actionID,
    bool rolledBack,
    uint256 nonce,
    address to,
    uint256 value,
    bytes data,
    bytes returnData
  );

  event CallFailure(
    bytes32 actionID,
    uint256 nonce,
    address to,
    uint256 value,
    bytes data,
    string revertReason
  );

  // ABIEncoderV2 uses an array of Calls for executing generic batch calls.
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  // ABIEncoderV2 uses an array of CallReturns for handling generic batch calls.
  struct CallReturn {
    bool ok;
    bytes returnData;
  }

  function withdrawEther(
    uint256 amount,
    address payable recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function executeAction(
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData);

  function recover(address newUserSigningKey) external;

  function executeActionWithAtomicBatchCalls(
    Call[] calldata calls,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool[] memory ok, bytes[] memory returnData);

  function getNextGenericActionID(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getGenericActionID(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getNextGenericAtomicBatchActionID(
    Call[] calldata calls,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getGenericAtomicBatchActionID(
    Call[] calldata calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);
}


interface DharmaSmartWalletImplementationV3Interface {
  event Cancel(uint256 cancelledNonce);
  event EthWithdrawal(uint256 amount, address recipient);
}


interface DharmaSmartWalletImplementationV4Interface {
  event Escaped();

  function setEscapeHatch(
    address account,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function removeEscapeHatch(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function permanentlyDisableEscapeHatch(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function escape(address token) external;

}


interface DharmaSmartWalletImplementationV7Interface {
  // Fires when a new user signing key is set on the smart wallet.
  event NewUserSigningKey(address userSigningKey);

  // Fires when an error occurs as part of an attempted action.
  event ExternalError(address indexed source, string revertReason);

  // The smart wallet recognizes DAI, USDC, ETH, and SAI as supported assets.
  enum AssetType {
    DAI,
    USDC,
    ETH,
    SAI
  }

  // Actions, or protected methods (i.e. not deposits) each have an action type.
  enum ActionType {
    Cancel,
    SetUserSigningKey,
    Generic,
    GenericAtomicBatch,
    SAIWithdrawal,
    USDCWithdrawal,
    ETHWithdrawal,
    SetEscapeHatch,
    RemoveEscapeHatch,
    DisableEscapeHatch,
    DAIWithdrawal,
    SignatureVerification,
    TradeEthForDai,
    DAIBorrow,
    USDCBorrow
  }

  function initialize(address userSigningKey) external;

  function repayAndDeposit() external;

  function withdrawDai(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function withdrawUSDC(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok);

  function cancel(
    uint256 minimumActionGas,
    bytes calldata signature
  ) external;

  function setUserSigningKey(
    address userSigningKey,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external;

  function migrateSaiToDai() external;

  function migrateCSaiToDDai() external;

  function migrateCDaiToDDai() external;

  function migrateCUSDCToDUSDC() external;

  function getBalances() external view returns (
    uint256 daiBalance,
    uint256 usdcBalance,
    uint256 etherBalance,
    uint256 dDaiUnderlyingDaiBalance,
    uint256 dUsdcUnderlyingUsdcBalance,
    uint256 dEtherUnderlyingEtherBalance // always returns zero
  );

  function getUserSigningKey() external view returns (address userSigningKey);

  function getNonce() external view returns (uint256 nonce);

  function getNextCustomActionID(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getCustomActionID(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getVersion() external pure returns (uint256 version);
}


interface DharmaSmartWalletImplementationV8Interface {
  function tradeEthForDaiAndMintDDai(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData);

  function getNextEthForDaiActionID(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);

  function getEthForDaiActionID(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID);
}


interface DharmaSmartWalletImplementationV12Interface {
  function setApproval(address token, uint256 amount) external;
}

interface DharmaSmartWalletImplementationV13Interface {
  function redeemAllDDai() external;
  function redeemAllDUSDC() external;
}


interface ERC20Interface {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256);
  function allowance(
    address owner, address spender
  ) external view returns (uint256);
}


interface ERC1271Interface {
  function isValidSignature(
    bytes calldata data, bytes calldata signature
  ) external view returns (bytes4 magicValue);
}


interface DTokenInterface {
  // These external functions trigger accrual on the dToken and backing cToken.
  function mint(uint256 underlyingToSupply) external returns (uint256 dTokensMinted);
  function redeem(uint256 dTokensToBurn) external returns (uint256 underlyingReceived);
  function redeemUnderlying(uint256 underlyingToReceive) external returns (uint256 dTokensBurned);

  // These external functions only trigger accrual on the dToken.
  function mintViaCToken(uint256 cTokensToSupply) external returns (uint256 dTokensMinted);

  // View and pure functions do not trigger accrual on the dToken or the cToken.
  function balanceOfUnderlying(address account) external view returns (uint256 underlyingBalance);
}


interface DharmaKeyRegistryInterface {
  function getKey() external view returns (address key);
}


interface DharmaEscapeHatchRegistryInterface {
  function setEscapeHatch(address newEscapeHatch) external;

  function removeEscapeHatch() external;

  function permanentlyDisableEscapeHatch() external;

  function getEscapeHatch() external view returns (
    bool exists, address escapeHatch
  );
}


interface RevertReasonHelperInterface {
  function reason(uint256 code) external pure returns (string memory);
}


interface EtherizedInterface {
  function triggerEtherTransfer(
    address payable target, uint256 value
  ) external returns (bool success);
}


library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}


library ECDSA {
  function recover(
    bytes32 hash, bytes memory signature
  ) internal pure returns (address) {
    if (signature.length != 65) {
      return (address(0));
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return address(0);
    }

    if (v != 27 && v != 28) {
      return address(0);
    }

    return ecrecover(hash, v, r, s);
  }

  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}


contract Etherized is EtherizedInterface {
  address private constant _ETHERIZER = address(
    0x723B51b72Ae89A3d0c2a2760f0458307a1Baa191 
  );

  function triggerEtherTransfer(
    address payable target, uint256 amount
  ) external returns (bool success) {
    require(msg.sender == _ETHERIZER, "Etherized: only callable by Etherizer");
    (success, ) = target.call.value(amount)("");
    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }
}


/**
 * @title DharmaSmartWalletImplementationV14
 * @author 0age
 * @notice The V14 implementation for the Dharma smart wallet is a non-custodial,
 * meta-transaction-enabled wallet with helper functions to facilitate lending
 * funds through Dharma Dai and Dharma USD Coin (which in turn use CompoundV2),
 * and with an added security backstop provided by Dharma Labs prior to making
 * withdrawals. It adds support for Dharma Dai and Dharma USD Coin - they employ
 * the respective cTokens as backing tokens and mint and redeem them internally
 * as interest-bearing collateral. This implementation also contains methods to
 * support account recovery, escape hatch functionality, and generic actions,
 * including in an atomic batch. The smart wallet instances utilizing this
 * implementation are deployed through the Dharma Smart Wallet Factory via
 * `CREATE2`, which allows for their address to be known ahead of time, and any
 * Dai or USDC that has already been sent into that address will automatically
 * be deposited into the respective Dharma Token upon deployment of the new
 * smart wallet instance. V14 allows for Ether transfers as part of generic
 * actions, supports "simulation" of generic batch actions, and revises escape
 * hatch functionality to support arbitrary token withdrawals.
 */
contract DharmaSmartWalletImplementationV14 is
  DharmaSmartWalletImplementationV1Interface,
  DharmaSmartWalletImplementationV3Interface,
  DharmaSmartWalletImplementationV4Interface,
  DharmaSmartWalletImplementationV7Interface,
  DharmaSmartWalletImplementationV8Interface,
  DharmaSmartWalletImplementationV12Interface,
  DharmaSmartWalletImplementationV13Interface,
  ERC1271Interface,
  Etherized {
  using Address for address;
  using ECDSA for bytes32;
  // WARNING: DO NOT REMOVE OR REORDER STORAGE WHEN WRITING NEW IMPLEMENTATIONS!

  // The user signing key associated with this account is in storage slot 0.
  // It is the core differentiator when it comes to the account in question.
  address private _userSigningKey;

  // The nonce associated with this account is in storage slot 1. Every time a
  // signature is submitted, it must have the appropriate nonce, and once it has
  // been accepted the nonce will be incremented.
  uint256 private _nonce;

  // The self-call context flag is in storage slot 2. Some protected functions
  // may only be called externally from calls originating from other methods on
  // this contract, which enables appropriate exception handling on reverts.
  // Any storage should only be set immediately preceding a self-call and should
  // be cleared upon entering the protected function being called.
  bytes4 internal _selfCallContext;

  // END STORAGE DECLARATIONS - DO NOT REMOVE OR REORDER STORAGE ABOVE HERE!

  // The smart wallet version will be used when constructing valid signatures.
  uint256 internal constant _DHARMA_SMART_WALLET_VERSION = 14;

  // DharmaKeyRegistryV2 holds a public key for verifying meta-transactions.
  DharmaKeyRegistryInterface internal constant _DHARMA_KEY_REGISTRY = (
    DharmaKeyRegistryInterface(0x000000000D38df53b45C5733c7b34000dE0BDF52)
  );

  // Account recovery is facilitated using a hard-coded recovery manager,
  // controlled by Dharma and implementing appropriate timelocks.
  address internal constant _ACCOUNT_RECOVERY_MANAGER = address(
    0x0000000000DfEd903aD76996FC07BF89C0127B1E
  );

  // Users can designate an "escape hatch" account with the ability to sweep any
  // funds from their smart wallet by using the Dharma Escape Hatch Registry.
  DharmaEscapeHatchRegistryInterface internal constant _ESCAPE_HATCH_REGISTRY = (
    DharmaEscapeHatchRegistryInterface(0x00000000005280B515004B998a944630B6C663f8)
  );

  // Interface with dDai and dUSDC contracts.
  DTokenInterface internal constant _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430 // mainnet
  );

  DTokenInterface internal constant _DUSDC = DTokenInterface(
    0x00000000008943c65cAf789FFFCF953bE156f6f8 // mainnet
  );

  // The "revert reason helper" contains a collection of revert reason strings.
  RevertReasonHelperInterface internal constant _REVERT_REASON_HELPER = (
    RevertReasonHelperInterface(0x9C0ccB765D3f5035f8b5Dd30fE375d5F4997D8E4)
  );

  // The "Trade Bot" enables limit orders using unordered meta-transactions.
  address internal constant _TRADE_BOT = address(
    0x8bFB7aC05bF9bDC6Bc3a635d4dd209c8Ba39E554
  );

  // ERC-1271 must return this magic value when `isValidSignature` is called.
  bytes4 internal constant _ERC_1271_MAGIC_VALUE = bytes4(0x20c13b0b);

  // Specify the amount of gas to supply when making Ether transfers.
  uint256 private constant _ETH_TRANSFER_GAS = 4999;

  /**
   * @notice Accept Ether in the fallback.
   */
  function () external payable {}

  /**
   * @notice In the initializer, set up the initial user signing key. Note that
   * this initializer is only callable while the smart wallet instance is still
   * in the contract creation phase.
   * @param userSigningKey address The initial user signing key for the smart
   * wallet.
   */
  function initialize(address userSigningKey) external {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    // Set up the user's signing key and emit a corresponding event.
    _setUserSigningKey(userSigningKey);
  }

  /**
   * @notice Redeem all Dharma Dai held by this account for Dai.
   */
  function redeemAllDDai() external {
    _withdrawMaxFromDharmaToken(AssetType.DAI);
  }

  /**
   * @notice Redeem all Dharma USD Coin held by this account for USDC.
   */
  function redeemAllDUSDC() external {
    _withdrawMaxFromDharmaToken(AssetType.USDC);
  }

  /**
   * @notice This call is no longer supported.
   */
  function repayAndDeposit() external {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function withdrawDai(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function withdrawUSDC(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {
    revert("Deprecated.");
  }

  /**
   * @notice Withdraw Ether to a provided recipient address by transferring it
   * to a recipient.
   * @param amount uint256 The amount of Ether to withdraw.
   * @param recipient address The account to transfer the Ether to.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   * @return True if the transfer succeeded, otherwise false.
   */
  function withdrawEther(
    uint256 amount,
    address payable recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.ETHWithdrawal,
      abi.encode(amount, recipient),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Ensure that a non-zero amount of Ether has been supplied.
    if (amount == 0) {
      revert(_revertReason(4));
    }

    // Ensure that a non-zero recipient has been supplied.
    if (recipient == address(0)) {
      revert(_revertReason(1));
    }

    // Attempt to transfer Ether to the recipient and emit an appropriate event.
    ok = _transferETH(recipient, amount);
  }

  /**
   * @notice Allow a signatory to increment the nonce at any point. The current
   * nonce needs to be provided as an argument to the signature so as not to
   * enable griefing attacks. All arguments can be omitted if called directly.
   * No value is returned from this function - it will either succeed or revert.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param signature bytes A signature that resolves to either the public key
   * set for this account in storage slot zero, `_userSigningKey`, or the public
   * key returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   */
  function cancel(
    uint256 minimumActionGas,
    bytes calldata signature
  ) external {
    // Get the current nonce.
    uint256 nonceToCancel = _nonce;

    // Ensure the caller or the supplied signature is valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.Cancel,
      abi.encode(),
      minimumActionGas,
      signature,
      signature
    );

    // Emit an event to validate that the nonce is no longer valid.
    emit Cancel(nonceToCancel);
  }

  /**
   * @notice This call is no longer supported.
   */
  function executeAction(
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData) {
    revert("Deprecated.");
  }

  /**
   * @notice Allow signatory to set a new user signing key. The current nonce
   * needs to be provided as an argument to the signature so as not to enable
   * griefing attacks. No value is returned from this function - it will either
   * succeed or revert.
   * @param userSigningKey address The new user signing key to set on this smart
   * wallet.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   */
  function setUserSigningKey(
    address userSigningKey,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.SetUserSigningKey,
      abi.encode(userSigningKey),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Set new user signing key on smart wallet and emit a corresponding event.
    _setUserSigningKey(userSigningKey);
  }

  /**
   * @notice Set a dedicated address as the "escape hatch" account. This account
   * can then call `escape(address token)` at any point to "sweep" the entire
   * balance of the token (or Ether given null address) from the smart wallet.
   * This function call will revert if the smart wallet has previously called
   * `permanentlyDisableEscapeHatch` at any point and disabled the escape hatch.
   * No value is returned from this function - it will either succeed or revert.
   * @param account address The account to set as the escape hatch account.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   */
  function setEscapeHatch(
    address account,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.SetEscapeHatch,
      abi.encode(account),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Ensure that an escape hatch account has been provided.
    if (account == address(0)) {
      revert(_revertReason(5));
    }

    // Set a new escape hatch for the smart wallet unless it has been disabled.
    _ESCAPE_HATCH_REGISTRY.setEscapeHatch(account);
  }

  /**
   * @notice Remove the "escape hatch" account if one is currently set. This
   * function call will revert if the smart wallet has previously called
   * `permanentlyDisableEscapeHatch` at any point and disabled the escape hatch.
   * No value is returned from this function - it will either succeed or revert.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   */
  function removeEscapeHatch(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.RemoveEscapeHatch,
      abi.encode(),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Remove the escape hatch for the smart wallet if one is currently set.
    _ESCAPE_HATCH_REGISTRY.removeEscapeHatch();
  }

  /**
   * @notice Permanently disable the "escape hatch" mechanism for this smart
   * wallet. This function call will revert if the smart wallet has already
   * called `permanentlyDisableEscapeHatch` at any point in the past. No value
   * is returned from this function - it will either succeed or revert.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   */
  function permanentlyDisableEscapeHatch(
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.DisableEscapeHatch,
      abi.encode(),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Permanently disable the escape hatch mechanism for this smart wallet.
    _ESCAPE_HATCH_REGISTRY.permanentlyDisableEscapeHatch();
  }

  /**
   * @notice This call is no longer supported.
   */
  function tradeEthForDaiAndMintDDai(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData) {
    revert("Deprecated.");
  }

  /**
   * @notice Allow the designated escape hatch account to redeem and "sweep"
   * the total token balance or Ether balance (by supplying the null address)
   * from the smart wallet. The call will revert for any other caller, or if
   * there is no escape hatch account on this smart wallet. An `Escaped` event
   * will be emitted. No value is returned from this function - it will either
   * succeed or revert.
   */
  function escape(address token) external {
    // Get the escape hatch account, if one exists, for this account.
    (bool exists, address escapeHatch) = _ESCAPE_HATCH_REGISTRY.getEscapeHatch();

    // Ensure that an escape hatch is currently set for this smart wallet.
    if (!exists) {
      revert(_revertReason(6));
    }

    // Ensure that the escape hatch account is the caller.
    if (msg.sender != escapeHatch) {
      revert(_revertReason(7));
    }

    if (token == address(0)) {
      // Determine if there is Ether at this address that should be transferred.
      uint256 balance = address(this).balance;
      if (balance > 0) {
        // Attempt to transfer any Ether to caller and emit an appropriate event.
        _transferETH(msg.sender, balance);
      }
    } else {
      // Attempt to transfer all tokens to the caller.
      _transferMax(ERC20Interface(address(token)), msg.sender, false);
    }

    // Emit an `Escaped` event.
    emit Escaped();
  }

  /**
   * @notice Allow the account recovery manager to set a new user signing key on
   * the smart wallet. The call will revert for any other caller. The account
   * recovery manager implements a set of controls around the process, including
   * a timelock and an option to permanently opt out of account recover. No
   * value is returned from this function - it will either succeed or revert.
   * @param newUserSigningKey address The new user signing key to set on this
   * smart wallet.
   */
  function recover(address newUserSigningKey) external {
    // Only the Account Recovery Manager contract may call this function.
    if (msg.sender != _ACCOUNT_RECOVERY_MANAGER) {
      revert(_revertReason(8));
    }

    // Increment nonce to prevent signature reuse should original key be reset.
    _nonce++;

    // Set up the user's new dharma key and emit a corresponding event.
    _setUserSigningKey(newUserSigningKey);
  }

  function setApproval(address token, uint256 amount) external {
    // Only the Trade Bot contract may call this function.
    if (msg.sender != _TRADE_BOT) {
      revert("Only the Trade Bot may call this function.");
    }

    ERC20Interface(token).approve(_TRADE_BOT, amount);
  }

  /**
   * @notice This call is no longer supported.
   */
  function migrateSaiToDai() external {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function migrateCSaiToDDai() external {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function migrateCDaiToDDai() external {
     revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function migrateCUSDCToDUSDC() external {
     revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function getBalances() external view returns (
    uint256 daiBalance,
    uint256 usdcBalance,
    uint256 etherBalance,
    uint256 dDaiUnderlyingDaiBalance,
    uint256 dUsdcUnderlyingUsdcBalance,
    uint256 dEtherUnderlyingEtherBalance // always returns 0
  ) {
    revert("Deprecated.");
  }

  /**
   * @notice View function for getting the current user signing key for the
   * smart wallet.
   * @return The current user signing key.
   */
  function getUserSigningKey() external view returns (address userSigningKey) {
    userSigningKey = _userSigningKey;
  }

  /**
   * @notice View function for getting the current nonce of the smart wallet.
   * This nonce is incremented whenever an action is taken that requires a
   * signature and/or a specific caller.
   * @return The current nonce.
   */
  function getNonce() external view returns (uint256 nonce) {
    nonce = _nonce;
  }

  /**
   * @notice View function that, given an action type and arguments, will return
   * the action ID or message hash that will need to be prefixed (according to
   * EIP-191 0x45), hashed, and signed by both the user signing key and by the
   * key returned for this smart wallet by the Dharma Key Registry in order to
   * construct a valid signature for the corresponding action. Any nonce value
   * may be supplied, which enables constructing valid message hashes for
   * multiple future actions ahead of time.
   * @param action uint8 The type of action, designated by it's index. Valid
   * custom actions include Cancel (0), SetUserSigningKey (1),
   * DAIWithdrawal (10), USDCWithdrawal (5), ETHWithdrawal (6),
   * SetEscapeHatch (7), RemoveEscapeHatch (8), and DisableEscapeHatch (9).
   * @param amount uint256 The amount to withdraw for Withdrawal actions. This
   * value is ignored for non-withdrawal action types.
   * @param recipient address The account to transfer withdrawn funds to or the
   * new user signing key. This value is ignored for Cancel, RemoveEscapeHatch,
   * and DisableEscapeHatch action types.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getNextCustomActionID(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      action,
      _validateCustomActionTypeAndGetArguments(action, amount, recipient),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice View function that, given an action type and arguments, will return
   * the action ID or message hash that will need to be prefixed (according to
   * EIP-191 0x45), hashed, and signed by both the user signing key and by the
   * key returned for this smart wallet by the Dharma Key Registry in order to
   * construct a valid signature for the corresponding action. The current nonce
   * will be used, which means that it will only be valid for the next action
   * taken.
   * @param action uint8 The type of action, designated by it's index. Valid
   * custom actions include Cancel (0), SetUserSigningKey (1),
   * DAIWithdrawal (10), USDCWithdrawal (5), ETHWithdrawal (6),
   * SetEscapeHatch (7), RemoveEscapeHatch (8), and DisableEscapeHatch (9).
   * @param amount uint256 The amount to withdraw for Withdrawal actions. This
   * value is ignored for non-withdrawal action types.
   * @param recipient address The account to transfer withdrawn funds to or the
   * new user signing key. This value is ignored for Cancel, RemoveEscapeHatch,
   * and DisableEscapeHatch action types.
   * @param nonce uint256 The nonce to use.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getCustomActionID(
    ActionType action,
    uint256 amount,
    address recipient,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      action,
      _validateCustomActionTypeAndGetArguments(action, amount, recipient),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice This call is no longer supported.
   */
  function getNextGenericActionID(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function getGenericActionID(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function getNextEthForDaiActionID(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    revert("Deprecated.");
  }

  /**
   * @notice This call is no longer supported.
   */
  function getEthForDaiActionID(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    revert("Deprecated.");
  }

  /**
   * @notice View function that implements ERC-1271 and validates a set of
   * signatures, one from the owner (using ERC-1271 as well if the user signing
   * key is a contract) and one from the Dharma Key Registry against the
   * supplied data. The data must be ABI encoded as (bytes32, bytes), where the
   * first bytes32 parameter represents the hash digest for validating the
   * supplied signatures and the second bytes parameter contains context for the
   * requested validation. The two signatures are packed together, with the one
   * from Dharma coming first and that from the user coming second - this is so
   * that, in future versions, multiple user signatures may be supplied if the
   * associated key ring requires them.
   * @param data bytes The data used to validate the signature.
   * @param signatures bytes The two signatures, each 65 bytes - one from the
   * owner (using ERC-1271 as well if the user signing key is a contract) and
   * one from the Dharma Key Registry.
   * @return The 4-byte magic value to signify a valid signature in ERC-1271, if
   * the signatures are both valid.
   */
  function isValidSignature(
    bytes calldata data, bytes calldata signatures
  ) external view returns (bytes4 magicValue) {
    // Get message hash digest and any additional context from data argument.
    bytes32 digest;
    bytes memory context;

    if (data.length == 32) {
      digest = abi.decode(data, (bytes32));
    } else {
      if (data.length < 64) {
        revert(_revertReason(30));
      }
      (digest, context) = abi.decode(data, (bytes32, bytes));
    }

    // Get Dharma signature & user signature from combined signatures argument.
    if (signatures.length != 130) {
      revert(_revertReason(11));
    }
    bytes memory signaturesInMemory = signatures;
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signaturesInMemory, 0x20))
      s := mload(add(signaturesInMemory, 0x40))
      v := byte(0, mload(add(signaturesInMemory, 0x60)))
    }
    bytes memory dharmaSignature = abi.encodePacked(r, s, v);

    assembly {
      r := mload(add(signaturesInMemory, 0x61))
      s := mload(add(signaturesInMemory, 0x81))
      v := byte(0, mload(add(signaturesInMemory, 0xa1)))
    }
    bytes memory userSignature = abi.encodePacked(r, s, v);

    // Validate user signature with `SignatureVerification` as the action type.
    if (
      !_validateUserSignature(
        digest,
        ActionType.SignatureVerification,
        context,
        _userSigningKey,
        userSignature
      )
    ) {
      revert(_revertReason(12));
    }

    // Recover Dharma signature against key returned from Dharma Key Registry.
    if (_getDharmaSigningKey() != digest.recover(dharmaSignature)) {
      revert(_revertReason(13));
    }

    // Return the ERC-1271 magic value to indicate success.
    magicValue = _ERC_1271_MAGIC_VALUE;
  }

  /**
   * @notice View function for getting the current Dharma Smart Wallet
   * implementation contract address set on the upgrade beacon.
   * @return The current Dharma Smart Wallet implementation contract.
   */
  function getImplementation() external view returns (address implementation) {
    (bool ok, bytes memory returnData) = address(
      0x000000000026750c571ce882B17016557279ADaa
    ).staticcall("");
    require(ok && returnData.length == 32, "Invalid implementation.");
    implementation = abi.decode(returnData, (address));
  }

  /**
   * @notice Pure function for getting the current Dharma Smart Wallet version.
   * @return The current Dharma Smart Wallet version.
   */
  function getVersion() external pure returns (uint256 version) {
    version = _DHARMA_SMART_WALLET_VERSION;
  }

  /**
   * @notice Perform a series of generic calls to other contracts. If any call
   * fails during execution, the preceding calls will be rolled back, but their
   * original return data will still be accessible. Calls that would otherwise
   * occur after the failed call will not be executed. Note that accounts with
   * no code may not be specified unless value is included, nor may the smart
   * wallet itself or the escape hatch registry. In order to increment the nonce
   * and invalidate the signatures, a call to this function with valid targets,
   * signatutes, and gas will always succeed. To determine whether each call
   * made as part of the action was successful or not, either the corresponding
   * return value or `CallSuccess` and `CallFailure` events can be used - note
   * that even calls that return a success status will be rolled back unless all
   * of the calls returned a success status. Finally, note that this function
   * must currently be implemented as a public function (instead of as an
   * external one) due to an ABIEncoderV2 `UnimplementedFeatureError`.
   * @param calls Call[] A struct containing the target, value, and calldata to
   * provide when making each call.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   * @return An array of structs signifying the status of each call, as well as
   * any data returned from that call. Calls that are not executed will return
   * empty data.
   */
  function executeActionWithAtomicBatchCalls(
    Call[] memory calls,
    uint256 minimumActionGas,
    bytes memory userSignature,
    bytes memory dharmaSignature
  ) public returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Ensure caller and/or supplied signatures are valid and increment nonce.
    (bytes32 actionID, uint256 nonce) = _validateActionAndIncrementNonce(
      ActionType.GenericAtomicBatch,
      abi.encode(calls),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire an CallFailure event.

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _executeActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.executeActionWithAtomicBatchCalls.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._executeActionWithAtomicBatchCallsAtomic.selector, calls
      )
    );

    // Ensure that self-call context has been cleared.
    if (!externalOk) {
      delete _selfCallContext;
    }

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      Call memory currentCall = calls[i];

      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed".
        emit CallSuccess(
          actionID,
          !externalOk, // If another call failed this will have been rolled back
          nonce,
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          actionID,
          nonce,
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          _decodeRevertReason(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  /**
   * @notice Protected function that can only be called from
   * `executeActionWithAtomicBatchCalls` on this contract. It will attempt to
   * perform each specified call, populating the array of results as it goes,
   * unless a failure occurs, at which point it will revert and "return" the
   * array of results as revert data. Otherwise, it will simply return the array
   * upon successful completion of each call. Finally, note that this function
   * must currently be implemented as a public function (instead of as an
   * external one) due to an ABIEncoderV2 `UnimplementedFeatureError`.
   * @param calls Call[] A struct containing the target, value, and calldata to
   * provide when making each call.
   * @return An array of structs signifying the status of each call, as well as
   * any data returned from that call. Calls that are not executed will return
   * empty data. If any of the calls fail, the array will be returned as revert
   * data.
   */
  function _executeActionWithAtomicBatchCallsAtomic(
    Call[] memory calls
  ) public returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.executeActionWithAtomicBatchCalls.selector);

    bool rollBack = false;
    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call.value(
        uint256(calls[i].value)
      )(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide bytes instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  /**
   * @notice Simulate a series of generic calls to other contracts. Signatures
   * are not required, but all calls will be rolled back (and calls will only be
   * simulated up until a failing call is encountered).
   * @param calls Call[] A struct containing the target, value, and calldata to
   * provide when making each call.
   * @return An array of structs signifying the status of each call, as well as
   * any data returned from that call. Calls that are not executed will return
   * empty data.
   */
  function simulateActionWithAtomicBatchCalls(
    Call[] memory calls
  ) public /* view */ returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulateActionWithAtomicBatchCalls.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulateActionWithAtomicBatchCallsAtomic.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation call must revert!");
    }

    // Ensure that self-call context has been cleared.
    delete _selfCallContext;

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      if (!callResults[i].ok) {
        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  /**
   * @notice Protected function that can only be called from
   * `simulateActionWithAtomicBatchCalls` on this contract. It will attempt to
   * perform each specified call, populating the array of results as it goes,
   * unless a failure occurs, at which point it will revert and "return" the
   * array of results as revert data. Regardless, it will roll back all calls at
   * the end of execution — in other words, this call always reverts.
   * @param calls Call[] A struct containing the target, value, and calldata to
   * provide when making each call.
   * @return An array of structs signifying the status of each call, as well as
   * any data returned from that call. Calls that are not executed will return
   * empty data. If any of the calls fail, the array will be returned as revert
   * data.
   */
  function _simulateActionWithAtomicBatchCallsAtomic(
    Call[] memory calls
  ) public returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulateActionWithAtomicBatchCalls.selector);

    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call.value(
        uint256(calls[i].value)
      )(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  /**
   * @notice View function that, given an action type and arguments, will return
   * the action ID or message hash that will need to be prefixed (according to
   * EIP-191 0x45), hashed, and signed by both the user signing key and by the
   * key returned for this smart wallet by the Dharma Key Registry in order to
   * construct a valid signature for a given generic atomic batch action. The
   * current nonce will be used, which means that it will only be valid for the
   * next action taken. Finally, note that this function must currently be
   * implemented as a public function (instead of as an external one) due to an
   * ABIEncoderV2 `UnimplementedFeatureError`.
   * @param calls Call[] A struct containing the target and calldata to provide
   * when making each call.
   * @param calls Call[] A struct containing the target and calldata to provide
   * when making each call.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getNextGenericAtomicBatchActionID(
    Call[] memory calls,
    uint256 minimumActionGas
  ) public view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      ActionType.GenericAtomicBatch,
      abi.encode(calls),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice View function that, given an action type and arguments, will return
   * the action ID or message hash that will need to be prefixed (according to
   * EIP-191 0x45), hashed, and signed by both the user signing key and by the
   * key returned for this smart wallet by the Dharma Key Registry in order to
   * construct a valid signature for a given generic atomic batch action. Any
   * nonce value may be supplied, which enables constructing valid message
   * hashes for multiple future actions ahead of time. Finally, note that this
   * function must currently be implemented as a public function (instead of as
   * an external one) due to an ABIEncoderV2 `UnimplementedFeatureError`.
   * @param calls Call[] A struct containing the target and calldata to provide
   * when making each call.
   * @param calls Call[] A struct containing the target and calldata to provide
   * when making each call.
   * @param nonce uint256 The nonce to use.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getGenericAtomicBatchActionID(
    Call[] memory calls,
    uint256 nonce,
    uint256 minimumActionGas
  ) public view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      ActionType.GenericAtomicBatch,
      abi.encode(calls),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice Internal function for setting a new user signing key. Called by the
   * initializer, by the `setUserSigningKey` function, and by the `recover`
   * function. A `NewUserSigningKey` event will also be emitted.
   * @param userSigningKey address The new user signing key to set on this smart
   * wallet.
   */
  function _setUserSigningKey(address userSigningKey) internal {
    // Ensure that a user signing key is set on this smart wallet.
    if (userSigningKey == address(0)) {
      revert(_revertReason(14));
    }

    _userSigningKey = userSigningKey;
    emit NewUserSigningKey(userSigningKey);
  }

  /**
   * @notice Internal function for withdrawing the total underlying asset
   * balance from the corresponding dToken. Note that the requested balance may
   * not be currently available on Compound, which will cause the withdrawal to
   * fail.
   * @param asset uint256 The asset's ID, either Dai (0) or USDC (1).
   */
  function _withdrawMaxFromDharmaToken(AssetType asset) internal {
    // Get dToken address for the asset type. (No custom ETH withdrawal action.)
    address dToken = asset == AssetType.DAI ? address(_DDAI) : address(_DUSDC);

    // Try to retrieve the current dToken balance for this account.
    ERC20Interface dTokenBalance;
    (bool ok, bytes memory data) = dToken.call(abi.encodeWithSelector(
      dTokenBalance.balanceOf.selector, address(this)
    ));

    uint256 redeemAmount = 0;
    if (ok && data.length == 32) {
      redeemAmount = abi.decode(data, (uint256));
    } else {
      // Something went wrong with the balance check - log an ExternalError.
      _checkDharmaTokenInteractionAndLogAnyErrors(
        asset, dTokenBalance.balanceOf.selector, ok, data
      );
    }

    // Only perform the call to redeem if there is a non-zero balance.
    if (redeemAmount > 0) {
      // Attempt to redeem the underlying balance from the dToken contract.
      (ok, data) = dToken.call(abi.encodeWithSelector(
        // Function selector is the same for all dTokens, so just use dDai's.
        _DDAI.redeem.selector, redeemAmount
      ));

      // Log an external error if something went wrong with the attempt.
      _checkDharmaTokenInteractionAndLogAnyErrors(
        asset, _DDAI.redeem.selector, ok, data
      );
    }
  }

  /**
   * @notice Internal function for transferring the total underlying balance of
   * the corresponding token to a designated recipient. It will return true if
   * tokens were successfully transferred (or there is no balance), signified by
   * the boolean returned by the transfer function, or the call status if the
   * `suppressRevert` boolean is set to true.
   * @param token IERC20 The interface of the token in question.
   * @param recipient address The account that will receive the tokens.
   * @param suppressRevert bool A boolean indicating whether reverts should be
   * suppressed or not. Used by the escape hatch so that a problematic transfer
   * will not block the rest of the call from executing.
   * @return True if tokens were successfully transferred or if there is no
   * balance, else false.
   */
  function _transferMax(
    ERC20Interface token, address recipient, bool suppressRevert
  ) internal returns (bool success) {
    // Get the current balance on the smart wallet for the supplied ERC20 token.
    uint256 balance = 0;
    bool balanceCheckWorked = true;
    if (!suppressRevert) {
      balance = token.balanceOf(address(this));
    } else {
      // Try to retrieve current token balance for this account with 1/2 gas.
      (bool ok, bytes memory data) = address(token).call.gas(gasleft() / 2)(
        abi.encodeWithSelector(token.balanceOf.selector, address(this))
      );

      if (ok && data.length >= 32) {
        balance = abi.decode(data, (uint256));
      } else {
        // Something went wrong with the balance check.
        balanceCheckWorked = false;
      }
    }

    // Only perform the call to transfer if there is a non-zero balance.
    if (balance > 0) {
      if (!suppressRevert) {
        // Perform the transfer and pass along the returned boolean (or revert).
        success = token.transfer(recipient, balance);
      } else {
        // Attempt transfer with 1/2 gas, allow reverts, and return call status.
        (success, ) = address(token).call.gas(gasleft() / 2)(
          abi.encodeWithSelector(token.transfer.selector, recipient, balance)
        );
      }
    } else {
      // Skip the transfer and return true as long as the balance check worked.
      success = balanceCheckWorked;
    }
  }

  /**
   * @notice Internal function for transferring Ether to a designated recipient.
   * It will return true and emit an `EthWithdrawal` event if Ether was
   * successfully transferred - otherwise, it will return false and emit an
   * `ExternalError` event.
   * @param recipient address payable The account that will receive the Ether.
   * @param amount uint256 The amount of Ether to transfer.
   * @return True if Ether was successfully transferred, else false.
   */
  function _transferETH(
    address payable recipient, uint256 amount
  ) internal returns (bool success) {
    // Attempt to transfer any Ether to caller and emit an event if it fails.
    (success, ) = recipient.call.gas(_ETH_TRANSFER_GAS).value(amount)("");
    if (!success) {
      emit ExternalError(recipient, _revertReason(18));
    } else {
      emit EthWithdrawal(amount, recipient);
    }
  }

  /**
   * @notice Internal function for validating supplied gas (if specified),
   * retrieving the signer's public key from the Dharma Key Registry, deriving
   * the action ID, validating the provided caller and/or signatures using that
   * action ID, and incrementing the nonce. This function serves as the
   * entrypoint for all protected "actions" on the smart wallet, and is the only
   * area where these functions should revert (other than due to out-of-gas
   * errors, which can be guarded against by supplying a minimum action gas
   * requirement).
   * @param action uint8 The type of action, designated by it's index. Valid
   * actions include Cancel (0), SetUserSigningKey (1), Generic (2),
   * GenericAtomicBatch (3), DAIWithdrawal (10), USDCWithdrawal (5),
   * ETHWithdrawal (6), SetEscapeHatch (7), RemoveEscapeHatch (8), and
   * DisableEscapeHatch (9).
   * @param arguments bytes ABI-encoded arguments for the action.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getCustomActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getCustomActionID` is prefixed and hashed to create the
   * signed message.
   * @return The nonce of the current action (prior to incrementing it).
   */
  function _validateActionAndIncrementNonce(
    ActionType action,
    bytes memory arguments,
    uint256 minimumActionGas,
    bytes memory userSignature,
    bytes memory dharmaSignature
  ) internal returns (bytes32 actionID, uint256 actionNonce) {
    // Ensure that the current gas exceeds the minimum required action gas.
    // This prevents griefing attacks where an attacker can invalidate a
    // signature without providing enough gas for the action to succeed. Also
    // note that some gas will be spent before this check is reached - supplying
    // ~30,000 additional gas should suffice when submitting transactions. To
    // skip this requirement, supply zero for the minimumActionGas argument.
    if (minimumActionGas != 0) {
      if (gasleft() < minimumActionGas) {
        revert(_revertReason(19));
      }
    }

    // Get the current nonce for the action to be performed.
    actionNonce = _nonce;

    // Get the user signing key that will be used to verify their signature.
    address userSigningKey = _userSigningKey;

    // Get the Dharma signing key that will be used to verify their signature.
    address dharmaSigningKey = _getDharmaSigningKey();

    // Determine the actionID - this serves as the signature hash.
    actionID = _getActionID(
      action,
      arguments,
      actionNonce,
      minimumActionGas,
      userSigningKey,
      dharmaSigningKey
    );

    // Compute the message hash - the hashed, EIP-191-0x45-prefixed action ID.
    bytes32 messageHash = actionID.toEthSignedMessageHash();

    // Actions other than Cancel require both signatures; Cancel only needs one.
    if (action != ActionType.Cancel) {
      // Validate user signing key signature unless it is `msg.sender`.
      if (msg.sender != userSigningKey) {
        if (
          !_validateUserSignature(
            messageHash, action, arguments, userSigningKey, userSignature
          )
        ) {
          revert(_revertReason(20));
        }
      }

      // Validate Dharma signing key signature unless it is `msg.sender`.
      if (msg.sender != dharmaSigningKey) {
        if (dharmaSigningKey != messageHash.recover(dharmaSignature)) {
          revert(_revertReason(21));
        }
      }
    } else {
      // Validate signing key signature unless user or Dharma is `msg.sender`.
      if (msg.sender != userSigningKey && msg.sender != dharmaSigningKey) {
        if (
          dharmaSigningKey != messageHash.recover(dharmaSignature) &&
          !_validateUserSignature(
            messageHash, action, arguments, userSigningKey, userSignature
          )
        ) {
          revert(_revertReason(22));
        }
      }
    }

    // Increment nonce in order to prevent reuse of signatures after the call.
    _nonce++;
  }

  /**
   * @notice Internal function to determine whether a call to a given dToken
   * succeeded, and to emit a relevant ExternalError event if it failed.
   * @param asset uint256 The ID of the asset, either Dai (0) or USDC (1).
   * @param functionSelector bytes4 The function selector that was called on the
   * corresponding dToken of the asset type.
   * @param ok bool A boolean representing whether the call returned or
   * reverted.
   * @param data bytes The data provided by the returned or reverted call.
   * @return True if the interaction was successful, otherwise false. This will
   * be used to determine if subsequent steps in the action should be attempted
   * or not, specifically a transfer following a withdrawal.
   */
  function _checkDharmaTokenInteractionAndLogAnyErrors(
    AssetType asset,
    bytes4 functionSelector,
    bool ok,
    bytes memory data
  ) internal returns (bool success) {
    // Log an external error if something went wrong with the attempt.
    if (ok) {
      if (data.length == 32) {
        uint256 amount = abi.decode(data, (uint256));
        if (amount > 0) {
          success = true;
        } else {
          // Get called contract address, name of contract, and function name.
          (address account, string memory name, string memory functionName) = (
            _getDharmaTokenDetails(asset, functionSelector)
          );

          emit ExternalError(
            account,
            string(
              abi.encodePacked(
                name,
                " gave no tokens calling ",
                functionName,
                "."
              )
            )
          );
        }
      } else {
        // Get called contract address, name of contract, and function name.
        (address account, string memory name, string memory functionName) = (
          _getDharmaTokenDetails(asset, functionSelector)
        );

        emit ExternalError(
          account,
          string(
            abi.encodePacked(
              name,
              " gave bad data calling ",
              functionName,
              "."
            )
          )
        );
      }

    } else {
      // Get called contract address, name of contract, and function name.
      (address account, string memory name, string memory functionName) = (
        _getDharmaTokenDetails(asset, functionSelector)
      );

      // Decode the revert reason in the event one was returned.
      string memory revertReason = _decodeRevertReason(data);

      emit ExternalError(
        account,
        string(
          abi.encodePacked(
            name,
            " reverted calling ",
            functionName,
            ": ",
            revertReason
          )
        )
      );
    }
  }

  /**
   * @notice Internal function to ensure that protected functions can only be
   * called from this contract and that they have the appropriate context set.
   * The self-call context is then cleared. It is used as an additional guard
   * against reentrancy, especially once generic actions are supported by the
   * smart wallet in future versions.
   * @param selfCallContext bytes4 The expected self-call context, equal to the
   * function selector of the approved calling function.
   */
  function _enforceSelfCallFrom(bytes4 selfCallContext) internal {
    // Ensure caller is this contract and self-call context is correctly set.
    if (msg.sender != address(this) || _selfCallContext != selfCallContext) {
      revert(_revertReason(25));
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  /**
   * @notice Internal view function for validating a user's signature. If the
   * user's signing key does not have contract code, it will be validated via
   * ecrecover; otherwise, it will be validated using ERC-1271, passing the
   * message hash that was signed, the action type, and the arguments as data.
   * @param messageHash bytes32 The message hash that is signed by the user. It
   * is derived by prefixing (according to EIP-191 0x45) and hashing an actionID
   * returned from `getCustomActionID`.
   * @param action uint8 The type of action, designated by it's index. Valid
   * actions include Cancel (0), SetUserSigningKey (1), Generic (2),
   * GenericAtomicBatch (3), DAIWithdrawal (10), USDCWithdrawal (5),
   * ETHWithdrawal (6), SetEscapeHatch (7), RemoveEscapeHatch (8), and
   * DisableEscapeHatch (9).
   * @param arguments bytes ABI-encoded arguments for the action.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used.
   * @return A boolean representing the validity of the supplied user signature.
   */
  function _validateUserSignature(
    bytes32 messageHash,
    ActionType action,
    bytes memory arguments,
    address userSigningKey,
    bytes memory userSignature
  ) internal view returns (bool valid) {
    if (!userSigningKey.isContract()) {
      valid = userSigningKey == messageHash.recover(userSignature);
    } else {
      bytes memory data = abi.encode(messageHash, action, arguments);
      valid = (
        ERC1271Interface(userSigningKey).isValidSignature(
          data, userSignature
        ) == _ERC_1271_MAGIC_VALUE
      );
    }
  }

  /**
   * @notice Internal view function to get the Dharma signing key for the smart
   * wallet from the Dharma Key Registry. This key can be set for each specific
   * smart wallet - if none has been set, a global fallback key will be used.
   * @return The address of the Dharma signing key, or public key corresponding
   * to the secondary signer.
   */
  function _getDharmaSigningKey() internal view returns (
    address dharmaSigningKey
  ) {
    dharmaSigningKey = _DHARMA_KEY_REGISTRY.getKey();
  }

  /**
   * @notice Internal view function that, given an action type and arguments,
   * will return the action ID or message hash that will need to be prefixed
   * (according to EIP-191 0x45), hashed, and signed by the key designated by
   * the Dharma Key Registry in order to construct a valid signature for the
   * corresponding action. The current nonce will be supplied to this function
   * when reconstructing an action ID during protected function execution based
   * on the supplied parameters.
   * @param action uint8 The type of action, designated by it's index. Valid
   * actions include Cancel (0), SetUserSigningKey (1), Generic (2),
   * GenericAtomicBatch (3), DAIWithdrawal (10), USDCWithdrawal (5),
   * ETHWithdrawal (6), SetEscapeHatch (7), RemoveEscapeHatch (8), and
   * DisableEscapeHatch (9).
   * @param arguments bytes ABI-encoded arguments for the action.
   * @param nonce uint256 The nonce to use.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param dharmaSigningKey address The address of the secondary key, or public
   * key corresponding to the secondary signer.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function _getActionID(
    ActionType action,
    bytes memory arguments,
    uint256 nonce,
    uint256 minimumActionGas,
    address userSigningKey,
    address dharmaSigningKey
  ) internal view returns (bytes32 actionID) {
    // actionID is constructed according to EIP-191-0x45 to prevent replays.
    actionID = keccak256(
      abi.encodePacked(
        address(this),
        _DHARMA_SMART_WALLET_VERSION,
        userSigningKey,
        dharmaSigningKey,
        nonce,
        minimumActionGas,
        action,
        arguments
      )
    );
  }

  /**
   * @notice Internal pure function to get the dToken address, it's name, and
   * the name of the called function, based on a supplied asset type and
   * function selector. It is used to help construct ExternalError events.
   * @param asset uint256 The ID of the asset, either Dai (0) or USDC (1).
   * @param functionSelector bytes4 The function selector that was called on the
   * corresponding dToken of the asset type.
   * @return The dToken address, it's name, and the name of the called function.
   */
  function _getDharmaTokenDetails(
    AssetType asset,
    bytes4 functionSelector
  ) internal pure returns (
    address account,
    string memory name,
    string memory functionName
  ) {
    if (asset == AssetType.DAI) {
      account = address(_DDAI);
      name = "Dharma Dai";
    } else {
      account = address(_DUSDC);
      name = "Dharma USD Coin";
    }

    // Note: since both dTokens have the same interface, just use dDai's.
    if (functionSelector == _DDAI.mint.selector) {
      functionName = "mint";
    } else {
      if (functionSelector == ERC20Interface(account).balanceOf.selector) {
        functionName = "balanceOf";
      } else {
        functionName = string(abi.encodePacked(
          "redeem",
          functionSelector == _DDAI.redeem.selector ? "" : "Underlying"
        ));
      }
    }
  }

  /**
   * @notice Internal view function to ensure that a given `to` address provided
   * as part of a generic action is valid. Calls cannot be performed to accounts
   * without code or back into the smart wallet itself. Additionally, generic
   * calls cannot supply the address of the Dharma Escape Hatch registry - the
   * specific, designated functions must be used in order to make calls into it.
   * @param to address The address that will be targeted by the generic call.
   */
  function _ensureValidGenericCallTarget(address to) internal view {
    if (!to.isContract()) {
      revert(_revertReason(26));
    }

    if (to == address(this)) {
      revert(_revertReason(27));
    }

    if (to == address(_ESCAPE_HATCH_REGISTRY)) {
      revert(_revertReason(28));
    }
  }

  /**
   * @notice Internal pure function to ensure that a given action type is a
   * "custom" action type (i.e. is not a generic action type) and to construct
   * the "arguments" input to an actionID based on that action type.
   * @param action uint8 The type of action, designated by it's index. Valid
   * custom actions include Cancel (0), SetUserSigningKey (1),
   * DAIWithdrawal (10), USDCWithdrawal (5), ETHWithdrawal (6),
   * SetEscapeHatch (7), RemoveEscapeHatch (8), and DisableEscapeHatch (9).
   * @param amount uint256 The amount to withdraw for Withdrawal actions. This
   * value is ignored for all non-withdrawal action types.
   * @param recipient address The account to transfer withdrawn funds to or the
   * new user signing key. This value is ignored for Cancel, RemoveEscapeHatch,
   * and DisableEscapeHatch action types.
   * @return A bytes array containing the arguments that will be provided as
   * a component of the inputs when constructing a custom action ID.
   */
  function _validateCustomActionTypeAndGetArguments(
    ActionType action, uint256 amount, address recipient
  ) internal pure returns (bytes memory arguments) {
    // Ensure that the action type is a valid custom action type.
    bool validActionType = (
      action == ActionType.Cancel ||
      action == ActionType.SetUserSigningKey ||
      action == ActionType.DAIWithdrawal ||
      action == ActionType.USDCWithdrawal ||
      action == ActionType.ETHWithdrawal ||
      action == ActionType.SetEscapeHatch ||
      action == ActionType.RemoveEscapeHatch ||
      action == ActionType.DisableEscapeHatch
    );
    if (!validActionType) {
      revert(_revertReason(29));
    }

    // Use action type to determine parameters to include in returned arguments.
    if (
      action == ActionType.Cancel ||
      action == ActionType.RemoveEscapeHatch ||
      action == ActionType.DisableEscapeHatch
    ) {
      // Ignore parameters for Cancel, RemoveEscapeHatch, or DisableEscapeHatch.
      arguments = abi.encode();
    } else if (
      action == ActionType.SetUserSigningKey ||
      action == ActionType.SetEscapeHatch
    ) {
      // Ignore `amount` parameter for other, non-withdrawal actions.
      arguments = abi.encode(recipient);
    } else {
      // Use both `amount` and `recipient` parameters for withdrawals.
      arguments = abi.encode(amount, recipient);
    }
  }

  /**
   * @notice Internal pure function to decode revert reasons. The revert reason
   * prefix is removed and the remaining string argument is decoded.
   * @param revertData bytes The raw data supplied alongside the revert.
   * @return The decoded revert reason string.
   */
  function _decodeRevertReason(
    bytes memory revertData
  ) internal pure returns (string memory revertReason) {
    // Solidity prefixes revert reason with 0x08c379a0 -> Error(string) selector
    if (
      revertData.length > 68 && // prefix (4) + position (32) + length (32)
      revertData[0] == byte(0x08) &&
      revertData[1] == byte(0xc3) &&
      revertData[2] == byte(0x79) &&
      revertData[3] == byte(0xa0)
    ) {
      // Get the revert reason without the prefix from the revert data.
      bytes memory revertReasonBytes = new bytes(revertData.length - 4);
      for (uint256 i = 4; i < revertData.length; i++) {
        revertReasonBytes[i - 4] = revertData[i];
      }

      // Decode the resultant revert reason as a string.
      revertReason = abi.decode(revertReasonBytes, (string));
    } else {
      // Simply return the default, with no revert reason.
      revertReason = _revertReason(uint256(-1));
    }
  }

  /**
   * @notice Internal pure function call the revert reason helper contract,
   * supplying a revert "code" and receiving back a revert reason string.
   * @param code uint256 The code for the revert reason.
   * @return The revert reason string.
   */
  function _revertReason(
    uint256 code
  ) internal pure returns (string memory reason) {
    reason = _REVERT_REASON_HELPER.reason(code);
  }
}