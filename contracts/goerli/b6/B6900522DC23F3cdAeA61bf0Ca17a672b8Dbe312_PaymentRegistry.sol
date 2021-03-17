// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../common/access/Guarded.sol";
import "../common/libs/ECDSALib.sol";
import "../common/libs/SafeMathLib.sol";
import "../common/lifecycle/Initializable.sol";
import "../common/signature/SignatureValidator.sol";
import "../common/token/ERC20Token.sol";
import "../external/ExternalAccountRegistry.sol";
import "../personal/PersonalAccountRegistry.sol";
import "../gateway/GatewayRecipient.sol";
import "./PaymentDepositAccount.sol";


/**
 * @title Payment registry
 *
 * @notice A registry for payment and payment channels
 *
 * @dev the `DepositExit` process can be used in a case operator (guardian) couldn't sign commit / withdrawal message.
 * Process will be rejected when any of senders channels will be committed.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract PaymentRegistry is Guarded, Initializable, SignatureValidator, GatewayRecipient {
  using ECDSALib for bytes32;
  using SafeMathLib for uint256;

  struct Deposit {
    address account;
    mapping(address => uint256) withdrawnAmount;
    mapping(address => uint256) exitLockedUntil;
  }

  struct PaymentChannel {
    uint256 committedAmount;
  }

  struct DepositWithdrawal {
    address owner;
    address token;
    uint256 amount;
  }

  struct PaymentChannelCommit {
    address sender;
    address recipient;
    address token;
    bytes32 uid;
    uint256 blockNumber;
    uint256 amount;
  }

  uint256 private constant DEFAULT_DEPOSIT_EXIT_LOCK_PERIOD = 28 days;

  bytes32 private constant HASH_PREFIX_DEPOSIT_WITHDRAWAL = keccak256(
    "DepositWithdrawal(address owner,address token,uint256 amount)"
  );
  bytes32 private constant HASH_PREFIX_PAYMENT_CHANNEL_COMMIT = keccak256(
    "PaymentChannelCommit(address sender,address recipient,address token,bytes32 uid,uint256 blockNumber,uint256 amount)"
  );

  ExternalAccountRegistry public externalAccountRegistry;
  PersonalAccountRegistry public personalAccountRegistry;

  uint256 public depositExitLockPeriod;

  mapping(address => Deposit) private deposits;
  mapping(bytes32 => PaymentChannel) private paymentChannels;

  // events

  /**
   * @dev Emitted when the deposit account is deployed
   * @param depositAccount deposit account address
   * @param owner owner address
   */
  event DepositAccountDeployed(
    address depositAccount,
    address owner
  );

  /**
   * @dev Emitted when the deposit exist is requested
   * @param depositAccount deposit account address
   * @param owner owner address
   * @param token token address
   * @param lockedUntil deposit exist locked util time
   */
  event DepositExitRequested(
    address depositAccount,
    address owner,
    address token,
    uint256 lockedUntil
  );

  /**
   * @dev Emitted when the deposit exist is completed
   * @param depositAccount deposit account address
   * @param owner owner address
   * @param token token address
   * @param amount deposit exist amount
   */
  event DepositExitCompleted(
    address depositAccount,
    address owner,
    address token,
    uint256 amount
  );

  /**
   * @dev Emitted when the deposit exist is rejected
   * @param depositAccount deposit account address
   * @param owner owner address
   * @param token token address
   */
  event DepositExitRejected(
    address depositAccount,
    address owner,
    address token
  );

  /**
   * @dev Emitted when the deposit has been withdrawn
   * @param depositAccount deposit account address
   * @param owner owner address
   * @param token token address
   * @param amount withdrawn amount
   */
  event DepositWithdrawn(
    address depositAccount,
    address owner,
    address token,
    uint256 amount
  );

  /**
   * @dev Emitted when the payment channel has been committed
   * @param hash channel hash
   * @param sender sender address
   * @param recipient recipient address
   * @param token token address
   * @param uid unique channel id
   * @param amount committed amount
   */
  event PaymentChannelCommitted(
    bytes32 hash,
    address sender,
    address recipient,
    address token,
    bytes32 uid,
    uint256 amount
  );

  /**
   * @dev Emitted when the payment has been withdrawn
   * @param channelHash channel hash
   * @param value payment value
   */
  event PaymentWithdrawn(
    bytes32 channelHash,
    uint256 value
  );

  /**
   * @dev Emitted when the payment has been deposited
   * @param channelHash channel hash
   * @param value payment value
   */
  event PaymentDeposited(
    bytes32 channelHash,
    uint256 value
  );

  /**
   * @dev Emitted when the payment has been withdrawn and deposited (split)
   * @param channelHash channel hash
   * @param totalValue payment total value
   * @param depositValue payment deposited value
   */
  event PaymentSplit(
    bytes32 channelHash,
    uint256 totalValue,
    uint256 depositValue
  );

  /**
   * @dev Public constructor
   */
  constructor() public Initializable() SignatureValidator() {}

  // external functions

  /**
   * @notice Initialize `PaymentRegistry` contract
   * @param externalAccountRegistry_ `ExternalAccountRegistry` contract address
   * @param personalAccountRegistry_ `PersonalAccountRegistry` contract address
   * @param depositExitLockPeriod_ deposit exit lock period
   * @param guardians_ array of guardians addresses
   * @param gateway_ `Gateway` contract address
   */
  function initialize(
    ExternalAccountRegistry externalAccountRegistry_,
    PersonalAccountRegistry personalAccountRegistry_,
    uint256 depositExitLockPeriod_,
    address[] calldata guardians_,
    address gateway_
  )
    external
    onlyInitializer
  {
    externalAccountRegistry = externalAccountRegistry_;
    personalAccountRegistry = personalAccountRegistry_;

    if (depositExitLockPeriod_ == 0) {
      depositExitLockPeriod = DEFAULT_DEPOSIT_EXIT_LOCK_PERIOD;
    } else {
      depositExitLockPeriod = depositExitLockPeriod_;
    }

    // Guarded
    _initializeGuarded(guardians_);

    // GatewayRecipient
    _initializeGatewayRecipient(gateway_);
  }

  /**
   * @notice Deploys deposit account
   * @param owner owner address
   */
  function deployDepositAccount(
    address owner
  )
    external
  {
    _deployDepositAccount(owner);
  }

  /**
   * @notice Requests deposit exit
   * @param token token address
   */
  function requestDepositExit(
    address token
  )
    external
  {
    address owner = _getContextAccount();
    uint256 lockedUntil = deposits[owner].exitLockedUntil[token];

    require(
      lockedUntil == 0,
      "PaymentRegistry: deposit exit already requested"
    );

    _deployDepositAccount(owner);

    // solhint-disable-next-line not-rely-on-time
    lockedUntil = now.add(depositExitLockPeriod);

    deposits[owner].exitLockedUntil[token] = lockedUntil;

    emit DepositExitRequested(
      deposits[owner].account,
      owner,
      token,
      lockedUntil
    );
  }

  /**
   * @notice Processes deposit exit
   * @param token token address
   */
  function processDepositExit(
    address token
  )
    external
  {
    address owner = _getContextAccount();
    uint256 lockedUntil = deposits[owner].exitLockedUntil[token];

    require(
      lockedUntil != 0,
      "PaymentRegistry: deposit exit not requested"
    );

    require(
      // solhint-disable-next-line not-rely-on-time
      lockedUntil <= now,
      "PaymentRegistry: deposit exit locked"
    );

    deposits[owner].exitLockedUntil[token] = 0;

    address depositAccount = deposits[owner].account;
    uint256 depositValue;

    if (token == address(0)) {
      depositValue = depositAccount.balance;
    } else {
      depositValue = ERC20Token(token).balanceOf(depositAccount);
    }

    _transferFromDeposit(
      depositAccount,
      owner,
      token,
      depositValue
    );

    emit DepositExitCompleted(
      depositAccount,
      owner,
      token,
      depositValue
    );
  }

  /**
   * @notice Withdraws deposit
   * @param token token address
   * @param amount amount to withdraw
   * @param guardianSignature guardian signature
   */
  function withdrawDeposit(
    address token,
    uint256 amount,
    bytes calldata guardianSignature
  )
    external
  {
    address owner = _getContextAccount();
    uint256 value = amount.sub(deposits[owner].withdrawnAmount[token]);

    require(
      value > 0,
      "PaymentRegistry: invalid amount"
    );

    bytes32 messageHash = _hashDepositWithdrawal(
      owner,
      token,
      amount
    );

    require(
      _verifyGuardianSignature(messageHash, guardianSignature),
      "PaymentRegistry: invalid guardian signature"
    );

    deposits[owner].withdrawnAmount[token] = amount;

    _verifyDepositExitOrDeployAccount(owner, token);

    _transferFromDeposit(
      deposits[owner].account,
      owner,
      token,
      value
    );

    emit DepositWithdrawn(
      deposits[owner].account,
      owner,
      token,
      amount
    );
  }

  /**
   * @notice Commits payment channel and withdraw payment
   * @param sender sender address
   * @param token token address
   * @param uid unique channel id
   * @param blockNumber block number
   * @param amount amount to commit
   * @param senderSignature sender signature
   * @param guardianSignature guardian signature
   */
  function commitPaymentChannelAndWithdraw(
    address sender,
    address token,
    bytes32 uid,
    uint256 blockNumber,
    uint256 amount,
    bytes calldata senderSignature,
    bytes calldata guardianSignature
  )
    external
  {
    address recipient = _getContextAccount();

    (bytes32 hash, address depositAccount, uint256 paymentValue) = _commitPaymentChannel(
      sender,
      recipient,
      token,
      uid,
      blockNumber,
      amount,
      senderSignature,
      guardianSignature
    );

    _transferFromDeposit(
      depositAccount,
      recipient,
      token,
      paymentValue
    );

    emit PaymentWithdrawn(hash, paymentValue);
  }

  /**
   * @notice Commits payment channel and deposit payment
   * @param sender sender address
   * @param token token address
   * @param uid unique channel id
   * @param blockNumber block number
   * @param amount amount to commit
   * @param senderSignature sender signature
   * @param guardianSignature guardian signature
   */
  function commitPaymentChannelAndDeposit(
    address sender,
    address token,
    bytes32 uid,
    uint256 blockNumber,
    uint256 amount,
    bytes calldata senderSignature,
    bytes calldata guardianSignature
  )
    external
  {
    address recipient = _getContextAccount();

    (bytes32 hash, address depositAccount, uint256 paymentValue) = _commitPaymentChannel(
      sender,
      recipient,
      token,
      uid,
      blockNumber,
      amount,
      senderSignature,
      guardianSignature
    );

    _transferFromDeposit(
      depositAccount,
      _computeDepositAccountAddress(recipient),
      token,
      paymentValue
    );

    emit PaymentDeposited(hash, paymentValue);
  }

  /**
   * @notice Commits payment channel, withdraws and deposits (split) payment
   * @param sender sender address
   * @param token token address
   * @param uid unique channel id
   * @param blockNumber block number
   * @param amount amount to commit
   * @param depositPaymentValue amount to deposit
   * @param senderSignature sender signature
   * @param guardianSignature guardian signature
   */
  function commitPaymentChannelAndSplit(
    address sender,
    address token,
    bytes32 uid,
    uint256 blockNumber,
    uint256 amount,
    uint256 depositPaymentValue,
    bytes calldata senderSignature,
    bytes calldata guardianSignature
  )
    external
  {
    address recipient = _getContextAccount();

    (bytes32 hash, address depositAccount, uint256 paymentValue) = _commitPaymentChannel(
      sender,
      recipient,
      token,
      uid,
      blockNumber,
      amount,
      senderSignature,
      guardianSignature
    );

    _transferSplitFromDeposit(
      depositAccount,
      recipient,
      token,
      paymentValue,
      depositPaymentValue
    );

    emit PaymentSplit(hash, paymentValue, depositPaymentValue);
  }

  // external functions (views)

  /**
   * @notice Computes deposit account address
   * @param owner owner address
   * @return deposit account address
   */
  function computeDepositAccountAddress(
    address owner
  )
    external
    view
    returns (address)
  {
    return _computeDepositAccountAddress(owner);
  }

  /**
   * @notice Checks if deposit account is deployed
   * @param owner owner address
   * @return true when deposit account is deployed
   */
  function isDepositAccountDeployed(
    address owner
  )
    external
    view
    returns (bool)
  {
    return deposits[owner].account != address(0);
  }

  /**
   * @notice Gets deposit exit locked until time
   * @param owner owner address
   * @param token token address
   * @return locked until time
   */
  function getDepositExitLockedUntil(
    address owner,
    address token
  )
    external
    view
    returns (uint256)
  {
    return deposits[owner].exitLockedUntil[token];
  }

  /**
   * @notice Gets deposit withdrawn amount
   * @param owner owner address
   * @param token token address
   * @return withdrawn amount
   */
  function getDepositWithdrawnAmount(
    address owner,
    address token
  )
    external
    view
    returns (uint256)
  {
    return deposits[owner].withdrawnAmount[token];
  }

  /**
   * @notice Gets payment channel committed amount
   * @param hash payment channel hash
   * @return committed amount
   */
  function getPaymentChannelCommittedAmount(
    bytes32 hash
  )
    external
    view
    returns (uint256)
  {
    return paymentChannels[hash].committedAmount;
  }

  // external functions (pure)

  /**
   * @notice Computes payment channel hash
   * @param sender sender address
   * @param recipient recipient address
   * @param token token address
   * @param uid unique channel id
   * @return hash
   */
  function computePaymentChannelHash(
    address sender,
    address recipient,
    address token,
    bytes32 uid
  )
    external
    pure
    returns (bytes32)
  {
    return _computePaymentChannelHash(
      sender,
      recipient,
      token,
      uid
    );
  }

  // public functions (views)

  /**
   * @notice Hashes `DepositWithdrawal` message payload
   * @param depositWithdrawal struct
   * @return hash
   */
  function hashDepositWithdrawal(
    DepositWithdrawal memory depositWithdrawal
  )
    public
    view
    returns (bytes32)
  {
    return _hashDepositWithdrawal(
      depositWithdrawal.owner,
      depositWithdrawal.token,
      depositWithdrawal.amount
    );
  }

  /**
   * @notice Hashes `PaymentChannelCommit` message payload
   * @param paymentChannelCommit struct
   * @return hash
   */
  function hashPaymentChannelCommit(
    PaymentChannelCommit memory paymentChannelCommit
  )
    public
    view
    returns (bytes32)
  {
    return _hashPaymentChannelCommit(
      paymentChannelCommit.sender,
      paymentChannelCommit.recipient,
      paymentChannelCommit.token,
      paymentChannelCommit.uid,
      paymentChannelCommit.blockNumber,
      paymentChannelCommit.amount
    );
  }

  // private functions

  function _deployDepositAccount(
    address owner
  )
    private
  {
    if (deposits[owner].account == address(0)) {
      bytes32 salt = keccak256(
        abi.encodePacked(
          owner
        )
      );

      deposits[owner].account = address(new PaymentDepositAccount{salt: salt}());

      emit DepositAccountDeployed(
        deposits[owner].account,
        owner
      );
    }
  }

  function _verifyDepositExitOrDeployAccount(
    address owner,
    address token
  )
    private
  {
    if (deposits[owner].exitLockedUntil[token] > 0) {
      deposits[owner].exitLockedUntil[token] = 0;

      emit DepositExitRejected(
        deposits[owner].account,
        owner,
        token
      );
    } else {
      _deployDepositAccount(owner);
    }
  }

  function _commitPaymentChannel(
    address sender,
    address recipient,
    address token,
    bytes32 uid,
    uint256 blockNumber,
    uint256 amount,
    bytes memory senderSignature,
    bytes memory guardianSignature
  )
    private
    returns (bytes32 hash, address depositAccount, uint256 paymentValue)
  {
    bytes32 messageHash = _hashPaymentChannelCommit(
      sender,
      recipient,
      token,
      uid,
      blockNumber,
      amount
    );

    if (senderSignature.length == 0) {
      require(
        externalAccountRegistry.verifyAccountProofAtBlock(sender, messageHash, blockNumber),
        "PaymentRegistry: invalid guardian signature"
      );
    } else {
      address signer = messageHash.recoverAddress(senderSignature);

      if (sender != signer) {
        require(
          personalAccountRegistry.verifyAccountOwnerAtBlock(sender, signer, blockNumber) ||
          externalAccountRegistry.verifyAccountOwnerAtBlock(sender, signer, blockNumber),
          "PaymentRegistry: invalid sender signature"
        );
      }
    }

    require(
      _verifyGuardianSignature(messageHash, guardianSignature),
      "PaymentRegistry: invalid guardian signature"
    );

    hash = _computePaymentChannelHash(
      sender,
      recipient,
      token,
      uid
    );

    /// @dev calc payment value
    paymentValue = amount.sub(paymentChannels[hash].committedAmount);

    require(
      paymentValue != 0,
      "PaymentRegistry: invalid payment value"
    );

    paymentChannels[hash].committedAmount = amount;

    _verifyDepositExitOrDeployAccount(sender, token);

    depositAccount = deposits[sender].account;

    emit PaymentChannelCommitted(
      hash,
      sender,
      recipient,
      token,
      uid,
      amount
    );

    return (hash, depositAccount, paymentValue);
  }

  function _transferFromDeposit(
    address depositAccount,
    address to,
    address token,
    uint256 value
  )
    private
  {
    if (token == address(0)) {
      PaymentDepositAccount(payable(depositAccount)).executeTransaction(
        to,
        value,
        new bytes(0)
      );
    } else {
      bytes memory response = PaymentDepositAccount(payable(depositAccount)).executeTransaction(
        token,
        0,
        abi.encodeWithSelector(
          ERC20Token(token).transfer.selector,
          to,
          value
        )
      );

      if (response.length > 0) {
        require(
          abi.decode(response, (bool)),
          "PaymentRegistry: ERC20Token transfer reverted"
        );
      }
    }
  }

  function _transferSplitFromDeposit(
    address depositAccount,
    address to,
    address token,
    uint256 paymentValue,
    uint256 depositValue
  )
    private
  {
    require(
      depositValue > 0,
      "PaymentRegistry: invalid deposit value"
    );

    uint256 withdrawValue = paymentValue.sub(depositValue);

    require(
      withdrawValue > 0,
      "PaymentRegistry: invalid withdraw value"
    );

    _transferFromDeposit(
      depositAccount,
      to,
      token,
      withdrawValue
    );

    _transferFromDeposit(
      depositAccount,
      _computeDepositAccountAddress(to),
      token,
      depositValue
    );
  }

  // private functions (views)

  function _computeDepositAccountAddress(
    address owner
  )
    private
    view
    returns (address)
  {
    bytes32 salt = keccak256(
      abi.encodePacked(
        owner
      )
    );

    bytes memory creationCode = type(PaymentDepositAccount).creationCode;

    bytes32 data = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        keccak256(creationCode)
      )
    );

    return address(uint160(uint256(data)));
  }

  function _hashDepositWithdrawal(
    address owner,
    address token,
    uint256 amount
  )
    private
    view
    returns (bytes32)
  {
    return _hashMessagePayload(HASH_PREFIX_DEPOSIT_WITHDRAWAL, abi.encodePacked(
      owner,
      token,
      amount
    ));
  }

  function _hashPaymentChannelCommit(
    address sender,
    address recipient,
    address token,
    bytes32 uid,
    uint256 blockNumber,
    uint256 amount
  )
    private
    view
    returns (bytes32)
  {
    return _hashMessagePayload(HASH_PREFIX_PAYMENT_CHANNEL_COMMIT, abi.encodePacked(
      sender,
      recipient,
      token,
      uid,
      blockNumber,
      amount
    ));
  }

  // private functions (pure)

  function _computePaymentChannelHash(
    address sender,
    address recipient,
    address token,
    bytes32 uid
  )
    private
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked(
        sender,
        recipient,
        token,
        uid
      )
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/ECDSALib.sol";


