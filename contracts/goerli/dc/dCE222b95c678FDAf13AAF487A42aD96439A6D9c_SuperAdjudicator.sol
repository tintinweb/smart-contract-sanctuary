// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {IArbitrator} from '@kleros/erc-792/contracts/IArbitrator.sol';

uint256 constant STARKNET_PRIME = 2**251 + 17 * 2**192 + 1;

// XXX: this selector computation probably isn't correct; verify it!
uint256 constant MASK_250 = 2**250 - 1;
uint256 constant ZORRO_SUPER_ADJUDICATE_SELECTOR = uint256(
  keccak256('super_adjudicate') & bytes32(MASK_250)
);
uint256 constant ZORRO_APPEAL_SELECTOR = uint256(
  keccak256('appeal') & bytes32(MASK_250)
);

interface IStarknetCore {
  // Sends a message to an L2 contract. Returns the hash of the message.
  function sendMessageToL2(
    uint256 to_address,
    uint256 selector,
    uint256[] calldata payload
  ) external returns (bytes32);
}

// Interface for https://github.com/kleros/arbitrable-proxy-contracts/blob/master/contracts/ArbitrableProxy.sol
interface IArbitrableProxy {
  function arbitrator() external returns (IArbitrator);

  function createDispute(
    bytes calldata _arbitratorExtraData,
    string calldata _metaevidenceURI,
    uint256 _numberOfRulingOptions
  ) external payable returns (uint256 disputeID);
}

