/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

/// @title Keep Random Beacon
///
/// @notice Keep Random Beacon generates verifiable randomness that is resistant
/// to bad actors both in the relay network and on the anchoring blockchain.
interface IRandomBeacon {
    /// @notice Event emitted for each new relay entry generated. It contains
    /// request ID allowing to associate the generated relay entry with relay
    /// request created previously with `requestRelayEntry` function. Event is
    /// emitted no matter if callback was executed or not.
    ///
    /// @param requestId Relay request ID for which entry was generated.
    /// @param entry Generated relay entry.
    event RelayEntryGenerated(uint256 requestId, uint256 entry);

    /// @notice Provides the customer with an estimated entry fee in wei to use
    /// in the request. The fee estimate is only valid for the transaction it is
    /// called in, so the customer must make the request immediately after
    /// obtaining the estimate. Insufficient payment will lead to the request
    /// being rejected and the transaction reverted.
    ///
    /// The customer may decide to provide more ether for an entry fee than
    /// estimated by this function. This is especially helpful when callback gas
    /// cost fluctuates. Any surplus between the passed fee and the actual cost
    /// of producing an entry and executing a callback is returned back to the
    /// customer.
    /// @param callbackGas Gas required for the callback.
    function entryFeeEstimate(uint256 callbackGas)
        external
        view
        returns (uint256);

    /// @notice Submits a request to generate a new relay entry. Executes
    /// callback on the provided callback contract with the generated entry and
    /// emits `RelayEntryGenerated(uint256 requestId, uint256 entry)` event.
    /// Callback contract has to declare public `__beaconCallback(uint256)`
    /// function that is going to be executed with the result, once ready.
    /// It is recommended to implement `IRandomBeaconConsumer` interface to
    /// ensure the correct callback function signature.
    ///
    /// @dev Beacon does not support concurrent relay requests. No new requests
    /// should be made while the beacon is already processing another request.
    /// Requests made while the beacon is busy will be rejected and the
    /// transaction reverted.
    ///
    /// @param callbackContract Callback contract address. Callback is called
    /// once a new relay entry has been generated. Must declare public
    /// `__beaconCallback(uint256)` function. It is recommended to implement
    /// `IRandomBeaconConsumer` interface to ensure the correct callback function
    /// signature.
    /// @param callbackGas Gas required for the callback.
    /// The customer needs to ensure they provide a sufficient callback gas
    /// to cover the gas fee of executing the callback. Any surplus is returned
    /// to the customer. If the callback gas amount turns to be not enough to
    /// execute the callback, callback execution is skipped.
    /// @return An uint256 representing uniquely generated relay request ID
    function requestRelayEntry(address callbackContract, uint256 callbackGas)
        external
        payable
        returns (uint256);

    /// @notice Submits a request to generate a new relay entry. Emits
    /// `RelayEntryGenerated(uint256 requestId, uint256 entry)` event for the
    /// generated entry.
    ///
    /// @dev Beacon does not support concurrent relay requests. No new requests
    /// should be made while the beacon is already processing another request.
    /// Requests made while the beacon is busy will be rejected and the
    /// transaction reverted.
    ///
    /// @return An uint256 representing uniquely generated relay request ID
    function requestRelayEntry() external payable returns (uint256);
}

/// @title Keep Random Beacon Consumer
///
/// @notice Receives Keep Random Beacon relay entries with `__beaconCallback`
/// function. Contract implementing this interface does not have to be the one
/// requesting relay entry but it is the one receiving the requested relay entry
/// once it is produced.
///
/// @dev Use this interface to indicate the contract receives relay entries from
/// the beacon and to ensure the correctness of callback function signature.
interface IRandomBeaconConsumer {
    /// @notice Receives relay entry produced by Keep Random Beacon. This function
    /// should be called only by Keep Random Beacon.
    ///
    /// @param relayEntry Relay entry (random number) produced by Keep Random
    /// Beacon.
    function __beaconCallback(uint256 relayEntry) external;
}

/**
▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
  ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓▌        ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
  ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
  ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓

                           Trust math, not hardware.
*/

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol";
import "./utils/AddressArrayUtils.sol";
import "./utils/PercentUtils.sol";
import "./KeepRegistry.sol";
import "./IRandomBeacon.sol";

