/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// File: contracts/AccessControllerInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface AccessControllerInterface {
    function hasAccess(address user, bytes calldata data)
        external
        view
        returns (bool);
}

contract AccessController is AccessControllerInterface {
    function hasAccess(address user, bytes calldata data)
        external
        view
        override
        returns (bool)
    {
        return true;
    }
}

// File: contracts/AggregatorInterface.sol

pragma solidity ^0.7.1;

interface AggregatorInterface {
    function latestAnswer()
        external
        view
        returns (
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory
        );

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId)
        external
        view
        returns (
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory
        );

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(
        bytes32 indexed current,
        uint256 indexed roundId,
        uint256 updatedAt
    );
    event NewRound(
        uint256 indexed roundId,
        address indexed startedBy,
        uint256 startedAt
    );

    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            bytes32 answer,
            uint8 validBytes,
            bytes32 multipleObservationsIndex,
            bytes32 multipleObservationsValidBytes,
            bytes32[] memory multipleObservations,
            uint256 updatedAt
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            bytes32 answer,
            uint8 validBytes,
            bytes32 multipleObservationsIndex,
            bytes32 multipleObservationsValidBytes,
            bytes32[] memory multipleObservations,
            uint256 updatedAt
        );

    function getStringAnswerByIndex(uint256 _roundId, uint8 _index)
        external
        view
        returns (string memory);

    function getStringAnswer(uint256 _roundId)
        external
        view
        returns (uint8[] memory _index, string memory _answerSet);

    function getLatestStringAnswerByIndex(uint8 _index)
        external
        view
        returns (string memory);

    function getLatestStringAnswer()
        external
        view
        returns (uint8[] memory _index, string memory _answerSet);
}

// File: contracts/PortTokenInterface.sol

pragma solidity ^0.7.1;

interface PortTokenInterface {
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
  function deposit(address user, uint256 amount) external; 
}

// File: contracts/Owned.sol

pragma solidity ^0.7.1;

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

// File: contracts/OffchainAggregatorBilling.sol

pragma solidity ^0.7.1;




