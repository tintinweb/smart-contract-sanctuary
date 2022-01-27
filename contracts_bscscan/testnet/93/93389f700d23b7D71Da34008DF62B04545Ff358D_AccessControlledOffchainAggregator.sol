// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./OffchainAggregator2.sol";
import "./SimpleReadAccessController.sol";

/**
 * @notice Wrapper of OffchainAggregator which checks read access on Aggregator-interface methods
 */
contract AccessControlledOffchainAggregator is OffchainAggregator, SimpleReadAccessController {

  constructor(
  )
  {
  }

  /*
   * Versioning
   */

  function typeAndVersion()
    external
    override
    pure
    virtual
    returns (string memory)
  {
    return "AccessControlledOffchainAggregator 3.0.0";
  }


  /*
   * v2 Aggregator interface
   */

  /// @inheritdoc OffchainAggregator
  function latestAnswer()
    public
    override
    view
    checkAccess()
    returns (int256)
  {
    return super.latestAnswer();
  }

  /// @inheritdoc OffchainAggregator
  function latestTimestamp()
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.latestTimestamp();
  }

  /// @inheritdoc OffchainAggregator
  function latestRound()
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.latestRound();
  }

  /// @inheritdoc OffchainAggregator
  function getAnswer(uint256 _roundId)
    public
    override
    view
    checkAccess()
    returns (int256)
  {
    return super.getAnswer(_roundId);
  }

  /// @inheritdoc OffchainAggregator
  function getTimestamp(uint256 _roundId)
    public
    override
    view
    checkAccess()
    returns (uint256)
  {
    return super.getTimestamp(_roundId);
  }

  /*
   * v3 Aggregator interface
   */

  /// @inheritdoc OffchainAggregator
  function description()
    public
    override
    view
    checkAccess()
    returns (string memory)
  {
    return super.description();
  }

  /// @inheritdoc OffchainAggregator
  function getRoundData(uint80 _roundId)
    public
    override
    view
    checkAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.getRoundData(_roundId);
  }

  /// @inheritdoc OffchainAggregator
  function latestRoundData()
    public
    override
    view
    checkAccess()
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    return super.latestRoundData();
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