interface OperatorContract {
    function entryVerificationFee() external view returns (uint256);

    function groupCreationFee() external view returns (uint256);

    function groupProfitFee() external view returns (uint256);

    function gasPriceCeiling() external view returns (uint256);

    function sign(uint256 requestId, bytes calldata previousEntry)
        external
        payable;

    function numberOfGroups() external view returns (uint256);

    function createGroup(uint256 newEntry, address payable submitter)
        external
        payable;

    function isGroupSelectionPossible() external view returns (bool);
}

/// @title KeepRandomBeaconServiceImplV1
/// @notice Initial version of service contract that works under Keep Random
/// Beacon proxy and allows upgradability. The purpose of the contract is to have
/// up-to-date logic for threshold random number generation. Updated contracts
/// must inherit from this contract and have to be initialized under updated version
/// name.
/// @dev Warning: you can't set constants directly in the contract and must use
/// initialize() please see openzeppelin upgradeable contracts approach for more
/// info.
contract KeepRandomBeaconServiceImplV1 is ReentrancyGuard, IRandomBeacon {
    using SafeMath for uint256;
    using PercentUtils for uint256;
    using AddressArrayUtils for address[];

    event RelayEntryRequested(uint256 requestId);

    /// @dev Fraction in % of the estimated cost of DKG that is included
    /// in relay request fee.
    uint256 internal _dkgContributionMargin;

    /// @dev Every relay request payment includes DKG contribution that is added to
    /// the DKG fee pool, once the pool value reaches the required minimum, a new
    /// relay entry will trigger the creation of a new group. Expressed in wei.
    uint256 internal _dkgFeePool;

    /// @dev Rewards not paid out to the operators are sent to request subsidy pool to
    /// subsidize new requests: 1% of the subsidy pool is returned to the requester's
    /// surplus address. Expressed in wei.
    uint256 internal _requestSubsidyFeePool;

    /// @dev Each service contract tracks its own requests and these are independent
    /// from operator contracts which track signing requests instead.
    uint256 internal _requestCounter;

    /// @dev Previous entry value produced by the beacon.
    bytes internal _previousEntry;

    /// @dev The cost of executing executeCallback() code of this contract, includes
    /// everything but the logic of the external contract called.
    /// The value is used to estimate the cost of executing a callback and is
    /// used for calculating callback call surplus reimbursement for requestor.
    ///
    /// This value has to be updated in case of EVM opcode price change, but since
    /// upgrading service contract is easy, it is not a worrisome problem.
    uint256 internal _baseCallbackGas;

    struct Callback {
        address callbackContract;
        uint256 callbackFee;
        uint256 callbackGas;
        address payable surplusRecipient;
    }

    mapping(uint256 => Callback) internal _callbacks;

    /// @dev KeepRegistry contract with a list of approved operator contracts and upgraders.
    address internal _registry;

    address[] internal _operatorContracts;

    /// @dev Mapping to store new implementation versions that inherit from this contract.
    mapping(string => bool) internal _initialized;

    /// @dev Seed used as the first random beacon value.
    /// It's a G1 point G * PI =
    /// G * 31415926535897932384626433832795028841971693993751058209749445923078164062862
    /// Where G is the generator of G1 abstract cyclic group.
    bytes internal constant _beaconSeed =
        hex"15c30f4b6cf6dbbcbdcc10fe22f54c8170aea44e198139b776d512d8f027319a1b9e8bfaf1383978231ce98e42bafc8129f473fc993cf60ce327f7d223460663";

    /// @dev Throws if called by any account other than the operator contract
    /// upgrader authorized for this service contract.
    modifier onlyOperatorContractUpgrader() {
        address operatorContractUpgrader =
            KeepRegistry(_registry).operatorContractUpgraderFor(address(this));
        require(
            operatorContractUpgrader == msg.sender,
            "Caller is not operator contract upgrader"
        );
        _;
    }

    constructor() public {
        _initialized["KeepRandomBeaconServiceImplV1"] = true;
    }

    /// @notice Initialize Keep Random Beacon service contract implementation.
    /// @param dkgContributionMargin Fraction in % of the estimated cost of DKG that is included in relay
    /// request fee.
    /// @param registry KeepRegistry contract linked to this contract.
    function initialize(uint256 dkgContributionMargin, address registry)
        public
    {
        require(!initialized(), "Contract is already initialized.");
        require(registry != address(0), "Incorrect registry address");

        _initialized["KeepRandomBeaconServiceImplV1"] = true;
        _dkgContributionMargin = dkgContributionMargin;
        _previousEntry = _beaconSeed;
        _registry = registry;
        _baseCallbackGas = 10226;
    }

    /// @notice Checks if this contract is initialized.
    function initialized() public view returns (bool) {
        return _initialized["KeepRandomBeaconServiceImplV1"];
    }

    /// @notice Adds operator contract
    /// @param operatorContract Address of the operator contract.
    function addOperatorContract(address operatorContract)
        public
        onlyOperatorContractUpgrader
    {
        require(
            KeepRegistry(_registry).isApprovedOperatorContract(
                operatorContract
            ),
            "Operator contract is not approved"
        );
        _operatorContracts.push(operatorContract);
    }

    /// @notice Removes operator contract
    /// @param operatorContract Address of the operator contract.
    function removeOperatorContract(address operatorContract)
        public
        onlyOperatorContractUpgrader
    {
        _operatorContracts.removeAddress(operatorContract);
    }

    /// @notice Add funds to DKG fee pool.
    function fundDkgFeePool() public payable {
        _dkgFeePool += msg.value;
    }

    /// @notice Add funds to request subsidy fee pool.
    function fundRequestSubsidyFeePool() public payable {
        _requestSubsidyFeePool += msg.value;
    }

    /// @notice Selects an operator contract from the available list using modulo
    /// operation with seed value weighted by the number of active groups on each
    /// operator contract.
    /// @param seed Cryptographically generated random value.
    /// @return Address of operator contract.
    function selectOperatorContract(uint256 seed)
        public
        view
        returns (address)
    {
        uint256 totalNumberOfGroups;

        uint256 approvedContractsCounter;
        address[] memory approvedContracts =
            new address[](_operatorContracts.length);

        for (uint256 i = 0; i < _operatorContracts.length; i++) {
            if (
                KeepRegistry(_registry).isApprovedOperatorContract(
                    _operatorContracts[i]
                )
            ) {
                totalNumberOfGroups += OperatorContract(_operatorContracts[i])
                    .numberOfGroups();
                approvedContracts[
                    approvedContractsCounter
                ] = _operatorContracts[i];
                approvedContractsCounter++;
            }
        }

        require(
            totalNumberOfGroups > 0,
            "Total number of groups must be greater than zero."
        );

        uint256 selectedIndex = seed % totalNumberOfGroups;

        uint256 selectedContract;
        uint256 indexByGroupCount;

        for (uint256 i = 0; i < approvedContractsCounter; i++) {
            indexByGroupCount += OperatorContract(approvedContracts[i])
                .numberOfGroups();
            if (selectedIndex < indexByGroupCount) {
                return approvedContracts[selectedContract];
            }
            selectedContract++;
        }

        return approvedContracts[selectedContract];
    }

    /// @notice Creates a request to generate a new relay entry, which will include
    /// a random number (by signing the previous entry's random number).
    /// @return An uint256 representing uniquely generated entry Id.
    function requestRelayEntry() public payable returns (uint256) {
        return requestRelayEntry(address(0), 0);
    }

    /// @notice Creates a request to generate a new relay entry (random number).
    /// @param callbackContract Callback contract address. Callback is called
    /// once a new relay entry has been generated. Callback contract must
    /// declare public `__beaconCallback(uint256)` function that is going to be
    /// executed with the result, once ready.
    /// @param callbackGas Gas required for the callback (2 million gas max).
    /// The customer needs to ensure they provide a sufficient callback gas
    /// to cover the gas fee of executing the callback. Any surplus is returned
    /// to the customer. If the callback gas amount turns to be not enough to
    /// execute the callback, callback execution is skipped.
    /// @return An uint256 representing uniquely generated relay request ID. It
    /// is also returned as part of the event.
    function requestRelayEntry(address callbackContract, uint256 callbackGas)
        public
        payable
        nonReentrant
        returns (uint256)
    {
        require(
            callbackGas <= 2000000,
            "Callback gas exceeds 2000000 gas limit"
        );

        require(
            msg.value >= entryFeeEstimate(callbackGas),
            "Payment is less than required minimum."
        );

        (
            uint256 entryVerificationFee,
            uint256 dkgContributionFee,
            uint256 groupProfitFee,
            uint256 gasPriceCeiling
        ) = entryFeeBreakdown();

        uint256 callbackFee =
            msg.value.sub(entryVerificationFee).sub(dkgContributionFee).sub(
                groupProfitFee
            );

        _dkgFeePool += dkgContributionFee;

        OperatorContract operatorContract =
            OperatorContract(
                selectOperatorContract(uint256(keccak256(_previousEntry)))
            );

        uint256 selectedOperatorContractFee =
            operatorContract.groupProfitFee().add(
                operatorContract.entryVerificationFee()
            );

        _requestCounter++;
        uint256 requestId = _requestCounter;

        operatorContract.sign.value(
            selectedOperatorContractFee.add(callbackFee)
        )(requestId, _previousEntry);

        // If selected operator contract is cheaper than expected return the
        // surplus to the subsidy fee pool.
        // We do that instead of returning the surplus to the requestor to have
        // a consistent beacon pricing for customers without fluctuations caused
        // by different operator contracts being selected.
        uint256 surplus =
            entryVerificationFee.add(groupProfitFee).sub(
                selectedOperatorContractFee
            );
        _requestSubsidyFeePool = _requestSubsidyFeePool.add(surplus);

        if (callbackContract != address(0)) {
            _callbacks[requestId] = Callback(
                callbackContract,
                callbackFee,
                callbackGas,
                msg.sender
            );
        }

        // Send 1% of the request subsidy pool to the requestor.
        if (_requestSubsidyFeePool >= 100) {
            uint256 amount = _requestSubsidyFeePool.percent(1);
            _requestSubsidyFeePool -= amount;
            (bool success, ) = msg.sender.call.value(amount)("");
            require(success, "Failed send subsidy fee");
        }

        emit RelayEntryRequested(requestId);
        return requestId;
    }

    /// @notice Store valid entry returned by operator contract and call customer
    /// specified callback if required.
    /// @param requestId Request id tracked internally by this contract.
    /// @param entry The generated random number.
    /// @param submitter Relay entry submitter.
    function entryCreated(
        uint256 requestId,
        bytes memory entry,
        address payable submitter
    ) public {
        require(
            _operatorContracts.contains(msg.sender),
            "Only authorized operator contract can call relay entry."
        );

        _previousEntry = entry;
        uint256 entryAsNumber = uint256(keccak256(entry));
        emit RelayEntryGenerated(requestId, entryAsNumber);

        createGroupIfApplicable(entryAsNumber, submitter);
    }

    /// @notice Executes customer specified callback for the relay entry request.
    /// @param requestId Request id tracked internally by this contract.
    /// @param entry The generated random number.
    function executeCallback(uint256 requestId, uint256 entry) public {
        require(
            _operatorContracts.contains(msg.sender),
            "Only authorized operator contract can call execute callback."
        );

        require(
            _callbacks[requestId].callbackContract != address(0),
            "Callback contract not found"
        );

        _callbacks[requestId].callbackContract.call(
            abi.encodeWithSignature("__beaconCallback(uint256)", entry)
        );

        delete _callbacks[requestId];
    }

    /// @notice Get base callback gas required for relay entry callback.
    function baseCallbackGas() public view returns (uint256) {
        return _baseCallbackGas;
    }

    /// @notice Get the entry fee estimate in wei for relay entry request.
    /// @param callbackGas Gas required for the callback.
    function entryFeeEstimate(uint256 callbackGas)
        public
        view
        returns (uint256)
    {
        require(
            callbackGas <= 2000000,
            "Callback gas exceeds 2000000 gas limit"
        );

        (
            uint256 entryVerificationFee,
            uint256 dkgContributionFee,
            uint256 groupProfitFee,
            uint256 gasPriceCeiling
        ) = entryFeeBreakdown();

        return
            entryVerificationFee
                .add(dkgContributionFee)
                .add(groupProfitFee)
                .add(callbackFee(callbackGas, gasPriceCeiling));
    }

    /// @notice Get the entry fee breakdown in wei for relay entry request.
    function entryFeeBreakdown()
        public
        view
        returns (
            uint256 entryVerificationFee,
            uint256 dkgContributionFee,
            uint256 groupProfitFee,
            uint256 gasPriceCeiling
        )
    {
        // Select the most expensive entry verification from all the operator contracts
        // and the highest group profit fee from all the operator contracts. We do not
        // know what is going to be the gas price at the moment of submitting an entry,
        // thus we can't calculate at this point which contract is the most expensive
        // based on the entry verification gas and group profit fee. Hence, we need to
        // select maximum of both those values separately.
        for (uint256 i = 0; i < _operatorContracts.length; i++) {
            OperatorContract operator = OperatorContract(_operatorContracts[i]);

            if (operator.numberOfGroups() > 0) {
                uint256 operatorBid = operator.entryVerificationFee();
                if (operatorBid > entryVerificationFee) {
                    entryVerificationFee = operatorBid;
                }

                operatorBid = operator.groupProfitFee();
                if (operatorBid > groupProfitFee) {
                    groupProfitFee = operatorBid;
                }

                operatorBid = operator.gasPriceCeiling();
                if (operatorBid > gasPriceCeiling) {
                    gasPriceCeiling = operatorBid;
                }
            }
        }

        // Use DKG gas estimate from the latest operator contract since it will be used for the next group creation.
        address latestOperatorContract =
            _operatorContracts[_operatorContracts.length.sub(1)];
        uint256 groupCreationFee =
            OperatorContract(latestOperatorContract).groupCreationFee();

        return (
            entryVerificationFee,
            groupCreationFee.percent(_dkgContributionMargin),
            groupProfitFee,
            gasPriceCeiling
        );
    }

    /// @notice Returns DKG contribution margin - a fraction in % of the
    /// estimated cost of DKG that is included in relay request fee.
    function dkgContributionMargin() public view returns (uint256) {
        return _dkgContributionMargin;
    }

    /// @notice Returns the current DKG fee pool value.
    /// Every relay request payment includes DKG contribution that is added to
    /// the DKG fee pool, once the pool value reaches the required minimum, a new
    /// relay entry will trigger the creation of a new group. Expressed in wei.
    function dkgFeePool() public view returns (uint256) {
        return _dkgFeePool;
    }

    /// @notice Returns the current value of request subsidy pool.
    /// Rewards not paid out to the operators are sent to request subsidy pool to
    /// subsidize new requests: 1% of the subsidy pool is returned to the requester's
    /// surplus address. Expressed in wei.
    function requestSubsidyFeePool() public view returns (uint256) {
        return _requestSubsidyFeePool;
    }

    /// @notice Returns callback surplus recipient for the provided request id.
    function callbackSurplusRecipient(uint256 requestId)
        public
        view
        returns (address payable)
    {
        return _callbacks[requestId].surplusRecipient;
    }

    /// @notice Gets version of the current implementation.
    function version() public pure returns (string memory) {
        return "V1";
    }

    /// @notice Triggers the selection process of a new candidate group if the
    /// DKG fee pool equals or exceeds DKG cost estimate.
    /// @param entry The generated random number.
    /// @param submitter Relay entry submitter - operator.
    function createGroupIfApplicable(uint256 entry, address payable submitter)
        internal
    {
        address latestOperatorContract =
            _operatorContracts[_operatorContracts.length.sub(1)];
        uint256 groupCreationFee =
            OperatorContract(latestOperatorContract).groupCreationFee();

        if (
            _dkgFeePool >= groupCreationFee &&
            OperatorContract(latestOperatorContract).isGroupSelectionPossible()
        ) {
            OperatorContract(latestOperatorContract).createGroup.value(
                groupCreationFee
            )(entry, submitter);
            _dkgFeePool = _dkgFeePool.sub(groupCreationFee);
        }
    }

    /// @notice Get the minimum payment in wei for relay entry callback.
    /// @param _callbackGas Gas required for the callback.
    function callbackFee(uint256 _callbackGas, uint256 _gasPriceCeiling)
        internal
        view
        returns (uint256)
    {
        // gas for the callback itself plus additional operational costs of
        // executing the callback
        uint256 callbackGas =
            _callbackGas == 0 ? 0 : _callbackGas.add(_baseCallbackGas);
        // We take the gas price from the price feed to not let malicious
        // miner-requestors manipulate the gas price when requesting relay entry
        // and underpricing expensive callbacks.
        return callbackGas.mul(_gasPriceCeiling);
    }
}