contract OffchainAggregatorBilling is Owned {
  uint256 constant internal maxNumOracles = 31;

  struct Billing {
    uint32 maximumGasPrice;
    uint32 reasonableGasPrice;
    uint32 microPortPerEth;
    uint32 portGweiPerObservation;
    uint32 portGweiPerTransmission;
  }
  Billing internal s_billing;
  PortTokenInterface immutable public PORT;
  AccessControllerInterface internal s_billingAccessController;
  uint16[maxNumOracles] internal s_oracleObservationsCounts;
  mapping (address => address)
    internal
    s_payees;

  mapping (address => address)
    internal
    s_proposedPayees;
  
  uint256[maxNumOracles] internal s_gasReimbursementsPortWei;
  enum Role {
    Unset,
    Signer,
    Transmitter
  }

  struct Oracle {
    uint8 index;
    Role role;
  }

  mapping (address => Oracle)
    internal s_oracles;

  address[] internal s_signers;
  address[] internal s_transmitters;

  uint256 constant private  maxUint16 = (1 << 16) - 1;
  uint256 constant internal maxUint128 = (1 << 128) - 1;

  constructor(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microPortPerEth,
    uint32 _portGweiPerObservation,
    uint32 _portGweiPerTransmission,
    address _port,
    AccessControllerInterface _billingAccessController
  )
  {
    setBillingInternal(_maximumGasPrice, _reasonableGasPrice, _microPortPerEth,
      _portGweiPerObservation, _portGweiPerTransmission);
    setBillingAccessControllerInternal(_billingAccessController);
    PORT = PortTokenInterface(_port);
    uint16[maxNumOracles] memory counts;
    uint256[maxNumOracles] memory gas;
    for (uint8 i = 0; i < maxNumOracles; i++) {
      counts[i] = 1;
      gas[i] = 1;
    }
    s_oracleObservationsCounts = counts;
    s_gasReimbursementsPortWei = gas;

  }

  event BillingSet(
    uint32 maximumGasPrice,
    uint32 reasonableGasPrice,
    uint32 microPortPerEth,
    uint32 portGweiPerObservation,
    uint32 portGweiPerTransmission
  );

  function setBillingInternal(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microPortPerEth,
    uint32 _portGweiPerObservation,
    uint32 _portGweiPerTransmission
  )
    internal
  {
    s_billing = Billing(_maximumGasPrice, _reasonableGasPrice, _microPortPerEth,
      _portGweiPerObservation, _portGweiPerTransmission);
    emit BillingSet(_maximumGasPrice, _reasonableGasPrice, _microPortPerEth,
      _portGweiPerObservation, _portGweiPerTransmission);
  }

  function setBilling(
    uint32 _maximumGasPrice,
    uint32 _reasonableGasPrice,
    uint32 _microPortPerEth,
    uint32 _portGweiPerObservation,
    uint32 _portGweiPerTransmission
  )
    external
  {
    AccessControllerInterface access = s_billingAccessController;
    require(msg.sender == owner || access.hasAccess(msg.sender, msg.data),
      "Only owner&billingAdmin can call");
    payOracles();
    setBillingInternal(_maximumGasPrice, _reasonableGasPrice, _microPortPerEth,
      _portGweiPerObservation, _portGweiPerTransmission);
  }

  function getBilling()
    external
    view
    returns (
      uint32 maximumGasPrice,
      uint32 reasonableGasPrice,
      uint32 microPortPerEth,
      uint32 portGweiPerObservation,
      uint32 portGweiPerTransmission
    )
  {
    Billing memory billing = s_billing;
    return (
      billing.maximumGasPrice,
      billing.reasonableGasPrice,
      billing.microPortPerEth,
      billing.portGweiPerObservation,
      billing.portGweiPerTransmission
    );
  }

  event BillingAccessControllerSet(AccessControllerInterface old, AccessControllerInterface current);

  function setBillingAccessControllerInternal(AccessControllerInterface _billingAccessController)
    internal
  {
    AccessControllerInterface oldController = s_billingAccessController;
    if (_billingAccessController != oldController) {
      s_billingAccessController = _billingAccessController;
      emit BillingAccessControllerSet(
        oldController,
        _billingAccessController
      );
    }
  }

  function setBillingAccessController(AccessControllerInterface _billingAccessController)
    external
    onlyOwner
  {
    setBillingAccessControllerInternal(_billingAccessController);
  }

  function billingAccessController()
    external
    view
    returns (AccessControllerInterface)
  {
    return s_billingAccessController;
  }

  function withdrawPayment(address _transmitter)
    external
  {
    require(msg.sender == s_payees[_transmitter], "Only payee can withdraw");
    payOracle(_transmitter);
  }

  function owedPayment(address _transmitter)
    public
    view
    returns (uint256)
  {
    Oracle memory oracle = s_oracles[_transmitter];
    if (oracle.role == Role.Unset) { return 0; }
    Billing memory billing = s_billing;
    uint256 portWeiAmount =
      uint256(s_oracleObservationsCounts[oracle.index] - 1) *
      uint256(billing.portGweiPerObservation) *
      (1 gwei);
    portWeiAmount += s_gasReimbursementsPortWei[oracle.index] - 1;
    return portWeiAmount;
  }

  event OraclePaid(address transmitter, address payee, uint256 amount);

  function payOracle(address _transmitter)
    internal
  {
    Oracle memory oracle = s_oracles[_transmitter];
    uint256 portWeiAmount = owedPayment(_transmitter);
    if (portWeiAmount > 0) {
      address payee = s_payees[_transmitter];
      require(PORT.transfer(payee, portWeiAmount), "insufficient funds");
      s_oracleObservationsCounts[oracle.index] = 1;
      s_gasReimbursementsPortWei[oracle.index] = 1;
      emit OraclePaid(_transmitter, payee, portWeiAmount);
    }
  }

  function payOracles()
    internal
  {
    Billing memory billing = s_billing;
    uint16[maxNumOracles] memory observationsCounts = s_oracleObservationsCounts;
    uint256[maxNumOracles] memory gasReimbursementsPortWei =
      s_gasReimbursementsPortWei;
    address[] memory transmitters = s_transmitters;
    for (uint transmitteridx = 0; transmitteridx < transmitters.length; transmitteridx++) {
      uint256 reimbursementAmountPortWei = gasReimbursementsPortWei[transmitteridx] - 1;
      uint256 obsCount = observationsCounts[transmitteridx] - 1;
      uint256 portWeiAmount =
        obsCount * uint256(billing.portGweiPerObservation) * (1 gwei) + reimbursementAmountPortWei;
      if (portWeiAmount > 0) {
          address payee = s_payees[transmitters[transmitteridx]];
          require(PORT.transfer(payee, portWeiAmount), "insufficient funds");
          observationsCounts[transmitteridx] = 1;
          gasReimbursementsPortWei[transmitteridx] = 1;
          emit OraclePaid(transmitters[transmitteridx], payee, portWeiAmount);
        }
    }
    s_oracleObservationsCounts = observationsCounts;
    s_gasReimbursementsPortWei = gasReimbursementsPortWei;
  }

  function oracleRewards(
    bytes memory observers,
    bytes memory observersCount,
    uint16[maxNumOracles] memory observations
  )
    internal
    pure
    returns (uint16[maxNumOracles] memory)
  {
    for (uint obsIdx = 0; obsIdx < observers.length; obsIdx++) {
      uint8 observer = uint8(observers[obsIdx]);
      observations[observer] = saturatingAddUint16(observations[observer], uint8(observersCount[obsIdx]));
    }
    return observations;
  }
  uint256 internal constant accountingGasCost = 6035;

  function impliedGasPrice(
    uint256 txGasPrice,
    uint256 reasonableGasPrice,   
    uint256 maximumGasPrice
  )
    internal
    pure
    returns (uint256)
  {
    uint256 gasPrice = txGasPrice;
    if (txGasPrice < reasonableGasPrice) {
      gasPrice += (reasonableGasPrice - txGasPrice) / 2;
    }
    return min(gasPrice, maximumGasPrice);
  }

  function transmitterGasCostEthWei(
    uint256 initialGas,
    uint256 gasPrice,
    uint256 callDataCost,
    uint256 gasLeft
  )
    internal
    pure
    returns (uint128 gasCostEthWei)
  {
    require(initialGas >= gasLeft, "gasLeft cannot exceed initialGas");
    uint256 gasUsed =
      initialGas - gasLeft +
      callDataCost + accountingGasCost;
    uint256 fullGasCostEthWei = gasUsed * gasPrice * (1 gwei);
    assert(fullGasCostEthWei < maxUint128);
    return uint128(fullGasCostEthWei);
  }

  function withdrawFunds(address _recipient, uint256 _amount)
    external
  {
    require(msg.sender == owner || s_billingAccessController.hasAccess(msg.sender, msg.data),
      "Only owner&billingAdmin can call");
    uint256 portDue = totalPORTDue();
    uint256 portBalance = PORT.balanceOf(address(this));
    require(portBalance >= portDue, "insufficient balance");
    require(PORT.transfer(_recipient, min(portBalance - portDue, _amount)), "insufficient funds");
  }

  function totalPORTDue()
    internal
    view
    returns (uint256 portDue)
  {
    uint16[maxNumOracles] memory observationCounts = s_oracleObservationsCounts;
    for (uint i = 0; i < maxNumOracles; i++) {
      portDue += observationCounts[i] - 1;
    }
    Billing memory billing = s_billing;
    portDue *= uint256(billing.portGweiPerObservation) * (1 gwei);
    address[] memory transmitters = s_transmitters;
    uint256[maxNumOracles] memory gasReimbursementsPortWei =
      s_gasReimbursementsPortWei;
    for (uint i = 0; i < transmitters.length; i++) {
      portDue += uint256(gasReimbursementsPortWei[i]-1);
    }
  }

  function portAvailableForPayment()
    external
    view
    returns (int256 availableBalance)
  {
    int256 balance = int256(PORT.balanceOf(address(this)));
    int256 due = int256(totalPORTDue());
    return int256(balance) - int256(due);
  }

  function oracleObservationCount(address _signerOrTransmitter)
    external
    view
    returns (uint16)
  {
    Oracle memory oracle = s_oracles[_signerOrTransmitter];
    if (oracle.role == Role.Unset) { return 0; }
    return s_oracleObservationsCounts[oracle.index] - 1;
  }


  function reimburseAndRewardOracles(
    uint32 initialGas,
    bytes memory observers,
    bytes memory observerCount
  )
    internal
  {
    Oracle memory txOracle = s_oracles[msg.sender];
    Billing memory billing = s_billing;
    s_oracleObservationsCounts =
      oracleRewards(observers, observerCount, s_oracleObservationsCounts);
    require(txOracle.role == Role.Transmitter,
      "sent by undesignated transmitter"
    );
    uint256 gasPrice = impliedGasPrice(
      tx.gasprice / (1 gwei),
      billing.reasonableGasPrice,
      billing.maximumGasPrice
    );
    uint256 callDataGasCost = 16 * msg.data.length;
    uint256 gasLeft = gasleft();
    uint256 gasCostEthWei = transmitterGasCostEthWei(
      uint256(initialGas),
      gasPrice,
      callDataGasCost,
      gasLeft
    );
    uint256 gasCostPortWei = (gasCostEthWei * billing.microPortPerEth)/ 1e6;    // 转换为port token
    s_gasReimbursementsPortWei[txOracle.index] =
      s_gasReimbursementsPortWei[txOracle.index] + gasCostPortWei +
      uint256(billing.portGweiPerTransmission) * (1 gwei);
  }

  event PayeeshipTransferRequested(
    address indexed transmitter,
    address indexed current,
    address indexed proposed
  );

  event PayeeshipTransferred(
    address indexed transmitter,
    address indexed previous,
    address indexed current
  );

  function setPayees(
    address[] calldata _transmitters,
    address[] calldata _payees
  )
    external
    onlyOwner()
  {
    require(_transmitters.length == _payees.length, "transmitters.size != payees.size");

    for (uint i = 0; i < _transmitters.length; i++) {
      address transmitter = _transmitters[i];
      address payee = _payees[i];
      address currentPayee = s_payees[transmitter];
      bool zeroedOut = currentPayee == address(0);
      require(zeroedOut || currentPayee == payee, "payee already set");
      s_payees[transmitter] = payee;

      if (currentPayee != payee) {
        emit PayeeshipTransferred(transmitter, currentPayee, payee);
      }
    }
  }

  function transferPayeeship(
    address _transmitter,
    address _proposed
  )
    external
  {
      require(msg.sender == s_payees[_transmitter], "only current payee can update");
      require(msg.sender != _proposed, "cannot transfer to self");

      address previousProposed = s_proposedPayees[_transmitter];
      s_proposedPayees[_transmitter] = _proposed;

      if (previousProposed != _proposed) {
        emit PayeeshipTransferRequested(_transmitter, msg.sender, _proposed);
      }
  }

  function acceptPayeeship(
    address _transmitter
  )
    external
  {
    require(msg.sender == s_proposedPayees[_transmitter], "only proposed payees can accept");

    address currentPayee = s_payees[_transmitter];
    s_payees[_transmitter] = msg.sender;
    s_proposedPayees[_transmitter] = address(0);

    emit PayeeshipTransferred(_transmitter, currentPayee, msg.sender);
  }

  function saturatingAddUint16(uint16 _x, uint16 _y)
    internal
    pure
    returns (uint16)
  {
    return uint16(min(uint256(_x)+uint256(_y), maxUint16));
  }

  function min(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
  {
    if (a < b) { return a; }
    return b;
  }
}

// File: contracts/OffchainAggregator.sol

pragma solidity ^0.7.1;






contract OffchainAggregator is
    Owned,
    OffchainAggregatorBilling,
    AggregatorInterface
{
    uint256 private constant maxUint32 = (1 << 32) - 1;

    struct HotVars {
        bytes16 latestConfigDigest;
        uint64 latestRoundId;
    }
    HotVars internal s_hotVars;

    struct Transmission {
        bytes32 answer;
        uint64 timestamp;
        uint8 validBytes;
        bytes32 multipleObservationsIndex;
        bytes32 multipleObservationsValidBytes;
        bytes32[] multipleObservations;
    }
    mapping(uint64 => Transmission) internal s_transmissions;
    uint32 internal s_configCount;
    uint32 internal s_latestConfigBlockNumber; // makes it easier for offchain systems

    constructor(
        uint32 _maximumGasPrice,
        uint32 _reasonableGasPrice,
        uint32 _microPortPerEth,
        uint32 _portGweiPerObservation,
        uint32 _portGweiPerTransmission,
        address _port,
        AccessControllerInterface _billingAccessController,
        AccessControllerInterface _requesterAccessController,
        uint8 _decimals,
        string memory _description
    )
        OffchainAggregatorBilling(
            _maximumGasPrice,
            _reasonableGasPrice,
            _microPortPerEth,
            _portGweiPerObservation,
            _portGweiPerTransmission,
            _port,
            _billingAccessController
        )
    {
        decimals = _decimals;
        s_description = _description;
        setRequesterAccessController(_requesterAccessController);
    }

    event ConfigSet(
        uint32 previousConfigBlockNumber,
        uint64 configCount,
        address[] signers,
        address[] transmitters,
        uint64 encodedConfigVersion,
        bytes encoded
    );

    modifier checkConfigValid(uint256 _numSigners, uint256 _numTransmitters) {
        require(_numSigners <= maxNumOracles, "too many signers");
        require(
            _numSigners == _numTransmitters,
            "oracle addresses out of registration"
        );
        _;
    }

    function setConfig(
        address[] calldata _signers,
        address[] calldata _transmitters,
        uint64 _encodedConfigVersion,
        bytes calldata _encoded
    )
        external
        checkConfigValid(_signers.length, _transmitters.length)
        onlyOwner()
    {
        while (s_signers.length != 0) {
            uint256 lastIdx = s_signers.length - 1;
            address signer = s_signers[lastIdx];
            address transmitter = s_transmitters[lastIdx];
            payOracle(transmitter);
            delete s_oracles[signer];
            delete s_oracles[transmitter];
            s_signers.pop();
            s_transmitters.pop();
        }

        for (uint256 i = 0; i < _signers.length; i++) {
            require(
                s_oracles[_signers[i]].role == Role.Unset,
                "repeated signer address"
            );
            s_oracles[_signers[i]] = Oracle(uint8(i), Role.Signer);
            require(
                s_payees[_transmitters[i]] != address(0),
                "payee must be set"
            );
            require(
                s_oracles[_transmitters[i]].role == Role.Unset,
                "repeated transmitter address"
            );
            s_oracles[_transmitters[i]] = Oracle(uint8(i), Role.Transmitter);
            s_signers.push(_signers[i]);
            s_transmitters.push(_transmitters[i]);
        }
        uint32 previousConfigBlockNumber = s_latestConfigBlockNumber;
        s_latestConfigBlockNumber = uint32(block.number);
        s_configCount += 1;
        uint64 configCount = s_configCount;
        {
            s_hotVars.latestConfigDigest = configDigestFromConfigData(
                address(this),
                configCount,
                _signers,
                _transmitters,
                _encodedConfigVersion,
                _encoded
            );
        }
        emit ConfigSet(
            previousConfigBlockNumber,
            configCount,
            _signers,
            _transmitters,
            _encodedConfigVersion,
            _encoded
        );
    }

    function configDigestFromConfigData(
        address _contractAddress,
        uint64 _configCount,
        address[] calldata _signers,
        address[] calldata _transmitters,
        uint64 _encodedConfigVersion,
        bytes calldata _encodedConfig
    ) internal pure returns (bytes16) {
        return
            bytes16(
                keccak256(
                    abi.encode(
                        _contractAddress,
                        _configCount,
                        _signers,
                        _transmitters,
                        _encodedConfigVersion,
                        _encodedConfig
                    )
                )
            );
    }

    function latestConfigDetails()
        external
        view
        returns (
            uint32 configCount,
            uint32 blockNumber,
            bytes16 configDigest
        )
    {
        return (
            s_configCount,
            s_latestConfigBlockNumber,
            s_hotVars.latestConfigDigest
        );
    }


    function transmitters() external view returns (address[] memory) {
        return s_transmitters;
    }

    AccessControllerInterface internal s_requesterAccessController;

    event RequesterAccessControllerSet(
        AccessControllerInterface old,
        AccessControllerInterface current
    );

    event RoundRequested(
        address indexed requester,
        bytes16 configDigest,
        uint64 roundId
    );

    function requesterAccessController()
        external
        view
        returns (AccessControllerInterface)
    {
        return s_requesterAccessController;
    }

    function setRequesterAccessController(
        AccessControllerInterface _requesterAccessController
    ) public onlyOwner() {
        AccessControllerInterface oldController = s_requesterAccessController;
        if (_requesterAccessController != oldController) {
            s_requesterAccessController = AccessControllerInterface(
                _requesterAccessController
            );
            emit RequesterAccessControllerSet(
                oldController,
                _requesterAccessController
            );
        }
    }

    function requestNewRound() external returns (uint80) {
        require(
            msg.sender == owner ||
                s_requesterAccessController.hasAccess(msg.sender, msg.data),
            "Only owner&requester can call"
        );

        HotVars memory hotVars = s_hotVars;

        emit RoundRequested(
            msg.sender,
            hotVars.latestConfigDigest,
            hotVars.latestRoundId
        );
        return hotVars.latestRoundId + 1;
    }

    event NewTransmission(
        uint64 indexed roundId,
        bytes32 answer,
        address transmitter,
        bytes observers,
        bytes32 rawReportContext
    );

    function decodeReport(bytes memory _report)
        internal
        pure
        returns (
            bytes32 rawReportContext,
            bytes32 rawObservers,
            bytes32 observersCount,
            bytes32 observation,
            bytes32 observationIndex,
            bytes32 observationLength,
            bytes32[] memory multipleObservation
        )
    {
        (
            rawReportContext,
            rawObservers,
            observersCount,
            observation,
            observationIndex,
            observationLength,
            multipleObservation
        ) = abi.decode(
            _report,
            (bytes32, bytes32, bytes32, bytes32, bytes32, bytes32, bytes32[])
        );
    }

    struct ReportData {
        HotVars hotVars;
        bytes observers;
        bytes observersCount;
        bytes32 observation;
        bytes vs;
        bytes32 rawReportContext;
    }

    function latestTransmissionDetails()
        external
        view
        returns (
            bytes16 configDigest,
            uint64 latestRoundId,
            bytes32 latestAnswer,
            uint8 validBytes,
            bytes32 multipleObservationsIndex,
            bytes32 multipleObservationsValidBytes,
            bytes32[] memory multipleObservations,
            uint64 latestTimestamp
        )
    {
        require(msg.sender == tx.origin, "Only callable by EOA");
        Transmission memory transmission =
            s_transmissions[s_hotVars.latestRoundId];
        return (
            s_hotVars.latestConfigDigest,
            s_hotVars.latestRoundId,
            transmission.answer,
            transmission.validBytes,
            transmission.multipleObservationsIndex,
            transmission.multipleObservationsValidBytes,
            transmission.multipleObservations,
            transmission.timestamp
        );
    }

    uint16 private constant TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT =
        4 + // function selector
            32 + // _report value
            32 + // _rs value
            32 + // _ss value
            32 + // _rawVs value
            32 + // length of _report
            32 + // length _rs
            32 + // length of _ss
            0; // placeholder

    function expectedMsgDataLength(
        bytes calldata _report,
        bytes32[] calldata _rs,
        bytes32[] calldata _ss
    ) private pure returns (uint256 length) {
        return
            uint256(TRANSMIT_MSGDATA_CONSTANT_LENGTH_COMPONENT) +
            _report.length +
            _rs.length *
            32 +
            _ss.length *
            32 + 
            0;
    }

    function transmit(
        bytes calldata _report,
        bytes32[] calldata _rs,
        bytes32[] calldata _ss,
        bytes32 _rawVs // signatures
    ) external {
        uint256 initialGas = gasleft();
        require(
            msg.data.length == expectedMsgDataLength(_report, _rs, _ss),
            "transmit message too long"
        );
        uint64 roundId;
        ReportData memory r;
        {
            r.hotVars = s_hotVars;

            bytes32 rawObservers;
            bytes32 observersCount;
            bytes32 observationIndex;
            bytes32 observationLength;
            bytes32[] memory multipleObservation;
            (
                r.rawReportContext,
                rawObservers,
                observersCount,
                r.observation,
                observationIndex,
                observationLength,
                multipleObservation
            ) = abi.decode(
                _report,
                (
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32,
                    bytes32[]
                )
            );

            // rawReportContext consists of:
            // 6-byte zero padding
            // 16-byte configDigest
            // 8-byte round id
            // 1-byte observer count
            // 1-byte valid byte count (answer)

            bytes16 configDigest = bytes16(r.rawReportContext << 48);
            require(
                r.hotVars.latestConfigDigest == configDigest,
                "configDigest mismatch"
            );

            roundId = uint64(bytes8(r.rawReportContext << 176));
            require(
                s_transmissions[roundId].timestamp == 0,
                "data has been transmitted"
            );

            uint8 observerCount = uint8(bytes1(r.rawReportContext << 240));
            s_transmissions[roundId] = Transmission(
                r.observation,
                uint64(block.timestamp),
                uint8(uint256(r.rawReportContext)),
                observationIndex,
                observationLength,
                multipleObservation
            );
            require(_rs.length <= maxNumOracles, "too many signatures");
            require(_ss.length == _rs.length, "signatures out of registration");

            r.vs = new bytes(_rs.length);
            for (uint8 i = 0; i < _rs.length; i++) {
                r.vs[i] = _rawVs[i];
            }

            r.observers = new bytes(observerCount);
            r.observersCount = new bytes(observerCount);
            bool[maxNumOracles] memory seen;
            for (uint8 i = 0; i < observerCount; i++) {
                uint8 observerIdx = uint8(rawObservers[i]);
                require(!seen[observerIdx], "observer index repeated");
                seen[observerIdx] = true;
                r.observers[i] = rawObservers[i];
                r.observersCount[i] = observersCount[i];
            }

            Oracle memory transmitter = s_oracles[msg.sender];
            require(
                transmitter.role == Role.Transmitter &&
                    msg.sender == s_transmitters[transmitter.index],
                "unauthorized transmitter"
            );
        }

        {
            bytes32 h = keccak256(_report);
            bool[maxNumOracles] memory signed;

            Oracle memory o;
            for (uint256 i = 0; i < _rs.length; i++) {
                address signer =
                    ecrecover(h, uint8(r.vs[i]) + 27, _rs[i], _ss[i]);
                o = s_oracles[signer];
                require(
                    o.role == Role.Signer,
                    "address not authorized to sign"
                );
                require(!signed[o.index], "non-unique signature");
                signed[o.index] = true;
            }
        }

        {
            if (roundId > r.hotVars.latestRoundId) {
                r.hotVars.latestRoundId = roundId;
            }
            emit NewTransmission(
                r.hotVars.latestRoundId,
                r.observation,
                msg.sender,
                r.observers,
                r.rawReportContext
            );
            emit NewRound(
                r.hotVars.latestRoundId,
                address(0x0),
                block.timestamp
            );
            emit AnswerUpdated(
                r.observation,
                r.hotVars.latestRoundId,
                block.timestamp
            );
        }
        s_hotVars = r.hotVars;
        assert(initialGas < maxUint32); // ？
        reimburseAndRewardOracles(
            uint32(initialGas),
            r.observers,
            r.observersCount
        );
    }

    function latestAnswer()
        public
        view
        virtual
        override
        returns (
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory
        )
    {
        return (
            s_transmissions[s_hotVars.latestRoundId].answer,
            s_transmissions[s_hotVars.latestRoundId].validBytes,
            s_transmissions[s_hotVars.latestRoundId].multipleObservationsIndex,
            s_transmissions[s_hotVars.latestRoundId]
                .multipleObservationsValidBytes,
            s_transmissions[s_hotVars.latestRoundId].multipleObservations
        );
    }

    function latestTimestamp() public view virtual override returns (uint256) {
        return s_transmissions[s_hotVars.latestRoundId].timestamp;
    }

    function latestRound() public view virtual override returns (uint256) {
        return s_hotVars.latestRoundId;
    }

    function getAnswer(uint256 _roundId)
        public
        view
        virtual
        override
        returns (
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory
        )
    {
        if (_roundId > 0xFFFFFFFF) {
            return (0, 0, 0, 0, new bytes32[](0));
        }
        return (
            s_transmissions[uint32(_roundId)].answer,
            s_transmissions[uint32(_roundId)].validBytes,
            s_transmissions[uint32(_roundId)].multipleObservationsIndex,
            s_transmissions[uint32(_roundId)].multipleObservationsValidBytes,
            s_transmissions[uint32(_roundId)].multipleObservations
        );
    }

    function getStringAnswerByIndex(uint256 _roundId, uint8 _index)
        public
        virtual
        override
        view
        returns (string memory)
    {
        Transmission memory transmission =
                s_transmissions[uint32(_roundId)];
        uint256 observationCount = transmission.multipleObservations.length;
        bytes32 observation;
        for(uint256 i = 0; i < observationCount; i ++){
            if(_index == uint8(transmission.multipleObservationsIndex[i])){
                observation = transmission.multipleObservations[i];
                break;
            }
        }
        return bytes32ToString(observation);
    }

    function getLatestStringAnswerByIndex(uint8 _index)
        public
        virtual
        override
        view
        returns (string memory)
    {
        Transmission memory transmission =
                s_transmissions[s_hotVars.latestRoundId];
        uint256 observationCount = transmission.multipleObservations.length;
        bytes32 observation;
        for(uint256 i = 0; i < observationCount; i ++){
            if(_index == uint8(transmission.multipleObservationsIndex[i])){
                observation = transmission.multipleObservations[i];
                break;
            }
        }
        return bytes32ToString(observation);
    }

    function getStringAnswer(uint256 _roundId)
        public
        virtual
        override
        view
        returns (uint8[] memory _index, string memory _answerSet)
    {
        Transmission memory transmission =
                s_transmissions[uint32(_roundId)];
        uint256 observationCount = transmission.multipleObservations.length;
        if(observationCount == 0){
            return (new uint8[](0), bytes32ToString(transmission.answer));
        }
        _index = new uint8[](observationCount);
        for(uint256 i = 0; i < observationCount; i ++){
            _index[i] = uint8(transmission.multipleObservationsIndex[i]);
            string memory observation = bytes32ToString(transmission.multipleObservations[i]);
            if(i == 0){
                _answerSet = observation;
            }
            else{
                _answerSet = string(abi.encodePacked(_answerSet, ";", observation));
            }
        }
    }

    function getLatestStringAnswer()
        public
        virtual
        override
        view
        returns (uint8[] memory _index, string memory _answerSet)
    {
        Transmission memory transmission =
                s_transmissions[s_hotVars.latestRoundId];
        uint256 observationCount = transmission.multipleObservations.length;
        if(observationCount == 0){
            return (new uint8[](0), bytes32ToString(transmission.answer));
        }
        _index = new uint8[](observationCount);
        for(uint256 i = 0; i < observationCount; i ++){
            _index[i] = uint8(transmission.multipleObservationsIndex[i]);
            string memory observation = bytes32ToString(transmission.multipleObservations[i]);
            if(i == 0){
                _answerSet = observation;
            }
            else{
                _answerSet = string(abi.encodePacked(_answerSet, ";", observation));
            }
        }
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function getTimestamp(uint256 _roundId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (_roundId > 0xFFFFFFFF) {
            return 0;
        }
        return s_transmissions[uint32(_roundId)].timestamp;
    }

    string private constant V3_NO_DATA_ERROR = "No data present";

    uint8 public immutable override decimals;

    uint256 public constant override version = 4;

    string internal s_description;

    function description()
        public
        view
        virtual
        override
        returns (string memory)
    {
        return s_description;
    }

    function getRoundData(uint80 _roundId)
        public
        view
        virtual
        override
        returns (
            uint80 roundId,
            bytes32 answer,
            uint8 validBytes,
            bytes32 multipleObservationsIndex,
            bytes32 multipleObservationsValidBytes,
            bytes32[] memory multipleObservations,
            uint256 updatedAt
        )
    {
        require(_roundId <= 0xFFFFFFFF, V3_NO_DATA_ERROR);
        Transmission memory transmission = s_transmissions[uint32(_roundId)];
        return (
            _roundId,
            transmission.answer,
            transmission.validBytes,
            transmission.multipleObservationsIndex,
            transmission.multipleObservationsValidBytes,
            transmission.multipleObservations,
            transmission.timestamp
        );
    }

    function latestRoundData()
        public
        view
        virtual
        override
        returns (
            uint80 roundId,
            bytes32 answer,
            uint8 validBytes,
            bytes32 multipleObservationsIndex,
            bytes32 multipleObservationsValidBytes,
            bytes32[] memory multipleObservations,
            uint256 updatedAt
        )
    {
        roundId = s_hotVars.latestRoundId;
        Transmission memory transmission = s_transmissions[uint32(roundId)];
        return (
            roundId,
            transmission.answer,
            transmission.validBytes,
            transmission.multipleObservationsIndex,
            transmission.multipleObservationsValidBytes,
            transmission.multipleObservations,
            transmission.timestamp
        );
    }
}

// File: contracts/SimpleWriteAccessController.sol

pragma solidity ^0.7.1;



/**
 * @title SimpleWriteAccessController
 * @notice Gives access to accounts explicitly added to an access list by the
 * controller's owner.
 * @dev does not make any special permissions for externally, see
 * SimpleReadAccessController for that.
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

// File: contracts/SimpleReadAccessController.sol

pragma solidity ^0.7.1;


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

// File: contracts/AccessControlledOffchainAggregator.sol

pragma solidity ^0.7.1;



contract AccessControlledOffchainAggregator is
    OffchainAggregator,
    SimpleReadAccessController
{
    constructor(
        uint32 _maximumGasPrice,
        uint32 _reasonableGasPrice,
        uint32 _microPortPerEth,
        uint32 _portGweiPerObservation,
        uint32 _portGweiPerTransmission,
        address _port,
        AccessControllerInterface _billingAccessController,
        AccessControllerInterface _requesterAccessController,
        uint8 _decimals,
        string memory description
    )
        OffchainAggregator(
            _maximumGasPrice,
            _reasonableGasPrice,
            _microPortPerEth,
            _portGweiPerObservation,
            _portGweiPerTransmission,
            _port,
            _billingAccessController,
            _requesterAccessController,
            _decimals,
            description
        )
    {}

    function latestAnswer()
        public
        view
        override
        checkAccess()
        returns (
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory
        )
    {
        return super.latestAnswer();
    }

    function latestTimestamp()
        public
        view
        override
        checkAccess()
        returns (uint256)
    {
        return super.latestTimestamp();
    }

    function latestRound()
        public
        view
        override
        checkAccess()
        returns (uint256)
    {
        return super.latestRound();
    }

    function getAnswer(uint256 _roundId)
        public
        view
        override
        checkAccess()
        returns (
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory
        )
    {
        return super.getAnswer(_roundId);
    }

    function getStringAnswerByIndex(uint256 _roundId, uint8 _index)
        public
        view
        override
        checkAccess()
        returns (
          string memory
        )
    {
        return super.getStringAnswerByIndex(_roundId, _index);
    }

    function getLatestStringAnswerByIndex(uint8 _index)
        public
        view
        override
        checkAccess()
        returns (
          string memory
        )
    {
        return super.getLatestStringAnswerByIndex(_index);
    }

    function getStringAnswer(uint256 _roundId)
        public
        view
        override
        checkAccess()
        returns (uint8[] memory _index, string memory _answerSet)
    {
        return super.getStringAnswer(_roundId);
    }

    function getLatestStringAnswer()
        public
        view
        override
        checkAccess()
        returns (uint8[] memory _index, string memory _answerSet)
    {
        return super.getLatestStringAnswer();
    }

    function getTimestamp(uint256 _roundId)
        public
        view
        override
        checkAccess()
        returns (uint256)
    {
        return super.getTimestamp(_roundId);
    }

    function description()
        public
        view
        override
        checkAccess()
        returns (string memory)
    {
        return super.description();
    }

    function getRoundData(uint80 _roundId)
        public
        view
        override
        checkAccess()
        returns (
            uint80,
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory,
            uint256
        )
    {
        return super.getRoundData(_roundId);
    }

    function latestRoundData()
        public
        view
        override
        checkAccess()
        returns (
            uint80,
            bytes32,
            uint8,
            bytes32,
            bytes32,
            bytes32[] memory,
            uint256
        )
    {
        return super.latestRoundData();
    }
}