abstract contract TypeAndVersionInterface{
  function typeAndVersion()
    external
    pure
    virtual
    returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorValidatorInterface {
  function validate(
    uint256 previousRoundId,
    int256 previousAnswer,
    uint256 currentRoundId,
    int256 currentAnswer
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);
  function latestTimestamp() external view returns (uint256);
  function latestRound() external view returns (uint256);
  function getAnswer(uint256 roundId) external view returns (int256);
  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface AccessControllerInterface {
  function hasAccess(address user, bytes calldata data) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./Owned.sol";
import "./interfaces/AccessControllerInterface.sol";

/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner. 控制器所有者授予添加到访问列表中的账户的访问权限
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that. 不必对外部访问控制做什么特殊权限，控制不了
 */
contract SimpleWriteAccessController is AccessControllerInterface, Owned {

  bool public checkEnabled;
  mapping(address => bool) internal accessList;

  event AddedAccess(address user);
  event RemovedAccess(address user);
  event CheckAccessEnabled();
  event CheckAccessDisabled();

  constructor()
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
  function addAccess(address _user) external onlyOwner() {
    addAccessInternal(_user);
  }

  function addAccessInternal(address _user) internal {
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
   * @notice makes the access check enforced 执行访问权限检查
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
   * @notice makes the access check unenforced 不执行访问权限检查
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
   * @dev reverts if the caller does not have access 是否有权限的修饰器
   */
  modifier checkAccess() {
    require(hasAccess(msg.sender, msg.data), "No access");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import "./SimpleWriteAccessController.sol";

/**
 * @title SimpleReadAccessController 读取访问控制器 这个合约是代理合约的访问设置
 * @notice Gives access to:
 * - any externally owned account (note that offchain actors can always read
 * any contract storage regardless of onchain access control measures, so this
 * does not weaken the access control while improving usability) 链下参与者可访问到合约状态
 * - accounts explicitly added to an access list 明确添加到访问列表的账户
 * @dev SimpleReadAccessController is not suitable for access controlling writes
 * since it grants any externally owned account access! See
 * SimpleWriteAccessController for that.
 SimpleReadAccessController 不适合访问控制写入，因为它授予任何外部拥有的帐户访问权限！请参阅 SimpleWriteAccessController 。
 */
contract SimpleReadAccessController is SimpleWriteAccessController {

  /**
   * @notice Returns the access of an address 返回某个地址的访问权限
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
pragma solidity ^0.7.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address payable public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./interfaces/AccessControllerInterface.sol";
import "./interfaces/AggregatorV2V3Interface.sol";
import "./interfaces/AggregatorValidatorInterface.sol";
import "./interfaces/LinkTokenInterface.sol";
import "./Owned.sol";
import "./interfaces/TypeAndVersionInterface.sol";

/**
  * @notice Onchain verification of reports from the offchain reporting protocol 链下报告链上验证

  * @dev For details on its operation, see the offchain reporting protocol design 具体信息可参考链下报告设计文档
  * @dev doc, which refers to this contract as simply the "contract".
*/
contract OffchainAggregator is Owned, AggregatorV2V3Interface, TypeAndVersionInterface {

  // Storing these fields used on the hot path in a HotVars variable reduces the
  // retrieval of all of them to a single SLOAD. If any further fields are
  // added, make sure that storage of the struct still takes at most 32 bytes.
  struct HotVars {
    // Provides 128 bits of security against 2nd pre-image attacks, but only
    // 64 bits against collisions. This is acceptable, since a malicious owner has
    // easier way of messing up the protocol than to find hash collisions.
    // mhxw bytes16 latestConfigDigest;
    uint8 latestConfigDigest;
    uint40 latestEpochAndRound; // 32 most sig bits for epoch, 8 least sig bits for round
    // Current bound assumed on number of faulty/dishonest oracles participating
    // in the protocol, this value is referred to as f in the design
    uint8 threshold;
    // Chainlink Aggregators expose a roundId to consumers. The offchain reporting
    // protocol does not use this id anywhere. We increment it whenever a new
    // transmission is made to provide callers with contiguous ids for successive
    // reports.
    uint32 latestAggregatorRoundId;
  }
  HotVars internal s_hotVars;

  // Transmission records the median answer from the transmit transaction at 发送中位数结果
  // time timestamp
  struct Transmission {
    int192 answer; // 192 bits ought to be enough for anyone
    uint64 timestamp;
  }
  mapping(uint32 /* aggregator round ID */ => Transmission) internal s_transmissions;

  /*
 * Versioning
 */
  function typeAndVersion()
  external
  override
  pure
  virtual
  returns (string memory)
  {
    return "OffchainAggregator 3.0.0";
  }

  /*
   * Transmission logic
   */

  /**
   * @notice indicates that a new report was transmitted
   * @param aggregatorRoundId the round to which this report was assigned
   * @param answer median of the observations attached this report
   * @param transmitter address from which the report was transmitted
   * @param observations observations transmitted with this report
   * @param rawReportContext signature-replay-prevention domain-separation tag
   */
  event NewTransmission(
    uint32 indexed aggregatorRoundId,
    int192 answer,
    address transmitter,
    int192[] observations,
    bytes observers,
    bytes32 rawReportContext
  );

  function transmit(
    int192 median
  )
  external
  {
    HotVars memory r_hotVars = s_hotVars; // cache read from storage
    r_hotVars.latestAggregatorRoundId++;
    s_transmissions[r_hotVars.latestAggregatorRoundId] =
    Transmission(median, uint64(block.timestamp));

    int192[] memory observations;
    bytes memory observers;
    bytes32 rawReportContext;

    emit NewTransmission(
      r_hotVars.latestAggregatorRoundId,
      median,
      msg.sender,
      observations,
      observers,
      rawReportContext
    );
    // Emit these for backwards compatability with offchain consumers
    // that only support legacy events
    emit NewRound(
      r_hotVars.latestAggregatorRoundId,
      address(0x0), // use zero address since we don't have anybody "starting" the round here
      block.timestamp
    );
    emit AnswerUpdated(
      median,
      r_hotVars.latestAggregatorRoundId,
      block.timestamp
    );
    s_hotVars = r_hotVars;
  }

  /*
   * v2 Aggregator interface
   */

  /**
   * @notice median from the most recent report
   */
  function latestAnswer()
  public
  override
  view
  virtual
  returns (int256)
  {
    return s_transmissions[s_hotVars.latestAggregatorRoundId].answer;
  }

  /**
   * @notice timestamp of block in which last report was transmitted
   */
  function latestTimestamp()
  public
  override
  view
  virtual
  returns (uint256)
  {
    return s_transmissions[s_hotVars.latestAggregatorRoundId].timestamp;
  }

  /**
   * @notice Aggregator round (NOT OCR round) in which last report was transmitted 发送的最后轮次 不是ocr轮次
   */
  function latestRound()
  public
  override
  view
  virtual
  returns (uint256)
  {
    return s_hotVars.latestAggregatorRoundId;
  }

  /**
   * @notice median of report from given aggregator round (NOT OCR round)
   * @param _roundId the aggregator round of the target report
   */
  function getAnswer(uint256 _roundId)
  public
  override
  view
  virtual
  returns (int256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].answer;
  }

  /**
   * @notice timestamp of block in which report from given aggregator round was transmitted
   * @param _roundId aggregator round (NOT OCR round) of target report
   */
  function getTimestamp(uint256 _roundId)
  public
  override
  view
  virtual
  returns (uint256)
  {
    if (_roundId > 0xFFFFFFFF) { return 0; }
    return s_transmissions[uint32(_roundId)].timestamp;
  }

  /*
   * v3 Aggregator interface
   */

  string constant private V3_NO_DATA_ERROR = "No data present";

  /**
   * @return answers are stored in fixed-point format, with this many digits of precision
   */
  uint8 immutable public override decimals = 8;

  /**
   * @notice aggregator contract version
   */
  uint256 constant public override version = 4;

  string internal s_description;

  /**
   * @notice human-readable description of observable this contract is reporting on
   */
  function description()
  public
  override
  view
  virtual
  returns (string memory)
  {
    return s_description;
  }

  /**
   * @notice details for the given aggregator round
   * @param _roundId target aggregator round (NOT OCR round). Must fit in uint32
   * @return roundId _roundId
   * @return answer median of report from given _roundId
   * @return startedAt timestamp of block in which report from given _roundId was transmitted
   * @return updatedAt timestamp of block in which report from given _roundId was transmitted
   * @return answeredInRound _roundId
   */
  function getRoundData(uint80 _roundId)
  public
  override
  view
  virtual
  returns (
    uint80 roundId,
    int256 answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80 answeredInRound
  )
  {
    require(_roundId <= 0xFFFFFFFF, V3_NO_DATA_ERROR);
    Transmission memory transmission = s_transmissions[uint32(_roundId)];
    return (
    _roundId,
    transmission.answer,
    transmission.timestamp,
    transmission.timestamp,
    _roundId
    );
  }

  /**
   * @notice aggregator details for the most recently transmitted report
   * @return roundId aggregator round of latest report (NOT OCR round)
   * @return answer median of latest report
   * @return startedAt timestamp of block containing latest report
   * @return updatedAt timestamp of block containing latest report
   * @return answeredInRound aggregator round of latest report
   */
  function latestRoundData()
    public
    override
    view
    virtual
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    )
  {
    roundId = s_hotVars.latestAggregatorRoundId;

    // Skipped for compatability with existing FluxAggregator in which latestRoundData never reverts.
    // require(roundId != 0, V3_NO_DATA_ERROR);

    Transmission memory transmission = s_transmissions[uint32(roundId)];
    return (
      roundId,
      transmission.answer,
      transmission.timestamp,
      transmission.timestamp,
      roundId
    );
  }
}