contract SuperAdjudicator {
  struct ArbitratorConfiguration {
    bytes arbitratorExtraData;
    string metaevidenceURI;
    uint256 numberOfRulingOptions;
  }

  event ArbitratorConfigurationChanged(
    bytes arbitratorExtraData,
    string metaevidenceURI,
    uint256 numberOfRulingOptions
  );

  event Appealed(uint256 indexed profileId, uint256 indexed disputeId);

  event RulingEnacted(
    uint256 indexed profileId,
    uint256 indexed disputeId,
    uint256 ruling
  );

  // Set once during construction
  IStarknetCore public immutable starknetCore;
  IArbitrableProxy public immutable arbitrableProxy;
  uint256 public immutable zorroL2Address;

  address public owner; // Owner can modify arbitrator configuration
  ArbitratorConfiguration public arbitratorConfiguration;
  mapping(uint256 => uint256) public disputeIdToProfileId;

  constructor(
    IStarknetCore _starknetCore,
    IArbitrableProxy _arbitrableProxy,
    uint256 _zorroL2Address,
    address _owner,
    bytes memory _arbitratorExtraData,
    string memory _metaevidenceURI,
    uint256 _numberOfRulingOptions
  ) {
    starknetCore = _starknetCore;
    arbitrableProxy = _arbitrableProxy;
    zorroL2Address = _zorroL2Address;
    owner = _owner;
    _setPolicy(_arbitratorExtraData, _metaevidenceURI, _numberOfRulingOptions);
  }

  function setOwner(address newOwner) external {
    require(msg.sender == owner, 'caller is not the owner');
    owner = newOwner;
  }

  function setPolicy(
    bytes calldata arbitratorExtraData,
    string calldata metaevidenceURI,
    uint256 numberOfRulingOptions
  ) external {
    require(msg.sender == owner, 'caller is not the owner');
    _setPolicy(arbitratorExtraData, metaevidenceURI, numberOfRulingOptions);
  }

  function _setPolicy(
    bytes memory arbitratorExtraData,
    string memory metaevidenceURI,
    uint256 numberOfRulingOptions
  ) internal {
    arbitratorConfiguration.arbitratorExtraData = arbitratorExtraData;
    arbitratorConfiguration.metaevidenceURI = metaevidenceURI;
    arbitratorConfiguration.numberOfRulingOptions = numberOfRulingOptions;
    emit ArbitratorConfigurationChanged(
      arbitratorExtraData,
      metaevidenceURI,
      numberOfRulingOptions
    );
  }

  function appeal(uint256 profileId)
    external
    payable
    returns (uint256 disputeId)
  {
    // Require that `profileId` does not overflow a starknet field element
    // otherwise could create two disputes simultaneously for the same
    // `profileId` by calling `appeal(x)` and `appeal(x + STARKNET_PRIME)`
    require(profileId < STARKNET_PRIME, 'profileId overflow');

    disputeId = arbitrableProxy.createDispute{value: msg.value}(
      arbitratorConfiguration.arbitratorExtraData,
      arbitratorConfiguration.metaevidenceURI,
      arbitratorConfiguration.numberOfRulingOptions
    );

    disputeIdToProfileId[disputeId] = profileId;

    uint256[] memory payload = new uint256[](2);
    payload[0] = profileId;
    payload[1] = disputeId;

    starknetCore.sendMessageToL2(
      zorroL2Address,
      ZORRO_APPEAL_SELECTOR,
      payload
    );

    emit Appealed(profileId, disputeId);
    return disputeId;
  }

  function enactRuling(uint256 disputeId) external {
    uint256 profileId = disputeIdToProfileId[disputeId];
    require(profileId != 0, "dispute doesn't exist");
    IArbitrator arbitrator = arbitrableProxy.arbitrator();
    IArbitrator.DisputeStatus status = arbitrator.disputeStatus(disputeId);
    require(
      status == IArbitrator.DisputeStatus.Solved,
      'still waiting for final ruling'
    );

    uint256 ruling = arbitrator.currentRuling(disputeId);
    uint256[] memory payload = new uint256[](2);
    payload[0] = profileId;
    payload[1] = disputeId;
    payload[2] = ruling; // XXX: this ruling will be 0 if adjudicator was wrong, 1 if adjudicator is right, which is not what the Zorro starknet contract expects right now.

    starknetCore.sendMessageToL2(
      zorroL2Address,
      ZORRO_SUPER_ADJUDICATE_SELECTOR,
      payload
    );

    // prevent this same ruling from ever being enacted again. matters because
    // a profile could be re-challenged, re-adjudicated, and re-appealed —
    // we wouldn't want someone to be able to enact the old ruling against it.
    disputeIdToProfileId[profileId] = 0;

    emit RulingEnacted(profileId, disputeId, ruling);
  }
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */

pragma solidity ^0.8.0;

import "./IArbitrable.sol";

/**
 * @title Arbitrator
 * Arbitrator abstract contract.
 * When developing arbitrator contracts we need to:
 * - Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
 * - Define the functions for cost display (arbitrationCost and appealCost).
 * - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
interface IArbitrator {
    enum DisputeStatus {
        Waiting,
        Appealable,
        Solved
    }

    /**
     * @dev To be emitted when a dispute is created.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when a dispute can be appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev To be emitted when the current ruling is appealed.
     * @param _disputeID ID of the dispute.
     * @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, IArbitrable indexed _arbitrable);

    /**
     * @dev Create a dispute. Must be called by the arbitrable contract.
     * Must be paid at least arbitrationCost(_extraData).
     * @param _choices Amount of choices the arbitrator can make in this dispute.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);

    /**
     * @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function arbitrationCost(bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes calldata _extraData) external payable;

    /**
     * @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     * @param _disputeID ID of the dispute to be appealed.
     * @param _extraData Can be used to give additional info on the dispute to be created.
     * @return cost Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes calldata _extraData) external view returns (uint256 cost);

    /**
     * @dev Compute the start and end of the dispute's current or next appeal period, if possible. If not known or appeal is impossible: should return (0, 0).
     * @param _disputeID ID of the dispute.
     * @return start The start of the period.
     * @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) external view returns (uint256 start, uint256 end);

    /**
     * @dev Return the status of a dispute.
     * @param _disputeID ID of the dispute to rule.
     * @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) external view returns (DisputeStatus status);

    /**
     * @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     * @param _disputeID ID of the dispute.
     * @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) external view returns (uint256 ruling);
}

/**
 * @authors: [@ferittuncer, @hbarcelos]
 * @reviewers: [@remedcu]
 * @auditors: []
 * @bounties: []
 * @deployments: []
 * SPDX-License-Identifier: MIT
 */
pragma solidity ^0.8.0;

import "./IArbitrator.sol";

/**
 * @title IArbitrable
 * Arbitrable interface.
 * When developing arbitrable contracts, we need to:
 * - Define the action taken when a ruling is received by the contract.
 * - Allow dispute creation. For this a function must call arbitrator.createDispute{value: _fee}(_choices,_extraData);
 */
interface IArbitrable {
    /**
     * @dev To be raised when a ruling is given.
     * @param _arbitrator The arbitrator giving the ruling.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling The ruling which was given.
     */
    event Ruling(IArbitrator indexed _arbitrator, uint256 indexed _disputeID, uint256 _ruling);

    /**
     * @dev Give a ruling for a dispute. Must be called by the arbitrator.
     * The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     * @param _disputeID ID of the dispute in the Arbitrator contract.
     * @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint256 _disputeID, uint256 _ruling) external;
}