/**
 * @title Guarded
 *
 * @dev Contract module which provides a guardian-type control mechanism.
 * It allows key accounts to have guardians and restricts specific methods to be accessible by guardians only.
 *
 * Each guardian account can remove other guardians
 *
 * Use `_initializeGuarded` to initialize the contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Guarded {
  using ECDSALib for bytes32;

  mapping(address => bool) private guardians;

  // events

  /**
   * @dev Emitted when a new guardian is added
   * @param sender sender address
   * @param guardian guardian address
   */
  event GuardianAdded(
    address sender,
    address guardian
  );

  /**
   * @dev Emitted when the existing guardian is removed
   * @param sender sender address
   * @param guardian guardian address
   */
  event GuardianRemoved(
    address sender,
    address guardian
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not a guardian account
   */
  modifier onlyGuardian() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      guardians[tx.origin],
      "Guarded: tx.origin is not the guardian"
    );

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor() internal {}

  // external functions

  /**
   * @notice Adds a new guardian
   * @param guardian guardian address
   */
  function addGuardian(
    address guardian
  )
    external
    onlyGuardian
  {
    _addGuardian(guardian);
  }

  /**
   * @notice Removes the existing guardian
   * @param guardian guardian address
   */
  function removeGuardian(
    address guardian
  )
    external
    onlyGuardian
  {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin != guardian,
      "Guarded: cannot remove self"
    );

    require(
      guardians[guardian],
      "Guarded: guardian doesn't exist"
    );

    guardians[guardian] = false;

    emit GuardianRemoved(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      guardian
    );
  }

  // external functions (views)

  /**
   * @notice Check if guardian exists
   * @param guardian guardian address
   * @return true when guardian exists
   */
  function isGuardian(
    address guardian
  )
    external
    view
    returns (bool)
  {
    return guardians[guardian];
  }

  /**
   * @notice Verifies guardian signature
   * @param messageHash message hash
   * @param signature signature
   * @return true on correct guardian signature
   */
  function verifyGuardianSignature(
    bytes32 messageHash,
    bytes calldata signature
  )
    external
    view
    returns (bool)
  {
    return _verifyGuardianSignature(
      messageHash,
      signature
    );
  }

  // internal functions

  /**
   * @notice Initializes `Guarded` contract
   * @dev If `guardians_` array is empty `tx.origin` is added as guardian account
   * @param guardians_ array of guardians addresses
   */
  function _initializeGuarded(
    address[] memory guardians_
  )
    internal
  {
    if (guardians_.length == 0) {
      // solhint-disable-next-line avoid-tx-origin
      _addGuardian(tx.origin);
    } else {
      uint guardiansLen = guardians_.length;
      for (uint i = 0; i < guardiansLen; i++) {
        _addGuardian(guardians_[i]);
      }
    }
  }


  // internal functions (views)

  function _verifyGuardianSignature(
    bytes32 messageHash,
    bytes memory signature
  )
    internal
    view
    returns (bool)
  {
    address guardian = messageHash.recoverAddress(signature);

    return guardians[guardian];
  }

  // private functions

  function _addGuardian(
    address guardian
  )
    private
  {
    require(
      guardian != address(0),
      "Guarded: cannot add 0x0 guardian"
    );

    require(
      !guardians[guardian],
      "Guarded: guardian already exists"
    );

    guardians[guardian] = true;

    emit GuardianAdded(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin,
      guardian
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title ECDSA library
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/cryptography/ECDSA.sol#L26
 */
library ECDSALib {
  function recoverAddress(
    bytes32 messageHash,
    bytes memory signature
  )
    internal
    pure
    returns (address)
  {
    address result = address(0);

    if (signature.length == 65) {
      bytes32 r;
      bytes32 s;
      uint8 v;

      // solhint-disable-next-line no-inline-assembly
      assembly {
        r := mload(add(signature, 0x20))
        s := mload(add(signature, 0x40))
        v := byte(0, mload(add(signature, 0x60)))
      }

      if (v < 27) {
        v += 27;
      }

      if (v == 27 || v == 28) {
        result = ecrecover(messageHash, v, r, s);
      }
    }

    return result;
  }

  function toEthereumSignedMessageHash(
    bytes32 messageHash
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      messageHash
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Safe math library
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/math/SafeMath.sol
 */
library SafeMathLib {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;

    require(c >= a, "SafeMathLib: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMathLib: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);

    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;

    require(c / a == b, "SafeMathLib: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMathLib: division by zero");
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);

    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMathLib: modulo by zero");
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);

    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Initializable
 *
 * @dev Contract module which provides access control mechanism, where
 * there is the initializer account that can be granted exclusive access to
 * specific functions.
 *
 * The initializer account will be tx.origin during contract deployment and will be removed on first use.
 * Use `onlyInitializer` modifier on contract initialize process.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Initializable {
  address private initializer;

  // events

  /**
   * @dev Emitted after `onlyInitializer`
   * @param initializer initializer address
   */
  event Initialized(
    address initializer
  );

  // modifiers

  /**
   * @dev Throws if tx.origin is not the initializer
   */
  modifier onlyInitializer() {
    require(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin == initializer,
      "Initializable: tx.origin is not the initializer"
    );

    /// @dev removes initializer
    initializer = address(0);

    _;

    emit Initialized(
      // solhint-disable-next-line avoid-tx-origin
      tx.origin
    );
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    // solhint-disable-next-line avoid-tx-origin
    initializer = tx.origin;
  }

   // external functions (views)

  /**
   * @notice Check if contract is initialized
   * @return true when contract is initialized
   */
  function isInitialized()
    external
    view
    returns (bool)
  {
    return initializer == address(0);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/ECDSALib.sol";

/**
 * @title Signature validator
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract SignatureValidator {
  using ECDSALib for bytes32;

  uint256 public chainId;

  /**
   * @dev internal constructor
   */
  constructor() internal {
    uint256 chainId_;

    // solhint-disable-next-line no-inline-assembly
    assembly {
      chainId_ := chainid()
    }

    chainId = chainId_;
  }

  // internal functions

  function _hashMessagePayload(
    bytes32 messagePrefix,
    bytes memory messagePayload
  )
    internal
    view
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      chainId,
      address(this),
      messagePrefix,
      messagePayload
    )).toEthereumSignedMessageHash();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../libs/SafeMathLib.sol";


/**
 * @title ERC20 token
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/token/ERC20/ERC20.sol
 */
contract ERC20Token {
  using SafeMathLib for uint256;

  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;

  mapping(address => uint256) internal balances;
  mapping(address => mapping(address => uint256)) internal allowances;

  // events

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // external functions

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (bool)
  {
    _transfer(_getSender(), to, value);

    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    virtual
    external
    returns (bool)
  {
    address sender = _getSender();

    _transfer(from, to, value);
    _approve(from, sender, allowances[from][sender].sub(value));

    return true;
  }

  function approve(
    address spender,
    uint256 value
  )
    virtual
    external
    returns (bool)
  {
    _approve(_getSender(), spender, value);

    return true;
  }

  // external functions (views)

  function balanceOf(
    address owner
  )
    virtual
    external
    view
    returns (uint256)
  {
    return balances[owner];
  }

  function allowance(
    address owner,
    address spender
  )
    virtual
    external
    view
    returns (uint256)
  {
    return allowances[owner][spender];
  }

  // internal functions

  function _transfer(
    address from,
    address to,
    uint256 value
  )
    virtual
    internal
  {
    require(
      from != address(0),
      "ERC20Token: cannot transfer from 0x0 address"
    );
    require(
      to != address(0),
      "ERC20Token: cannot transfer to 0x0 address"
    );

    balances[from] = balances[from].sub(value);
    balances[to] = balances[to].add(value);

    emit Transfer(from, to, value);
  }

  function _approve(
    address owner,
    address spender,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot approve from 0x0 address"
    );
    require(
      spender != address(0),
      "ERC20Token: cannot approve to 0x0 address"
    );

    allowances[owner][spender] = value;

    emit Approval(owner, spender, value);
  }

  function _mint(
    address owner,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot mint to 0x0 address"
    );
    require(
      value > 0,
      "ERC20Token: cannot mint 0 value"
    );

    balances[owner] = balances[owner].add(value);
    totalSupply = totalSupply.add(value);

    emit Transfer(address(0), owner, value);
  }

  function _burn(
    address owner,
    uint256 value
  )
    virtual
    internal
  {
    require(
      owner != address(0),
      "ERC20Token: cannot burn from 0x0 address"
    );

    balances[owner] = balances[owner].sub(
      value,
      "ERC20Token: burn value exceeds balance"
    );

    totalSupply = totalSupply.sub(value);

    emit Transfer(owner, address(0), value);
  }

  // internal functions (views)

  function _getSender()
    virtual
    internal
    view
    returns (address)
  {
    return msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/libs/BlockLib.sol";


/**
 * @title External account registry
 *
 * @notice Global registry for keys and external (outside of the platform) contract based wallets
 *
 * @dev An account can call the registry to add (`addAccountOwner`) or remove (`removeAccountOwner`) its own owners.
 * When the owner has been added, information about that fact will live in the registry forever.
 * Removing an owner only affects the future blocks (until the owner is re-added).
 *
 * Given the fact, there is no way to sign the data using a contract based wallet,
 * we created a registry to store signed by the key wallet proofs.
 * ERC-1271 allows removing a signer after the signature was created. Thus store the signature for the later use
 * doesn't guarantee the signer is still has access to that smart account.
 * Because of that, the ERC1271's `isValidSignature()` cannot be used in e.g. `PaymentRegistry`.*
 *
 * An account can call the registry to add (`addAccountProof`) or remove (`removeAccountProof`) proof hash.
 * When the proof has been added, information about that fact will live in the registry forever.
 * Removing a proof only affects the future blocks (until the proof is re-added).
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract ExternalAccountRegistry {
  using BlockLib for BlockLib.BlockRelated;

  struct Account {
    mapping(address => BlockLib.BlockRelated) owners;
    mapping(bytes32 => BlockLib.BlockRelated) proofs;
  }

  mapping(address => Account) private accounts;

  // events

  /**
   * @dev Emitted when the new owner is added
   * @param account account address
   * @param owner owner address
   */
  event AccountOwnerAdded(
    address account,
    address owner
  );

  /**
   * @dev Emitted when the existing owner is removed
   * @param account account address
   * @param owner owner address
   */
  event AccountOwnerRemoved(
    address account,
    address owner
  );

  /**
   * @dev Emitted when the new proof is added
   * @param account account address
   * @param hash proof hash
   */
  event AccountProofAdded(
    address account,
    bytes32 hash
  );

  /**
   * @dev Emitted when the existing proof is removed
   * @param account account address
   * @param hash proof hash
   */
  event AccountProofRemoved(
    address account,
    bytes32 hash
  );

  // external functions

  /**
   * @notice Adds a new account owner
   * @param owner owner address
   */
  function addAccountOwner(
    address owner
  )
    external
  {
    require(
      owner != address(0),
      "ExternalAccountRegistry: cannot add 0x0 owner"
    );

    require(
      !accounts[msg.sender].owners[owner].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: owner already exists"
    );

    accounts[msg.sender].owners[owner].added = true;
    accounts[msg.sender].owners[owner].removedAtBlockNumber = 0;

    emit AccountOwnerAdded(
      msg.sender,
      owner
    );
  }

  /**
   * @notice Removes existing account owner
   * @param owner owner address
   */
  function removeAccountOwner(
    address owner
  )
    external
  {
    require(
      accounts[msg.sender].owners[owner].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: owner doesn't exist"
    );

    accounts[msg.sender].owners[owner].removedAtBlockNumber = block.number;

    emit AccountOwnerRemoved(
      msg.sender,
      owner
    );
  }

  /**
   * @notice Adds a new account proof
   * @param hash proof hash
   */
  function addAccountProof(
    bytes32 hash
  )
    external
  {
    require(
      !accounts[msg.sender].proofs[hash].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: proof already exists"
    );

    accounts[msg.sender].proofs[hash].added = true;
    accounts[msg.sender].proofs[hash].removedAtBlockNumber = 0;

    emit AccountProofAdded(
      msg.sender,
      hash
    );
  }

  /**
   * @notice Removes existing account proof
   * @param hash proof hash
   */
  function removeAccountProof(
    bytes32 hash
  )
    external
  {
    require(
      accounts[msg.sender].proofs[hash].verifyAtCurrentBlock(),
      "ExternalAccountRegistry: proof doesn't exist"
    );

    accounts[msg.sender].proofs[hash].removedAtBlockNumber = block.number;

    emit AccountProofRemoved(
      msg.sender,
      hash
    );
  }

  // external functions (views)

  /**
   * @notice Verifies the owner of the account at current block
   * @param account account address
   * @param owner owner address
   * @return true on correct account owner
   */
  function verifyAccountOwner(
    address account,
    address owner
  )
    external
    view
    returns (bool)
  {
    return accounts[account].owners[owner].verifyAtCurrentBlock();
  }

  /**
   * @notice Verifies the owner of the account at specific block
   * @param account account address
   * @param owner owner address
   * @param blockNumber block number to verify
   * @return true on correct account owner
   */
  function verifyAccountOwnerAtBlock(
    address account,
    address owner,
    uint256 blockNumber
  )
    external
    view
    returns (bool)
  {
    return accounts[account].owners[owner].verifyAtBlock(blockNumber);
  }

  /**
   * @notice Verifies the proof of the account at current block
   * @param account account address
   * @param hash proof hash
   * @return true on correct account proof
   */
  function verifyAccountProof(
    address account,
    bytes32 hash
  )
    external
    view
    returns (bool)
  {
    return accounts[account].proofs[hash].verifyAtCurrentBlock();
  }

  /**
   * @notice Verifies the proof of the account at specific block
   * @param account account address
   * @param hash proof hash
   * @param blockNumber block number to verify
   * @return true on correct account proof
   */
  function verifyAccountProofAtBlock(
    address account,
    bytes32 hash,
    uint256 blockNumber
  )
    external
    view
    returns (bool)
  {
    return accounts[account].proofs[hash].verifyAtBlock(blockNumber);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/access/Guarded.sol";
import "../common/account/AccountController.sol";
import "../common/account/AccountRegistry.sol";
import "../common/libs/BlockLib.sol";
import "../common/libs/ECDSALib.sol";
import "../common/libs/ECDSAExtendedLib.sol";
import "../common/libs/SafeMathLib.sol";
import "../common/lifecycle/Initializable.sol";
import "../common/token/ERC20Token.sol";
import "../gateway/GatewayRecipient.sol";


/**
 * @title Personal account registry
 *
 * @notice A registry for personal (controlled by owners) accounts
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract PersonalAccountRegistry is Guarded, AccountController, AccountRegistry, Initializable, GatewayRecipient {
  using BlockLib for BlockLib.BlockRelated;
  using SafeMathLib for uint256;
  using ECDSALib for bytes32;
  using ECDSAExtendedLib for bytes;

  struct Account {
    bool deployed;
    bytes32 salt;
    mapping(address => BlockLib.BlockRelated) owners;
  }

  mapping(address => Account) private accounts;

  // events

  /**
   * @dev Emitted when the new owner is added
   * @param account account address
   * @param owner owner address
   */
  event AccountOwnerAdded(
    address account,
    address owner
  );

  /**
   * @dev Emitted when the existing owner is removed
   * @param account account address
   * @param owner owner address
   */
  event AccountOwnerRemoved(
    address account,
    address owner
  );

  /**
   * @dev Emitted when the call is refunded
   * @param account account address
   * @param beneficiary beneficiary address
   * @param token token address
   * @param value value
   */
  event AccountCallRefunded(
    address account,
    address beneficiary,
    address token,
    uint256 value
  );

  /**
   * @dev Public constructor
   */
  constructor() public Initializable() {}

  // external functions

  /**
   * @notice Initializes `PersonalAccountRegistry` contract
   * @param guardians_ array of guardians addresses
   * @param accountImplementation_ account implementation address
   * @param gateway_ `Gateway` contract address
   */
  function initialize(
    address[] calldata guardians_,
    address accountImplementation_,
    address gateway_
  )
    external
    onlyInitializer
  {
    // Guarded
    _initializeGuarded(guardians_);

    // AccountController
    _initializeAccountController(address(this), accountImplementation_);

    // GatewayRecipient
    _initializeGatewayRecipient(gateway_);
  }

  /**
   * @notice Upgrades `PersonalAccountRegistry` contract
   * @param accountImplementation_ account implementation address
   */
  function upgrade(
    address accountImplementation_
  )
    external
    onlyGuardian
  {
    _setAccountImplementation(accountImplementation_, true);
  }

  /**
   * @notice Deploys account
   * @param account account address
   */
  function deployAccount(
    address account
  )
    external
  {
    _verifySender(account);
    _deployAccount(account);
  }

  /**
   * @notice Upgrades account
   * @param account account address
   */
  function upgradeAccount(
    address account
  )
    external
  {
    _verifySender(account);
    _upgradeAccount(account, true);
  }

  /**
   * @notice Adds a new account owner
   * @param account account address
   * @param owner owner address
   */
  function addAccountOwner(
    address account,
    address owner
  )
    external
  {
    _verifySender(account);

    require(
      owner != address(0),
      "PersonalAccountRegistry: cannot add 0x0 owner"
    );

    require(
      !accounts[account].owners[owner].verifyAtCurrentBlock(),
      "PersonalAccountRegistry: owner already exists"
    );

    accounts[account].owners[owner].added = true;
    accounts[account].owners[owner].removedAtBlockNumber = 0;

    emit AccountOwnerAdded(
      account,
      owner
    );
  }

  /**
   * @notice Removes the existing account owner
   * @param account account address
   * @param owner owner address
   */
  function removeAccountOwner(
    address account,
    address owner
  )
    external
  {
    address sender = _verifySender(account);

    require(
      owner != sender,
      "PersonalAccountRegistry: cannot remove self"
    );

    require(
      accounts[account].owners[owner].verifyAtCurrentBlock(),
      "PersonalAccountRegistry: owner doesn't exist"
    );

    accounts[account].owners[owner].removedAtBlockNumber = block.number;

    emit AccountOwnerRemoved(
      account,
      owner
    );
  }

  /**
   * @notice Executes account transaction
   * @dev Deploys an account if not deployed yet
   * @param account account address
   * @param to to address
   * @param value value
   * @param data data
   */
  function executeAccountTransaction(
    address account,
    address to,
    uint256 value,
    bytes calldata data
  )
    external
  {
    _verifySender(account);

    _deployAccount(account);

    _executeAccountTransaction(
      account,
      to,
      value,
      data,
      true
    );
  }

  /**
   * @notice Refunds account call
   * @dev Deploys an account if not deployed yet
   * @param account account address
   * @param token token address
   * @param value value
   */
  function refundAccountCall(
    address account,
    address token,
    uint256 value
  )
    external
  {
    _verifySender(account);

    _deployAccount(account);

    /* solhint-disable avoid-tx-origin */

    if (token == address(0)) {
      _executeAccountTransaction(
        account,
        tx.origin,
        value,
        new bytes(0),
        false
      );
    } else {
      bytes memory response = _executeAccountTransaction(
        account,
        token,
        0,
        abi.encodeWithSelector(
          ERC20Token(token).transfer.selector,
          tx.origin,
          value
        ),
        false
      );

      if (response.length > 0) {
        require(
          abi.decode(response, (bool)),
          "PersonalAccountRegistry: ERC20Token transfer reverted"
        );
      }
    }

    emit AccountCallRefunded(
      account,
      tx.origin,
      token,
      value
    );

    /* solhint-enable avoid-tx-origin */
  }

  // external functions (views)

  /**
   * @notice Computes account address
   * @param saltOwner salt owner address
   * @return account address
   */
  function computeAccountAddress(
    address saltOwner
  )
    external
    view
    returns (address)
  {
    return _computeAccountAddress(saltOwner);
  }

  /**
   * @notice Checks if account is deployed
   * @param account account address
   * @return true when account is deployed
   */
  function isAccountDeployed(
    address account
  )
    external
    view
    returns (bool)
  {
    return accounts[account].deployed;
  }

  /**
   * @notice Verifies the owner of the account at the current block
   * @param account account address
   * @param owner owner address
   * @return true on correct account owner
   */
  function verifyAccountOwner(
    address account,
    address owner
  )
    external
    view
    returns (bool)
  {
    return _verifyAccountOwner(account, owner);
  }

  /**
   * @notice Verifies the owner of the account at a specific block
   * @param account account address
   * @param owner owner address
   * @param blockNumber block number to verify
   * @return true on correct account owner
   */
  function verifyAccountOwnerAtBlock(
    address account,
    address owner,
    uint256 blockNumber
  )
    external
    view
    returns (bool)
  {
    bool result = false;

    if (_verifyAccountOwner(account, owner)) {
      result = true;
    } else {
      result = accounts[account].owners[owner].verifyAtBlock(blockNumber);
    }

    return result;
  }

  /**
   * @notice Verifies account signature
   * @param account account address
   * @param messageHash message hash
   * @param signature signature
   * @return magic hash if valid
   */
  function isValidAccountSignature(
    address account,
    bytes32 messageHash,
    bytes calldata signature
  )
    override
    external
    view
    returns (bool)
  {
    return _verifyAccountOwner(
      account,
      messageHash.recoverAddress(signature)
    );
  }

  /**
   * @notice Verifies account signature
   * @param account account address
   * @param message message
   * @param signature signature
   * @return magic hash if valid
   */
  function isValidAccountSignature(
    address account,
    bytes calldata message,
    bytes calldata signature
  )
    override
    external
    view
    returns (bool)
  {
    return _verifyAccountOwner(
      account,
      message.toEthereumSignedMessageHash().recoverAddress(signature)
    );
  }

  // private functions

  function _verifySender(
    address account
  )
    private
    returns (address)
  {
    address sender = _getContextSender();

    if (accounts[account].owners[sender].added) {
      require(
        accounts[account].owners[sender].removedAtBlockNumber == 0,
        "PersonalAccountRegistry: sender is not the account owner"
      );
    } else {
      require(
        accounts[account].salt == 0,
        "PersonalAccountRegistry: sender is not the account owner"
      );

      bytes32 salt = keccak256(
        abi.encodePacked(sender)
      );

      require(
        account == _computeAccountAddress(salt),
        "PersonalAccountRegistry: sender is not the account owner"
      );

      accounts[account].salt = salt;
      accounts[account].owners[sender].added = true;

      emit AccountOwnerAdded(
        account,
        sender
      );
    }

    return sender;
  }

  function _deployAccount(
    address account
  )
    internal
  {
    if (!accounts[account].deployed) {
      _deployAccount(
        accounts[account].salt,
        true
      );

      accounts[account].deployed = true;
    }
  }

  // private functions (views)

  function _computeAccountAddress(
    address saltOwner
  )
    private
    view
    returns (address)
  {
    bytes32 salt = keccak256(
      abi.encodePacked(saltOwner)
    );

    return _computeAccountAddress(salt);
  }

  function _verifyAccountOwner(
    address account,
    address owner
  )
    private
    view
    returns (bool)
  {
    bool result;

    if (accounts[account].owners[owner].added) {
      result = accounts[account].owners[owner].removedAtBlockNumber == 0;
    } else if (accounts[account].salt == 0) {
      result = account == _computeAccountAddress(owner);
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/libs/BytesLib.sol";


/**
 * @title Gateway recipient
 *
 * @notice Gateway target contract
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract GatewayRecipient {
  using BytesLib for bytes;

  address public gateway;

  /**
   * @dev internal constructor
   */
  constructor() internal {}

  // internal functions

  /**
   * @notice Initializes `GatewayRecipient` contract
   * @param gateway_ `Gateway` contract address
   */
  function _initializeGatewayRecipient(
    address gateway_
  )
    internal
  {
    gateway = gateway_;
  }

  // internal functions (views)

  /**
   * @notice Gets gateway context account
   * @return context account address
   */
  function _getContextAccount()
    internal
    view
    returns (address)
  {
    return _getContextAddress(40);
  }

  /**
   * @notice Gets gateway context sender
   * @return context sender address
   */
  function _getContextSender()
    internal
    view
    returns (address)
  {
    return _getContextAddress(20);
  }

  /**
   * @notice Gets gateway context data
   * @return context data
   */
  function _getContextData()
    internal
    view
    returns (bytes calldata)
  {
    bytes calldata result;

    if (_isGatewaySender()) {
      result = msg.data[:msg.data.length - 40];
    } else {
      result = msg.data;
    }

    return result;
  }

  // private functions (views)

  function _getContextAddress(
    uint256 offset
  )
    private
    view
    returns (address)
  {
    address result = address(0);

    if (_isGatewaySender()) {
      uint from = msg.data.length - offset;
      result = bytes(msg.data[from:from + 20]).toAddress();
    } else {
      result = msg.sender;
    }

    return result;
  }

  function _isGatewaySender()
    private
    view
    returns (bool)
  {
    bool result;

    if (msg.sender == gateway) {
      require(
        msg.data.length >= 44,
        "GatewayRecipient: invalid msg.data"
      );

      result = true;
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../common/access/Controlled.sol";


/**
 * @title Payment deposit account
 *
 * @dev Simple account contract with only one method - `executeTransaction`
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract PaymentDepositAccount is Controlled {
  /**
   * @dev Public constructor
   */
  constructor() public payable Controlled() {}

  /**
   * @notice Allow receives
   */
  receive()
    external
    payable
  {
    //
  }

  // external functions

  /**
   * @notice Executes transaction
   * @param to to address
   * @param value value
   * @param data data
   * @return transaction result
   */
  function executeTransaction(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    onlyController
    returns (bytes memory)
  {
    bytes memory result;
    bool succeeded;

    // solhint-disable-next-line avoid-call-value, avoid-low-level-calls
    (succeeded, result) = payable(to).call{value: value}(data);

    require(
      succeeded,
      "Account: transaction reverted"
    );

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Block library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library BlockLib {
  struct BlockRelated {
    bool added;
    uint256 removedAtBlockNumber;
  }

  /**
   * @notice Verifies self struct at current block
   * @param self self struct
   * @return true on correct self struct
   */
  function verifyAtCurrentBlock(
    BlockRelated memory self
  )
    internal
    view
    returns (bool)
  {
    return verifyAtBlock(self, block.number);
  }

  /**
   * @notice Verifies self struct at any block
   * @param self self struct
   * @return true on correct self struct
   */
  function verifyAtAnyBlock(
    BlockRelated memory self
  )
    internal
    pure
    returns (bool)
  {
    return verifyAtBlock(self, 0);
  }

  /**
   * @notice Verifies self struct at specific block
   * @param self self struct
   * @param blockNumber block number to verify
   * @return true on correct self struct
   */
  function verifyAtBlock(
    BlockRelated memory self,
    uint256 blockNumber
  )
    internal
    pure
    returns (bool)
  {
    bool result = false;

    if (self.added) {
      if (self.removedAtBlockNumber == 0) {
        result = true;
      } else if (blockNumber == 0) {
        result = true;
      } else {
        result = self.removedAtBlockNumber > blockNumber;
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Account.sol";


/**
 * @title Account controller
 *
 * @dev Contract module which provides Account deployment mechanism
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract AccountController {
  address public accountRegistry;
  address public accountImplementation;

  // events

  /**
   * @dev Emitted when the account registry is updated
   * @param accountRegistry account registry address
   */
  event AccountRegistryUpdated(
    address accountRegistry
  );

  /**
   * @dev Emitted when the account implementation is updated
   * @param accountImplementation account implementation address
   */
  event AccountImplementationUpdated(
    address accountImplementation
  );

  /**
   * @dev Emitted when the account is deployed
   * @param account account address
   * @param accountImplementation account implementation address
   */
  event AccountDeployed(
    address account,
    address accountImplementation
  );

  /**
   * @dev Emitted when the account is upgraded
   * @param account account address
   * @param accountImplementation account implementation address
   */
  event AccountUpgraded(
    address account,
    address accountImplementation
  );

  /**
   * @dev Emitted when the transaction is executed
   * @param account account address
   * @param to to address
   * @param value value
   * @param data data
   * @param response response
   */
  event AccountTransactionExecuted(
    address account,
    address to,
    uint256 value,
    bytes data,
    bytes response
  );

  /**
   * @dev Internal constructor
   */
  constructor() internal {}

  // internal functions

  /**
   * @notice Initializes `AccountController` contract
   * @param accountRegistry_ account registry address
   * @param accountImplementation_ account implementation address
   */
  function _initializeAccountController(
    address accountRegistry_,
    address accountImplementation_
  )
    internal
  {
    _setAccountRegistry(accountRegistry_, false);
    _setAccountImplementation(accountImplementation_, false);
  }

  /**
   * @notice Sets account registry
   * @param accountRegistry_ account registry address
   * @param emitEvent it will emit event when flag is set to true
   */
  function _setAccountRegistry(
    address accountRegistry_,
    bool emitEvent
  )
    internal
  {
    require(
      accountRegistry_ != address(0),
      "AccountController: cannot set account registry to 0x0"
    );

    accountRegistry = accountRegistry_;

    if (emitEvent) {
      emit AccountRegistryUpdated(accountRegistry);
    }
  }

  /**
   * @notice Sets account implementation
   * @param accountImplementation_ account implementation address
   * @param emitEvent it will emit event when flag is set to true
   */
  function _setAccountImplementation(
    address accountImplementation_,
    bool emitEvent
  )
    internal
  {
    require(
      accountImplementation_ != address(0),
      "AccountController: cannot set account Implementation to 0x0"
    );

    accountImplementation = accountImplementation_;

    if (emitEvent) {
      emit AccountImplementationUpdated(accountImplementation);
    }
  }

  /**
   * @notice Deploys account
   * @param salt CREATE2 salt
   * @param emitEvent it will emit event when flag is set to true
   * @return account address
   */
  function _deployAccount(
    bytes32 salt,
    bool emitEvent
  )
    internal
    returns (address)
  {
    address account = address(new Account{salt: salt}(
      accountRegistry,
      accountImplementation
    ));

    if (emitEvent) {
      emit AccountDeployed(
        account,
        accountImplementation
      );
    }

    return account;
  }

  /**
   * @notice Upgrades account
   * @param account account address
   * @param emitEvent it will emit event when flag is set to true
   */
  function _upgradeAccount(
    address account,
    bool emitEvent
  )
    internal
  {
    require(
      Account(payable(account)).implementation() != accountImplementation,
      "AccountController: account already upgraded"
    );

    Account(payable(account)).setImplementation(accountImplementation);

    if (emitEvent) {
      emit AccountUpgraded(
        account,
        accountImplementation
      );
    }
  }

  /**
   * @notice Executes transaction from the account
   * @param account account address
   * @param to to address
   * @param value value
   * @param data data
   * @param emitEvent it will emit event when flag is set to true
   * @return transaction result
   */
  function _executeAccountTransaction(
    address account,
    address to,
    uint256 value,
    bytes memory data,
    bool emitEvent
  )
    internal
    returns (bytes memory)
  {
    require(
      to != address(0),
      "AccountController: cannot send to 0x0"
    );

    require(
      to != address(this),
      "AccountController: cannot send to controller"
    );

    require(
      to != account,
      "AccountController: cannot send to self"
    );

    bytes memory response = Account(payable(account)).executeTransaction(
      to,
      value,
      data
    );

    if (emitEvent) {
      emit AccountTransactionExecuted(
        account,
        to,
        value,
        data,
        response
      );
    }

    return response;
  }

  // internal functions (views)

  /**
   * @notice Computes account CREATE2 address
   * @param salt CREATE2 salt
   * @return account address
   */
  function _computeAccountAddress(
    bytes32 salt
  )
    internal
    view
    returns (address)
  {
    bytes memory creationCode = abi.encodePacked(
      type(Account).creationCode,
      bytes12(0),
      accountRegistry,
      bytes12(0),
      accountImplementation
    );

    bytes32 data = keccak256(
      abi.encodePacked(
        bytes1(0xff),
        address(this),
        salt,
        keccak256(creationCode)
      )
    );

    return address(uint160(uint256(data)));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./Account.sol";


/**
 * @title Account registry
 *
 * @author Stanisław Głogowski <[email protected]>
 */
abstract contract AccountRegistry {
  /**
   * @notice Verifies account signature
   * @param account account address
   * @param messageHash message hash
   * @param signature signature
   * @return true if valid
   */
  function isValidAccountSignature(
    address account,
    bytes32 messageHash,
    bytes calldata signature
  )
    virtual
    external
    view
    returns (bool);

  /**
   * @notice Verifies account signature
   * @param account account address
   * @param message message
   * @param signature signature
   * @return true if valid
   */
  function isValidAccountSignature(
    address account,
    bytes calldata message,
    bytes calldata signature
  )
    virtual
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./StringsLib.sol";


/**
 * @title ECDSA extended library
 */
library ECDSAExtendedLib {
  using StringsLib for uint;

  function toEthereumSignedMessageHash(
    bytes memory message
  )
    internal
    pure
    returns (bytes32)
  {
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n",
      message.length.toString(),
      abi.encodePacked(message)
    ));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "../access/Controlled.sol";
import "./AccountBase.sol";


/**
 * @title Account
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Account is Controlled, AccountBase {
  address public implementation;

  /**
   * @dev Public constructor
   * @param registry_ account registry address
   * @param implementation_ account implementation address
   */
  constructor(
    address registry_,
    address implementation_
  )
    public
    Controlled()
  {
    registry = registry_;
    implementation = implementation_;
  }

  // external functions

  /**
   * @notice Payable receive
   */
  receive()
    external
    payable
  {
    //
  }

  /**
   * @notice Fallback
   */
  // solhint-disable-next-line payable-fallback
  fallback()
    external
  {
    if (msg.data.length != 0) {
      address implementation_ = implementation;

      // solhint-disable-next-line no-inline-assembly
      assembly {
        let calldedatasize := calldatasize()

        calldatacopy(0, 0, calldedatasize)

        let result := delegatecall(gas(), implementation_, 0, calldedatasize, 0, 0)
        let returneddatasize := returndatasize()

        returndatacopy(0, 0, returneddatasize)

        switch result
        case 0 { revert(0, returneddatasize) }
        default { return(0, returneddatasize) }
      }
    }
  }

  /**
   * @notice Sets implementation
   * @param implementation_ implementation address
   */
  function setImplementation(
    address implementation_
  )
    external
    onlyController
  {
    implementation = implementation_;
  }

  /**
   * @notice Executes transaction
   * @param to to address
   * @param value value
   * @param data data
   * @return transaction result
   */
  function executeTransaction(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    onlyController
    returns (bytes memory)
  {
    bytes memory result;
    bool succeeded;

    // solhint-disable-next-line avoid-call-value, avoid-low-level-calls
    (succeeded, result) = payable(to).call{value: value}(data);

    require(
      succeeded,
      "Account: transaction reverted"
    );

    return result;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Controlled
 *
 * @dev Contract module which provides an access control mechanism.
 * It ensures there is only one controlling account of the smart contract
 * and grants that account exclusive access to specific functions.
 *
 * The controller account will be the one that deploys the contract.
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract Controlled {
  /**
   * @return controller account address
   */
  address public controller;

  // modifiers

  /**
   * @dev Throws if msg.sender is not the controller
   */
  modifier onlyController() {
    require(
      msg.sender == controller,
      "Controlled: msg.sender is not the controller"
    );

    _;
  }

  /**
   * @dev Internal constructor
   */
  constructor()
    internal
  {
    controller = msg.sender;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Account base
 *
 * @author Stanisław Głogowski <[email protected]>
 */
contract AccountBase {
  address public registry;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Strings library
 *
 * @dev Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.3.0/contracts/utils/Strings.sol#L12
 */
library StringsLib {
  function toString(
    uint256 value
  )
    internal
    pure
    returns (string memory)
  {
    if (value == 0) {
      return "0";
    }

    uint256 temp = value;
    uint256 digits;

    while (temp != 0) {
      digits++;
      temp /= 10;
    }

    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = value;

    while (temp != 0) {
      buffer[index--] = byte(uint8(48 + temp % 10));
      temp /= 10;
    }

    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @title Bytes library
 *
 * @author Stanisław Głogowski <[email protected]>
 */
library BytesLib {
  /**
   * @notice Converts bytes to address
   * @param data data
   * @return address
   */
  function toAddress(
    bytes memory data
  )
    internal
    pure
    returns (address)
  {
    address result;

    require(
      data.length == 20,
      "BytesLib: invalid data length"
    );

    // solhint-disable-next-line no-inline-assembly
    assembly {
      result := div(mload(add(data, 0x20)), 0x1000000000000000000000000)
    }

    return result;
  }
}