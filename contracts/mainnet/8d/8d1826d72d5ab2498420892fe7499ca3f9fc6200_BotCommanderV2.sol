pragma solidity 0.6.12; // optimization runs: 200, evm version: istanbul
pragma experimental ABIEncoderV2;


interface BotCommanderV2Interface {
  event LimitOrderProcessed(
    address indexed account,
    address indexed suppliedAsset, // Ether = address(0)
    address indexed receivedAsset, // Ether = address(0)
    uint256 suppliedAmount,
    uint256 receivedAmount,
    bytes32 orderID
  );

  event LimitOrderCancelled(bytes32 orderID);
  event RoleModified(Role indexed role, address account);
  event RolePaused(Role indexed role);
  event RoleUnpaused(Role indexed role);

  enum Role {
    BOT_COMMANDER,
    CANCELLER,
    PAUSER
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  struct LimitOrderArguments {
    address account;
    address assetToSupply;        // Ether = address(0)
    address assetToReceive;       // Ether = address(0)
    uint256 maximumAmountToSupply;
    uint256 maximumPriceToAccept; // represented as a mantissa (n * 10^18)
    uint256 expiration;
    bytes32 salt;
  }

  struct LimitOrderExecutionArguments {
    uint256 amountToSupply; // will be lower than maximum for partial fills
    bytes signatures;
    address tradeTarget;
    bytes tradeData;
  }

  function processLimitOrder(
    LimitOrderArguments calldata args,
    LimitOrderExecutionArguments calldata executionArgs
  ) external returns (uint256 amountReceived);

  function cancelLimitOrder(LimitOrderArguments calldata args) external;

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool paused);

  function isRole(Role role) external view returns (bool hasRole);
  
  function getOrderID(
    LimitOrderArguments calldata args
  ) external view returns (bytes32 orderID, bool valid);

  function getBotCommander() external view returns (address botCommander);
  
  function getCanceller() external view returns (address canceller);

  function getPauser() external view returns (address pauser);
}


interface SupportingContractInterface {
  function setApproval(address token, uint256 amount) external;
}


interface ERC1271Interface {
  function isValidSignature(
    bytes calldata data, bytes calldata signatures
  ) external view returns (bytes4 magicValue);
}


interface ERC20Interface {
  function transfer(address, uint256) external returns (bool);
  function transferFrom(address, address, uint256) external returns (bool);
  function approve(address, uint256) external returns (bool);
  function balanceOf(address) external view returns (uint256);
  function allowance(address, address) external view returns (uint256);
}



library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");

    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }
}


/**
 * @notice Contract module which provides a basic access control mechanism,
 * where there is an account (an owner) that can be granted exclusive access
 * to specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */
contract TwoStepOwnable {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  address private _owner;

  address private _newPotentialOwner;

  /**
   * @notice Initialize contract with transaction submitter as initial owner.
   */
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @notice Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @notice Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() external onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @notice Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() external {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }

  /**
   * @notice Returns the address of the current owner.
   */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
   * @notice Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }
}


/**
 * @title BotCommanderV2
 * @author 0age
 * @notice BotCommander is a contract for performing meta-transaction-enabled
 * limit orders against external automated money markets or other sources of
 * on-chain liquidity. Eth-to-Token trades require that `triggerEtherTransfer`
 * is implemented on the account making the trade, and all trades require
 * that the account implements `isValidSignature` as specified by ERC-1271,
 * as well as a `setApproval` function, in order to enable meta-transactions.
 */
