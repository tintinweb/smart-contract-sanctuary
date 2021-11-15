// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./vendor/@eth-optimism/contracts/0.4.7/contracts/optimistic-ethereum/iOVM/bridge/messaging/iOVM_CrossDomainMessenger.sol";
import "../interfaces/AggregatorValidatorInterface.sol";
import "../interfaces/TypeAndVersionInterface.sol";
import "../interfaces/AccessControllerInterface.sol";
import "../vendor/SimpleWriteAccessController.sol";
import "./interfaces/FlagsInterface.sol";
import "./OptimismCrossDomainAccount.sol";

/**
 * @title OptimismValidator
 * @notice Allows to raise and lower Flags on the Optimism network through its Layer 1 contracts
 *  - The internal AccessController controls the access of the validate method
 *  - Gas configuration is controlled by a configurable external SimpleWriteAccessController
 */
contract OptimismValidator is TypeAndVersionInterface, AggregatorValidatorInterface, SimpleWriteAccessController {
  // Config for L1 -> L2 call
  struct GasConfiguration {
    uint32 gasLimitL2;
  }

  /// @dev Follows: https://eips.ethereum.org/EIPS/eip-1967
  address constant private FLAG_OPTIMISM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.optimism-seq-offline")) - 1)));
  bytes constant private CALL_RAISE_FLAG = abi.encodeWithSelector(FlagsInterface.raiseFlag.selector, FLAG_OPTIMISM_SEQ_OFFLINE);
  bytes constant private CALL_LOWER_FLAG = abi.encodeWithSelector(FlagsInterface.lowerFlag.selector, FLAG_OPTIMISM_SEQ_OFFLINE);
  uint8 constant ANSWER_OPTIMISM_SEQ_OFFLINE = 1;

  address private s_l2FlagsAddress;
  iOVM_CrossDomainMessenger private s_crossDomainMessenger;
  OptimismCrossDomainAccount private s_crossDomainAccount;
  AccessControllerInterface private s_gasConfigAccessController;
  GasConfiguration private s_gasConfig;

  /**
   * @notice emitted when a new gas configuration is set
   * @param gasLimitL2 gas limit
   */
  event GasConfigurationSet(
    uint32 gasLimitL2
  );

  /**
   * @notice emitted when a new gas access-control contract is set
   * @param previous the address prior to the current setting
   * @param current the address of the new access-control contract
   */
  event GasAccessControllerSet(
    address indexed previous,
    address indexed current
  );

  /**
   * @param optimismMessengerAddress address of the Optimism Messenger L1 contract
   * @param l2CrossDomainAccount address of the Chainlink L2 Forwarder contract
   * @param l2FlagsAddress address of the Chainlink L2 Flags contract
   * @param gasConfigAccessControllerAddress address of the access controller for managing gas price on Arbitrum
   * @param gasLimitL2 gas limit for immediate L2 execution attempt. A value around 1M should be sufficient
   */
  constructor(
    address optimismMessengerAddress,
    address l2CrossDomainAccount,
    address l2FlagsAddress,
    address gasConfigAccessControllerAddress,
    uint32 gasLimitL2
  ) {
    require(optimismMessengerAddress != address(0), "Invalid Optimism Messenger contract address");
    require(l2CrossDomainAccount != address(0), "Invalid L2 Forwarder contract address");
    require(l2FlagsAddress != address(0), "Invalid Flags contract address");
    s_crossDomainMessenger = iOVM_CrossDomainMessenger(optimismMessengerAddress);
    s_crossDomainAccount = OptimismCrossDomainAccount(l2CrossDomainAccount);
    s_gasConfigAccessController = AccessControllerInterface(gasConfigAccessControllerAddress);
    s_l2FlagsAddress = l2FlagsAddress;
    _setGasConfiguration(gasLimitL2);
  }

  /**
   * @notice versions:
   *
   * - OptimismValidator 0.1.0: initial release
   *
   * @inheritdoc TypeAndVersionInterface
   */
  function typeAndVersion()
    external
    pure
    virtual
    override
    returns (
      string memory
    )
  {
    return "OptimismValidator 0.1.0";
  }

  /// @return L2 Flags contract address
  function l2Flags()
    external
    view
    virtual
    returns (address)
  {
    return s_l2FlagsAddress;
  }

  /// @return Optimism L2 forwarder contract address
  function crossDomainAccount()
    external
    view
    virtual
    returns (address)
  {
    return address(s_crossDomainAccount);
  }

  /// @return gas config AccessControllerInterface contract address
  function gasConfigAccessController()
    external
    view
    virtual
    returns (address)
  {
    return address(s_gasConfigAccessController);
  }

  /// @return stored GasConfiguration
  function gasConfig()
    external
    view
    virtual
    returns (uint32)
  {
    return s_gasConfig.gasLimitL2;
  }

  /**
   * @notice sets gas config AccessControllerInterface contract
   * @dev only owner can call this
   * @param accessController new AccessControllerInterface contract address
   */
  function setGasAccessController(
    address accessController
  )
    external
    onlyOwner
  {
    _setGasAccessController(accessController);
  }

  /**
   * @notice sets Optimism gas configuration
   * @dev access control provided by s_gasConfigAccessController
   * @param gasLimitL2 gas limit for immediate L2 execution attempt. A value around 1M should be sufficient
   */
  function setGasConfiguration(
    uint32 gasLimitL2
  )
    external
  {
    require(s_gasConfigAccessController.hasAccess(msg.sender, msg.data), "Access required to set config");
    _setGasConfiguration(gasLimitL2);
  }

  /**
   * @notice validate method updates the state of an L2 Flag in case of change on the Optimism Sequencer.
   * A one answer considers the service as offline.
   * In case the previous answer is the same as the current it does not trigger any tx on L2. In other case,
   * a message is relayed to the Optimism Messenger contract. 
   * @dev access control provided internally by SimpleWriteAccessController
   * @param previousAnswer previous aggregator answer
   * @param currentAnswer new aggregator answer
   */
  function validate(
    uint256 /* previousRoundId */,
    int256 previousAnswer,
    uint256 /* currentRoundId */,
    int256 currentAnswer
  ) 
    external
    override
    checkAccess
    returns (bool)
  {
    // Avoids resending to L2 the same tx on every call
    if (previousAnswer == currentAnswer) {
      return true;
    }

    s_crossDomainMessenger.sendMessage(
      address(s_crossDomainAccount),
      abi.encodeWithSelector(s_crossDomainAccount.forward.selector, s_l2FlagsAddress, currentAnswer == ANSWER_OPTIMISM_SEQ_OFFLINE ? CALL_RAISE_FLAG : CALL_LOWER_FLAG),
      s_gasConfig.gasLimitL2
    );
    return true;
  }

  function _setGasConfiguration(
    uint32 gasLimitL2
  )
    internal
  {
    s_gasConfig = GasConfiguration(gasLimitL2);
    emit GasConfigurationSet(gasLimitL2);
  }

  function _setGasAccessController(
    address accessController
  )
    internal
  {
    address previousAccessController = address(s_gasConfigAccessController);
    if (accessController != previousAccessController) {
      s_gasConfigAccessController = AccessControllerInterface(accessController);
      emit GasAccessControllerSet(previousAccessController, accessController);
    }
  }
}

