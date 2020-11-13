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
    bytes data,
    bytes returnData
  );

  event CallFailure(
    bytes32 actionID,
    uint256 nonce,
    address to,
    bytes data,
    string revertReason
  );

  // ABIEncoderV2 uses an array of Calls for executing generic batch calls.
  struct Call {
    address to;
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

  function escape() external;
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


interface CTokenInterface {
  function redeem(uint256 redeemAmount) external returns (uint256 err);
  function transfer(address recipient, uint256 value) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);

  function balanceOf(address account) external view returns (uint256 balance);
  function allowance(address owner, address spender) external view returns (uint256);
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


interface USDCV1Interface {
  function isBlacklisted(address _account) external view returns (bool);
  function paused() external view returns (bool);
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


interface TradeHelperInterface {
  function tradeEthForDai(
    uint256 daiExpected, address target, bytes calldata data
  ) external payable returns (uint256 daiReceived);
}


interface RevertReasonHelperInterface {
  function reason(uint256 code) external pure returns (string memory);
}


interface EtherizedInterface {
  function triggerEtherTransfer(
    address payable target, uint256 value
  ) external returns (bool success);
}


interface DharmaDaiExchangerInterface {
  function mintTo(
    address account, uint256 daiToSupply
  ) external returns (uint256 dDaiMinted);
  function redeemUnderlyingTo(
    address account, uint256 daiToReceive
  ) external returns (uint256 dDaiBurned);
}


interface ConfigurationRegistryInterface {
  function get(bytes32 key) external view returns (bytes32 value);
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
 * @title DharmaSmartWalletImplementationV12
 * @author 0age
 * @notice The V12 implementation for the Dharma smart wallet is a non-custodial,
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
 * smart wallet instance. V12 uses the dai <> dDai exchanger to save gas when
 * minting and redeeming dDai, and adds support for limit orders using the new
 * DharmaTradeBotV1 contract.
 */
contract DharmaSmartWalletImplementationV12 is
  DharmaSmartWalletImplementationV1Interface,
  DharmaSmartWalletImplementationV3Interface,
  DharmaSmartWalletImplementationV4Interface,
  DharmaSmartWalletImplementationV7Interface,
  DharmaSmartWalletImplementationV8Interface,
  DharmaSmartWalletImplementationV12Interface,
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
  uint256 internal constant _DHARMA_SMART_WALLET_VERSION = 12;

  // DharmaKeyRegistryV2 holds a public key for verifying meta-transactions.
  DharmaKeyRegistryInterface internal constant _DHARMA_KEY_REGISTRY = (
    DharmaKeyRegistryInterface(0x000000000D38df53b45C5733c7b34000dE0BDF52)
  );
  
  // Account recovery is facilitated using a hard-coded recovery manager,
  // controlled by Dharma and implementing appropriate timelocks.
  address internal constant _ACCOUNT_RECOVERY_MANAGER = address(
    0x0000000000DfEd903aD76996FC07BF89C0127B1E
  );

  // Users can designate an "escape hatch" account with the ability to sweep all
  // funds from their smart wallet by using the Dharma Escape Hatch Registry.
  DharmaEscapeHatchRegistryInterface internal constant _ESCAPE_HATCH_REGISTRY = (
    DharmaEscapeHatchRegistryInterface(0x00000000005280B515004B998a944630B6C663f8)
  );

  // Interface with dDai, dUSDC, Dai, USDC, Sai, cSai, cDai, cUSDC, & migrator.
  DTokenInterface internal constant _DDAI = DTokenInterface(
    0x00000000001876eB1444c986fD502e618c587430 // mainnet
  );

  DTokenInterface internal constant _DUSDC = DTokenInterface(
    0x00000000008943c65cAf789FFFCF953bE156f6f8 // mainnet
  );

  ERC20Interface internal constant _DAI = ERC20Interface(
    0x6B175474E89094C44Da98b954EedeAC495271d0F // mainnet
  );

  ERC20Interface internal constant _USDC = ERC20Interface(
    0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48 // mainnet
  );

  CTokenInterface internal constant _CDAI = CTokenInterface(
    0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643 // mainnet
  );

  CTokenInterface internal constant _CUSDC = CTokenInterface(
    0x39AA39c021dfbaE8faC545936693aC917d5E7563 // mainnet
  );
  
  // The "trade helper" facilitates Eth-to-Dai trades in an isolated context.
  TradeHelperInterface internal constant _TRADE_HELPER = TradeHelperInterface(
    0x421816CDFe2073945173c0c35799ec21261fB399
  );

  // The "exchanger" facilitates cheaper minting and redeeming for Dharma Dai.
  DharmaDaiExchangerInterface internal constant _DDAI_EXCHANGER = (
    DharmaDaiExchangerInterface(
      0x83E02F0b169be417C38d1216fc2a5134C48Af44a
    )
  );

  // The "revert reason helper" contains a collection of revert reason strings.
  RevertReasonHelperInterface internal constant _REVERT_REASON_HELPER = (
    RevertReasonHelperInterface(0x9C0ccB765D3f5035f8b5Dd30fE375d5F4997D8E4)
  );
  
  ConfigurationRegistryInterface internal constant _CONFIG_REGISTRY = (
    ConfigurationRegistryInterface(0xC5C0ead7Df3CeFC45c8F4592E3a0f1500949E75D)
  );
  
  // The "Trade Bot" enables limit orders using unordered meta-transactions.
  address internal constant _TRADE_BOT = address(
    0x8bFB7aC05bF9bDC6Bc3a635d4dd209c8Ba39E554
  );
  
  bytes32 internal constant _ENABLE_USDC_MINTING_KEY = bytes32(
    0x596746115f08448433597980d42b4541c0197187d07ffad9c7f66a471c49dbba
  ); // keccak256("allowAvailableUSDCToBeUsedToMintCUSDC")

  // Compound returns a value of 0 to indicate success, or lack of an error.
  uint256 internal constant _COMPOUND_SUCCESS = 0;

  // ERC-1271 must return this magic value when `isValidSignature` is called.
  bytes4 internal constant _ERC_1271_MAGIC_VALUE = bytes4(0x20c13b0b);

  // Minimum supported deposit & non-maximum withdrawal size is .001 underlying.
  uint256 private constant _JUST_UNDER_ONE_1000th_DAI = 999999999999999;
  uint256 private constant _JUST_UNDER_ONE_1000th_USDC = 999;

  // Specify the amount of gas to supply when making Ether transfers.
  uint256 private constant _ETH_TRANSFER_GAS = 4999;
  
  constructor() public {
    assert(
      _ENABLE_USDC_MINTING_KEY == keccak256(
        bytes("allowAvailableUSDCToBeUsedToMintCUSDC")
      )
    );
  }

  /**
   * @notice Accept Ether in the fallback.
   */
  function () external payable {}

  /**
   * @notice In the initializer, set up the initial user signing key, set
   * approval on the Dharma Dai and Dharma USD Coin contracts, and deposit any
   * Dai or USDC already at this address to receive dDai or dUSDC. Note that
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

    // Approve the dDai contract to transfer Dai on behalf of this contract.
    if (_setFullApproval(AssetType.DAI)) {
      // Get the current Dai balance on this contract.
      uint256 daiBalance = _DAI.balanceOf(address(this));

      // Try to deposit the full Dai balance to Dharma Dai.
      _depositDharmaToken(AssetType.DAI, daiBalance);
    }

    // Approve the dUSDC contract to transfer USDC on behalf of this contract.
    if (_setFullApproval(AssetType.USDC)) {
      // Get the current USDC balance on this contract.
      uint256 usdcBalance = _USDC.balanceOf(address(this));

      // Try to deposit the full Dai balance to Dharma USDC.
      _depositDharmaToken(AssetType.USDC, usdcBalance);
    }
  }

  /**
   * @notice Deposit all Dai and USDC currently residing at this address and
   * receive Dharma Dai or Dharma USD Coin in return. Note that "repay" is not
   * currently implemented, though it may be in a future implementation. If some
   * step of this function fails, the function itself will still succeed, but an
   * `ExternalError` with information on what went wrong will be emitted.
   */
  function repayAndDeposit() external {
    // Get the current Dai balance on this contract.
    uint256 daiBalance = _DAI.balanceOf(address(this));

    // If there is any Dai balance, check for adequate approval for dDai.
    if (daiBalance > 0) {
      uint256 daiAllowance = _DAI.allowance(address(this), address(_DDAI_EXCHANGER));
      // If allowance is insufficient, try to set it before depositing.
      if (daiAllowance < daiBalance) {
        if (_setFullApproval(AssetType.DAI)) {
          // Deposit the full available Dai balance to Dharma Dai.
          _depositDharmaToken(AssetType.DAI, daiBalance);
        }
      // Otherwise, just go ahead and try the Dai deposit.
      } else {
        // Deposit the full available Dai balance to Dharma Dai.
        _depositDharmaToken(AssetType.DAI, daiBalance);
      }
    }

    // Get the current USDC balance on this contract.
    uint256 usdcBalance = _USDC.balanceOf(address(this));

    // If there is any USDC balance, check for adequate approval for dUSDC.
    if (usdcBalance > 0) {
      uint256 usdcAllowance = _USDC.allowance(address(this), address(_DUSDC));
      // If allowance is insufficient, try to set it before depositing.
      if (usdcAllowance < usdcBalance) {
        if (_setFullApproval(AssetType.USDC)) {
          // Deposit the full available USDC balance to Dharma USDC.
          _depositDharmaToken(AssetType.USDC, usdcBalance);
        }
      // Otherwise, just go ahead and try the USDC deposit.
      } else {
        // Deposit the full available USDC balance to Dharma USDC.
        _depositDharmaToken(AssetType.USDC, usdcBalance);
      }
    }
  }

  /**
   * @notice Withdraw Dai to a provided recipient address by redeeming the
   * underlying Dai from the dDai contract and transferring it to the recipient.
   * All Dai in Dharma Dai and in the smart wallet itself can be withdrawn by
   * providing an amount of uint256(-1) or 0xfff...fff. This function can be
   * called directly by the account set as the global key on the Dharma Key
   * Registry, or by any relayer that provides a signed message from the same
   * keyholder. The nonce used for the signature must match the current nonce on
   * the smart wallet, and gas supplied to the call must exceed the specified
   * minimum action gas, plus the gas that will be spent before the gas check is
   * reached - usually somewhere around 25,000 gas. If the withdrawal fails, an
   * `ExternalError` with additional details on what went wrong will be emitted.
   * Note that some dust may still be left over, even in the event of a max
   * withdrawal, due to the fact that Dai has a higher precision than dDai. Also
   * note that the withdrawal will fail in the event that Compound does not have
   * sufficient Dai available to withdraw.
   * @param amount uint256 The amount of Dai to withdraw.
   * @param recipient address The account to transfer the withdrawn Dai to.
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
   * @return True if the withdrawal succeeded, otherwise false.
   */
  function withdrawDai(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.DAIWithdrawal,
      abi.encode(amount, recipient),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Ensure that an amount of at least 0.001 Dai has been supplied.
    if (amount <= _JUST_UNDER_ONE_1000th_DAI) {
      revert(_revertReason(0));
    }

    // Ensure that a non-zero recipient has been supplied.
    if (recipient == address(0)) {
      revert(_revertReason(1));
    }

    // Set the self-call context in order to call _withdrawDaiAtomic.
    _selfCallContext = this.withdrawDai.selector;

    // Make the atomic self-call - if redeemUnderlying fails on dDai, it will
    // succeed but nothing will happen except firing an ExternalError event. If
    // the second part of the self-call (the Dai transfer) fails, it will revert
    // and roll back the first part of the call as well as fire an ExternalError
    // event after returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._withdrawDaiAtomic.selector, amount, recipient
    ));

    // If the atomic call failed, emit an event signifying a transfer failure.
    if (!ok) {
      emit ExternalError(address(_DAI), _revertReason(2));
    } else {
      // Set ok to false if the call succeeded but the withdrawal failed.
      ok = abi.decode(returnData, (bool));
    }
  }

  /**
   * @notice Protected function that can only be called from `withdrawDai` on
   * this contract. It will attempt to withdraw the supplied amount of Dai, or
   * the maximum amount if specified using `uint256(-1)`, to the supplied
   * recipient address by redeeming the underlying Dai from the dDai contract
   * and transferring it to the recipient. An ExternalError will be emitted and
   * the transfer will be skipped if the call to `redeem` or `redeemUnderlying`
   * fails, and any revert will be caught by `withdrawDai` and diagnosed in
   * order to emit an appropriate `ExternalError` as well.
   * @param amount uint256 The amount of Dai to withdraw.
   * @param recipient address The account to transfer the withdrawn Dai to.
   * @return True if the withdrawal succeeded, otherwise false.
   */
  function _withdrawDaiAtomic(
    uint256 amount,
    address recipient
  ) external returns (bool success) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.withdrawDai.selector);

    // If amount = 0xfff...fff, withdraw the maximum amount possible.
    bool maxWithdraw = (amount == uint256(-1));
    if (maxWithdraw) {
      // First attempt to redeem all dDai if there is a balance.
      _withdrawMaxFromDharmaToken(AssetType.DAI);

      // Then transfer all Dai to recipient if there is a balance.
      require(_transferMax(_DAI, recipient, false));
      success = true;
    } else {
      // Attempt to withdraw specified Dai from Dharma Dai before proceeding.
      if (_withdrawFromDharmaToken(AssetType.DAI, amount)) {
        // At this point Dai transfer should never fail - wrap it just in case.
        require(_DAI.transfer(recipient, amount));
        success = true;
      }
    }
  }

  /**
   * @notice Withdraw USDC to a provided recipient address by redeeming the
   * underlying USDC from the dUSDC contract and transferring it to recipient.
   * All USDC in Dharma USD Coin and in the smart wallet itself can be withdrawn
   * by providing an amount of uint256(-1) or 0xfff...fff. This function can be
   * called directly by the account set as the global key on the Dharma Key
   * Registry, or by any relayer that provides a signed message from the same
   * keyholder. The nonce used for the signature must match the current nonce on
   * the smart wallet, and gas supplied to the call must exceed the specified
   * minimum action gas, plus the gas that will be spent before the gas check is
   * reached - usually somewhere around 25,000 gas. If the withdrawal fails, an
   * `ExternalError` with additional details on what went wrong will be emitted.
   * Note that the USDC contract can be paused and also allows for blacklisting
   * accounts - either of these possibilities may cause a withdrawal to fail. In
   * addition, Compound may not have sufficient USDC available at the time to
   * withdraw.
   * @param amount uint256 The amount of USDC to withdraw.
   * @param recipient address The account to transfer the withdrawn USDC to.
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
   * @return True if the withdrawal succeeded, otherwise false.
   */
  function withdrawUSDC(
    uint256 amount,
    address recipient,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok) {
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.USDCWithdrawal,
      abi.encode(amount, recipient),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Ensure that an amount of at least 0.001 USDC has been supplied.
    if (amount <= _JUST_UNDER_ONE_1000th_USDC) {
      revert(_revertReason(3));
    }

    // Ensure that a non-zero recipient has been supplied.
    if (recipient == address(0)) {
      revert(_revertReason(1));
    }

    // Set the self-call context in order to call _withdrawUSDCAtomic.
    _selfCallContext = this.withdrawUSDC.selector;

    // Make the atomic self-call - if redeemUnderlying fails on dUSDC, it will
    // succeed but nothing will happen except firing an ExternalError event. If
    // the second part of the self-call (USDC transfer) fails, it will revert
    // and roll back the first part of the call as well as fire an ExternalError
    // event after returning from the failed call.
    bytes memory returnData;
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._withdrawUSDCAtomic.selector, amount, recipient
    ));
    if (!ok) {
      // Find out why USDC transfer reverted (doesn't give revert reasons).
      _diagnoseAndEmitUSDCSpecificError(_USDC.transfer.selector);
    } else {
      // Set ok to false if the call succeeded but the withdrawal failed.
      ok = abi.decode(returnData, (bool));
    }
  }

  /**
   * @notice Protected function that can only be called from `withdrawUSDC` on
   * this contract. It will attempt to withdraw the supplied amount of USDC, or
   * the maximum amount if specified using `uint256(-1)`, to the supplied
   * recipient address by redeeming the underlying USDC from the dUSDC contract
   * and transferring it to the recipient. An ExternalError will be emitted and
   * the transfer will be skipped if the call to `redeemUnderlying` fails, and
   * any revert will be caught by `withdrawUSDC` and diagnosed in order to emit
   * an appropriate ExternalError as well.
   * @param amount uint256 The amount of USDC to withdraw.
   * @param recipient address The account to transfer the withdrawn USDC to.
   * @return True if the withdrawal succeeded, otherwise false.
   */
  function _withdrawUSDCAtomic(
    uint256 amount,
    address recipient
  ) external returns (bool success) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.withdrawUSDC.selector);

    // If amount = 0xfff...fff, withdraw the maximum amount possible.
    bool maxWithdraw = (amount == uint256(-1));
    if (maxWithdraw) {
      // Attempt to redeem all dUSDC from Dharma USDC if there is a balance.
      _withdrawMaxFromDharmaToken(AssetType.USDC);

      // Then transfer all USDC to recipient if there is a balance.
      require(_transferMax(_USDC, recipient, false));
      success = true;
    } else {
      // Attempt to withdraw specified USDC from Dharma USDC before proceeding.
      if (_withdrawFromDharmaToken(AssetType.USDC, amount)) {
        // Ensure that the USDC transfer does not fail.
        require(_USDC.transfer(recipient, amount));
        success = true;
      }
    }
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
   * @notice Perform a generic call to another contract. Note that accounts with
   * no code may not be specified, nor may the smart wallet itself or the escape
   * hatch registry. In order to increment the nonce and invalidate the
   * signatures, a call to this function with a valid target, signatutes, and
   * gas will always succeed. To determine whether the call made as part of the
   * action was successful or not, either the return values or the `CallSuccess`
   * or `CallFailure` event can be used.
   * @param to address The contract to call.
   * @param data bytes The calldata to provide when making the call.
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
   * @return A boolean signifying the status of the call, as well as any data
   * returned from the call.
   */
  function executeAction(
    address to,
    bytes calldata data,
    uint256 minimumActionGas,
    bytes calldata userSignature,
    bytes calldata dharmaSignature
  ) external returns (bool ok, bytes memory returnData) {
    // Ensure that the `to` address is a contract and is not this contract.
    _ensureValidGenericCallTarget(to);

    // Ensure caller and/or supplied signatures are valid and increment nonce.
    (bytes32 actionID, uint256 nonce) = _validateActionAndIncrementNonce(
      ActionType.Generic,
      abi.encode(to, data),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this action. However, the call
    // itself may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire an CallFailure event.

    // Perform the action via low-level call and set return values using result.
    (ok, returnData) = to.call(data);

    // Emit a CallSuccess or CallFailure event based on the outcome of the call.
    if (ok) {
      // Note: while the call succeeded, the action may still have "failed"
      // (for example, successful calls to Compound can still return an error).
      emit CallSuccess(actionID, false, nonce, to, data, returnData);
    } else {
      // Note: while the call failed, the nonce will still be incremented, which
      // will invalidate all supplied signatures.
      emit CallFailure(actionID, nonce, to, data, _decodeRevertReason(returnData));
    }
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
   * can then call `escape()` at any point to "sweep" the entire Dai, USDC,
   * residual cDai, cUSDC, dDai, dUSDC, and Ether balance from the smart wallet.
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
   * @notice Swap Ether for Dai and use it to mint Dharma Dai. The trade is
   * facilitated by a "trade helper" contract in order to protect against
   * malicious calls related to processing swaps via potentially unsafe call
   * targets or other parameters. In the event that a swap does not result in
   * sufficient Dai being received, the swap will be rolled back. In either
   * case the nonce will still be incremented as long as signatures are valid.
   * @param ethToSupply uint256 The Ether to supply as part of the swap.
   * @param minimumDaiReceived uint256 The minimum amount of Dai that must be
   * received in exchange for the supplied Ether.
   * @param target address The contract that the trade helper should call in
   * order to facilitate the swap.
   * @param data bytes The payload that will be passed to the target, along with
   * the supplied Ether, by the trade helper in order to facilitate the swap.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @param userSignature bytes A signature that resolves to the public key
   * set for this account in storage slot zero, `_userSigningKey`. If the user
   * signing key is not a contract, ecrecover will be used; otherwise, ERC1271
   * will be used. A unique hash returned from `getEthForDaiActionID` is prefixed
   * and hashed to create the message hash for the signature.
   * @param dharmaSignature bytes A signature that resolves to the public key
   * returned for this account from the Dharma Key Registry. A unique hash
   * returned from `getEthForDaiActionIDActionID` is prefixed and hashed to
   * create the signed message.
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
    // Ensure caller and/or supplied signatures are valid and increment nonce.
    _validateActionAndIncrementNonce(
      ActionType.TradeEthForDai,
      abi.encode(ethToSupply, minimumDaiReceived, target, data),
      minimumActionGas,
      userSignature,
      dharmaSignature
    );

    // Ensure that an amount of at least 0.001 Dai will be received.
    if (minimumDaiReceived <= _JUST_UNDER_ONE_1000th_DAI) {
      revert(_revertReason(31));
    }

    // Set the self-call context in order to call _tradeEthForDaiAndMintDDaiAtomic.
    _selfCallContext = this.tradeEthForDaiAndMintDDai.selector;

    // Make the atomic self-call - if the swap fails or the received dai is not
    // greater than or equal to the requirement, it will revert and roll back the
    // atomic call as well as fire an ExternalError. If dDai is not successfully
    // minted, the swap will succeed but an ExternalError for dDai will be fired.
    (ok, returnData) = address(this).call(abi.encodeWithSelector(
      this._tradeEthForDaiAndMintDDaiAtomic.selector,
      ethToSupply, minimumDaiReceived, target, data
    ));

    // If the atomic call failed, emit an event signifying a trade failure.
    if (!ok) {
      emit ExternalError(
        address(_TRADE_HELPER), _decodeRevertReason(returnData)
      );
    }
  }
  
  function _tradeEthForDaiAndMintDDaiAtomic(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data
  ) external {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.tradeEthForDaiAndMintDDai.selector);
    
    // Do swap using supplied Ether amount, minimum Dai, target, and data.
    uint256 daiReceived = _TRADE_HELPER.tradeEthForDai.value(ethToSupply)(
      minimumDaiReceived, target, data
    );
    
    // Ensure that sufficient Dai was returned as a result of the swap. 
    if (daiReceived < minimumDaiReceived) {
      revert(_revertReason(32));
    }
    
    // Attempt to deposit the dai received and mint Dharma Dai.
    _depositDharmaToken(AssetType.DAI, daiReceived);
  }

  /**
   * @notice Allow the designated escape hatch account to redeem and "sweep"
   * the entire Dai, USDC, residual dDai, dUSDC, cDai, cUSDC, & Ether balance
   * from the smart wallet. The call will revert for any other caller, or if
   * there is no escape hatch account on this smart wallet. First, an attempt
   * will be made to redeem any dDai or dUSDC that is currently deposited in a
   * dToken. Then, attempts will be made to transfer any balance in Dai, USDC,
   * residual cDai & cUSDC, and Ether to the escape hatch account. If any
   * portion of this operation does not succeed, it will simply be skipped,
   * allowing the rest of the operation to proceed. Finally, an `Escaped` event
   * will be emitted. No value is returned from this function - it will either
   * succeed or revert.
   */
  function escape() external {
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

    // Attempt to redeem all dDai for Dai on Dharma Dai.
    _withdrawMaxFromDharmaToken(AssetType.DAI);

    // Attempt to redeem all dUSDC for USDC on Dharma USDC.
    _withdrawMaxFromDharmaToken(AssetType.USDC);

    // Attempt to transfer the total Dai balance to the caller.
    _transferMax(_DAI, msg.sender, true);

    // Attempt to transfer the total USDC balance to the caller.
    _transferMax(_USDC, msg.sender, true);

    // Attempt to transfer any residual cDai to the caller.
    _transferMax(ERC20Interface(address(_CDAI)), msg.sender, true);

    // Attempt to transfer any residual cUSDC to the caller.
    _transferMax(ERC20Interface(address(_CUSDC)), msg.sender, true);

    // Attempt to transfer any residual dDai to the caller.
    _transferMax(ERC20Interface(address(_DDAI)), msg.sender, true);

    // Attempt to transfer any residual dUSDC to the caller.
    _transferMax(ERC20Interface(address(_DUSDC)), msg.sender, true);

    // Determine if there is Ether at this address that should be transferred.
    uint256 balance = address(this).balance;
    if (balance > 0) {
      // Attempt to transfer any Ether to caller and emit an appropriate event.
      _transferETH(msg.sender, balance);
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
    revert();
  }

  /**
   * @notice This call is no longer supported.
   */
  function migrateCSaiToDDai() external {
    revert();
  }

  /**
   * @notice Redeem all available cDAI for Dai and use that Dai to mint dDai. If
   * any step in the process fails, the call will revert and prior steps will be
   * rolled back. Also note that existing Sai and Dai are not included as part
   * of this operation.
   */
  function migrateCDaiToDDai() external {
     _migrateCTokenToDToken(AssetType.DAI);
  }

  /**
   * @notice Redeem all available cUSDC for USDC and use that USDC to mint
   * dUSDC. If any step in the process fails, the call will revert and prior
   * steps will be rolled back. Also note that existing USDC is not included as
   * part of this operation.
   */
  function migrateCUSDCToDUSDC() external {
     _migrateCTokenToDToken(AssetType.USDC);
  }

  /**
   * @notice View function to retrieve the Dai and USDC balances held by the
   * smart wallet, both directly and held in Dharma Dai and Dharma USD Coin, as
   * well as the Ether balance (the underlying dEther balance will always return
   * zero in this implementation, as there is no dEther yet).
   * @return The Dai balance, the USDC balance, the Ether balance, the
   * underlying Dai balance of the dDai balance, and the underlying USDC balance
   * of the dUSDC balance (zero will always be returned as the underlying Ether
   * balance of the dEther balance in this implementation).
   */
  function getBalances() external view returns (
    uint256 daiBalance,
    uint256 usdcBalance,
    uint256 etherBalance,
    uint256 dDaiUnderlyingDaiBalance,
    uint256 dUsdcUnderlyingUsdcBalance,
    uint256 dEtherUnderlyingEtherBalance // always returns 0
  ) {
    daiBalance = _DAI.balanceOf(address(this));
    usdcBalance = _USDC.balanceOf(address(this));
    etherBalance = address(this).balance;
    dDaiUnderlyingDaiBalance = _DDAI.balanceOfUnderlying(address(this));
    dUsdcUnderlyingUsdcBalance = _DUSDC.balanceOfUnderlying(address(this));
    dEtherUnderlyingEtherBalance = 0;
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
   * custom actions in V8 include Cancel (0), SetUserSigningKey (1),
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
   * custom actions in V8 include Cancel (0), SetUserSigningKey (1),
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
   * @notice View function that will return the action ID or message hash that
   * will need to be prefixed (according to EIP-191 0x45), hashed, and signed by
   * both the user signing key and by the key returned for this smart wallet by
   * the Dharma Key Registry in order to construct a valid signature for a given
   * generic action. The current nonce will be used, which means that it will
   * only be valid for the next action taken.
   * @param to address The target to call into as part of the generic action.
   * @param data bytes The data to supply when calling into the target.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getNextGenericActionID(
    address to,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      ActionType.Generic,
      abi.encode(to, data),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice View function that will return the action ID or message hash that
   * will need to be prefixed (according to EIP-191 0x45), hashed, and signed by
   * both the user signing key and by the key returned for this smart wallet by
   * the Dharma Key Registry in order to construct a valid signature for a given
   * generic action. Any nonce value may be supplied, which enables constructing
   * valid message hashes for multiple future actions ahead of time.
   * @param to address The target to call into as part of the generic action.
   * @param data bytes The data to supply when calling into the target.
   * @param nonce uint256 The nonce to use.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getGenericActionID(
    address to,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      ActionType.Generic,
      abi.encode(to, data),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice View function that will return the action ID or message hash that
   * will need to be prefixed (according to EIP-191 0x45), hashed, and signed by
   * both the user signing key and by the key returned for this smart wallet by
   * the Dharma Key Registry in order to construct a valid signature for an
   * Eth-to-Dai swap. The current nonce will be used, which means that it will
   * only be valid for the next action taken.
   * @param ethToSupply uint256 The Ether to supply as part of the swap.
   * @param minimumDaiReceived uint256 The minimum amount of Dai that must be
   * received in exchange for the supplied Ether.
   * @param target address The contract that the trade helper should call in
   * order to facilitate the swap.
   * @param data bytes The payload that will be passed to the target, along with
   * the supplied Ether, by the trade helper in order to facilitate the swap.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */
  function getNextEthForDaiActionID(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      ActionType.TradeEthForDai,
      abi.encode(ethToSupply, minimumDaiReceived, target, data),
      _nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
  }

  /**
   * @notice View function that will return the action ID or message hash that
   * will need to be prefixed (according to EIP-191 0x45), hashed, and signed by
   * both the user signing key and by the key returned for this smart wallet by
   * the Dharma Key Registry in order to construct a valid signature for an
   * Eth-to-Dai swap. Any nonce value may be supplied, which enables
   * constructing valid message hashes for multiple future actions ahead of
   * time.
   * @param ethToSupply uint256 The Ether to supply as part of the swap.
   * @param minimumDaiReceived uint256 The minimum amount of Dai that must be
   * received in exchange for the supplied Ether.
   * @param target address The contract that the trade helper should call in
   * order to facilitate the swap.
   * @param data bytes The payload that will be passed to the target, along with
   * the supplied Ether, by the trade helper in order to facilitate the swap.
   * @param nonce uint256 The nonce to use.
   * @param minimumActionGas uint256 The minimum amount of gas that must be
   * provided to this call - be aware that additional gas must still be included
   * to account for the cost of overhead incurred up until the start of this
   * function call.
   * @return The action ID, which will need to be prefixed, hashed and signed in
   * order to construct a valid signature.
   */ 
  function getEthForDaiActionID(
    uint256 ethToSupply,
    uint256 minimumDaiReceived,
    address target,
    bytes calldata data,
    uint256 nonce,
    uint256 minimumActionGas
  ) external view returns (bytes32 actionID) {
    // Determine the actionID - this serves as a signature hash for an action.
    actionID = _getActionID(
      ActionType.TradeEthForDai,
      abi.encode(ethToSupply, minimumDaiReceived, target, data),
      nonce,
      minimumActionGas,
      _userSigningKey,
      _getDharmaSigningKey()
    );
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
   * no code may not be specified, nor may the smart wallet itself or the escape
   * hatch registry. In order to increment the nonce and invalidate the
   * signatures, a call to this function with valid targets, signatutes, and gas
   * will always succeed. To determine whether each call made as part of the
   * action was successful or not, either the corresponding return value or the
   * corresponding `CallSuccess` or `CallFailure` event can be used - note that
   * even calls that return a success status will have been rolled back unless
   * all of the calls returned a success status. Finally, note that this
   * function must currently be implemented as a public function (instead of as
   * an external one) due to an ABIEncoderV2 `UnimplementedFeatureError`.
   * @param calls Call[] A struct containing the target and calldata to provide
   * when making each call.
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
      _ensureValidGenericCallTarget(calls[i].to);
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
   * @param calls Call[] A struct containing the target and calldata to provide
   * when making each call.
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
      (bool ok, bytes memory returnData) = calls[i].to.call(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide data instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
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
   * @notice Internal function for setting the allowance of a given ERC20 asset
   * to the maximum value. This enables the corresponding dToken for the asset
   * to pull in tokens in order to make deposits.
   * @param asset uint256 The ID of the asset, either Dai (0) or USDC (1).
   * @return True if the approval succeeded, otherwise false.
   */
  function _setFullApproval(AssetType asset) internal returns (bool ok) {
    // Get asset's underlying token address and corresponding dToken address.
    address token;
    address dToken;
    if (asset == AssetType.DAI) {
      token = address(_DAI);
      dToken = address(_DDAI_EXCHANGER);
    } else {
      token = address(_USDC);
      dToken = address(_DUSDC);
    }

    // Approve dToken contract to transfer underlying on behalf of this wallet.
    (ok, ) = address(token).call(abi.encodeWithSelector(
      // Note: since both Tokens have the same interface, just use DAI's.
      _DAI.approve.selector, dToken, uint256(-1)
    ));

    // Emit a corresponding event if the approval failed.
    if (!ok) {
      if (asset == AssetType.DAI) {
        emit ExternalError(address(_DAI), _revertReason(17));
      } else {
        // Find out why USDC transfer reverted (it doesn't give revert reasons).
        _diagnoseAndEmitUSDCSpecificError(_USDC.approve.selector);
      }
    }
  }

  /**
   * @notice Internal function for depositing a given ERC20 asset and balance on
   * the corresponding dToken. No value is returned, as no additional steps need
   * to be conditionally performed after the deposit.
   * @param asset uint256 The ID of the asset, either Dai (0) or USDC (1).
   * @param balance uint256 The amount of the asset to deposit. Note that an
   * attempt to deposit "dust" (i.e. very small amounts) may result in fewer
   * dTokens being minted than is implied by the current exchange rate due to a
   * lack of sufficient precision on the tokens in question. USDC deposits are
   * also dependent on a flag being set on the Configuration Registry contract.
   */
  function _depositDharmaToken(AssetType asset, uint256 balance) internal {
    // Only perform a deposit if the balance is at least .001 Dai or USDC.
    if (
      asset == AssetType.DAI && balance > _JUST_UNDER_ONE_1000th_DAI ||
      asset == AssetType.USDC && (
        balance > _JUST_UNDER_ONE_1000th_USDC &&
        uint256(_CONFIG_REGISTRY.get(_ENABLE_USDC_MINTING_KEY)) != 0
      )
    ) {
      bool ok;
      bytes memory data;
      if (asset == AssetType.DAI) {
        // Attempt to mint the Dai balance on the dDai Exchanger contract.
        (ok, data) = address(_DDAI_EXCHANGER).call(abi.encodeWithSelector(
          _DDAI_EXCHANGER.mintTo.selector, address(this), balance
        ));
      } else {
        // Attempt to mint the USDC balance on the dUDSC contract.
        (ok, data) = address(_DUSDC).call(abi.encodeWithSelector(
          _DUSDC.mint.selector, balance
        ));
      }

      // Log an external error if something went wrong with the attempt.
      _checkDharmaTokenInteractionAndLogAnyErrors(
        asset, _DDAI.mint.selector, ok, data
      );
    }
  }

  /**
   * @notice Internal function for withdrawing a given underlying asset balance
   * from the corresponding dToken. Note that the requested balance may not be
   * currently available on Compound, which will cause the withdrawal to fail.
   * @param asset uint256 The asset's ID, either Dai (0) or USDC (1).
   * @param balance uint256 The amount of the asset to withdraw, denominated in
   * the underlying token. Note that an attempt to withdraw "dust" (i.e. very
   * small amounts) may result in 0 underlying tokens being redeemed, or in
   * fewer tokens being redeemed than is implied by the current exchange rate
   * (due to lack of sufficient precision on the tokens).
   * @return True if the withdrawal succeeded, otherwise false.
   */
  function _withdrawFromDharmaToken(
    AssetType asset, uint256 balance
  ) internal returns (bool success) {
    // Get dToken address for the asset type. (No custom ETH withdrawal action.)
    address dToken = asset == AssetType.DAI ? address(_DDAI) : address(_DUSDC);

    // Attempt to redeem the underlying balance from the dToken contract.
    (bool ok, bytes memory data) = dToken.call(abi.encodeWithSelector(
      // Note: function selector is the same for each dToken so just use dDai's.
      _DDAI.redeemUnderlying.selector, balance
    ));

    // Log an external error if something went wrong with the attempt.
    success = _checkDharmaTokenInteractionAndLogAnyErrors(
      asset, _DDAI.redeemUnderlying.selector, ok, data
    );
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

      if (ok && data.length == 32) {
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
   * actions in V8 include Cancel (0), SetUserSigningKey (1), Generic (2),
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
   * @notice Use all available cTokens to mint the respective dTokens. If any
   * step in the process fails, the call will revert and prior steps will be
   * rolled back. Also note that existing underlying tokens are not included as
   * part of this operation.
   */
  function _migrateCTokenToDToken(AssetType token) internal {
    CTokenInterface cToken;
    DTokenInterface dToken;

    if (token == AssetType.DAI) {
      cToken = _CDAI;
      dToken = _DDAI;
    } else {
      cToken = _CUSDC;
      dToken = _DUSDC;
    }

    // Get the current cToken balance for this account.
    uint256 balance = cToken.balanceOf(address(this));

    // Only perform the conversion if there is a non-zero balance.
    if (balance > 0) {    
      // If the allowance is insufficient, set it before depositing.
      if (cToken.allowance(address(this), address(dToken)) < balance) {
        if (!cToken.approve(address(dToken), uint256(-1))) {
          revert(_revertReason(23));
        }
      }
      
      // Deposit the new balance on the Dharma Token.
      if (dToken.mintViaCToken(balance) == 0) {
        revert(_revertReason(24));
      }
    }
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
   * @notice Internal function to diagnose the reason that a call to the USDC
   * contract failed and to emit a corresponding ExternalError event. USDC can
   * blacklist accounts and pause the contract, which can both cause a transfer
   * or approval to fail.
   * @param functionSelector bytes4 The function selector that was called on the
   * USDC contract.
   */
  function _diagnoseAndEmitUSDCSpecificError(bytes4 functionSelector) internal {
    // Determine the name of the function that was called on USDC.
    string memory functionName;
    if (functionSelector == _USDC.transfer.selector) {
      functionName = "transfer";
    } else {
      functionName = "approve";
    }
    
    USDCV1Interface usdcNaughty = USDCV1Interface(address(_USDC));

    // Find out why USDC transfer reverted (it doesn't give revert reasons).
    if (usdcNaughty.isBlacklisted(address(this))) {
      emit ExternalError(
        address(_USDC),
        string(
          abi.encodePacked(
            functionName, " failed - USDC has blacklisted this user."
          )
        )
      );
    } else { // Note: `else if` breaks coverage.
      if (usdcNaughty.paused()) {
        emit ExternalError(
          address(_USDC),
          string(
            abi.encodePacked(
              functionName, " failed - USDC contract is currently paused."
            )
          )
        );
      } else {
        emit ExternalError(
          address(_USDC),
          string(
            abi.encodePacked(
              "USDC contract reverted on ", functionName, "."
            )
          )
        );
      }
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
   * actions in V8 include Cancel (0), SetUserSigningKey (1), Generic (2),
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
   * actions in V8 include Cancel (0), SetUserSigningKey (1), Generic (2),
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
   * custom actions in V8 include Cancel (0), SetUserSigningKey (1),
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