pragma solidity 0.5.17;

/// @title KeepRegistry
/// @notice Governance owned registry of approved contracts and roles.
contract KeepRegistry {
    enum ContractStatus {New, Approved, Disabled}

    // Governance role is to enable recovery from key compromise by rekeying
    // other roles. Also, it can disable operator contract panic buttons
    // permanently.
    address public governance;

    // Registry Keeper maintains approved operator contracts. Each operator
    // contract must be approved before it can be authorized by a staker or
    // used by a service contract.
    address public registryKeeper;

    // Each operator contract has a Panic Button which can disable malicious
    // or malfunctioning contract that have been previously approved by the
    // Registry Keeper.
    //
    // New operator contract added to the registry has a default panic button
    // value assigned (defaultPanicButton). Panic button for each operator
    // contract can be later updated by Governance to individual value.
    //
    // It is possible to disable panic button for individual contract by
    // setting the panic button to zero address. In such case, operator contract
    // can not be disabled and is permanently approved in the registry.
    mapping(address => address) public panicButtons;

    // Default panic button for each new operator contract added to the
    // registry. Can be later updated for each contract.
    address public defaultPanicButton;

    // Each service contract has a Operator Contract Upgrader whose purpose
    // is to manage operator contracts for that specific service contract.
    // The Operator Contract Upgrader can add new operator contracts to the
    // service contract’s operator contract list, and deprecate old ones.
    mapping(address => address) public operatorContractUpgraders;

    // Operator contract may have a Service Contract Upgrader whose purpose is
    // to manage service contracts for that specific operator contract.
    // Service Contract Upgrader can add and remove service contracts
    // from the list of service contracts approved to work with the operator
    // contract. List of service contracts is maintained in the operator
    // contract and is optional - not every operator contract needs to have
    // a list of service contracts it wants to cooperate with.
    mapping(address => address) public serviceContractUpgraders;

    // The registry of operator contracts
    mapping(address => ContractStatus) public operatorContracts;

    event OperatorContractApproved(address operatorContract);
    event OperatorContractDisabled(address operatorContract);

    event GovernanceUpdated(address governance);
    event RegistryKeeperUpdated(address registryKeeper);
    event DefaultPanicButtonUpdated(address defaultPanicButton);
    event OperatorContractPanicButtonDisabled(address operatorContract);
    event OperatorContractPanicButtonUpdated(
        address operatorContract,
        address panicButton
    );
    event OperatorContractUpgraderUpdated(
        address serviceContract,
        address upgrader
    );
    event ServiceContractUpgraderUpdated(
        address operatorContract,
        address keeper
    );

    modifier onlyGovernance() {
        require(governance == msg.sender, "Not authorized");
        _;
    }

    modifier onlyRegistryKeeper() {
        require(registryKeeper == msg.sender, "Not authorized");
        _;
    }

    modifier onlyPanicButton(address _operatorContract) {
        address panicButton = panicButtons[_operatorContract];
        require(panicButton != address(0), "Panic button disabled");
        require(panicButton == msg.sender, "Not authorized");
        _;
    }

    modifier onlyForNewContract(address _operatorContract) {
        require(
            isNewOperatorContract(_operatorContract),
            "Not a new operator contract"
        );
        _;
    }

    modifier onlyForApprovedContract(address _operatorContract) {
        require(
            isApprovedOperatorContract(_operatorContract),
            "Not an approved operator contract"
        );
        _;
    }

    constructor() public {
        governance = msg.sender;
        registryKeeper = msg.sender;
        defaultPanicButton = msg.sender;
    }

    function setGovernance(address _governance) public onlyGovernance {
        governance = _governance;
        emit GovernanceUpdated(governance);
    }

    function setRegistryKeeper(address _registryKeeper) public onlyGovernance {
        registryKeeper = _registryKeeper;
        emit RegistryKeeperUpdated(registryKeeper);
    }

    function setDefaultPanicButton(address _panicButton) public onlyGovernance {
        defaultPanicButton = _panicButton;
        emit DefaultPanicButtonUpdated(defaultPanicButton);
    }

    function setOperatorContractPanicButton(
        address _operatorContract,
        address _panicButton
    ) public onlyForApprovedContract(_operatorContract) onlyGovernance {
        require(
            panicButtons[_operatorContract] != address(0),
            "Disabled panic button cannot be updated"
        );
        require(
            _panicButton != address(0),
            "Panic button must be non-zero address"
        );

        panicButtons[_operatorContract] = _panicButton;

        emit OperatorContractPanicButtonUpdated(
            _operatorContract,
            _panicButton
        );
    }

    function disableOperatorContractPanicButton(address _operatorContract)
        public
        onlyForApprovedContract(_operatorContract)
        onlyGovernance
    {
        require(
            panicButtons[_operatorContract] != address(0),
            "Panic button already disabled"
        );

        panicButtons[_operatorContract] = address(0);

        emit OperatorContractPanicButtonDisabled(_operatorContract);
    }

    function setOperatorContractUpgrader(
        address _serviceContract,
        address _operatorContractUpgrader
    ) public onlyGovernance {
        operatorContractUpgraders[_serviceContract] = _operatorContractUpgrader;
        emit OperatorContractUpgraderUpdated(
            _serviceContract,
            _operatorContractUpgrader
        );
    }

    function setServiceContractUpgrader(
        address _operatorContract,
        address _serviceContractUpgrader
    ) public onlyGovernance {
        serviceContractUpgraders[_operatorContract] = _serviceContractUpgrader;
        emit ServiceContractUpgraderUpdated(
            _operatorContract,
            _serviceContractUpgrader
        );
    }

    function approveOperatorContract(address operatorContract)
        public
        onlyForNewContract(operatorContract)
        onlyRegistryKeeper
    {
        operatorContracts[operatorContract] = ContractStatus.Approved;
        panicButtons[operatorContract] = defaultPanicButton;
        emit OperatorContractApproved(operatorContract);
    }

    function disableOperatorContract(address operatorContract)
        public
        onlyForApprovedContract(operatorContract)
        onlyPanicButton(operatorContract)
    {
        operatorContracts[operatorContract] = ContractStatus.Disabled;
        emit OperatorContractDisabled(operatorContract);
    }

    function isNewOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.New;
    }

    function isApprovedOperatorContract(address operatorContract)
        public
        view
        returns (bool)
    {
        return operatorContracts[operatorContract] == ContractStatus.Approved;
    }

    function operatorContractUpgraderFor(address _serviceContract)
        public
        view
        returns (address)
    {
        return operatorContractUpgraders[_serviceContract];
    }

    function serviceContractUpgraderFor(address _operatorContract)
        public
        view
        returns (address)
    {
        return serviceContractUpgraders[_operatorContract];
    }
}

pragma solidity 0.5.17;

library AddressArrayUtils {
    function contains(address[] memory self, address _address)
        internal
        pure
        returns (bool)
    {
        for (uint256 i = 0; i < self.length; i++) {
            if (_address == self[i]) {
                return true;
            }
        }
        return false;
    }

    function removeAddress(address[] storage self, address _addressToRemove)
        internal
        returns (address[] storage)
    {
        for (uint256 i = 0; i < self.length; i++) {
            // If address is found in array.
            if (_addressToRemove == self[i]) {
                // Delete element at index and shift array.
                for (uint256 j = i; j < self.length - 1; j++) {
                    self[j] = self[j + 1];
                }
                self.length--;
                i--;
            }
        }
        return self;
    }
}

pragma solidity 0.5.17;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

library PercentUtils {
    using SafeMath for uint256;

    // Return `b`% of `a`
    // 200.percent(40) == 80
    // Commutative, works both ways
    function percent(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(100);
    }

    // Return `a` as percentage of `b`:
    // 80.asPercentOf(200) == 40
    function asPercentOf(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(100).div(b);
    }
}

pragma solidity ^0.5.0;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