pragma solidity ^0.7.0;

/**
 * @title iOVM_CrossDomainMessenger
 */
interface iOVM_CrossDomainMessenger {

    /**********
     * Events *
     **********/

    event SentMessage(bytes message);
    event RelayedMessage(bytes32 msgHash);
    event FailedRelayedMessage(bytes32 msgHash);


    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);


    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorValidatorInterface {
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  )
    external
    returns (
      bool
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    virtual
    returns (
      string memory
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwner.sol";
import "../interfaces/AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
 */
contract SimpleWriteAccessController is AccessControllerInterface, ConfirmedOwner {

  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor() 
    ConfirmedOwner(msg.sender) 
  {
    checkEnabled = true;
  }

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return accessList[_user] || !checkEnabled;
  }

  /**
   * @notice Adds an address to the access list
   * @param _user The address to add
   */
  function addAccess(address _user)
    external
    onlyOwner()
  {
    if (!accessList[_user]) {
      accessList[_user] = true;

      emit AddedAccess(_user);
    }
  }

  /**
   * @notice Removes an address from the access list
   * @param _user The address to remove
   */
  function removeAccess(address _user)
    external
    onlyOwner()
  {
    if (accessList[_user]) {
      accessList[_user] = false;

      emit RemovedAccess(_user);
    }
  }

  /**
   * @notice makes the access check enforced
   */
  function enableAccessCheck()
    external
    onlyOwner()
  {
    if (!checkEnabled) {
      checkEnabled = true;

      emit CheckAccessEnabled();
    }
  }

  /**
   * @notice makes the access check unenforced
   */
  function disableAccessCheck()
    external
    onlyOwner()
  {
    if (checkEnabled) {
      checkEnabled = false;

      emit CheckAccessDisabled();
    }
  }

  /**
   * @dev reverts if the caller does not have access
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);
  function getFlags(address[] calldata) external view returns (bool[] memory);
  function raiseFlag(address) external;
  function raiseFlags(address[] calldata) external;
  function lowerFlag(address) external;
  function lowerFlags(address[] calldata) external;
  function setRaisingAccessController(address) external;
  function setLoweringAccessController(address) external;
}

pragma solidity ^0.7.0;

import "./vendor/@eth-optimism/contracts/0.4.7/contracts/optimistic-ethereum/iOVM/bridge/messaging/iOVM_CrossDomainMessenger.sol";
import "../vendor/ConfirmedOwner.sol";

// L2 Contract which receives messages from a specific L1 address and transparently
// forwards them to the destination.
// 
// Any other L2 contract which uses this contract's address as a privileged position,
// can be considered to be owned by the `l1Owner`
contract OptimismCrossDomainAccount is ConfirmedOwner {

    // OVM_L2CrossDomainMessenger is a precompiled with same address on every network
    iOVM_CrossDomainMessenger constant private s_messenger = iOVM_CrossDomainMessenger(0x4200000000000000000000000000000000000007);
    address s_l1Owner;

    event L1OwnershipTransfer(
      address indexed newOwner
    );

    constructor(
      address _l1Owner
    ) 
      ConfirmedOwner(msg.sender) 
    {
      s_l1Owner = _l1Owner;
    }

    function l1Owner() view public returns (address) {
      return s_l1Owner;
    }

    /**
     * @notice transfer ownership of this account to a new L1 owner
     * @dev only owner can call this
     * @param _l1Owner new L1 owner
     */
    function transferL1Ownership(
      address _l1Owner
    ) 
      external 
      onlyOwner
    {
      if (s_l1Owner != _l1Owner) {
        s_l1Owner = _l1Owner;
        emit L1OwnershipTransfer(_l1Owner);
      }
    }

    /**
     * @notice `forward` `calls` the `target` with `data`
     * @dev only `messenger` can call this. Only called if `tx.l1MessageSender == s_l1Owner`
     * @param _target contract address to be called
     * @param _data data to send to _target contract
     */
    function forward(
      address _target, 
      bytes memory _data
    ) 
      external 
    {
      // 1. The call MUST come from the L1 Messenger
      require(msg.sender == address(s_messenger), "Sender is not the messenger");
      // 2. The L1 Messenger's caller MUST be the L1 Owner
      require(s_messenger.xDomainMessageSender() == s_l1Owner, "L1Sender is not the L1Owner");
      // 3. Make the external call
      (bool success, bytes memory res) = _target.call(_data);
      require(success, string(abi.encode("XChain call failed:", res)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {

  constructor(
    address newOwner
  )
    ConfirmedOwnerWithProposal(
      newOwner,
      address(0)
    )
  {
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "../interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {

  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor(
    address newOwner,
    address pendingOwner
  ) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(
    address to
  )
    public
    override
    onlyOwner()
  {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
    override
  {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner()
    public
    view
    override
    returns (
      address
    )
  {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(
    address to
  )
    private
  {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership()
    internal
    view
  {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface OwnableInterface {
  function owner()
    external
    returns (
      address
    );

  function transferOwnership(
    address recipient
  )
    external;

  function acceptOwnership()
    external;
}