contract BotCommanderV2 is BotCommanderV2Interface, TwoStepOwnable {
  using SafeMath for uint256;

  // Maintain a role status mapping with assigned accounts and paused states.
  mapping(uint256 => RoleStatus) private _roles;

  // Maintain a mapping of invalid meta-transaction order IDs.
  mapping (bytes32 => bool) private _invalidMetaTxHashes;

  ERC20Interface private constant _ETHERIZER = ERC20Interface(
    0x723B51b72Ae89A3d0c2a2760f0458307a1Baa191
  );

  receive() external payable {}

  /**
   * @notice Only callable by the bot commander or the owner. Enforces the
   * expiration (or skips if it is set to zero) and trade size, validates
   * the execution signatures using ERC-1271 against the account, sets
   * approval to transfer the supplied token on behalf of that account,
   * pulls in the necessary supplied tokens, sets an allowance for the
   * provided trade target, calls the trade target with supplied data,
   * ensures that the call was successful, calculates the required amount
   * that must be received back based on the supplied amount and price,
   * ensures that at least that amount was returned, sends it to the
   * account, and emits an event. Use the null address to signify that
   * the supplied or retained asset is Ether.
   * @return amountReceived The amount received back from the trade.
   */
  function processLimitOrder(
    LimitOrderArguments calldata args,
    LimitOrderExecutionArguments calldata executionArgs
  ) external override onlyOwnerOr(Role.BOT_COMMANDER) returns (
    uint256 amountReceived
  ) {
    _enforceExpiration(args.expiration);
    
    require(
      executionArgs.amountToSupply <= args.maximumAmountToSupply,
      "Cannot supply more than the maximum authorized amount."
    );

    if (executionArgs.tradeData.length >= 4) {
      require(
        abi.decode(
          abi.encodePacked(executionArgs.tradeData[:4], bytes28(0)), (bytes4)
        ) != SupportingContractInterface.setApproval.selector,
        "Trade data has a prohibited function selector."
      );
    }

    // Construct order's "context" and use it to validate meta-transaction.
    bytes memory context = _constructLimitOrderContext(args);
    bytes32 orderID = _validateMetaTransaction(
      args.account, context, executionArgs.signatures
    );

    // Determine the asset being supplied (use Etherizer for Ether).
    ERC20Interface assetToSupply = (
      args.assetToSupply == address(0)
        ? _ETHERIZER
        : ERC20Interface(args.assetToSupply)
    );

    // Ensure that target has allowance to transfer tokens.
    _grantApprovalIfNecessary(
      assetToSupply, executionArgs.tradeTarget, executionArgs.amountToSupply
    );

    // Call `setApproval` on the supplying account.
    SupportingContractInterface(args.account).setApproval(
      address(assetToSupply), executionArgs.amountToSupply
    );

    // Make the transfer in.
    _transferInToken(
      assetToSupply, args.account, executionArgs.amountToSupply
    );

    // Call into target, supplying data, and revert on failure.
    _performCallToTradeTarget(
      executionArgs.tradeTarget, executionArgs.tradeData
    );

    // Determine amount expected back using supplied amount and price.
    uint256 amountExpected = (
      executionArgs.amountToSupply.mul(1e18)
    ).div(
      args.maximumPriceToAccept
    );
 
    if (args.assetToReceive == address(0)) {
      // Determine ether balance held by this contract.
      amountReceived = address(this).balance;  
      
      // Ensure that enough Ether was received.
      require(
        amountReceived >= amountExpected,
        "Trade did not result in the expected amount of Ether."
      );
      
      // Transfer the Ether out and revert on failure.
      _transferEther(args.account, amountReceived);
    } else {
      ERC20Interface assetToReceive = ERC20Interface(args.assetToReceive);

      // Determine balance of received tokens held by this contract.
      amountReceived = assetToReceive.balanceOf(address(this));
      
      // Ensure that enough tokens were received.
      require(
        amountReceived >= amountExpected,
        "Trade did not result in the expected amount of tokens."
      );

      // Transfer the tokens and revert on failure.
      _transferOutToken(assetToReceive, args.account, amountReceived);
    }

    emit LimitOrderProcessed(
      args.account,
      args.assetToSupply,
      args.assetToReceive,
      executionArgs.amountToSupply,
      amountReceived,
      orderID
    );
  }

  /**
   * @notice Cancels a potential limit order. Only the owner, the account
   * in question, or the canceller role may call this function.
   */
  function cancelLimitOrder(
    LimitOrderArguments calldata args
  ) external override onlyOwnerOrAccountOr(Role.CANCELLER, args.account) {
    _enforceExpiration(args.expiration);

    // Construct the order ID using relevant "context" of the limit order.
    bytes32 orderID = keccak256(_constructLimitOrderContext(args));

    // Ensure the order ID has not been used or cancelled and invalidate it.
    require(
      !_invalidMetaTxHashes[orderID], "Meta-transaction already invalid."
    );
    _invalidMetaTxHashes[orderID] = true;
    
    emit LimitOrderCancelled(orderID);
  }

  /**
   * @notice Pause a currently unpaused role and emit a `RolePaused` event. Only
   * the owner or the designated pauser may call this function. Also, bear in
   * mind that only the owner may unpause a role once paused.
   * @param role The role to pause.
   */
  function pause(Role role) external override onlyOwnerOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }

  /**
   * @notice Unpause a currently paused role and emit a `RoleUnpaused` event.
   * Only the owner may call this function.
   * @param role The role to pause.
   */
  function unpause(Role role) external override onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }

  /**
   * @notice Set a new account on a given role and emit a `RoleModified` event
   * if the role holder has changed. Only the owner may call this function.
   * @param role The role that the account will be set for.
   * @param account The account to set as the designated role bearer.
   */
  function setRole(Role role, address account) external override onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }

  /**
   * @notice Remove any current role bearer for a given role and emit a
   * `RoleModified` event if a role holder was previously set. Only the owner
   * may call this function.
   * @param role The role that the account will be removed from.
   */
  function removeRole(Role role) external override onlyOwner {
    _setRole(role, address(0));
  }

  /**
   * @notice View function to determine an order's meta-transaction message hash
   * and to determine if it is still valid (i.e. it has not yet been used and is
   * not expired). The returned order ID will need to be prefixed using EIP-191
   * 0x45 and hashed again in order to generate a final digest for the required
   * signature - in other words, the same procedure utilized by `eth_Sign`.
   * @return orderID The ID corresponding to the limit order's meta-transaction.
   */
  function getOrderID(
    LimitOrderArguments calldata args
  ) external view override returns (bytes32 orderID, bool valid) {
    // Construct the order ID based on relevant context.
    orderID = keccak256(_constructLimitOrderContext(args));

    // The meta-transaction is valid if it has not been used and is not expired.
    valid = (
      !_invalidMetaTxHashes[orderID] && (
        args.expiration == 0 || block.timestamp <= args.expiration
      )
    );
  }

  /**
   * @notice External view function to check whether or not the functionality
   * associated with a given role is currently paused or not. The owner or the
   * pauser may pause any given role (including the pauser itself), but only the
   * owner may unpause functionality. Additionally, the owner may call paused
   * functions directly.
   * @param role The role to check the pause status on.
   * @return paused A boolean to indicate if the functionality associated with
   * the role in question is currently paused.
   */
  function isPaused(Role role) external view override returns (bool paused) {
    paused = _isPaused(role);
  }

  /**
   * @notice External view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return hasRole A boolean indicating if the caller has the specified role.
   */
  function isRole(Role role) external view override returns (bool hasRole) {
    hasRole = _isRole(role);
  }

  /**
   * @notice External view function to check the account currently holding the
   * bot commander role. The bot commander can execute limit orders.
   * @return botCommander The address of the current bot commander, or the null
   * address if none is set.
   */
  function getBotCommander() external view override returns (
    address botCommander
  ) {
    botCommander = _roles[uint256(Role.BOT_COMMANDER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * canceller role. The canceller can cancel limit orders.
   * @return canceller The address of the current canceller, or the null
   * address if none is set.
   */
  function getCanceller() external view override returns (
    address canceller
  ) {
    canceller = _roles[uint256(Role.CANCELLER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * pauser role. The pauser can pause any role from taking its standard action,
   * though the owner will still be able to call the associated function in the
   * interim and is the only entity able to unpause the given role once paused.
   * @return pauser The address of the current pauser, or the null address if
   * none is set.
   */
  function getPauser() external view override returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }

  /**
   * @notice Private function to enforce that a given meta-transaction
   * has not been used before and that the signature is valid according
   * to the account in question (using ERC-1271).
   * @param account address The account originating the meta-transaction.
   * @param context bytes Information about the meta-transaction.
   * @param signatures bytes Signature or signatures used to validate
   * the meta-transaction.
   */
  function _validateMetaTransaction(
    address account, bytes memory context, bytes memory signatures
  ) private returns (bytes32 orderID) {
    // Construct the order ID using the provided context.
    orderID = keccak256(context);

    // Ensure ID has not been used or cancelled and invalidate it.
    require(
      !_invalidMetaTxHashes[orderID], "Order is no longer valid."
    );
    _invalidMetaTxHashes[orderID] = true;

    // Construct the digest to compare signatures against using EIP-191 0x45.
    bytes32 digest = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", orderID)
    );

    // Validate via ERC-1271 against the specified account.
    bytes memory data = abi.encode(digest, context);
    bytes4 magic = ERC1271Interface(account).isValidSignature(data, signatures);
    require(magic == bytes4(0x20c13b0b), "Invalid signatures.");
  }

  /**
   * @notice Private function to set a new account on a given role and emit a
   * `RoleModified` event if the role holder has changed.
   * @param role The role that the account will be set for.
   * @param account The account to set as the designated role bearer.
   */
  function _setRole(Role role, address account) private {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }

  /**
   * @notice Private function to perform a call to a given trade target, supplying
   * given data, and revert with reason on failure.
   */
  function _performCallToTradeTarget(address target, bytes memory data) private {
    // Call into the provided target, supplying provided data.
    (bool tradeTargetCallSuccess,) = target.call(data);

    // Revert with reason if the call was not successful.
    if (!tradeTargetCallSuccess) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    } else {
      // Ensure that the target is a contract.
      uint256 returnSize;
      assembly { returnSize := returndatasize() }
      if (returnSize == 0) {
        uint256 size;
        assembly { size := extcodesize(target) }
        require(size > 0, "Specified target does not have contract code.");
      }
    }
  }

  /**
   * @notice Private function to set approval for a given target to transfer tokens
   * on behalf of this contract. It should generally be assumed that this contract
   * is highly permissive when it comes to approvals.
   */
  function _grantApprovalIfNecessary(
    ERC20Interface token, address target, uint256 amount
  ) private {
    if (token.allowance(address(this), target) < amount) {
      // Try removing approval first as a workaround for unusual tokens.
      (bool success, bytes memory returnData) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, target, uint256(0)
        )
      );

      // Grant approval to transfer tokens on behalf of this contract.
      (success, returnData) = address(token).call(
        abi.encodeWithSelector(
          token.approve.selector, target, type(uint256).max
        )
      );

      if (!success) {
        // Some really janky tokens only allow setting approval up to current balance.
        (success, returnData) = address(token).call(
          abi.encodeWithSelector(
            token.approve.selector, target, amount
          )
        );
      }

      require(
        success && (returnData.length == 0 || abi.decode(returnData, (bool))),
        "Token approval to trade against the target failed."
      );
    }
  }

  /**
   * @notice Private function to transfer tokens out of this contract.
   */
  function _transferOutToken(ERC20Interface token, address to, uint256 amount) private {
    (bool success, bytes memory returnData) = address(token).call(
      abi.encodeWithSelector(token.transfer.selector, to, amount)
    );

    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
    
    if (returnData.length == 0) {
      uint256 size;
      assembly { size := extcodesize(token) }
      require(size > 0, "Token specified to transfer out does not have contract code.");
    } else {
      require(abi.decode(returnData, (bool)), 'Token transfer out failed.');
    }
  }

  /**
   * @notice Private function to transfer Ether out of this contract.
   */
  function _transferEther(address recipient, uint256 etherAmount) private {
    // Send Ether to recipient and revert with reason on failure.
    (bool ok, ) = recipient.call{value: etherAmount}("");
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
  }

  /**
   * @notice Private function to transfer tokens into this contract.
   */
  function _transferInToken(ERC20Interface token, address from, uint256 amount) private {
    (bool success, bytes memory returnData) = address(token).call(
      abi.encodeWithSelector(token.transferFrom.selector, from, address(this), amount)
    );

    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }
    
    if (returnData.length == 0) {
      uint256 size;
      assembly { size := extcodesize(token) }
      require(size > 0, "Token specified to transfer in does not have contract code.");
    } else {
      require(abi.decode(returnData, (bool)), 'Token transfer in failed.');
    }
  }

  /**
   * @notice Private view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return hasRole A boolean indicating if the caller has the specified role.
   */
  function _isRole(Role role) private view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }

  /**
   * @notice Private view function to check whether the given role is paused or
   * not.
   * @param role The role to check for.
   * @return paused A boolean indicating if the specified role is paused or not.
   */
  function _isPaused(Role role) private view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }

  /**
   * @notice Private view function to construct the "context" or details that
   * need to be included when generating the order ID.
   * @return context bytes The context.
   */
  function _constructLimitOrderContext(
    LimitOrderArguments memory args
  ) private view returns (bytes memory context) {
    context = abi.encode(
      address(this),
      args.account,
      args.assetToSupply,
      args.assetToReceive,
      args.maximumAmountToSupply,
      args.maximumPriceToAccept,
      args.expiration,
      args.salt
    );
  }

  /**
   * @notice Private view function to ensure that a given expiration has
   * not elapsed, or is set to zero (signifying no expiration).
   */
  function _enforceExpiration(uint256 expiration) private view {
    require(
      expiration == 0 || block.timestamp <= expiration,
      "Order has expired."
    );
  }

  /**
   * @notice Modifier that throws if called by any account other than the owner
   * or the supplied role, or if the caller is not the owner and the role in
   * question is paused.
   * @param role The role to require unless the caller is the owner. Permitted
   * roles are bot commander (0), and canceller (1), and pauser (2).
   */
  modifier onlyOwnerOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }

  /**
   * @notice Modifier that throws if called by any account other than the owner,
   * a specified account, or the supplied role, or if the caller is not the
   * owner or the specified account and the role in question is paused.
   * @param role The role to require unless the caller is the owner or the
   * specified account. Permitted roles are bot commander (0), and canceller (1),
   * and pauser (2).
   */
  modifier onlyOwnerOrAccountOr(Role role, address account) {
    if (!isOwner() && !(msg.sender == account)) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }
}