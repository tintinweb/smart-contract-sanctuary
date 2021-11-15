// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

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
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";
import "./interfaces/AggregatorValidatorInterface.sol";
import "./interfaces/TypeAndVersionInterface.sol";

contract ValidatorProxy is AggregatorValidatorInterface, TypeAndVersionInterface, ConfirmedOwner {

  /// @notice Uses a single storage slot to store the current address
  struct AggregatorConfiguration {
    address target;
    bool hasNewProposal;
  }

  struct ValidatorConfiguration {
    AggregatorValidatorInterface target;
    bool hasNewProposal;
  }

  // Configuration for the current aggregator
  AggregatorConfiguration private s_currentAggregator;
  // Proposed aggregator address
  address private s_proposedAggregator;

  // Configuration for the current validator
  ValidatorConfiguration private s_currentValidator;
  // Proposed validator address
  AggregatorValidatorInterface private s_proposedValidator;

  event AggregatorProposed(
    address indexed aggregator
  );
  event AggregatorUpgraded(
    address indexed previous,
    address indexed current
  );
  event ValidatorProposed(
    AggregatorValidatorInterface indexed validator
  );
  event ValidatorUpgraded(
    AggregatorValidatorInterface indexed previous,
    AggregatorValidatorInterface indexed current
  );
  /// @notice The proposed aggregator called validate, but the call was not passed on to any validators
  event ProposedAggregatorValidateCall(
    address indexed proposed,
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  );

  /**
   * @notice Construct the ValidatorProxy with an aggregator and a validator
   * @param aggregator address
   * @param validator address
   */
  constructor(
    address aggregator,
    AggregatorValidatorInterface validator
  )
    ConfirmedOwner(msg.sender)
  {
    s_currentAggregator = AggregatorConfiguration({
      target: aggregator,
      hasNewProposal: false
    });
    s_currentValidator = ValidatorConfiguration({
      target: validator,
      hasNewProposal: false
    });
  }

  /**
   * @notice Validate a transmission
   * @dev Must be called by either the `s_currentAggregator.target`, or the `s_proposedAggregator`.
   * If called by the `s_currentAggregator.target` this function passes the call on to the `s_currentValidator.target`
   * and the `s_proposedValidator`, if it is set.
   * If called by the `s_proposedAggregator` this function emits a `ProposedAggregatorValidateCall` to signal that
   * the call was received.
   * @dev To guard against external `validate` calls reverting, we use raw calls here.
   * We favour `call` over try-catch to ensure that failures are avoided even if the validator address is incorrectly
   * set as a non-contract address.
   * @dev If the `aggregator` and `validator` are the same contract or collude, this could exhibit reentrancy behavior.
   * However, since that contract would have to be explicitly written for reentrancy and that the `owner` would have
   * to configure this contract to use that malicious contract, we refrain from using mutex or check here.
   * @dev This does not perform any checks on any roundId, so it is possible that a validator receive different reports
   * for the same roundId at different points in time. Validator implementations should be aware of this.
   * @param previousRoundId uint256
   * @param previousAnswer int256
   * @param currentRoundId uint256
   * @param currentAnswer int256
   * @return bool
   */
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  )
    external
    override
    returns (
      bool
    )
  {
    address currentAggregator = s_currentAggregator.target;
    if (msg.sender != currentAggregator) {
      address proposedAggregator = s_proposedAggregator;
      require(msg.sender == proposedAggregator, "Not a configured aggregator");
      // If the aggregator is still in proposed state, emit an event and don't push to any validator.
      // This is to confirm that `validate` is being called prior to upgrade.
      emit ProposedAggregatorValidateCall(
        proposedAggregator,
        previousRoundId,
        previousAnswer,
        currentRoundId,
        currentAnswer
      );
      return true;
    }

    // Send the validate call to the current validator
    ValidatorConfiguration memory currentValidator = s_currentValidator;
    address currentValidatorAddress = address(currentValidator.target);
    require(currentValidatorAddress != address(0), "No validator set");
    currentValidatorAddress.call(
      abi.encodeWithSelector(
        AggregatorValidatorInterface.validate.selector,
        previousRoundId,
        previousAnswer,
        currentRoundId,
        currentAnswer
      )
    );
    // If there is a new proposed validator, send the validate call to that validator also
    if (currentValidator.hasNewProposal) {
      address(s_proposedValidator).call(
        abi.encodeWithSelector(
          AggregatorValidatorInterface.validate.selector,
          previousRoundId,
          previousAnswer,
          currentRoundId,
          currentAnswer
        )
      );
    }
    return true;
  }

  /** AGGREGATOR CONFIGURATION FUNCTIONS **/

  /**
   * @notice Propose an aggregator
   * @dev A zero address can be used to unset the proposed aggregator. Only owner can call.
   * @param proposed address
   */
  function proposeNewAggregator(
    address proposed
  )
    external
    onlyOwner()
  {
    require(s_proposedAggregator != proposed && s_currentAggregator.target != proposed, "Invalid proposal");
    s_proposedAggregator = proposed;
    // If proposed is zero address, hasNewProposal = false
    s_currentAggregator.hasNewProposal = (proposed != address(0));
    emit AggregatorProposed(proposed);
  }

  /**
   * @notice Upgrade the aggregator by setting the current aggregator as the proposed aggregator.
   * @dev Must have a proposed aggregator. Only owner can call.
   */
  function upgradeAggregator()
    external
    onlyOwner()
  {
    // Get configuration in memory
    AggregatorConfiguration memory current = s_currentAggregator;
    address previous = current.target;
    address proposed = s_proposedAggregator;

    // Perform the upgrade
    require(current.hasNewProposal, "No proposal");
    s_currentAggregator = AggregatorConfiguration({
      target: proposed,
      hasNewProposal: false
    });
    delete s_proposedAggregator;

    emit AggregatorUpgraded(previous, proposed);
  }

  /**
   * @notice Get aggregator details
   * @return current address
   * @return hasProposal bool
   * @return proposed address
   */
  function getAggregators()
    external
    view
    returns(
      address current,
      bool hasProposal,
      address proposed
    )
  {
    current = s_currentAggregator.target;
    hasProposal = s_currentAggregator.hasNewProposal;
    proposed = s_proposedAggregator;
  }

  /** VALIDATOR CONFIGURATION FUNCTIONS **/

  /**
   * @notice Propose an validator
   * @dev A zero address can be used to unset the proposed validator. Only owner can call.
   * @param proposed address
   */
  function proposeNewValidator(
    AggregatorValidatorInterface proposed
  )
    external
    onlyOwner()
  {
    require(s_proposedValidator != proposed && s_currentValidator.target != proposed, "Invalid proposal");
    s_proposedValidator = proposed;
    // If proposed is zero address, hasNewProposal = false
    s_currentValidator.hasNewProposal = (address(proposed) != address(0));
    emit ValidatorProposed(proposed);
  }

  /**
   * @notice Upgrade the validator by setting the current validator as the proposed validator.
   * @dev Must have a proposed validator. Only owner can call.
   */
  function upgradeValidator()
    external
    onlyOwner()
  {
    // Get configuration in memory
    ValidatorConfiguration memory current = s_currentValidator;
    AggregatorValidatorInterface previous = current.target;
    AggregatorValidatorInterface proposed = s_proposedValidator;

    // Perform the upgrade
    require(current.hasNewProposal, "No proposal");
    s_currentValidator = ValidatorConfiguration({
      target: proposed,
      hasNewProposal: false
    });
    delete s_proposedValidator;

    emit ValidatorUpgraded(previous, proposed);
  }

  /**
   * @notice Get validator details
   * @return current address
   * @return hasProposal bool
   * @return proposed address
   */
  function getValidators()
    external
    view
    returns(
      AggregatorValidatorInterface current,
      bool hasProposal,
      AggregatorValidatorInterface proposed
    )
  {
    current = s_currentValidator.target;
    hasProposal = s_currentValidator.hasNewProposal;
    proposed = s_proposedValidator;
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
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
    return "ValidatorProxy 1.0.0";
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.0;

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
pragma solidity ^0.8.6;

import "../SimpleReadAccessController.sol";
import "../interfaces/AccessControllerInterface.sol";
import "../interfaces/TypeAndVersionInterface.sol";

/* dev dependencies - to be re/moved after audit */
import "./interfaces/FlagsInterface.sol";

/**
 * @title The Flags contract
 * @notice Allows flags to signal to any reader on the access control list.
 * The owner can set flags, or designate other addresses to set flags. 
 * Raise flag actions are controlled by its own access controller.
 * Lower flag actions are controlled by its own access controller.
 * An expected pattern is to allow addresses to raise flags on themselves, so if you are subscribing to
 * FlagOn events you should filter for addresses you care about.
 */
contract Flags is TypeAndVersionInterface, FlagsInterface, SimpleReadAccessController {

  AccessControllerInterface public raisingAccessController;
  AccessControllerInterface public loweringAccessController;

  mapping(address => bool) private flags;

  event FlagRaised(
    address indexed subject
  );
  event FlagLowered(
    address indexed subject
  );
  event RaisingAccessControllerUpdated(
    address indexed previous,
    address indexed current
  );
  event LoweringAccessControllerUpdated(
    address indexed previous,
    address indexed current
  );

  /**
   * @param racAddress address for the raising access controller.
   * @param lacAddress address for the lowering access controller.
   */
  constructor(
    address racAddress,
    address lacAddress
  ) {
    setRaisingAccessController(racAddress);
    setLoweringAccessController(lacAddress);
  }

  /**
   * @notice versions:
   *
   * - Flags 1.1.0: upgraded to solc 0.8, added lowering access controller
   * - Flags 1.0.0: initial release
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
    return "Flags 1.1.0";
  }

  /**
   * @notice read the warning flag status of a contract address.
   * @param subject The contract address being checked for a flag.
   * @return A true value indicates that a flag was raised and a
   * false value indicates that no flag was raised.
   */
  function getFlag(
    address subject
  )
    external
    view
    override
    checkAccess()
    returns (bool)
  {
    return flags[subject];
  }

  /**
   * @notice read the warning flag status of a contract address.
   * @param subjects An array of addresses being checked for a flag.
   * @return An array of bools where a true value for any flag indicates that
   * a flag was raised and a false value indicates that no flag was raised.
   */
  function getFlags(
    address[] calldata subjects
  )
    external
    view
    override
    checkAccess()
    returns (bool[] memory)
  {
    bool[] memory responses = new bool[](subjects.length);
    for (uint256 i = 0; i < subjects.length; i++) {
      responses[i] = flags[subjects[i]];
    }
    return responses;
  }

  /**
   * @notice enable the warning flag for an address.
   * Access is controlled by raisingAccessController, except for owner
   * who always has access.
   * @param subject The contract address whose flag is being raised
   */
  function raiseFlag(
    address subject
  )
    external
    override
  {
    require(_allowedToRaiseFlags(), "Not allowed to raise flags");

    _tryToRaiseFlag(subject);
  }

  /**
   * @notice enable the warning flags for multiple addresses.
   * Access is controlled by raisingAccessController, except for owner
   * who always has access.
   * @param subjects List of the contract addresses whose flag is being raised
   */
  function raiseFlags(
    address[] calldata subjects
  )
    external
    override
  {
    require(_allowedToRaiseFlags(), "Not allowed to raise flags");

    for (uint256 i = 0; i < subjects.length; i++) {
      _tryToRaiseFlag(subjects[i]);
    }
  }

  /**
   * @notice allows owner to disable the warning flags for an addresses.
   * Access is controlled by loweringAccessController, except for owner
   * who always has access.
   * @param subject The contract address whose flag is being lowered
   */
  function lowerFlag(
    address subject
  )
    external
    override
  {
    require(_allowedToLowerFlags(), "Not allowed to lower flags");

    _tryToLowerFlag(subject);
  }

  /**
   * @notice allows owner to disable the warning flags for multiple addresses.
   * Access is controlled by loweringAccessController, except for owner
   * who always has access.
   * @param subjects List of the contract addresses whose flag is being lowered
   */
  function lowerFlags(
    address[] calldata subjects
  )
    external
    override
  {
    require(_allowedToLowerFlags(), "Not allowed to lower flags");

    for (uint256 i = 0; i < subjects.length; i++) {
      address subject = subjects[i];

      _tryToLowerFlag(subject);
    }
  }

  /**
   * @notice allows owner to change the access controller for raising flags.
   * @param racAddress new address for the raising access controller.
   */
  function setRaisingAccessController(
    address racAddress
  )
    public
    override
    onlyOwner()
  {
    address previous = address(raisingAccessController);

    if (previous != racAddress) {
      raisingAccessController = AccessControllerInterface(racAddress);

      emit RaisingAccessControllerUpdated(previous, racAddress);
    }
  }

  function setLoweringAccessController(
    address lacAddress
  )
    public
    override
    onlyOwner()
  {
    address previous = address(loweringAccessController);

    if (previous != lacAddress) {
      loweringAccessController = AccessControllerInterface(lacAddress);

      emit LoweringAccessControllerUpdated(previous, lacAddress);
    }
  }


  // PRIVATE
  function _allowedToRaiseFlags()
    private
    view
    returns (bool)
  {
    return msg.sender == owner() ||
      raisingAccessController.hasAccess(msg.sender, msg.data);
  }

  function _allowedToLowerFlags()
    private
    view
    returns (bool)
  {
    return msg.sender == owner() ||
      loweringAccessController.hasAccess(msg.sender, msg.data);
  }

  function _tryToRaiseFlag(
    address subject
  )
    private
  {
    if (!flags[subject]) {
      flags[subject] = true;
      emit FlagRaised(subject);
    }
  }

  function _tryToLowerFlag(
    address subject
  )
    private
  {
    if (flags[subject]) {
      flags[subject] = false;
      emit FlagLowered(subject);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleWriteAccessController.sol";

/**
 * @title SimpleReadAccessController
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability)
 * - accounts explicitly added to an access list
 * @dev SimpleReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * SimpleWriteAccessController for that.
 */
contract SimpleReadAccessController is SimpleWriteAccessController {

  /**
   * @notice Returns the access of an address
   * @param _user The address to query
   */
  function hasAccess(
    address _user,
    bytes memory _calldata
  )
    public
    view
    virtual
    override
    returns (bool)
  {
    return super.hasAccess(_user, _calldata) || _user == tx.origin;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwner.sol";
import "./interfaces/AccessControllerInterface.sol";

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
pragma solidity ^0.8.6;

import "../interfaces/AggregatorValidatorInterface.sol";
import "../interfaces/TypeAndVersionInterface.sol";
import "../interfaces/AccessControllerInterface.sol";
import "../SimpleWriteAccessController.sol";

/* dev dependencies - to be re/moved after audit */
import "./vendor/arb-bridge-eth/v0.8.0-custom/contracts/bridge/interfaces/IInbox.sol";
import "./interfaces/FlagsInterface.sol";

/**
 * @title ArbitrumValidator
 * @notice Allows to raise and lower Flags on the Arbitrum network through its Layer 1 contracts
 *  - The internal AccessController controls the access of the validate method
 *  - Gas configuration is controlled by a configurable external SimpleWriteAccessController
 *  - Funds on the contract are managed by the owner
 */
contract ArbitrumValidator is TypeAndVersionInterface, AggregatorValidatorInterface, SimpleWriteAccessController {
  // Config for L1 -> L2 `createRetryableTicket` call
  struct GasConfiguration {
    uint256 maxSubmissionCost;
    uint256 maxGasPrice;
    uint256 gasCostL2;
    uint256 gasLimitL2;
    address refundableAddress;
  }

  /// @dev Follows: https://eips.ethereum.org/EIPS/eip-1967
  address constant private FLAG_ARBITRUM_SEQ_OFFLINE = address(bytes20(bytes32(uint256(keccak256("chainlink.flags.arbitrum-seq-offline")) - 1)));
  bytes constant private CALL_RAISE_FLAG = abi.encodeWithSelector(FlagsInterface.raiseFlag.selector, FLAG_ARBITRUM_SEQ_OFFLINE);
  bytes constant private CALL_LOWER_FLAG = abi.encodeWithSelector(FlagsInterface.lowerFlag.selector, FLAG_ARBITRUM_SEQ_OFFLINE);

  address private s_l2FlagsAddress;
  IInbox private s_inbox;
  AccessControllerInterface private s_gasConfigAccessController;
  GasConfiguration private s_gasConfig;

  /**
   * @notice emitted when a new gas configuration is set
   * @param maxSubmissionCost maximum cost willing to pay on L2
   * @param maxGasPrice maximum gas price to pay on L2
   * @param gasCostL2 value to send to L2 to cover gas fee
   * @param refundableAddress address where gas excess on L2 will be sent
   */
  event GasConfigurationSet(
    uint256 maxSubmissionCost,
    uint256 maxGasPrice,
    uint256 gasCostL2,
    uint256 gasLimitL2,
    address indexed refundableAddress
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
   * @param inboxAddress address of the Arbitrum Inbox L1 contract
   * @param l2FlagsAddress address of the Chainlink L2 Flags contract
   * @param gasConfigAccessControllerAddress address of the access controller for managing gas price on Arbitrum
   * @param maxSubmissionCost maximum cost willing to pay on L2
   * @param maxGasPrice maximum gas price to pay on L2
   * @param gasCostL2 value to send to L2 to cover gas fee
   * @param gasLimitL2 gas limit for immediate L2 execution attempt. A value around 1M should be sufficient
   * @param refundableAddress address where gas excess on L2 will be sent
   */
  constructor(
    address inboxAddress,
    address l2FlagsAddress,
    address gasConfigAccessControllerAddress,
    uint256 maxSubmissionCost,
    uint256 maxGasPrice,
    uint256 gasCostL2,
    uint256 gasLimitL2,
    address refundableAddress
  ) {
    require(inboxAddress != address(0), "Invalid Inbox contract address");
    require(l2FlagsAddress != address(0), "Invalid Flags contract address");
    s_inbox = IInbox(inboxAddress);
    s_gasConfigAccessController = AccessControllerInterface(gasConfigAccessControllerAddress);
    s_l2FlagsAddress = l2FlagsAddress;
    _setGasConfiguration(maxSubmissionCost, maxGasPrice, gasCostL2, gasLimitL2, refundableAddress);
  }

  /**
   * @notice versions:
   *
   * - ArbitrumValidator 0.1.0: initial release
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
    return "ArbitrumValidator 0.1.0";
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

  /// @return Arbitrum Inbox contract address
  function inbox()
    external
    view
    virtual
    returns (address)
  {
    return address(s_inbox);
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
    returns (GasConfiguration memory)
  {
    return s_gasConfig;
  }

  /// @notice makes this contract payable as it need funds to pay for L2 transactions fees on L1.
  receive() external payable {}

  /**
   * @notice withdraws all funds availbale in this contract to the msg.sender
   * @dev only owner can call this
   */
  function withdrawFunds()
    external
    onlyOwner()
  {
    address payable to = payable(msg.sender);
    to.transfer(address(this).balance);
  }

  /**
   * @notice withdraws all funds availbale in this contract to the address specified
   * @dev only owner can call this
   * @param to address where to send the funds
   */
  function withdrawFundsTo(
    address payable to
  ) 
    external
    onlyOwner()
  {
    to.transfer(address(this).balance);
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
   * @notice sets Arbitrum gas configuration
   * @dev access control provided by s_gasConfigAccessController
   * @param maxSubmissionCost maximum cost willing to pay on L2
   * @param maxGasPrice maximum gas price to pay on L2
   * @param gasCostL2 value to send to L2 to cover gas fee
   * @param gasLimitL2 gas limit for immediate L2 execution attempt. A value around 1M should be sufficient
   * @param refundableAddress address where gas excess on L2 will be sent
   */
  function setGasConfiguration(
    uint256 maxSubmissionCost,
    uint256 maxGasPrice,
    uint256 gasCostL2,
    uint256 gasLimitL2,
    address refundableAddress
  )
    external
  {
    require(s_gasConfigAccessController.hasAccess(msg.sender, msg.data), "Access required to set config");
    _setGasConfiguration(maxSubmissionCost, maxGasPrice, gasCostL2, gasLimitL2, refundableAddress);
  }

  /**
   * @notice validate method updates the state of an L2 Flag in case of change on the Arbitrum Sequencer.
   * A one answer considers the service as offline.
   * In case the previous answer is the same as the current it does not trigger any tx on L2. In other case,
   * a retryable ticket is created on the Arbitrum L1 Inbox contract. The tx gas fee can be paid from this
   * contract providing a value, or the same address on L2.
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
    checkAccess()
    returns (bool)
  {
    // Avoids resending to L2 the same tx on every call
    if (previousAnswer == currentAnswer) {
      return true;
    }

    int isServiceOffline = 1;
    // NOTICE: if gasCostL2 is zero the payment is processed on L2 so the L2 address needs to be funded, as it will
    // paying the fee. We also ignore the returned msg number, that can be queried via the InboxMessageDelivered event.
    s_inbox.createRetryableTicket{value: s_gasConfig.gasCostL2}(
      s_l2FlagsAddress,
      0, // L2 call value
      // NOTICE: maxSubmissionCost info will possibly become available on L1 after the London fork. At that time this
      // contract could start querying/calculating it directly so we wouldn't need to configure it statically. On L2 this
      // info is available via `ArbRetryableTx.getSubmissionPrice`.
      s_gasConfig.maxSubmissionCost, // Max submission cost of sending data length
      s_gasConfig.refundableAddress, // excessFeeRefundAddress
      s_gasConfig.refundableAddress, // callValueRefundAddress
      s_gasConfig.gasLimitL2,
      s_gasConfig.maxGasPrice,
      currentAnswer == isServiceOffline ? CALL_RAISE_FLAG : CALL_LOWER_FLAG
    );
    return true;
  }

  function _setGasConfiguration(
    uint256 maxSubmissionCost,
    uint256 maxGasPrice,
    uint256 gasCostL2,
    uint256 gasLimitL2,
    address refundableAddress
  )
    internal
  {
    // L2 will pay the fee if gasCostL2 is zero
    if (gasCostL2 > 0) {
      uint256 minGasCostValue = maxSubmissionCost + gasLimitL2 * maxGasPrice;
      require(gasCostL2 >= minGasCostValue, "Gas cost provided is too low");
    }
    s_gasConfig = GasConfiguration(maxSubmissionCost, maxGasPrice, gasCostL2, gasLimitL2, refundableAddress);
    emit GasConfigurationSet(maxSubmissionCost, maxGasPrice, gasCostL2, gasLimitL2, refundableAddress);
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

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// NOTICE: pragma different from original (updated from `^0.6.11` -> `^0.8.6`)
pragma solidity ^0.8.6;

import "./IBridge.sol";
import "./IMessageProvider.sol";

interface IInbox is IMessageProvider {
    function sendL2Message(bytes calldata messageData) external returns (uint256);

    function sendUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (uint256);

    function sendL1FundedUnsignedTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        uint256 nonce,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function sendL1FundedContractTransaction(
        uint256 maxGas,
        uint256 gasPriceBid,
        address destAddr,
        bytes calldata data
    ) external payable returns (uint256);

    function createRetryableTicket(
        address destAddr,
        uint256 arbTxCallValue,
        uint256 maxSubmissionCost,
        address submissionRefundAddress,
        address valueRefundAddress,
        uint256 maxGas,
        uint256 gasPriceBid,
        bytes calldata data
    ) external payable returns (uint256);

    function depositEth(address destAddr) external payable returns (uint256);

    function depositEthRetryable(address destAddr, uint256 maxSubmissionCost, uint256 maxGas, uint256 maxGasPrice) external payable returns (uint256);

    function bridge() external view returns (IBridge);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// NOTICE: pragma different from original (updated from `^0.6.11` -> `^0.8.6`)
pragma solidity ^0.8.6;

interface IBridge {
    event MessageDelivered(
        uint256 indexed messageIndex,
        bytes32 indexed beforeInboxAcc,
        address inbox,
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    );

    function deliverMessageToInbox(
        uint8 kind,
        address sender,
        bytes32 messageDataHash
    ) external payable returns (uint256);

    function executeCall(
        address destAddr,
        uint256 amount,
        bytes calldata data
    ) external returns (bool success, bytes memory returnData);

    // These are only callable by the admin
    function setInbox(address inbox, bool enabled) external;

    function setOutbox(address inbox, bool enabled) external;

    // View functions

    function activeOutbox() external view returns (address);

    function allowedInboxes(address inbox) external view returns (bool);

    function allowedOutboxes(address outbox) external view returns (bool);

    function inboxAccs(uint256 index) external view returns (bytes32);

    function messageCount() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

/*
 * Copyright 2021, Offchain Labs, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// NOTICE: pragma different from original (updated from `^0.6.11` -> `^0.8.6`)
pragma solidity ^0.8.6;

interface IMessageProvider {
    event InboxMessageDelivered(uint256 indexed messageNum, bytes data);

    event InboxMessageDeliveredFromOrigin(uint256 indexed messageNum);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./SimpleReadAccessController.sol";
import "./interfaces/AccessControllerInterface.sol";
import "./interfaces/FlagsInterface.sol";


/**
 * @title The Flags contract
 * @notice Allows flags to signal to any reader on the access control list.
 * The owner can set flags, or designate other addresses to set flags. The
 * owner must turn the flags off, other setters cannot. An expected pattern is
 * to allow addresses to raise flags on themselves, so if you are subscribing to
 * FlagOn events you should filter for addresses you care about.
 */
contract Flags is FlagsInterface, SimpleReadAccessController {

  AccessControllerInterface public raisingAccessController;

  mapping(address => bool) private flags;

  event FlagRaised(
    address indexed subject
  );
  event FlagLowered(
    address indexed subject
  );
  event RaisingAccessControllerUpdated(
    address indexed previous,
    address indexed current
  );

  /**
   * @param racAddress address for the raising access controller.
   */
  constructor(
    address racAddress
  ) {
    setRaisingAccessController(racAddress);
  }

  /**
   * @notice read the warning flag status of a contract address.
   * @param subject The contract address being checked for a flag.
   * @return A true value indicates that a flag was raised and a
   * false value indicates that no flag was raised.
   */
  function getFlag(address subject)
    external
    view
    override
    checkAccess()
    returns (bool)
  {
    return flags[subject];
  }

  /**
   * @notice read the warning flag status of a contract address.
   * @param subjects An array of addresses being checked for a flag.
   * @return An array of bools where a true value for any flag indicates that
   * a flag was raised and a false value indicates that no flag was raised.
   */
  function getFlags(address[] calldata subjects)
    external
    view
    override
    checkAccess()
    returns (bool[] memory)
  {
    bool[] memory responses = new bool[](subjects.length);
    for (uint256 i = 0; i < subjects.length; i++) {
      responses[i] = flags[subjects[i]];
    }
    return responses;
  }

  /**
   * @notice enable the warning flag for an address.
   * Access is controlled by raisingAccessController, except for owner
   * who always has access.
   * @param subject The contract address whose flag is being raised
   */
  function raiseFlag(address subject)
    external
    override
  {
    require(allowedToRaiseFlags(), "Not allowed to raise flags");

    tryToRaiseFlag(subject);
  }

  /**
   * @notice enable the warning flags for multiple addresses.
   * Access is controlled by raisingAccessController, except for owner
   * who always has access.
   * @param subjects List of the contract addresses whose flag is being raised
   */
  function raiseFlags(address[] calldata subjects)
    external
    override
  {
    require(allowedToRaiseFlags(), "Not allowed to raise flags");

    for (uint256 i = 0; i < subjects.length; i++) {
      tryToRaiseFlag(subjects[i]);
    }
  }

  /**
   * @notice allows owner to disable the warning flags for multiple addresses.
   * @param subjects List of the contract addresses whose flag is being lowered
   */
  function lowerFlags(address[] calldata subjects)
    external
    override
    onlyOwner()
  {
    for (uint256 i = 0; i < subjects.length; i++) {
      address subject = subjects[i];

      if (flags[subject]) {
        flags[subject] = false;
        emit FlagLowered(subject);
      }
    }
  }

  /**
   * @notice allows owner to change the access controller for raising flags.
   * @param racAddress new address for the raising access controller.
   */
  function setRaisingAccessController(
    address racAddress
  )
    public
    override
    onlyOwner()
  {
    address previous = address(raisingAccessController);

    if (previous != racAddress) {
      raisingAccessController = AccessControllerInterface(racAddress);

      emit RaisingAccessControllerUpdated(previous, racAddress);
    }
  }


  // PRIVATE

  function allowedToRaiseFlags()
    private
    view
    returns (bool)
  {
    return msg.sender == owner() ||
      raisingAccessController.hasAccess(msg.sender, msg.data);
  }

  function tryToRaiseFlag(address subject)
    private
  {
    if (!flags[subject]) {
      flags[subject] = true;
      emit FlagRaised(subject);
    }
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface FlagsInterface {
  function getFlag(address) external view returns (bool);
  function getFlags(address[] calldata) external view returns (bool[] memory);
  function raiseFlag(address) external;
  function raiseFlags(address[] calldata) external;
  function lowerFlags(address[] calldata) external;
  function setRaisingAccessController(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Flags.sol";

contract FlagsTestHelper {
  Flags public flags;

  constructor(
    address flagsContract
  ) {
    flags = Flags(flagsContract);
  }

  function getFlag(
    address subject
  )
    external
    view
    returns(bool)
  {
    return flags.getFlag(subject);
  }

  function getFlags(
    address[] calldata subjects
  )
    external
    view
    returns(bool[] memory)
  {
    return flags.getFlags(subjects);
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/AggregatorValidatorInterface.sol";

contract MockAggregatorValidator is AggregatorValidatorInterface {
  
  uint8 immutable id;

  constructor(uint8 id_) {
    id = id_;
  }

  event ValidateCalled(
    uint8 id,
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  );
  
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  )
    external
    override
    returns (
      bool
    )
  {
    emit ValidateCalled(id, previousRoundId, previousAnswer, currentRoundId, currentAnswer);
    return true;
  }

}

